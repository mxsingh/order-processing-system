output "dynamodb_table_name" {
    value = aws_dynamodb_table.dynamodb_table.name  
}

output "dynamodb_table_arn" {
    value = aws_dynamodb_table.dynamodb_table.arn
}

output "lambda_exec_role_arn" {
    value = aws_iam_role.lambda_exec.arn
}
