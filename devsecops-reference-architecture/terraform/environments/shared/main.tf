# Main Terraform Configuration - Shared Infrastructure
# Creates VPC and EKS cluster

locals {
  cluster_name = "devsecops-demo-${var.environment}"

  common_tags = {
    Environment = var.environment
    Cluster     = local.cluster_name
  }
}

# VPC Module
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = local.cluster_name
  cidr = var.vpc_cidr

  azs            = var.availability_zones
  public_subnets = [for i, az in var.availability_zones : cidrsubnet(var.vpc_cidr, 8, i)]

  # Public-only VPC (no NAT or private subnets)
  enable_nat_gateway      = false
  map_public_ip_on_launch = true

  public_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                      = "1"
  }

  tags = local.common_tags
}

# EKS Module
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = local.cluster_name
  cluster_version = var.cluster_version

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.public_subnets

  cluster_endpoint_public_access           = var.enable_public_access
  cluster_endpoint_public_access_cidrs     = var.public_access_cidrs
  cluster_enabled_log_types                = var.enabled_cluster_log_types
  enable_cluster_creator_admin_permissions = true

  eks_managed_node_group_defaults = {
    ami_type      = var.node_ami_type
    capacity_type = var.node_capacity_type
    disk_size     = var.node_disk_size
    labels        = merge({ Environment = var.environment, NodeGroup = "default" }, var.node_labels)
  }

  eks_managed_node_groups = {
    default = {
      instance_types = var.node_instance_types
      desired_size   = var.node_desired_size
      min_size       = var.node_min_size
      max_size       = var.node_max_size
      subnet_ids     = module.vpc.public_subnets
    }
  }

  cluster_addons = {
    vpc-cni = {
      addon_version               = var.vpc_cni_version
      resolve_conflicts_on_create = "OVERWRITE"
      resolve_conflicts_on_update = "PRESERVE"
    }
    kube-proxy = {
      addon_version               = var.kube_proxy_version
      resolve_conflicts_on_create = "OVERWRITE"
      resolve_conflicts_on_update = "PRESERVE"
    }
    coredns = {
      addon_version               = var.coredns_version
      resolve_conflicts_on_create = "OVERWRITE"
      resolve_conflicts_on_update = "PRESERVE"
    }
  }

  access_entries = {
    for name, principal in var.additional_iam_users : name => {
      principal_arn = principal
      type          = "STANDARD"
      policy_associations = [{
        policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
        access_scope = {
          type = "cluster"
        }
      }]
    }
  }

  tags = local.common_tags

  depends_on = [module.vpc]
}

# Note: Container image stored in ECR
# Update image tag in k8s/backend-deployment.yaml via CI
# Image URL: <aws_account_id>.dkr.ecr.us-east-1.amazonaws.com/devsecops/backend
