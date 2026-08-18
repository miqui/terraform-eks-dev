## Why

The current repo bundles RDS provisioning into the EKS cluster stack, but the cluster and its services should be separate concerns. A clean dev EKS cluster (network + EKS + ingress + generic pod IAM) should stand on its own, with service access (RDS, S3, SQS) added as separate changes when needed. The current `pod-rds-access` and `refactor-app-iam-modular` changes were built on top of a design that conflated cluster provisioning with service provisioning. This change corrects that by separating the cluster baseline from service-specific modules.

## What Changes

- **BREAKING**: Remove `modules/rds/` from the cluster baseline — RDS is a service, not part of the cluster
- **BREAKING**: Remove `modules/iam-policy-rds/` from the cluster baseline — service-specific policies are layered on separately
- Move the `modules/app-iam/` generic IRSA role module into the cluster baseline as a first-class module (it was already refactored to be generic in the previous change)
- Remove the `module "rds"` and `module "iam_policy_rds"` blocks from `envs/dev/main.tf`
- Remove the `module "app_iam"` RDS-specific wiring from `envs/dev/main.tf` — `app_iam` stays but with no policies attached and no secret (clean baseline)
- Remove RDS variables (`db_instance_class`, `db_name`, `db_username`) from `envs/dev/variables.tf` and `terraform.tfvars`
- Remove RDS outputs (`rds_endpoint`, `rds_secret_arn`) from `envs/dev/outputs.tf`
- Remove `k8s/sample/app-deployment.yaml` (depends on RDS secret) — keep `k8s/sample/deployment.yaml` (the nginx ingress sample)
- Update README to reflect the clean cluster baseline, document that service access is added as separate OpenSpec changes
- Archive or supersede the `pod-rds-access` and `refactor-app-iam-modular` changes — their implementation is folded into this change

## Capabilities

### New Capabilities
- `pod-iam`: Generic IRSA role + ServiceAccount module as part of the cluster baseline — gives pods a ready-to-use identity with no service-specific permissions, to which policy modules are attached in separate changes

### Modified Capabilities
- `app-iam`: Renamed conceptually to `pod-iam` — the IRSA role module is now part of the cluster baseline rather than a service-specific add-on. The capability name changes from `app-iam` to `pod-iam` to reflect that it's a cluster component, not an app-specific one

## Impact

- **Deleted files**: `modules/rds/` (3 files), `modules/iam-policy-rds/` (3 files), `k8s/sample/app-deployment.yaml`
- **Modified files**: `envs/dev/main.tf` (remove rds + iam_policy_rds modules, simplify app_iam wiring), `envs/dev/variables.tf` (remove RDS vars), `envs/dev/terraform.tfvars` (remove RDS values), `envs/dev/outputs.tf` (remove RDS outputs), `README.md`
- **OpenSpec changes**: `pod-rds-access` and `refactor-app-iam-modular` are superseded — their useful work (generic app-iam refactor, node SG output, EKS module improvements) is preserved; their RDS-specific artifacts are discarded
- **No AWS resource changes**: The cluster baseline (network + EKS + ingress) is unchanged. RDS was never deployed (no `terraform apply` was run). This is a code organization refactor only.
