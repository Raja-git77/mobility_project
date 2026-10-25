"""app.py — AI Mobility Platform Flask backend."""
import os, json, math, random
from decimal import Decimal
from datetime import datetime
from dotenv import load_dotenv
from flask import Flask, render_template, request, jsonify, send_from_directory, make_response
from flask.json.provider import DefaultJSONProvider

load_dotenv()

try:
    from flask_cors import CORS
except ImportError:
    CORS = None

import database as db

class CustomJSONProvider(DefaultJSONProvider):
    def default(self, obj):
        if isinstance(obj, Decimal):
            return float(obj)
        return super().default(obj)

app = Flask(__name__)
app.json = CustomJSONProvider(app)
app.config['TEMPLATES_AUTO_RELOAD'] = True
app.jinja_env.auto_reload = True

# ── CORS setup ─────────────────────────────────────────────────────────────
allowed_origins_env = os.getenv("ALLOWED_ORIGINS", "*")
if allowed_origins_env != "*":
    origins = [o.strip() for o in allowed_origins_env.split(",") if o.strip()]
    supports_credentials = True
else:
    origins = "*"
    supports_credentials = False

if CORS:
    CORS(app, resources={r"/*": {"origins": origins}}, supports_credentials=supports_credentials)

@app.after_request
def apply_cors_headers(response):
    origin = request.headers.get("Origin")
    if origin and allowed_origins_env != "*":
        if origin in origins:
            response.headers["Access-Control-Allow-Origin"] = origin
            response.headers["Access-Control-Allow-Credentials"] = "true"
    else:
        response.headers.setdefault("Access-Control-Allow-Origin", "*")
    response.headers.setdefault("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS, PATCH")
    response.headers.setdefault("Access-Control-Allow-Headers", "Content-Type, Authorization, X-Requested-With")
    return response

@app.route("/", defaults={"path": ""}, methods=["OPTIONS"])
@app.route("/<path:path>", methods=["OPTIONS"])
def preflight_options(path=""):
    resp = make_response()
    resp.headers["Access-Control-Allow-Origin"] = "*"
    resp.headers["Access-Control-Allow-Methods"] = "GET, POST, PUT, DELETE, OPTIONS, PATCH"
    resp.headers["Access-Control-Allow-Headers"] = "Content-Type, Authorization, X-Requested-With"
    return resp, 204

# ── AI helpers ─────────────────────────────────────────────────────────────
def _surge():
    h = datetime.now().hour
    if 7 <= h <= 10 or 17 <= h <= 20:
        return round(random.uniform(1.7, 2.2), 2)
    elif 11 <= h <= 16:
        return round(random.uniform(1.1, 1.5), 2)
    return round(random.uniform(0.9, 1.1), 2)

def _ai_score(v):
    rating = float(v.get("rating", 4.5))
    base_per_hr = float(v.get("base_per_hr", 500))
    return rating * 10 + (5 if v.get("is_ev") else 0) - (base_per_hr / 200)

def _driver_score(d):
    rating = float(d.get("rating", 4.5))
    dist = float(d.get("distance_km", 2.0))
    exp = int(d.get("exp_years", 3))
    prox = max(0.0, 10.0 - dist)
    return round(rating * 4 + prox * 3 + min(exp, 10) * 0.3, 2)

def _fare(base, hrs, multiplier, driver_fee=0):
    return round(float(base) * float(multiplier) * float(hrs) + float(driver_fee), 2)

FLUTTER_WEB_DIR = os.path.join(os.path.dirname(__file__), "build", "web")

@app.get("/")
def index():
    return render_template("index.html")

@app.route("/flutter")
@app.route("/flutter/")
def flutter_index():
    if os.path.exists(os.path.join(FLUTTER_WEB_DIR, "index.html")):
        return send_from_directory(FLUTTER_WEB_DIR, "index.html")
    return "Flutter web build not found. Run 'flutter build web' to generate it.", 404

@app.route("/flutter/<path:filename>")
def flutter_static(filename):
    if os.path.exists(os.path.join(FLUTTER_WEB_DIR, filename)):
        return send_from_directory(FLUTTER_WEB_DIR, filename)
    return send_from_directory(FLUTTER_WEB_DIR, "index.html")

@app.get("/api/health")
def health():
    return jsonify({"status": "online", "db": "postgresql" if db._USE_PG else "sqlite",
                    "time": datetime.now().isoformat()})

# ── Vehicles ───────────────────────────────────────────────────────────────
@app.get("/api/vehicles")
def get_vehicles():
    cat  = request.args.get("category", "All")
    hrs  = float(request.args.get("hours", 4))
    rows = db.execute("SELECT * FROM vehicles WHERE available=1 ORDER BY rating DESC", fetch="all")
    surge = _surge()
    result = []
    for v in (rows or []):
        if cat != "All" and v["category"] != cat:
            continue
        v["base_per_hr"] = float(v["base_per_hr"])
        v["rating"] = float(v["rating"])
        v["is_ev"] = bool(v["is_ev"])
        v["features"] = json.loads(v["features"]) if isinstance(v["features"], str) else v["features"]
        v["demand_multiplier"] = surge
        v["fare"] = _fare(v["base_per_hr"], hrs, surge)
        v["ai_score"] = round(_ai_score(v), 1)
        v["ai_recommended"] = v["ai_score"] >= 47
        result.append(v)
    result.sort(key=lambda x: -x["ai_score"])
    return jsonify(result)

# ── Price calculator ───────────────────────────────────────────────────────
@app.get("/api/price")
def get_price():
    base = float(request.args.get("base", 550))
    hrs  = float(request.args.get("hours", 4))
    svc  = request.args.get("service", "self_drive")
    mult = _surge()
    driver_fee = round(200 * hrs, 2) if svc in ("rental_driver", "acting_driver") else 0
    return jsonify({"base": base, "multiplier": mult, "duration": hrs,
                    "driver_fee": driver_fee, "total": _fare(base, hrs, mult, driver_fee)})

# ── Drivers ────────────────────────────────────────────────────────────────
@app.get("/api/drivers/match")
@app.post("/api/drivers/match")
def match_drivers():
    rows = db.execute("SELECT * FROM drivers WHERE is_online=1 ORDER BY rating DESC LIMIT 8", fetch="all")
    if not rows:
        return jsonify([])
    scored = []
    for d in rows:
        d["rating"] = float(d.get("rating", 4.5))
        d["distance_km"] = float(d.get("distance_km", 2.0))
        d["match_score"] = _driver_score(d)
        d["eta_min"] = int(d["distance_km"] * 3.5 + random.uniform(1, 4))
        d["assigned"] = False
        scored.append(d)
    scored.sort(key=lambda x: -x["match_score"])
    scored[0]["assigned"] = True
    return jsonify(scored[:5])

# ── Bookings ───────────────────────────────────────────────────────────────
@app.post("/api/book")
def book():
    d   = request.json or {}
    ref = db.ref_id()
    row = (
        ref,
        d.get("service_type", "self_drive"),
        d.get("vehicle_model", ""),
        d.get("vehicle_category", ""),
        d.get("driver_name", ""),
        d.get("pickup", ""),
        d.get("dropoff", ""),
        float(d.get("duration_hrs", 4)),
        float(d.get("fare", 0)),
        float(d.get("demand_multiplier", 1.0)),
        d.get("payment_method", "UPI"),
    )
    db.execute(
        """INSERT INTO bookings
           (booking_ref,service_type,vehicle_model,vehicle_category,driver_name,
            pickup,dropoff,duration_hrs,fare,demand_multiplier,payment_method)
           VALUES (?,?,?,?,?,?,?,?,?,?,?)""",
        row, commit=True
    )
    eta = random.randint(4, 14)
    return jsonify({"status": "confirmed", "booking_ref": ref,
                    "fare": float(d.get("fare", 0)), "eta_min": eta,
                    "receipt": {
                        "ref": ref, "service": d.get("service_type"),
                        "vehicle": d.get("vehicle_model"),
                        "driver": d.get("driver_name"),
                        "fare": float(d.get("fare", 0)),
                        "payment": d.get("payment_method", "UPI"),
                        "eta": eta
                    }})

@app.get("/api/bookings")
def get_bookings():
    rows = db.execute("SELECT * FROM bookings ORDER BY id DESC LIMIT 30", fetch="all")
    return jsonify(rows or [])

@app.post("/api/rate")
def rate():
    d   = request.json or {}
    ref = d.get("booking_ref")
    stars = int(d.get("rating", 5))
    pay   = d.get("payment_method", "UPI")
    db.execute("UPDATE bookings SET rating=?, payment_method=?, status='completed' WHERE booking_ref=?",
               (stars, pay, ref), commit=True)
    return jsonify({"status": "rated", "rating": stars})

# ── Partner Fleet ──────────────────────────────────────────────────────────
@app.post("/api/partner/vehicle")
def add_partner_vehicle():
    d = request.json or {}
    model = d.get("model", "My Car")
    cat   = d.get("category", "Sedan")
    base  = float(d.get("base_per_hr", 500))
    feat  = json.dumps(d.get("features", ["AC", "GPS"]))
    is_ev = 1 if str(d.get("is_ev", False)).lower() in ("true", "1") else 0
    vid = db.execute(
        "INSERT INTO vehicles (model,category,base_per_hr,features,is_ev) VALUES (?,?,?,?,?)",
        (model, cat, base, feat, is_ev), fetch="id", commit=True
    )
    return jsonify({"status": "listed", "id": vid, "model": model})

@app.post("/api/partner/toggle/<int:vid>")
def toggle_vehicle(vid):
    db.execute("UPDATE vehicles SET available=1-available WHERE id=?", (vid,), commit=True)
    row = db.execute("SELECT id, model, available FROM vehicles WHERE id=?", (vid,), fetch="one")
    return jsonify({"status": "toggled", "vehicle": row})

# ── Demand zones ───────────────────────────────────────────────────────────
@app.get("/api/partner/demand")
def partner_demand():
    zones = db.execute("SELECT * FROM demand_zones ORDER BY multiplier DESC", fetch="all")
    # enrich with live projected data
    earnings = db.execute("SELECT COALESCE(SUM(fare),0) as total, COUNT(*) as trips FROM bookings", fetch="one")
    for z in (zones or []):
        z["multiplier"] = float(z.get("multiplier", 1.0))
        z["projected_trips"] = int(z["multiplier"] * random.uniform(18, 40))
        z["revenue_potential"] = round(z["projected_trips"] * 450 * z["multiplier"], 0)
    return jsonify({
        "zones": zones or [],
        "summary": {
            "total_earnings": float((earnings or {}).get("total", 0)),
            "total_trips": int((earnings or {}).get("trips", 0))
        }
    })

# ── GPS simulation ─────────────────────────────────────────────────────────
@app.get("/api/gps/simulate")
def gps():
    lat, lng = 13.0827 + random.uniform(-0.05, 0.05), 80.2707 + random.uniform(-0.05, 0.05)
    return jsonify({"lat": round(lat, 6), "lng": round(lng, 6),
                    "eta_min": random.randint(2, 12), "status": "en_route"})

# ── SEO & Search Engine Endpoints ──────────────────────────────────────────
@app.get("/robots.txt")
def robots_txt():
    for base in [app.root_path, os.path.join(app.root_path, "static")]:
        if os.path.exists(os.path.join(base, "robots.txt")):
            return send_from_directory(base, "robots.txt", mimetype="text/plain")
    return "User-agent: *\nAllow: /\nSitemap: https://mobility-project.onrender.com/sitemap.xml\n", 200, {"Content-Type": "text/plain"}

@app.get("/sitemap.xml")
def sitemap_xml():
    for base in [app.root_path, os.path.join(app.root_path, "static")]:
        if os.path.exists(os.path.join(base, "sitemap.xml")):
            return send_from_directory(base, "sitemap.xml", mimetype="application/xml")
    return "<urlset xmlns=\"http://www.sitemaps.org/schemas/sitemap/0.9\"></urlset>", 200, {"Content-Type": "application/xml"}

if __name__ == "__main__":
    db.init_db()
    port = int(os.getenv("PORT", 8000))
    debug_mode = os.getenv("FLASK_DEBUG", "1").lower() in ("1", "true", "yes")
    print(f"[*] Starting AI Mobility Platform at http://127.0.0.1:{port} (Live Reload: {debug_mode})")
    app.run(debug=debug_mode, host="0.0.0.0", port=port, use_reloader=debug_mode)
else:
    db.init_db()
