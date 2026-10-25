-- AI Integrated Mobility Platform — PostgreSQL Schema
-- Run: psql -U postgres -d mobility_db -f schema.sql

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Users
CREATE TABLE IF NOT EXISTS users (
    id              SERIAL PRIMARY KEY,
    name            VARCHAR(120) NOT NULL,
    email           VARCHAR(180) UNIQUE NOT NULL,
    phone           VARCHAR(20) UNIQUE NOT NULL,
    password_hash   TEXT NOT NULL,
    role            VARCHAR(20) NOT NULL DEFAULT 'customer'
                    CHECK (role IN ('admin','customer','driver')),
    is_active       BOOLEAN NOT NULL DEFAULT TRUE,
    profile_picture_url TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Vehicles
CREATE TABLE IF NOT EXISTS vehicles (
    id                      SERIAL PRIMARY KEY,
    make                    VARCHAR(80) NOT NULL,
    model                   VARCHAR(80) NOT NULL,
    year                    INTEGER NOT NULL,
    registration_number     VARCHAR(30) UNIQUE NOT NULL,
    category                VARCHAR(20) NOT NULL
                            CHECK (category IN ('sedan','suv','hatchback','bike','auto','luxury')),
    status                  VARCHAR(20) NOT NULL DEFAULT 'available'
                            CHECK (status IN ('available','booked','maintenance')),
    seats                   INTEGER NOT NULL DEFAULT 4,
    fuel_type               VARCHAR(30) NOT NULL DEFAULT 'petrol',
    transmission            VARCHAR(20) NOT NULL DEFAULT 'manual',
    base_fare_per_km        NUMERIC(8,2) NOT NULL DEFAULT 12.0,
    image_url               TEXT,
    features                JSONB DEFAULT '[]',
    current_lat             DOUBLE PRECISION,
    current_lng             DOUBLE PRECISION,
    created_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at              TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Drivers
CREATE TABLE IF NOT EXISTS drivers (
    id              SERIAL PRIMARY KEY,
    user_id         INTEGER UNIQUE NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    license_number  VARCHAR(50) UNIQUE NOT NULL,
    vehicle_id      INTEGER REFERENCES vehicles(id) ON DELETE SET NULL,
    rating          NUMERIC(3,2) NOT NULL DEFAULT 5.00,
    total_rides     INTEGER NOT NULL DEFAULT 0,
    is_online       BOOLEAN NOT NULL DEFAULT FALSE,
    current_lat     DOUBLE PRECISION,
    current_lng     DOUBLE PRECISION,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Bookings
CREATE TABLE IF NOT EXISTS bookings (
    id              SERIAL PRIMARY KEY,
    booking_ref     VARCHAR(20) UNIQUE NOT NULL,
    customer_id     INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    driver_id       INTEGER REFERENCES drivers(id) ON DELETE SET NULL,
    vehicle_id      INTEGER REFERENCES vehicles(id) ON DELETE SET NULL,
    service_type    VARCHAR(20) NOT NULL CHECK (service_type IN ('self_drive','on_demand')),
    status          VARCHAR(20) NOT NULL DEFAULT 'pending'
                    CHECK (status IN ('pending','confirmed','in_progress','completed','cancelled')),
    pickup_address  TEXT NOT NULL,
    pickup_lat      DOUBLE PRECISION NOT NULL,
    pickup_lng      DOUBLE PRECISION NOT NULL,
    dropoff_address TEXT NOT NULL,
    dropoff_lat     DOUBLE PRECISION NOT NULL,
    dropoff_lng     DOUBLE PRECISION NOT NULL,
    distance_km     NUMERIC(8,2),
    scheduled_at    TIMESTAMPTZ,
    started_at      TIMESTAMPTZ,
    completed_at    TIMESTAMPTZ,
    estimated_fare  NUMERIC(10,2) NOT NULL,
    final_fare      NUMERIC(10,2),
    surge_multiplier NUMERIC(4,2) NOT NULL DEFAULT 1.00,
    customer_rating NUMERIC(3,2),
    driver_rating   NUMERIC(3,2),
    review_text     TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Payments
CREATE TABLE IF NOT EXISTS payments (
    id                  SERIAL PRIMARY KEY,
    booking_id          INTEGER UNIQUE NOT NULL REFERENCES bookings(id) ON DELETE CASCADE,
    gateway_order_id    VARCHAR(120) UNIQUE,
    gateway_payment_id  VARCHAR(120),
    gateway_signature   TEXT,
    method              VARCHAR(20) NOT NULL CHECK (method IN ('razorpay','stripe','upi','cash')),
    amount              NUMERIC(10,2) NOT NULL,
    currency            VARCHAR(5) NOT NULL DEFAULT 'INR',
    status              VARCHAR(20) NOT NULL DEFAULT 'pending'
                        CHECK (status IN ('pending','completed','failed','refunded')),
    receipt             VARCHAR(80),
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_bookings_customer_id ON bookings(customer_id);
CREATE INDEX IF NOT EXISTS idx_bookings_driver_id   ON bookings(driver_id);
CREATE INDEX IF NOT EXISTS idx_bookings_status      ON bookings(status);
CREATE INDEX IF NOT EXISTS idx_drivers_is_online    ON drivers(is_online);
CREATE INDEX IF NOT EXISTS idx_payments_order_id    ON payments(gateway_order_id);
CREATE INDEX IF NOT EXISTS idx_users_email          ON users(email);

-- Seed default admin account (password: Admin@12345)
INSERT INTO users (name, email, phone, password_hash, role)
VALUES (
    'Super Admin',
    'admin@mobilityai.com',
    '9000000000',
    '$2b$12$K9H8Q0wC5D2pVx3tY.vJuO8L4Gq6yF7E1dZ9xM2jS5nR3aWbI0ce',
    'admin'
) ON CONFLICT (email) DO NOTHING;
