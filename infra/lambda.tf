data "archive_file" "submit_order" {
  type        = "zip"
  source_dir  = "${path.module}/../lambda/submit_order"
  output_path = "${path.module}/build/submit_order.zip"
}

resource "aws_lambda_function" "submit_order" {
  function_name   = "${var.project_name}-submit-order"
  role            = aws_iam_role.lambda_exec.arn
  handler         = "app.handler"
  runtime         = "python3.12"
  timeout         = 10
  memory_size     = 128

  filename            = data.archive_file.submit_order.output_path
  source_code_hash    = data.archive_file.submit_order.output_base64sha256

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.dynamodb_table.name
      ORDER_EVENTS_TOPIC_ARN = aws_sns_topic.order_events.arn
    }
  }
}

resource "aws_cloudwatch_log_group" "submit_order" {
  name                = "/aws/lambda/${aws_lambda_function.submit_order.function_name}"
  retention_in_days   = 7
}

# Inventory check Lambda

data "archive_file" "inventory_check" {
  type        = "zip"
  source_dir  = "${path.module}/../lambda/inventory_check"
  output_path = "${path.module}/build/inventory_check.zip"
}

resource "aws_lambda_function" "inventory_check" {
  function_name   = "${var.project_name}-inventory-check"
  role            = aws_iam_role.lambda_exec.arn
  handler         = "app.handler"
  runtime         = "python3.12"
  timeout         = 10
  memory_size     = 128

  filename          = data.archive_file.inventory_check.output_path
  source_code_hash  = data.archive_file.inventory_check.output_base64sha256
}

resource "aws_cloudwatch_log_group" "inventory_check" {
  name              = "/aws/lambda/${aws_lambda_function.inventory_check.function_name}"
  retention_in_days = 7
}

resource "aws_lambda_event_source_mapping" "inventory_check" {
  event_source_arn  = aws_sqs_queue.inventory_check.arn
  function_name     = aws_lambda_function.inventory_check.arn
  batch_size        = 10
}

# Notification Lambda
data "archive_file" "notification" {
  type = "zip"
  source_dir = "${path.module}/../lambda/notification"
  output_path = "${path.module}/build/notification.zip"
}

resource "aws_lambda_function" "notification" {
  function_name   = "${var.project_name}-notification"
  role            = aws_iam_role.lambda_exec.arn
  handler         = "app.handler"
  runtime         = "python3.12"
  timeout         = 10
  memory_size     = 128

  filename          = data.archive_file.notification.output_path
  source_code_hash  = data.archive_file.notification.output_base64sha256
}

resource "aws_cloudwatch_log_group" "notification" {
  name              = "/aws/lambda/${aws_lambda_function.notification.function_name}"
  retention_in_days = 7
}

resource "aws_lambda_event_source_mapping" "notification" {
  event_source_arn  = aws_sqs_queue.notification.arn
  function_name     = aws_lambda_function.notification.arn
  batch_size        = 10
}
