# use-cases document template

Read [template rules](template-rules.md) before using this scaffold.
MUST compose the file skeleton with every field in the Use case format of [business-records.md](business-records.md#use-case-format). The placeholder is an insertion point, not permission to omit records.

Insert the shared document identity block after the output title, unless the local
metadata format already carries it. The fenced content is the output scaffold,
not a prewritten claim about any repository.

```markdown
# Use cases

## Scope and actors
<Covered goals and actors; links to product authority; exclusions with reasons.>

## Scenario index
| ID | Actor goal | Trigger | Business rules | Record |
|---|---|---|---|---|
| <stable UC-ID> | <goal> | <event> | <BR links> | <record anchor> |

## Scenarios by capability
### <Capability>
<Insert one complete Use case format record from business-records.md for each actor goal. Include all meaningful branches within its record; adjust heading depth without dropping fields.>

## Cross-scenario relationships
| From | Relationship/condition | To | State or data carried forward |
|---|---|---|---|
| <UC link> | <precedes/retries/compensates/enables> | <UC link> | <business-visible consequence> |

## Coverage and unresolved scenarios
| Capability | Covered scenarios | Missing branch or ambiguity | Evidence/next check |
|---|---|---|---|
| <scope> | <UC links> | <gap or supported NONE> | <locator/check> |
```
