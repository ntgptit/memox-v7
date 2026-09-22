# data-model document template

Read [template rules](template-rules.md) before using this scaffold.
MUST fill the following file scaffold from discovered evidence and applicable authorities.

Insert the shared document identity block after the output title, unless the local
metadata format already carries it. The fenced content is the output scaffold,
not a prewritten claim about any repository.

```markdown
# Data model

## Scope and ownership
<Storage/exchange technologies actually found, data boundaries and canonical owners.>

## Concept and entity index
| Entity/concept | Meaning | Storage/exchange location | Owner | Consumers |
|---|---|---|---|---|
| <actual name> | <business meaning> | <table/file/message or logical concept> | <boundary> | <UC/interface links> |

## Relationships
<Relationship diagram or table with direction, cardinality, lifecycle coupling and evidence.>

## Entity records
### <Entity>
Purpose: <business responsibility>.
Identity: <identity/uniqueness rules>.
| Field | Meaning | Type/unit | Required/default | Constraint | Evidence |
|---|---|---|---|---|---|
| <contract-relevant field> | <meaning> | <type/unit> | <rule> | <BR/schema reference> | <locator> |

Relationships: <related entities and cardinality>.
Lifecycle: <creation, transitions, deletion/retention>.
Read/write consumers: <UC/interface links>.
Invariants: <canonical BR links and enforcement evidence; conflicts retained>.
Privacy: <classification/access link when applicable>.

## Consistency boundaries
<Atomicity, concurrency/conflict rules and failure effects where evidenced.>

## Migrations and compatibility
<Existing evolution/version rules, upgrade/downgrade constraints and migration evidence; NOT APPLICABLE with reason if absent.>

## Unresolved data questions
<Missing constraints, conflicting schema/intent, affected consumers and required checks.>
```
