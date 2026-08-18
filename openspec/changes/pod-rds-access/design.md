## Context

The cluster already has OIDC/IRSA enabled (used by the LBC in `modules/ingress/`). The network module provides private subnets. The EKS module creates a node group with a security group, but does not currently expose that security group ID as an output — that needs to be added. See proposal.md for motivation.

## Goals / Non-Goals

**Goals:**
- Application pods can connect to a PostgreSQL RDS instance using IRSA-scoped credentials
- DB credentials stored in Secrets Manager, never in pod specs or tfvars
- RDS reachable only from EKS nodes, not from the internet
- New `modules/rds/` and `modules/app-iam/` following the same module pattern as network/eks/ingress

**Non-Goals:**
- Multi-AZ RDS or read replicas (dev only)
- Read replicas, automated backups beyond default, or point-in-time recovery
- Secret rotation Lambda (password is generated once at create time; rotation is a follow-up)
- Cross-account or cross-cluster access
- RDS Proxy (connection pooling is overkill for dev)

## Decisions

### 1. RDS instance: db.t4.micro, PostgreSQL 16, single-AZ
Dev-grade: cheapest available instance, single-AZ (multi-AZ is not worth it for a throwaway dev DB).

**Alternative considered:** Aurora Serverless v2. Rejected — more expensive, more complex, not needed for dev.

### 2. Secrets Manager for DB password
Use `aws_secretsmanager_secret` with a randomly generated password (`random_password` resource). The RDS instance references the secret value for its master password. The secret ARN is passed to the app-iam module so pods can read it.

**Alternative considered:** SSM Parameter Store (securestring). Rejected — Secrets Manager is the standard for RDS integration, and the Terraform `rds` provider has native support for referencing Secrets Manager secrets via `manage_master_user_password`.

**Decision**: Use `manage_master_user_password = true` on the RDS instance (AWS-managed secret in Secrets Manager automatically), rather than a separate `random_password` + `aws_secretsmanager_secret`. This is the modern approach — AWS creates and manages the secret, and we read its ARN from the RDS instance attribute.

### 3. IRSA for app pods (same pattern as LBC)
Create an IAM role with OIDC trust for the app ServiceAccount, attach a policy with `rds-db:connect` on the instance ARN and `secretsmanager:GetSecretValue` on the secret ARN.

**Alternative considered:** node IAM role permissions. Rejected — overbroad, every pod gets DB access.

### 4. Security group wiring: EKS node SG → RDS SG
The RDS security group allows ingress on 5432 from the EKS node security group. This requires the EKS module to output its node security group ID. Pods run on nodes, so this is the correct traffic path.

**Alternative considered:** Pod security group (SecurityGroupForPods). Rejected — adds complexity; node SG ingress is sufficient for dev.

### 5. SecretProviderClass for mounting DB creds to pods
Use the AWS Secrets & Configuration Provider (ASCP) via a `SecretProviderClass` CRD so pods can mount DB credentials as environment variables. This keeps credentials out of pod specs.

**Alternative considered:** env vars directly from the secret. Rejected — requires CSI driver anyway, and SecretProviderClass is the standard pattern.

### 6. Module layout
```
modules/
├── rds/          # RDS instance, subnet group, SG, secret reference
└── app-iam/      # IRSA role, IAM policy, ServiceAccount + SecretProviderClass manifests
```

Both modules are composed in `envs/dev/main.tf` alongside the existing network, eks, and ingress modules.

## Risks / Trade-offs

- **[RDS cost]** → db.t4.micro is ~$13/mo; acceptable for dev. Mitigation: `terraform destroy` tears it down.
- **[Secret management]** → Using `manage_master_user_password` means AWS controls the secret lifecycle; deleting the RDS instance may retain the secret. Mitigation: add `lifecycle.ignore_changes` and document cleanup in README.
- **[Node SG coupling]** → RDS ingress is scoped to the node SG, which is broader than individual pod SGs. Acceptable for dev; for prod, use SecurityGroupForPods.
- **[Provider dependency]** → app-iam module needs the OIDC issuer URL (from eks module) and the RDS instance ARN + secret ARN (from rds module). Module ordering in main.tf handles this.
