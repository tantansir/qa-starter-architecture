#!/usr/bin/env bash
set -euo pipefail

REGION="${AWS_REGION:-us-east-1}"
FUNCTION_NAME="${FUNCTION_NAME:-qa-starter-service}"
mkdir -p docs build

IDENTITY="$(aws sts get-caller-identity --region "$REGION" | sed -E 's/[0-9]{12}/<redacted-account-id>/g')"
FUNCTION_URL="$(aws lambda get-function-url-config --function-name "$FUNCTION_NAME" --region "$REGION" --query FunctionUrl --output text 2>/dev/null || true)"

TEST_METHOD="direct Lambda invoke"
TEST_ENDPOINT="$FUNCTION_NAME"
RESPONSE=""

if [[ -n "$FUNCTION_URL" && "$FUNCTION_URL" != "None" ]]; then
  TEST_METHOD="Lambda Function URL"
  TEST_ENDPOINT="$FUNCTION_URL"
  RESPONSE="$(curl -s -X POST "${FUNCTION_URL}ask" -H 'content-type: application/json' -d '{"question":"What does this service do?"}')"
else
  cat > build/payload.json <<'JSON'
{"question":"What does this service do?"}
JSON
  aws lambda invoke \
    --function-name "$FUNCTION_NAME" \
    --payload fileb://build/payload.json \
    build/lambda_response.json \
    --region "$REGION" >/dev/null
  RESPONSE="$(cat build/lambda_response.json)"
fi

cat > docs/lab_build_evidence.md <<EOF2
# Academy Learner Lab Build Evidence

Built and verified in the AWS Academy Learner Lab sandbox.

- Region: ${REGION}
- Date UTC: $(date -u '+%Y-%m-%d %H:%M:%SZ')
- Deployed service: AWS Lambda
- Function name: ${FUNCTION_NAME}
- Test method: ${TEST_METHOD}
- Test endpoint: ${TEST_ENDPOINT}

## AWS identity check

\`\`\`json
${IDENTITY}
\`\`\`

## Prototype endpoint test

\`\`\`json
${RESPONSE}
\`\`\`
EOF2

echo "Wrote docs/lab_build_evidence.md"
