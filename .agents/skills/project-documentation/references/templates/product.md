# product document template

Read [template rules](template-rules.md) before using this scaffold.
MUST fill the following file scaffold from discovered evidence and applicable authorities.

Insert the shared document identity block after the output title, unless the local
metadata format already carries it. The fenced content is the output scaffold,
not a prewritten claim about any repository.

```markdown
# Product definition

## Problem and goals
<Problem, affected audience, desired outcomes, and evidence supporting them.>

## Actors and needs
| Actor | Goal | Permissions/responsibility | Evidence |
|---|---|---|---|
| <actual actor> | <user need> | <boundary or rule link> | <locator> |

## Capability inventory
| Capability | Actor outcome | Included scenarios | Rule authority | Current/proposed |
|---|---|---|---|---|
| <capability> | <observable value> | <UC links> | <BR links> | <status + evidence> |

## Scope
### Included
<Explicit product boundaries and supported contexts.>
### Excluded or deferred
<Explicit exclusions with authority; do not infer a roadmap from absent code.>

## Constraints and assumptions
| Constraint/assumption | Provenance | Consequence | Evidence or confirmation needed |
|---|---|---|---|
| <statement> | <state> | <affected behavior> | <locator or gap> |

## Success criteria
<Approved measurable/observable outcomes; UNKNOWN if not established, without invented targets.>

## Open product questions
<Question, affected capability, evidence gap and decision needed; NONE only with basis.>
```
