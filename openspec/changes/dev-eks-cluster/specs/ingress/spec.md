## Purpose

Provides the AWS Load Balancer Controller, its IAM role via IRSA, and an IngressClass so that Kubernetes Ingress resources automatically create internet-facing Application Load Balancers routing public traffic to cluster workloads.

## ADDED Requirements

### Requirement: AWS Load Balancer Controller add-on
The system SHALL install the AWS Load Balancer Controller as an EKS add-on (or Helm release) on the cluster, configured to manage ALBs for Ingress resources.

#### Scenario: Controller running
- **WHEN** Terraform is applied and the cluster is ready
- **THEN** the AWS Load Balancer Controller is installed and its pods are running in the `kube-system` namespace

#### Scenario: Controller version pinned
- **WHEN** the add-on is installed
- **THEN** the controller version is pinned to a specific version variable to prevent unexpected upgrades on re-apply

### Requirement: IRSA-based IAM role for the controller
The system SHALL create an IAM role that the AWS Load Balancer Controller assumes via Kubernetes ServiceAccount (IRSA), using the cluster's OIDC provider for trust.

#### Scenario: OIDC provider exists
- **WHEN** the cluster is created
- **THEN** an OIDC identity provider is associated with the cluster, enabled for IRSA

#### Scenario: Controller role trusts OIDC
- **WHEN** the LBC IAM role is created
- **THEN** its trust policy allows the OIDC provider to assume it for the specific `kube-system/aws-load-balancer-controller` ServiceAccount, with a condition matching the service account audience

#### Scenario: Controller permissions scoped
- **WHEN** the LBC role policy is attached
- **THEN** it grants only the permissions needed to create and manage ALBs, target groups, listeners, and register targets — no wildcard account-level access

### Requirement: IngressClass for ALB routing
The system SHALL create an IngressClass resource that designates the AWS Load Balancer Controller as the default ingress controller.

#### Scenario: IngressClass is default
- **WHEN** an Ingress resource is created without an explicit ingress class
- **THEN** it is handled by the AWS Load Balancer Controller and an internet-facing ALB is provisioned

#### Scenario: ALB is internet-facing
- **WHEN** the LBC processes an Ingress with scheme `internet-facing`
- **THEN** the resulting ALB has a public DNS name reachable from the internet

### Requirement: End-to-end reachability validation
The system SHALL include a sample Deployment and Ingress manifest that, when applied, results in a publicly reachable HTTP endpoint.

#### Scenario: Sample workload reachable
- **WHEN** the sample deployment and ingress are applied to the cluster
- **THEN** an ALB is created, and an HTTP request to its public DNS name returns a successful response from the sample pod

#### Scenario: Sample uses default ingress class
- **WHEN** the sample Ingress is created
- **THEN** it does not specify an explicit ingress class and is handled by the default IngressClass
