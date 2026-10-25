"""
chrome_watcher.py — Background watcher to auto-redirect 'mobility app' Google Searches in Chrome.
- Checks foreground window title every 200ms using ctypes.windll.user32.
- Whenever active window matches 'mobility app - Google Search' or 'mobility - Google Search',
  it sends Alt+D, types http://127.0.0.1:8000, and presses Enter via WScript.Shell.
- Tab immediately redirects into the live Mobility App in < 0.2s.
"""
import ctypes
import time
import os
import subprocess

user32 = ctypes.windll.user32

PROJECT_DIR = os.path.dirname(os.path.abspath(__file__))
VBS_PATH = os.path.join(PROJECT_DIR, "redirect_tab.vbs")
LOG_PATH = os.path.join(PROJECT_DIR, "chrome_watcher.log")

def log(msg):
    try:
        with open(LOG_PATH, "a", encoding="utf-8") as f:
            f.write(f"[{time.strftime('%Y-%m-%d %H:%M:%S')}] {msg}\n")
    except Exception:
        pass

def attach_to_default_desktop():
    try:
        hDesk = user32.OpenDesktopW("Default", 0, False, 0x01FF)
        if hDesk:
            user32.SetThreadDesktop(hDesk)
            user32.CloseDesktop(hDesk)
    except Exception:
        pass

def get_foreground_window():
    hwnd = user32.GetForegroundWindow()
    if not hwnd:
        return "", 0
    length = user32.GetWindowTextLengthW(hwnd)
    if length <= 0:
        return "", hwnd
    buff = ctypes.create_unicode_buffer(length + 1)
    user32.GetWindowTextW(hwnd, buff, length + 1)
    return buff.value, hwnd

def is_matching_title(title):
    t = title.lower()
    return (
        ("mobility app" in t and "google" in t and "search" in t) or
        ("mobility - google search" in t) or
        ("mobility app - google" in t) or
        ("mobility - google" in t) or
        (t.startswith("mobility") and "google search" in t)
    )

def redirect_active_tab():
    try:
        subprocess.run(["wscript", "//nologo", VBS_PATH], timeout=2)
        return True
    except Exception as e:
        log(f"Error executing redirect_tab.vbs: {e}")
        return False

def main():
    attach_to_default_desktop()
    log("Chrome Mobility Watcher started (200ms active window checking)")
    last_trigger = 0

    while True:
        try:
            attach_to_default_desktop()
            title, hwnd = get_foreground_window()
            if title and is_matching_title(title):
                now = time.time()
                # 2.5s debounce to prevent double-redirection during navigation
                if now - last_trigger > 2.5:
                    last_trigger = now
                    log(f"INTERCEPTED: '{title}' -> Redirecting tab to http://127.0.0.1:8000")
                    redirect_active_tab()

            time.sleep(0.2)
        except Exception as e:
            log(f"Watcher loop exception: {e}")
            time.sleep(0.5)

if __name__ == "__main__":
    main()
