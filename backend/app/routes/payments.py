"""
Payments API — Razorpay order creation, secure webhook verification, status lookup.
"""
import hashlib
import hmac
import time
from flask import Blueprint, request, jsonify, current_app
from flask_jwt_extended import jwt_required, get_jwt_identity
from app.extensions import db
from app.models import Booking, Payment, PaymentStatus, PaymentMethod, BookingStatus

payments_bp = Blueprint("payments", __name__)


# ─────────────────────────────────────────────────────────────────
# Razorpay helpers
# ─────────────────────────────────────────────────────────────────

def _get_razorpay_client():
    import razorpay
    client = razorpay.Client(
        auth=(
            current_app.config["RAZORPAY_KEY_ID"],
            current_app.config["RAZORPAY_KEY_SECRET"],
        )
    )
    return client


def _verify_razorpay_signature(order_id: str, payment_id: str, signature: str) -> bool:
    secret = current_app.config["RAZORPAY_KEY_SECRET"].encode("utf-8")
    message = f"{order_id}|{payment_id}".encode("utf-8")
    expected = hmac.new(secret, message, hashlib.sha256).hexdigest()
    return hmac.compare_digest(expected, signature)


# ─────────────────────────────────────────────────────────────────
# Endpoints
# ─────────────────────────────────────────────────────────────────

@payments_bp.post("/create-order")
@jwt_required()
def create_order():
    """
    Create a Razorpay order for a confirmed booking.
    Body: { "booking_id": <int>, "payment_method": "razorpay" }
    """
    customer_id = int(get_jwt_identity())
    data = request.get_json(silent=True) or {}

    booking_id = data.get("booking_id")
    if not booking_id:
        return jsonify({"success": False, "message": "'booking_id' is required."}), 400

    booking = Booking.query.get(booking_id)
    if not booking:
        return jsonify({"success": False, "message": "Booking not found."}), 404
    if booking.customer_id != customer_id:
        return jsonify({"success": False, "message": "Access denied."}), 403
    if booking.status not in (BookingStatus.confirmed, BookingStatus.pending):
        return jsonify({"success": False, "message": "Booking is not in a payable state."}), 400

    # Check if payment already exists
    existing = Payment.query.filter_by(booking_id=booking_id).first()
    if existing and existing.status == PaymentStatus.completed:
        return jsonify({"success": False, "message": "Booking already paid."}), 409

    method_str = data.get("payment_method", "razorpay")
    try:
        method = PaymentMethod(method_str)
    except ValueError:
        return jsonify({"success": False, "message": "Invalid payment_method."}), 400

    amount_paise = int(booking.estimated_fare * 100)  # Razorpay uses paise
    receipt = f"rcpt_{booking.booking_ref}"

    try:
        client = _get_razorpay_client()
        rz_order = client.order.create({
            "amount": amount_paise,
            "currency": "INR",
            "receipt": receipt,
            "payment_capture": 1,
            "notes": {
                "booking_ref": booking.booking_ref,
                "customer_id": customer_id,
            },
        })
    except Exception as exc:
        current_app.logger.error("Razorpay order creation failed: %s", exc)
        return jsonify({"success": False, "message": "Payment gateway error. Try again."}), 502

    # Upsert payment record
    if existing:
        existing.gateway_order_id = rz_order["id"]
        existing.amount = booking.estimated_fare
        existing.method = method
        existing.receipt = receipt
    else:
        payment = Payment(
            booking_id=booking.id,
            gateway_order_id=rz_order["id"],
            method=method,
            amount=booking.estimated_fare,
            currency="INR",
            status=PaymentStatus.pending,
            receipt=receipt,
        )
        db.session.add(payment)

    db.session.commit()

    return jsonify({
        "success": True,
        "order_id": rz_order["id"],
        "amount": amount_paise,
        "currency": "INR",
        "key_id": current_app.config["RAZORPAY_KEY_ID"],
        "booking_ref": booking.booking_ref,
        "receipt": receipt,
    }), 200


@payments_bp.post("/verify")
@jwt_required()
def verify_payment():
    """
    Called from the Flutter app after Razorpay SDK returns success.
    Verifies signature and marks payment completed.
    Body: { "razorpay_order_id", "razorpay_payment_id", "razorpay_signature" }
    """
    data = request.get_json(silent=True) or {}
    order_id = data.get("razorpay_order_id", "")
    payment_id = data.get("razorpay_payment_id", "")
    signature = data.get("razorpay_signature", "")

    if not all([order_id, payment_id, signature]):
        return jsonify({"success": False, "message": "razorpay_order_id, razorpay_payment_id, razorpay_signature required."}), 400

    if not _verify_razorpay_signature(order_id, payment_id, signature):
        return jsonify({"success": False, "message": "Signature verification failed. Payment rejected."}), 400

    payment = Payment.query.filter_by(gateway_order_id=order_id).first()
    if not payment:
        return jsonify({"success": False, "message": "Payment record not found."}), 404

    payment.gateway_payment_id = payment_id
    payment.gateway_signature = signature
    payment.status = PaymentStatus.completed

    # Update booking status
    booking = payment.booking
    if booking:
        booking.status = BookingStatus.confirmed

    db.session.commit()

    # Send SMS confirmation
    _send_booking_sms(booking)

    return jsonify({
        "success": True,
        "message": "Payment verified and booking confirmed.",
        "payment": payment.to_dict(),
        "booking": booking.to_dict() if booking else None,
    }), 200


@payments_bp.post("/webhook")
def razorpay_webhook():
    """
    Secure server-side webhook endpoint for Razorpay.
    Validates X-Razorpay-Signature header before processing.
    """
    payload_bytes = request.get_data()
    signature = request.headers.get("X-Razorpay-Signature", "")
    webhook_secret = current_app.config.get("RAZORPAY_KEY_SECRET", "")

    # Verify webhook signature
    expected_sig = hmac.new(
        webhook_secret.encode("utf-8"),
        payload_bytes,
        hashlib.sha256,
    ).hexdigest()

    if not hmac.compare_digest(expected_sig, signature):
        current_app.logger.warning("Razorpay webhook: invalid signature from %s", request.remote_addr)
        return jsonify({"error": "Invalid signature"}), 400

    event = request.get_json(force=True, silent=True) or {}
    event_type = event.get("event", "")
    current_app.logger.info("Razorpay webhook event: %s", event_type)

    if event_type == "payment.captured":
        payload = event.get("payload", {}).get("payment", {}).get("entity", {})
        order_id = payload.get("order_id")
        payment_id = payload.get("id")

        payment = Payment.query.filter_by(gateway_order_id=order_id).first()
        if payment and payment.status != PaymentStatus.completed:
            payment.gateway_payment_id = payment_id
            payment.status = PaymentStatus.completed
            if payment.booking:
                payment.booking.status = BookingStatus.confirmed
            db.session.commit()
            current_app.logger.info("Webhook: payment %s marked completed for order %s", payment_id, order_id)

    elif event_type == "payment.failed":
        payload = event.get("payload", {}).get("payment", {}).get("entity", {})
        order_id = payload.get("order_id")
        payment = Payment.query.filter_by(gateway_order_id=order_id).first()
        if payment:
            payment.status = PaymentStatus.failed
            db.session.commit()

    elif event_type == "refund.created":
        payload = event.get("payload", {}).get("refund", {}).get("entity", {})
        payment_id = payload.get("payment_id")
        payment = Payment.query.filter_by(gateway_payment_id=payment_id).first()
        if payment:
            payment.status = PaymentStatus.refunded
            db.session.commit()

    return jsonify({"status": "ok"}), 200


@payments_bp.get("/status/<int:booking_id>")
@jwt_required()
def payment_status(booking_id: int):
    customer_id = int(get_jwt_identity())
    booking = Booking.query.get(booking_id)
    if not booking:
        return jsonify({"success": False, "message": "Booking not found."}), 404
    if booking.customer_id != customer_id:
        return jsonify({"success": False, "message": "Access denied."}), 403

    payment = Payment.query.filter_by(booking_id=booking_id).first()
    if not payment:
        return jsonify({"success": False, "message": "No payment record found."}), 404

    return jsonify({"success": True, "payment": payment.to_dict()}), 200


# ─────────────────────────────────────────────────────────────────
# Internal helpers
# ─────────────────────────────────────────────────────────────────

def _send_booking_sms(booking):
    """Send booking confirmation SMS via Fast2SMS. Errors are swallowed."""
    try:
        import requests as req
        from flask import current_app as app
        api_key = app.config.get("FAST2SMS_API_KEY", "")
        if not api_key or not booking:
            return
        phone = booking.customer.phone if booking.customer else None
        if not phone:
            return
        message = (
            f"Hi {booking.customer.name}, your booking {booking.booking_ref} is confirmed! "
            f"Pickup: {booking.pickup_address}. Fare: INR {booking.estimated_fare:.0f}. "
            f"Thank you for using Mobility Platform."
        )
        req.get(
            "https://www.fast2sms.com/dev/bulkV2",
            headers={"authorization": api_key},
            params={"route": "q", "numbers": phone, "message": message},
            timeout=5,
        )
    except Exception:
        pass
