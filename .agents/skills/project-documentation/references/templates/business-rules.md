# business-rules document template

Read [template rules](template-rules.md) before using this scaffold.
MUST compose the file skeleton with every field in the Business rule format of [business-records.md](business-records.md#business-rule-format). The placeholder is an insertion point, not permission to omit records.

Insert the shared document identity block after the output title, unless the local
metadata format already carries it. The fenced content is the output scaffold,
not a prewritten claim about any repository.

```markdown
# Business rules

## Scope and authority
<Covered capabilities; intended versus observed behavior; authoritative sources and precedence.>

## Rule index
| ID | Rule | Capability | Used by | Provenance | Confidence |
|---|---|---|---|---|---|
| <stable BR-ID> | <link to record> | <capability> | <UC links or justified invariant scope> | <state> | <level + basis in record> |

## Rules by capability
### <Capability>
<Insert one complete Business rule format record from business-records.md for every identified rule. Use a deeper heading level if needed; retain every field and stable anchor.>

## Rule interactions
| Rule | Related rule | Dependency/precedence/conflict | Evidence |
|---|---|---|---|
| <BR link> | <BR link> | <relationship and behavioral consequence> | <locator> |

## Unresolved rules and coverage
| Rule/capability | Missing or conflicting knowledge | Impact | Required evidence/decision |
|---|---|---|---|
| <ID or scope> | <gap> | <affected scenarios> | <next check> |
```
