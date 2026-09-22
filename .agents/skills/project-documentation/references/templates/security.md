# security document template

Read [template rules](template-rules.md) before using this scaffold.
MUST fill the following file scaffold from discovered evidence and applicable authorities.

Insert the shared document identity block after the output title, unless the local
metadata format already carries it. The fenced content is the output scaffold,
not a prewritten claim about any repository.

```markdown
# Security and privacy

## Scope and protected assets
| Asset/data | Sensitivity | Owner | Exposure | Evidence |
|---|---|---|---|---|
| <actual asset> | <supported classification> | <boundary> | <entry/exit point> | <locator> |

## Actors and access rules
| Actor | Resource/action | Allow/deny condition | Rule | Evidence |
|---|---|---|---|---|
| <actor> | <resource> | <condition> | <BR link> | <locator> |

## Trust boundaries
<Internal/external boundaries, entry points and data movement; diagram where useful.>

## Data handling
| Data | Collection/purpose | Storage/access | Sharing/logging | Retention/deletion | Authority |
|---|---|---|---|---|---|
| <category> | <purpose> | <boundary> | <actual policy> | <lifecycle> | <locator> |

## Safeguards and failure behavior
| Risk/requirement | Approved safeguard | Observed behavior | Failure outcome | Verification |
|---|---|---|---|---|
| <evidenced concern> | <authority or UNKNOWN> | <evidence> | <business impact> | <check/status> |

## Secrets and sensitive examples
<Supported secret handling and redaction guidance. Never embed credentials or private user data.>

## Known limitations and unresolved risks
<Explicit gaps, conflicts and needed decisions; no unsupported compliance or security certification claim.>

## Incident or reporting procedure
<Existing contact/procedure if evidenced; UNKNOWN if not established.>
```
