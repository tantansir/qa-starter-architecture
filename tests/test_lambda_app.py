import json
import unittest

from qa_service.lambda_app import handler


class TestLambdaApp(unittest.TestCase):
    def test_direct_lambda_invoke_accepts_question(self):
        response = handler({"question": "What is this?"}, None)
        self.assertEqual(response["statusCode"], 200)
        body = json.loads(response["body"])
        self.assertEqual(body["question"], "What is this?")

    def test_function_url_style_event_accepts_question(self):
        event = {
            "requestContext": {"http": {"method": "POST"}},
            "rawPath": "/ask",
            "body": json.dumps({"question": "What is this?"}),
        }
        response = handler(event, None)
        self.assertEqual(response["statusCode"], 200)
        body = json.loads(response["body"])
        self.assertEqual(body["mode"], "stub")

    def test_health_endpoint_returns_ok(self):
        event = {
            "requestContext": {"http": {"method": "GET"}},
            "rawPath": "/health",
        }
        response = handler(event, None)
        self.assertEqual(response["statusCode"], 200)
        body = json.loads(response["body"])
        self.assertEqual(body["status"], "ok")

    def test_unknown_path_returns_not_found(self):
        event = {
            "requestContext": {"http": {"method": "POST"}},
            "rawPath": "/missing",
            "body": json.dumps({"question": "What is this?"}),
        }
        response = handler(event, None)
        self.assertEqual(response["statusCode"], 404)
        body = json.loads(response["body"])
        self.assertEqual(body["error"], "not found")

    def test_bad_json_is_rejected(self):
        event = {
            "requestContext": {"http": {"method": "POST"}},
            "rawPath": "/ask",
            "body": "{not-json",
        }
        response = handler(event, None)
        self.assertEqual(response["statusCode"], 400)
        body = json.loads(response["body"])
        self.assertIn("error", body)

    def test_missing_question_is_rejected(self):
        event = {
            "requestContext": {"http": {"method": "POST"}},
            "rawPath": "/ask",
            "body": json.dumps({}),
        }
        response = handler(event, None)
        self.assertEqual(response["statusCode"], 400)
        body = json.loads(response["body"])
        self.assertIn("question", body["error"])


if __name__ == "__main__":
    unittest.main()
