#!/usr/bin/env bash
set -euo pipefail

# Healthie Quick Start
# Diamitani Industries

cat << "EOF"
┌─────────────────────────────────────────────────────────────────┐
│                                                                   │
│   ██╗  ██╗███████╗ █████╗ ██╗  ████████╗██╗  ██╗██╗███████╗     │
│   ██║  ██║██╔════╝██╔══██╗██║  ╚══██╔══╝██║  ██║██║██╔════╝     │
│   ███████║█████╗  ███████║██║     ██║   ███████║██║█████╗       │
│   ██╔══██║██╔══╝  ██╔══██║██║     ██║   ██╔══██║██║██╔══╝       │
│   ██║  ██║███████╗██║  ██║███████╗██║   ██║  ██║██║███████╗     │
│   ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚══════╝╚═╝   ╚═╝  ╚═╝╚═╝╚══════╝     │
│                                                                   │
│            Diamitani Industries - Health Intelligence             │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘

EOF

echo "Welcome to Healthie setup!"
echo ""
echo "This will guide you through deploying Healthie infrastructure to AWS."
echo ""

# Check if we're in the right directory
if [ ! -f "README.md" ] || [ ! -d "infrastructure" ]; then
    echo "❌ Please run this script from the healthie repository root."
    exit 1
fi

echo "📋 Deployment Options:"
echo ""
echo "1. Full Infrastructure Deployment (Recommended)"
echo "   - Creates complete AWS infrastructure"
echo "   - Estimated time: 20-30 minutes"
echo "   - Cost: ~\$263/month"
echo ""
echo "2. View Deployment Guide"
echo "   - Read detailed deployment documentation"
echo ""
echo "3. Check Prerequisites"
echo "   - Verify AWS CLI, Terraform, etc."
echo ""
echo "4. Exit"
echo ""

read -p "Select option [1-4]: " option

case $option in
    1)
        echo ""
        echo "🚀 Starting full infrastructure deployment..."
        echo ""
        ./infrastructure/scripts/setup-infrastructure.sh
        ;;
    2)
        echo ""
        if command -v less &> /dev/null; then
            less DEPLOYMENT.md
        elif command -v more &> /dev/null; then
            more DEPLOYMENT.md
        else
            cat DEPLOYMENT.md
        fi
        ;;
    3)
        echo ""
        echo "🔍 Checking prerequisites..."
        echo ""

        # Check AWS CLI
        if command -v aws &> /dev/null; then
            echo "✅ AWS CLI: $(aws --version | head -1)"
        else
            echo "❌ AWS CLI: Not found"
            echo "   Install: https://aws.amazon.com/cli/"
        fi

        # Check Terraform
        if command -v terraform &> /dev/null; then
            echo "✅ Terraform: $(terraform version | head -1)"
        else
            echo "❌ Terraform: Not found"
            echo "   Install: https://www.terraform.io/downloads"
        fi

        # Check jq
        if command -v jq &> /dev/null; then
            echo "✅ jq: $(jq --version)"
        else
            echo "❌ jq: Not found"
            echo "   Install: https://stedolan.github.io/jq/"
        fi

        # Check Python
        if command -v python3 &> /dev/null; then
            echo "✅ Python: $(python3 --version)"
        else
            echo "❌ Python: Not found"
        fi

        # Check AWS credentials
        echo ""
        echo "Checking AWS credentials..."
        if aws sts get-caller-identity &> /dev/null; then
            echo "✅ AWS Credentials: Configured"
            aws sts get-caller-identity | jq -r '"Account: \(.Account)\nUser: \(.Arn)"'
        else
            echo "❌ AWS Credentials: Not configured"
            echo "   Run: aws configure"
        fi

        echo ""
        echo "Prerequisites check complete!"
        ;;
    4)
        echo ""
        echo "👋 Goodbye!"
        exit 0
        ;;
    *)
        echo ""
        echo "❌ Invalid option"
        exit 1
        ;;
esac

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📚 Next Steps:"
echo ""
echo "1. Review DEPLOYMENT.md for detailed instructions"
echo "2. Implement backend Lambda functions in backend/"
echo "3. Set up database schema (see DEPLOYMENT.md Phase 3)"
echo "4. Deploy Lambda code"
echo "5. Upload static assets"
echo "6. Create admin user in Cognito"
echo "7. Configure DNS"
echo ""
echo "📧 Support: infrastructure@diamitani.com"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
