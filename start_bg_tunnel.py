"""start_bg_tunnel.py — Launch Cloudflare Tunnel as a detached background process."""
import os, sys, time, re, subprocess, json

PROJECT_DIR = r"C:\Users\RAJAVEL\Desktop\mobility_project"
CLOUDFLARED = os.path.join(PROJECT_DIR, "cloudflared.exe")
LOG_FILE = os.path.join(PROJECT_DIR, "cf_tunnel.log")
URL_FILE = os.path.join(PROJECT_DIR, "tunnel_url.txt")

DETACHED_PROCESS = 0x00000008
CREATE_NEW_PROCESS_GROUP = 0x00000200

def launch():
    if os.path.exists(LOG_FILE):
        try:
            os.remove(LOG_FILE)
        except Exception:
            pass

    log_handle = open(LOG_FILE, "a", encoding="utf-8")
    
    cmd = [CLOUDFLARED, "tunnel", "--protocol", "http2", "--url", "http://127.0.0.1:8000"]
    proc = subprocess.Popen(
        cmd,
        stdout=log_handle,
        stderr=subprocess.STDOUT,
        cwd=PROJECT_DIR,
        creationflags=DETACHED_PROCESS | CREATE_NEW_PROCESS_GROUP,
        close_fds=True
    )
    
    print(f"[+] Detached Cloudflare Tunnel launched (PID: {proc.pid})")
    
    tunnel_url = None
    pattern = re.compile(r'https://[a-zA-Z0-9-]+\.trycloudflare\.com')
    
    for _ in range(25):
        time.sleep(0.6)
        if os.path.exists(LOG_FILE):
            with open(LOG_FILE, "r", encoding="utf-8", errors="ignore") as f:
                content = f.read()
                m = pattern.search(content)
                if m:
                    tunnel_url = m.group(0)
                    break
                    
    if tunnel_url:
        print(f"[+] Active Public Tunnel URL: {tunnel_url}")
        with open(URL_FILE, "w", encoding="utf-8") as f:
            f.write(tunnel_url.strip())
            
        cfg = {
            "api_url": tunnel_url.strip(),
            "updated_at": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
            "status": "online"
        }
        for dest in ["api_config.json", "web/api_config.json", "build/web/api_config.json"]:
            full_dest = os.path.join(PROJECT_DIR, dest)
            d = os.path.dirname(full_dest)
            if d:
                os.makedirs(d, exist_ok=True)
            with open(full_dest, "w", encoding="utf-8") as f:
                json.dump(cfg, f, indent=2)
                
        return tunnel_url
    else:
        print("[-] Could not parse tunnel URL in time. Check cf_tunnel.log.")
        return None

if __name__ == "__main__":
    launch()
