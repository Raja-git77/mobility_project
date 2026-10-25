# AI-Driven Integrated Mobility Platform
## Complete Setup Guide

---

## Directory Structure

```
mobility_project/
├── backend/                          # Flask Python backend
│   ├── app/
│   │   ├── __init__.py               # App factory
│   │   ├── config.py                 # Dev/Prod/Test configs
│   │   ├── extensions.py             # db, jwt, bcrypt, socketio
│   │   ├── models/
│   │   │   └── __init__.py           # All SQLAlchemy models
│   │   ├── routes/
│   │   │   ├── auth.py               # /api/auth/*
│   │   │   ├── vehicles.py           # /api/vehicles/*
│   │   │   ├── bookings.py           # /api/bookings/*
│   │   │   ├── drivers.py            # /api/drivers/*
│   │   │   ├── payments.py           # /api/payment/*
│   │   │   └── ai_routes.py          # /api/ai/*
│   │   ├── ai/
│   │   │   ├── dynamic_pricing.py    # LinearRegression surge pricing
│   │   │   ├── recommendation_engine.py  # KNN vehicle recommendations
│   │   │   └── driver_matching.py    # LinearRegression driver scoring
│   │   └── sockets/
│   │       └── location.py           # SocketIO /tracking events
│   ├── requirements.txt
│   ├── run.py                        # WSGI entry-point
│   └── .env.example
│
├── lib/                              # Flutter frontend
│   ├── main.dart                     # App entry-point + theme
│   ├── config/app_config.dart
│   ├── models/
│   │   ├── user_model.dart
│   │   ├── vehicle_model.dart
│   │   ├── booking_model.dart
│   │   └── payment_model.dart
│   ├── providers/
│   │   ├── auth_provider.dart
│   │   └── booking_provider.dart
│   ├── services/
│   │   ├── api_service.dart          # Dio HTTP + JWT auto-refresh
│   │   └── socket_service.dart       # Socket.IO /tracking client
│   └── screens/
│       ├── splash_screen.dart
│       ├── login_screen.dart
│       ├── register_screen.dart
│       ├── dashboard_screen.dart
│       ├── vehicle_selection_screen.dart
│       ├── booking_confirmation_screen.dart
│       ├── payment_checkout_screen.dart  # Razorpay + HMAC verify
│       ├── trip_tracking_screen.dart     # Google Maps + WebSocket
│       ├── my_bookings_screen.dart
│       └── profile_screen.dart
│
├── schema.sql                        # PostgreSQL DDL + seed admin
└── pubspec.yaml
```

---

## Backend Setup

### 1. Create PostgreSQL database
```bash
psql -U postgres -c "CREATE DATABASE mobility_db;"
psql -U postgres -d mobility_db -f schema.sql
```

### 2. Configure environment
```bash
cd backend
copy .env.example .env
# Edit .env — fill in your real keys
```

### 3. Create virtual environment and install
```bash
cd backend
python -m venv venv
venv\Scripts\activate          # Windows
pip install -r requirements.txt
```

### 4. Run the backend
```bash
python run.py
# Server starts at http://localhost:5000
```

---

## Flutter Frontend Setup

### 1. Set API keys in `lib/config/app_config.dart`
- `googleMapsApiKey` — from Google Cloud Console
- `razorpayKeyId` — from Razorpay dashboard

### 2. Android — add Google Maps API key
In `android/app/src/main/AndroidManifest.xml` inside `<application>`:
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_GOOGLE_MAPS_API_KEY"/>
```

### 3. iOS — add Google Maps API key
In `ios/Runner/AppDelegate.swift`:
```swift
GMSServices.provideAPIKey("YOUR_GOOGLE_MAPS_API_KEY")
```

### 4. Install Flutter dependencies
```bash
flutter pub get
```

### 5. Run
```bash
flutter run -d chrome          # Web
flutter run -d android         # Android emulator
flutter run -d ios             # iOS simulator
```

---

## API Reference

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| POST | `/api/auth/register` | — | Register user |
| POST | `/api/auth/login` | — | Login → JWT |
| GET | `/api/auth/me` | JWT | Current user |
| POST | `/api/auth/refresh` | Refresh JWT | New access token |
| GET | `/api/vehicles/available` | JWT | Available vehicles |
| POST | `/api/vehicles/` | JWT+Admin | Create vehicle |
| POST | `/api/bookings/` | JWT | Create booking |
| GET | `/api/bookings/` | JWT | My bookings |
| PATCH | `/api/bookings/:id/status` | JWT | Update status |
| POST | `/api/bookings/:id/rate` | JWT | Rate completed trip |
| POST | `/api/payment/create-order` | JWT | Razorpay order |
| POST | `/api/payment/verify` | JWT | Verify Razorpay signature |
| POST | `/api/payment/webhook` | HMAC | Razorpay webhook |
| POST | `/api/ai/recommend-vehicles` | JWT | AI vehicle picker |
| POST | `/api/ai/estimate-fare` | JWT | Dynamic fare estimate |
| POST | `/api/ai/match-driver` | JWT | AI driver match |

---

## WebSocket Events (namespace: `/tracking`)

| Event (emit) | Payload | Description |
|---|---|---|
| `join_booking_room` | `{booking_id}` | Subscribe to trip room |
| `driver_location` | `{booking_id, driver_id, lat, lng}` | Driver GPS update |
| `trip_status_update` | `{booking_id, status, message}` | Status broadcast |
| `customer_ping` | `{booking_id}` | Heartbeat |

| Event (receive) | Payload | Description |
|---|---|---|
| `driver_location_update` | `{driver_id, lat, lng, booking_id}` | Live driver coords |
| `trip_status_changed` | `{booking_id, status, message}` | Trip state changed |
| `pong` | `{booking_id}` | Heartbeat response |

---

## AI Modules

| Module | Algorithm | Input | Output |
|---|---|---|---|
| `dynamic_pricing.py` | LinearRegression | hour, is_weekend, demand_index | surge multiplier (1.0–2.5x) |
| `recommendation_engine.py` | KNeighborsClassifier (k=3) | budget, seats, trip_type, fuel | ranked vehicle list |
| `driver_matching.py` | LinearRegression | dist_km, rating, total_rides_norm | desirability score |
