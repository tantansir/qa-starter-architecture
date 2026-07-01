# QA Starter Architecture

This repository is a working starter architecture for a question-answering prototype built in the AWS Academy Learner Lab sandbox and saved to GitHub.

The current implementation accepts a user question and returns a deterministic stubbed answer. The generation boundary is intentionally isolated so a future model provider, such as Amazon Bedrock or another approved LLM service, can replace the stub without changing the public API contract.

## Repository structure

```text
.devcontainer/             Reproducible development environment definition
.github/workflows/         Continuous integration checks for GitHub
src/qa_service/            Application code
tests/                     Unit tests
docs/                      Architecture diagram, narrative, provenance, lab evidence
scripts/                   Deployment and evidence capture scripts
infra/                     Notes for future infrastructure-as-code work
```

## Local run

No third-party Python packages are required for the current prototype.

```bash
make test
make run
```

In another terminal:

```bash
curl -s -X POST http://localhost:8000/ask \
  -H 'content-type: application/json' \
  -d '{"question":"What does this service do?"}'
```

Expected result: JSON containing the original question, a stubbed answer, the model adapter name, and a timestamp.

## AWS Academy Learner Lab deployment

The Learner Lab is restricted to `us-east-1`, so the deployment script defaults to that region.

```bash
aws configure set region us-east-1
make deploy
```

The deployment creates or updates an AWS Lambda function and exposes it through a Lambda Function URL. The script uses the existing Academy `LabRole` rather than creating a new IAM role.

After deployment:

```bash
make evidence
```

This writes `docs/lab_build_evidence.md` with the region, timestamp, redacted AWS identity check, and endpoint response.

## Development conventions

Keep request validation and answer-generation logic in `src/qa_service/core.py`. Keep transport-specific wrappers separate: `local_server.py` for local HTTP and `lambda_app.py` for AWS Lambda Function URL. Do not put provider-specific LLM code directly in handlers; add a model adapter behind the same `generate_answer(question)` boundary.

Use small, reviewable commits. Every agent-generated change must be captured in `docs/provenance_log.md` and reviewed by a human teammate before submission.

## Submission

Submit the GitHub repository link. The repository should include the devcontainer, application code, tests, architecture documentation, provenance log, and lab evidence file.
