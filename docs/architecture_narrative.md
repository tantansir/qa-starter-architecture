# Architecture Narrative

## Goal

This starter architecture provides the first working slice of a question-answering application. The immediate requirement is not a complete AI product; it is a defensible foundation that a teammate can clone, run, review, and extend. The prototype accepts a question and returns a structured JSON response. At this stage, the model response is stubbed, but the code boundary is arranged so a real model provider can be added later without changing the external API contract.

## What was built

The repository contains a small Python service with three layers. The core layer in `src/qa_service/core.py` validates and normalizes a question and returns the current answer payload. The local transport layer in `local_server.py` exposes the same behavior through a minimal HTTP server for development. The cloud transport layer in `lambda_app.py` adapts both AWS Lambda Function URL events and direct `aws lambda invoke` payloads to the same core function. This separation keeps the business logic independent from local development tooling and AWS-specific event formats.

The public contract is intentionally small. The preferred HTTP request is `POST /ask` with JSON shaped as `{"question":"..."}`. The response includes the normalized question, a deterministic stub answer, the model adapter name, a generation timestamp, and the current mode. The service also exposes `GET /health` for local and cloud smoke checks. Invalid JSON, missing questions, non-string questions, and overlong questions return client errors rather than passing bad input into the generation boundary.

## Cloud services and rationale

The implemented sandbox service uses AWS Lambda in `us-east-1`. Lambda was selected because it fits the Academy Learner Lab constraints: it has low operational overhead, it can run a small stateless prototype, and it can be rebuilt quickly when the lab session is reset. The deployment script first creates or updates the Lambda function using the existing Academy `LabRole`. It then attempts to create a Lambda Function URL as a public HTTPS endpoint. If the installed AWS CLI or sandbox permissions do not support Function URLs, the same prototype still runs through direct Lambda invocation. This fallback is intentional because Learner Lab environments sometimes have older local tooling or restricted permissions.

CloudWatch Logs are part of the operating model because Lambda automatically emits function logs there. For this assignment, the repository also includes a generated `docs/lab_build_evidence.md` file after running `make evidence` in the sandbox. That file records the region, timestamp, redacted AWS identity check, and a real prototype response. The canonical project state is GitHub because the Academy sandbox is temporary and cleaned up at the end of the session.

## Why this architecture is defensible

The design is intentionally small but not throwaway. The public API is stable enough for a teammate to build against while the answer-generation internals are still changing. The answer-generation function is isolated from the HTTP and Lambda adapters. When the team is ready to use a real model, the replacement should happen behind the `generate_answer(question)` boundary. A later implementation can call Amazon Bedrock, an approved external LLM API, or a retrieval-augmented generation service without rewriting the endpoint handler.

The current service is stateless. This is appropriate for the first prototype because there is no durable conversation history, user account model, or document ingestion pipeline yet. Avoiding premature storage keeps the initial security surface small. If the project later needs persistence, the likely additions are Amazon S3 for source documents or artifacts, DynamoDB for request metadata or conversation state, and a retrieval/indexing component for grounding model answers. Those services are intentionally shown as future architecture rather than claimed as current implementation.

The repository structure is designed for teammate onboarding. Documentation lives in `docs/`, application code in `src/`, tests in `tests/`, operational scripts in `scripts/`, and future infrastructure notes in `infra/`. The devcontainer defines a reproducible environment, sets the Python import path for the `src/` layout, forwards the local server port, and runs tests on creation. The CI workflow runs the unit and local integration tests on every push. The provenance log records which parts were human-written versus agent-generated and what review was performed.

## Security, operations, and failure modes

The prototype should not receive sensitive data. If a Lambda Function URL is active, it uses unauthenticated access only because this is a short-lived classroom sandbox and the current response is a non-sensitive stub. A production version would require authentication, request throttling, structured logs, monitoring alarms, cost controls, and input-safety checks before connecting to a real model service.

The main failure modes in this starter version are malformed requests, sandbox credential expiration, missing Lambda permissions, and Function URL creation failure. Malformed requests are handled in code and return JSON errors. Credential or permission failures are handled by the deployment and evidence scripts with explicit messages or a direct-invoke fallback. The fallback path is important because it proves the prototype can still run in the Learner Lab even when the optional public HTTPS endpoint is unavailable.

## Known limitations and next steps

The answer is currently deterministic and does not call a real model. The deployment is script-based rather than infrastructure as code. The Lambda Function URL, when available, has no authentication. These limitations are acceptable for the current assignment but not for production. The next technical step is to replace the stub adapter with an approved model call and add tests around error handling, prompt construction, response formatting, and cost or timeout behavior. A later production version should also move deployment into AWS SAM, CDK, or Terraform once the target AWS account model and permissions are known.
