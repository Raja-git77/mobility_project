"""
Vehicles CRUD API — list, get, create, update, delete, search by category.
"""
from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt
from app.extensions import db
from app.models import Vehicle, VehicleCategory, VehicleStatus

vehicles_bp = Blueprint("vehicles", __name__)


def _admin_required():
    claims = get_jwt()
    return claims.get("role") == "admin"


@vehicles_bp.get("/")
@jwt_required()
def list_vehicles():
    category = request.args.get("category")
    status = request.args.get("status")
    page = int(request.args.get("page", 1))
    per_page = int(request.args.get("per_page", 20))

    query = Vehicle.query
    if category:
        try:
            query = query.filter_by(category=VehicleCategory(category))
        except ValueError:
            return jsonify({"success": False, "message": f"Invalid category '{category}'."}), 400
    if status:
        try:
            query = query.filter_by(status=VehicleStatus(status))
        except ValueError:
            return jsonify({"success": False, "message": f"Invalid status '{status}'."}), 400

    pagination = query.order_by(Vehicle.id).paginate(page=page, per_page=per_page, error_out=False)
    return jsonify({
        "success": True,
        "vehicles": [v.to_dict() for v in pagination.items],
        "total": pagination.total,
        "pages": pagination.pages,
        "page": page,
    }), 200


@vehicles_bp.get("/<int:vehicle_id>")
@jwt_required()
def get_vehicle(vehicle_id: int):
    vehicle = Vehicle.query.get_or_404(vehicle_id)
    return jsonify({"success": True, "vehicle": vehicle.to_dict()}), 200


@vehicles_bp.get("/available")
@jwt_required()
def available_vehicles():
    """Return all vehicles with status=available, optionally filtered by category."""
    category = request.args.get("category")
    query = Vehicle.query.filter_by(status=VehicleStatus.available)
    if category:
        try:
            query = query.filter_by(category=VehicleCategory(category))
        except ValueError:
            return jsonify({"success": False, "message": "Invalid category."}), 400
    vehicles = query.order_by(Vehicle.base_fare_per_km).all()
    return jsonify({"success": True, "vehicles": [v.to_dict() for v in vehicles]}), 200


@vehicles_bp.post("/")
@jwt_required()
def create_vehicle():
    if not _admin_required():
        return jsonify({"success": False, "message": "Admin access required."}), 403

    data = request.get_json(silent=True) or {}
    required = ["make", "model", "year", "registration_number", "category"]
    for field in required:
        if not data.get(field):
            return jsonify({"success": False, "message": f"'{field}' is required."}), 400

    if Vehicle.query.filter_by(registration_number=data["registration_number"]).first():
        return jsonify({"success": False, "message": "Registration number already exists."}), 409

    try:
        cat = VehicleCategory(data["category"])
    except ValueError:
        return jsonify({"success": False, "message": "Invalid vehicle category."}), 400

    vehicle = Vehicle(
        make=data["make"],
        model=data["model"],
        year=int(data["year"]),
        registration_number=data["registration_number"].upper(),
        category=cat,
        seats=data.get("seats", 4),
        fuel_type=data.get("fuel_type", "petrol"),
        transmission=data.get("transmission", "manual"),
        base_fare_per_km=float(data.get("base_fare_per_km", 12.0)),
        image_url=data.get("image_url"),
        features=data.get("features", []),
        current_lat=data.get("current_lat"),
        current_lng=data.get("current_lng"),
    )
    db.session.add(vehicle)
    db.session.commit()
    return jsonify({"success": True, "vehicle": vehicle.to_dict()}), 201


@vehicles_bp.put("/<int:vehicle_id>")
@jwt_required()
def update_vehicle(vehicle_id: int):
    if not _admin_required():
        return jsonify({"success": False, "message": "Admin access required."}), 403

    vehicle = Vehicle.query.get_or_404(vehicle_id)
    data = request.get_json(silent=True) or {}

    allowed_fields = [
        "make", "model", "year", "seats", "fuel_type", "transmission",
        "base_fare_per_km", "image_url", "features", "current_lat", "current_lng",
    ]
    for field in allowed_fields:
        if field in data:
            setattr(vehicle, field, data[field])

    if "status" in data:
        try:
            vehicle.status = VehicleStatus(data["status"])
        except ValueError:
            return jsonify({"success": False, "message": "Invalid status value."}), 400

    if "category" in data:
        try:
            vehicle.category = VehicleCategory(data["category"])
        except ValueError:
            return jsonify({"success": False, "message": "Invalid category value."}), 400

    db.session.commit()
    return jsonify({"success": True, "vehicle": vehicle.to_dict()}), 200


@vehicles_bp.delete("/<int:vehicle_id>")
@jwt_required()
def delete_vehicle(vehicle_id: int):
    if not _admin_required():
        return jsonify({"success": False, "message": "Admin access required."}), 403

    vehicle = Vehicle.query.get_or_404(vehicle_id)
    db.session.delete(vehicle)
    db.session.commit()
    return jsonify({"success": True, "message": "Vehicle deleted."}), 200
