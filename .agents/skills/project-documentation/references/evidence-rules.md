# Evidence and authority

## Independent provenance and verification axes

Discovery does not approve what exists. Every important claim MUST distinguish:

| Provenance | Meaning |
|---|---|
| OBSERVED | Directly found in source, config, schema or execution |
| APPROVED | Explicitly adopted by authoritative instruction/accepted decision/user; cite it |
| CONFIGURED | Optional override choice; not proof of correctness |
| INFERRED | Interpretation supported by clues; state how to verify |
| UNKNOWN | Insufficient evidence |
| CONFLICT | Inspected sources/authorities disagree; retain both locators |

Verification is VERIFIED, NEEDS_VERIFICATION or CONFLICT. A pattern can be verified
as present without being approved or good architecture. Missing instructions or
storage evidence do not justify importing a familiar project template.

## Claim records and conflict handling

MUST record claim, intended/observed role, provenance, canonical owner, source
path/symbol/section (line when useful), revision/dirty state, supporting and counter
evidence, verification and remaining checks. Unrun tests prove only test text exists.
A hash identifies bytes, not correctness; age alone does not prove staleness.

BR/UC records persist their own evidence and confidence using
[business-records.md](templates/business-records.md#confidence-and-missing-information).
Confidence does not replace provenance or verification.

MUST derive authority order from applicable instructions and accepted decisions.
When implementation and normative intent differ, report CONFLICT and identify the
needed documentation or code fix. If precedence is unclear, retain CONFLICT rather
than choose newest, majority or easiest-to-edit. Configuration cannot override
higher-priority instructions or itself authorize edits to protected documents.

Descriptive updates require current source/tests/config/schema evidence where
applicable. Plans/comments alone do not prove behavior. Implementation defects stay
outside documentation-only repair. Inspect definitions and concrete scenarios before
normalizing vocabulary; distinct concepts must not collapse into one convenient term.

## Business conflicts require user resolution

When discovery, drafting or review exposes a business conflict, the coordinator
MUST ask the user before choosing or writing a resolved business interpretation.
This includes contradictory rules, scenarios, permissions, limits, transitions,
outcomes or data effects, including code/tests that disagree with approved intent.
An authority hierarchy identifies existing intent; it does not silently settle
whether newly conflicting behavior should be corrected or the business rule changed.
Do not ask again if the user already explicitly resolved this exact conflict and
the evidence has not materially changed; cite that decision and apply its scope.

First inspect enough evidence to distinguish a real conflict from different scopes,
versions or terms. Then ask a concrete question containing:

- Conflict ID and affected BR/UC/capability.
- Each competing behavior and its exact evidence/authority locator.
- A representative input/state where the outcomes differ.
- The user-visible consequences and affected documentation of each option.
- A clear choice or missing business decision; a recommendation may be labeled
  as such but MUST NOT be treated as the user's answer.

Use an available user-question tool or a direct chat question. Batch related
conflicts when they share a decision; allow a different answer from the proposed
options. Investigators/auditors return conflicts to the coordinator for one
consolidated question rather than independently deciding business policy.

Until the user answers, MUST retain CONFLICT and both evidence locators. Pause only
dependent claims/edits; continue independent discovery and documentation work.
An explicitly labeled unresolved conflict can be documented, but do not replace
canonical rules, alter downstream scenarios or normalize terminology as though a
choice were approved. Silence, a default selection, elapsed time, a generic request
to continue, majority agreement or passing tests is not resolution. If no response
channel is available, report the exact decision needed and leave dependent work
blocked; do not invent an answer to finish the document set.

After an explicit answer, MUST record the decision, its scope and conversation or
decision locator in the run evidence; persist it under local rules when applicable.
Update eligible canonical documentation first, then affected BR/UC/Data links and
diagrams; recheck coverage and dependent claims. A business decision does not itself
expand write permissions or authorize product code/schema changes. Code that still
contradicts the chosen intent remains a disclosed implementation finding.

Pure formatting/link defects and missing information without contradictory business
behavior do not trigger this rule; handle them using the normal evidence workflow.
AUDIT remains read-only and may finish with unresolved findings, but MUST raise the
business question rather than hide the conflict only in a final report. Write modes
MUST NOT claim full completion while a required business decision remains pending.

## Design provenance

These informed the method, not project layout or runtime dependencies:

- [Superpowers SDD](https://github.com/obra/superpowers/blob/main/skills/subagent-driven-development/SKILL.md): bounded context, separate review, evidence after repairs.
- [Writing for agents](https://github.com/mattpocock/skills/blob/main/skills/productivity/writing-for-agents/SKILL.md): conditional pointers, observable completion, one instruction owner.
- [Domain modeling](https://github.com/mattpocock/skills/blob/main/skills/engineering/domain-modeling/SKILL.md): verify terminology through concrete scenarios and source.
