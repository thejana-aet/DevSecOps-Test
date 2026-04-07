# Environment Variables

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (staging/production)"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "cluster_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.35"
}

# EKS API Access
variable "enable_public_access" {
  description = "Enable public API server endpoint"
  type        = bool
  default     = true
}

variable "public_access_cidrs" {
  description = "CIDR blocks allowed to access public API endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "enabled_cluster_log_types" {
  description = "List of control plane logs to enable"
  type        = list(string)
  default     = ["api", "audit", "authenticator"]
}

# Node Group Configuration
variable "node_ami_type" {
  description = "AMI type for node group"
  type        = string
  default     = "BOTTLEROCKET_x86_64"
}

variable "node_instance_types" {
  description = "Instance types for node group"
  type        = list(string)
  default     = ["t3a.small"]
}

variable "node_capacity_type" {
  description = "Capacity type: ON_DEMAND or SPOT"
  type        = string
  default     = "SPOT"
}

variable "node_desired_size" {
  description = "Desired number of nodes"
  type        = number
  default     = 2
}

variable "node_min_size" {
  description = "Minimum number of nodes"
  type        = number
  default     = 1
}

variable "node_max_size" {
  description = "Maximum number of nodes"
  type        = number
  default     = 3
}

variable "node_disk_size" {
  description = "Disk size for nodes in GB"
  type        = number
  default     = 20
}

variable "node_labels" {
  description = "Extra labels to apply to all managed node groups"
  type        = map(string)
  default     = {}
}

# EKS Addons
variable "vpc_cni_version" {
  description = "Version of vpc-cni addon"
  type        = string
  default     = null
}

variable "kube_proxy_version" {
  description = "Version of kube-proxy addon"
  type        = string
  default     = null
}

variable "coredns_version" {
  description = "Version of coredns addon"
  type        = string
  default     = null
}

# Additional Access
variable "additional_iam_users" {
  description = "Map of additional IAM users/roles to grant cluster access"
  type        = map(string)
  default     = {}
}
