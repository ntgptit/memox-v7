# Business rules

Rules are true regardless of UI. Number them so use cases, code and tests cite
the same identifier — when a rule changes, the citation is how you find every
place that depends on it.

## Rules

| ID | Rule | Applies to | Source |
|---|---|---|---|
| BR-01 | | | stakeholder / regulation / product decision |

## Validation rules

| Field | Rule | Message shown to user | Where enforced |
|---|---|---|---|
| | | | domain / server / both |

Write the actual user-facing message. "Must be valid" produces vague error text
in the UI because nobody decided what it should say.

`Where enforced` matters: a rule enforced only client-side is advisory, and a
rule enforced only server-side needs a UI story for the rejection.

## Entity state machines

### <Entity>

**States:** `draft` · `active` · `archived` · `deleted`

| From | To | Trigger | Guard |
|---|---|---|---|
| draft | active | user publishes | all required fields present |

**Illegal transitions:** <list them — these are the ones to assert against in
tests, and the ones a sealed class makes unrepresentable>

**Terminal states:** <states nothing leaves>

Model this as an enum or sealed class in `domain/entity/`. If the entity's state
lives in three separate booleans, the illegal combinations are reachable and
eventually one of them will happen in production.

## Edge cases

| Case | Expected behaviour |
|---|---|
| Empty dataset on first launch | |
| Very large dataset | |
| Concurrent edit from another device | |
| Clock skew / timezone boundary | |
| Partial sync interrupted | |
| User revokes permission after granting | |
| Storage full | |

Trim rows that do not apply to this app, but delete them deliberately rather
than leaving them blank.
