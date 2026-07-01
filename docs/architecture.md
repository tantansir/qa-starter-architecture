# Architecture Diagram

![QA starter architecture](architecture.svg)

## Components

| Component | One-line description |
|---|---|
| Developer workstation / devcontainer | Reproducible development environment for running tests and the local HTTP prototype. |
| GitHub repository | System of record for source code, documentation, provenance log, and teammate onboarding instructions. |
| Local HTTP server | Standard-library development server that exposes the same `/ask` contract used by the cloud adapter. |
| AWS Lambda Function URL | Public HTTPS entry point for the sandbox prototype without requiring API Gateway setup. |
| AWS Lambda function | Stateless compute layer that validates the request and calls the QA generation boundary. |
| Stub model adapter | Deterministic placeholder response generator that will later be replaced by an approved LLM or RAG pipeline. |
| CloudWatch Logs | Operational log destination automatically used by Lambda for debugging sandbox runs. |
| Future model service | Planned integration point for Amazon Bedrock or another approved model provider. |

## Request flow

1. A caller sends `POST /ask` with a JSON body containing `question`.
2. Lambda Function URL receives the HTTPS request and invokes the Lambda handler.
3. The Lambda handler validates and normalizes the question through `core.py`.
4. The current stub model adapter returns a deterministic response.
5. The same API contract can later call a real model service without changing the external endpoint.
