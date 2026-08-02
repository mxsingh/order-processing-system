output "dynamodb_table_name" {
    value = aws_dynamodb_table.dynamodb_table.name  
}

output "dynamodb_table_arn" {
    value = aws_dynamodb_table.dynamodb_table.arn
}

output "lambda_exec_role_arn" {
    value = aws_iam_role.lambda_exec.arn
}

output "submit_order_function_name" {
    value = aws_lambda_function.submit_order.function_name
}

output "api_invoke_url" {
    value = "${aws_api_gateway_stage.dev.invoke_url}/orders"
}

output "order_events_topic_arn" {
    value = aws_sns_topic.order_events.arn
}

output "dlq_url" {
    value = aws_sqs_queue.dlq.id
}

output "terraform_state_bucket_name" {
    value = aws_s3_bucket.terraform_state.id
}

output "terraform_locks_table_name" {
    value = aws_dynamodb_table.terraform_locks.name
}
