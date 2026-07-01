"""Minimal local HTTP server for the QA starter prototype."""

from __future__ import annotations

from http.server import BaseHTTPRequestHandler, HTTPServer
import json
import os
from urllib.parse import urlparse

from qa_service.core import generate_answer


class QARequestHandler(BaseHTTPRequestHandler):
    server_version = "qa-starter/0.1"

    def _json_response(self, status_code: int, payload: dict) -> None:
        body = json.dumps(payload, indent=2).encode("utf-8")
        self.send_response(status_code)
        self.send_header("content-type", "application/json")
        self.send_header("content-length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self) -> None:
        path = urlparse(self.path).path
        if path in {"/", "/health"}:
            self._json_response(200, {"status": "ok", "service": "qa-starter"})
            return
        self._json_response(404, {"error": "not found"})

    def do_POST(self) -> None:
        path = urlparse(self.path).path.rstrip("/")
        if path != "/ask":
            self._json_response(404, {"error": "not found"})
            return

        try:
            length = int(self.headers.get("content-length", "0"))
            raw_body = self.rfile.read(length).decode("utf-8")
            request_body = json.loads(raw_body or "{}")
            response_body = generate_answer(request_body.get("question"))
        except (TypeError, ValueError, json.JSONDecodeError) as exc:
            self._json_response(400, {"error": str(exc)})
            return

        self._json_response(200, response_body)

    def log_message(self, format: str, *args) -> None:
        print("local_server:", format % args)


def main() -> None:
    port = int(os.environ.get("PORT", "8000"))
    server = HTTPServer(("0.0.0.0", port), QARequestHandler)
    print(f"QA starter service listening on http://0.0.0.0:{port}")
    server.serve_forever()


if __name__ == "__main__":
    main()
