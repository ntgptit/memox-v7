# progress document template

Read [template rules](template-rules.md) before using this scaffold.
MUST fill the following file scaffold from discovered evidence and applicable authorities.

Insert the shared document identity block after the output title, unless the local
metadata format already carries it. The fenced content is the output scaffold,
not a prewritten claim about any repository.

```markdown
# <Work scope> progress

## Scope and reference plan
<Actual task scope; canonical plan/requirements links; current revision/context.>

## Work items
| ID | Outcome/deliverable | Status | Dependencies | Evidence | Next action |
|---|---|---|---|---|---|
| <actual task ID or run-local label> | <result> | <not started/in progress/blocked/done> | <items> | <commit/file/check> | <action> |

## Completed and verified
<Finished outcomes and supporting evidence; distinguish written, reviewed and verified.>

## In progress
<Current work and remaining acceptance criteria.>

## Blockers and unresolved decisions
| Item | Blocker | Impact | Needed action/authority |
|---|---|---|---|
| <item> | <concrete condition> | <scope> | <next step> |

## Verification status
<Checks run, outcomes and outstanding checks; no inferred green status.>

## Next steps
<Dependency-ordered actions; use actual owners/dates only when supplied.>

## Update context
<Actual update task and revision/dirty state; preserve local history rules.>
```
