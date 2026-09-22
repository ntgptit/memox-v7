# plan document template

Read [template rules](template-rules.md) before using this scaffold.
MUST fill the following file scaffold from discovered evidence and applicable authorities.

Insert the shared document identity block after the output title, unless the local
metadata format already carries it. The fenced content is the output scaffold,
not a prewritten claim about any repository.

```markdown
# <Task or change> plan

## Objective and scope
<Requested outcome, editable areas, exclusions and completion criteria.>

## 5Why
| Why/question | Evidence/root cause | Constraint/tradeoff | Decision enabled |
|---|---|---|---|
| <each of five concrete causal questions> | <answer> | <constraint> | <consequence for plan> |

## Source of truth and current state
<Applicable authorities, existing behavior, revision/dirty state and confirmed gaps.>

## Deliverables
| File/area | Change | Required contents/behavior | Reason | Dependencies |
|---|---|---|---|---|
| <exact path> | <create/update> | <contract/template link> | <need> | <prerequisite> |

## Implementation sequence
1. <bounded actionable step with inputs, result and dependency>
<Continue until the plan is executable without inventing product decisions.>

## Verification and acceptance
| Requirement | Check/procedure | Expected outcome | Completion evidence |
|---|---|---|---|
| <goal> | <command/review> | <result> | <artifact/result> |

## Risks, blockers and decisions
<Concrete uncertainty, mitigation and decisions needed; no invented assignments or dates.>

## Handoff and stop conditions
<Worktree safety, allowed scope, true blockers and evidence required for completion.>
```
