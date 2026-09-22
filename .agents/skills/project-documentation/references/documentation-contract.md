# Generic documentation contract

## Required knowledge and output set

MUST account for purpose, use/verification, folder architecture, responsibilities
and dependency direction. MUST resolve the file set and required sections using
[output-contract.md](output-contract.md). Apply approved local document types,
headings and metadata; absent conventions use the catalog defaults.

| Knowledge | Include when | Canonical location decision |
|---|---|---|
| Purpose, use, verification | Every project | Catalog entry/product/verification families or approved local equivalents |
| Folders, modules, ownership, dependencies | Every project | Existing architecture guide/section or entry-document section |
| Rules, terminology, workflows | Domain behavior needs explanation | Existing authority; split only for distinct responsibility/audience |
| Use cases, state transitions | Branching/state needs explanation | Beside the rule/feature contract it illustrates |
| Storage and migrations | Persistence actually exists | Existing data authority, linked by consumers |
| Operational/release/security guidance | Relevant operations exist and are in scope | Existing maintained operator guide |
| Decisions/plans/status/audits | A real decision/task or requested report warrants it | Existing family, preserving authority/status |
| Generated tree/index/schema | Deterministic content adds value | Existing generated area/block or temporary run output |

MUST search headings, authority declarations, identifiers and inbound links before
creating content. Preserve local naming/language. Without a convention, use the
catalog's default filenames and section names. Avoid empty template sections.

Without local metadata rules, new authored content MUST state scope and whether it
is current, proposed or historical, with locators for material claims. Concise prose
is enough; no mandatory header schema. Persisted audits also record inspected
revision/dirty state and results. Never invent tasks, dates, owners or approvals.

## Business completeness, not code narration

MUST measure detail by coverage of in-scope business behavior, not word count,
number of files or amount of source inspected. Concise prose and a small entry
document do not permit omitted rules or branches.

Before writing, MUST build a run-local behavior-to-document map from applicable
requirements, accepted decisions, existing docs, and source/test evidence. Enumerate
distinct rules and meaningful scenarios, including applicable actors/permissions,
preconditions, main and alternative paths, limits, exceptions, state transitions,
outcomes and business-visible side effects. Follow cross-feature consequences.
Do not invent scenarios without evidence or treat observed behavior as approved.
For technical tools without a business domain, cover their user-visible behavior;
do not invent a domain taxonomy.

Each item MUST record an evidence locator and provenance, a canonical document
section (or missing location), and one disposition: covered, missing, conflict,
unverified, or outside scope with a concrete reason. Preserve existing rule IDs;
temporary run-local labels need not become new product identifiers. Keep this map
in working evidence/chat unless persistence is requested or locally required.

Covered means the section or its canonical links actually explain the behavior
and relevant outcomes; a heading, source link, feature name or "handles errors"
does not establish coverage. A short table may cover several scenarios if each
condition and outcome remains explicit. No minimum length or duplicated rule text
is required. Unknowns and conflicts MUST remain visible, not filled by invention.

MUST write business explanations in domain/user terms. Source is evidence, not an
outline to transcribe: do not add class/function catalogs, call-by-call walkthroughs,
implementation pseudocode or internal algorithms merely because they were read.
Folder responsibilities, module boundaries, dependency/flow diagrams and technical
details needed to explain a relevant contract MAY be included. Describe a formula
when it is itself a business rule, rather than copying its implementation. Detailed
code/API documentation belongs only to explicitly requested or authoritative local
documentation requirements. Evidence locators can remain in review records or brief
citations without turning the document into a code tour.

## Folder architecture

MUST inspect folders/modules for responsibility, entry points, owned types/data,
consumers, outgoing dependencies and authoritative docs. Use imports/build wiring
and tests, not names alone. Shared/core/features require explicit ownership where
they exist; do not impose those folders elsewhere. People require ownership evidence.

Audit patterns for cycles, inconsistent boundaries, duplicate responsibility and
unclear shared ownership. A repeated pattern is not an approved architecture.
Separate observed structure from accepted decisions and proposed improvements.
A missing decision does not authorize inventing one.

## Flow diagrams

MAY use Mermaid for material business, use-case/feature, module dependency, data or
state-transition flows. Place it beside the canonical explanation; avoid one diagram
per class/function or a redundant diagram hierarchy. MUST distinguish intended from
observed behavior and cite specs/symbols. Verify nodes, edges, conditions, failures,
retries, transaction boundaries where present and terminal states against evidence.
Rendering proves syntax only; record unavailable rendering separately.

## Canonical facts and links

MUST keep one authoritative home per fact and reference it elsewhere. Preserve stable
IDs/history under local rules. Similar headings/hashes indicate candidates, not
proven duplicates. Historical archives are not automatically stale current contracts.
Check an orphan candidate's intended entry path before removal.

MUST check target existence, fragment and semantic relevance. Moves require inbound
link repair. Resolve relative links from their document and root-relative links from
the target repo, never from a global installation. See [evidence-rules.md](evidence-rules.md).

## Generated versus authored

MUST prefer deterministic generators for inventories/indexes/schema exports when
useful tooling exists. Inventory gives paths/hashes and schema candidates, not a
fabricated schema or module purpose. No persistence means no required database doc.
Inspect generators first; discovery never executes target code.

Persisted generated content MUST identify generator, inputs/revision and warn
`Generated — do not edit by hand`. Compare repeat runs on unchanged inputs. Keep
authored analysis outside generated blocks and apply local format rules. Review
outputs before treating them as evidence; repair their generator, not generated bytes.
