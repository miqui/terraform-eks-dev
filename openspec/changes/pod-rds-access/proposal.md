## Why

The dev EKS cluster currently has no path for application pods to access AWS services like RDS. Pods running on the cluster need database access for real workloads, and the cluster already has OIDC/IRSA enabled (used by the LBC). Extending IRSA to application pods — plus provisioning a small RDS instance with proper security group wiring — gives pods secure, scoped database access without embedding long-lived credentials.

## What Changes

- New `modules/rds/` Terraform module: RDS instance, subnet group in private subnets, security group allowing ingress from the EKS node security group on port 5432, Secrets Manager secret storing DB credentials
- New `modules/app-iam/` Terraform module: IRSA IAM role for a configurable application ServiceAccount, with an IAM policy granting RDS access scoped to the provisioned instance
- Kubernetes ServiceAccount manifest annotated with the IRSA role ARN, plus a sample SecretProviderClass for mounting DB credentials as env vars
- Dev stack (`envs/dev/main.tf`) wiring: network → rds, eks → app-iam, rds → app-iam policy scoping
- Updated README with RDS access documentation

## Capabilities

### New Capabilities
- `rds`: RDS instance, subnet group, security group, and Secrets Manager secret for database credentials — the database layer pods connect to
- `app-iam`: IRSA IAM role for application pods, with RDS-scoped permissions delivered via OIDC — the credentials path from pod to AWS services

### Modified Capabilities
<!-- None — no existing specs are changing behavior. -->

## Impact

- **New AWS resources**: RDS instance (db.t4.micro for dev), DB subnet group, DB security group, Secrets Manager secret, IAM role + policy for app pods
- **New Terraform code**: `modules/rds/` (4-5 files), `modules/app-iam/` (3-4 files), dev stack wiring
- **New Kubernetes manifests**: ServiceAccount with role annotation, SecretProviderClass for Secrets Manager
- **Existing modules**: EKS module outputs must expose node security group ID (new output); network module outputs used by RDS module
- **Cost**: RDS db.t4.micro ~$13/month, Secrets Manager ~$0.40/secret/month, storage ~$0.115/GB/month
- **Security**: DB credentials stored in Secrets Manager, not in pod specs or tfvars; IRSA scopes pod permissions to RDS only
