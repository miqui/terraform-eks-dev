data "aws_iam_openid_connect_provider" "cluster" {
  url = var.cluster_oidc_issuer
}

# IRSA IAM role for the app ServiceAccount
resource "aws_iam_role" "app" {
  name = "${var.cluster_name}-app-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = data.aws_iam_openid_connect_provider.cluster.arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${replace(var.cluster_oidc_issuer, "https://", "")}:sub" = "system:serviceaccount:${var.app_sa_namespace}:${var.app_sa_name}"
          "${replace(var.cluster_oidc_issuer, "https://", "")}:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })

  tags = var.tags
}

# Attach external policy ARNs (from iam-policy-* modules)
resource "aws_iam_role_policy_attachment" "this" {
  for_each = toset(var.attached_policy_arns)

  role       = aws_iam_role.app.name
  policy_arn = each.value
}

# Kubernetes ServiceAccount with IRSA annotation
resource "kubernetes_service_account_v1" "app" {
  metadata {
    name      = var.app_sa_name
    namespace = var.app_sa_namespace
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.app.arn
    }
  }

  depends_on = [aws_iam_role_policy_attachment.this]
}

# SecretProviderClass — only created when secret_arn is provided
resource "kubernetes_manifest" "secret_provider_class" {
  count = var.secret_arn != null ? 1 : 0

  manifest = {
    apiVersion = "secrets-store.csi.x-k8s.io/v1"
    kind       = "SecretProviderClass"
    metadata = {
      name      = "app-secret-spc"
      namespace = var.app_sa_namespace
    }
    spec = {
      provider = "aws"
      parameters = {
        objects = jsonencode([
          {
            objectName = "app-secret"
            objectType = "secretsmanager"
            objectAlias = "mounted-secret"
          }
        ])
        region = var.region
      }
      secretObjects = [
        {
          secretName = var.secret_name
          type       = "Opaque"
          data = [
            {
              objectName = "mounted-secret"
              key        = var.secret_key
            }
          ]
        }
      ]
    }
  }

  depends_on = [kubernetes_service_account_v1.app]
}
