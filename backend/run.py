"""
WSGI entry-point. Run with:
  eventlet:  python run.py
  gunicorn:  gunicorn -k eventlet -w 1 run:app
"""
import eventlet
eventlet.monkey_patch()

from app import create_app
from app.extensions import socketio

app = create_app("app.config.DevelopmentConfig")

if __name__ == "__main__":
    socketio.run(
        app,
        host="0.0.0.0",
        port=5000,
        debug=True,
        use_reloader=False,
    )
