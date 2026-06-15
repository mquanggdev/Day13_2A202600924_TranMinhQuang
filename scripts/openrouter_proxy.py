from __future__ import annotations

import http.client
import json
import os
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import urlparse


OPENROUTER_HOST = "openrouter.ai"
OPENROUTER_PREFIX = "/api/v1"


class ProxyHandler(BaseHTTPRequestHandler):
    def _send_json(self, status: int, payload: dict) -> None:
        body = json.dumps(payload).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self) -> None:
        if urlparse(self.path).path == "/health":
            self._send_json(200, {"ok": True})
            return
        self._proxy()

    def do_POST(self) -> None:
        self._proxy()

    def _proxy(self) -> None:
        api_key = os.getenv("OPENROUTER_API_KEY") or os.getenv("OPENAI_API_KEY")
        if not api_key:
            self._send_json(401, {"error": {"message": "OPENROUTER_API_KEY is not set"}})
            return
        api_key = api_key.strip()
        if api_key.lower().startswith("bearer "):
            api_key = api_key[7:].strip()

        length = int(self.headers.get("Content-Length", "0"))
        body = self.rfile.read(length) if length else b""
        parsed = urlparse(self.path)
        path = parsed.path
        if path == "/v1":
            path = ""
        elif path.startswith("/v1/"):
            path = path[3:]
        target = OPENROUTER_PREFIX + path
        if parsed.query:
            target += "?" + parsed.query

        headers = {
            "Authorization": f"Bearer {api_key}",
            "Content-Type": self.headers.get("Content-Type", "application/json"),
            "Accept": "application/json",
            "HTTP-Referer": "http://localhost/observathon",
            "X-Title": "Observathon Lab",
        }

        conn = http.client.HTTPSConnection(OPENROUTER_HOST, timeout=120)
        try:
            conn.request(self.command, target, body=body, headers=headers)
            response = conn.getresponse()
            data = response.read()
            self.send_response(response.status)
            for name, value in response.getheaders():
                lname = name.lower()
                if lname not in {"transfer-encoding", "connection", "content-encoding"}:
                    self.send_header(name, value)
            self.send_header("Content-Length", str(len(data)))
            self.end_headers()
            self.wfile.write(data)
        except Exception as exc:
            self._send_json(502, {"error": {"message": f"OpenRouter proxy error: {exc}"}})
        finally:
            conn.close()

    def log_message(self, fmt: str, *args) -> None:
        print("[openrouter-proxy] " + (fmt % args), flush=True)


def main() -> None:
    port = int(os.getenv("PORT", "8000"))
    server = ThreadingHTTPServer(("127.0.0.1", port), ProxyHandler)
    print(f"[openrouter-proxy] listening on http://127.0.0.1:{port}/v1", flush=True)
    server.serve_forever()


if __name__ == "__main__":
    main()
