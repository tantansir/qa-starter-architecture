# AI Use Modes Alignment

This document makes the AI-use process explicit for the starter architecture submission. It complements `docs/provenance_log.md` by mapping the work to the course AI Use Modes guide and recording a condensed prompt/action history, review steps, and human contribution.

## Modes used

| Mode | How it was used in this project | Boundaries |
|---|---|---|
| Operator/Agent | Used when the AI assistant was directed to take concrete action in GitHub: create or update repository files, write starter code, add tests, revise documentation, and organize the submission materials. | The agent worked under user direction. Humans remain responsible for understanding the code, running the sandbox commands, validating the behavior, and submitting the final repository. |
| Critic/Red Teamer | Used to review the repository against the assignment requirements, identify weak spots, surface missing evidence, and recommend high-impact fixes before submission. | Critique was used to improve the work, not to replace team review. Findings were converted into specific changes only after the team requested the edits. |

No production model integration is claimed. The current model behavior is a deterministic stub, and future LLM or RAG work is intentionally labeled as future architecture.

## Condensed prompt/action history

| Step | AI use mode | Prompt or instruction summary | Output or change | Review / verification |
|---|---|---|---|---|
| 1 | Operator/Agent | Build a working and defensible starter architecture for the Academy Learner Lab sandbox, saved to GitHub, with devcontainer, sane repo structure, architecture docs, prototype, and provenance log. | Created the initial repository structure, Python QA service, local HTTP handler, Lambda adapter, deployment/evidence scripts, tests, architecture diagram, narrative, and provenance log. | Team review required: understand each code path, run tests, and verify sandbox deployment evidence. |
| 2 | Critic/Red Teamer | Check and grade the GitHub submission against the assignment requirements. | Identified that the submission was strong but could improve provenance wording, Lambda error-path tests, and deployment-prerequisite clarity. | Team selected the highest-impact fixes before final submission. |
| 3 | Operator/Agent | Directly modify GitHub to fix the critique items. | Added Lambda adapter tests for health, bad JSON, missing question, and wrong path; clarified README test coverage and AWS credential requirements; cleaned stale submission-readiness notes from the provenance log. | Team should run `make test`, review the final diff, and confirm the documentation still matches actual behavior. |
| 4 | Critic/Red Teamer, Operator/Agent | Check whether the submission explicitly follows the AI Use Modes guide; if not, add the missing documentation. | Added this alignment document and linked it from the provenance log. | Team should confirm that the role mapping and prompt/action history are accurate before submission. |

## What was checked

The repository was checked against the assignment requirements for a working starter architecture: devcontainer, clone-and-run instructions, architecture diagram, architecture narrative, prototype endpoint, GitHub organization, lab evidence, tests, and code provenance. The critique pass specifically checked for unsupported architecture claims, missing test coverage, unclear deployment prerequisites, and incomplete AI-use documentation.

## Human contribution and responsibility

Human teammates supplied the assignment context, project constraints, target cloud environment, and final submission goal. Human teammates are responsible for reviewing the AI-generated files, running the relevant tests and Learner Lab commands, confirming that the docs match the deployed behavior, and explaining the architecture and code during review.

The team should not submit code it cannot explain. If any file is changed after this record, update `docs/provenance_log.md` and this file so the AI-use record stays accurate.
