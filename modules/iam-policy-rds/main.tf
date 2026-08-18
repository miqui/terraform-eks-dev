resource "aws_iam_policy" "this" {
  name        = "terraform-eks-dev-rds-policy"
  description = "RDS connect and secret read for app pods"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "rds-db:connect"
        ]
        Resource = var.rds_instance_arn
      },
      {
        Effect = "Allow"
        Action = [
          "rds:DescribeDBInstances"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = var.rds_secret_arn
      }
    ]
  })

  tags = var.tags
}
