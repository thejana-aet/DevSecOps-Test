# Terraform Variables - Parameterized Infrastructure
# This file controls the environment being deployed

environment = "prod"
aws_region  = "us-east-1"

# VPC Configuration
vpc_cidr           = "10.0.0.0/16"
availability_zones = ["us-east-1a", "us-east-1b"]

# EKS Configuration
# Use latest stable version (check: https://docs.aws.amazon.com/eks/latest/userguide/kubernetes-versions.html)
cluster_version = "1.35" # Latest version (released Jan 2026)

# API Access - public (lock down for production)
enable_public_access = true
public_access_cidrs  = ["0.0.0.0/0"] # TODO: Restrict to your IP in production

# Control Plane Logs (minimal for cost)
enabled_cluster_log_types = ["api", "audit"]

# Node Group - Staging Configuration
node_ami_type = "BOTTLEROCKET_x86_64" # Bottlerocket = most secure, container-optimized
# Options: BOTTLEROCKET_x86_64, AL2023_x86_64_STANDARD, AL2_x86_64
node_instance_types = ["t3a.small"] # AMD = cheaper than Intel (t3)
node_capacity_type  = "ON_DEMAND"
node_desired_size   = 3
node_min_size       = 2
node_max_size       = 3
node_disk_size      = 20

# Note: Spot instances save cost but may have capacity issues during peak hours.

# Additional IAM Users (optional)
# Add your IAM user ARN here if you want cluster access
additional_iam_users = {
  # "your-name" = "arn:aws:iam::123456789012:user/your-username"
}
