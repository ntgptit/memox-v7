# interfaces document template

Read [template rules](template-rules.md) before using this scaffold.
MUST fill the following file scaffold from discovered evidence and applicable authorities.

Insert the shared document identity block after the output title, unless the local
metadata format already carries it. The fenced content is the output scaffold,
not a prewritten claim about any repository.

```markdown
# Interfaces and integrations

## Scope and consumers
<Actual public APIs/commands/events/formats/integrations; distinguish public contracts from internal implementation.>

## Interface index
| Contract | Kind | Producer/provider | Consumer | Version/status |
|---|---|---|---|---|
| <record link> | <API/CLI/event/file> | <owner> | <audience> | <supported contract> |

## Contract records
### <Interface name>
Purpose: <actor goal and linked UC>.
Invocation / trigger: <route, command, event or file exchange as applicable>.
| Input | Meaning | Required/default | Validation | Evidence |
|---|---|---|---|---|
| <input> | <meaning> | <requirement> | <constraint/BR link> | <locator> |

Output: <shape/meaning and success/empty outcomes>.
Errors: <condition, externally visible code/message and resulting state>.
Authorization: <actual access rule or reason not applicable>.
Side effects: <data/event changes and timing>.
Retry / idempotency: <supported semantics or UNKNOWN; no invented guarantees>.
Compatibility: <versioning/deprecation constraints>.
Usage example: <safe representative request/input and result; no real secrets>.
Business rules / data: <canonical links>.
Evidence: <spec, implementation and tests; confidence/provenance as needed>.

## Integration failure scenarios
<Unavailable dependency, timeout, invalid input or partial delivery only where relevant; link UC branches.>

## Open contract questions
<Ambiguities, unsupported guarantees and needed evidence.>
```
