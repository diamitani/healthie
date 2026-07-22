# CloudWatch Monitoring and SNS Alerting

# SNS Topic for Alerts
resource "aws_sns_topic" "alerts" {
  name              = "${var.organization_name}-${var.project_name}-alerts"
  kms_master_key_id = aws_kms_key.healthie.id

  tags = {
    Name = "${var.organization_name}-${var.project_name}-alerts"
  }
}

resource "aws_sns_topic_subscription" "alerts_email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = "alerts@diamitani.com"
}

# Lambda Error Alarms
resource "aws_cloudwatch_metric_alarm" "document_processor_errors" {
  alarm_name          = "${var.organization_name}-${var.project_name}-document-processor-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 10
  alarm_description   = "Document processor Lambda errors"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    FunctionName = aws_lambda_function.document_processor.function_name
  }
}

resource "aws_cloudwatch_metric_alarm" "document_processor_throttles" {
  alarm_name          = "${var.organization_name}-${var.project_name}-document-processor-throttles"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Throttles"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 5
  alarm_description   = "Document processor Lambda throttles"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    FunctionName = aws_lambda_function.document_processor.function_name
  }
}

resource "aws_cloudwatch_metric_alarm" "medical_analyst_errors" {
  alarm_name          = "${var.organization_name}-${var.project_name}-medical-analyst-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 10
  alarm_description   = "Medical analyst Lambda errors"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    FunctionName = aws_lambda_function.medical_analyst.function_name
  }
}

# API Gateway Alarms
resource "aws_cloudwatch_metric_alarm" "api_5xx_errors" {
  alarm_name          = "${var.organization_name}-${var.project_name}-api-5xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "5XXError"
  namespace           = "AWS/ApiGateway"
  period              = 300
  statistic           = "Sum"
  threshold           = 10
  alarm_description   = "API Gateway 5XX errors"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    ApiName = aws_api_gateway_rest_api.healthie.name
    Stage   = aws_api_gateway_stage.healthie.stage_name
  }
}

resource "aws_cloudwatch_metric_alarm" "api_latency" {
  alarm_name          = "${var.organization_name}-${var.project_name}-api-high-latency"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "Latency"
  namespace           = "AWS/ApiGateway"
  period              = 300
  statistic           = "Average"
  threshold           = 3000
  alarm_description   = "API Gateway high latency (>3s)"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    ApiName = aws_api_gateway_rest_api.healthie.name
    Stage   = aws_api_gateway_stage.healthie.stage_name
  }
}

# Cognito Alarms
resource "aws_cloudwatch_metric_alarm" "cognito_failed_signins" {
  alarm_name          = "${var.organization_name}-${var.project_name}-cognito-failed-signins"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "UserAuthenticationFailed"
  namespace           = "AWS/Cognito"
  period              = 300
  statistic           = "Sum"
  threshold           = 20
  alarm_description   = "High number of failed Cognito sign-ins"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    UserPoolId = aws_cognito_user_pool.healthie.id
  }
}

# X-Ray for Distributed Tracing
resource "aws_xray_sampling_rule" "healthie" {
  rule_name      = "${var.organization_name}-${var.project_name}-sampling"
  priority       = 1000
  version        = 1
  reservoir_size = 1
  fixed_rate     = 0.05
  url_path       = "*"
  host           = "*"
  http_method    = "*"
  service_type   = "*"
  service_name   = "*"
  resource_arn   = "*"

  tags = {
    Name = "${var.organization_name}-${var.project_name}-xray-sampling"
  }
}

# CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "healthie" {
  dashboard_name = "${var.organization_name}-${var.project_name}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/Lambda", "Invocations", { stat = "Sum", label = "Document Processor" }],
            [".", "Errors", { stat = "Sum", label = "Errors" }],
            [".", "Duration", { stat = "Average", label = "Duration" }]
          ]
          period = 300
          stat   = "Sum"
          region = var.aws_region
          title  = "Document Processor Lambda"
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/ApiGateway", "Count", { stat = "Sum" }],
            [".", "4XXError", { stat = "Sum" }],
            [".", "5XXError", { stat = "Sum" }],
            [".", "Latency", { stat = "Average" }]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "API Gateway Metrics"
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/RDS", "CPUUtilization", { stat = "Average" }],
            [".", "DatabaseConnections", { stat = "Sum" }],
            [".", "FreeStorageSpace", { stat = "Average" }]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "RDS Metrics"
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/Cognito", "UserAuthentication", { stat = "Sum" }],
            [".", "UserAuthenticationFailed", { stat = "Sum" }]
          ]
          period = 300
          stat   = "Sum"
          region = var.aws_region
          title  = "Cognito Authentication"
        }
      }
    ]
  })
}

# EventBridge Rule for Daily Health Check
resource "aws_cloudwatch_event_rule" "daily_health_check" {
  name                = "${var.organization_name}-${var.project_name}-daily-health-check"
  description         = "Trigger daily health check"
  schedule_expression = "cron(0 8 * * ? *)" # 8 AM UTC daily

  tags = {
    Name = "${var.organization_name}-${var.project_name}-daily-health-check"
  }
}

# CloudWatch Logs Insights Queries
resource "aws_cloudwatch_query_definition" "error_analysis" {
  name = "${var.organization_name}-${var.project_name}-error-analysis"

  log_group_names = [
    aws_cloudwatch_log_group.document_processor.name,
    aws_cloudwatch_log_group.medical_analyst.name,
    aws_cloudwatch_log_group.rag_dal_agent.name
  ]

  query_string = <<-QUERY
    fields @timestamp, @message
    | filter @message like /ERROR/ or @message like /Exception/
    | sort @timestamp desc
    | limit 100
  QUERY
}

resource "aws_cloudwatch_query_definition" "performance_analysis" {
  name = "${var.organization_name}-${var.project_name}-performance-analysis"

  log_group_names = [
    aws_cloudwatch_log_group.api_gateway.name
  ]

  query_string = <<-QUERY
    fields @timestamp, responseLength, status, httpMethod, resourcePath
    | filter status >= 200 and status < 300
    | stats avg(responseLength) as avg_response_size,
            pct(responseLength, 95) as p95_response_size,
            count(*) as request_count
      by httpMethod, resourcePath
  QUERY
}
