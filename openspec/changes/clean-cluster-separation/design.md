## Context

The repo currently has three OpenSpec changes: `dev-eks-cluster` (the baseline, implemented), `pod-rds-access` (proposed + implemented but not archived), and `refactor-app-iam-modular` (proposed + implemented but not archived). The latter two bundled RDS provisioning into the cluster stack. The user identified this as a design mistake: the cluster should be clean, and service access added separately. No `terraform apply` was ever run, so this is a code-only refactor — no AWS resources to destroy or migrate. See proposal.md for motivation.

## Goals / Non-Goals

**Goals:**
- Clean cluster baseline: network + EKS + ingress + generic pod IAM only
- `modules/app-iam/` stays in the baseline as a generic IRSA module with no policies attached
- RDS, iam-policy-rds, and RDS-specific sample manifests removed from the repo
- `envs/dev/` has zero service-specific variables, outputs, or module references
- README documents the clean baseline and the pattern for adding service access as separate changes
- Previous OpenSpec changes (`pod-rds-access`, `refactor-app-iam-modular`) are superseded

**Non-Goals:**
- Creating new service access modules (RDS, S3, etc.) — those are separate future changes
- Changing the network, EKS, or ingress modules — they're already clean
- Archiving the previous changes via the archive workflow — they're superseded by this change and will be removed from the changes directory

## Decisions

### 1. Delete RDS modules, keep generic app-iam

```
BEFORE:                              AFTER:
modules/                              modules/
├── network/                         ├── network/
├── eks/                             ├── eks/
├── ingress/                         ├── ingress/
├── rds/            ← DELETE         └── app-iam/  (generic, no policies)
├── iam-policy-rds/ ← DELETE
└── app-iam/  (generic, has rds       envs/dev/main.tf:
    wiring in dev stack)              module "network" { ... }
                                       module "eks" { ... }
                                       module "ingress" { ... }
                                       module "app_iam" {
                                         attached_policy_arns = []
                                         secret_arn = null
                                       }
```

**Alternative considered:** Keep RDS modules but move them to a `services/` directory. Rejected — the user explicitly wants a clean cluster repo; service access should be separate OpenSpec changes that add modules when needed, not pre-existing unused modules.

### 2. app_iam in dev stack with empty policy list

```hcl
module "app_iam" {
  source = "../../modules/app-iam"
  # ...
  attached_policy_arns = []  # empty — no service access in baseline
  secret_arn = null           # no secret in baseline
}
```

The ServiceAccount and role are created but have no permissions. When a service change is added later, it adds a policy module and populates `attached_policy_arns`.

**Alternative considered:** Don't include `app_iam` in the baseline at all. Rejected — having the IRSA role ready means a service change only needs to create a policy module and add one line to `attached_policy_arns`. Without it, every service change would also need to create the role and SA, which is repetitive.

### 3. Remove RDS sample, keep nginx sample

- Delete `k8s/sample/app-deployment.yaml` (depends on RDS secret + IRSA)
- Keep `k8s/sample/deployment.yaml`, `service.yaml`, `ingress.yaml` (nginx — tests ingress only, no service deps)

### 4. Supersede previous changes

Remove `openspec/changes/pod-rds-access/` and `openspec/changes/refactor-app-iam-modular/` from the changes directory. Their useful artifacts (generic app-iam refactor, node SG output) are preserved in the code; their RDS-specific planning artifacts are discarded. This is not archiving — it's removing superseded planning artifacts so the change history is clean.

### 5. README documents the pattern

Replace the RDS-specific sections with a "Adding Pod Access to an AWS Service" section that explains:
1. Create a `modules/iam-policy-<service>/` module
2. Add it to `envs/dev/main.tf`
3. Add its `policy_arn` to `app_iam.attached_policy_arns`
4. (If secret mounting is needed) set `app_iam.secret_arn`

## Risks / Trade-offs

- **[Lost planning artifacts]** → Removing the previous two changes' OpenSpec artifacts means their design rationale is gone. Mitigation: the `clean-cluster-separation` design.md captures the reasoning; the code already reflects the generic app-iam refactor.
- **[Breaking if applied against live infra]** → If someone had run `terraform apply` with the RDS module, this change would try to destroy the RDS instance. Mitigation: no apply was ever run; this is code-only.
- **[Empty role looks unused]** → The IRSA role with no policies may look like a mistake to a new reader. Mitigation: README and code comments document that it's intentional and policies are added in separate changes.
