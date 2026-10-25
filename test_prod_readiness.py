"""
test_prod_readiness.py — Automated verification of production readiness & SEO.
"""
import os
import sys

# Ensure mobility_project root is in python path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import app

def test_all():
    print("[*] Starting automated production readiness & SEO test...")
    client = app.app.test_client()

    # 1. Test / (Landing Page & SEO)
    r_index = client.get('/')
    assert r_index.status_code == 200, f"Index failed: {r_index.status_code}"
    assert b"Mobility Project - AI-Driven Integrated Mobility Platform" in r_index.data, "Missing H1 keywords in index"
    assert b"application/ld+json" in r_index.data, "Missing JSON-LD in index"
    print("  [x] Test 1: Landing Page (H1 & JSON-LD Structured Data) passed!")

    # 2. Test /robots.txt
    r_robots = client.get('/robots.txt')
    assert r_robots.status_code == 200, f"robots.txt failed: {r_robots.status_code}"
    assert b"User-agent: *" in r_robots.data, "robots.txt invalid content"
    assert b"sitemap.xml" in r_robots.data, "robots.txt missing sitemap reference"
    print("  [x] Test 2: robots.txt route & crawlers permission passed!")

    # 3. Test /sitemap.xml
    r_sitemap = client.get('/sitemap.xml')
    assert r_sitemap.status_code == 200, f"sitemap.xml failed: {r_sitemap.status_code}"
    assert b"<urlset" in r_sitemap.data, "sitemap.xml invalid content"
    print("  [x] Test 3: sitemap.xml indexing route passed!")

    # 4. Test /api/health
    r_health = client.get('/api/health')
    assert r_health.status_code == 200, f"health check failed: {r_health.status_code}"
    health_json = r_health.get_json()
    print(f"  [x] Test 4: /api/health passed! DB status: {health_json.get('db')}")

    # 5. Test /api/vehicles
    r_veh = client.get('/api/vehicles')
    assert r_veh.status_code == 200, f"vehicles failed: {r_veh.status_code}"
    veh_data = r_veh.get_json()
    print(f"  [x] Test 5: /api/vehicles loaded ({len(veh_data)} vehicles found)")

    # 6. Test /api/drivers/match
    r_drv = client.get('/api/drivers/match')
    assert r_drv.status_code == 200, f"drivers failed: {r_drv.status_code}"
    print(f"  [x] Test 6: /api/drivers/match passed ({len(r_drv.get_json())} matched)")

    # 7. Test /api/price
    r_price = client.get('/api/price?base=500&hours=4&service=self_drive')
    assert r_price.status_code == 200, f"price failed: {r_price.status_code}"
    print(f"  [x] Test 7: /api/price calculator passed! Total: {r_price.get_json().get('total')}")

    # 8. Test /api/bookings
    r_bk = client.get('/api/bookings')
    assert r_bk.status_code == 200, f"bookings failed: {r_bk.status_code}"
    print(f"  [x] Test 8: /api/bookings passed ({len(r_bk.get_json())} records)")

    # 9. Test /api/partner/demand
    r_dem = client.get('/api/partner/demand')
    assert r_dem.status_code == 200, f"demand failed: {r_dem.status_code}"
    print(f"  [x] Test 9: /api/partner/demand passed!")

    print("\n[SUCCESS] ALL PRODUCTION READINESS & SEO SUITES PASSED (100%)!")

if __name__ == "__main__":
    test_all()
