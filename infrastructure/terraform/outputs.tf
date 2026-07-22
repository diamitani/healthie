# Terraform Outputs

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "private_subnet_ids" {
  description = "IDs of private subnets"
  value       = aws_subnet.private[*].id
}

output "public_subnet_ids" {
  description = "IDs of public subnets"
  value       = aws_subnet.public[*].id
}

output "rds_endpoint" {
  description = "RDS instance endpoint"
  value       = aws_db_instance.healthie.endpoint
  sensitive   = true
}

output "rds_secret_arn" {
  description = "ARN of RDS credentials secret"
  value       = aws_secretsmanager_secret.rds_credentials.arn
}

output "documents_bucket" {
  description = "S3 bucket for document uploads"
  value       = aws_s3_bucket.documents.id
}

output "documents_bucket_arn" {
  description = "ARN of documents S3 bucket"
  value       = aws_s3_bucket.documents.arn
}

output "knowledge_base_bucket" {
  description = "S3 bucket for RAG DAL knowledge base"
  value       = aws_s3_bucket.knowledge_base.id
}

output "static_assets_bucket" {
  description = "S3 bucket for static website assets"
  value       = aws_s3_bucket.static_assets.id
}

output "kms_key_id" {
  description = "KMS key ID for encryption"
  value       = aws_kms_key.healthie.id
}

output "kms_key_arn" {
  description = "KMS key ARN for encryption"
  value       = aws_kms_key.healthie.arn
}

output "cognito_user_pool_id" {
  description = "Cognito User Pool ID"
  value       = aws_cognito_user_pool.healthie.id
}

output "cognito_user_pool_arn" {
  description = "Cognito User Pool ARN"
  value       = aws_cognito_user_pool.healthie.arn
}

output "cognito_user_pool_client_id" {
  description = "Cognito User Pool Client ID"
  value       = aws_cognito_user_pool_client.web.id
  sensitive   = true
}

output "cognito_identity_pool_id" {
  description = "Cognito Identity Pool ID"
  value       = aws_cognito_identity_pool.healthie.id
}

output "cognito_domain" {
  description = "Cognito hosted UI domain"
  value       = aws_cognito_user_pool_domain.healthie.domain
}

output "api_gateway_id" {
  description = "API Gateway REST API ID"
  value       = aws_api_gateway_rest_api.healthie.id
}

output "api_gateway_url" {
  description = "API Gateway invoke URL"
  value       = aws_api_gateway_stage.healthie.invoke_url
}

output "api_gateway_execution_arn" {
  description = "API Gateway execution ARN"
  value       = aws_api_gateway_rest_api.healthie.execution_arn
}

output "document_processor_function_name" {
  description = "Document Processor Lambda function name"
  value       = aws_lambda_function.document_processor.function_name
}

output "medical_analyst_function_name" {
  description = "Medical Analyst Lambda function name"
  value       = aws_lambda_function.medical_analyst.function_name
}

output "rag_dal_function_name" {
  description = "RAG DAL Lambda function name"
  value       = aws_lambda_function.rag_dal_agent.function_name
}

output "waf_web_acl_arn" {
  description = "WAF Web ACL ARN"
  value       = var.enable_waf ? aws_wafv2_web_acl.healthie[0].arn : null
}

output "cloudtrail_bucket" {
  description = "CloudTrail logging bucket"
  value       = aws_s3_bucket.cloudtrail.id
}

output "sns_alerts_topic_arn" {
  description = "SNS topic ARN for alerts"
  value       = aws_sns_topic.alerts.arn
}

output "cloudwatch_dashboard_name" {
  description = "CloudWatch dashboard name"
  value       = aws_cloudwatch_dashboard.healthie.dashboard_name
}

output "region" {
  description = "AWS region"
  value       = var.aws_region
}

output "account_id" {
  description = "AWS account ID"
  value       = data.aws_caller_identity.current.account_id
}

output "organization" {
  description = "Organization name"
  value       = var.organization_name
}

output "project" {
  description = "Project name"
  value       = var.project_name
}

output "environment" {
  description = "Environment"
  value       = var.environment
}
