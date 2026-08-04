# Event-driven order processing system

A serverless, event-driven order processing pipeline on AWS, built to mirror production backend architecture. Fully provisioned as infrastructure-as-code with automated CI/CD.

## Tech Stack

AWS Lambda (Python 3.12), API Gateway, DynamoDB, SNS, SQS, IAM, X-Ray, Lambda Layers, Terraform, GitHub Actions

## Project Structure

```
order-processing-system/
|-- .github/workflows/deploy.yaml   # CI: plan on PR, apply on merge to main
|-- infra/                          # all Terraform config
|   |-- api_gateway.tf
|   |-- backend.tf                  # S3 bucket + DynamoDB table
|   |-- dynamodb.tf                 # single-table design + GSI
|   |-- iam.tf                      # shared Lambda execution role + scoped policies
|   |-- lambda.tf                   # three Lambda functions + X-Ray layer
|   |-- outputs.tf
|   |-- provider.tf                 # providers + S3 remote state backend
|   |-- sns.tf                      # order-events topic
|   |-- sqs.tf                      # fan-out subscriptions + DLQ
|   |-- variables.tf
|-- lambda/
|   |-- submit_order/               # validates + writes order, publishes event
|   |-- inventory_check/            # consumes order-events
|   |-- notification/               # consumes order-events
|-- layers/xray_dependencies/       # aws-xray-sdk (Lambda layer)
```

## Setup (from a clean clone of this project)

**Prerequisites:** Terraform >= 1.5.0, Python 3.12, AWS CLI (configure to manage Lambda, DynamoDB, IAM, SNS, SQS, API Gateway, S3, and CloudWatch/X-Ray)

**1. Build the X-Ray layer's dependencies** (not committed - see `.gitignore`):

```bash
cd layers/xray_dependencies
pip install -r requirements.txt -t python/ -upgrade
cd ..
```

**2. Initialize** -- S3 backend is already configured in `provider.tf`, so a fresh clone needs:

```bash
cd infra
terraform init
```

<details>

<summary> Setting this project up under your own AWS account?</summary>

You'll need your own state bucket. Comment out the `backend "s3"` block in `provider.tf`. Then run:

```bash
terraform init
terraform apply     # creates aws_s3_bucket.terraform_state + aws_dynamodb_table.terraform_locks
```

Uncomment the `backend "s3"` block and fill in your bucket name from `terraform output terraform_state_bucket_name`. Then run:

```bash
terraform init -migrate-state
```

</details>

**3. Deploy everything else:**

```bash
terraform apply
```

## Try running the project

**Run the following command:**

```bash
curl -X POST "$(terraform output -raw api_invoke_url)" \
  -H "Content-Type: application/json" \
  -d '{"customerId": "cust-123", "items": [{"sku": "SKU-001", "quantity": 2}]}'
```

Expect a `201` with an `orderId`. Confirm the fan-out:

```bash
aws dynamodb scan --table-name order-processing-table
aws logs tail /aws/lambda/order-processing-inventory-check --since 2m
aws logs tail /aws/lambda/order-processing-notification --since 2m
```

Both consumer Lambdas should log the same `orderId`, independently.

## Single-table DynamoDB design

| Access pattern | Key |
| --- | --- |
| Get order by ID | `PK=ORDER#<id>`, `SK=ORDER#<id>`|
| Get inventory item by SKU | `PK=ITEM#<sku>`, `SK=ITEM#<sku>`|
| List orders by status | `GSI1PK=STATUS#<status>`|

## Observability

All three Lambdas and the API Gateway stage have X-Ray tracing enabled. `submit-order` additionally instruments its `boto3` calls (`patch_all()` via the shared X-Ray layer). This allows DynamoDB and SNS calls to show up as their own subsegments in the trace. Check X-Ray's console service map after submitting an order to see the full path.

## CI/CD

GitHub Actions `.github/workflows/deploy.yaml`:

- **Pull requests** -> `terraform fmt -check`, `validate`, and `plan` (posted as a PR comment)
- **Merge to `main`** -> `terraform apply`, automatically
