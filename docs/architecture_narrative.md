# Architecture Narrative

## Goal

This starter architecture provides the first working slice of a question-answering application. The immediate requirement is not a complete AI product; it is a defensible foundation that a teammate can clone, run, review, and extend. The prototype accepts a question and returns a structured JSON response. At this stage, the model response is stubbed, but the code boundary is arranged so a real model provider can be added later without changing the external API contract.

## What was built

The repository contains a small Python service with three layers. The core layer in `src/qa_service/core.py` validates and normalizes a question and returns the current answer payload. The local transport layer in `local_server.py` exposes the same behavior through a minimal HTTP server for development. The cloud transport layer in `lambda_app.py` adapts AWS Lambda Function URL events to the same core function. This separation keeps the business logic independent from local development tooling and AWS-specific event formats.

The deployed sandbox service uses AWS Lambda and a Lambda Function URL in `us-east-1`. Lambda was selected because it fits the Academy Learner Lab constraints: it has low operational overhead, it can run a small stateless prototype, and it can be rebuilt quickly when the lab session is reset. Lambda Function URL was selected over API Gateway for this first iteration because it provides a direct HTTPS endpoint with fewer moving parts. The code uses the existing Academy `LabRole` instead of creating new IAM infrastructure, which reduces permission risk inside the sandbox.

CloudWatch Logs are part of the operating model because Lambda automatically emits function logs there. For this assignment, the repository also includes `docs/lab_build_evidence.md`, generated from the sandbox after deployment, to show the AWS identity check, region, and endpoint test response. The canonical project state is GitHub because the Academy sandbox is temporary and cleaned up at the end of the session.

## Why this architecture is defensible

The design is intentionally small but not throwaway. The public API is `POST /ask` with a JSON body containing a `question` field. That contract is stable enough for front-end, CLI, or integration work to begin. The answer-generation function is isolated from the HTTP and Lambda adapters. When the team is ready to use a real model, the replacement should happen behind the `generate_answer(question)` boundary. A later implementation can call Amazon Bedrock, an approved external LLM API, or a retrieval-augmented generation service without rewriting the endpoint handler.

The current service is stateless. This is appropriate for the first prototype because there is no durable conversation history, user account model, or document ingestion pipeline yet. Avoiding premature storage keeps the initial security surface small. If the project later needs persistence, the likely additions are Amazon S3 for source documents or artifacts, DynamoDB for request metadata or conversation state, and a retrieval/indexing component for grounding model answers. Those services are intentionally shown as future architecture rather than claimed as current implementation.

The repository structure is designed for teammate onboarding. Documentation lives in `docs/`, application code in `src/`, tests in `tests/`, operational scripts in `scripts/`, and future infrastructure notes in `infra/`. The devcontainer defines a reproducible environment. The CI workflow runs the unit tests on every push. The provenance log records which parts were human-written versus agent-generated and what review was performed.

## Known limitations and next steps

The answer is currently deterministic and does not call a real model. There is no authentication on the Function URL, which is acceptable only for a short-lived classroom sandbox and non-sensitive stub responses. A production version would add authentication, request limits, structured observability, input safety checks, and a model provider with cost controls. The next technical step is to replace the stub adapter with an approved model call and add tests around error handling, prompt construction, and response formatting.
