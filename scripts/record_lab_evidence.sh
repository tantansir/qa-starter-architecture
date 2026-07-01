#!/usr/bin/env bash
set -euo pipefail

REGION="${AWS_REGION:-us-east-1}"
FUNCTION_NAME="${FUNCTION_NAME:-qa-starter-service}"
mkdir -p docs

IDENTITY="$(aws sts get-caller-identity --region "$REGION" | sed -E 's/[0-9]{12}/<redacted-account-id>/g')"
FUNCTION_URL="$(aws lambda get-function-url-config --function-name "$FUNCTION_NAME" --region "$REGION" --query FunctionUrl --output text 2>/dev/null || true)"

if [[ -n "$FUNCTION_URL" && "$FUNCTION_URL" != "None" ]]; then
  RESPONSE="$(curl -s -X POST "${FUNCTION_URL}ask" -H 'content-type: application/json' -d '{"question":"What does this service do?"}')"
else
  RESPONSE='{"error":"Function URL not found. Run make deploy first."}'
fi

cat > docs/lab_build_evidence.md <<EOF2
# Academy Learner Lab Build Evidence

Built and verified in the AWS Academy Learner Lab sandbox.

- Region: ${REGION}
- Date UTC: $(date -u '+%Y-%m-%d %H:%M:%SZ')
- Deployed service: AWS Lambda Function URL
- Function name: ${FUNCTION_NAME}

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
