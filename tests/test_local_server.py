import json
import threading
import unittest
from http.client import HTTPConnection
from http.server import HTTPServer

from qa_service.local_server import QARequestHandler


class SilentQARequestHandler(QARequestHandler):
    def log_message(self, format, *args):
        pass


class TestLocalServer(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.server = HTTPServer(("127.0.0.1", 0), SilentQARequestHandler)
        cls.port = cls.server.server_address[1]
        cls.thread = threading.Thread(target=cls.server.serve_forever)
        cls.thread.daemon = True
        cls.thread.start()

    @classmethod
    def tearDownClass(cls):
        cls.server.shutdown()
        cls.server.server_close()
        cls.thread.join(timeout=2)

    def request_json(self, method, path, payload=None, headers=None):
        body = None
        final_headers = dict(headers or {})
        if payload is not None:
            if isinstance(payload, (dict, list)):
                body = json.dumps(payload)
                final_headers.setdefault("content-type", "application/json")
            else:
                body = payload

        connection = HTTPConnection("127.0.0.1", self.port, timeout=5)
        connection.request(method, path, body=body, headers=final_headers)
        response = connection.getresponse()
        raw_body = response.read().decode("utf-8")
        connection.close()
        return response.status, json.loads(raw_body)

    def test_health_endpoint_returns_ok(self):
        status, payload = self.request_json("GET", "/health")
        self.assertEqual(status, 200)
        self.assertEqual(payload["status"], "ok")

    def test_ask_endpoint_accepts_question(self):
        status, payload = self.request_json("POST", "/ask", {"question": "  What   is this?  "})
        self.assertEqual(status, 200)
        self.assertEqual(payload["question"], "What is this?")
        self.assertEqual(payload["mode"], "stub")

    def test_missing_question_is_rejected(self):
        status, payload = self.request_json("POST", "/ask", {})
        self.assertEqual(status, 400)
        self.assertIn("question", payload["error"])

    def test_bad_json_is_rejected(self):
        status, payload = self.request_json(
            "POST",
            "/ask",
            "{not-json",
            {"content-type": "application/json"},
        )
        self.assertEqual(status, 400)
        self.assertIn("Expecting", payload["error"])

    def test_unknown_path_returns_not_found(self):
        status, payload = self.request_json("POST", "/missing", {"question": "What is this?"})
        self.assertEqual(status, 404)
        self.assertEqual(payload["error"], "not found")


if __name__ == "__main__":
    unittest.main()
