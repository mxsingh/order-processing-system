# Execution role for Lambdas
data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    effect = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda_exec" {
    name                = "${var.project_name}-lambda-exec-role"
    assume_role_policy  = data.aws_iam_policy_document.lambda_assume_role.json
}

# CloudWatch
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
    role        = aws_iam_role.lambda_exec.name
    policy_arn  = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# DynamoDB
data "aws_iam_policy_document" "dynamodb_access" {
    statement {
        effect = "Allow"
        actions = [
            "dynamodb:GetItem",
            "dynamodb:PutItem",
            "dynamodb:UpdateItem",
            "dynamodb:DeleteItem",
            "dynamodb:Query"
        ]
        resources = [
            aws_dynamodb_table.dynamodb_table.arn,
            "${aws_dynamodb_table.dynamodb_table.arn}/index/*"
        ]
    }
}

resource "aws_iam_policy" "dynamodb_access" {
    name    = "${var.project_name}-dynamodb-access"
    policy  = data.aws_iam_policy_document.dynamodb_access.json
}

resource "aws_iam_role_policy_attachment" "lambda_dynamodb" {
    role        = aws_iam_role.lambda_exec.name
    policy_arn  = aws_iam_policy.dynamodb_access.arn
}

# SNS
data "aws_iam_policy_document" "sns_publish" {
    statement {
      effect = "Allow"
      actions = ["sns:Publish"]
      resources = [aws_sns_topic.order_events.arn]
    }
}

resource "aws_iam_policy" "sns_publish" {
    name    = "${var.project_name}-sns-publish"
    policy  = data.aws_iam_policy_document.sns_publish.json
}

resource "aws_iam_role_policy_attachment" "lambda_sns_publish" {
    role        = aws_iam_role.lambda_exec.name
    policy_arn  = aws_iam_policy.sns_publish.arn
}

# SQS
data "aws_iam_policy_document" "sqs_consume" {
    statement {
      effect = "Allow"
      actions = [
        "sqs:ReceiveMessage",
        "sqs:DeleteMessage",
        "sqs:GetQueueAttributes"
      ]
      resources = [
        aws_sqs_queue.inventory_check.arn,
        aws_sqs_queue.notification.arn
      ]
    }
}

resource "aws_iam_policy" "sqs_consume" {
    name    = "${var.project_name}-sqs-consume"
    policy  = data.aws_iam_policy_document.sqs_consume.json
}

resource "aws_iam_role_policy_attachment" "lambda_sqs_consume" {
    role        = aws_iam_role.lambda_exec.name
    policy_arn  = aws_iam_policy.sqs_consume.arn
}

# X-Ray
resource "aws_iam_role_policy_attachment" "lambda_xray" {
    role        = aws_iam_role.lambda_exec.name
    policy_arn  = "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess"
}
