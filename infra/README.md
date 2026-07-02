# Infrastructure notes

The current deployment is script-based because the AWS Academy Learner Lab is temporary and permission-restricted. The script creates or updates a single Lambda function in `us-east-1` and attempts to create a Lambda Function URL when supported by the sandbox tooling.

A future iteration should replace the shell deployment with infrastructure as code after the target AWS permissions and production account model are known. Likely options are AWS SAM, AWS CDK, or Terraform.
