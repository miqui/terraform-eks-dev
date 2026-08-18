## Why

The current `modules/app-iam/` hardcodes RDS-specific permissions and requires RDS inputs, so creating a second IRSA role for a different workload (S3, SQS, DynamoDB) means duplicating the module or passing dummy values. Separating the generic IRSA role + ServiceAccount from service-specific IAM policies makes the module composable and lets any workload get scoped AWS access without touching the role logic.

## What Changes

- **BREAKING**: `modules/app-iam/` refactored — no longer creates IAM policies or requires RDS inputs. It creates only the IRSA IAM role and Kubernetes ServiceAccount, and accepts a list of policy ARNs to attach
- New `modules/iam-policy-rds/` — standalone IAM policy granting `rds-db:connect` + `secretsmanager:GetSecretValue` scoped to a specific RDS instance and secret
- Dev stack rewired: `app_iam` module + `iam_policy_rds` module composed together, with the policy ARN passed to `app_iam`
- `modules/app-iam/` variables cleaned: RDS-specific inputs removed; `attached_policy_arns` list added
- SecretProviderClass stays in `app-iam` (it's generic — mounts any secret), but the secret ARN becomes a generic variable instead of RDS-specific
- `modules/app-iam/` can now be instantiated multiple times with different ServiceAccount names for different workloads

## Capabilities

### New Capabilities
- `iam-policy-rds`: Standalone IAM policy module granting RDS connect + secret read permissions, scoped to a specific instance and secret — reusable and composable with any IRSA role

### Modified Capabilities
- `app-iam`: IRSA role + ServiceAccount module refactored from RDS-specific to generic — accepts any list of policy ARNs instead of hardcoding RDS permissions

## Impact

- **Modified files**: `modules/app-iam/variables.tf` (remove RDS vars, add `attached_policy_arns`), `modules/app-iam/main.tf` (remove policy resource, accept policy ARNs), `envs/dev/main.tf` (add `iam_policy_rds` module, rewire `app_iam`)
- **New files**: `modules/iam-policy-rds/` (variables.tf, main.tf, outputs.tf)
- **Breaking**: Any existing reference to `module.app_iam` RDS-specific outputs must be updated; the policy ARN is now an output of `iam_policy_rds` passed as input to `app_iam`
- **No new AWS resources**: Same IAM role, same ServiceAccount, same policy — just reorganized into two modules instead of one
