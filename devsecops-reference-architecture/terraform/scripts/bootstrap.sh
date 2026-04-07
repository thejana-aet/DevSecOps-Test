#!/bin/bash
# Bootstrap script to create S3 bucket and DynamoDB table for Terraform state

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}==> Bootstrapping Terraform Backend${NC}"
echo ""

# Check for AWS CLI
if ! command -v aws &> /dev/null; then
    echo -e "${RED}[ERROR] AWS CLI not found. Please install it first.${NC}"
    exit 1
fi

# AWS Profile Selection
echo -e "${BLUE}==> AWS Profile Selection${NC}"
echo ""
echo "Available profiles:"
aws configure list-profiles 2>/dev/null || echo "  default"
echo ""
read -p "Enter AWS profile to use (press Enter for 'default'): " AWS_PROFILE_INPUT
AWS_PROFILE=${AWS_PROFILE_INPUT:-default}

# Set profile for AWS CLI commands
if [ "$AWS_PROFILE" != "default" ]; then
    export AWS_PROFILE
    AWS_CLI_ARGS="--profile $AWS_PROFILE"
else
    AWS_CLI_ARGS=""
fi

echo ""
echo -e "${BLUE}[INFO] Verifying AWS credentials for profile: ${AWS_PROFILE}${NC}"
echo ""

# Check for AWS credentials
if ! aws sts get-caller-identity $AWS_CLI_ARGS &> /dev/null; then
    echo -e "${RED}[ERROR] AWS credentials not configured for profile '${AWS_PROFILE}'.${NC}"
    echo -e "${YELLOW}Run: aws configure --profile ${AWS_PROFILE}${NC}"
    exit 1
fi

# Get AWS account ID and region
AWS_ACCOUNT_ID=$(aws sts get-caller-identity $AWS_CLI_ARGS --query Account --output text)
AWS_USER_ARN=$(aws sts get-caller-identity $AWS_CLI_ARGS --query Arn --output text)

# Get region from terraform.tfvars (not from AWS CLI profile)
if [ -f "environments/shared/terraform.tfvars" ]; then
    AWS_REGION=$(grep '^aws_region' environments/shared/terraform.tfvars | sed 's/.*=\s*"\(.*\)".*/\1/')
    echo -e "${BLUE}[INFO] Using region from terraform.tfvars: ${AWS_REGION}${NC}"
else
    AWS_REGION=${AWS_REGION:-$(aws configure get region $AWS_CLI_ARGS || echo "us-east-1")}
    echo -e "${YELLOW}[WARNING] terraform.tfvars not found, using AWS CLI region: ${AWS_REGION}${NC}"
fi

# Get environment from terraform.tfvars
if [ -f "environments/shared/terraform.tfvars" ]; then
    ENVIRONMENT=$(grep '^environment' environments/shared/terraform.tfvars | sed 's/.*=\s*"\(.*\)".*/\1/')
    echo -e "${BLUE}[INFO] Using environment from terraform.tfvars: ${ENVIRONMENT}${NC}"
else
    ENVIRONMENT="prod"
    echo -e "${YELLOW}[WARNING] terraform.tfvars not found, using default environment: ${ENVIRONMENT}${NC}"
fi

echo -e "${GREEN}[OK] AWS Profile: ${AWS_PROFILE}${NC}"
echo -e "${GREEN}[OK] AWS Account ID: ${AWS_ACCOUNT_ID}${NC}"
echo -e "${GREEN}[OK] AWS User/Role: ${AWS_USER_ARN}${NC}"
echo -e "${GREEN}[OK] AWS Region: ${AWS_REGION}${NC}"
echo -e "${GREEN}[OK] Environment: ${ENVIRONMENT}${NC}"
echo ""

# S3 bucket name (must be globally unique)
# Include environment and region in name
BUCKET_NAME="devsecops-demo-tfstate-${ENVIRONMENT}-${AWS_REGION}-${AWS_ACCOUNT_ID}"
DYNAMODB_TABLE="devsecops-demo-terraform-locks-${ENVIRONMENT}"

echo -e "${CYAN}==> Bootstrapping Terraform backend for account ${AWS_ACCOUNT_ID}${NC}"
echo "  - S3 Bucket: ${BUCKET_NAME}"
echo "  - DynamoDB Table: ${DYNAMODB_TABLE}"
echo "  - Region: ${AWS_REGION}"
echo ""

echo -e "${YELLOW}Creating S3 bucket: ${BUCKET_NAME}${NC}"

# Check if bucket exists
if aws s3 ls "s3://${BUCKET_NAME}" $AWS_CLI_ARGS 2>&1 | grep -q 'NoSuchBucket'; then
    # Create bucket
    if [ "${AWS_REGION}" = "us-east-1" ]; then
        aws s3api create-bucket --bucket "${BUCKET_NAME}" --region "${AWS_REGION}" $AWS_CLI_ARGS > /dev/null
    else
        aws s3api create-bucket --bucket "${BUCKET_NAME}" --region "${AWS_REGION}" \
            --create-bucket-configuration LocationConstraint="${AWS_REGION}" $AWS_CLI_ARGS > /dev/null
    fi

    # Enable versioning
    aws s3api put-bucket-versioning \
        --bucket "${BUCKET_NAME}" \
        --versioning-configuration Status=Enabled $AWS_CLI_ARGS > /dev/null

    # Enable encryption
    aws s3api put-bucket-encryption \
        --bucket "${BUCKET_NAME}" \
        --server-side-encryption-configuration '{
            "Rules": [{
                "ApplyServerSideEncryptionByDefault": {
                    "SSEAlgorithm": "AES256"
                }
            }]
        }' $AWS_CLI_ARGS > /dev/null

    # Block public access
    aws s3api put-public-access-block \
        --bucket "${BUCKET_NAME}" \
        --public-access-block-configuration \
            "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true" $AWS_CLI_ARGS > /dev/null

    echo -e "${GREEN}[OK] S3 bucket created: ${BUCKET_NAME}${NC}"
else
    echo -e "${YELLOW}[WARNING] S3 bucket already exists: ${BUCKET_NAME}${NC}"
fi

echo ""
echo -e "${CYAN}==> Creating DynamoDB table: ${DYNAMODB_TABLE}${NC}"

# Check if table exists
if ! aws dynamodb describe-table --table-name "${DYNAMODB_TABLE}" --region "${AWS_REGION}" $AWS_CLI_ARGS &> /dev/null; then
    # Create DynamoDB table for state locking
    aws dynamodb create-table \
        --table-name "${DYNAMODB_TABLE}" \
        --attribute-definitions AttributeName=LockID,AttributeType=S \
        --key-schema AttributeName=LockID,KeyType=HASH \
        --billing-mode PAY_PER_REQUEST \
        --region "${AWS_REGION}" \
        --tags Key=Project,Value=devsecops-demo Key=ManagedBy,Value=terraform $AWS_CLI_ARGS > /dev/null

    echo -e "${GREEN}[OK] DynamoDB table created: ${DYNAMODB_TABLE}${NC}"
else
    echo -e "${YELLOW}[WARNING] DynamoDB table already exists: ${DYNAMODB_TABLE}${NC}"
fi

echo ""
echo -e "${GREEN}[SUCCESS] Terraform backend bootstrapped successfully!${NC}"
echo ""
echo -e "${BLUE}[INFO] Backend configuration created:${NC}"
echo ""
cat <<EOF
bucket         = "${BUCKET_NAME}"
key            = "devsecops-demo-${ENVIRONMENT}/terraform.tfstate"
region         = "${AWS_REGION}"
dynamodb_table = "${DYNAMODB_TABLE}"
encrypt        = true
EOF
echo ""

# Create backend.hcl file automatically
BACKEND_CONFIG_FILE="environments/shared/backend.hcl"
cat > "${BACKEND_CONFIG_FILE}" <<EOF
bucket         = "${BUCKET_NAME}"
key            = "devsecops-demo-${ENVIRONMENT}/terraform.tfstate"
region         = "${AWS_REGION}"
dynamodb_table = "${DYNAMODB_TABLE}"
encrypt        = true
EOF

echo -e "${GREEN}[OK] Created backend configuration: ${BACKEND_CONFIG_FILE}${NC}"
echo ""

# Save the selected profile for terraform commands
PROFILE_FILE="environments/shared/.terraform-profile"
echo "${AWS_PROFILE}" > "${PROFILE_FILE}"
echo -e "${GREEN}[OK] Saved AWS profile for Terraform: ${AWS_PROFILE}${NC}"

if [ "$AWS_PROFILE" != "default" ]; then
    echo -e "${BLUE}[INFO] Terraform will use profile: ${AWS_PROFILE}${NC}"
    echo ""
fi

echo -e "${GREEN}[OK] Backend ready for Terraform initialization${NC}"
echo ""
