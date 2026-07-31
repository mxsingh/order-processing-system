resource "aws_api_gateway_rest_api" "orders_api" {
    name        = "${var.project_name}-api"
    description = "REST API for submitting orders"
}

resource "aws_api_gateway_resource" "orders" {
    rest_api_id = aws_api_gateway_rest_api.orders_api.id
    parent_id   = aws_api_gateway_rest_api.orders_api.root_resource_id
    path_part   = "orders"
}

resource "aws_api_gateway_method" "post_order" {
    rest_api_id     = aws_api_gateway_rest_api.orders_api.id
    resource_id     = aws_api_gateway_resource.orders.id
    http_method     = "POST"
    authorization   = "NONE"
}

resource "aws_api_gateway_integration" "post_order" {
    rest_api_id             = aws_api_gateway_rest_api.orders_api.id
    resource_id             = aws_api_gateway_resource.orders.id
    http_method             = aws_api_gateway_method.post_order.http_method
    integration_http_method = "POST"
    type                    = "AWS_PROXY"
    uri                     = aws_lambda_function.submit_order.invoke_arn
}

resource "aws_lambda_permission" "allow_api_gateway" {
    statement_id    = "AllowAPIGatewayInvoke"
    action          = "lambda:InvokeFunction"
    function_name   = aws_lambda_function.submit_order.function_name
    principal       = "apigateway.amazonaws.com"
    source_arn      = "${aws_api_gateway_rest_api.orders_api.execution_arn}/*/*"
}

resource "aws_api_gateway_deployment" "orders_api" {
    rest_api_id = aws_api_gateway_rest_api.orders_api.id

    triggers = {
        redeployment = sha1(jsonencode([
            aws_api_gateway_resource.orders.id,
            aws_api_gateway_method.post_order.id,
            aws_api_gateway_integration.post_order.id
        ]))
    }

    lifecycle {
      create_before_destroy = true
    }
}

resource "aws_api_gateway_stage" "dev" {
    deployment_id           = aws_api_gateway_deployment.orders_api.id
    rest_api_id             = aws_api_gateway_rest_api.orders_api.id
    stage_name              = var.environment
    xray_tracing_enabled    = true
}
