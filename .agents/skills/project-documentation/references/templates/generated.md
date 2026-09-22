# generated document template

Read [template rules](template-rules.md) before using this scaffold.
Use only when generated Markdown is requested or useful under the output contract. The generator, not manual editing, must produce this structure; adapt to existing generator contracts.

Insert the shared document identity block after the output title, unless the local
metadata format already carries it. The fenced content is the output scaffold,
not a prewritten claim about any repository.

```markdown
# <Generated inventory, index or schema>

Generated — do not edit by hand.

## Provenance
Generator: <actual script/tool and version>.
Inputs: <source paths/options>.
Revision / dirty state: <actual input identity>.
Regeneration: <exact command and working directory>.
Determinism: <repeat-run result or NOT CHECKED>.
Scope / exclusions: <inventory bounds and unsupported areas>.

## Generated records
| Identifier/path | Kind | Extracted fact | Input locator |
|---|---|---|---|
| <actual item> | <tree/index/schema record type> | <mechanically extracted value> | <source> |

## Diagnostics and limits
<Missing inputs, extraction failures, excluded records and limitations; no inferred business meanings.>

## Authored interpretation
<Link to separate canonical authored document. Do not place hand-maintained analysis inside generated output.>
```
