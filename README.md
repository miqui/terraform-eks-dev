# terraform-eks-dev

Small development EKS cluster provisioned with Terraform, including the AWS Load Balancer Controller and Ingress support for publicly reachable workloads.

## Architecture

```
Internet ──► ALB (AWS LBC) ──► Ingress ──► Service ──► Pod
                                │
                ┌───────────────┼───────────────┐
                ▼               ▼               ▼
          VPC (2 AZs)     EKS Cluster      Managed NG
          Public + Private  1.30            t3.medium × 2
          NAT + IGW         Public EP        On-Demand
                                │
                                ▼
                         Pod IAM (IRSA)
                         Role + ServiceAccount
                         (no policies — ready for service access)
```

**Modules:**
- `modules/network/` — VPC, subnets (2 AZ), NAT gateway, IGW, route tables, EKS subnet tags
- `modules/eks/` — EKS cluster, managed node group, IAM roles, CloudWatch logging
- `modules/ingress/` — AWS LBC (Helm), IRSA role, default IngressClass
- `modules/app-iam/` — Generic IRSA role + ServiceAccount (empty policy list — service access added separately)

**Stack:** `envs/dev/` composes all four modules with dev defaults.

## Prerequisites

- AWS account with permissions to create VPC, EKS, IAM, and CloudWatch resources
- Terraform >= 1.5 installed locally (provisioning runs from your machine)
- `kubectl` and `aws` CLI installed locally
- S3 bucket for remote state (or use local state for ephemeral use — see below)

## AWS Credentials

Terraform uses the standard AWS SDK credential resolution chain. It tries each source in order and uses the first one it finds:

1. **Environment variables** — `AWS_ACCESS_KEY_ID` + `AWS_SECRET_ACCESS_KEY` (+ `AWS_SESSION_TOKEN` for temp creds)
2. **Shared credentials file** — `~/.aws/credentials` (`[default]` or a named profile)
3. **Shared config file** — `~/.aws/config` (region, `source_profile`, `role_arn`, SSO)
4. **EC2/ECS instance metadata** — IAM instance profile or task role
5. **EKS IRSA** — web identity token from a pod ServiceAccount

For local dev, you'll typically use option 1 or 2. Verify which credentials Terraform will pick up:

```bash
aws sts get-caller-identity
```

If you use a **named profile** (not `[default]`), set it in `envs/dev/providers.tf`:

```hcl
provider "aws" {
  region  = var.region
  profile = "your-profile-name"
}
```

If you use **SSO**:

```bash
aws sso login --profile your-sso-profile
```

This caches a temporary token that Terraform reads automatically — no key IDs needed.

## Quick Start

### 1. Configure state backend

Edit `envs/dev/backend.tf` with your S3 bucket name:

```hcl
backend "s3" {
  bucket = "your-state-bucket-name"
  key    = "dev/terraform.tfstate"
  region = "us-east-1"
  use_lockfile = true
}
```

**No state bucket yet?** For ephemeral spin-up-and-destroy, comment out the backend block and use local state:

```bash
cd envs/dev
# Comment out the backend "s3" block in backend.tf, then:
terraform init -reconfigure
```

### 2. Configure endpoint access (auto-detected by default)

The cluster endpoint allowlist auto-detects your local public IP at apply time via `api.ipify.org`. Leave `endpoint_public_access_cidrs = []` in `terraform.tfvars` to use this.

To override with a specific IP:
```hcl
endpoint_public_access_cidrs = ["203.0.113.10/32"]
```

### 3. Validate

```bash
./scripts/validate.sh
```

This runs `terraform fmt -recursive`, `terraform init -backend=false`, and `terraform validate`.

### 4. Plan and Apply

```bash
cd envs/dev
terraform init
terraform plan -var-file=terraform.tfvars
terraform apply -var-file=terraform.tfvars
```

### 5. Configure kubectl

```bash
aws eks update-kubeconfig --name dev-eks-cluster --region us-east-1
```

### 6. Deploy sample workload

```bash
kubectl apply -f k8s/sample/

# Get the ALB URL
kubectl get ingress -n default

# Wait for the ALB to provision (~1-2 min), then:
curl http://$(kubectl get ingress sample-nginx -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
```

## Adding Pod Access to an AWS Service

The cluster baseline includes a generic IRSA role (`modules/app-iam/`) with an empty `attached_policy_arns` list. To give pods access to an AWS service (RDS, S3, SQS, etc.), create a separate OpenSpec change that adds a policy module and wires it in.

**Pattern:**

1. **Create a policy module** (e.g. `modules/iam-policy-rds/`):
```hcl
resource "aws_iam_policy" "this" {
  name = "terraform-eks-dev-rds-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = ["rds-db:connect"]
      Resource = aws_db_instance.example.arn
    }]
  })
}

output "policy_arn" { value = aws_iam_policy.this.arn }
```

2. **Wire it into the dev stack** (`envs/dev/main.tf`):
```hcl
module "iam_policy_rds" {
  source = "../../modules/iam-policy-rds"
  # ... service-specific variables
}

module "app_iam" {
  # ... existing config
  attached_policy_arns = [module.iam_policy_rds.policy_arn]
}
```

3. **(Optional) Secret mounting** — if the service uses secrets (e.g. DB password), set `secret_arn` on the `app_iam` module to create a SecretProviderClass.

4. **Deploy your pod** with `serviceAccountName: my-app-sa`.

One policy module per service. One `app-iam` instance per workload (or reuse the same SA for multiple policies).

## Tear Down

```bash
# Delete sample workload first
kubectl delete -f k8s/sample/

# Destroy infrastructure
cd envs/dev
terraform destroy -var-file=terraform.tfvars

# If using local state, clean up:
rm terraform.tfstate*
```

## Cost Estimate

| Resource          | Monthly cost |
|-------------------|--------------|
| t3.medium × 2     | ~$30         |
| NAT gateway + EIP  | ~$32         |
| ALB (runtime)     | ~$16         |
| CloudWatch logs    | ~$1          |
| EKS control plane | $73          |
| **Total**         | **~$152/mo** |

> Note: EKS control plane is $73/mo. For a true minimal dev setup, consider using k3s or eksctl with Fargate to reduce cost. This stack is designed for EKS-managed control plane with managed node groups.

Tear down with `terraform destroy` when not in use to stop all charges.

## Repository Layout

```
terraform-eks-dev/
├── modules/
│   ├── network/          # VPC, subnets, NAT, IGW
│   ├── eks/              # Cluster, node group, IAM, logs
│   ├── ingress/          # LBC, IRSA, IngressClass
│   └── app-iam/          # Generic IRSA role + ServiceAccount (no policies in baseline)
├── envs/
│   └── dev/              # Dev environment stack
│       ├── backend.tf
│       ├── providers.tf
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       └── terraform.tfvars
├── k8s/
│   └── sample/           # Sample nginx deployment + service + ingress
├── scripts/
│   └── validate.sh       # fmt + validate workflow
├── openspec/             # Spec-driven design artifacts
└── README.md
```

## Validation

Run validation locally before applying:

```bash
./scripts/validate.sh

# For a full plan:
cd envs/dev
terraform init -backend=false
terraform plan -var-file=terraform.tfvars
```

## OpenSpec

This project uses [OpenSpec](https://github.com/Fission-AI/OpenSpec) for spec-driven development. The change proposal lives in `openspec/changes/dev-eks-cluster/`.

To view the proposal:
```bash
openspec show dev-eks-cluster
```
