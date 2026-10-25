import os
import sys
import time
import re
import subprocess
import socket

PROJECT_DIR = r"C:\Users\RAJAVEL\Desktop\mobility_project"
URL_FILE = os.path.join(PROJECT_DIR, "tunnel_url.txt")
LOG_FILE = os.path.join(PROJECT_DIR, "tunnel.log")

def get_wifi_ip():
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
        s.close()
        return ip
    except Exception:
        return "10.164.115.216"

def is_port_listening(port=8080):
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        return s.connect_ex(('127.0.0.1', port)) == 0

def start_server():
    if not is_port_listening(8080):
        print("[*] Starting serve_mobile.py on port 8080...")
        srv_script = os.path.join(PROJECT_DIR, "mobility_app", "serve_mobile.py")
        subprocess.Popen([sys.executable, srv_script], cwd=os.path.join(PROJECT_DIR, "mobility_app"))
        time.sleep(2)
    else:
        print("[*] Port 8080 server is already active.")

def run_tunnel():
    start_server()
    print("[*] Launching Cloudflare Tunnel (HTTP/2)...")
    
    cmd = ["npx.cmd", "--yes", "cloudflared", "tunnel", "--protocol", "http2", "--url", "http://127.0.0.1:8080"]
    
    with open(LOG_FILE, "w", encoding="utf-8") as log_f:
        proc = subprocess.Popen(
            cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            bufsize=1,
            cwd=PROJECT_DIR
        )

        found_url = None
        start_time = time.time()
        
        while time.time() - start_time < 30:
            line = proc.stdout.readline()
            if not line:
                break
            log_f.write(line)
            log_f.flush()
            print(line, end="")
            
            match = re.search(r'https://[a-zA-Z0-9-]+\.trycloudflare\.com', line)
            if match:
                found_url = match.group(0)
                with open(URL_FILE, "w", encoding="utf-8") as uf:
                    uf.write(found_url)
                print(f"\n[+] SUCCESS: Registered Public Tunnel: {found_url}\n")
                break

        if not found_url:
            print("[!] Cloudflare didn't return URL in 30s, attempting localhost.run fallback...")
            ssh_cmd = ["ssh", "-o", "StrictHostKeyChecking=no", "-R", "80:127.0.0.1:8080", "nokey@localhost.run"]
            ssh_proc = subprocess.Popen(ssh_cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, bufsize=1)
            for _ in range(15):
                s_line = ssh_proc.stdout.readline()
                if not s_line:
                    break
                print(s_line, end="")
                s_match = re.search(r'https://[a-zA-Z0-9-]+\.lhr\.life', s_line)
                if s_match:
                    found_url = s_match.group(0)
                    with open(URL_FILE, "w", encoding="utf-8") as uf:
                        uf.write(found_url)
                    print(f"\n[+] SUCCESS: Registered Fallback Tunnel: {found_url}\n")
                    break

        # Keep running process alive
        while True:
            line = proc.stdout.readline()
            if not line and proc.poll() is not None:
                break
            if line:
                log_f.write(line)
                log_f.flush()

if __name__ == '__main__':
    run_tunnel()
