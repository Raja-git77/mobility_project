"""
Application factory and entry-point for the AI Mobility Platform backend.
"""
import os
from flask import Flask
from flask_cors import CORS
from flask_jwt_extended import JWTManager
from flask_bcrypt import Bcrypt
from flask_migrate import Migrate
from flask_socketio import SocketIO

from app.extensions import db, jwt, bcrypt, socketio
from app.routes.auth import auth_bp
from app.routes.vehicles import vehicles_bp
from app.routes.bookings import bookings_bp
from app.routes.drivers import drivers_bp
from app.routes.payments import payments_bp
from app.routes.ai_routes import ai_bp
from app.sockets.location import register_location_events


def create_app(config_object: str = "app.config.DevelopmentConfig") -> Flask:
    app = Flask(__name__, instance_relative_config=False)
    app.config.from_object(config_object)

    # ── Extension init ──────────────────────────────────────────
    db.init_app(app)
    jwt.init_app(app)
    bcrypt.init_app(app)
    CORS(
        app,
        resources={r"/api/*": {"origins": app.config["ALLOWED_ORIGINS"]}},
        supports_credentials=True,
    )
    Migrate(app, db)
    socketio.init_app(
        app,
        cors_allowed_origins="*",
        async_mode="eventlet",
        logger=False,
        engineio_logger=False,
    )

    # ── Blueprints ──────────────────────────────────────────────
    app.register_blueprint(auth_bp, url_prefix="/api/auth")
    app.register_blueprint(vehicles_bp, url_prefix="/api/vehicles")
    app.register_blueprint(bookings_bp, url_prefix="/api/bookings")
    app.register_blueprint(drivers_bp, url_prefix="/api/drivers")
    app.register_blueprint(payments_bp, url_prefix="/api/payment")
    app.register_blueprint(ai_bp, url_prefix="/api/ai")

    # ── Socket.IO events ────────────────────────────────────────
    register_location_events(socketio)

    # ── Health check ─────────────────────────────────────────────
    @app.get("/api/health")
    def health():
        return {
            "status": "online",
            "service": "AI Integrated Mobility Platform",
            "version": "2.0.0",
        }

    # ── Create tables on first run ──────────────────────────────
    with app.app_context():
        db.create_all()

    return app
