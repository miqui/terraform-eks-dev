## Context

Greenfield project: no existing Terraform code, no existing EKS cluster, no existing VPC. The target is a small, cost-conscious dev cluster in a single AWS region with public workload support via ALB ingress. Terraform CLI runs on a separate validation host, not on the Hermes orchestration host. See proposal.md for motivation.

## Goals / Non-Goals

**Goals:**
- A reproducible, one-command (`terraform apply`) dev EKS cluster with public workload ingress
- Module-based layout that can grow to multi-environment (dev/stage/prod) without restructuring
- S3 remote state with native lockfiles (no DynamoDB) per the Terraform infrastructure skill guidance
- Validation workflow (fmt, validate, plan) that runs on a designated host
- End-to-end: a sample workload reachable via a public ALB URL after apply

**Non-Goals:**
- Production-grade HA, multi-region, or compliance controls
- Cluster Autoscaler, Karpenter, or node autoscaling beyond the node group's min/max
- GitOps (Argo CD, Flux), service mesh, or observability stack
- TLS termination via ACM + Route53 (can be added as a follow-up change)
- Private cluster endpoint (dev uses public + IP allowlist)
- Spot instances (on-demand for stability in dev)

## Decisions

### 1. Repository layout: modules + envs
Use a `modules/` + `envs/dev/` layout per the Terraform infrastructure skill. Root stacks compose modules; modules contain reusable resource logic.

**Alternative considered:** single flat `main.tf`. Rejected — it doesn't scale to a second environment without copy-paste, and the module boundaries are clear from the start for network/cluster/ingress.

```
terraform-eks-dev/
├── modules/
│   ├── network/       # VPC, subnets, NAT, IGW, route tables
│   ├── eks/           # cluster, node group, IAM roles, logs
│   └── ingress/       # LBC add-on, IRSA role, IngressClass
├── envs/
│   └── dev/
│       ├── backend.tf       # S3 backend, use_lockfile = true
│       ├── providers.tf     # AWS provider, version pins
│       ├── main.tf          # module composition
│       ├── variables.tf
│       ├── outputs.tf
│       └── terraform.tfvars
├── k8s/
│   └── sample/       # sample Deployment + Ingress for validation
└── README.md
```

### 2. S3 backend with native lockfiles
Use `backend "s3"` with `use_lockfile = true`. Do not introduce DynamoDB locking — the S3 backend's DynamoDB option is deprecated per the Terraform infrastructure skill.

**Alternative considered:** Terraform Cloud remote state. Rejected for dev simplicity — S3 + lockfile is the standard team default and requires no extra service.

**Bootstrap note:** If the S3 state bucket does not exist yet, a one-time bootstrap stack (using `backend "local"`) creates it with `prevent_destroy = true`, then the dev stack switches to the S3 backend.

### 3. Managed node group (not self-managed)
Use `aws_eks_node_group` with managed node groups. AWS handles the AMI, kubelet config, and graceful drain/upgrade.

**Alternative considered:** self-managed EC2 + ASG. Rejected — more operational overhead with no benefit for a dev cluster.

### 4. Public endpoint with IP allowlist
Set `endpoint_public_access = true` with `public_access_cidrs` from a variable. Set `endpoint_private_access = false`.

**Alternative considered:** private endpoint + VPN. Rejected for dev — adds bastion/VPN complexity for no security benefit in a throwaway dev cluster.

### 5. AWS LBC via Helm release (not EKS add-on API)
Install the AWS Load Balancer Controller via the Terraform Helm provider rather than `aws_eks_addon`, because the LBC is not available as a native EKS add-on in all regions/versions and the Helm chart gives more configuration control.

**Alternative considered:** `aws_eks_addon`. Rejected — the AWS LBC is a Helm chart, not a first-class EKS add-on; using the Helm provider is the standard approach.

### 6. IRSA for LBC IAM role
Create an IAM role with a trust policy scoped to the cluster's OIDC provider and the `kube-system/aws-load-balancer-controller` ServiceAccount. Attach a policy granting only ALB-related permissions.

**Alternative considered:** instance profile on node group (old pattern). Rejected — IRSA is the recommended approach; node-wide credentials are overbroad.

### 7. IngressClass as default
Create an `IngressClass` with `ingressClassName: alb` and `isDefaultClass: true` annotation so Ingress resources without an explicit class are handled by the LBC automatically.

## Risks / Trade-offs

- **[NAT gateway cost]** → A single NAT gateway costs ~$32/month even with zero traffic. For a cost-sensitive dev cluster, this is the largest non-compute line item. Mitigation: document the cost; tear down with `terraform destroy` when not in use.
- **[Public endpoint exposure]** → The API server endpoint is public, reducing security posture vs. a private endpoint. Mitigation: the IP allowlist restricts access to configured IPs; the cluster is dev-only and tear-down capable.
- **[LBC version drift]** → The Helm chart version is pinned, but upstream releases frequently. Mitigation: version is a variable; upgrades are a deliberate variable change, not automatic.
- **[State bucket bootstrap]** → The S3 state bucket must exist before the dev stack can use it. Mitigation: a documented bootstrap step (local backend → create bucket → switch to S3 backend) handles this cleanly.
- **[Terraform not on Hermes host]** → `terraform validate` and `plan` cannot run on the orchestration host. Mitigation: the repo includes a validation script and CI config for a designated host; the README documents the workflow.

## Resolved Questions

- **Region**: `us-east-1`
- **State bucket**: Configurable via variable; user creates or specifies an existing S3 bucket. For ephemeral spin-up-and-destroy workflows, local state is an acceptable fallback documented in the README.
- **Tear-down**: Ephemeral — `terraform destroy` is the expected end-of-life. README documents the full tear-down sequence.
