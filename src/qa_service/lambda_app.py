"""AWS Lambda adapter for the QA starter prototype."""

import base64
import json
from typing import Any, Dict

from qa_service.core import generate_answer


def _response(status_code: int, payload: Dict[str, Any]) -> Dict[str, Any]:
    return {
        "statusCode": status_code,
        "headers": {"content-type": "application/json"},
        "body": json.dumps(payload),
    }


def _method(event: Dict[str, Any]) -> str:
    return (
        event.get("requestContext", {}).get("http", {}).get("method")
        or event.get("httpMethod")
        or "GET"
    ).upper()


def _path(event: Dict[str, Any]) -> str:
    return event.get("rawPath") or event.get("path") or "/"


def _request_body_from_event(event: Dict[str, Any]) -> Dict[str, Any]:
    body = event.get("body")
    if body is None:
        return event
    if event.get("isBase64Encoded"):
        body = base64.b64decode(body).decode("utf-8")
    return json.loads(body or "{}")


def handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    # Direct Lambda invoke path: aws lambda invoke --payload '{"question":"..."}'
    if "question" in event and "body" not in event:
        try:
            return _response(200, generate_answer(event.get("question")))
        except (TypeError, ValueError) as exc:
            return _response(400, {"error": str(exc)})

    method = _method(event)
    path = _path(event).rstrip("/") or "/"

    if method == "GET" and path in {"/", "/health"}:
        return _response(200, {"status": "ok", "service": "qa-starter"})

    if method != "POST" or path != "/ask":
        return _response(404, {"error": "not found"})

    try:
        request_body = _request_body_from_event(event)
        return _response(200, generate_answer(request_body.get("question")))
    except (TypeError, ValueError, json.JSONDecodeError) as exc:
        return _response(400, {"error": str(exc)})
