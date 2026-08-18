## Purpose

Provides an IRSA-based IAM role for application pods, scoped to RDS and Secrets Manager access via the cluster's OIDC provider, so pods can call AWS services without long-lived credentials.

## ADDED Requirements

### Requirement: IRSA IAM role for application ServiceAccount
The system SHALL create an IAM role that is assumable by the cluster's OIDC provider for a specific Kubernetes ServiceAccount, using the same IRSA pattern as the Load Balancer Controller.

#### Scenario: Role trusts OIDC for app SA
- **WHEN** the app-iam module is applied
- **THEN** the IAM role has a trust policy scoped to the cluster's OIDC provider URL and the configured ServiceAccount name and namespace

#### Scenario: Pod gets credentials via IRSA
- **WHEN** a pod runs with the annotated ServiceAccount
- **THEN** AWS SDK calls in the pod automatically use the IRSA role credentials, with no static keys in env vars or secrets

### Requirement: RDS-scoped IAM policy
The system SHALL attach an IAM policy to the app role that grants only the permissions needed to connect to the provisioned RDS instance and read the DB credentials secret.

#### Scenario: RDS connect permission
- **WHEN** the policy is attached
- **THEN** it grants `rds-db:connect` on the provisioned RDS instance and `rds:DescribeDBInstances` for discovery

#### Scenario: Secrets Manager read permission
- **WHEN** the policy is attached
- **THEN** it grants `secretsmanager:GetSecretValue` scoped to the DB credentials secret ARN only, not all secrets

#### Scenario: No wildcard permissions
- **WHEN** the policy is reviewed
- **THEN** it does not contain `Resource: "*"` for data-plane actions (only for describe/list permissions that require it)

### Requirement: Configurable ServiceAccount name
The system SHALL accept the ServiceAccount name and namespace as variables, so multiple app roles can be created for different workloads.

#### Scenario: Default SA name
- **WHEN** no ServiceAccount variables are provided
- **THEN** the role defaults to `default/my-app-sa`

#### Scenario: Custom SA name
- **WHEN** a user provides `app_sa_name` and `app_sa_namespace`
- **THEN** the IRSA trust policy is scoped to that specific ServiceAccount
