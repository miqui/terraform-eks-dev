## 1. Remove RDS and service-specific modules

- [x] 1.1 Delete `modules/rds/` directory (variables.tf, main.tf, outputs.tf)
- [x] 1.2 Delete `modules/iam-policy-rds/` directory (variables.tf, main.tf, outputs.tf)
- [x] 1.3 Delete `k8s/sample/app-deployment.yaml` (depends on RDS secret + IRSA)

## 2. Clean up dev stack

- [x] 2.1 Remove `module "rds"` block from `envs/dev/main.tf`
- [x] 2.2 Remove `module "iam_policy_rds"` block from `envs/dev/main.tf`
- [x] 2.3 Simplify `module "app_iam"` in `envs/dev/main.tf` — set `attached_policy_arns = []` and `secret_arn = null`, remove any RDS-specific wiring
- [x] 2.4 Remove RDS variables from `envs/dev/variables.tf` (db_instance_class, db_name, db_username)
- [x] 2.5 Remove RDS values from `envs/dev/terraform.tfvars`
- [x] 2.6 Remove RDS outputs from `envs/dev/outputs.tf` (rds_endpoint, rds_secret_arn)

## 3. Verify app-iam module is clean

- [x] 3.1 Verify `modules/app-iam/` has no RDS-specific variables (confirmed — zero matches)
- [x] 3.2 Verify `modules/app-iam/outputs.tf` has no RDS-specific outputs (confirmed — zero matches)
- [x] 3.3 Add a comment in `modules/app-iam/variables.tf` above `attached_policy_arns` documenting that it's empty in the baseline and populated by service-specific changes

## 4. Remove superseded OpenSpec changes

- [x] 4.1 Delete `openspec/changes/pod-rds-access/` directory
- [x] 4.2 Delete `openspec/changes/refactor-app-iam-modular/` directory

## 5. Update README

- [x] 5.1 Remove "RDS & Pod DB Access" section
- [x] 5.2 Remove RDS cost line from the cost table (RDS cost was not in the table — cost table was already clean from the original baseline)
- [x] 5.3 Replace "Adding a New AWS Service" section with a cleaner version that starts from the empty baseline (not from an RDS-specific example)
- [x] 5.4 Update architecture diagram to show only: network → EKS → ingress → pod IAM (no RDS)
- [x] 5.5 Update repository layout to remove `modules/rds/` and `modules/iam-policy-rds/`, add `modules/app-iam/`
- [x] 5.6 Remove RDS tear-down notes (there were none beyond the general `terraform destroy`)

## 6. Validation

- [x] 6.1 Verify no stale references to `module.rds` or `module.iam_policy_rds` remain in `envs/dev/` (confirmed — zero matches)
- [x] 6.2 Verify brace balance in all .tf files (confirmed — all balanced)
- [x] 6.3 Document that `terraform validate` should be run locally before apply (already in README Validation section)
