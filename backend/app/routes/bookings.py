"""
Bookings API — create, list, get, update status, cancel, rate.
"""
import uuid
from datetime import datetime
from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity, get_jwt
from app.extensions import db
from app.models import (
    Booking, BookingStatus, ServiceType, Vehicle, VehicleStatus,
    Driver, Payment, PaymentStatus, PaymentMethod,
)
from app.ai.dynamic_pricing import calculate_fare
from app.ai.driver_matching import find_best_driver

bookings_bp = Blueprint("bookings", __name__)


def _generate_booking_ref() -> str:
    return "MB" + uuid.uuid4().hex[:8].upper()


@bookings_bp.post("/")
@jwt_required()
def create_booking():
    customer_id = int(get_jwt_identity())
    data = request.get_json(silent=True) or {}

    required = [
        "service_type", "vehicle_id", "pickup_address",
        "pickup_lat", "pickup_lng", "dropoff_address",
        "dropoff_lat", "dropoff_lng",
    ]
    for field in required:
        if data.get(field) is None:
            return jsonify({"success": False, "message": f"'{field}' is required."}), 400

    # Validate service type
    try:
        svc_type = ServiceType(data["service_type"])
    except ValueError:
        return jsonify({"success": False, "message": "Invalid service_type."}), 400

    # Validate vehicle
    vehicle = Vehicle.query.get(data["vehicle_id"])
    if not vehicle:
        return jsonify({"success": False, "message": "Vehicle not found."}), 404
    if vehicle.status != VehicleStatus.available:
        return jsonify({"success": False, "message": "Vehicle is not available."}), 409

    # Compute distance (Haversine approximation in km)
    from math import radians, cos, sin, asin, sqrt
    def haversine(lat1, lng1, lat2, lng2):
        R = 6371.0
        dlat = radians(lat2 - lat1)
        dlng = radians(lng2 - lng1)
        a = sin(dlat / 2) ** 2 + cos(radians(lat1)) * cos(radians(lat2)) * sin(dlng / 2) ** 2
        return R * 2 * asin(sqrt(a))

    dist_km = haversine(
        float(data["pickup_lat"]), float(data["pickup_lng"]),
        float(data["dropoff_lat"]), float(data["dropoff_lng"]),
    )
    dist_km = max(dist_km, 1.0)

    # AI dynamic pricing
    fare_result = calculate_fare(
        base_fare_per_km=vehicle.base_fare_per_km,
        distance_km=dist_km,
        vehicle_category=vehicle.category.value,
        service_type=svc_type.value,
    )
    estimated_fare = fare_result["total_fare"]
    surge = fare_result["surge_multiplier"]

    # AI driver matching (only for on-demand)
    assigned_driver_id = None
    if svc_type == ServiceType.on_demand:
        driver = find_best_driver(
            pickup_lat=float(data["pickup_lat"]),
            pickup_lng=float(data["pickup_lng"]),
        )
        if driver:
            assigned_driver_id = driver["id"]

    # Create booking
    booking = Booking(
        booking_ref=_generate_booking_ref(),
        customer_id=customer_id,
        driver_id=assigned_driver_id,
        vehicle_id=vehicle.id,
        service_type=svc_type,
        status=BookingStatus.confirmed,
        pickup_address=data["pickup_address"],
        pickup_lat=float(data["pickup_lat"]),
        pickup_lng=float(data["pickup_lng"]),
        dropoff_address=data["dropoff_address"],
        dropoff_lat=float(data["dropoff_lat"]),
        dropoff_lng=float(data["dropoff_lng"]),
        distance_km=round(dist_km, 2),
        estimated_fare=round(estimated_fare, 2),
        surge_multiplier=surge,
        scheduled_at=(
            datetime.fromisoformat(data["scheduled_at"])
            if data.get("scheduled_at")
            else None
        ),
    )
    vehicle.status = VehicleStatus.booked
    db.session.add(booking)
    db.session.commit()

    return jsonify({
        "success": True,
        "message": "Booking created successfully.",
        "booking": booking.to_dict(),
        "fare_breakdown": fare_result,
    }), 201


@bookings_bp.get("/")
@jwt_required()
def list_bookings():
    identity = int(get_jwt_identity())
    claims = get_jwt()
    role = claims.get("role", "customer")
    page = int(request.args.get("page", 1))
    per_page = int(request.args.get("per_page", 10))
    status_filter = request.args.get("status")

    if role == "admin":
        query = Booking.query
    elif role == "driver":
        from app.models import Driver as DriverModel
        driver = DriverModel.query.filter_by(user_id=identity).first()
        if not driver:
            return jsonify({"success": False, "message": "Driver profile not found."}), 404
        query = Booking.query.filter_by(driver_id=driver.id)
    else:
        query = Booking.query.filter_by(customer_id=identity)

    if status_filter:
        try:
            query = query.filter_by(status=BookingStatus(status_filter))
        except ValueError:
            return jsonify({"success": False, "message": "Invalid status filter."}), 400

    pagination = query.order_by(Booking.created_at.desc()).paginate(
        page=page, per_page=per_page, error_out=False
    )
    return jsonify({
        "success": True,
        "bookings": [b.to_dict() for b in pagination.items],
        "total": pagination.total,
        "pages": pagination.pages,
        "page": page,
    }), 200


@bookings_bp.get("/<int:booking_id>")
@jwt_required()
def get_booking(booking_id: int):
    identity = int(get_jwt_identity())
    claims = get_jwt()
    role = claims.get("role", "customer")

    booking = Booking.query.get_or_404(booking_id)

    if role == "customer" and booking.customer_id != identity:
        return jsonify({"success": False, "message": "Access denied."}), 403

    return jsonify({"success": True, "booking": booking.to_dict()}), 200


@bookings_bp.patch("/<int:booking_id>/status")
@jwt_required()
def update_booking_status(booking_id: int):
    claims = get_jwt()
    role = claims.get("role", "customer")

    booking = Booking.query.get_or_404(booking_id)
    data = request.get_json(silent=True) or {}
    new_status_str = data.get("status", "")

    try:
        new_status = BookingStatus(new_status_str)
    except ValueError:
        return jsonify({"success": False, "message": "Invalid status."}), 400

    # Role-based transition rules
    allowed_by_driver = {BookingStatus.in_progress, BookingStatus.completed}
    allowed_by_admin = set(BookingStatus)
    allowed_by_customer = {BookingStatus.cancelled}

    if role == "driver" and new_status not in allowed_by_driver:
        return jsonify({"success": False, "message": "Drivers can only set in_progress or completed."}), 403
    if role == "customer" and new_status not in allowed_by_customer:
        return jsonify({"success": False, "message": "Customers can only cancel bookings."}), 403

    booking.status = new_status
    if new_status == BookingStatus.in_progress:
        booking.started_at = datetime.utcnow()
    elif new_status == BookingStatus.completed:
        booking.completed_at = datetime.utcnow()
        booking.final_fare = booking.estimated_fare
        # Free the vehicle
        if booking.vehicle:
            booking.vehicle.status = VehicleStatus.available
        # Update driver stats
        if booking.driver:
            booking.driver.total_rides += 1
    elif new_status == BookingStatus.cancelled:
        if booking.vehicle:
            booking.vehicle.status = VehicleStatus.available

    db.session.commit()
    return jsonify({"success": True, "booking": booking.to_dict()}), 200


@bookings_bp.post("/<int:booking_id>/rate")
@jwt_required()
def rate_booking(booking_id: int):
    identity = int(get_jwt_identity())
    booking = Booking.query.get_or_404(booking_id)

    if booking.customer_id != identity:
        return jsonify({"success": False, "message": "Only the customer can rate this booking."}), 403
    if booking.status != BookingStatus.completed:
        return jsonify({"success": False, "message": "Can only rate completed bookings."}), 400

    data = request.get_json(silent=True) or {}
    rating = float(data.get("rating", 0))
    if not (1.0 <= rating <= 5.0):
        return jsonify({"success": False, "message": "Rating must be between 1 and 5."}), 400

    booking.customer_rating = rating
    booking.review_text = data.get("review_text", "")

    # Update driver's average rating
    if booking.driver:
        driver = booking.driver
        total = driver.total_rides or 1
        driver.rating = round(
            ((driver.rating * (total - 1)) + rating) / total, 2
        )

    db.session.commit()
    return jsonify({"success": True, "message": "Rating submitted.", "booking": booking.to_dict()}), 200
