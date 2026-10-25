"""
Configuration classes for different deployment environments.
"""
import os
from datetime import timedelta
from dotenv import load_dotenv

load_dotenv()


class BaseConfig:
    # ── Core ──────────────────────────────────────────────────────
    SECRET_KEY: str = os.getenv("SECRET_KEY", "dev-secret-change-in-production")
    DEBUG: bool = False
    TESTING: bool = False

    # ── Database ──────────────────────────────────────────────────
    _raw_db_url = os.getenv("DATABASE_URL")
    if _raw_db_url and _raw_db_url.startswith("postgres://"):
        _raw_db_url = "postgresql://" + _raw_db_url[len("postgres://"):]
    SQLALCHEMY_DATABASE_URI: str = _raw_db_url or (
        f"postgresql://{os.getenv('PGUSER', os.getenv('DB_USER', 'postgres'))}:"
        f"{os.getenv('PGPASSWORD', os.getenv('DB_PASSWORD', ''))}@"
        f"{os.getenv('PGHOST', os.getenv('DB_HOST', 'localhost'))}:"
        f"{os.getenv('PGPORT', os.getenv('DB_PORT', '5432'))}/"
        f"{os.getenv('PGDATABASE', os.getenv('DB_NAME', 'mobility_db'))}"
    )
    SQLALCHEMY_TRACK_MODIFICATIONS: bool = False
    SQLALCHEMY_ECHO: bool = False
    SQLALCHEMY_ENGINE_OPTIONS = {
        "pool_pre_ping": True,
        "pool_recycle": 300,
        "pool_size": 10,
        "max_overflow": 20,
    }

    # ── JWT ───────────────────────────────────────────────────────
    JWT_SECRET_KEY: str = os.getenv("JWT_SECRET_KEY", "jwt-secret-change-me")
    JWT_ACCESS_TOKEN_EXPIRES: timedelta = timedelta(hours=1)
    JWT_REFRESH_TOKEN_EXPIRES: timedelta = timedelta(days=30)
    JWT_TOKEN_LOCATION: list = ["headers"]
    JWT_HEADER_NAME: str = "Authorization"
    JWT_HEADER_TYPE: str = "Bearer"

    # ── CORS ──────────────────────────────────────────────────────
    _raw_origins = os.getenv("ALLOWED_ORIGINS", "*")
    ALLOWED_ORIGINS: list = (
        [o.strip() for o in _raw_origins.split(",") if o.strip()]
        if _raw_origins != "*"
        else ["*"]
    )

    # ── Razorpay ──────────────────────────────────────────────────
    RAZORPAY_KEY_ID: str = os.getenv("RAZORPAY_KEY_ID", "")
    RAZORPAY_KEY_SECRET: str = os.getenv("RAZORPAY_KEY_SECRET", "")

    # ── Stripe ────────────────────────────────────────────────────
    STRIPE_SECRET_KEY: str = os.getenv("STRIPE_SECRET_KEY", "")
    STRIPE_WEBHOOK_SECRET: str = os.getenv("STRIPE_WEBHOOK_SECRET", "")

    # ── SMS ───────────────────────────────────────────────────────
    FAST2SMS_API_KEY: str = os.getenv("FAST2SMS_API_KEY", "")

    # ── Maps ──────────────────────────────────────────────────────
    GOOGLE_MAPS_API_KEY: str = os.getenv("GOOGLE_MAPS_API_KEY", "")


class DevelopmentConfig(BaseConfig):
    DEBUG = True
    SQLALCHEMY_ECHO = True


class ProductionConfig(BaseConfig):
    DEBUG = False
    SQLALCHEMY_ECHO = False


class TestingConfig(BaseConfig):
    TESTING = True
    SQLALCHEMY_DATABASE_URI = "sqlite:///:memory:"
    JWT_ACCESS_TOKEN_EXPIRES = timedelta(minutes=5)
