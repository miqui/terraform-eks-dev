## Why

A small development Kubernetes cluster is needed for iterative testing of workloads before promoting to higher environments. Provisioning via Terraform ensures the cluster is reproducible, tear-down capable, and version-controlled. Including the AWS Load Balancer Controller and Ingress support from the start means deployed workloads (websites, APIs) can be made publicly reachable without a follow-up infrastructure change.

## What Changes

- New Terraform project under `~/development/terraform-eks-dev` with module-based layout and S3 remote state (native lockfiles, no DynamoDB)
- New VPC with public and private subnets across 2 AZs, NAT gateway for egress, and an internet gateway
- New EKS cluster (managed control plane) with public endpoint access restricted to a configurable IP allowlist
- New managed node group running EKS-optimized AMI on t3.medium × 2 (on-demand)
- IAM roles for cluster and node group with least-privilege trust and access policies
- CloudWatch log group for control-plane logs with 7-day retention
- AWS Load Balancer Controller installed as an EKS add-on with IRSA-based IAM role
- IngressClass resource making the ALB controller the default ingress handler
- Sample deployment and Ingress manifest to validate end-to-end public reachability
- Terraform validation workflow (fmt, validate, plan) documented for a separate validation host — Terraform CLI is not installed on the Hermes orchestration host

## Capabilities

### New Capabilities
- `network`: VPC, subnets, route tables, NAT gateway, internet gateway — the network fabric the cluster runs in
- `eks-cluster`: EKS control plane, managed node group, IAM roles, CloudWatch logging — the Kubernetes cluster itself
- `ingress`: AWS Load Balancer Controller add-on, IRSA role, IngressClass — the mechanism for routing public traffic to cluster workloads

### Modified Capabilities
<!-- None — this is a greenfield project with no existing specs. -->

## Impact

- **New AWS resources**: VPC, subnets, route tables, NAT gateway, IGW, EKS cluster, node group, IAM roles, CloudWatch log group, ALB (at runtime), IRSA role, OIDC provider
- **New Terraform code**: modules for network, eks, and ingress; environment stack in `envs/dev/`; backend and provider configuration
- **External dependencies**: AWS account with sufficient permissions; S3 bucket for remote state (pre-existing or bootstrapped); kubectl + aws CLI on the validation host
- **Cost**: approximately $40-60/month (compute + ALB + NAT gateway); tear-down via `terraform destroy` expected
- **Validation host**: Terraform CLI runs on a designated host, not the Hermes orchestration host
