## 1. Project Scaffolding

- [x] 1.1 Create directory structure: `modules/network/`, `modules/eks/`, `modules/ingress/`, `envs/dev/`, `k8s/sample/`
- [x] 1.2 Create `README.md` with project overview, prerequisites, and validation-host workflow
- [x] 1.3 Create `.gitignore` for Terraform (`.terraform/`, `*.tfstate`, `*.tfvars.local`, `.terraform.lock.hcl` if not committing lockfile)

## 2. Remote State Backend

- [x] 2.1 Create `envs/dev/backend.tf` with `backend "s3"` config: `use_lockfile = true`, configurable bucket and key via variables or tfvars
- [x] 2.2 Document the bootstrap step for creating the S3 state bucket if it doesn't exist (local backend → create bucket → switch to S3)
- [x] 2.3 Add `prevent_destroy` note in README for the state bucket if a bootstrap stack is used

## 3. Network Module

- [x] 3.1 Create `modules/network/variables.tf`: vpc_cidr (default `10.0.0.0/16`), subnet_cidr offsets, AZ count, region, environment tag, common tags
- [x] 3.2 Create `modules/network/main.tf`: VPC, 2 public subnets, 2 private subnets, IGW, NAT gateway in a public subnet, route tables for public and private subnets
- [x] 3.3 Add EKS subnet tags: `kubernetes.io/role/elb = 1` on public, `kubernetes.io/role/internal-elb = 1` on private, plus `karpenter.sh/discovery` tag for future use
- [x] 3.4 Create `modules/network/outputs.tf`: vpc_id, public_subnet_ids, private_subnet_ids, nat_gateway_id, igw_id
- [x] 3.5 Create `modules/network/versions.tf` or provider requirements

## 4. EKS Cluster Module

- [x] 4.1 Create `modules/eks/variables.tf`: cluster_name, kubernetes_version, endpoint_public_access_cidrs, node_instance_type (default `t3.medium`), node_desired (default 2), node_min (default 1), node_max (default 3), log_retention_days (default 7), common tags
- [x] 4.2 Create `modules/eks/main.tf` — IAM: cluster IAM role with `AmazonEKSClusterPolicy`, node IAM role with `AmazonEKSWorkerNodePolicy`, `AmazonEC2ContainerRegistryReadOnly`, `AmazonEKS_CNI_Policy`
- [x] 4.3 Create `modules/eks/main.tf` — Cluster: `aws_eks_cluster` with public endpoint, IP allowlist, private endpoint disabled, CloudWatch log group with enabled log types (api, audit, authenticator, controllerManager, scheduler) and configurable retention
- [x] 4.4 Create `modules/eks/main.tf` — Node group: `aws_eks_node_group` referencing the cluster and subnets, with on-demand capacity type, configurable instance type and scaling
- [x] 4.5 Create `modules/eks/outputs.tf`: cluster_name, cluster_endpoint, cluster_ca_data, cluster_oidc_issuer_url, node_group_arn

## 5. Ingress Module (AWS LBC + IngressClass)

- [x] 5.1 Create `modules/ingress/variables.tf`: cluster_name, cluster_oidc_issuer_url, lbc_chart_version (pinned), lbc_namespace (default `kube-system`), common tags
- [x] 5.2 Create `modules/ingress/main.tf` — OIDC: `aws_iam_openid_connect_provider` resource (or data source if cluster creates it) for IRSA
- [x] 5.3 Create `modules/ingress/main.tf` — IRSA IAM role: trust policy scoped to OIDC provider and `kube-system/aws-load-balancer-controller` ServiceAccount with audience condition
- [x] 5.4 Create `modules/ingress/main.tf` — IAM policy: attach a policy granting ALB management permissions (create/load balancers, target groups, listeners, register targets) scoped to the VPC and subnets
- [x] 5.5 Create `modules/ingress/main.tf` — Helm release: `helm_release` for `aws-load-balancer-controller` with pinned chart version, namespace, set values for cluster name, VPC ID, service account IAM role ARN, and region
- [x] 5.6 Create `modules/ingress/main.tf` — IngressClass: Kubernetes manifest resource for `IngressClass` named `alb` with `isDefaultClass: true` annotation, controller `ingress.k8s.aws/alb`
- [x] 5.7 Create `modules/ingress/outputs.tf`: lbc_role_arn, ingress_class_name

## 6. Dev Environment Stack

- [x] 6.1 Create `envs/dev/providers.tf`: AWS provider with region variable, Terraform version constraint, required providers (aws, helm, kubernetes) with version pins
- [x] 6.2 Create `envs/dev/variables.tf`: region (default `us-east-1`), cluster_name, endpoint_public_access_cidrs, state_bucket, state_key, node config overrides, environment tag
- [x] 6.3 Create `envs/dev/main.tf`: compose network, eks, and ingress modules with wiring (network outputs → eks and ingress inputs; eks outputs → ingress inputs)
- [x] 6.4 Create `envs/dev/outputs.tf`: cluster_name, cluster_endpoint, cluster_ca_data, node_group_arn, vpc_id, lbc_role_arn
- [x] 6.5 Create `envs/dev/terraform.tfvars`: default dev values (region, cluster name, IP allowlist placeholder, node config)

## 7. Sample Workload

- [x] 7.1 Create `k8s/sample/deployment.yaml`: nginx deployment with 2 replicas, labeled for the sample service
- [x] 7.2 Create `k8s/sample/service.yaml`: ClusterIP service selecting the deployment pods, port 80 → 8080 (or 80)
- [x] 7.3 Create `k8s/sample/ingress.yaml`: Ingress with default ingress class (alb), internet-facing scheme annotation, path `/` → sample service
- [x] 7.4 Document applying the sample in README: `kubectl apply -f k8s/sample/` and how to get the ALB DNS

## 8. Validation Workflow

- [x] 8.1 Create `scripts/validate.sh` (or Makefile target): runs `terraform fmt -recursive`, `terraform init -backend=false`, `terraform validate` in `envs/dev/`
- [x] 8.2 Document in README: validation runs on a designated host with Terraform CLI installed (not the Hermes orchestration host)
- [x] 8.3 Add a `terraform plan` dry-run section in README with instructions for running plan against the dev environment on the validation host
- [x] 8.4 Note in README: `terraform fmt -recursive` must be run before `terraform fmt -check` per the Terraform infrastructure skill guidance

## 9. Documentation

- [x] 9.1 README: architecture overview (network → EKS → LBC → Ingress → sample workload)
- [x] 9.2 README: prerequisites (AWS account, S3 state bucket, Terraform >= 1.5, kubectl, aws CLI, Helm)
- [x] 9.3 README: cost estimate breakdown
- [x] 9.4 README: tear-down instructions (`terraform destroy` + sample `kubectl delete`)
- [x] 9.5 README: open questions from design.md documented as decisions to make at apply time (region, state bucket name)
