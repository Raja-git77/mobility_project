"""manage_tunnel.py — Start and monitor Cloudflare Quick Tunnel for port 8000."""
import os, sys, time, re, subprocess, json, urllib.request

PROJECT_DIR = r"C:\Users\RAJAVEL\Desktop\mobility_project"
CLOUDFLARED = os.path.join(PROJECT_DIR, "cloudflared.exe")
TUNNEL_URL_FILE = os.path.join(PROJECT_DIR, "tunnel_url.txt")
TUNNEL_LOG_FILE = os.path.join(PROJECT_DIR, "cf_tunnel.log")

def get_live_tunnel_url(timeout=25):
    print("[*] Launching Cloudflare Tunnel (HTTP/2) for http://127.0.0.1:8000...")
    cmd = [CLOUDFLARED, "tunnel", "--protocol", "http2", "--url", "http://127.0.0.1:8000"]
    
    proc = subprocess.Popen(
        cmd,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        bufsize=1,
        cwd=PROJECT_DIR
    )
    
    tunnel_url = None
    start = time.time()
    pattern = re.compile(r'https://[a-zA-Z0-9-]+\.trycloudflare\.com')
    
    with open(TUNNEL_LOG_FILE, "w", encoding="utf-8") as log_f:
        while time.time() - start < timeout:
            line = proc.stdout.readline()
            if not line:
                if proc.poll() is not None:
                    break
                time.sleep(0.1)
                continue
            log_f.write(line)
            log_f.flush()
            m = pattern.search(line)
            if m:
                tunnel_url = m.group(0)
                break
                
    if tunnel_url:
        print(f"[+] Tunnel URL Established: {tunnel_url}")
        with open(TUNNEL_URL_FILE, "w", encoding="utf-8") as f:
            f.write(tunnel_url.strip())
            
        config = {
            "api_url": tunnel_url.strip(),
            "updated_at": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
            "status": "online"
        }
        for dest in [
            os.path.join(PROJECT_DIR, "api_config.json"),
            os.path.join(PROJECT_DIR, "web", "api_config.json"),
            os.path.join(PROJECT_DIR, "build", "web", "api_config.json")
        ]:
            os.makedirs(os.path.dirname(dest), exist_ok=True)
            with open(dest, "w", encoding="utf-8") as f:
                json.dump(config, f, indent=2)
                
        return tunnel_url, proc
    else:
        print("[-] Could not establish Cloudflare tunnel within timeout.")
        return None, proc

if __name__ == "__main__":
    url, proc = get_live_tunnel_url()
    if url:
        print(f"[*] Live Tunnel is running (PID: {proc.pid}). Testing /api/health...")
        time.sleep(2)
        try:
            with urllib.request.urlopen(f"{url}/api/health", timeout=5) as resp:
                print(f"[+] Health Check over Tunnel: HTTP {resp.status} - {resp.read().decode()}")
        except Exception as e:
            print(f"[!] Warning checking health over tunnel: {e}")
            
        # Keep running
        print("[*] Press Ctrl+C to stop tunnel.")
        try:
            proc.wait()
        except KeyboardInterrupt:
            proc.terminate()
