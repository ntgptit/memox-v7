# Template selection and adaptation

MUST select a template for every Markdown output before drafting. Read only the
templates for selected families, plus shared rules and any referenced record format.
The output catalog decides applicability and number of files; templates decide the
content of each file. Templates are not instructions to create every family.

| Output family | Complete scaffold |
|---|---|
| entry | [entry.md](entry.md) |
| product | [product.md](product.md) |
| business-rules | [business-rules.md](business-rules.md) |
| use-cases | [use-cases.md](use-cases.md) |
| glossary | [glossary.md](glossary.md) |
| architecture | [architecture.md](architecture.md) |
| verification | [verification.md](verification.md) |
| data-model | [data-model.md](data-model.md) |
| interfaces | [interfaces.md](interfaces.md) |
| operations | [operations.md](operations.md) |
| security | [security.md](security.md) |
| decisions | [decisions.md](decisions.md) |
| feature | [feature.md](feature.md) |
| plan | [plan.md](plan.md) |
| progress | [progress.md](progress.md) |
| audit-report | [audit-report.md](audit-report.md) |
| generated | [generated.md](generated.md) |
| extension | [extension.md](extension.md) |

Plans, progress logs and audit reports require a user request or local requirement.
Generated Markdown requires an applicable generator/use case. The extension template
applies only to an additional requested/local family absent from the catalog.

## Shared document identity

Insert this block below the output title unless an approved local metadata format
already represents these facts. A local format replaces the block, not the facts.

```markdown
Status: <current / proposed / historical; use approved local vocabulary>
Purpose: <reader need this document serves>
Scope: <included and excluded behavior/areas>
Source of truth for: <facts this document owns>
Depends on: <canonical documents or justified NONE>
Evidence context: <inspected revision/dirty state or explicit unavailable context>
```

## Filling a scaffold

MUST replace every placeholder, sample table row and instructional sentence with
actual evidence-supported content. Expand repeated records for all applicable items,
not one representative example. Preserve every required field; complete BR/UC records
are composed from business-records.md, the single owner of their field definitions.
Template-relative links belong to skill instructions, not generated product docs.
Resolve output links against each actual destination file.

MUST use the target language and approved naming/metadata conventions. Record an
explicit mapping from template sections/fields to local equivalents in the output
manifest. Existing canonical sections can satisfy the contract through precise links;
do not copy a fact merely to make the scaffold look populated.

If a section/field is not applicable, give the evidence-based reason in the manifest
or record as required by its contract. UNKNOWN states the missing evidence and next
check; it is not completion. Do not fill blanks with assumed architecture, invented
data, guessed commands, owners, approvals or dates. Do not output empty tables,
ellipsis-only steps, template placeholders or generic filler.

MUST distinguish business explanation from implementation narration. Evidence
citations are welcome; class/function tours are not a substitute for behavior.
Folder diagrams, dependency boundaries, schemas and public contracts may contain
necessary technical details. Diagrams must use actual nodes/edges and have evidence,
intended/observed labels and a rendering status; inventing a diagram to fill a slot
is a defect.

## Output manifest and review

Business conflicts in any template follow
[the user-resolution protocol](../evidence-rules.md#business-conflicts-require-user-resolution).
Include the competing evidence, question and pending/answered decision in the
relevant unresolved section. A template is never permission to decide business policy.

MUST add template path, destination path and required-section mapping to each output
manifest row. Check every destination for meaningful content, applicable record
coverage, references, authority and outstanding uncertainty. A correct file count,
matching headings or mechanical validator success does not establish completeness.

For a family outside this catalog, use extension.md to resolve a concrete per-file
template from the request/local contract before writing; do not emit its generic
section-contract shell as final documentation. Record the resolved template in the
run evidence so review can evaluate it. Templates for known families must not be
bypassed through this extension route.
