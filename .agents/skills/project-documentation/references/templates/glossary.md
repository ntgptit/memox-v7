# glossary document template

Read [template rules](template-rules.md) before using this scaffold.
MUST fill the following file scaffold from discovered evidence and applicable authorities.

Insert the shared document identity block after the output title, unless the local
metadata format already carries it. The fenced content is the output scaffold,
not a prewritten claim about any repository.

```markdown
# Domain terminology

## Naming conventions
<Established language, identifier and alias conventions; distinguish approved from observed.>

## Term index
| Canonical term | Meaning | Owning record | Aliases |
|---|---|---|---|
| <term> | <short definition> | <record anchor> | <aliases or NONE> |

## Term records
### <Canonical term>
Definition: <Meaning in this project's domain, including relevant boundaries.>

Aliases: <Known equivalents and contexts; NONE if absent.>

Distinguished from: <Similar concept and the material difference.>

Example / counterexample: <Evidence-supported illustration that disambiguates the term.>

Used by: <Links to BR/UC/data concepts.>

Evidence: <Authoritative definition or inspected source locator.>

Provenance: <state>; Confidence: <level and basis>.

## Ambiguous or deprecated names
| Name | Problem/context | Canonical replacement or unresolved choice | Evidence |
|---|---|---|---|
| <name> | <ambiguity> | <term link or UNKNOWN> | <locator> |

## Open terminology questions
<Unresolved distinctions and evidence needed; do not silently merge concepts.>
```
