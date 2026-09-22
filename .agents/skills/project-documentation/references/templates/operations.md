# operations document template

Read [template rules](template-rules.md) before using this scaffold.
MUST fill the following file scaffold from discovered evidence and applicable authorities.

Insert the shared document identity block after the output title, unless the local
metadata format already carries it. The fenced content is the output scaffold,
not a prewritten claim about any repository.

```markdown
# Operations and release

## Scope and supported environments
<Actual distribution/runtime environments, operational responsibility and exclusions.>

## Configuration
| Setting | Purpose | Required/default | Source | Sensitive? | Validation |
|---|---|---|---|---|---|
| <setting name> | <meaning> | <requirement> | <location, never secret value> | <classification> | <check> |

## Build and release
Prerequisites: <tools, permissions, inputs>.
1. <verified build/package step>
2. <verification/signing/distribution step if applicable>
Success: <artifact and observable acceptance criteria>.
Evidence: <authoritative scripts/CI/procedure>.

## Deployment or installation
<Ordered steps, target selection, compatibility and post-install checks; justified NOT APPLICABLE for absent deployment.>

## Health and diagnostics
| Symptom/check | How to inspect | Healthy result | Failure action | Evidence |
|---|---|---|---|---|
| <condition> | <command/procedure> | <result> | <runbook link> | <locator> |

## Recovery and rollback
### <Failure scenario>
Trigger: <observable condition>.
Impact: <affected users/data>.
Recovery: <ordered verified procedure>.
Rollback limits: <irreversible changes/data effects>.
Verification: <recovered state checks>.

## Backup and restore
<Applicability; data scope, supported procedure, integrity verification and known recovery limits. Do not invent recovery targets.>

## Operational limitations
<Known risks, untested procedures, missing permissions/tools and required follow-up.>
```
