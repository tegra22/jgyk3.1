#!/usr/bin/env python3

import base64
import hmac
import os
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer

ADMIN_DIRECTORY = "/opt/mrh-admin"
ADMIN_USERNAME = os.getenv("MRH_ADMIN_USERNAME", "admin")
ADMIN_PASSWORD = os.getenv("MRH_ADMIN_PASSWORD", "Sample@Sample")
AUTH_TOKEN = base64.b64encode(f"{ADMIN_USERNAME}:{ADMIN_PASSWORD}".encode("utf-8")).decode("ascii")


class AdminAuthHandler(SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=ADMIN_DIRECTORY, **kwargs)

    def _is_authorized(self):
        authorization = self.headers.get("Authorization", "")
        if not authorization.startswith("Basic "):
            return False
        presented_token = authorization[6:].strip()
        return hmac.compare_digest(presented_token, AUTH_TOKEN)

    def _request_auth(self):
        self.send_response(401)
        self.send_header("WWW-Authenticate", 'Basic realm="MRH Admin Panel", charset="UTF-8"')
        self.send_header("Content-Type", "text/plain; charset=utf-8")
        self.end_headers()
        self.wfile.write(b"Authentication required.")

    def do_GET(self):
        if not self._is_authorized():
            self._request_auth()
            return
        super().do_GET()

    def do_HEAD(self):
        if not self._is_authorized():
            self._request_auth()
            return
        super().do_HEAD()


if __name__ == "__main__":
    server = ThreadingHTTPServer(("0.0.0.0", 8080), AdminAuthHandler)
    server.serve_forever()
