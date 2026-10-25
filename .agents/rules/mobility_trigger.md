# Mobility App Autonomous Workflow Trigger

Whenever the user prompts with **"mobility app"**:
1. Check if the local development server at `C:\Users\RAJAVEL\Desktop\mobility_project` is active on port 8000 (`http://127.0.0.1:8000/api/health`).
2. If inactive, start `python app.py` with real-time live reload enabled (`FLASK_DEBUG=1`).
3. Automatically launch Google Chrome at `http://127.0.0.1:8000`.
4. Inform the user with the status of the server and the Chrome window.
