"""database.py — PostgreSQL primary with ThreadedConnectionPool, SQLite auto-fallback."""
import os, sqlite3, json, random, string, time
from datetime import datetime
from dotenv import load_dotenv

load_dotenv()

# ── connection config ──────────────────────────────────────────────────────
SQLITE_PATH = os.path.join(os.path.dirname(__file__), "mobility.db")
_USE_PG = False
_pg_pool = None

def _get_pg_kwargs():
    """Extract connection parameters from DATABASE_URL or individual env vars."""
    db_url = os.getenv("DATABASE_URL")
    if db_url:
        # Standardize url for psycopg2
        if db_url.startswith("postgres://"):
            db_url = "postgresql://" + db_url[len("postgres://"):]
        return {"dsn": db_url}
    
    return {
        "host": os.getenv("DB_HOST", os.getenv("PGHOST", "localhost")),
        "port": int(os.getenv("DB_PORT", os.getenv("PGPORT", "5432"))),
        "dbname": os.getenv("DB_NAME", os.getenv("PGDATABASE", "postgres")),
        "user": os.getenv("DB_USER", os.getenv("PGUSER", "postgres")),
        "password": os.getenv("DB_PASSWORD", os.getenv("PGPASSWORD", "")),
        "connect_timeout": 5,
    }

def _init_pg_pool():
    """Initializes ThreadedConnectionPool with auto-reconnection for cloud databases."""
    global _pg_pool, _USE_PG
    try:
        import psycopg2
        from psycopg2 import pool
        conn_params = _get_pg_kwargs()
        
        # Test direct connection first
        test_conn = psycopg2.connect(**conn_params)
        test_conn.close()
        
        _pg_pool = pool.ThreadedConnectionPool(minconn=1, maxconn=20, **conn_params)
        _USE_PG = True
        print("[DB] OK PostgreSQL ThreadedConnectionPool initialized (maxconn=20)")
    except Exception as e:
        _USE_PG = False
        _pg_pool = None
        print(f"[DB] INFO PostgreSQL not connected ({e}) — operating on SQLite fallback ({SQLITE_PATH})")

def _probe_pg():
    _init_pg_pool()

def checkout_conn():
    """Checks out a healthy connection from the pool or opens SQLite."""
    global _pg_pool, _USE_PG
    if _USE_PG and _pg_pool:
        import psycopg2
        for attempt in range(2):
            try:
                conn = _pg_pool.getconn()
                # Pre-ping to verify connection is alive (prevents drops from cloud timeouts)
                if conn.closed != 0:
                    raise psycopg2.OperationalError("Connection is closed")
                with conn.cursor() as cur:
                    cur.execute("SELECT 1")
                return conn, "pg"
            except Exception as err:
                try:
                    if 'conn' in locals() and conn:
                        _pg_pool.putconn(conn, close=True)
                except Exception:
                    pass
                if attempt == 1:
                    # Retry pool re-init on cloud disconnect
                    _init_pg_pool()
                    if _pg_pool:
                        return _pg_pool.getconn(), "pg"
        # If pool fails, temporarily fallback to SQLite
        print("[DB] WARN PG pool checkout failed, falling back to SQLite")
    
    c = sqlite3.connect(SQLITE_PATH)
    c.row_factory = sqlite3.Row
    return c, "sl"

def release_conn(conn, kind):
    """Safely returns connection to pool or closes SQLite connection."""
    if kind == "pg" and _pg_pool:
        try:
            _pg_pool.putconn(conn)
        except Exception:
            pass
    elif conn:
        try:
            conn.close()
        except Exception:
            pass

def get_conn():
    """Legacy helper for direct single-connection use."""
    return checkout_conn()

def _q(sql, kind):
    """Convert ? placeholders to %s and adapt boolean checks for psycopg2."""
    if kind == "pg":
        sql = sql.replace("?", "%s")
        # Adapt boolean integer comparisons to PostgreSQL boolean operators
        sql = sql.replace("available=1", "available IS TRUE")
        sql = sql.replace("available=0", "available IS FALSE")
        sql = sql.replace("is_online=1", "is_online IS TRUE")
        sql = sql.replace("is_online=0", "is_online IS FALSE")
    return sql

def execute(sql, params=(), *, fetch="none", commit=False):
    """Executes query with auto-reconnection and connection pool management."""
    max_retries = 2
    for attempt in range(max_retries):
        conn, kind = checkout_conn()
        try:
            if kind == "pg":
                import psycopg2.extras
                cur = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
            else:
                cur = conn.cursor()
            
            cur.execute(_q(sql, kind), params)
            result = None
            if fetch == "one":
                row = cur.fetchone()
                result = dict(row) if row else None
            elif fetch == "all":
                result = [dict(r) for r in cur.fetchall()]
            elif fetch == "id":
                if kind == "pg":
                    row = cur.fetchone()
                    result = dict(row)["id"] if row else None
                else:
                    result = cur.lastrowid
            if commit:
                conn.commit()
            return result
        except Exception as e:
            if commit and conn:
                try:
                    conn.rollback()
                except Exception:
                    pass
            # If PostgreSQL disconnected mid-query, retry once
            if kind == "pg" and attempt == 0:
                print(f"[DB] WARN Query failed with connection error ({e}), retrying...")
                time.sleep(0.5)
                continue
            raise e
        finally:
            release_conn(conn, kind)

# ── DDL ────────────────────────────────────────────────────────────────────
_PG_VEHICLES = """
CREATE TABLE IF NOT EXISTS vehicles (
    id SERIAL PRIMARY KEY,
    model VARCHAR(120) NOT NULL,
    category VARCHAR(30) NOT NULL,
    base_per_hr NUMERIC(10,2) NOT NULL,
    seats INTEGER NOT NULL DEFAULT 5,
    rating NUMERIC(3,2) NOT NULL DEFAULT 4.5,
    features TEXT NOT NULL DEFAULT '[]',
    is_ev BOOLEAN NOT NULL DEFAULT FALSE,
    available BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT NOW()
)"""

_SL_VEHICLES = """
CREATE TABLE IF NOT EXISTS vehicles (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    model TEXT NOT NULL,
    category TEXT NOT NULL,
    base_per_hr REAL NOT NULL,
    seats INTEGER NOT NULL DEFAULT 5,
    rating REAL NOT NULL DEFAULT 4.5,
    features TEXT NOT NULL DEFAULT '[]',
    is_ev INTEGER NOT NULL DEFAULT 0,
    available INTEGER NOT NULL DEFAULT 1,
    created_at TEXT DEFAULT (datetime('now'))
)"""

_PG_DRIVERS = """
CREATE TABLE IF NOT EXISTS drivers (
    id SERIAL PRIMARY KEY,
    name VARCHAR(120) NOT NULL,
    rating NUMERIC(3,2) NOT NULL DEFAULT 4.5,
    distance_km NUMERIC(6,2) NOT NULL DEFAULT 2.0,
    exp_years INTEGER NOT NULL DEFAULT 3,
    is_online BOOLEAN NOT NULL DEFAULT TRUE,
    total_trips INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP DEFAULT NOW()
)"""

_SL_DRIVERS = """
CREATE TABLE IF NOT EXISTS drivers (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    rating REAL NOT NULL DEFAULT 4.5,
    distance_km REAL NOT NULL DEFAULT 2.0,
    exp_years INTEGER NOT NULL DEFAULT 3,
    is_online INTEGER NOT NULL DEFAULT 1,
    total_trips INTEGER NOT NULL DEFAULT 0,
    created_at TEXT DEFAULT (datetime('now'))
)"""

_PG_BOOKINGS = """
CREATE TABLE IF NOT EXISTS bookings (
    id SERIAL PRIMARY KEY,
    booking_ref VARCHAR(20) UNIQUE NOT NULL,
    service_type VARCHAR(40) NOT NULL,
    vehicle_model VARCHAR(120),
    vehicle_category VARCHAR(40),
    driver_name VARCHAR(120),
    pickup TEXT,
    dropoff TEXT,
    duration_hrs NUMERIC(6,2),
    fare NUMERIC(10,2),
    demand_multiplier NUMERIC(5,2) DEFAULT 1.0,
    payment_method VARCHAR(20) DEFAULT 'UPI',
    status VARCHAR(20) DEFAULT 'confirmed',
    rating INTEGER,
    created_at TIMESTAMP DEFAULT NOW()
)"""

_SL_BOOKINGS = """
CREATE TABLE IF NOT EXISTS bookings (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    booking_ref TEXT UNIQUE NOT NULL,
    service_type TEXT NOT NULL,
    vehicle_model TEXT,
    vehicle_category TEXT,
    driver_name TEXT,
    pickup TEXT,
    dropoff TEXT,
    duration_hrs REAL,
    fare REAL,
    demand_multiplier REAL DEFAULT 1.0,
    payment_method TEXT DEFAULT 'UPI',
    status TEXT DEFAULT 'confirmed',
    rating INTEGER,
    created_at TEXT DEFAULT (datetime('now'))
)"""

_PG_ZONES = """
CREATE TABLE IF NOT EXISTS demand_zones (
    id SERIAL PRIMARY KEY,
    zone_name VARCHAR(120) NOT NULL,
    demand_level VARCHAR(20) NOT NULL DEFAULT 'Medium',
    multiplier NUMERIC(5,2) NOT NULL DEFAULT 1.2,
    city VARCHAR(80) DEFAULT 'Chennai'
)"""

_SL_ZONES = """
CREATE TABLE IF NOT EXISTS demand_zones (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    zone_name TEXT NOT NULL,
    demand_level TEXT NOT NULL DEFAULT 'Medium',
    multiplier REAL NOT NULL DEFAULT 1.2,
    city TEXT DEFAULT 'Chennai'
)"""

_SEED_VEHICLES = [
    ("Maruti Swift",      "Hatchback", 350,  5, 4.5, '["AC","Music","GPS"]',              0),
    ("Hyundai i20",       "Hatchback", 400,  5, 4.6, '["AC","Android Auto","Sunroof"]',   0),
    ("Honda City",        "Sedan",     550,  5, 4.7, '["AC","Leather Seats","GPS"]',       0),
    ("Toyota Camry",      "Sedan",     800,  5, 4.8, '["AC","Ventilated Seats","ADAS"]',   0),
    ("Hyundai Creta",     "SUV",       750,  5, 4.7, '["AC","Panoramic Roof","4WD"]',      0),
    ("Mahindra XUV700",   "SUV",       950,  7, 4.8, '["AC","ADAS","7-Seater"]',           0),
    ("Toyota Fortuner",   "SUV",      1100,  7, 4.9, '["AC","Leather","4WD"]',             0),
    ("BMW 3 Series",      "Sedan",    1500,  5, 5.0, '["AC","Premium Audio","Sunroof"]',   0),
    ("Tata Nexon EV",     "EV",        600,  5, 4.9, '["EV","Fast Charge","ADAS"]',        1),
    ("MG ZS EV",          "EV",        700,  5, 4.8, '["EV","Panoramic Roof","360Cam"]',   1),
]

_SEED_DRIVERS = [
    ("Rajan Kumar",  4.9, 2.1, 8),
    ("Suresh Babu",  4.8, 3.4, 12),
    ("Mani Selvan",  4.7, 1.8, 5),
    ("Priya Devi",   5.0, 4.2, 15),
    ("Karthi M",     4.6, 2.8, 20),
    ("Selvam G",     4.8, 1.2, 3),
    ("Anbu Raja",    4.9, 3.1, 9),
    ("Deepika S",    4.7, 2.5, 7),
]

_SEED_ZONES = [
    ("OMR Tech Corridor", "High",   2.3),
    ("Chennai Central",   "High",   2.1),
    ("Anna Nagar",        "High",   1.9),
    ("Velachery",         "High",   1.8),
    ("T. Nagar",          "Medium", 1.5),
    ("Guindy IT Park",    "Medium", 1.4),
    ("Porur",             "Medium", 1.3),
    ("Tambaram",          "Low",    1.1),
]

def _init():
    conn, kind = checkout_conn()
    try:
        cur = conn.cursor()
        # create tables
        for sql_pg, sql_sl in [
            (_PG_VEHICLES, _SL_VEHICLES),
            (_PG_DRIVERS, _SL_DRIVERS),
            (_PG_BOOKINGS, _SL_BOOKINGS),
            (_PG_ZONES, _SL_ZONES),
        ]:
            cur.execute(sql_pg if kind == "pg" else sql_sl)

        # Synchronize columns for PostgreSQL if older table variations exist
        if kind == "pg":
            cur.execute("""
                DO $$
                BEGIN
                    -- Vehicles table compatibility
                    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name='vehicles') THEN
                        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='vehicles' AND column_name='model') THEN
                            ALTER TABLE vehicles ADD COLUMN model VARCHAR(120);
                            IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='vehicles' AND column_name='name') THEN
                                UPDATE vehicles SET model = name WHERE model IS NULL;
                            END IF;
                        END IF;
                        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='vehicles' AND column_name='base_per_hr') THEN
                            ALTER TABLE vehicles ADD COLUMN base_per_hr NUMERIC(10,2) DEFAULT 500.0;
                            IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='vehicles' AND column_name='base_multiplier') THEN
                                UPDATE vehicles SET base_per_hr = ROUND(COALESCE(base_multiplier, 1.0) * 450, 0) WHERE base_per_hr IS NULL;
                            END IF;
                        END IF;
                        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='vehicles' AND column_name='available') THEN
                            ALTER TABLE vehicles ADD COLUMN available BOOLEAN DEFAULT TRUE;
                            IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='vehicles' AND column_name='is_available') THEN
                                UPDATE vehicles SET available = is_available WHERE available IS NULL;
                            END IF;
                        END IF;
                        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='vehicles' AND column_name='is_ev') THEN
                            ALTER TABLE vehicles ADD COLUMN is_ev BOOLEAN DEFAULT FALSE;
                            IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='vehicles' AND column_name='fuel_type') THEN
                                UPDATE vehicles SET is_ev = (fuel_type ILIKE '%electric%') WHERE is_ev IS NULL;
                            END IF;
                        END IF;
                        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='vehicles' AND column_name='features') THEN
                            ALTER TABLE vehicles ADD COLUMN features TEXT DEFAULT '["AC","GPS"]';
                        END IF;
                    END IF;

                    -- Drivers table compatibility
                    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name='drivers') THEN
                        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='drivers' AND column_name='is_online') THEN
                            ALTER TABLE drivers ADD COLUMN is_online BOOLEAN DEFAULT TRUE;
                            IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='drivers' AND column_name='is_available') THEN
                                UPDATE drivers SET is_online = is_available WHERE is_online IS NULL;
                            END IF;
                        END IF;
                        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='drivers' AND column_name='distance_km') THEN
                            ALTER TABLE drivers ADD COLUMN distance_km NUMERIC(6,2) DEFAULT 2.5;
                        END IF;
                        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='drivers' AND column_name='exp_years') THEN
                            ALTER TABLE drivers ADD COLUMN exp_years INTEGER DEFAULT 3;
                            IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='drivers' AND column_name='experience_years') THEN
                                UPDATE drivers SET exp_years = experience_years WHERE exp_years IS NULL;
                            END IF;
                        END IF;
                    END IF;

                    -- Bookings table compatibility
                    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name='bookings') THEN
                        -- Ensure legacy columns don't block new inserts
                        BEGIN
                            ALTER TABLE bookings ALTER COLUMN booking_code DROP NOT NULL;
                            ALTER TABLE bookings ALTER COLUMN pickup_address DROP NOT NULL;
                            ALTER TABLE bookings ALTER COLUMN dropoff_address DROP NOT NULL;
                            ALTER TABLE bookings ALTER COLUMN pickup_lat DROP NOT NULL;
                            ALTER TABLE bookings ALTER COLUMN pickup_lng DROP NOT NULL;
                            ALTER TABLE bookings ALTER COLUMN dropoff_lat DROP NOT NULL;
                            ALTER TABLE bookings ALTER COLUMN dropoff_lng DROP NOT NULL;
                            ALTER TABLE bookings ALTER COLUMN distance_km DROP NOT NULL;
                            ALTER TABLE bookings ALTER COLUMN estimated_fare DROP NOT NULL;
                        EXCEPTION WHEN OTHERS THEN NULL;
                        END;

                        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='bookings' AND column_name='booking_ref') THEN
                            ALTER TABLE bookings ADD COLUMN booking_ref VARCHAR(40);
                            IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='bookings' AND column_name='booking_code') THEN
                                UPDATE bookings SET booking_ref = booking_code WHERE booking_ref IS NULL;
                            END IF;
                        END IF;
                        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='bookings' AND column_name='vehicle_model') THEN
                            ALTER TABLE bookings ADD COLUMN vehicle_model VARCHAR(120);
                        END IF;
                        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='bookings' AND column_name='driver_name') THEN
                            ALTER TABLE bookings ADD COLUMN driver_name VARCHAR(120);
                        END IF;
                        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='bookings' AND column_name='pickup') THEN
                            ALTER TABLE bookings ADD COLUMN pickup TEXT;
                            IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='bookings' AND column_name='pickup_address') THEN
                                UPDATE bookings SET pickup = pickup_address WHERE pickup IS NULL;
                            END IF;
                        END IF;
                        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='bookings' AND column_name='dropoff') THEN
                            ALTER TABLE bookings ADD COLUMN dropoff TEXT;
                            IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='bookings' AND column_name='dropoff_address') THEN
                                UPDATE bookings SET dropoff = dropoff_address WHERE dropoff IS NULL;
                            END IF;
                        END IF;
                        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='bookings' AND column_name='duration_hrs') THEN
                            ALTER TABLE bookings ADD COLUMN duration_hrs NUMERIC(6,2) DEFAULT 4;
                            IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='bookings' AND column_name='duration_hours') THEN
                                UPDATE bookings SET duration_hrs = duration_hours WHERE duration_hrs IS NULL;
                            END IF;
                        END IF;
                        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='bookings' AND column_name='fare') THEN
                            ALTER TABLE bookings ADD COLUMN fare NUMERIC(10,2) DEFAULT 0;
                            IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='bookings' AND column_name='final_fare') THEN
                                UPDATE bookings SET fare = COALESCE(final_fare, estimated_fare, 0) WHERE fare IS NULL;
                            END IF;
                        END IF;
                        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='bookings' AND column_name='demand_multiplier') THEN
                            ALTER TABLE bookings ADD COLUMN demand_multiplier NUMERIC(5,2) DEFAULT 1.0;
                        END IF;
                        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='bookings' AND column_name='payment_method') THEN
                            ALTER TABLE bookings ADD COLUMN payment_method VARCHAR(30) DEFAULT 'UPI';
                        END IF;
                    END IF;
                END $$;
            """)

        # seed if empty
        cur.execute("SELECT COUNT(*) FROM vehicles")
        count = cur.fetchone()
        n = list(count)[0] if count else 0
        if n == 0:
            ph = "%s" if kind == "pg" else "?"
            for row in _SEED_VEHICLES:
                cur.execute(
                    f"INSERT INTO vehicles (model,category,base_per_hr,seats,rating,features,is_ev) VALUES ({ph},{ph},{ph},{ph},{ph},{ph},{ph})",
                    row)
            for row in _SEED_DRIVERS:
                cur.execute(
                    f"INSERT INTO drivers (name,rating,distance_km,exp_years) VALUES ({ph},{ph},{ph},{ph})",
                    row)
            for row in _SEED_ZONES:
                cur.execute(
                    f"INSERT INTO demand_zones (zone_name,demand_level,multiplier) VALUES ({ph},{ph},{ph})",
                    row)
        conn.commit()
        print("[DB] Tables ready")
    finally:
        release_conn(conn, kind)

def ref_id():
    return "MOB" + "".join(random.choices(string.digits, k=8))

def init_db():
    _probe_pg()
    _init()
