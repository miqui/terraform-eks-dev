output "lbc_role_arn" {
  description = "IAM role ARN for the AWS Load Balancer Controller"
  value       = aws_iam_role.lbc.arn
}

output "lbc_release_status" {
  description = "Status of the LBC Helm release"
  value       = helm_release.aws_load_balancer_controller.status
}

output "ingress_class_name" {
  description = "Name of the IngressClass managed by the LBC"
  value       = kubernetes_ingress_class_v1.alb.metadata[0].name
}
