# Cognito User Pool for Authentication

resource "aws_cognito_user_pool" "healthie" {
  name = "${var.organization_name}-${var.project_name}-users"

  # Password Policy
  password_policy {
    minimum_length                   = 12
    require_lowercase                = true
    require_uppercase                = true
    require_numbers                  = true
    require_symbols                  = true
    temporary_password_validity_days = 7
  }

  # MFA Configuration
  mfa_configuration = var.enable_cognito_mfa ? "OPTIONAL" : "OFF"

  software_token_mfa_configuration {
    enabled = var.enable_cognito_mfa
  }

  # Account Recovery
  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }

    recovery_mechanism {
      name     = "verified_phone_number"
      priority = 2
    }
  }

  # Auto-verified attributes
  auto_verified_attributes = ["email"]

  # Email Configuration
  email_configuration {
    email_sending_account = "COGNITO_DEFAULT"
  }

  # User Attributes
  schema {
    name                = "email"
    attribute_data_type = "String"
    required            = true
    mutable             = true

    string_attribute_constraints {
      min_length = 5
      max_length = 254
    }
  }

  schema {
    name                = "name"
    attribute_data_type = "String"
    required            = true
    mutable             = true

    string_attribute_constraints {
      min_length = 1
      max_length = 100
    }
  }

  # Custom attribute for context engine user ID
  schema {
    name                = "context_engine_id"
    attribute_data_type = "String"
    mutable             = true

    string_attribute_constraints {
      min_length = 36
      max_length = 36
    }
  }

  # Lambda Triggers
  lambda_config {
    pre_sign_up                    = aws_lambda_function.cognito_pre_signup.arn
    post_confirmation              = aws_lambda_function.cognito_post_confirmation.arn
    pre_authentication             = aws_lambda_function.cognito_pre_authentication.arn
    post_authentication            = aws_lambda_function.cognito_post_authentication.arn
  }

  # Advanced Security
  user_pool_add_ons {
    advanced_security_mode = "ENFORCED"
  }

  # Deletion Protection
  deletion_protection = "ACTIVE"

  tags = {
    Name = "${var.organization_name}-${var.project_name}-user-pool"
  }
}

# User Pool Domain
resource "aws_cognito_user_pool_domain" "healthie" {
  domain       = "${var.organization_name}-${var.project_name}-auth"
  user_pool_id = aws_cognito_user_pool.healthie.id
}

# User Pool Client (Web App)
resource "aws_cognito_user_pool_client" "web" {
  name         = "${var.project_name}-web-client"
  user_pool_id = aws_cognito_user_pool.healthie.id

  generate_secret                      = false
  refresh_token_validity               = 30
  access_token_validity                = 60
  id_token_validity                    = 60
  token_validity_units {
    access_token  = "minutes"
    id_token      = "minutes"
    refresh_token = "days"
  }

  explicit_auth_flows = [
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_PASSWORD_AUTH"
  ]

  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["code", "implicit"]
  allowed_oauth_scopes                 = ["email", "openid", "profile"]
  callback_urls                        = var.allowed_origins
  logout_urls                          = var.allowed_origins

  supported_identity_providers = ["COGNITO"]

  read_attributes = [
    "email",
    "email_verified",
    "name",
    "custom:context_engine_id"
  ]

  write_attributes = [
    "email",
    "name"
  ]

  prevent_user_existence_errors = "ENABLED"
}

# Identity Pool for AWS service access
resource "aws_cognito_identity_pool" "healthie" {
  identity_pool_name               = "${var.organization_name}_${var.project_name}_identity_pool"
  allow_unauthenticated_identities = false

  cognito_identity_providers {
    client_id               = aws_cognito_user_pool_client.web.id
    provider_name           = aws_cognito_user_pool.healthie.endpoint
    server_side_token_check = true
  }

  tags = {
    Name = "${var.organization_name}-${var.project_name}-identity-pool"
  }
}

# IAM Roles for authenticated users
resource "aws_iam_role" "authenticated" {
  name = "${var.organization_name}-${var.project_name}-cognito-authenticated"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = "cognito-identity.amazonaws.com"
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "cognito-identity.amazonaws.com:aud" = aws_cognito_identity_pool.healthie.id
          }
          "ForAnyValue:StringLike" = {
            "cognito-identity.amazonaws.com:amr" = "authenticated"
          }
        }
      }
    ]
  })

  tags = {
    Name = "${var.organization_name}-${var.project_name}-cognito-authenticated-role"
  }
}

resource "aws_iam_role_policy" "authenticated" {
  name = "${var.organization_name}-${var.project_name}-cognito-authenticated-policy"
  role = aws_iam_role.authenticated.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = [
          "${aws_s3_bucket.documents.arn}/$${cognito-identity.amazonaws.com:sub}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "execute-api:Invoke"
        ]
        Resource = [
          "${aws_api_gateway_rest_api.healthie.execution_arn}/*"
        ]
      }
    ]
  })
}

# Attach identity pool roles
resource "aws_cognito_identity_pool_roles_attachment" "healthie" {
  identity_pool_id = aws_cognito_identity_pool.healthie.id

  roles = {
    "authenticated" = aws_iam_role.authenticated.arn
  }
}

# CloudWatch Log Group for Cognito
resource "aws_cloudwatch_log_group" "cognito" {
  name              = "/aws/cognito/${var.organization_name}-${var.project_name}"
  retention_in_days = var.log_retention_days
  kms_key_id        = aws_kms_key.healthie.arn

  tags = {
    Name = "${var.organization_name}-${var.project_name}-cognito-logs"
  }
}
