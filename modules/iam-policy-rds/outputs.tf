output "policy_arn" {
  description = "ARN of the IAM policy for RDS access"
  value       = aws_iam_policy.this.arn
}
