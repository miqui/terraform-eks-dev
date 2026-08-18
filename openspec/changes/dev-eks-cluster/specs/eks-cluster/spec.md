## Purpose

Provides the EKS control plane, managed node group, IAM roles, and control-plane logging that constitute the Kubernetes cluster.

## ADDED Requirements

### Requirement: EKS cluster with managed control plane
The system SHALL create an EKS cluster with a managed control plane using a supported Kubernetes version, with the cluster endpoint publicly accessible but restricted to a configurable IP allowlist.

#### Scenario: Cluster created with default version
- **WHEN** Terraform is applied without a Kubernetes version override
- **THEN** the EKS cluster is created using the latest supported version available in the provider at apply time

#### Scenario: Public endpoint with IP restriction
- **WHEN** the cluster endpoint is configured for public access
- **THEN** the endpoint is reachable only from the IP addresses in the configured allowlist variable

#### Scenario: Private endpoint disabled
- **WHEN** the cluster is in a dev configuration
- **THEN** private endpoint access is disabled to avoid VPN/bastion complexity

### Requirement: Managed node group
The system SHALL create a managed node group with configurable instance type, desired capacity, and scaling limits, defaulting to t3.medium with 2 on-demand instances.

#### Scenario: Default node group
- **WHEN** no node group variables are overridden
- **THEN** the node group uses t3.medium instances with min=1, desired=2, max=3, on-demand capacity

#### Scenario: Custom node configuration
- **WHEN** a user provides instance type and capacity variables
- **THEN** the node group uses the provided values

### Requirement: IAM roles with least privilege
The system SHALL create IAM roles for the cluster and node group with only the permissions required for EKS operation, using trust policies scoped to the EKS service and EC2 respectively.

#### Scenario: Cluster role
- **WHEN** the cluster IAM role is created
- **THEN** it has a trust policy allowing `eks.amazonaws.com` to assume it, with the minimal managed policies attached (`AmazonEKSClusterPolicy`)

#### Scenario: Node role
- **WHEN** the node group IAM role is created
- **THEN** it has a trust policy allowing `ec2.amazonaws.com` to assume it, with the minimal managed policies attached (`AmazonEKSWorkerNodePolicy`, `AmazonEC2ContainerRegistryReadOnly`, `AmazonEKS_CNI_Policy`)

### Requirement: Control-plane logging
The system SHALL enable CloudWatch logging for the EKS control plane with a configurable retention period defaulting to 7 days.

#### Scenario: Logs enabled
- **WHEN** the cluster is created
- **THEN** a CloudWatch log group is created and control-plane log types (api, audit, authenticator, controllerManager, scheduler) are enabled

#### Scenario: Retention configurable
- **WHEN** a user sets the log retention variable
- **THEN** the log group uses that retention period; otherwise it defaults to 7 days
