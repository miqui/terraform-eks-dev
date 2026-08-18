variable "region" {
  description = "AWS region for the dev cluster"
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "dev-eks-cluster"
}

variable "endpoint_public_access_cidrs" {
  description = "List of CIDR blocks allowed to access the public cluster endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "node_instance_type" {
  description = "EC2 instance type for the managed node group"
  type        = string
  default     = "t3.medium"
}

variable "node_desired_capacity" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 2
}

variable "node_min_capacity" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 1
}

variable "node_max_capacity" {
  description = "Maximum number of worker nodes"
  type        = number
  default     = 3
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days for control-plane logs"
  type        = number
  default     = 7
}

variable "lbc_chart_version" {
  description = "AWS Load Balancer Controller Helm chart version (pinned)"
  type        = string
  default     = "1.4.8"
}
