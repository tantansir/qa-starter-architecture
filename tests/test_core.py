import unittest

from qa_service.core import MAX_QUESTION_CHARS, generate_answer, normalize_question


class TestCore(unittest.TestCase):
    def test_normalize_question_strips_extra_whitespace(self):
        self.assertEqual(normalize_question("  What   is this? \n"), "What is this?")

    def test_empty_question_is_rejected(self):
        with self.assertRaises(ValueError):
            normalize_question("   ")

    def test_non_string_question_is_rejected(self):
        with self.assertRaises(TypeError):
            normalize_question(None)

    def test_long_question_is_rejected(self):
        with self.assertRaises(ValueError):
            normalize_question("x" * (MAX_QUESTION_CHARS + 1))

    def test_generate_answer_returns_stub_payload(self):
        payload = generate_answer("How will this work?")
        self.assertEqual(payload["question"], "How will this work?")
        self.assertEqual(payload["mode"], "stub")
        self.assertIn("Stub response", payload["answer"])
        self.assertIn("generated_at", payload)


if __name__ == "__main__":
    unittest.main()
