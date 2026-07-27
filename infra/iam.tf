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

# CloudWatch logs
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
    role = aws_iam_role.lambda_exec.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
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
