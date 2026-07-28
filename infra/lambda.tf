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
      }
    }
}

resource "aws_cloudwatch_log_group" "submit_order" {
    name                = "/aws/lambda/${aws_lambda_function.submit_order.function_name}"
    retention_in_days   = 7
}
