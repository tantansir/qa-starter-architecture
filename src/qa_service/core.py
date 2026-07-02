"""Core domain logic for the QA starter prototype.

This module deliberately has no cloud, web-framework, or model-provider dependency.
The transport layers call generate_answer(question) and can later swap the stub for
an approved model integration.
"""

from datetime import datetime, timezone
import re
from typing import Any, Dict

MAX_QUESTION_CHARS = 2000
MODEL_NAME = "stubbed-llm-v0"


def normalize_question(question: Any) -> str:
    """Validate and normalize a user question."""
    if not isinstance(question, str):
        raise TypeError("question must be a string")

    cleaned = re.sub(r"\s+", " ", question).strip()
    if not cleaned:
        raise ValueError("question is required")
    if len(cleaned) > MAX_QUESTION_CHARS:
        raise ValueError("question must be {} characters or fewer".format(MAX_QUESTION_CHARS))
    return cleaned


def generate_answer(question: Any) -> Dict[str, str]:
    """Return the current prototype answer payload.

    The answer is intentionally deterministic. In the next iteration, only this
    function should need to change to call a model provider or retrieval pipeline.
    """
    normalized = normalize_question(question)
    generated_at = datetime.now(timezone.utc).isoformat()

    return {
        "question": normalized,
        "answer": (
            "Stub response: I received your question. This prototype will later "
            "route the request to an approved model service. The current design "
            "keeps request handling separate from model generation so the stub can "
            "be replaced without changing the API contract."
        ),
        "model": MODEL_NAME,
        "generated_at": generated_at,
        "mode": "stub",
    }
