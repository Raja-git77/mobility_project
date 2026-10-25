"""Flask-SocketIO real-time location tracking events."""
from flask_socketio import join_room, leave_room, emit
from flask import request


def register_location_events(socketio):
    """Register all Socket.IO event handlers on the /tracking namespace."""

    @socketio.on("connect", namespace="/tracking")
    def on_connect():
        print(f"[SocketIO] Client connected: {request.sid}")
        emit("connected", {"message": "Connected to tracking server.", "sid": request.sid})

    @socketio.on("disconnect", namespace="/tracking")
    def on_disconnect():
        print(f"[SocketIO] Client disconnected: {request.sid}")

    @socketio.on("join_booking_room", namespace="/tracking")
    def on_join_booking_room(data):
        """
        Customer or driver joins a room identified by booking_id.
        Payload: { "booking_id": <int> }
        """
        booking_id = data.get("booking_id")
        if not booking_id:
            emit("error", {"message": "booking_id required to join room."})
            return
        room = f"booking_{booking_id}"
        join_room(room)
        emit("room_joined", {"room": room, "booking_id": booking_id})
        print(f"[SocketIO] {request.sid} joined room {room}")

    @socketio.on("leave_booking_room", namespace="/tracking")
    def on_leave_booking_room(data):
        booking_id = data.get("booking_id")
        if booking_id:
            room = f"booking_{booking_id}"
            leave_room(room)
            emit("room_left", {"room": room})

    @socketio.on("driver_location", namespace="/tracking")
    def on_driver_location(data):
        """
        Driver broadcasts live GPS coordinates.
        Payload: { "booking_id": <int>, "driver_id": <int>, "lat": float, "lng": float }
        Room: all clients subscribed to booking_<id> receive the update.
        """
        booking_id = data.get("booking_id")
        driver_id = data.get("driver_id")
        lat = data.get("lat")
        lng = data.get("lng")

        if not all([booking_id, driver_id, lat is not None, lng is not None]):
            emit("error", {"message": "booking_id, driver_id, lat, lng required."})
            return

        room = f"booking_{booking_id}"
        # Broadcast to everyone in the booking room (including customer)
        socketio.emit(
            "driver_location_update",
            {"driver_id": driver_id, "lat": lat, "lng": lng, "booking_id": booking_id},
            room=room,
            namespace="/tracking",
            include_self=False,
        )

    @socketio.on("trip_status_update", namespace="/tracking")
    def on_trip_status_update(data):
        """
        Driver or system broadcasts trip status changes.
        Payload: { "booking_id": <int>, "status": str, "message": str }
        """
        booking_id = data.get("booking_id")
        status = data.get("status")
        if not booking_id or not status:
            emit("error", {"message": "booking_id and status required."})
            return
        room = f"booking_{booking_id}"
        socketio.emit(
            "trip_status_changed",
            {"booking_id": booking_id, "status": status, "message": data.get("message", "")},
            room=room,
            namespace="/tracking",
        )

    @socketio.on("customer_ping", namespace="/tracking")
    def on_customer_ping(data):
        """Heartbeat ping from customer; respond with pong."""
        emit("pong", {"booking_id": data.get("booking_id")})
