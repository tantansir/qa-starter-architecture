.PHONY: test run ask deploy evidence clean

test:
	PYTHONPATH=src python3 -m unittest discover -s tests -v

run:
	PYTHONPATH=src python3 -m qa_service.local_server

ask:
	curl -s -X POST http://localhost:8000/ask -H 'content-type: application/json' -d '{"question":"What does this service do?"}' && echo

deploy:
	bash scripts/deploy_lambda_url.sh

evidence:
	bash scripts/record_lab_evidence.sh

clean:
	rm -rf build .pytest_cache .ruff_cache __pycache__ src/qa_service/__pycache__ tests/__pycache__
