"""
SQLAlchemy models: User, Vehicle, Booking, Payment, DriverLocation.
"""
import enum
from datetime import datetime
from app.extensions import db


# ─────────────────────────────────────────────────────────────────
# Enumerations
# ─────────────────────────────────────────────────────────────────

class UserRole(str, enum.Enum):
    admin = "admin"
    customer = "customer"
    driver = "driver"


class VehicleCategory(str, enum.Enum):
    sedan = "sedan"
    suv = "suv"
    hatchback = "hatchback"
    bike = "bike"
    auto = "auto"
    luxury = "luxury"


class VehicleStatus(str, enum.Enum):
    available = "available"
    booked = "booked"
    maintenance = "maintenance"


class BookingStatus(str, enum.Enum):
    pending = "pending"
    confirmed = "confirmed"
    in_progress = "in_progress"
    completed = "completed"
    cancelled = "cancelled"


class ServiceType(str, enum.Enum):
    self_drive = "self_drive"
    on_demand = "on_demand"


class PaymentStatus(str, enum.Enum):
    pending = "pending"
    completed = "completed"
    failed = "failed"
    refunded = "refunded"


class PaymentMethod(str, enum.Enum):
    razorpay = "razorpay"
    stripe = "stripe"
    upi = "upi"
    cash = "cash"


# ─────────────────────────────────────────────────────────────────
# Users
# ─────────────────────────────────────────────────────────────────

class User(db.Model):
    __tablename__ = "users"

    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(120), nullable=False)
    email = db.Column(db.String(180), unique=True, nullable=False, index=True)
    phone = db.Column(db.String(20), unique=True, nullable=False)
    password_hash = db.Column(db.Text, nullable=False)
    role = db.Column(db.Enum(UserRole), nullable=False, default=UserRole.customer)
    is_active = db.Column(db.Boolean, default=True, nullable=False)
    profile_picture_url = db.Column(db.Text, nullable=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationships
    bookings = db.relationship("Booking", foreign_keys="Booking.customer_id", back_populates="customer", lazy="dynamic")
    driver_profile = db.relationship("Driver", back_populates="user", uselist=False, cascade="all, delete-orphan")

    def to_dict(self):
        return {
            "id": self.id,
            "name": self.name,
            "email": self.email,
            "phone": self.phone,
            "role": self.role.value,
            "is_active": self.is_active,
            "profile_picture_url": self.profile_picture_url,
            "created_at": self.created_at.isoformat(),
        }


# ─────────────────────────────────────────────────────────────────
# Driver Profile
# ─────────────────────────────────────────────────────────────────

class Driver(db.Model):
    __tablename__ = "drivers"

    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey("users.id", ondelete="CASCADE"), unique=True, nullable=False)
    license_number = db.Column(db.String(50), unique=True, nullable=False)
    vehicle_id = db.Column(db.Integer, db.ForeignKey("vehicles.id", ondelete="SET NULL"), nullable=True)
    rating = db.Column(db.Float, default=5.0, nullable=False)
    total_rides = db.Column(db.Integer, default=0, nullable=False)
    is_online = db.Column(db.Boolean, default=False, nullable=False)
    current_lat = db.Column(db.Float, nullable=True)
    current_lng = db.Column(db.Float, nullable=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    # Relationships
    user = db.relationship("User", back_populates="driver_profile")
    vehicle = db.relationship("Vehicle", back_populates="current_driver", foreign_keys=[vehicle_id])
    bookings = db.relationship("Booking", foreign_keys="Booking.driver_id", back_populates="driver", lazy="dynamic")

    def to_dict(self):
        return {
            "id": self.id,
            "user_id": self.user_id,
            "name": self.user.name if self.user else None,
            "phone": self.user.phone if self.user else None,
            "license_number": self.license_number,
            "vehicle_id": self.vehicle_id,
            "rating": self.rating,
            "total_rides": self.total_rides,
            "is_online": self.is_online,
            "current_lat": self.current_lat,
            "current_lng": self.current_lng,
        }


# ─────────────────────────────────────────────────────────────────
# Vehicle
# ─────────────────────────────────────────────────────────────────

class Vehicle(db.Model):
    __tablename__ = "vehicles"

    id = db.Column(db.Integer, primary_key=True)
    make = db.Column(db.String(80), nullable=False)
    model = db.Column(db.String(80), nullable=False)
    year = db.Column(db.Integer, nullable=False)
    registration_number = db.Column(db.String(30), unique=True, nullable=False)
    category = db.Column(db.Enum(VehicleCategory), nullable=False)
    status = db.Column(db.Enum(VehicleStatus), default=VehicleStatus.available, nullable=False)
    seats = db.Column(db.Integer, default=4, nullable=False)
    fuel_type = db.Column(db.String(30), default="petrol", nullable=False)
    transmission = db.Column(db.String(20), default="manual", nullable=False)
    base_fare_per_km = db.Column(db.Float, nullable=False, default=12.0)
    image_url = db.Column(db.Text, nullable=True)
    features = db.Column(db.JSON, default=list)
    current_lat = db.Column(db.Float, nullable=True)
    current_lng = db.Column(db.Float, nullable=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationships
    current_driver = db.relationship("Driver", back_populates="vehicle", foreign_keys="Driver.vehicle_id")
    bookings = db.relationship("Booking", back_populates="vehicle", lazy="dynamic")

    def to_dict(self):
        return {
            "id": self.id,
            "make": self.make,
            "model": self.model,
            "year": self.year,
            "registration_number": self.registration_number,
            "category": self.category.value,
            "status": self.status.value,
            "seats": self.seats,
            "fuel_type": self.fuel_type,
            "transmission": self.transmission,
            "base_fare_per_km": self.base_fare_per_km,
            "image_url": self.image_url,
            "features": self.features or [],
            "current_lat": self.current_lat,
            "current_lng": self.current_lng,
        }


# ─────────────────────────────────────────────────────────────────
# Booking
# ─────────────────────────────────────────────────────────────────

class Booking(db.Model):
    __tablename__ = "bookings"

    id = db.Column(db.Integer, primary_key=True)
    booking_ref = db.Column(db.String(20), unique=True, nullable=False, index=True)
    customer_id = db.Column(db.Integer, db.ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    driver_id = db.Column(db.Integer, db.ForeignKey("drivers.id", ondelete="SET NULL"), nullable=True)
    vehicle_id = db.Column(db.Integer, db.ForeignKey("vehicles.id", ondelete="SET NULL"), nullable=True)
    service_type = db.Column(db.Enum(ServiceType), nullable=False)
    status = db.Column(db.Enum(BookingStatus), default=BookingStatus.pending, nullable=False)

    # Location
    pickup_address = db.Column(db.Text, nullable=False)
    pickup_lat = db.Column(db.Float, nullable=False)
    pickup_lng = db.Column(db.Float, nullable=False)
    dropoff_address = db.Column(db.Text, nullable=False)
    dropoff_lat = db.Column(db.Float, nullable=False)
    dropoff_lng = db.Column(db.Float, nullable=False)
    distance_km = db.Column(db.Float, nullable=True)

    # Timing
    scheduled_at = db.Column(db.DateTime, nullable=True)
    started_at = db.Column(db.DateTime, nullable=True)
    completed_at = db.Column(db.DateTime, nullable=True)

    # Fare
    estimated_fare = db.Column(db.Float, nullable=False)
    final_fare = db.Column(db.Float, nullable=True)
    surge_multiplier = db.Column(db.Float, default=1.0)

    # Rating
    customer_rating = db.Column(db.Float, nullable=True)
    driver_rating = db.Column(db.Float, nullable=True)
    review_text = db.Column(db.Text, nullable=True)

    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationships
    customer = db.relationship("User", foreign_keys=[customer_id], back_populates="bookings")
    driver = db.relationship("Driver", foreign_keys=[driver_id], back_populates="bookings")
    vehicle = db.relationship("Vehicle", back_populates="bookings")
    payment = db.relationship("Payment", back_populates="booking", uselist=False, cascade="all, delete-orphan")

    def to_dict(self):
        return {
            "id": self.id,
            "booking_ref": self.booking_ref,
            "customer_id": self.customer_id,
            "driver_id": self.driver_id,
            "vehicle_id": self.vehicle_id,
            "service_type": self.service_type.value,
            "status": self.status.value,
            "pickup_address": self.pickup_address,
            "pickup_lat": self.pickup_lat,
            "pickup_lng": self.pickup_lng,
            "dropoff_address": self.dropoff_address,
            "dropoff_lat": self.dropoff_lat,
            "dropoff_lng": self.dropoff_lng,
            "distance_km": self.distance_km,
            "scheduled_at": self.scheduled_at.isoformat() if self.scheduled_at else None,
            "started_at": self.started_at.isoformat() if self.started_at else None,
            "completed_at": self.completed_at.isoformat() if self.completed_at else None,
            "estimated_fare": self.estimated_fare,
            "final_fare": self.final_fare,
            "surge_multiplier": self.surge_multiplier,
            "customer_rating": self.customer_rating,
            "created_at": self.created_at.isoformat(),
        }


# ─────────────────────────────────────────────────────────────────
# Payment
# ─────────────────────────────────────────────────────────────────

class Payment(db.Model):
    __tablename__ = "payments"

    id = db.Column(db.Integer, primary_key=True)
    booking_id = db.Column(db.Integer, db.ForeignKey("bookings.id", ondelete="CASCADE"), unique=True, nullable=False)
    gateway_order_id = db.Column(db.String(120), unique=True, nullable=True, index=True)
    gateway_payment_id = db.Column(db.String(120), nullable=True)
    gateway_signature = db.Column(db.Text, nullable=True)
    method = db.Column(db.Enum(PaymentMethod), nullable=False)
    amount = db.Column(db.Float, nullable=False)
    currency = db.Column(db.String(5), default="INR", nullable=False)
    status = db.Column(db.Enum(PaymentStatus), default=PaymentStatus.pending, nullable=False)
    receipt = db.Column(db.String(80), nullable=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationship
    booking = db.relationship("Booking", back_populates="payment")

    def to_dict(self):
        return {
            "id": self.id,
            "booking_id": self.booking_id,
            "gateway_order_id": self.gateway_order_id,
            "gateway_payment_id": self.gateway_payment_id,
            "method": self.method.value,
            "amount": self.amount,
            "currency": self.currency,
            "status": self.status.value,
            "receipt": self.receipt,
            "created_at": self.created_at.isoformat(),
        }
