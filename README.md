# Healthie

Plain-English health-document intelligence. Part of the **Diamitani Industries** ecosystem.

Built on the **ROSTR framework** (PAL + NPAO + RAG DAL + ContextEngine + ROSTR Hub) with production-grade AWS infrastructure.

## Overview

Healthie transforms confusing medical and billing documents into plain-English understanding, grounded in authoritative medical literature. It's a consumer health-intelligence assistant that:

- 📄 Processes medical labs, imaging reports, visit notes
- 💰 Explains medical bills, EOBs, insurance documents
- 🔬 Grounds findings in peer-reviewed research (RAG DAL)
- 💬 Answers follow-up questions with citations
- 📊 Tracks trends across multiple uploads
- 🔒 HIPAA-aligned security and privacy

**Never diagnoses. Never prescribes. Always cites sources.**

## Architecture

```
User → CloudFront → API Gateway → Lambda Functions
                                    ↓
                          RDS PostgreSQL (pgvector)
                                    ↓
                        S3 (Documents + Knowledge Base)
                                    ↓
                        Bedrock (Claude Sonnet 4)
```

## Repository Structure

```
healthie/
├── agents/                      # ROSTR agent definitions
│   └── healthie-agent-soul.md  # Master agent soul
├── backend/                     # Lambda functions (to be created)
│   ├── document_processor/
│   ├── pal_intake/
│   ├── medical_analyst/
│   ├── rag_dal/
│   └── cognito_triggers/
├── infrastructure/              # AWS Terraform configs
│   ├── terraform/              # Main infrastructure
│   │   ├── main.tf
│   │   ├── vpc.tf
│   │   ├── security.tf
│   │   ├── database.tf
│   │   ├── storage.tf
│   │   ├── cognito.tf
│   │   ├── lambda.tf
│   │   ├── api_gateway.tf
│   │   ├── monitoring.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── scripts/
│       └── setup-infrastructure.sh
├── web/                        # Frontend assets
│   └── index.html             # Landing page
└── README.md                   # This file
```

## Quick Start

### Prerequisites

- AWS CLI configured with your Diamitani Industries credentials
- Terraform >= 1.0
- Python 3.11
- Node.js (for frontend tooling)

### 1. Deploy Infrastructure

```bash
# Run automated setup
./infrastructure/scripts/setup-infrastructure.sh

# Or manual deployment
cd infrastructure/terraform
terraform init
terraform plan
terraform apply
```

This creates:
- ✅ Multi-AZ VPC with public/private/database subnets
- ✅ RDS PostgreSQL with pgvector (Multi-AZ, encrypted)
- ✅ S3 buckets (documents, knowledge base, static assets)
- ✅ Cognito authentication (with MFA)
- ✅ Lambda functions and API Gateway
- ✅ KMS encryption, WAF, CloudTrail
- ✅ CloudWatch monitoring and alarms

### 2. Deploy Backend Code

```bash
cd backend
./scripts/build_lambdas.sh
./scripts/deploy_lambdas.sh
```

### 3. Upload Static Assets

```bash
BUCKET=$(cd infrastructure/terraform && terraform output -raw static_assets_bucket)
aws s3 sync web s3://$BUCKET/
```

### 4. Create Admin User

```bash
USER_POOL_ID=$(cd infrastructure/terraform && terraform output -raw cognito_user_pool_id)

aws cognito-idp admin-create-user \
  --user-pool-id $USER_POOL_ID \
  --username admin@diamitani.com \
  --user-attributes Name=email,Value=admin@diamitani.com \
  --temporary-password "TempPass123!" \
  --message-action SUPPRESS
```

## Components

### Frontend
- `web/index.html` - Marketing landing page (Nexus design system)

### Backend (ROSTR Agents)
- **PAL Intake Agent**: Document classification and extraction
- **Medical Records Analyst**: Lab results, visit notes analysis
- **Billing Analyst**: Insurance and billing explanation
- **RAG DAL Agent**: 3-tier knowledge retrieval (academic → editorial → community)
- **Safety Agent**: Guardrails (no diagnosis/prescription)
- **UX Writer Agent**: Plain-language rewriting

### Infrastructure
- **VPC**: Multi-AZ with NAT Gateways
- **RDS**: PostgreSQL 15.5 with pgvector extension
- **Lambda**: Python 3.11 functions in VPC
- **S3**: Versioned, encrypted, lifecycle-managed
- **Cognito**: User pools with MFA
- **API Gateway**: REST API with Cognito authorizer
- **KMS**: Encryption at rest for all data
- **WAF**: Rate limiting and attack protection
- **CloudTrail**: Audit logging for compliance

## Security Features

### HIPAA-Aligned Architecture
- ✅ Encryption at rest (KMS)
- ✅ Encryption in transit (TLS 1.2+)
- ✅ Audit logging (CloudTrail)
- ✅ Access controls (IAM, SGs, Cognito)
- ✅ Data isolation (per-user namespaces)
- ✅ Automated backups (30-day retention)
- ✅ Multi-AZ redundancy
- ✅ VPC isolation

### Network Security
- Private subnets for Lambda and RDS
- Public subnets only for ALB
- Security groups with least-privilege rules
- VPC Flow Logs for monitoring
- WAF with AWS Managed Rule Sets

### Data Protection
- KMS encryption for S3, RDS, Secrets Manager
- S3 bucket versioning and lifecycle policies
- RDS automated backups and point-in-time recovery
- No PHI in shared knowledge base (isolation)

## Monitoring

### CloudWatch Dashboard
- Lambda invocations, errors, duration
- API Gateway request count, latency, errors
- RDS CPU, connections, storage
- Cognito authentication metrics

### Alarms
- Lambda errors > 10 in 5 minutes
- API Gateway 5XX errors
- RDS high CPU (>80%)
- RDS low storage (<10 GB)
- High authentication failures

Alerts sent to: `alerts@diamitani.com`

## Development

### Local Testing

```bash
# Run tests
cd backend
python -m pytest

# Local Lambda invocation
sam local invoke DocumentProcessor -e events/upload.json
```

### Environment Variables

```bash
export ENVIRONMENT=dev
export RDS_SECRET_ARN=arn:aws:secretsmanager:...
export DOCUMENTS_BUCKET=diamitani-industries-healthie-documents-...
export KNOWLEDGE_BASE_BUCKET=diamitani-industries-healthie-knowledge-base-...
```

## Cost Estimate

Monthly costs (us-east-1, moderate usage):

| Service | Configuration | Cost |
|---------|--------------|------|
| RDS PostgreSQL | db.t3.medium, Multi-AZ | $130 |
| NAT Gateways | 2 (HA) | $90 |
| Lambda | 100K invocations | $20 |
| S3 | 100 GB | $3 |
| API Gateway | 100K requests | $4 |
| CloudWatch | 10 GB logs | $5 |
| WAF | Base + rules | $10 |
| KMS | Key + requests | $1 |
| **Total** | | **~$263/month** |

## ROSTR Framework

Healthie implements the full ROSTR architecture:

- **PAL (Prompt Abstraction Layer)**: Intent compilation into agent manifests
- **NPAO (Navigate, Prioritize, Allocate, Orchestrate)**: 5D phase taxonomy + 4D priority scoring
- **RAG DAL (Dynamic Acquisition Layer)**: 3-tier source credibility + multi-pass retrieval
- **ContextEngine**: Per-user isolated memory (HIPAA-compliant)
- **ROSTR Hub**: Agent coordination and state management

See `agents/healthie-agent-soul.md` for complete agent specification.

## Support

- **Infrastructure**: infrastructure@diamitani.com
- **Product**: healthie@diamitani.com
- **Security**: security@diamitani.com

## License

© 2026 Diamitani Industries. All rights reserved.

Part of the Monarch / ROSTR ecosystem.

---

**Built with**:
- AWS (VPC, Lambda, RDS, S3, Cognito, API Gateway, KMS, WAF)
- Terraform (Infrastructure as Code)
- Python 3.11 (Backend)
- PostgreSQL 15.5 + pgvector (Database)
- Amazon Bedrock / Claude Sonnet 4 (AI)
- ROSTR Framework (Multi-agent orchestration)
