## 1. New Module: iam-policy-rds

- [x] 1.1 Create `modules/iam-policy-rds/variables.tf`: rds_instance_arn, rds_secret_arn, tags
- [x] 1.2 Create `modules/iam-policy-rds/main.tf`: `aws_iam_policy` with `rds-db:connect` on instance ARN, `rds:DescribeDBInstances` on `*`, `secretsmanager:GetSecretValue` on secret ARN
- [x] 1.3 Create `modules/iam-policy-rds/outputs.tf`: policy_arn

## 2. Refactor Module: app-iam

- [x] 2.1 Remove RDS-specific variables from `modules/app-iam/variables.tf` (rds_secret_arn, rds_instance_arn, db_name, db_username, db_endpoint)
- [x] 2.2 Add `attached_policy_arns` variable (list(string), default []) and `secret_arn` variable (string, default null), `secret_name` (string, default "app-secret"), `secret_key` (string, default "password")
- [x] 2.3 Remove the `aws_iam_policy` and `aws_iam_role_policy_attachment` resources from `modules/app-iam/main.tf` — replace with `for_each` attachment of `attached_policy_arns`
- [x] 2.4 Make SecretProviderClass conditional: only create it when `secret_arn` is not null; parameterize the secret reference with `secret_arn`, `secret_name`, `secret_key`
- [x] 2.5 Update `modules/app-iam/outputs.tf`: remove RDS-specific outputs; keep app_role_arn, app_sa_name, secret_provider_class_name (output null when not created)

## 3. Dev Stack Rewiring

- [x] 3.1 Add `module "iam_policy_rds"` to `envs/dev/main.tf` — sources from `../../modules/iam-policy-rds`, inputs from `module.rds` outputs
- [x] 3.2 Update `module "app_iam"` in `envs/dev/main.tf` — remove RDS inputs, add `attached_policy_arns = [module.iam_policy_rds.policy_arn]`, add `secret_arn = module.rds.rds_secret_arn`, `secret_name = "app-db-credentials"`
- [x] 3.3 Update `envs/dev/outputs.tf` if any output references changed

## 4. Validation

- [x] 4.1 Run `terraform fmt -recursive` on the project (requires Terraform CLI on local host)
- [x] 4.2 Run `terraform validate` in `envs/dev/` (with `-backend=false`) to confirm no syntax or reference errors (requires Terraform CLI on local host)
- [x] 4.3 Verify no references to removed RDS-specific app-iam variables remain in the dev stack (verified — zero matches)

## 5. Documentation

- [x] 5.1 Update README "RDS & Pod DB Access" section to reflect the split: `iam-policy-rds` (policy) + `app-iam` (role + SA) composed together
- [x] 5.2 Add a "Adding a New Service" section to README showing the pattern: create `modules/iam-policy-<service>/`, instantiate `app-iam` with the policy ARN
