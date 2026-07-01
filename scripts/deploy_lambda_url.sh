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

ROLE_ARN="${LAMBDA_ROLE_ARN:-}"
if [[ -z "$ROLE_ARN" ]]; then
  ROLE_ARN="$(aws iam get-role --role-name LabRole --query 'Role.Arn' --output text --region "$REGION" 2>/dev/null || true)"
fi

if [[ -z "$ROLE_ARN" || "$ROLE_ARN" == "None" ]]; then
  echo "Could not find the Academy LabRole. Set LAMBDA_ROLE_ARN manually and rerun." >&2
  exit 1
fi

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
  aws lambda wait function-updated --function-name "$FUNCTION_NAME" --region "$REGION"
else
  echo "Creating Lambda function: $FUNCTION_NAME"
  aws lambda create-function \
    --function-name "$FUNCTION_NAME" \
    --runtime python3.11 \
    --handler qa_service.lambda_app.handler \
    --role "$ROLE_ARN" \
    --zip-file fileb://build/function.zip \
    --architectures x86_64 \
    --timeout 15 \
    --memory-size 128 \
    --region "$REGION" >/dev/null
  aws lambda wait function-active --function-name "$FUNCTION_NAME" --region "$REGION"
fi

if ! aws lambda get-function-url-config --function-name "$FUNCTION_NAME" --region "$REGION" >/dev/null 2>&1; then
  echo "Creating Lambda Function URL"
  aws lambda create-function-url-config \
    --function-name "$FUNCTION_NAME" \
    --auth-type NONE \
    --region "$REGION" >/dev/null
fi

PERMISSION_OUTPUT="$(mktemp)"
if ! aws lambda add-permission \
  --function-name "$FUNCTION_NAME" \
  --statement-id FunctionURLAllowPublicAccess \
  --action lambda:InvokeFunctionUrl \
  --principal "*" \
  --function-url-auth-type NONE \
  --region "$REGION" >"$PERMISSION_OUTPUT" 2>&1; then
  if grep -q "ResourceConflictException" "$PERMISSION_OUTPUT"; then
    echo "Invoke permission already exists."
  else
    cat "$PERMISSION_OUTPUT" >&2
    rm -f "$PERMISSION_OUTPUT"
    exit 1
  fi
fi
rm -f "$PERMISSION_OUTPUT"

FUNCTION_URL="$(aws lambda get-function-url-config --function-name "$FUNCTION_NAME" --region "$REGION" --query FunctionUrl --output text)"

echo
echo "Deployment complete."
echo "Function URL: ${FUNCTION_URL}"
echo
echo "Test command:"
echo "curl -s -X POST '${FUNCTION_URL}ask' -H 'content-type: application/json' -d '{\"question\":\"What does this service do?\"}' && echo"
echo
