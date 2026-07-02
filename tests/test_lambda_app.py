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


if __name__ == "__main__":
    unittest.main()
