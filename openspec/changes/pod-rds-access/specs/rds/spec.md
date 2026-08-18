## Purpose

Provides an RDS instance, subnet group, security group, and Secrets Manager secret so that application pods on the EKS cluster can connect to a PostgreSQL database with credentials managed securely.

## ADDED Requirements

### Requirement: RDS instance in private subnets
The system SHALL create a PostgreSQL RDS instance in the VPC's private subnets using a DB subnet group, with a configurable instance class defaulting to db.t4.micro for dev.

#### Scenario: RDS created in private subnets
- **WHEN** Terraform is applied
- **THEN** an RDS instance exists with a DB subnet group spanning the VPC's private subnets, and the instance is not directly reachable from the internet

#### Scenario: Configurable instance class
- **WHEN** a user provides the `rds_instance_class` variable
- **THEN** the RDS instance uses that class; otherwise it defaults to `db.t4.micro`

### Requirement: Security group allowing EKS ingress only
The system SHALL create a security group for the RDS instance that allows ingress on port 5432 only from the EKS node security group, and no other sources.

#### Scenario: EKS nodes can reach RDS
- **WHEN** the EKS node group security group is provided as input
- **THEN** the RDS security group has an ingress rule on port 5432 from the node security group ID

#### Scenario: No public access
- **WHEN** the RDS instance is queried from outside the VPC
- **THEN** the connection is refused because no public ingress rule exists

### Requirement: DB credentials in Secrets Manager
The system SHALL store the database master password in AWS Secrets Manager and expose the secret ARN as a module output, not in tfvars or pod specs.

#### Scenario: Password stored in Secrets Manager
- **WHEN** the RDS instance is created
- **THEN** a Secrets Manager secret is created with a generated password, and the RDS instance uses that password

#### Scenario: Secret ARN available to other modules
- **WHEN** the app-iam or k8s modules need the secret reference
- **THEN** the rds module outputs the secret ARN and the DB connection string components (endpoint, port, db name)

### Requirement: Configurable retention and deletion
The system SHALL accept a `deletion_protection` variable (default false for dev) and set the RDS `skip_final_snapshot` behavior accordingly.

#### Scenario: Dev deletion
- **WHEN** `deletion_protection` is false (default)
- **THEN** `terraform destroy` removes the RDS instance without a final snapshot, suitable for ephemeral dev clusters
