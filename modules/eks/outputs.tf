output "cluster_name" {
  description = "Name of the EKS cluster"
  value       = aws_eks_cluster.this.name
}

output "cluster_endpoint" {
  description = "Endpoint for the EKS control plane"
  value       = aws_eks_cluster.this.endpoint
}

output "cluster_ca_data" {
  description = "Base64-encoded CA certificate for the cluster"
  value       = aws_eks_cluster.this.certificate_authority[0].data
}

output "cluster_oidc_issuer_url" {
  description = "OIDC issuer URL for the cluster (for IRSA)"
  value       = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

output "node_group_arn" {
  description = "ARN of the managed node group"
  value       = aws_eks_node_group.this.arn
}
