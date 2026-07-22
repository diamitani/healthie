#!/usr/bin/env bash
set -euo pipefail

# Healthie Infrastructure Setup Script
# Part of Diamitani Industries
# Author: Patrick Diamitani

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
TERRAFORM_DIR="$PROJECT_ROOT/infrastructure/terraform"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_prerequisites() {
    log_info "Checking prerequisites..."

    # Check AWS CLI
    if ! command -v aws &> /dev/null; then
        log_error "AWS CLI not found. Please install: https://aws.amazon.com/cli/"
        exit 1
    fi

    # Check Terraform
    if ! command -v terraform &> /dev/null; then
        log_error "Terraform not found. Please install: https://www.terraform.io/downloads"
        exit 1
    fi

    # Check jq
    if ! command -v jq &> /dev/null; then
        log_error "jq not found. Please install: https://stedolan.github.io/jq/"
        exit 1
    fi

    # Check AWS credentials
    if ! aws sts get-caller-identity &> /dev/null; then
        log_error "AWS credentials not configured. Run: aws configure"
        exit 1
    fi

    log_info "Prerequisites check passed ✓"
}

setup_terraform_backend() {
    log_info "Setting up Terraform backend..."

    local STATE_BUCKET="diamitani-industries-terraform-state"
    local LOCK_TABLE="diamitani-terraform-locks"
    local REGION="us-east-1"

    # Check if bucket exists
    if ! aws s3api head-bucket --bucket "$STATE_BUCKET" 2>/dev/null; then
        log_info "Creating S3 bucket for Terraform state..."
        aws s3api create-bucket \
            --bucket "$STATE_BUCKET" \
            --region "$REGION"

        # Enable versioning
        aws s3api put-bucket-versioning \
            --bucket "$STATE_BUCKET" \
            --versioning-configuration Status=Enabled

        # Enable encryption
        aws s3api put-bucket-encryption \
            --bucket "$STATE_BUCKET" \
            --server-side-encryption-configuration '{
                "Rules": [{
                    "ApplyServerSideEncryptionByDefault": {
                        "SSEAlgorithm": "AES256"
                    },
                    "BucketKeyEnabled": true
                }]
            }'

        # Block public access
        aws s3api put-public-access-block \
            --bucket "$STATE_BUCKET" \
            --public-access-block-configuration \
            "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"

        log_info "S3 bucket created: $STATE_BUCKET"
    else
        log_info "S3 bucket already exists: $STATE_BUCKET"
    fi

    # Check if DynamoDB table exists
    if ! aws dynamodb describe-table --table-name "$LOCK_TABLE" &> /dev/null; then
        log_info "Creating DynamoDB table for state locking..."
        aws dynamodb create-table \
            --table-name "$LOCK_TABLE" \
            --attribute-definitions AttributeName=LockID,AttributeType=S \
            --key-schema AttributeName=LockID,KeyType=HASH \
            --billing-mode PAY_PER_REQUEST \
            --region "$REGION"

        log_info "DynamoDB table created: $LOCK_TABLE"
    else
        log_info "DynamoDB table already exists: $LOCK_TABLE"
    fi

    log_info "Terraform backend setup complete ✓"
}

create_tfvars() {
    log_info "Creating terraform.tfvars..."

    cd "$TERRAFORM_DIR"

    if [ -f "terraform.tfvars" ]; then
        log_warn "terraform.tfvars already exists. Backing up..."
        cp terraform.tfvars "terraform.tfvars.backup.$(date +%Y%m%d-%H%M%S)"
    fi

    cat > terraform.tfvars <<EOF
# Healthie Infrastructure Configuration
# Diamitani Industries

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

    log_info "terraform.tfvars created ✓"
}

initialize_terraform() {
    log_info "Initializing Terraform..."

    cd "$TERRAFORM_DIR"

    terraform init

    log_info "Terraform initialized ✓"
}

validate_terraform() {
    log_info "Validating Terraform configuration..."

    cd "$TERRAFORM_DIR"

    terraform validate

    log_info "Terraform validation passed ✓"
}

plan_infrastructure() {
    log_info "Planning infrastructure deployment..."

    cd "$TERRAFORM_DIR"

    terraform plan -out=tfplan

    log_info "Terraform plan created ✓"
    log_warn "Review the plan above carefully before proceeding."
}

apply_infrastructure() {
    log_info "Applying infrastructure..."

    cd "$TERRAFORM_DIR"

    if [ ! -f "tfplan" ]; then
        log_error "No plan file found. Run plan first."
        exit 1
    fi

    terraform apply tfplan

    log_info "Infrastructure deployed ✓"
}

configure_database() {
    log_info "Configuring RDS database..."

    cd "$TERRAFORM_DIR"

    local RDS_SECRET_ARN=$(terraform output -raw rds_secret_arn)
    local RDS_ENDPOINT=$(terraform output -raw rds_endpoint)

    # Get database credentials
    local DB_CREDS=$(aws secretsmanager get-secret-value \
        --secret-id "$RDS_SECRET_ARN" \
        --query SecretString \
        --output text)

    local DB_USER=$(echo "$DB_CREDS" | jq -r '.username')
    local DB_PASS=$(echo "$DB_CREDS" | jq -r '.password')
    local DB_HOST=$(echo "$DB_CREDS" | jq -r '.host')
    local DB_PORT=$(echo "$DB_CREDS" | jq -r '.port')
    local DB_NAME=$(echo "$DB_CREDS" | jq -r '.dbname')

    log_info "Database endpoint: $DB_HOST:$DB_PORT"

    # Note: You'll need to install pgvector extension manually
    # or use a Lambda function in VPC to do this
    log_warn "Manual step required: Install pgvector extension"
    log_warn "Run: CREATE EXTENSION IF NOT EXISTS vector;"
    log_warn "     CREATE EXTENSION IF NOT EXISTS pg_stat_statements;"
}

output_info() {
    log_info "Retrieving deployment outputs..."

    cd "$TERRAFORM_DIR"

    echo ""
    echo "=========================================="
    echo "Healthie Infrastructure Deployment Info"
    echo "=========================================="
    echo ""
    echo "Organization: $(terraform output -raw organization)"
    echo "Project: $(terraform output -raw project)"
    echo "Environment: $(terraform output -raw environment)"
    echo "Region: $(terraform output -raw region)"
    echo "Account ID: $(terraform output -raw account_id)"
    echo ""
    echo "API Gateway URL: $(terraform output -raw api_gateway_url)"
    echo "Cognito User Pool: $(terraform output -raw cognito_user_pool_id)"
    echo "Documents Bucket: $(terraform output -raw documents_bucket)"
    echo "Knowledge Base Bucket: $(terraform output -raw knowledge_base_bucket)"
    echo "Static Assets Bucket: $(terraform output -raw static_assets_bucket)"
    echo ""
    echo "CloudWatch Dashboard: $(terraform output -raw cloudwatch_dashboard_name)"
    echo "SNS Alerts Topic: $(terraform output -raw sns_alerts_topic_arn)"
    echo ""
    echo "=========================================="
    echo ""
}

main() {
    log_info "Starting Healthie infrastructure setup..."
    log_info "Organization: Diamitani Industries"
    log_info "Project: Healthie"
    echo ""

    check_prerequisites
    echo ""

    setup_terraform_backend
    echo ""

    create_tfvars
    echo ""

    initialize_terraform
    echo ""

    validate_terraform
    echo ""

    plan_infrastructure
    echo ""

    read -p "Do you want to apply this infrastructure? (yes/no): " response
    if [ "$response" != "yes" ]; then
        log_warn "Deployment cancelled by user."
        exit 0
    fi

    apply_infrastructure
    echo ""

    output_info
    echo ""

    log_info "Next steps:"
    log_info "1. Configure database: Run SQL migrations"
    log_info "2. Deploy Lambda functions: cd backend && ./scripts/deploy_lambdas.sh"
    log_info "3. Upload static assets: aws s3 sync web s3://\$(terraform output -raw static_assets_bucket)/"
    log_info "4. Create admin user in Cognito"
    log_info "5. Configure DNS for domain: healthie.diamitani.com"
    echo ""

    log_info "Setup complete! 🎉"
}

# Run main function
main "$@"
