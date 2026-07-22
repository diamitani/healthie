# Healthie Deployment Guide

**Organization**: Diamitani Industries  
**Project**: Healthie - Plain-English Health Document Intelligence  
**Framework**: ROSTR (PAL + NPAO + RAG DAL + ContextEngine + Hub)  
**Infrastructure**: AWS (Terraform)

## Deployment Summary

You now have a complete, production-ready AWS infrastructure configuration for Healthie under the **Diamitani Industries** organization hierarchy. All resources will be created with proper tagging, security controls, and HIPAA-aligned architecture.

## What's Been Created

### 1. Infrastructure Code (Terraform)

**Location**: `infrastructure/terraform/`

Complete Terraform configuration including:

- **`main.tf`**: Provider configuration, S3 backend
- **`variables.tf`**: Configurable parameters
- **`vpc.tf`**: Multi-AZ VPC with public/private/database subnets, NAT gateways
- **`security.tf`**: Security groups, KMS keys, WAF, CloudTrail, Secrets Manager
- **`database.tf`**: RDS PostgreSQL 15.5 with pgvector, Multi-AZ, encrypted
- **`storage.tf`**: S3 buckets for documents, knowledge base, static assets, logs
- **`cognito.tf`**: User authentication with MFA, identity pools
- **`lambda.tf`**: Function definitions for all ROSTR agents
- **`api_gateway.tf`**: REST API with Cognito authorizer
- **`monitoring.tf`**: CloudWatch dashboards, alarms, X-Ray tracing
- **`outputs.tf`**: Resource identifiers and endpoints

### 2. Automated Deployment Script

**Location**: `infrastructure/scripts/setup-infrastructure.sh`

Features:
- ✅ Prerequisites check (AWS CLI, Terraform, jq)
- ✅ AWS credential validation
- ✅ Terraform state backend creation (S3 + DynamoDB)
- ✅ Configuration file generation
- ✅ Infrastructure plan and apply
- ✅ Post-deployment output summary

### 3. Documentation

- **Main README**: Complete project overview
- **Infrastructure README**: Detailed deployment and operations guide
- **Agent Soul**: ROSTR framework implementation specification

### 4. Repository Organization

```
healthie/ (pushed to github.com/diamitani/healthie)
├── .gitignore              ✅
├── README.md               ✅
├── DEPLOYMENT.md           ✅ (this file)
├── agents/
│   └── healthie-agent-soul.md  ✅
├── infrastructure/
│   ├── terraform/          ✅ (17 .tf files)
│   └── scripts/
│       └── setup-infrastructure.sh  ✅
└── web/
    └── index.html          ✅
```

## Next Steps

### Phase 1: Deploy Infrastructure (Today)

```bash
cd /Users/patmini/healthie
./infrastructure/scripts/setup-infrastructure.sh
```

This will:
1. Create Terraform state backend (S3 + DynamoDB)
2. Initialize Terraform
3. Plan infrastructure (~$263/month)
4. Deploy after your confirmation
5. Output resource details

**Expected Duration**: 20-30 minutes

### Phase 2: Backend Implementation (Next)

Create Lambda function code:

```bash
mkdir -p backend/{document_processor,pal_intake,medical_analyst,rag_dal,cognito_triggers}
```

**Required Implementation**:

1. **Document Processor**
   - S3 upload handler
   - Textract OCR integration
   - Document classification

2. **PAL Intake Agent**
   - Intent extraction
   - NPAO classification
   - Agent routing

3. **Medical Analyst**
   - Lab result parsing
   - RAG DAL query orchestration
   - Plain-language explanation

4. **RAG DAL Agent**
   - 3-tier search (academic → editorial → community)
   - pgvector similarity search
   - Knowledge base persistence

5. **Cognito Triggers**
   - Pre-signup validation
   - Post-confirmation user setup
   - Authentication logging

### Phase 3: Database Setup

```bash
# After infrastructure is deployed, get RDS endpoint
cd infrastructure/terraform
RDS_ENDPOINT=$(terraform output -raw rds_endpoint)
RDS_SECRET_ARN=$(terraform output -raw rds_secret_arn)

# Get credentials
aws secretsmanager get-secret-value \
  --secret-id $RDS_SECRET_ARN \
  --query SecretString --output text | jq

# Connect and initialize
psql -h $RDS_ENDPOINT -U healthie_admin -d healthie <<SQL
-- Enable extensions
CREATE EXTENSION IF NOT EXISTS vector;
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

-- Create schema for ROSTR Hub
CREATE SCHEMA rostr_hub;

-- ContextEngine tables (per-user isolation)
CREATE TABLE rostr_hub.user_contexts (
  user_id UUID PRIMARY KEY,
  context_data JSONB NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- RAG DAL knowledge base
CREATE TABLE rostr_hub.knowledge_entries (
  entry_id UUID PRIMARY KEY,
  query_origin TEXT NOT NULL,
  content TEXT NOT NULL,
  summary TEXT,
  source JSONB NOT NULL,
  metadata JSONB,
  vector_embedding vector(1536),  -- For Claude embeddings
  confidence FLOAT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create index for vector similarity search
CREATE INDEX idx_knowledge_embedding ON rostr_hub.knowledge_entries 
USING ivfflat (vector_embedding vector_cosine_ops);

-- Document processing tracking
CREATE TABLE rostr_hub.documents (
  document_id UUID PRIMARY KEY,
  user_id UUID NOT NULL,
  s3_key TEXT NOT NULL,
  document_type TEXT,
  status TEXT,
  processing_result JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- NPAO task queue
CREATE TABLE rostr_hub.tasks (
  task_id UUID PRIMARY KEY,
  user_id UUID NOT NULL,
  document_id UUID REFERENCES rostr_hub.documents(document_id),
  npao_class TEXT NOT NULL CHECK (npao_class IN ('N', 'A', 'P', 'O')),
  priority_score FLOAT,
  status TEXT,
  agent_assignment TEXT,
  result JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  completed_at TIMESTAMPTZ
);

-- Audit log for HIPAA compliance
CREATE TABLE rostr_hub.audit_log (
  log_id BIGSERIAL PRIMARY KEY,
  user_id UUID,
  action TEXT NOT NULL,
  resource_type TEXT,
  resource_id UUID,
  details JSONB,
  ip_address INET,
  timestamp TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes
CREATE INDEX idx_documents_user ON rostr_hub.documents(user_id);
CREATE INDEX idx_tasks_npao_priority ON rostr_hub.tasks(npao_class, priority_score DESC);
CREATE INDEX idx_audit_log_user ON rostr_hub.audit_log(user_id, timestamp);

GRANT ALL ON SCHEMA rostr_hub TO healthie_admin;
GRANT ALL ON ALL TABLES IN SCHEMA rostr_hub TO healthie_admin;
SQL
```

### Phase 4: Deploy Lambda Code

```bash
cd backend

# Build deployment packages
for dir in document_processor pal_intake medical_analyst rag_dal cognito_triggers; do
  cd $dir
  pip install -r requirements.txt -t .
  zip -r ../lambda_${dir}.zip .
  cd ..
done

# Deploy
DOCUMENT_PROCESSOR=$(cd ../infrastructure/terraform && terraform output -raw document_processor_function_name)
aws lambda update-function-code \
  --function-name $DOCUMENT_PROCESSOR \
  --zip-file fileb://lambda_document_processor.zip

# Repeat for other functions...
```

### Phase 5: Frontend Deployment

```bash
# Upload static site
BUCKET=$(cd infrastructure/terraform && terraform output -raw static_assets_bucket)
aws s3 sync web s3://$BUCKET/ --delete

# Configure CloudFront (optional, for better performance)
# Create CloudFront distribution pointing to S3 bucket
```

### Phase 6: Configure DNS

```bash
# Get API Gateway URL
API_URL=$(cd infrastructure/terraform && terraform output -raw api_gateway_url)

# Create DNS records in your domain registrar:
# healthie.diamitani.com → CloudFront distribution (if created)
# api.healthie.diamitani.com → API Gateway custom domain (if created)
```

### Phase 7: Create Admin User

```bash
USER_POOL_ID=$(cd infrastructure/terraform && terraform output -raw cognito_user_pool_id)

aws cognito-idp admin-create-user \
  --user-pool-id $USER_POOL_ID \
  --username admin@diamitani.com \
  --user-attributes Name=email,Value=admin@diamitani.com \
  --temporary-password "ChangeMe123!" \
  --message-action SUPPRESS

# Set permanent password
aws cognito-idp admin-set-user-password \
  --user-pool-id $USER_POOL_ID \
  --username admin@diamitani.com \
  --password "YourSecurePassword123!" \
  --permanent
```

### Phase 8: Testing

```bash
# Test document upload
curl -X POST https://api.healthie.diamitani.com/documents \
  -H "Authorization: Bearer $ID_TOKEN" \
  -F "file=@test_lab_results.pdf"

# Test chat
curl -X POST https://api.healthie.diamitani.com/chat \
  -H "Authorization: Bearer $ID_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"message": "What does my WBC count mean?", "documentId": "..."}'
```

## Resource Hierarchy in AWS

All resources will be tagged with:

```yaml
Organization: Diamitani Industries
Project: Healthie
ManagedBy: Terraform
Environment: prod
```

**Naming Convention**: `diamitani-industries-healthie-<resource-type>`

Examples:
- VPC: `diamitani-industries-healthie-vpc`
- RDS: `diamitani-industries-healthie-db`
- S3: `diamitani-industries-healthie-documents-<account-id>`
- Lambda: `diamitani-industries-healthie-document-processor`
- KMS: `alias/diamitani-industries/healthie`

## Cost Management

### Initial Deployment Costs

| Component | Monthly Cost |
|-----------|-------------|
| RDS (db.t3.medium, Multi-AZ) | $130 |
| NAT Gateways (2 × $45) | $90 |
| Lambda (100K invocations) | $20 |
| S3 (100 GB) | $3 |
| API Gateway | $4 |
| CloudWatch | $5 |
| WAF | $10 |
| KMS | $1 |
| **Total** | **~$263/month** |

### Cost Optimization Tips

1. **Development Environment**: Use smaller RDS instance (db.t3.micro)
2. **NAT Gateways**: Use single NAT for dev (remove high availability)
3. **Lambda**: Use provisioned concurrency only for production
4. **S3**: Enable Intelligent-Tiering for cost savings
5. **CloudWatch**: Adjust log retention (7 days for dev)

## Security Checklist

Before going to production:

- [ ] Review all security group rules
- [ ] Enable GuardDuty for threat detection
- [ ] Configure AWS Config for compliance monitoring
- [ ] Set up SNS alert subscriptions for security alarms
- [ ] Review IAM policies for least privilege
- [ ] Enable MFA for all admin users
- [ ] Configure CloudTrail log file validation
- [ ] Review S3 bucket policies
- [ ] Test disaster recovery procedures
- [ ] Document incident response plan
- [ ] Sign AWS Business Associate Agreement (BAA) for HIPAA

## Monitoring Setup

### CloudWatch Dashboard

Access: AWS Console → CloudWatch → Dashboards → `diamitani-industries-healthie-dashboard`

### Key Metrics to Watch

1. **Lambda Errors**: Should be < 1%
2. **API Latency**: Should be < 2 seconds
3. **RDS CPU**: Should be < 70% average
4. **RDS Connections**: Should be < 80% of max
5. **Authentication Failures**: Spikes indicate potential attack

### Alert Recipients

Configure SNS subscription:

```bash
SNS_TOPIC=$(cd infrastructure/terraform && terraform output -raw sns_alerts_topic_arn)

aws sns subscribe \
  --topic-arn $SNS_TOPIC \
  --protocol email \
  --notification-endpoint your-email@diamitani.com
```

## Backup and Recovery

### RDS Backups

- **Automated**: Daily backups, 30-day retention
- **Manual**: Take snapshot before major changes
- **Recovery**: Point-in-time restore available

### S3 Versioning

- Enabled on documents bucket
- Lifecycle policy: Archive to Glacier after 90 days

### Disaster Recovery Plan

**RTO (Recovery Time Objective)**: 4 hours  
**RPO (Recovery Point Objective)**: 24 hours

**Procedure**:
1. Restore RDS from latest snapshot
2. Restore S3 objects from versioned backups
3. Redeploy Lambda functions from code repository
4. Update DNS if needed
5. Verify all services operational

## Troubleshooting

### Infrastructure Deployment Issues

```bash
# Check Terraform state
cd infrastructure/terraform
terraform show

# Validate configuration
terraform validate

# Check AWS permissions
aws sts get-caller-identity

# View detailed plan
terraform plan -out=tfplan
terraform show tfplan
```

### Lambda Issues

```bash
# View logs
aws logs tail /aws/lambda/diamitani-industries-healthie-document-processor --follow

# Test invocation
aws lambda invoke \
  --function-name diamitani-industries-healthie-document-processor \
  --payload '{"test": true}' \
  response.json
```

### RDS Connection Issues

```bash
# Check security group
aws ec2 describe-security-groups --group-ids <sg-id>

# Test from Lambda
# (Lambda must be in VPC to access RDS)
```

## Support

- **Infrastructure Issues**: infrastructure@diamitani.com
- **Product Questions**: healthie@diamitani.com
- **Security Concerns**: security@diamitani.com
- **Emergency**: Call Patrick directly

## References

- **ROSTR Framework**: See `agents/healthie-agent-soul.md`
- **AWS Best Practices**: https://aws.amazon.com/architecture/well-architected/
- **HIPAA on AWS**: https://aws.amazon.com/compliance/hipaa-compliance/
- **Terraform Docs**: https://registry.terraform.io/providers/hashicorp/aws/latest/docs

---

**Status**: Infrastructure code complete ✅  
**Next Action**: Run `./infrastructure/scripts/setup-infrastructure.sh`  
**Owner**: Patrick Diamitani  
**Organization**: Diamitani Industries  
**Date**: July 22, 2026
