# Document set and section contracts

## Resolve the output set before writing

MUST use this catalog for whole-repository AUDIT/FULL_SYNC and initial documentation
generation. UPDATE/REPAIR select affected families and dependents; they MUST NOT
create unrelated documents merely to fill the catalog.

MUST read [template-rules.md](templates/template-rules.md) and the linked full-file
templates for selected families before drafting. Every Markdown output MUST have
a selected template; BR/UC file templates additionally compose the record formats.

MUST build an output manifest with one row per family: applicability and evidence,
exact repository-relative output path(s), selected template, required section mapping, canonical
authority, existing/missing status and intended action. Every core family applies;
every conditional family requires an evidence-based yes/no/unknown decision.
Unknown is an unresolved coverage gap, not a reason to silently omit a family.

Reuse existing canonical files and approved section names. When absent, use the
default filenames below in the discovered documentation location; if none exists,
use the repository root. This does not require a docs directory or configuration.
Default: one file per applicable family, with the entry document linking them.
Only explicit user/local convention may consolidate families; map every required
section and explain the reduced file count. "Small project" alone is not permission
to collapse the set into a README. Existing splits are valid when the manifest
maps all parts and preserves one authority per fact.

Report expected and actual unique file counts from this manifest, plus missing
files/sections. Do not set an arbitrary identical total for projects with different
capabilities. Additional first-party features may require additional files; give
each an explicit contract and canonical owner rather than an empty template.

## Core families

The listed sections are required semantic content, not a mandatory language or
heading spelling. Without local conventions, use these section names. Each file
also states scope, authority/status and relevant source or canonical references.

| Family / default file | Required sections/content |
|---|---|
| Entry / README.md | Purpose; quick start or first-use path; prerequisites; documentation index and reading order; verification entry point |
| Product / product.md | Problem and goals; intended users/actors; capabilities; in-scope and out-of-scope behavior; constraints and assumptions; unresolved product questions |
| Rules / business-rules.md | Rule index by capability; for each rule: condition, required/forbidden behavior, limits, exceptions and outcome; cross-rule dependencies/conflicts; unresolved rules |
| Scenarios / use-cases.md | Scenario index; for each scenario: actor/trigger, preconditions, main flow, alternatives, failures, final state and business-visible effects; links to rules; unresolved scenarios |
| Terminology / glossary.md | Canonical terms and definitions; aliases and discouraged/ambiguous names where present; distinctions between similar concepts; links to owning rules/concepts |
| Architecture / architecture.md | System context and boundaries; folder/module responsibilities; dependency direction; important business/data/state flows with suitable diagrams; approved constraints versus observed structure; conflicts/open decisions |
| Verification / verification.md | Supported verification/setup commands; business-scenario coverage and test references; expected outcomes; manual checks where needed; known gaps and environment limitations; actual verification status without claiming unrun tests passed |

Technical tools use product/user-visible contracts in rules and scenarios; no
business-domain fiction is necessary. Rules own normative facts; scenarios illustrate
and link them. Architecture explains boundaries and flows, not class/function lists.
Entry and verification may link an existing installation guide instead of repeating it.

## Conditional families

For Rules and Scenarios, MUST read and apply
[business-records.md](templates/business-records.md) to every BR/UC record.
Its concrete formats define fields, evidence, confidence and cross-reference
requirements; a file-level outline alone does not satisfy these families.

| Family / default file | Applies when | Required sections/content |
|---|---|---|
| Data / data-model.md | Persistent or externally exchanged structured data exists | Concepts/entities and ownership; relationships; fields meaningful to the contract; constraints/invariants; lifecycle/retention; migrations/compatibility if present; consistency boundaries; unresolved data questions |
| Interfaces / interfaces.md | Public APIs, commands, events, file formats or external integrations exist | Consumers and purpose; inputs/outputs; validation and errors; compatibility/versioning; authorization if applicable; retries/idempotency and failure effects when present; usage scenarios |
| Operations / operations.md | Deployment, distribution, release or maintained runtime operations exist | Build/release/deploy procedure; configuration; health/diagnostics; failure recovery/rollback; backup/restore if relevant; operational limitations |
| Security/privacy / security.md | Sensitive data, trust boundaries, permissions or security requirements exist | Protected assets; actors/access rules; trust boundaries; collection/storage/sharing/retention; applicable safeguards and failure behavior; known limitations and unresolved risks |
| Decisions / decisions.md or existing decision records | Accepted/proposed architectural or product decisions need an explicit record | Decision index/status; context; alternatives; choice and authority; rationale/tradeoffs; consequences; supersession links |
| Feature guides / feature-name.md in the chosen location | A capability needs its own document under local convention or cannot fit its canonical family without obscuring ownership | Purpose/scope; actors; linked rules; scenarios and exceptions; state/effect summary; dependencies/integration; verification and unresolved questions |

Plans, progress logs and audit reports are additional deliverables only when requested
or locally required. Their local contract controls sections; do not fabricate tasks,
dates, owners or a roadmap to increase the file count.

## Meaningful sections and completion

MUST populate sections from evidence or link the precise canonical section that owns
the content. An empty heading, generic filler or TODO is missing coverage. If a
dimension genuinely does not apply, state why in the manifest; the document can omit
that section under the recorded applicability decision. If evidence is unavailable,
record UNKNOWN with the needed verification; do not invent facts to fill the outline.

MUST check both set completeness (all applicable files/sections) and business
completeness (behavior-to-document map). File count alone proves neither. A full
write is incomplete while an applicable file, required section or in-scope behavior
is missing/unverified. AUDIT reports these gaps without creating files. Protected
authorities remain protected; blocked changes are reported rather than bypassed.

These are agent-enforced semantic contracts. The generic Markdown validator does
not prove catalog coverage; optional required_files/document_rules can add local
mechanical checks, but zero-config execution MUST still apply this catalog.
