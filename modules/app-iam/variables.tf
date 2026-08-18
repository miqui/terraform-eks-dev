variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "cluster_oidc_issuer" {
  description = "OIDC issuer URL for the cluster"
  type        = string
}

variable "app_sa_name" {
  description = "Name of the application ServiceAccount"
  type        = string
  default     = "my-app-sa"
}

variable "app_sa_namespace" {
  description = "Namespace of the application ServiceAccount"
  type        = string
  default     = "default"
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "attached_policy_arns" {
  description = "IAM policy ARNs to attach to the IRSA role"
  type        = list(string)
  default     = []
}

variable "secret_arn" {
  description = "Secrets Manager secret ARN to mount via SecretProviderClass. If null, no SPC is created."
  type        = string
  default     = null
}

variable "secret_name" {
  description = "Name of the Kubernetes secret created by the SecretProviderClass"
  type        = string
  default     = "app-secret"
}

variable "secret_key" {
  description = "Key name in the Kubernetes secret for the mounted value"
  type        = string
  default     = "password"
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}
