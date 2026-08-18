## 1. EKS Module — Expose Node Security Group ID

- [ ] 1.1 Add `node_security_group_id` output to `modules/eks/outputs.tf`
- [ ] 1.2 Add the node security group resource (or data source) to `modules/eks/main.tf` if not already explicitly created — EKS managed node groups create a default SG; reference it via `aws_eks_node_group.this.resources[0].remote_access_security_group_id` or create a dedicated SG

## 2. RDS Module

- [ ] 2.1 Create `modules/rds/variables.tf`: vpc_id, private_subnet_ids, allowed_security_group_id (EKS node SG), db_instance_class (default `db.t4.micro`), db_engine (default `postgres`), db_engine_version (default `16`), db_name, db_username, deletion_protection (default false), tags
- [ ] 2.2 Create `modules/rds/main.tf` — DB subnet group spanning private subnets
- [ ] 2.3 Create `modules/rds/main.tf` — RDS instance with `manage_master_user_password = true`, configurable engine/class/version, deletion_protection, skip_final_snapshot when dev
- [ ] 2.4 Create `modules/rds/main.tf` — Security group with ingress on 5432 from the EKS node SG only
- [ ] 2.5 Create `modules/rds/outputs.tf`: rds_endpoint, rds_arn, rds_secret_arn (from `master_user_secret`), db_name, db_username, security_group_id

## 3. App-IAM Module

- [ ] 3.1 Create `modules/app-iam/variables.tf`: cluster_name, cluster_oidc_issuer, app_sa_name (default `my-app-sa`), app_sa_namespace (default `default`), rds_secret_arn, rds_instance_arn, db_name, db_username, db_endpoint, tags
- [ ] 3.2 Create `modules/app-iam/main.tf` — OIDC data source (reuse pattern from ingress module)
- [ ] 3.3 Create `modules/app-iam/main.tf` — IAM role with OIDC trust policy scoped to the app ServiceAccount
- [ ] 3.4 Create `modules/app-iam/main.tf` — IAM policy: `rds-db:connect` on the RDS instance ARN, `rds:DescribeDBInstances` (resource `*`), `secretsmanager:GetSecretValue` on the RDS secret ARN only
- [ ] 3.5 Create `modules/app-iam/main.tf` — Kubernetes ServiceAccount manifest with `eks.amazonaws.com/role-arn` annotation
- [ ] 3.6 Create `modules/app-iam/main.tf` — SecretProviderClass CRD using ASCP driver, mounting the DB secret as env vars (endpoint, port, username, password, dbname)
- [ ] 3.7 Create `modules/app-iam/outputs.tf`: app_role_arn, app_sa_name, secret_provider_class_name

## 4. Dev Stack Wiring

- [ ] 4.1 Add `rds_secret_arn`, `rds_instance_arn`, `rds_endpoint`, `db_name`, `db_username` variables to `envs/dev/variables.tf` with defaults that reference module outputs
- [ ] 4.2 Add `modules/rds/` and `modules/app-iam/` to `envs/dev/main.tf` with correct wiring: network → rds, eks → rds (node SG), eks → app-iam (OIDC), rds → app-iam (secret ARN, instance ARN, connection info)
- [ ] 4.3 Add new outputs to `envs/dev/outputs.tf`: rds_endpoint, rds_secret_arn, app_role_arn
- [ ] 4.4 Add RDS variables to `envs/dev/terraform.tfvars`: db_instance_class, db_name, db_username

## 5. Sample Workload Update

- [ ] 5.1 Create `k8s/sample/app-deployment.yaml` — sample pod that uses the annotated ServiceAccount and mounts the SecretProviderClass as env vars (can be a simple postgres client or echo pod)
- [ ] 5.2 Document in README how to apply the sample app and verify DB connectivity

## 6. README Update

- [ ] 6.1 Add "RDS & Pod DB Access" section: architecture (pod → IRSA → RDS), IRSA flow diagram, SecretProviderClass explanation
- [ ] 6.2 Add RDS cost line to the cost table (~$13/mo db.t4.micro + ~$0.40/secret)
- [ ] 6.3 Add tear-down note: RDS instance is deleted with `terraform destroy` when `deletion_protection = false`; AWS-managed secret may need manual cleanup
- [ ] 6.4 Add prereq note: ASCP CSI driver must be installed on the cluster (document the Helm install command for `secrets-store-csi-driver` + `aws-secrets-manager-provider`)
