# architecture document template

Read [template rules](template-rules.md) before using this scaffold.
MUST fill the following file scaffold from discovered evidence and applicable authorities.

Insert the shared document identity block after the output title, unless the local
metadata format already carries it. The fenced content is the output scaffold,
not a prewritten claim about any repository.

```markdown
# Architecture

## System context
<Users, external systems, boundary of this repository and its responsibilities.>

## Architectural constraints
| Constraint | Intended/observed | Provenance | Authority/evidence |
|---|---|---|---|
| <boundary rule> | <role> | <state> | <locator> |

## Folder and module responsibilities
| Actual path/module | Responsibility | Owns | Consumers | Outgoing dependencies | Evidence |
|---|---|---|---|---|---|
| <discovered path> | <purpose> | <concept/data boundary> | <modules> | <modules/systems> | <imports/build/decision locator> |

## Dependency direction
<Allowed versus observed directions, forbidden edges if approved, and relevant cycles/conflicts.>

## System and flow diagrams
<Insert evidence-grounded context/dependency and material flow/state diagrams where useful.>
For each diagram: <purpose; intended/observed; node/edge evidence; conditions/failure paths; rendering status>.
<Use real discovered labels; a rendered diagram alone does not establish correctness.>

## Ownership and integration boundaries
<Shared responsibilities, external contracts, persistence/consistency boundaries where applicable; link data/interfaces authorities.>

## Decisions and tradeoffs
<Links to accepted/proposed decision records; no invented approval.>

## Architectural conflicts and open questions
| Boundary | Intended | Observed | Impact | Evidence | Disposition |
|---|---|---|---|---|---|
| <scope> | <rule> | <finding> | <effect> | <both locators> | <unresolved/proposed fix> |
```
