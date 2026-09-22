# Business rule and use case records

MUST use these per-record contracts when generating or reviewing rules/use cases.
They supplement the per-file contract, not replace it. Existing approved local
formats may change labels/layout, but MUST map these fields explicitly; missing
content is a gap, not an excuse to rewrite a protected authority.

Preserve existing IDs. If no convention exists, allocate unique stable BR-NNN and
UC-NNN IDs after checking the entire applicable document set. Do not renumber for
cosmetic ordering, reuse deleted IDs, or mistake example IDs for real rules.
Group records by capability and provide a linked index. One record describes one
independently meaningful rule or actor goal; do not create a record per method.

## Business rule format

```markdown
### BR-NNN — <precise condition and required business outcome>

Rule:
<Complete requirement in domain terms; title alone suffices only if unambiguous.>

Applies when:
- <actor, state, condition, threshold, unit or time boundary relevant to this rule>

Exceptions:
- <exception and resulting behavior, or NONE with supporting basis>

Evidence:
- <relative path + section/symbol/test name> — <what it establishes>
- <additional relevant authority, source, data or test evidence>

Used by:
- <linked UC-ID — scenario title>

Confidence: <HIGH | MEDIUM | LOW> — <basis and outstanding uncertainty>
Provenance: <APPROVED | OBSERVED | CONFIGURED | INFERRED | UNKNOWN | CONFLICT>
Verification: <VERIFIED | NEEDS_VERIFICATION | CONFLICT> — <checks actually performed>

Open questions / conflicts:
- <unresolved point and verification needed, or NONE>
```

MUST make the rule's outcome, limits and exceptions explicit, including equality
boundaries, units and time semantics when material. Do not turn implementation
choices into normative requirements. Mark extracted behavior OBSERVED unless an
authority adopted it; retain conflicting intent and behavior with both locators.

Evidence MUST identify an actual inspected location and its contribution. A folder
glob, ellipsis, guessed test or "see source" is not sufficient. Cite specifications,
implementation, persistence and tests where relevant and available; do not require
all categories for every rule or invent missing tests. Test text is evidence of test
intent; an execution claim additionally needs the actual command/result/context.

Used by MUST link actual scenarios, not merely feature names. A global invariant
with no scenario consumer states that explicitly with its scope; an untraced
consumer is UNKNOWN, not NONE. Reverse links are navigation, not copies of rule text.

## Use case format

```markdown
### UC-NNN — <actor goal>

Actor / trigger:
- <who initiates the scenario and which event starts it>

Input:
- <business input> — <meaning, required/optional, valid values or linked constraint>

Preconditions:
- <state or permission that must hold before the scenario starts>

Behavior:
1. <business action or decision and its observable result>
2. <next step; reference applicable BR IDs at the relevant decision>

Alternatives / failures:
- <branch ID; originating step/condition> — <response, resulting state,
  effects preserved/rolled back, and rejoin or termination>

Output:
- <returned result, business meaning, and empty/error outcome where relevant>

Postconditions:
- <state guaranteed at successful completion; failure guarantees belong to branches>

Side effects:
- <business-visible change/event/history entry; when it occurs and failure semantics>

Business rules:
- <linked BR-ID — short title>

Data:
- <canonical entity/table/file/message> — <read/create/update/delete; purpose;
  link to data authority if one exists>

Evidence:
- <relative path + section/symbol/test name> — <which step/branch it supports>

Confidence: <HIGH | MEDIUM | LOW> — <basis and outstanding uncertainty>
Provenance: <APPROVED | OBSERVED | CONFIGURED | INFERRED | UNKNOWN | CONFLICT>
Verification: <VERIFIED | NEEDS_VERIFICATION | CONFLICT> — <checks actually performed>

Open questions / conflicts:
- <unresolved point and verification needed, or NONE>
```

Behavior MUST explain the complete main flow in business terms, not a list of
function calls. Alternatives/failures MUST cover each evidenced meaningful branch:
validation, permissions, empty results, cancellation, repeat requests, stale state
or partial failure where those actually exist. Do not invent generic edge cases.
Each branch states its outcome; "handle error" is insufficient.

Input and Output are external/business contracts, not copied method signatures.
Separate returned output, persistent or external side effects, and final state.
Data MUST use discovered names, not a familiar project's tables. No database does
not mean no data: files/messages/in-memory concepts may apply. If genuinely absent,
state NONE and why. Business rules link canonical records rather than restating them.

## Confidence and missing information

All fields above MUST be accounted for per record. NONE / NOT APPLICABLE requires
a reason; UNKNOWN requires a specific evidence gap and next check. An empty list,
placeholder or omitted field is not a completed record. Local equivalent sections
may carry these values; do not add redundant duplicate fields.

Confidence measures support for the stated claim, not approval or test execution:

| Value | Required basis |
|---|---|
| HIGH | Direct authoritative evidence for intended behavior, or direct inspected evidence for observed behavior, covers the material conditions/branches; no unresolved counterevidence |
| MEDIUM | Relevant evidence exists, but some material condition, branch or corroboration remains indirect/unverified; name it |
| LOW | Evidence is insufficient, primarily inferred, or contradictory; state what is missing and avoid a definitive behavioral claim |

MUST assess intended and observed claims separately when they disagree. A combined
unresolved behavior claim cannot receive HIGH; the factual statement that two
sources conflict can be well-supported. Confidence never overrides provenance or
verification, and MEDIUM/LOW is not permission to claim documentation complete.

## Record-level review

For a business conflict, Open questions / conflicts MUST include the conflict ID,
competing interpretations and evidence, affected BR/UCs, question sent to the user,
and pending or explicitly answered decision with its locator. Follow
[the user-resolution protocol](../evidence-rules.md#business-conflicts-require-user-resolution);
do not fill the resolved Rule/Behavior from the agent's preferred interpretation.

MUST check unique/stable IDs, meaningful field contents, source locator relevance,
and BR/UC references in both directions. Every UC Business rules link must resolve;
each corresponding BR Used by list must include the consuming UC. A BR consumer
must reference the rule back. Data references must resolve to actual discovered
concepts or be explicitly UNKNOWN. Never fabricate a UC just to satisfy backlinks.

Review main and alternative paths against raw evidence, not only against the
writer's record list. Missing rules, branches, outcomes, evidence or consumers are
findings even if every heading exists. Report orphan rules for investigation;
global invariants are not automatically defects. Keep record gaps tied to the
behavior-to-document map and apply the normal scope/authority repair limits.
