# API Gateway REST API for Healthie

resource "aws_api_gateway_rest_api" "healthie" {
  name        = "${var.organization_name}-${var.project_name}-api"
  description = "Healthie Document Intelligence API"

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = {
    Name = "${var.organization_name}-${var.project_name}-api"
  }
}

# API Gateway Authorizer (Cognito)
resource "aws_api_gateway_authorizer" "cognito" {
  name          = "${var.project_name}-cognito-authorizer"
  rest_api_id   = aws_api_gateway_rest_api.healthie.id
  type          = "COGNITO_USER_POOLS"
  provider_arns = [aws_cognito_user_pool.healthie.arn]
}

# API Resources
resource "aws_api_gateway_resource" "documents" {
  rest_api_id = aws_api_gateway_rest_api.healthie.id
  parent_id   = aws_api_gateway_rest_api.healthie.root_resource_id
  path_part   = "documents"
}

resource "aws_api_gateway_resource" "document_id" {
  rest_api_id = aws_api_gateway_rest_api.healthie.id
  parent_id   = aws_api_gateway_resource.documents.id
  path_part   = "{documentId}"
}

resource "aws_api_gateway_resource" "chat" {
  rest_api_id = aws_api_gateway_rest_api.healthie.id
  parent_id   = aws_api_gateway_rest_api.healthie.root_resource_id
  path_part   = "chat"
}

# POST /documents - Upload document
resource "aws_api_gateway_method" "upload_document" {
  rest_api_id   = aws_api_gateway_rest_api.healthie.id
  resource_id   = aws_api_gateway_resource.documents.id
  http_method   = "POST"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id

  request_parameters = {
    "method.request.header.Content-Type" = true
  }
}

resource "aws_api_gateway_integration" "upload_document" {
  rest_api_id             = aws_api_gateway_rest_api.healthie.id
  resource_id             = aws_api_gateway_resource.documents.id
  http_method             = aws_api_gateway_method.upload_document.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.document_processor.invoke_arn
}

# GET /documents/{documentId} - Retrieve document
resource "aws_api_gateway_method" "get_document" {
  rest_api_id   = aws_api_gateway_rest_api.healthie.id
  resource_id   = aws_api_gateway_resource.document_id.id
  http_method   = "GET"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id

  request_parameters = {
    "method.request.path.documentId" = true
  }
}

resource "aws_api_gateway_integration" "get_document" {
  rest_api_id             = aws_api_gateway_rest_api.healthie.id
  resource_id             = aws_api_gateway_resource.document_id.id
  http_method             = aws_api_gateway_method.get_document.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.document_processor.invoke_arn
}

# POST /chat - Chat with medical analyst
resource "aws_api_gateway_method" "chat" {
  rest_api_id   = aws_api_gateway_rest_api.healthie.id
  resource_id   = aws_api_gateway_resource.chat.id
  http_method   = "POST"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id
}

resource "aws_api_gateway_integration" "chat" {
  rest_api_id             = aws_api_gateway_rest_api.healthie.id
  resource_id             = aws_api_gateway_resource.chat.id
  http_method             = aws_api_gateway_method.chat.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.medical_analyst.invoke_arn
}

# Lambda Permissions for API Gateway
resource "aws_lambda_permission" "api_gateway_document_processor" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.document_processor.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.healthie.execution_arn}/*/*"
}

resource "aws_lambda_permission" "api_gateway_medical_analyst" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.medical_analyst.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.healthie.execution_arn}/*/*"
}

# API Deployment
resource "aws_api_gateway_deployment" "healthie" {
  rest_api_id = aws_api_gateway_rest_api.healthie.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.documents.id,
      aws_api_gateway_method.upload_document.id,
      aws_api_gateway_integration.upload_document.id,
      aws_api_gateway_method.get_document.id,
      aws_api_gateway_integration.get_document.id,
      aws_api_gateway_method.chat.id,
      aws_api_gateway_integration.chat.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

# API Stage
resource "aws_api_gateway_stage" "healthie" {
  deployment_id = aws_api_gateway_deployment.healthie.id
  rest_api_id   = aws_api_gateway_rest_api.healthie.id
  stage_name    = var.environment

  xray_tracing_enabled = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway.arn
    format = jsonencode({
      requestId      = "$context.requestId"
      ip             = "$context.identity.sourceIp"
      caller         = "$context.identity.caller"
      user           = "$context.identity.user"
      requestTime    = "$context.requestTime"
      httpMethod     = "$context.httpMethod"
      resourcePath   = "$context.resourcePath"
      status         = "$context.status"
      protocol       = "$context.protocol"
      responseLength = "$context.responseLength"
    })
  }

  tags = {
    Name = "${var.organization_name}-${var.project_name}-api-${var.environment}"
  }
}

# API Gateway CloudWatch Log Group
resource "aws_cloudwatch_log_group" "api_gateway" {
  name              = "/aws/apigateway/${var.organization_name}-${var.project_name}"
  retention_in_days = var.log_retention_days
  kms_key_id        = aws_kms_key.healthie.arn

  tags = {
    Name = "${var.organization_name}-${var.project_name}-api-logs"
  }
}

# API Gateway Method Settings
resource "aws_api_gateway_method_settings" "healthie" {
  rest_api_id = aws_api_gateway_rest_api.healthie.id
  stage_name  = aws_api_gateway_stage.healthie.stage_name
  method_path = "*/*"

  settings {
    metrics_enabled    = true
    logging_level      = "INFO"
    data_trace_enabled = true
    throttling_burst_limit = 5000
    throttling_rate_limit  = 10000
  }
}

# Associate WAF with API Gateway
resource "aws_wafv2_web_acl_association" "api_gateway" {
  count        = var.enable_waf ? 1 : 0
  resource_arn = aws_api_gateway_stage.healthie.arn
  web_acl_arn  = aws_wafv2_web_acl.healthie[0].arn
}
