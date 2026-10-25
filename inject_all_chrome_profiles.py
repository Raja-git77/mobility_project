"""inject_all_chrome_profiles.py — Injects 'mobility' keyword across all Chrome profiles."""
import os, sys, sqlite3, time, uuid

def inject_profiles():
    # 1. Close Chrome
    print("[*] Closing running Chrome instances...")
    os.system("taskkill /F /IM chrome.exe >nul 2>&1")
    time.sleep(1.5)

    user_data = os.path.expandvars(r"%LOCALAPPDATA%\Google\Chrome\User Data")
    if not os.path.exists(user_data):
        print(f"[-] User Data not found: {user_data}")
        return

    # Find all profile folders with 'Web Data'
    profile_dirs = []
    for item in os.listdir(user_data):
        full_p = os.path.join(user_data, item)
        if os.path.isdir(full_p):
            web_data = os.path.join(full_p, "Web Data")
            if os.path.exists(web_data):
                profile_dirs.append(full_p)

    print(f"[*] Found {len(profile_dirs)} Chrome profile(s) with Web Data: {[os.path.basename(p) for p in profile_dirs]}")

    now = int(time.time())
    keywords_to_add = [
        ("Mobility App", "mobility", "http://127.0.0.1:8000/?q={searchTerms}"),
        ("Mobility App", "mobility app", "http://127.0.0.1:8000/?q={searchTerms}"),
        ("Mobility App Direct", "mobilityapp", "http://127.0.0.1:8000/"),
    ]

    for p_dir in profile_dirs:
        web_data = os.path.join(p_dir, "Web Data")
        p_name = os.path.basename(p_dir)
        try:
            conn = sqlite3.connect(web_data, timeout=5)
            cursor = conn.cursor()

            for short_name, kw, url in keywords_to_add:
                cursor.execute("DELETE FROM keywords WHERE keyword = ?", (kw,))
                guid = str(uuid.uuid4())
                cursor.execute("""
                    INSERT INTO keywords (
                        short_name, keyword, favicon_url, url, safe_for_autoreplace,
                        originating_url, date_created, usage_count, input_encodings,
                        suggest_url, prepopulate_id, created_by_policy, last_modified,
                        sync_guid, is_active
                    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                """, (
                    short_name, kw, "http://127.0.0.1:8000/favicon.png", url, 1,
                    "", now, 100, "UTF-8",
                    "", 0, 0, now,
                    guid, 1
                ))
            conn.commit()
            conn.close()
            print(f"[+] Successfully injected into profile '{p_name}'")
        except Exception as e:
            print(f"[-] Could not update profile '{p_name}': {e}")

    print("[*] Omnibox keyword injection complete.")

if __name__ == "__main__":
    inject_profiles()
