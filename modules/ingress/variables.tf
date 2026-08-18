variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "cluster_oidc_issuer" {
  description = "OIDC issuer URL for the cluster"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "lbc_chart_version" {
  description = "AWS Load Balancer Controller Helm chart version (pinned)"
  type        = string
  default     = "1.4.8"
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}
