"""add_chrome_keyword.py — Register 'mobility' and 'mobility app' in Chrome's Omnibox keywords."""
import sqlite3, os, time, uuid

def add_chrome_keywords():
    db_path = os.path.expandvars(r"%LOCALAPPDATA%\Google\Chrome\User Data\Default\Web Data")
    if not os.path.exists(db_path):
        print(f"[-] Chrome Web Data not found at: {db_path}")
        return False
        
    try:
        conn = sqlite3.connect(db_path, timeout=5)
        cursor = conn.cursor()
        
        keywords_to_add = [
            ("Mobility App", "mobility app", "http://127.0.0.1:8000/?q={searchTerms}"),
            ("Mobility App", "mobility", "http://127.0.0.1:8000/?q={searchTerms}"),
            ("Mobility App Web", "mobility.app", "http://127.0.0.1:8000/?q={searchTerms}"),
        ]
        
        now = int(time.time())
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
                short_name, kw, 'http://127.0.0.1:8000/favicon.png', url, 1,
                '', now, 100, 'UTF-8',
                '', 0, 0, now,
                guid, 1
            ))
            print(f"[+] Added Chrome Omnibox Keyword: '{kw}' -> {url}")
            
        conn.commit()
        conn.close()
        print("[+] Chrome Omnibox keywords successfully saved and committed!")
        return True
    except Exception as e:
        print(f"[-] Could not update Chrome Web Data directly: {e}")
        return False

if __name__ == "__main__":
    add_chrome_keywords()
