#!/usr/bin/env bash
set -euo pipefail

REGION="${AWS_REGION:-us-east-1}"
FUNCTION_NAME="${FUNCTION_NAME:-qa-starter-service}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if ! aws sts get-caller-identity --region "$REGION" >/dev/null 2>&1; then
  echo "AWS credentials are not active. In Learner Lab, click Start Lab and wait until credentials are ready." >&2
  exit 1
fi

ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text --region "$REGION")"
ROLE_ARN="${LAMBDA_ROLE_ARN:-arn:aws:iam::${ACCOUNT_ID}:role/LabRole}"

echo "Using region: $REGION"
echo "Using role: $ROLE_ARN"

rm -rf build
mkdir -p build/lambda
cp -R src/qa_service build/lambda/qa_service

pushd build/lambda >/dev/null
if command -v zip >/dev/null 2>&1; then
  zip -qr ../function.zip qa_service
else
  python3 - <<'PY'
import shutil
shutil.make_archive('../function', 'zip', '.')
PY
fi
popd >/dev/null

if aws lambda get-function --function-name "$FUNCTION_NAME" --region "$REGION" >/dev/null 2>&1; then
  echo "Updating existing Lambda function: $FUNCTION_NAME"
  aws lambda update-function-code \
    --function-name "$FUNCTION_NAME" \
    --zip-file fileb://build/function.zip \
    --region "$REGION" >/dev/null
  sleep 10
else
  echo "Creating Lambda function: $FUNCTION_NAME"
  aws lambda create-function \
    --function-name "$FUNCTION_NAME" \
    --runtime python3.11 \
    --handler qa_service.lambda_app.handler \
    --role "$ROLE_ARN" \
    --zip-file fileb://build/function.zip \
    --timeout 15 \
    --memory-size 128 \
    --region "$REGION" >/dev/null
  sleep 10
fi

FUNCTION_URL=""
if aws lambda get-function-url-config --function-name "$FUNCTION_NAME" --region "$REGION" >/tmp/qa_function_url_check.json 2>/tmp/qa_function_url_check.err; then
  FUNCTION_URL="$(python3 - <<'PY'
import json
with open('/tmp/qa_function_url_check.json') as f:
    data = json.load(f)
print(data.get('FunctionUrl', ''))
PY
)"
else
  if aws lambda create-function-url-config --function-name "$FUNCTION_NAME" --auth-type NONE --region "$REGION" >/dev/null 2>/tmp/qa_function_url_create.err; then
    FUNCTION_URL="$(aws lambda get-function-url-config --function-name "$FUNCTION_NAME" --region "$REGION" --query FunctionUrl --output text 2>/dev/null || true)"
  else
    echo "Function URL could not be created in this sandbox. Continuing with direct Lambda invoke fallback."
  fi
fi

if [[ -n "$FUNCTION_URL" && "$FUNCTION_URL" != "None" ]]; then
  if ! aws lambda add-permission \
    --function-name "$FUNCTION_NAME" \
    --statement-id FunctionURLAllowPublicAccess \
    --action lambda:InvokeFunctionUrl \
    --principal "*" \
    --function-url-auth-type NONE \
    --region "$REGION" >/tmp/qa_lambda_permission.out 2>/tmp/qa_lambda_permission.err; then
    if grep -q "ResourceConflictException" /tmp/qa_lambda_permission.err; then
      echo "Function URL invoke permission already exists."
    else
      echo "Function URL permission could not be added; direct Lambda invoke still works."
      FUNCTION_URL=""
    fi
  fi
fi

cat > build/payload.json <<'JSON'
{"question":"What does this service do?"}
JSON

aws lambda invoke \
  --function-name "$FUNCTION_NAME" \
  --payload fileb://build/payload.json \
  build/lambda_response.json \
  --region "$REGION" >/dev/null

echo
echo "Deployment complete."
echo "Lambda function: ${FUNCTION_NAME}"
echo "Direct invoke response:"
cat build/lambda_response.json
echo

if [[ -n "$FUNCTION_URL" && "$FUNCTION_URL" != "None" ]]; then
  echo "Function URL: ${FUNCTION_URL}"
  echo
  echo "Function URL test command:"
  echo "curl -s -X POST '${FUNCTION_URL}ask' -H 'content-type: application/json' -d '{\"question\":\"What does this service do?\"}' && echo"
else
  echo "No Function URL is active. This is acceptable for the sandbox fallback path."
  echo
  echo "Direct invoke test command:"
  echo "aws lambda invoke --function-name '${FUNCTION_NAME}' --payload fileb://build/payload.json build/lambda_response.json --region '${REGION}' >/dev/null && cat build/lambda_response.json && echo"
fi
