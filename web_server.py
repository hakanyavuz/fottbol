import http.server
import socketserver
import subprocess
import time
import json
import os
import sys

PORT = 8080
DIRECTORY = os.path.join(os.path.dirname(__file__), "build", "web")

# 30 saniyelik bellek önbelleği: aynı lig istekleri anında yanıtlanır
_CACHE = {}

class ThreadingHTTPServer(socketserver.ThreadingMixIn, http.server.HTTPServer):
    daemon_threads = True
    allow_reuse_address = True

class ProxyHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=DIRECTORY, **kwargs)

    def do_OPTIONS(self):
        self.send_response(200)
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', '*')
        self.end_headers()

    def do_GET(self):
        if self.path.startswith('/api/espn/'):
            subpath = self.path[len('/api/espn/'):]
            target_url = f"https://site.api.espn.com/apis/site/v2/sports/soccer/{subpath}"
            
            now = time.time()
            if target_url in _CACHE:
                cached_data, cached_time = _CACHE[target_url]
                if now - cached_time < 30:
                    self.send_response(200)
                    self.send_header('Content-Type', 'application/json; charset=utf-8')
                    self.send_header('Access-Control-Allow-Origin', '*')
                    self.end_headers()
                    self.wfile.write(cached_data)
                    return

            try:
                result = subprocess.run(
                    ['curl.exe', '-s', '--max-time', '8', target_url],
                    capture_output=True,
                    check=True
                )
                if result.stdout:
                    _CACHE[target_url] = (result.stdout, now)
                self.send_response(200)
                self.send_header('Content-Type', 'application/json; charset=utf-8')
                self.send_header('Access-Control-Allow-Origin', '*')
                self.end_headers()
                self.wfile.write(result.stdout)
            except Exception as e:
                self.send_response(502)
                self.send_header('Content-Type', 'application/json')
                self.send_header('Access-Control-Allow-Origin', '*')
                self.end_headers()
                self.wfile.write(json.dumps({'error': str(e)}).encode())
            return
        return super().do_GET()

if __name__ == '__main__':
    with ThreadingHTTPServer(("", PORT), ProxyHandler) as httpd:
        print(f"Multi-threaded proxy server running at http://localhost:{PORT} from {DIRECTORY}")
        httpd.serve_forever()
