import os
import sys
import mimetypes
from http.server import ThreadingHTTPServer, SimpleHTTPRequestHandler

# Setup proper MIME types for Flutter Web & WASM
mimetypes.init()
mimetypes.add_type('application/javascript', '.js')
mimetypes.add_type('application/wasm', '.wasm')
mimetypes.add_type('application/json', '.json')
mimetypes.add_type('font/otf', '.otf')
mimetypes.add_type('font/ttf', '.ttf')
mimetypes.add_type('image/svg+xml', '.svg')
mimetypes.add_type('image/png', '.png')

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
WEB_DIR = os.path.join(SCRIPT_DIR, 'build', 'web')

if not os.path.exists(WEB_DIR):
    os.makedirs(WEB_DIR, exist_ok=True)

class FlutterWebHandler(SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=WEB_DIR, **kwargs)

    def end_headers(self):
        # Allow cross-origin and embedding in WhatsApp / mobile webviews
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS, HEAD')
        self.send_header('Access-Control-Allow-Headers', '*')
        self.send_header('Cross-Origin-Opener-Policy', 'same-origin-allow-popups')
        self.send_header('Cross-Origin-Embedder-Policy', 'credentialless')
        
        # Don't cache index or bootstrap to ensure fresh mobile updates
        if self.path in ['/', '/index.html', '/flutter_bootstrap.js']:
            self.send_header('Cache-Control', 'no-cache, no-store, must-revalidate')
        else:
            self.send_header('Cache-Control', 'public, max-age=3600')
        super().end_headers()

    def do_OPTIONS(self):
        self.send_response(200)
        self.end_headers()

    def do_GET(self):
        # If requested path does not exist on disk, fall back to index.html for SPA routing
        req_path = self.translate_path(self.path)
        if not os.path.exists(req_path) and not '.' in os.path.basename(self.path):
            self.path = '/index.html'
        return super().do_GET()

def run_server(host='0.0.0.0', port=8080):
    print(f"[*] Starting Multi-Threaded Mobile Server on {host}:{port}")
    print(f"[*] Serving files from: {WEB_DIR}")
    server = ThreadingHTTPServer((host, port), FlutterWebHandler)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\n[*] Server stopping...")
        server.server_close()

if __name__ == '__main__':
    port = 8080
    if len(sys.argv) > 1:
        try:
            port = int(sys.argv[1])
        except ValueError:
            pass
    run_server(port=port)
