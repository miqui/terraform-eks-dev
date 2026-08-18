output "cluster_name" {
  description = "Name of the EKS cluster"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "Endpoint for the EKS control plane"
  value       = module.eks.cluster_endpoint
}

output "cluster_ca_data" {
  description = "Base64-encoded CA certificate for the cluster"
  value       = module.eks.cluster_ca_data
  sensitive   = true
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.network.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.network.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = module.network.private_subnet_ids
}

output "lbc_role_arn" {
  description = "IAM role ARN for the AWS Load Balancer Controller"
  value       = module.ingress.lbc_role_arn
}

output "kubectl_config_command" {
  description = "Command to configure kubectl for the cluster"
  value       = "aws eks update-kubeconfig --name ${module.eks.cluster_name} --region ${var.region}"
}

output "rds_endpoint" {
  description = "Endpoint of the RDS instance"
  value       = module.rds.rds_endpoint
}

output "rds_secret_arn" {
  description = "Secrets Manager secret ARN for DB credentials"
  value       = module.rds.rds_secret_arn
}

output "app_role_arn" {
  description = "IAM role ARN for application pods (IRSA)"
  value       = module.app_iam.app_role_arn
}
