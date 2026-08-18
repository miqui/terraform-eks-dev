output "app_role_arn" {
  description = "IAM role ARN for the application pods"
  value       = aws_iam_role.app.arn
}

output "app_sa_name" {
  description = "Name of the application ServiceAccount"
  value       = kubernetes_service_account_v1.app.metadata[0].name
}

output "secret_provider_class_name" {
  description = "Name of the SecretProviderClass, or null if not created"
  value       = var.secret_arn != null ? kubernetes_manifest.secret_provider_class[0].manifest.name : null
}
