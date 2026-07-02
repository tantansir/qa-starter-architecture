# Academy Learner Lab Build Evidence

Built and verified in the AWS Academy Learner Lab sandbox.

- Region: us-east-1
- Date UTC: 2026-07-02 02:13:20Z
- Deployed service: AWS Lambda
- Function name: qa-starter-service
- Test method: direct Lambda invoke
- Test endpoint: qa-starter-service

## AWS identity check

```json
{
    "Account": "<redacted-account-id>",
    "UserId": "AROAT7K6UF6M7L5WLCFW7:<redacted-user>",
    "Arn": "arn:aws:sts::<redacted-account-id>:assumed-role/voclabs/<redacted-user>"
}
```

## Prototype endpoint test

```json
{"statusCode": 200, "headers": {"content-type": "application/json"}, "body": "{\"question\": \"What does this service do?\", \"answer\": \"Stub response: I received your question. This prototype will later route the request to an approved model service. The current design keeps request handling separate from model generation so the stub can be replaced without changing the API contract.\", \"model\": \"stubbed-llm-v0\", \"generated_at\": \"2026-07-02T02:13:20.086280+00:00\", \"mode\": \"stub\"}"}
```
