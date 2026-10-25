"""
Vehicle Recommendation Engine.

Uses a scikit-learn KNeighborsClassifier trained on synthetic vehicle data
to recommend the best vehicle category for a given set of customer preferences.
Then queries the database to return actual available vehicles of that category.
"""
import numpy as np
from sklearn.neighbors import KNeighborsClassifier
from sklearn.preprocessing import LabelEncoder

# ─────────────────────────────────────────────────────────────────
# Synthetic training data
# Features: [budget, seats, distance_km, trip_type_enc, fuel_enc]
# Labels:   vehicle category
# ─────────────────────────────────────────────────────────────────

TRIP_TYPES = ["city", "highway", "outstation", "airport"]
FUEL_TYPES = ["petrol", "diesel", "electric", "any"]

trip_enc = LabelEncoder().fit(TRIP_TYPES)
fuel_enc = LabelEncoder().fit(FUEL_TYPES)

TRAIN_X = np.array([
    # budget, seats, dist_km, trip_type_enc, fuel_enc
    [200,  2, 5,   0, 0],   # city  → bike
    [300,  2, 8,   0, 0],   # city  → auto
    [400,  4, 15,  0, 0],   # city  → hatchback
    [600,  4, 25,  0, 0],   # city  → sedan
    [800,  5, 40,  2, 1],   # outstation → suv
    [1200, 6, 100, 2, 1],   # outstation → suv
    [1500, 4, 60,  1, 0],   # highway → sedan
    [2500, 4, 80,  3, 0],   # airport → luxury
    [500,  4, 20,  0, 2],   # city electric → hatchback
    [900,  5, 50,  1, 1],   # highway diesel → suv
    [1800, 4, 120, 2, 1],   # outstation diesel → luxury
    [350,  2, 10,  0, 0],   # city → auto
], dtype=float)

TRAIN_Y = np.array([
    "bike", "auto", "hatchback", "sedan", "suv", "suv",
    "sedan", "luxury", "hatchback", "suv", "luxury", "auto",
])

_knn = KNeighborsClassifier(n_neighbors=3)
_knn.fit(TRAIN_X, TRAIN_Y)


def recommend_vehicles(
    budget: float,
    seats: int,
    trip_type: str,
    preferred_fuel: str,
    distance_km: float,
) -> list:
    """
    Returns a ranked list of vehicle recommendation dicts from the database.
    Falls back to all available vehicles if DB is empty.
    """
    trip_type = trip_type.lower() if trip_type.lower() in TRIP_TYPES else "city"
    preferred_fuel = preferred_fuel.lower() if preferred_fuel.lower() in FUEL_TYPES else "any"

    te = int(trip_enc.transform([trip_type])[0])
    fe = int(fuel_enc.transform([preferred_fuel])[0])

    features = np.array([[budget, seats, distance_km, te, fe]])
    predicted_category = _knn.predict(features)[0]

    # Fetch neighbours' probabilities for ranking
    neighbours = _knn.kneighbors(features, n_neighbors=3, return_distance=True)
    distances, indices = neighbours
    neighbour_categories = [TRAIN_Y[i] for i in indices[0]]

    # Query DB for available vehicles of predicted category first
    from app.models import Vehicle, VehicleStatus, VehicleCategory
    results = []
    seen_categories = set()

    for cat_str in [predicted_category] + neighbour_categories:
        if cat_str in seen_categories:
            continue
        seen_categories.add(cat_str)
        try:
            cat = VehicleCategory(cat_str)
        except ValueError:
            continue
        vehicles = Vehicle.query.filter_by(
            status=VehicleStatus.available, category=cat
        ).limit(5).all()
        for v in vehicles:
            v_dict = v.to_dict()
            v_dict["recommendation_score"] = round(
                max(1.0 - (distances[0][0] / 200.0), 0.5), 2
            )
            v_dict["recommended_category"] = cat_str
            results.append(v_dict)

    # If no vehicles in DB, return category suggestions only
    if not results:
        results = [
            {
                "recommended_category": cat,
                "note": "No vehicles currently available in this category.",
                "recommendation_score": round(max(1.0 - (d / 200.0), 0.5), 2),
            }
            for cat, d in zip(
                [predicted_category] + neighbour_categories,
                [0.0] + list(distances[0]),
            )
        ]

    return results
