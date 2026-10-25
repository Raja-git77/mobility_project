"""
Dynamic Pricing Calculator.

Uses a scikit-learn LinearRegression trained on synthetic trip data to predict
a base fare multiplier, then applies surge pricing rules based on:
  - Hour of day (peak/off-peak)
  - Vehicle category premium
  - Service type premium
  - Distance band bonus
"""
import datetime
import numpy as np
from sklearn.linear_model import LinearRegression


# ─────────────────────────────────────────────────────────────────
# Synthetic training data (hour, is_weekend, demand_index → multiplier)
# ─────────────────────────────────────────────────────────────────

TRAIN_X = np.array([
    # hour, is_weekend, demand_index
    [8,  0, 0.9],   [9,  0, 1.0],   [10, 0, 0.7],
    [12, 0, 0.8],   [17, 0, 1.1],   [18, 0, 1.3],
    [19, 0, 1.2],   [22, 0, 0.6],   [0,  0, 0.4],
    [8,  1, 0.7],   [10, 1, 0.8],   [14, 1, 0.9],
    [17, 1, 1.4],   [19, 1, 1.5],   [22, 1, 1.1],
], dtype=float)

TRAIN_Y = np.array([
    1.3, 1.4, 1.1, 1.0, 1.5, 1.8, 1.7, 1.0, 0.9,
    1.1, 1.0, 1.1, 1.6, 1.9, 1.3,
])

_model = LinearRegression()
_model.fit(TRAIN_X, TRAIN_Y)


# ─────────────────────────────────────────────────────────────────
# Category and service premiums
# ─────────────────────────────────────────────────────────────────

CATEGORY_PREMIUM = {
    "sedan": 1.0,
    "suv": 1.25,
    "hatchback": 0.9,
    "bike": 0.75,
    "auto": 0.8,
    "luxury": 1.8,
}

SERVICE_PREMIUM = {
    "on_demand": 1.0,
    "self_drive": 1.1,
}

# Flat base fare components (INR)
BASE_PLATFORM_FEE = 20.0
PER_MINUTE_RATE = 1.5


def calculate_fare(
    base_fare_per_km: float,
    distance_km: float,
    vehicle_category: str = "sedan",
    service_type: str = "on_demand",
    duration_minutes: float = 0.0,
) -> dict:
    """
    Returns a dict with fare breakdown:
      - base_fare
      - surge_multiplier
      - category_premium
      - service_premium
      - platform_fee
      - time_charge
      - total_fare
    """
    now = datetime.datetime.now()
    hour = now.hour
    is_weekend = int(now.weekday() >= 5)

    # Estimate demand index from time
    if 8 <= hour <= 10 or 17 <= hour <= 20:
        demand_index = 1.1
    elif 0 <= hour <= 5:
        demand_index = 0.4
    else:
        demand_index = 0.8

    surge_raw = float(
        _model.predict([[hour, is_weekend, demand_index]])[0]
    )
    surge = round(min(max(surge_raw, 1.0), 2.5), 2)

    cat_premium = CATEGORY_PREMIUM.get(vehicle_category, 1.0)
    svc_premium = SERVICE_PREMIUM.get(service_type, 1.0)

    base_fare = base_fare_per_km * distance_km
    time_charge = PER_MINUTE_RATE * duration_minutes
    total = (base_fare * surge * cat_premium * svc_premium) + BASE_PLATFORM_FEE + time_charge
    total = round(max(total, 40.0), 2)

    return {
        "base_fare": round(base_fare, 2),
        "surge_multiplier": surge,
        "category_premium": cat_premium,
        "service_premium": svc_premium,
        "platform_fee": BASE_PLATFORM_FEE,
        "time_charge": round(time_charge, 2),
        "total_fare": total,
        "distance_km": round(distance_km, 2),
        "vehicle_category": vehicle_category,
        "service_type": service_type,
    }
