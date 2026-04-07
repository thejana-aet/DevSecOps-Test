#!/bin/bash
set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}==> Verifying AWS prerequisites${NC}"
echo ""

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check Terraform (assumed to be pre-installed)
echo "Checking Terraform..."
if ! command_exists terraform; then
    echo -e "${RED}[ERROR] Terraform not found${NC}"
    echo ""
    echo "Terraform should already be installed."
    echo "Install: https://developer.hashicorp.com/terraform/install"
    exit 1
fi
echo -e "${GREEN}[OK] Terraform: $(terraform version | head -n1)${NC}"

# Check AWS CLI (assumed to be pre-installed)
echo "Checking AWS CLI..."
if ! command_exists aws; then
    echo -e "${RED}[ERROR] AWS CLI not found${NC}"
    echo ""
    echo "AWS CLI should already be installed."
    echo "Install: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html"
    exit 1
fi
AWS_CLI_VERSION=$(aws --version 2>&1 | head -n1)
if ! echo "$AWS_CLI_VERSION" | grep -q "aws-cli/2"; then
    echo -e "${RED}[ERROR] AWS CLI v2 required (found: ${AWS_CLI_VERSION})${NC}"
    echo "Install v2: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html"
    exit 1
fi
echo -e "${GREEN}[OK] AWS CLI: ${AWS_CLI_VERSION}${NC}"

echo ""
echo -e "${GREEN}[SUCCESS] All prerequisites verified${NC}"
echo ""
