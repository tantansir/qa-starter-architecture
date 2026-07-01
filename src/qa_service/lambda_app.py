"""AWS Lambda Function URL adapter for the QA starter prototype."""

from __future__ import annotations

import base64
import json
from typing import Any

from qa_service.core import generate_answer


def _response(status_code: int, payload: dict[str, Any]) -> dict[str, Any]:
    return {
        "statusCode": status_code,
        "headers": {"content-type": "application/json"},
        "body": json.dumps(payload),
    }


def _method(event: dict[str, Any]) -> str:
    return (
        event.get("requestContext", {}).get("http", {}).get("method")
        or event.get("httpMethod")
        or "GET"
    ).upper()


def _path(event: dict[str, Any]) -> str:
    return event.get("rawPath") or event.get("path") or "/"


def handler(event: dict[str, Any], context: Any) -> dict[str, Any]:
    method = _method(event)
    path = _path(event).rstrip("/") or "/"

    if method == "GET" and path in {"/", "/health"}:
        return _response(200, {"status": "ok", "service": "qa-starter"})

    if method != "POST" or path != "/ask":
        return _response(404, {"error": "not found"})

    try:
        body = event.get("body") or "{}"
        if event.get("isBase64Encoded"):
            body = base64.b64decode(body).decode("utf-8")
        request_body = json.loads(body)
        return _response(200, generate_answer(request_body.get("question")))
    except (TypeError, ValueError, json.JSONDecodeError) as exc:
        return _response(400, {"error": str(exc)})
