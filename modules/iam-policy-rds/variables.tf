variable "rds_instance_arn" {
  description = "ARN of the RDS instance to grant access to"
  type        = string
}

variable "rds_secret_arn" {
  description = "ARN of the Secrets Manager secret containing the DB password"
  type        = string
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}
