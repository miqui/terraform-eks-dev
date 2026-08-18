## Purpose

Provides the network fabric — VPC, subnets, routing, and internet egress — that the EKS cluster and its workloads run within.

## ADDED Requirements

### Requirement: VPC with multi-AZ subnets
The system SHALL create a VPC with public and private subnets across at least two availability zones to support high availability and future growth.

#### Scenario: VPC and subnets created
- **WHEN** Terraform is applied
- **THEN** a VPC exists with at least 2 public subnets and 2 private subnets, each in a different availability zone

#### Scenario: Subnet tagging for EKS
- **WHEN** the EKS cluster is created
- **THEN** public and private subnets MUST be tagged with `kubernetes.io/role/elb = 1` (public) and `kubernetes.io/role/internal-elb = 1` (private) so the AWS Load Balancer Controller can place load balancers correctly

### Requirement: Internet egress
The system SHALL provide internet egress for resources in private subnets via a NAT gateway, and direct internet access for public subnets via an internet gateway.

#### Scenario: Private subnet egress
- **WHEN** a pod in a private subnet makes an outbound request
- **THEN** the request routes through the NAT gateway to the internet and the response returns successfully

#### Scenario: Public subnet access
- **WHEN** a resource in a public subnet needs internet access
- **THEN** it routes directly through the internet gateway without NAT

### Requirement: Configurable CIDR blocks
The system SHALL accept VPC CIDR and subnet CIDR ranges as Terraform variables with sensible defaults for a dev environment.

#### Scenario: Default CIDR values
- **WHEN** no CIDR variables are provided
- **THEN** the VPC uses `10.0.0.0/16` with `/18` subnets by default

#### Scenario: Custom CIDR values
- **WHEN** a user provides custom CIDR variables
- **THEN** the VPC and subnets use the provided ranges
