## Purpose

Provides a generic IRSA IAM role and Kubernetes ServiceAccount that accepts any list of IAM policy ARNs to attach, so any workload can get scoped AWS access without service-specific logic in the role module.

## MODIFIED Requirements

### Requirement: Generic IRSA IAM role
The system SHALL create an IAM role assumable by the cluster's OIDC provider for a specific Kubernetes ServiceAccount, with no service-specific permissions hardcoded. Policies are attached via a variable.

#### Scenario: Role created with no policies
- **WHEN** the module is applied with an empty `attached_policy_arns` list
- **THEN** an IAM role is created with an OIDC trust policy scoped to the configured ServiceAccount, and no permissions are attached

#### Scenario: Role created with external policies
- **WHEN** the module is applied with `attached_policy_arns = ["arn:aws:iam::123:policy/my-rds-policy"]`
- **THEN** the IAM role is created and each policy ARN in the list is attached to the role via `aws_iam_role_policy_attachment`

#### Scenario: Multiple workloads supported
- **WHEN** the module is instantiated twice with different `app_sa_name` values
- **THEN** two separate IAM roles and ServiceAccounts are created, each with their own policy attachments

### Requirement: Kubernetes ServiceAccount with IRSA annotation
The system SHALL create a Kubernetes ServiceAccount annotated with the IRSA role ARN.

#### Scenario: ServiceAccount created
- **WHEN** the module is applied
- **THEN** a ServiceAccount is created in the configured namespace with `eks.amazonaws.com/role-arn` annotation pointing to the IRSA role

### Requirement: No service-specific inputs
The system SHALL NOT require RDS, S3, or any service-specific inputs. The module accepts only IRSA-related variables (cluster name, OIDC issuer, SA name, namespace) and a generic list of policy ARNs.

#### Scenario: RDS variables removed
- **WHEN** the module is applied without any RDS instance ARN or secret ARN
- **THEN** the module creates successfully — those inputs no longer exist

### Requirement: SecretProviderClass remains generic
The system SHALL create a SecretProviderClass that mounts a configurable secret, not an RDS-specific secret. The secret ARN and name are generic variables.

#### Scenario: Generic secret mounting
- **WHEN** the `secret_arn` variable is provided
- **THEN** a SecretProviderClass is created that mounts that secret via ASCP, regardless of whether it's an RDS password or another secret type

#### Scenario: SecretProviderClass optional
- **WHEN** no `secret_arn` is provided
- **THEN** no SecretProviderClass is created — the role and ServiceAccount are still created without one
