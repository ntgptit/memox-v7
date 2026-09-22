# extension document template

Read [template rules](template-rules.md) before using this scaffold.
Use only for a requested or locally required family outside the catalog. MUST resolve concrete headings and per-record fields before creating the output. Never emit this unresolved shell.

Insert the shared document identity block after the output title, unless the local
metadata format already carries it. The fenced content is the output scaffold,
not a prewritten claim about any repository.

```markdown
# <Repository-specific document title>

## Purpose, audience and scope
<Actual requested/local document responsibility and boundaries.>

## Authority and relationship to existing documents
<Canonical facts owned here; dependencies and links avoiding duplicate ownership.>

## Section contract
| Required section | Reader question | Required fields/record shape | Evidence source | Applicability |
|---|---|---|---|---|
| <section name> | <question to answer> | <concrete field list> | <locator> | <reason> |

## <Each resolved required section>
<Replace this instruction with the actual sections and full record formats defined above. Resolve the complete contract before drafting; this generic shell is not a completed document.>

## References and verification
<Supporting authorities, actual checks/results and limitations.>

## Unresolved questions
<Missing evidence and decisions; do not fill with invented content.>
```
