# feature document template

Read [template rules](template-rules.md) before using this scaffold.
MUST fill the following file scaffold from discovered evidence and applicable authorities.

Insert the shared document identity block after the output title, unless the local
metadata format already carries it. The fenced content is the output scaffold,
not a prewritten claim about any repository.

```markdown
# <Capability name>

## Purpose and scope
<Actor goal, included behavior and explicit exclusions.>

## Actors and entry points
<Who uses the capability, trigger and relevant permissions; UC links.>

## Business rules
| Rule | Role in this capability | Canonical record |
|---|---|---|
| <BR ID> | <short relationship, not copied requirement> | <link> |

## Scenarios and exceptions
| Scenario | Main outcome | Alternative/failure branches | Canonical record |
|---|---|---|---|
| <UC ID> | <summary> | <branch links> | <link> |

## State and side effects
<Material state transitions, data/event effects and invariants; diagram if it clarifies behavior.>

## Dependencies and boundaries
<Folder/module ownership, upstream/downstream capabilities and interfaces. No class-by-class tour.>

## Data and interfaces
<Canonical entity/contract links and read/write purpose; justified absence if not applicable.>

## Verification
<Scenario/test/procedure links and actual verification status.>

## Open questions and conflicts
<Unresolved behavior, evidence/authority and impact.>
```
