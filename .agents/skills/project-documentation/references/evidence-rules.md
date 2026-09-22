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

MUST derive authority order from applicable instructions and accepted decisions.
When implementation and normative intent differ, report CONFLICT and identify the
needed documentation or code fix. If precedence is unclear, retain CONFLICT rather
than choose newest, majority or easiest-to-edit. Configuration cannot override
higher-priority instructions or itself authorize edits to protected documents.

Descriptive updates require current source/tests/config/schema evidence where
applicable. Plans/comments alone do not prove behavior. Implementation defects stay
outside documentation-only repair. Inspect definitions and concrete scenarios before
normalizing vocabulary; distinct concepts must not collapse into one convenient term.

## Design provenance

These informed the method, not project layout or runtime dependencies:

- [Superpowers SDD](https://github.com/obra/superpowers/blob/main/skills/subagent-driven-development/SKILL.md): bounded context, separate review, evidence after repairs.
- [Writing for agents](https://github.com/mattpocock/skills/blob/main/skills/productivity/writing-for-agents/SKILL.md): conditional pointers, observable completion, one instruction owner.
- [Domain modeling](https://github.com/mattpocock/skills/blob/main/skills/engineering/domain-modeling/SKILL.md): verify terminology through concrete scenarios and source.
