"""
Drivers API — list online drivers, create profile, update location, go online/offline.
"""
from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity, get_jwt
from app.extensions import db
from app.models import Driver, User, Vehicle, VehicleStatus, UserRole

drivers_bp = Blueprint("drivers", __name__)


@drivers_bp.get("/")
@jwt_required()
def list_drivers():
    """Admin: list all drivers. Optionally filter by is_online."""
    claims = get_jwt()
    if claims.get("role") != "admin":
        return jsonify({"success": False, "message": "Admin access required."}), 403

    online_only = request.args.get("online") == "true"
    query = Driver.query
    if online_only:
        query = query.filter_by(is_online=True)

    drivers = query.all()
    return jsonify({"success": True, "drivers": [d.to_dict() for d in drivers]}), 200


@drivers_bp.get("/nearby")
@jwt_required()
def nearby_drivers():
    """Return online drivers within a radius (km) of the given lat/lng."""
    try:
        lat = float(request.args["lat"])
        lng = float(request.args["lng"])
        radius = float(request.args.get("radius", 10.0))
    except (KeyError, ValueError):
        return jsonify({"success": False, "message": "lat, lng required as floats."}), 400

    from math import radians, cos, sin, asin, sqrt

    def haversine(lat1, lng1, lat2, lng2):
        R = 6371.0
        dlat = radians(lat2 - lat1)
        dlng = radians(lng2 - lng1)
        a = sin(dlat / 2) ** 2 + cos(radians(lat1)) * cos(radians(lat2)) * sin(dlng / 2) ** 2
        return R * 2 * asin(sqrt(a))

    online_drivers = Driver.query.filter(
        Driver.is_online == True,
        Driver.current_lat.isnot(None),
        Driver.current_lng.isnot(None),
    ).all()

    result = []
    for d in online_drivers:
        dist = haversine(lat, lng, d.current_lat, d.current_lng)
        if dist <= radius:
            driver_dict = d.to_dict()
            driver_dict["distance_km"] = round(dist, 2)
            result.append(driver_dict)

    result.sort(key=lambda x: x["distance_km"])
    return jsonify({"success": True, "drivers": result}), 200


@drivers_bp.get("/<int:driver_id>")
@jwt_required()
def get_driver(driver_id: int):
    driver = Driver.query.get_or_404(driver_id)
    return jsonify({"success": True, "driver": driver.to_dict()}), 200


@drivers_bp.post("/register")
@jwt_required()
def register_driver():
    """Register a user as a driver (requires driver role or admin)."""
    identity = int(get_jwt_identity())
    claims = get_jwt()
    role = claims.get("role")

    data = request.get_json(silent=True) or {}
    target_user_id = int(data.get("user_id", identity))

    # Only admin can register another user as driver
    if target_user_id != identity and role != "admin":
        return jsonify({"success": False, "message": "Cannot register another user as driver."}), 403

    if not data.get("license_number"):
        return jsonify({"success": False, "message": "'license_number' is required."}), 400

    user = User.query.get(target_user_id)
    if not user:
        return jsonify({"success": False, "message": "User not found."}), 404
    if Driver.query.filter_by(user_id=target_user_id).first():
        return jsonify({"success": False, "message": "Driver profile already exists for this user."}), 409
    if Driver.query.filter_by(license_number=data["license_number"]).first():
        return jsonify({"success": False, "message": "License number already registered."}), 409

    # Upgrade user role to driver
    user.role = UserRole.driver

    driver = Driver(
        user_id=target_user_id,
        license_number=data["license_number"].upper().strip(),
        vehicle_id=data.get("vehicle_id"),
    )
    db.session.add(driver)
    db.session.commit()
    return jsonify({"success": True, "driver": driver.to_dict()}), 201


@drivers_bp.patch("/me/location")
@jwt_required()
def update_my_location():
    """Driver updates their own live GPS coordinates."""
    identity = int(get_jwt_identity())
    driver = Driver.query.filter_by(user_id=identity).first()
    if not driver:
        return jsonify({"success": False, "message": "Driver profile not found."}), 404

    data = request.get_json(silent=True) or {}
    try:
        lat = float(data["lat"])
        lng = float(data["lng"])
    except (KeyError, ValueError, TypeError):
        return jsonify({"success": False, "message": "'lat' and 'lng' are required floats."}), 400

    driver.current_lat = lat
    driver.current_lng = lng
    db.session.commit()

    # Broadcast to any connected clients in the driver's room via SocketIO
    from app.extensions import socketio
    socketio.emit(
        "driver_location_update",
        {"driver_id": driver.id, "lat": lat, "lng": lng},
        room=f"booking_{driver.id}",
        namespace="/tracking",
    )

    return jsonify({"success": True, "message": "Location updated."}), 200


@drivers_bp.patch("/me/online")
@jwt_required()
def toggle_online():
    """Driver toggles their online/offline status."""
    identity = int(get_jwt_identity())
    driver = Driver.query.filter_by(user_id=identity).first()
    if not driver:
        return jsonify({"success": False, "message": "Driver profile not found."}), 404

    data = request.get_json(silent=True) or {}
    driver.is_online = bool(data.get("is_online", not driver.is_online))
    db.session.commit()
    return jsonify({
        "success": True,
        "is_online": driver.is_online,
        "message": f"You are now {'online' if driver.is_online else 'offline'}.",
    }), 200
