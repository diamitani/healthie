# Lambda Functions for Healthie Backend

# Lambda Execution Role
resource "aws_iam_role" "lambda_exec" {
  name_prefix = "${var.organization_name}-${var.project_name}-lambda-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.organization_name}-${var.project_name}-lambda-exec-role"
  }
}

resource "aws_iam_role_policy_attachment" "lambda_vpc_execution" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_role_policy" "lambda_exec" {
  name_prefix = "${var.organization_name}-${var.project_name}-lambda-policy-"
  role        = aws_iam_role.lambda_exec.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = [
          "${aws_s3_bucket.documents.arn}/*",
          "${aws_s3_bucket.knowledge_base.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = aws_kms_key.healthie.arn
      },
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = aws_secretsmanager_secret.rds_credentials.arn
      },
      {
        Effect = "Allow"
        Action = [
          "textract:AnalyzeDocument",
          "textract:DetectDocumentText",
          "textract:StartDocumentAnalysis",
          "textract:GetDocumentAnalysis"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "bedrock:InvokeModel"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "xray:PutTraceSegments",
          "xray:PutTelemetryRecords"
        ]
        Resource = "*"
      }
    ]
  })
}

# Lambda Layer for shared dependencies
resource "aws_lambda_layer_version" "healthie_dependencies" {
  filename            = "lambda_layer_payload.zip"
  layer_name          = "${var.organization_name}-${var.project_name}-dependencies"
  compatible_runtimes = ["python3.11"]
  description         = "Shared dependencies for Healthie Lambda functions"

  lifecycle {
    ignore_changes = [filename]
  }
}

# Document Processing Lambda
resource "aws_lambda_function" "document_processor" {
  filename      = "lambda_function_payload.zip"
  function_name = "${var.organization_name}-${var.project_name}-document-processor"
  role          = aws_iam_role.lambda_exec.arn
  handler       = "document_processor.handler"
  runtime       = "python3.11"
  timeout       = 300
  memory_size   = 1024

  vpc_config {
    subnet_ids         = aws_subnet.private[*].id
    security_group_ids = [aws_security_group.lambda.id]
  }

  environment {
    variables = {
      ENVIRONMENT           = var.environment
      RDS_SECRET_ARN        = aws_secretsmanager_secret.rds_credentials.arn
      DOCUMENTS_BUCKET      = aws_s3_bucket.documents.id
      KNOWLEDGE_BASE_BUCKET = aws_s3_bucket.knowledge_base.id
      KMS_KEY_ID            = aws_kms_key.healthie.id
    }
  }

  tracing_config {
    mode = "Active"
  }

  layers = [aws_lambda_layer_version.healthie_dependencies.arn]

  tags = {
    Name = "${var.organization_name}-${var.project_name}-document-processor"
  }

  lifecycle {
    ignore_changes = [filename]
  }
}

# PAL Intake Agent Lambda
resource "aws_lambda_function" "pal_intake_agent" {
  filename      = "lambda_function_payload.zip"
  function_name = "${var.organization_name}-${var.project_name}-pal-intake"
  role          = aws_iam_role.lambda_exec.arn
  handler       = "pal_intake.handler"
  runtime       = "python3.11"
  timeout       = 60
  memory_size   = 512

  vpc_config {
    subnet_ids         = aws_subnet.private[*].id
    security_group_ids = [aws_security_group.lambda.id]
  }

  environment {
    variables = {
      ENVIRONMENT      = var.environment
      RDS_SECRET_ARN   = aws_secretsmanager_secret.rds_credentials.arn
      DOCUMENTS_BUCKET = aws_s3_bucket.documents.id
    }
  }

  tracing_config {
    mode = "Active"
  }

  layers = [aws_lambda_layer_version.healthie_dependencies.arn]

  tags = {
    Name = "${var.organization_name}-${var.project_name}-pal-intake"
  }

  lifecycle {
    ignore_changes = [filename]
  }
}

# Medical Records Analyst Lambda
resource "aws_lambda_function" "medical_analyst" {
  filename      = "lambda_function_payload.zip"
  function_name = "${var.organization_name}-${var.project_name}-medical-analyst"
  role          = aws_iam_role.lambda_exec.arn
  handler       = "medical_analyst.handler"
  runtime       = "python3.11"
  timeout       = 300
  memory_size   = 2048

  vpc_config {
    subnet_ids         = aws_subnet.private[*].id
    security_group_ids = [aws_security_group.lambda.id]
  }

  environment {
    variables = {
      ENVIRONMENT           = var.environment
      RDS_SECRET_ARN        = aws_secretsmanager_secret.rds_credentials.arn
      KNOWLEDGE_BASE_BUCKET = aws_s3_bucket.knowledge_base.id
    }
  }

  tracing_config {
    mode = "Active"
  }

  layers = [aws_lambda_layer_version.healthie_dependencies.arn]

  tags = {
    Name = "${var.organization_name}-${var.project_name}-medical-analyst"
  }

  lifecycle {
    ignore_changes = [filename]
  }
}

# RAG DAL Agent Lambda
resource "aws_lambda_function" "rag_dal_agent" {
  filename      = "lambda_function_payload.zip"
  function_name = "${var.organization_name}-${var.project_name}-rag-dal"
  role          = aws_iam_role.lambda_exec.arn
  handler       = "rag_dal.handler"
  runtime       = "python3.11"
  timeout       = 300
  memory_size   = 2048

  vpc_config {
    subnet_ids         = aws_subnet.private[*].id
    security_group_ids = [aws_security_group.lambda.id]
  }

  environment {
    variables = {
      ENVIRONMENT           = var.environment
      RDS_SECRET_ARN        = aws_secretsmanager_secret.rds_credentials.arn
      KNOWLEDGE_BASE_BUCKET = aws_s3_bucket.knowledge_base.id
    }
  }

  tracing_config {
    mode = "Active"
  }

  layers = [aws_lambda_layer_version.healthie_dependencies.arn]

  tags = {
    Name = "${var.organization_name}-${var.project_name}-rag-dal"
  }

  lifecycle {
    ignore_changes = [filename]
  }
}

# Cognito Triggers
resource "aws_lambda_function" "cognito_pre_signup" {
  filename      = "lambda_function_payload.zip"
  function_name = "${var.organization_name}-${var.project_name}-cognito-pre-signup"
  role          = aws_iam_role.lambda_exec.arn
  handler       = "cognito_triggers.pre_signup"
  runtime       = "python3.11"
  timeout       = 10
  memory_size   = 256

  environment {
    variables = {
      ENVIRONMENT = var.environment
    }
  }

  tags = {
    Name = "${var.organization_name}-${var.project_name}-cognito-pre-signup"
  }

  lifecycle {
    ignore_changes = [filename]
  }
}

resource "aws_lambda_function" "cognito_post_confirmation" {
  filename      = "lambda_function_payload.zip"
  function_name = "${var.organization_name}-${var.project_name}-cognito-post-confirmation"
  role          = aws_iam_role.lambda_exec.arn
  handler       = "cognito_triggers.post_confirmation"
  runtime       = "python3.11"
  timeout       = 30
  memory_size   = 256

  vpc_config {
    subnet_ids         = aws_subnet.private[*].id
    security_group_ids = [aws_security_group.lambda.id]
  }

  environment {
    variables = {
      ENVIRONMENT    = var.environment
      RDS_SECRET_ARN = aws_secretsmanager_secret.rds_credentials.arn
    }
  }

  tags = {
    Name = "${var.organization_name}-${var.project_name}-cognito-post-confirmation"
  }

  lifecycle {
    ignore_changes = [filename]
  }
}

resource "aws_lambda_function" "cognito_pre_authentication" {
  filename      = "lambda_function_payload.zip"
  function_name = "${var.organization_name}-${var.project_name}-cognito-pre-auth"
  role          = aws_iam_role.lambda_exec.arn
  handler       = "cognito_triggers.pre_authentication"
  runtime       = "python3.11"
  timeout       = 10
  memory_size   = 256

  environment {
    variables = {
      ENVIRONMENT = var.environment
    }
  }

  tags = {
    Name = "${var.organization_name}-${var.project_name}-cognito-pre-auth"
  }

  lifecycle {
    ignore_changes = [filename]
  }
}

resource "aws_lambda_function" "cognito_post_authentication" {
  filename      = "lambda_function_payload.zip"
  function_name = "${var.organization_name}-${var.project_name}-cognito-post-auth"
  role          = aws_iam_role.lambda_exec.arn
  handler       = "cognito_triggers.post_authentication"
  runtime       = "python3.11"
  timeout       = 10
  memory_size   = 256

  environment {
    variables = {
      ENVIRONMENT = var.environment
    }
  }

  tags = {
    Name = "${var.organization_name}-${var.project_name}-cognito-post-auth"
  }

  lifecycle {
    ignore_changes = [filename]
  }
}

# Lambda Permissions for Cognito
resource "aws_lambda_permission" "cognito_pre_signup" {
  statement_id  = "AllowCognitoInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cognito_pre_signup.function_name
  principal     = "cognito-idp.amazonaws.com"
  source_arn    = aws_cognito_user_pool.healthie.arn
}

resource "aws_lambda_permission" "cognito_post_confirmation" {
  statement_id  = "AllowCognitoInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cognito_post_confirmation.function_name
  principal     = "cognito-idp.amazonaws.com"
  source_arn    = aws_cognito_user_pool.healthie.arn
}

resource "aws_lambda_permission" "cognito_pre_authentication" {
  statement_id  = "AllowCognitoInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cognito_pre_authentication.function_name
  principal     = "cognito-idp.amazonaws.com"
  source_arn    = aws_cognito_user_pool.healthie.arn
}

resource "aws_lambda_permission" "cognito_post_authentication" {
  statement_id  = "AllowCognitoInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cognito_post_authentication.function_name
  principal     = "cognito-idp.amazonaws.com"
  source_arn    = aws_cognito_user_pool.healthie.arn
}

# CloudWatch Log Groups
resource "aws_cloudwatch_log_group" "document_processor" {
  name              = "/aws/lambda/${aws_lambda_function.document_processor.function_name}"
  retention_in_days = var.log_retention_days
  kms_key_id        = aws_kms_key.healthie.arn
}

resource "aws_cloudwatch_log_group" "pal_intake_agent" {
  name              = "/aws/lambda/${aws_lambda_function.pal_intake_agent.function_name}"
  retention_in_days = var.log_retention_days
  kms_key_id        = aws_kms_key.healthie.arn
}

resource "aws_cloudwatch_log_group" "medical_analyst" {
  name              = "/aws/lambda/${aws_lambda_function.medical_analyst.function_name}"
  retention_in_days = var.log_retention_days
  kms_key_id        = aws_kms_key.healthie.arn
}

resource "aws_cloudwatch_log_group" "rag_dal_agent" {
  name              = "/aws/lambda/${aws_lambda_function.rag_dal_agent.function_name}"
  retention_in_days = var.log_retention_days
  kms_key_id        = aws_kms_key.healthie.arn
}
