# Healthie AWS Infrastructure

This directory contains Terraform configuration for deploying Healthie's secure AWS infrastructure under **Diamitani Industries**.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                     Diamitani Industries                         │
│                         Healthie Platform                        │
├─────────────────────────────────────────────────────────────────┤
│ CloudFront → ALB → API Gateway → Lambda Functions               │
│                                    ↓                              │
│                                 RDS (PostgreSQL + pgvector)      │
│                                    ↓                              │
│                            S3 (Documents, Knowledge Base)        │
├─────────────────────────────────────────────────────────────────┤
│ Security: WAF, KMS, Cognito, VPC, CloudTrail, Secrets Manager   │
└─────────────────────────────────────────────────────────────────┘
```

## Components

### Network Layer
- **VPC**: Multi-AZ with public/private/database subnets
- **NAT Gateways**: High-availability (one per AZ)
- **VPC Flow Logs**: Security monitoring
- **Security Groups**: Least-privilege access controls

### Compute Layer
- **Lambda Functions**:
  - Document Processor (Textract OCR)
  - PAL Intake Agent
  - Medical Records Analyst
  - RAG DAL Agent
  - Cognito Triggers

### Database Layer
- **RDS PostgreSQL 15.5**:
  - Multi-AZ for high availability
  - Encrypted with KMS
  - Automated backups (30 days)
  - Performance Insights enabled
  - pgvector extension for RAG DAL

### Storage Layer
- **S3 Buckets**:
  - `documents`: PHI-protected document uploads
  - `knowledge-base`: RAG DAL reference corpus
  - `static-assets`: Website hosting
  - `logs`: Audit and access logs
  - `cloudtrail`: CloudTrail audit logs

### Security Layer
- **Cognito**: User authentication with MFA
- **KMS**: Encryption key management
- **WAF**: Web Application Firewall
- **Secrets Manager**: Credential rotation
- **CloudTrail**: Audit logging
- **Security Groups**: Network segmentation

### Monitoring Layer
- **CloudWatch**: Metrics, logs, alarms
- **X-Ray**: Distributed tracing
- **SNS**: Alert notifications
- **Dashboard**: Operational visibility

## Prerequisites

1. **AWS CLI** configured with credentials
2. **Terraform** >= 1.0
3. **AWS Account** with appropriate permissions
4. **S3 Bucket** for Terraform state (created separately)

## Initial Setup

### 1. Create Terraform State Backend

```bash
# Create S3 bucket for Terraform state
aws s3api create-bucket \
  --bucket diamitani-industries-terraform-state \
  --region us-east-1

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket diamitani-industries-terraform-state \
  --versioning-configuration Status=Enabled

# Enable encryption
aws s3api put-bucket-encryption \
  --bucket diamitani-industries-terraform-state \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }'

# Create DynamoDB table for state locking
aws dynamodb create-table \
  --table-name diamitani-terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-east-1
```

### 2. Initialize Terraform

```bash
cd infrastructure/terraform
terraform init
```

### 3. Review Configuration

```bash
# Create a terraform.tfvars file
cat > terraform.tfvars <<EOF
aws_region           = "us-east-1"
environment          = "prod"
organization_name    = "diamitani-industries"
project_name         = "healthie"
domain_name          = "healthie.diamitani.com"
allowed_origins      = ["https://healthie.diamitani.com"]
enable_waf           = true
enable_cognito_mfa   = true
log_retention_days   = 30
backup_retention_days = 30
EOF
```

### 4. Plan Deployment

```bash
terraform plan -out=tfplan
```

### 5. Deploy Infrastructure

```bash
terraform apply tfplan
```

## Post-Deployment Steps

### 1. Configure Database

```bash
# Get RDS endpoint
RDS_ENDPOINT=$(terraform output -raw rds_endpoint)
RDS_SECRET_ARN=$(terraform output -raw rds_secret_arn)

# Retrieve credentials
aws secretsmanager get-secret-value \
  --secret-id $RDS_SECRET_ARN \
  --query SecretString \
  --output text | jq -r '.password'

# Connect and set up pgvector
psql -h $RDS_ENDPOINT -U healthie_admin -d healthie <<SQL
CREATE EXTENSION IF NOT EXISTS vector;
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
SQL
```

### 2. Upload Static Assets

```bash
# Upload landing page to S3
BUCKET=$(terraform output -raw static_assets_bucket)
aws s3 cp ../../web/index.html s3://$BUCKET/index.html
aws s3 sync ../../web s3://$BUCKET/
```

### 3. Deploy Lambda Functions

```bash
# Build and deploy Lambda functions
cd ../../backend
./scripts/build_lambdas.sh
./scripts/deploy_lambdas.sh
```

### 4. Configure Cognito

```bash
# Get Cognito details
USER_POOL_ID=$(terraform output -raw cognito_user_pool_id)
CLIENT_ID=$(terraform output -raw cognito_user_pool_client_id)

# Create first admin user
aws cognito-idp admin-create-user \
  --user-pool-id $USER_POOL_ID \
  --username admin@diamitani.com \
  --user-attributes Name=email,Value=admin@diamitani.com \
  --temporary-password "TempPass123!" \
  --message-action SUPPRESS
```

## Security Compliance

### HIPAA Considerations

This infrastructure is designed with HIPAA compliance in mind:

- ✅ Encryption at rest (KMS)
- ✅ Encryption in transit (TLS 1.2+)
- ✅ Audit logging (CloudTrail)
- ✅ Access controls (IAM, Security Groups)
- ✅ Data isolation (per-user namespaces)
- ✅ Backup and recovery (automated backups)
- ✅ Monitoring and alerting (CloudWatch)

**Note**: Full HIPAA compliance requires additional organizational controls, BAAs with AWS, and ongoing security assessments.

## Cost Optimization

Estimated monthly costs (us-east-1):

- RDS (db.t3.medium, Multi-AZ): ~$130
- Lambda (100K invocations/month): ~$20
- S3 (100 GB): ~$3
- NAT Gateways (2): ~$90
- API Gateway (100K requests): ~$4
- CloudWatch Logs (10 GB): ~$5
- KMS: ~$1
- WAF: ~$10
- **Total**: ~$263/month

## Disaster Recovery

### Backup Strategy

- **RDS**: Automated daily backups, 30-day retention
- **S3**: Versioning enabled, lifecycle policies
- **Secrets**: Recovery window of 7 days

### Recovery Procedures

```bash
# Restore RDS from snapshot
aws rds restore-db-instance-from-db-snapshot \
  --db-instance-identifier healthie-restored \
  --db-snapshot-identifier <snapshot-id>

# Restore S3 objects
aws s3api list-object-versions \
  --bucket <bucket-name> \
  --prefix <key-prefix>
```

## Monitoring

### CloudWatch Dashboard

Access at: AWS Console → CloudWatch → Dashboards → `diamitani-industries-healthie-dashboard`

### Key Metrics

- Lambda error rates
- API Gateway latency
- RDS CPU/connections
- Cognito authentication failures

### Alarms

Alerts are sent to: `alerts@diamitani.com`

Configure additional recipients:

```bash
SNS_TOPIC=$(terraform output -raw sns_alerts_topic_arn)
aws sns subscribe \
  --topic-arn $SNS_TOPIC \
  --protocol email \
  --notification-endpoint your-email@example.com
```

## Maintenance

### Updating Infrastructure

```bash
# Update Terraform code
git pull

# Review changes
terraform plan

# Apply updates
terraform apply
```

### Rotating Secrets

```bash
# Rotate RDS password
aws secretsmanager rotate-secret \
  --secret-id $(terraform output -raw rds_secret_arn)
```

### Scaling

```bash
# Update RDS instance class in terraform.tfvars
# Then apply changes
terraform apply
```

## Troubleshooting

### Lambda Errors

```bash
# View Lambda logs
aws logs tail /aws/lambda/<function-name> --follow
```

### RDS Connection Issues

```bash
# Check security group rules
aws ec2 describe-security-groups \
  --group-ids <sg-id>

# Test connectivity from Lambda
aws lambda invoke \
  --function-name <function-name> \
  --payload '{"test": "connection"}' \
  response.json
```

### API Gateway Issues

```bash
# Check API Gateway logs
aws logs tail /aws/apigateway/diamitani-industries-healthie --follow
```

## Cleanup

⚠️ **WARNING**: This will destroy all resources and data.

```bash
# Disable deletion protection
aws rds modify-db-instance \
  --db-instance-identifier diamitani-industries-healthie-db \
  --no-deletion-protection

# Destroy infrastructure
terraform destroy
```

## Support

For infrastructure issues:
- Email: infrastructure@diamitani.com
- Internal: #healthie-infrastructure Slack channel

## License

© 2026 Diamitani Industries. All rights reserved.
