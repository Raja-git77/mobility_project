"""
AI endpoints — vehicle recommendation, price estimate, driver match preview.
"""
from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from app.ai.recommendation_engine import recommend_vehicles
from app.ai.dynamic_pricing import calculate_fare
from app.ai.driver_matching import find_best_driver

ai_bp = Blueprint("ai", __name__)


@ai_bp.post("/recommend-vehicles")
@jwt_required()
def recommend():
    """
    Recommend vehicles based on customer preferences.
    Body: { "budget": float, "seats": int, "trip_type": str,
            "preferred_fuel": str, "distance_km": float }
    """
    data = request.get_json(silent=True) or {}
    result = recommend_vehicles(
        budget=float(data.get("budget", 500.0)),
        seats=int(data.get("seats", 4)),
        trip_type=data.get("trip_type", "city"),
        preferred_fuel=data.get("preferred_fuel", "any"),
        distance_km=float(data.get("distance_km", 20.0)),
    )
    return jsonify({"success": True, "recommendations": result}), 200


@ai_bp.post("/estimate-fare")
@jwt_required()
def estimate_fare():
    """
    Estimate dynamic fare for a trip.
    Body: { "vehicle_id": int, "pickup_lat", "pickup_lng",
            "dropoff_lat", "dropoff_lng", "service_type" }
    """
    from math import radians, cos, sin, asin, sqrt
    from app.models import Vehicle

    data = request.get_json(silent=True) or {}

    def haversine(lat1, lng1, lat2, lng2):
        R = 6371.0
        dlat = radians(lat2 - lat1)
        dlng = radians(lng2 - lng1)
        a = sin(dlat / 2) ** 2 + cos(radians(lat1)) * cos(radians(lat2)) * sin(dlng / 2) ** 2
        return R * 2 * asin(sqrt(a))

    try:
        vehicle = Vehicle.query.get(int(data.get("vehicle_id", 0)))
        if not vehicle:
            return jsonify({"success": False, "message": "Vehicle not found."}), 404

        dist_km = haversine(
            float(data["pickup_lat"]), float(data["pickup_lng"]),
            float(data["dropoff_lat"]), float(data["dropoff_lng"]),
        )
        dist_km = max(dist_km, 1.0)

        result = calculate_fare(
            base_fare_per_km=vehicle.base_fare_per_km,
            distance_km=dist_km,
            vehicle_category=vehicle.category.value,
            service_type=data.get("service_type", "on_demand"),
        )
        return jsonify({"success": True, "estimate": result, "distance_km": round(dist_km, 2)}), 200
    except (KeyError, TypeError, ValueError) as exc:
        return jsonify({"success": False, "message": str(exc)}), 400


@ai_bp.post("/match-driver")
@jwt_required()
def match_driver():
    """Return the AI-matched best available driver for a pickup point."""
    data = request.get_json(silent=True) or {}
    try:
        lat = float(data["pickup_lat"])
        lng = float(data["pickup_lng"])
    except (KeyError, TypeError, ValueError):
        return jsonify({"success": False, "message": "pickup_lat and pickup_lng required."}), 400

    driver = find_best_driver(pickup_lat=lat, pickup_lng=lng)
    if not driver:
        return jsonify({"success": False, "message": "No available drivers nearby."}), 404

    return jsonify({"success": True, "driver": driver}), 200
