"""
JWT Authentication routes: /register, /login, /refresh, /logout, /me
"""
import re
from flask import Blueprint, request, jsonify
from flask_jwt_extended import (
    create_access_token,
    create_refresh_token,
    jwt_required,
    get_jwt_identity,
    get_jwt,
)
from app.extensions import db, bcrypt
from app.models import User, UserRole

auth_bp = Blueprint("auth", __name__)

EMAIL_RE = re.compile(r"^[^@\s]+@[^@\s]+\.[^@\s]+$")
PHONE_RE = re.compile(r"^\+?[0-9]{10,15}$")


def _validate_register_payload(data: dict) -> str | None:
    """Return an error message string or None if valid."""
    if not data.get("name") or len(data["name"].strip()) < 2:
        return "Name must be at least 2 characters."
    if not EMAIL_RE.match(data.get("email", "")):
        return "Invalid email address."
    if not PHONE_RE.match(data.get("phone", "")):
        return "Invalid phone number. Must be 10-15 digits."
    if len(data.get("password", "")) < 8:
        return "Password must be at least 8 characters."
    if data.get("role") and data["role"] not in [r.value for r in UserRole]:
        return f"Invalid role. Choose from {[r.value for r in UserRole]}."
    return None


@auth_bp.post("/register")
def register():
    data = request.get_json(silent=True) or {}
    error = _validate_register_payload(data)
    if error:
        return jsonify({"success": False, "message": error}), 400

    # Duplicate checks
    if User.query.filter_by(email=data["email"].lower()).first():
        return jsonify({"success": False, "message": "Email already registered."}), 409
    if User.query.filter_by(phone=data["phone"]).first():
        return jsonify({"success": False, "message": "Phone number already registered."}), 409

    role = UserRole(data.get("role", UserRole.customer.value))
    # Prevent external callers from self-assigning admin
    if role == UserRole.admin:
        return jsonify({"success": False, "message": "Cannot self-register as admin."}), 403

    hashed_pw = bcrypt.generate_password_hash(data["password"]).decode("utf-8")
    user = User(
        name=data["name"].strip(),
        email=data["email"].lower().strip(),
        phone=data["phone"].strip(),
        password_hash=hashed_pw,
        role=role,
    )
    db.session.add(user)
    db.session.commit()

    access_token = create_access_token(identity=str(user.id), additional_claims={"role": role.value})
    refresh_token = create_refresh_token(identity=str(user.id))

    return jsonify({
        "success": True,
        "message": "Registration successful.",
        "access_token": access_token,
        "refresh_token": refresh_token,
        "user": user.to_dict(),
    }), 201


@auth_bp.post("/login")
def login():
    data = request.get_json(silent=True) or {}
    email = data.get("email", "").lower().strip()
    password = data.get("password", "")

    if not email or not password:
        return jsonify({"success": False, "message": "Email and password required."}), 400

    user = User.query.filter_by(email=email).first()
    if not user or not bcrypt.check_password_hash(user.password_hash, password):
        return jsonify({"success": False, "message": "Invalid credentials."}), 401
    if not user.is_active:
        return jsonify({"success": False, "message": "Account is deactivated. Contact support."}), 403

    access_token = create_access_token(
        identity=str(user.id),
        additional_claims={"role": user.role.value},
    )
    refresh_token = create_refresh_token(identity=str(user.id))

    return jsonify({
        "success": True,
        "message": "Login successful.",
        "access_token": access_token,
        "refresh_token": refresh_token,
        "user": user.to_dict(),
    }), 200


@auth_bp.post("/refresh")
@jwt_required(refresh=True)
def refresh():
    identity = get_jwt_identity()
    user = User.query.get(int(identity))
    if not user or not user.is_active:
        return jsonify({"success": False, "message": "User not found or inactive."}), 404
    access_token = create_access_token(
        identity=identity,
        additional_claims={"role": user.role.value},
    )
    return jsonify({"success": True, "access_token": access_token}), 200


@auth_bp.get("/me")
@jwt_required()
def me():
    identity = get_jwt_identity()
    user = User.query.get(int(identity))
    if not user:
        return jsonify({"success": False, "message": "User not found."}), 404
    return jsonify({"success": True, "user": user.to_dict()}), 200


@auth_bp.put("/me")
@jwt_required()
def update_profile():
    identity = get_jwt_identity()
    user = User.query.get(int(identity))
    if not user:
        return jsonify({"success": False, "message": "User not found."}), 404

    data = request.get_json(silent=True) or {}
    if "name" in data and len(data["name"].strip()) >= 2:
        user.name = data["name"].strip()
    if "phone" in data and PHONE_RE.match(data["phone"]):
        existing = User.query.filter_by(phone=data["phone"]).first()
        if existing and existing.id != user.id:
            return jsonify({"success": False, "message": "Phone already in use."}), 409
        user.phone = data["phone"]
    if "profile_picture_url" in data:
        user.profile_picture_url = data["profile_picture_url"]

    db.session.commit()
    return jsonify({"success": True, "user": user.to_dict()}), 200


@auth_bp.post("/change-password")
@jwt_required()
def change_password():
    identity = get_jwt_identity()
    user = User.query.get(int(identity))
    if not user:
        return jsonify({"success": False, "message": "User not found."}), 404

    data = request.get_json(silent=True) or {}
    old_pw = data.get("old_password", "")
    new_pw = data.get("new_password", "")

    if not bcrypt.check_password_hash(user.password_hash, old_pw):
        return jsonify({"success": False, "message": "Current password is incorrect."}), 401
    if len(new_pw) < 8:
        return jsonify({"success": False, "message": "New password must be at least 8 characters."}), 400

    user.password_hash = bcrypt.generate_password_hash(new_pw).decode("utf-8")
    db.session.commit()
    return jsonify({"success": True, "message": "Password changed successfully."}), 200
