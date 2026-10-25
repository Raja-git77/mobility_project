"""
Driver Matching Algorithm.

Uses a weighted scoring model (scikit-learn LinearRegression) to rank
available online drivers by proximity, rating, and total rides completed.
Returns the best-matched driver dict.
"""
from math import radians, cos, sin, asin, sqrt
import numpy as np
from sklearn.linear_model import LinearRegression


# ─────────────────────────────────────────────────────────────────
# Synthetic training for scoring weights
# Features: [distance_km, rating, total_rides_norm]
# Label:    desirability_score (0-1)
# ─────────────────────────────────────────────────────────────────

TRAIN_X = np.array([
    [0.5, 5.0, 1.0],
    [1.0, 4.8, 0.9],
    [2.0, 4.5, 0.7],
    [3.0, 4.0, 0.5],
    [5.0, 3.5, 0.3],
    [8.0, 5.0, 0.8],
    [0.8, 4.9, 0.95],
    [10.0, 3.0, 0.2],
    [1.5, 4.7, 0.85],
    [0.3, 4.6, 0.6],
], dtype=float)

TRAIN_Y = np.array([0.98, 0.92, 0.78, 0.60, 0.42, 0.71, 0.94, 0.22, 0.84, 0.90])

_model = LinearRegression()
_model.fit(TRAIN_X, TRAIN_Y)


def _haversine(lat1: float, lng1: float, lat2: float, lng2: float) -> float:
    R = 6371.0
    dlat = radians(lat2 - lat1)
    dlng = radians(lng2 - lng1)
    a = sin(dlat / 2) ** 2 + cos(radians(lat1)) * cos(radians(lat2)) * sin(dlng / 2) ** 2
    return R * 2 * asin(sqrt(a))


def find_best_driver(pickup_lat: float, pickup_lng: float, radius_km: float = 15.0) -> dict | None:
    """
    Query online drivers from DB, score each using the ML model, and return
    the highest-scoring driver as a dict. Returns None if no drivers available.
    """
    from app.models import Driver

    online_drivers = Driver.query.filter(
        Driver.is_online == True,
        Driver.current_lat.isnot(None),
        Driver.current_lng.isnot(None),
    ).all()

    if not online_drivers:
        return None

    scored = []
    for driver in online_drivers:
        dist = _haversine(pickup_lat, pickup_lng, driver.current_lat, driver.current_lng)
        if dist > radius_km:
            continue

        rides_norm = min(driver.total_rides / 500.0, 1.0)
        features = np.array([[dist, driver.rating, rides_norm]])
        score = float(_model.predict(features)[0])
        score = max(0.0, min(score, 1.0))

        scored.append((score, dist, driver))

    if not scored:
        return None

    scored.sort(key=lambda x: (-x[0], x[1]))
    best_score, best_dist, best_driver = scored[0]

    result = best_driver.to_dict()
    result["match_score"] = round(best_score, 3)
    result["distance_to_pickup_km"] = round(best_dist, 2)
    return result
