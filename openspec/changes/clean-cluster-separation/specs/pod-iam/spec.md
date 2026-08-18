## Purpose

Provides a generic IRSA (IAM Roles for Service Accounts) role and Kubernetes ServiceAccount as part of the clean EKS cluster baseline, so pods have a ready-to-use identity with no service-specific permissions. Service access policies are attached in separate OpenSpec changes.

## ADDED Requirements

### Requirement: Generic IRSA role in cluster baseline
The system SHALL include an IRSA IAM role module as a first-class component of the cluster baseline, creating a role assumable by the cluster's OIDC provider for a configurable ServiceAccount, with no service-specific permissions hardcoded.

#### Scenario: Role created with no policies
- **WHEN** the cluster baseline is applied
- **THEN** an IRSA role and ServiceAccount exist, with an empty `attached_policy_arns` list — the pod has an identity but no AWS service permissions

#### Scenario: Policies attached in separate changes
- **WHEN** a subsequent OpenSpec change adds a service policy module (e.g. RDS, S3)
- **THEN** the policy ARN is added to `attached_policy_arns` in the dev stack, granting the pod access to that service

### Requirement: No service-specific inputs in baseline
The system SHALL NOT include any RDS, S3, or service-specific variables in the cluster baseline. The IRSA module accepts only IRSA-related variables (cluster name, OIDC issuer, SA name, namespace, region) and a generic `attached_policy_arns` list.

#### Scenario: Clean baseline has no service inputs
- **WHEN** the cluster baseline is applied
- **THEN** no variables for database instances, secret ARNs, or bucket names exist in `variables.tf` or `terraform.tfvars`

### Requirement: Optional SecretProviderClass
The system SHALL create a SecretProviderClass only when a `secret_arn` is explicitly provided. In the clean baseline, no secret is provided, so no SecretProviderClass is created.

#### Scenario: No SecretProviderClass in baseline
- **WHEN** the cluster baseline is applied with `secret_arn = null`
- **THEN** no SecretProviderClass resource is created — it's added when a service change provides a secret to mount

### Requirement: Configurable ServiceAccount name
The system SHALL accept the ServiceAccount name and namespace as variables, so different workloads can use different identities.

#### Scenario: Default SA
- **WHEN** no SA variables are provided
- **THEN** the role defaults to `default/my-app-sa`

#### Scenario: Custom SA
- **WHEN** a user provides `app_sa_name` and `app_sa_namespace`
- **THEN** the IRSA trust policy is scoped to that ServiceAccount
