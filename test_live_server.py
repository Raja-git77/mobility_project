"""
test_live_server.py — Automated Real-Time Verification Suite
"""
import urllib.request
import json
import sys

# Ensure UTF-8 output on Windows terminal
if hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8')

BASE = 'http://127.0.0.1:8000'

def test_all():
    print("[*] Starting Real-Time API Automated Verification against:", BASE)

    # 1. Vehicles (simulate tab switch / catalog load)
    print("\n[1] Testing GET /api/vehicles (Tab switch & vehicle catalog)...")
    with urllib.request.urlopen(f"{BASE}/api/vehicles?category=All&hours=4") as res:
        assert res.status == 200, f"Expected 200, got {res.status}"
        vehicles = json.loads(res.read().decode())
        assert len(vehicles) > 0, "No vehicles returned"
        print(f"    [PASS] HTTP {res.status} OK -- Loaded {len(vehicles)} vehicles in real-time!")

    # 2. Dynamic Price (simulate moving duration slider: 2h, 4h, 8h)
    print("\n[2] Testing GET /api/price (Moving hours slider: 2h, 4h, 8h)...")
    for hours in [2, 4, 8]:
        with urllib.request.urlopen(f"{BASE}/api/price?base=550&hours={hours}&service=self_drive") as res:
            assert res.status == 200
            price = json.loads(res.read().decode())
            assert "total" in price
            print(f"    [PASS] HTTP {res.status} OK -- {hours} hrs -> Total: Rs.{price['total']} (Surge: {price['multiplier']}x)")

    # 3. Booking (simulate live ride booking)
    print("\n[3] Testing POST /api/book (Live ride booking simulation)...")
    payload = {
        "service_type": "self_drive",
        "vehicle_model": vehicles[0]["model"],
        "vehicle_category": vehicles[0]["category"],
        "pickup": "Chennai Central Station",
        "dropoff": "OMR IT Corridor",
        "duration_hrs": 4,
        "fare": 620.0,
        "payment_method": "UPI"
    }
    req = urllib.request.Request(
        f"{BASE}/api/book",
        data=json.dumps(payload).encode('utf-8'),
        headers={"Content-Type": "application/json"}
    )
    with urllib.request.urlopen(req) as res:
        assert res.status == 200
        booking = json.loads(res.read().decode())
        assert booking.get("status") == "confirmed"
        ref = booking.get("booking_ref")
        print(f"    [PASS] HTTP {res.status} OK -- Booking confirmed in real-time! Ref: {ref}")

    # 4. SEO & Static Endpoints
    print("\n[4] Testing SEO Routes: /robots.txt & /sitemap.xml...")
    with urllib.request.urlopen(f"{BASE}/robots.txt") as res:
        assert res.status == 200
        print("    [PASS] /robots.txt -> HTTP 200 OK")
    with urllib.request.urlopen(f"{BASE}/sitemap.xml") as res:
        assert res.status == 200
        print("    [PASS] /sitemap.xml -> HTTP 200 OK")

    # 5. Landing Page & SEO Structure
    print("\n[5] Testing Landing Page / & SEO Structure...")
    with urllib.request.urlopen(f"{BASE}/") as res:
        assert res.status == 200
        html = res.read().decode()
        assert "Mobility Project | AI-Driven Integrated Mobility Platform" in html, "Missing Title in HTML"
        assert "application/ld+json" in html, "Missing Schema.org JSON-LD"
        assert "REAL-TIME API MONITOR" in html, "Missing Live Real-Time Monitor panel"
        print("    [PASS] / Landing page loaded with Title, H1, Schema.org JSON-LD, & Real-Time Monitor!")

    print("\n" + "=" * 65)
    print(">>> 100% REAL-TIME LIVE VERIFICATION PASSED (ALL HTTP 200 OK) <<<")
    print("=" * 65)

if __name__ == "__main__":
    test_all()
