# Mobility Platform Autonomous Agent Rules

## Trigger: "mobility app"
Whenever the user says or types **"mobility app"** (or phrases such as "run mobility app", "start mobility app", "open mobility app"):
1. Navigate to the project directory: `C:\Users\RAJAVEL\Desktop\mobility_project`.
2. Check if the local development server is running on `http://127.0.0.1:8000`. If not running, start `python app.py` in the background with `FLASK_DEBUG=1`.
3. Verify that `http://127.0.0.1:8000/api/health` is responding.
4. Launch Google Chrome and navigate to `http://127.0.0.1:8000`.
5. Confirm to the user that the server is live with real-time hot-reloading active and Google Chrome is open.
