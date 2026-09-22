# decisions document template

Read [template rules](template-rules.md) before using this scaffold.
MUST fill the following file scaffold from discovered evidence and applicable authorities.

Insert the shared document identity block after the output title, unless the local
metadata format already carries it. The fenced content is the output scaffold,
not a prewritten claim about any repository.

```markdown
# Decisions

## Scope and status vocabulary
<Which decisions this file owns; proposed/accepted/rejected/superseded meaning and authority.>

## Decision index
| ID | Title | Status | Authority | Supersedes / superseded by | Record |
|---|---|---|---|---|---|
| <existing convention or stable ID> | <choice> | <actual state> | <evidence> | <links or NONE> | <anchor/file> |

## Decision records
### <Decision ID — title>
Status: <actual status; never invent acceptance>.
Context: <problem, constraints and relevant evidence>.
Options:
| Option | Benefits | Costs/risks | Evidence |
|---|---|---|---|
| <real considered option> | <benefits> | <tradeoffs> | <source or clearly labeled analysis> |

Decision: <choice or pending question>.
Authority: <accepted decision/user instruction locator, or UNKNOWN>.
Rationale: <why selected under the constraints>.
Consequences: <behavioral/architectural implications and follow-up>.
Affected contracts: <BR/UC/architecture/data links>.
Supersession: <history links or NONE>.
Verification: <how adherence can be assessed; actual status>.

## Pending decisions
<Decision needed, evidence gap and impact; no fabricated owner/deadline.>
```
