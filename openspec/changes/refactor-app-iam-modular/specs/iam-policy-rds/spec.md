## Purpose

Provides a standalone, reusable IAM policy module granting RDS connect and Secrets Manager read permissions scoped to a specific RDS instance and secret, composable with any IRSA role module.

## ADDED Requirements

### Requirement: Standalone IAM policy for RDS access
The system SHALL create an IAM policy that grants `rds-db:connect` on a specific RDS instance ARN and `secretsmanager:GetSecretValue` on a specific secret ARN, without creating or referencing an IAM role.

#### Scenario: Policy created standalone
- **WHEN** the module is applied with an RDS instance ARN and secret ARN
- **THEN** an IAM policy is created with `rds-db:connect` scoped to the instance and `secretsmanager:GetSecretValue` scoped to the secret, and its ARN is exposed as an output

#### Scenario: No role created
- **WHEN** the module is applied
- **THEN** no IAM role is created — the policy ARN is intended to be attached to a role by a separate module (e.g. `app-iam`)

### Requirement: Scoped permissions only
The system SHALL NOT grant wildcard resource permissions for data-plane actions.

#### Scenario: RDS permission scoped
- **WHEN** the policy is reviewed
- **THEN** `rds-db:connect` is scoped to the specific RDS instance ARN, not `Resource: "*"`

#### Scenario: Secrets permission scoped
- **WHEN** the policy is reviewed
- **THEN** `secretsmanager:GetSecretValue` is scoped to the specific secret ARN, not all secrets

#### Scenario: Describe permission
- **WHEN** the policy is reviewed
- **THEN** `rds:DescribeDBInstances` is allowed on `Resource: "*"` (required by the AWS API for discovery) and no other wildcard data-plane permissions exist
