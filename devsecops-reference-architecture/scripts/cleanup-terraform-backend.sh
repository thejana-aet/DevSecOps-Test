#!/bin/bash
# Clean up Terraform backend resources (S3 bucket and DynamoDB table)
# Use this to completely reset the Terraform state for a fresh start

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}==> Terraform Backend Cleanup${NC}"
echo ""

# AWS Profile Selection
echo "Available AWS profiles:"
aws configure list-profiles 2>/dev/null || echo "  default"
echo ""
read -p "Enter AWS profile to use (press Enter for 'default'): " AWS_PROFILE_INPUT
AWS_PROFILE=${AWS_PROFILE_INPUT:-default}
export AWS_PROFILE

echo ""
echo "Verifying AWS credentials for profile: $AWS_PROFILE"
if ! aws sts get-caller-identity >/dev/null 2>&1; then
    echo -e "${RED}[ERROR] AWS credentials not configured for profile '$AWS_PROFILE'${NC}"
    exit 1
fi

AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
AWS_REGION=$(grep '^aws_region' terraform/environments/shared/terraform.tfvars | sed 's/.*=\s*"\(.*\)".*/\1/')

echo -e "${GREEN}[OK] Account: $AWS_ACCOUNT_ID${NC}"
echo -e "${GREEN}[OK] Region: $AWS_REGION${NC}"
echo ""

BUCKET_NAME="devsecops-demo-tfstate-prod-us-east-1-${AWS_ACCOUNT_ID}"
DYNAMODB_TABLE="devsecops-demo-terraform-locks-prod"

echo -e "${YELLOW}[WARNING] This will delete:${NC}"
echo "  - S3 Bucket: $BUCKET_NAME (all versions)"
echo "  - DynamoDB Table: $DYNAMODB_TABLE"
echo "  - Local Terraform cache and state files"
echo ""
read -p "Are you sure? (type 'yes' to proceed): " confirm
if [ "$confirm" != "yes" ]; then
    echo "Cleanup cancelled."
    exit 0
fi

echo ""
echo -e "${CYAN}==> Deleting S3 bucket: $BUCKET_NAME${NC}"

# Check if bucket exists
if aws s3 ls "s3://${BUCKET_NAME}" 2>/dev/null; then
    # Delete all object versions
    echo "  - Deleting all object versions..."
    aws s3api delete-objects --bucket "$BUCKET_NAME" \
        --delete "$(aws s3api list-object-versions --bucket "$BUCKET_NAME" \
        --query '{Objects: Versions[].{Key:Key,VersionId:VersionId}}' --output json)" \
        2>/dev/null || true

    # Delete all delete markers
    echo "  - Deleting delete markers..."
    aws s3api delete-objects --bucket "$BUCKET_NAME" \
        --delete "$(aws s3api list-object-versions --bucket "$BUCKET_NAME" \
        --query '{Objects: DeleteMarkers[].{Key:Key,VersionId:VersionId}}' --output json)" \
        2>/dev/null || true

    # Delete bucket
    echo "  - Deleting bucket..."
    aws s3 rb "s3://${BUCKET_NAME}" 2>/dev/null || true
    echo -e "${GREEN}[OK] S3 bucket deleted${NC}"
else
    echo -e "${YELLOW}[WARNING] S3 bucket not found (may already be deleted)${NC}"
fi

echo ""
echo -e "${CYAN}==> Deleting DynamoDB table: $DYNAMODB_TABLE${NC}"

if aws dynamodb describe-table --table-name "$DYNAMODB_TABLE" --region "$AWS_REGION" >/dev/null 2>&1; then
    aws dynamodb delete-table --table-name "$DYNAMODB_TABLE" --region "$AWS_REGION" >/dev/null
    echo -e "${GREEN}[OK] DynamoDB table deleted${NC}"
else
    echo -e "${YELLOW}[WARNING] DynamoDB table not found (may already be deleted)${NC}"
fi

echo ""
echo -e "${CYAN}==> Cleaning local Terraform files${NC}"

# Clean up local files in terraform directory
cd "$(dirname "$0")/../terraform/environments/shared" || exit 1
rm -rf .terraform .terraform.lock.hcl tfplan backend.hcl .terraform-profile 2>/dev/null || true
echo -e "${GREEN}[OK] Local Terraform files cleaned${NC}"

echo ""
echo -e "${GREEN}[SUCCESS] Terraform backend completely cleaned!${NC}"
echo ""
echo "You can now run 'make aws-up' for a fresh deployment."
