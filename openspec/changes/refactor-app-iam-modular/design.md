## Context

The `modules/app-iam/` module currently bundles three concerns: (1) IRSA role creation, (2) RDS-specific IAM policy, (3) Kubernetes ServiceAccount + SecretProviderClass. This makes it impossible to reuse the role for a non-RDS workload without duplicating the module or passing dummy RDS values. See proposal.md for motivation.

## Goals / Non-Goals

**Goals:**
- `modules/app-iam/` becomes generic: IRSA role + ServiceAccount + optional SecretProviderClass, no service-specific policy
- New `modules/iam-policy-rds/` holds the RDS-specific policy, composable with any role
- Zero new AWS resources — same role, same policy, same SA, just split across two modules
- Future workloads (S3, SQS) get their own `modules/iam-policy-<service>/` and attach to a new `app-iam` instance

**Non-Goals:**
- Creating policy modules for S3, SQS, or other services (those are separate changes when needed)
- Changing the SecretProviderClass CSI driver installation (already documented in README)
- Changing RDS module or network module (no impact)

## Decisions

### 1. Split: `app-iam` (role) + `iam-policy-rds` (policy)

```
BEFORE (one module):              AFTER (two modules):
┌─────────────────────┐          ┌─────────────────────┐
│ modules/app-iam/    │          │ modules/app-iam/    │
│  - IRSA role        │          │  - IRSA role        │
│  - RDS IAM policy   │  ──►     │  - ServiceAccount    │
│  - ServiceAccount   │          │  - SecretProviderClass│
│  - SecretProviderClass│        │  (generic, optional) │
└─────────────────────┘          └─────────┬───────────┘
                                           │ attached_policy_arns
                                           ▼
                                 ┌─────────────────────┐
                                 │ modules/iam-policy-  │
                                 │   rds/               │
                                 │  - IAM policy only  │
                                 │  (rds-db:connect +   │
                                 │   secretsmanager)    │
                                 └─────────────────────┘
```

**Alternative considered:** Make `app-iam` accept a list of inline policy statements. Rejected — separate policy modules are cleaner, each service's permissions are isolated and reusable, and `aws_iam_policy` resources are easier to audit than inline JSON in variables.

### 2. `attached_policy_arns` as a list(string) variable

```hcl
variable "attached_policy_arns" {
  description = "IAM policy ARNs to attach to the IRSA role"
  type        = list(string)
  default     = []
}
```

Using `for_each` on `aws_iam_role_policy_attachment` to attach each policy:

```hcl
resource "aws_iam_role_policy_attachment" "this" {
  for_each = toset(var.attached_policy_arns)
  role       = aws_iam_role.app.name
  policy_arn = each.value
}
```

### 3. SecretProviderClass becomes optional and generic

The SecretProviderClass moves from RDS-specific to generic. Variables:
- `secret_arn` (optional, default `null`) — if provided, a SecretProviderClass is created
- `secret_name` (optional, default `"app-secret"`) — Kubernetes secret name
- `secret_key` (optional, default `"password"`) — key in the mounted secret

When `secret_arn` is `null`, no SecretProviderClass is created. This lets workloads that don't need secret mounting skip it.

### 4. Dev stack composition

```hcl
module "iam_policy_rds" {
  source = "../../modules/iam-policy-rds"
  rds_instance_arn = module.rds.rds_arn
  rds_secret_arn   = module.rds.rds_secret_arn
}

module "app_iam" {
  source = "../../modules/app-iam"
  cluster_name        = module.eks.cluster_name
  cluster_oidc_issuer = module.eks.cluster_oidc_issuer_url
  app_sa_name         = "my-app-sa"
  app_sa_namespace    = "default"
  region              = var.region
  attached_policy_arns = [module.iam_policy_rds.policy_arn]
  secret_arn   = module.rds.rds_secret_arn
  secret_name  = "app-db-credentials"
}
```

Future S3 workload:
```hcl
module "iam_policy_s3" { ... }
module "worker_iam" {
  source = "../../modules/app-iam"
  app_sa_name = "worker-sa"
  attached_policy_arns = [module.iam_policy_s3.policy_arn]
  # no secret_arn — worker doesn't need secret mounting
}
```

## Risks / Trade-offs

- **[Breaking change]** → Any reference to `module.app_iam` that expects RDS-specific outputs must be updated. Since this is a dev project with no other consumers, the blast radius is contained to `envs/dev/main.tf`.
- **[More modules]** → Two modules where there was one. Mitigation: the composition is clean and the trade-off is reusability — adding a third service is a new policy module + a new `app-iam` instance, no duplication.
- **[SecretProviderClass generality]** → Making the secret generic means the module doesn't "know" it's an RDS password. Acceptable — the SecretProviderClass just mounts a secret; the pod decides how to use it.
