# QA Starter Architecture

This repository is a working starter architecture for a university services navigator: an AI-enabled question-answering service that can later answer routine student questions about deadlines, course logistics, registration, campus resources, and university office policies. It is built in the AWS Academy Learner Lab sandbox and saved to GitHub.

The current implementation accepts a user question and returns a deterministic stubbed answer. It does not yet claim to solve institutional advising. The generation boundary is intentionally isolated so a future model provider, such as Amazon Bedrock or another approved LLM service, can replace the stub without changing the public API contract.

This version is compatible with the older Python 3.6 interpreter commonly present in the Learner Lab terminal. The devcontainer and GitHub CI run Python 3.11.

## Repository structure

```text
.devcontainer/             Reproducible development environment definition
.github/workflows/         Continuous integration checks for GitHub
src/qa_service/            Application code
tests/                     Unit and local integration tests
docs/                      Architecture diagram, narrative, provenance, lab evidence
scripts/                   Deployment and evidence capture scripts
infra/                     Notes for future infrastructure-as-code work
```

## Development environment

The repository is designed so a new teammate can clone it and run the prototype without installing third-party Python packages.

Use the devcontainer through VS Code, GitHub Codespaces, or another compatible Dev Containers client. The container uses Python 3.11, forwards port `8000`, sets `PYTHONPATH` for the `src/` layout, and runs the test suite after creation.

For a non-container local environment, use the `make` commands below. They set `PYTHONPATH=src` explicitly so the package can be imported without installing it.

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

## Test coverage

The current test suite covers:

- question normalization and validation in the core logic;
- stub response shape and mode;
- direct Lambda invoke events;
- Lambda Function URL-style success, health, bad JSON, missing question, and wrong-path behavior;
- local HTTP `/health`, `/ask`, bad JSON, missing question, and wrong-path behavior.

Run all tests with:

```bash
make test
```

## AWS Academy Learner Lab deployment

The Learner Lab is restricted to `us-east-1`, so the deployment script defaults to that region. Deployment commands require active AWS Academy Learner Lab credentials and AWS CLI access; local and devcontainer prototype commands do not require AWS access.

```bash
make deploy
```

The deployment creates or updates an AWS Lambda function. When the installed AWS CLI and sandbox permissions support Lambda Function URLs, the script also creates an HTTPS Function URL. If Function URL support is unavailable, the Lambda function can still be tested through `aws lambda invoke`; the evidence script handles both paths.

After deployment:

```bash
make evidence
```

This writes `docs/lab_build_evidence.md` with the region, timestamp, redacted AWS identity check, and prototype response.

## Development conventions

Keep request validation and answer-generation logic in `src/qa_service/core.py`. Keep transport-specific wrappers separate: `local_server.py` for local HTTP and `lambda_app.py` for AWS Lambda. Do not put provider-specific LLM code directly in handlers; add a model adapter behind the same `generate_answer(question)` boundary.

Use small, reviewable commits. Every agent-generated change must be captured in `docs/provenance_log.md` and reviewed by a human teammate before submission.

## Submission

Submit the GitHub repository link. The repository should include the devcontainer, application code, tests, architecture documentation, provenance log, and lab evidence file.