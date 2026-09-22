# audit-report document template

Read [template rules](template-rules.md) before using this scaffold.
MUST fill the following file scaffold from discovered evidence and applicable authorities.

Insert the shared document identity block after the output title, unless the local
metadata format already carries it. The fenced content is the output scaffold,
not a prewritten claim about any repository.

```markdown
# <Scope> documentation audit

## Request, mode and inspected state
<Task, AUDIT/REPAIR/FULL_SYNC, revision/dirty state, timestamp if actually recorded.>

## Skill identity and repository context
<Active skill path/version/scope, overrides, authorities and relevant discovery results.>

## Output manifest
| Family | Applicability/basis | Template | Canonical paths/sections | Expected action | Actual status |
|---|---|---|---|---|---|
| <family> | <yes/no/unknown + evidence> | <template> | <locations> | <action> | <status> |
Expected/actual unique files: <counts>; missing files/sections: <list>.

## Investigation and business coverage
| Area / BR / UC | Evidence inspected | Canonical documentation | Coverage status | Gap/exclusion reason |
|---|---|---|---|---|
| <item> | <raw locators> | <section link> | <covered/missing/conflict/unverified/outside scope> | <reason> |

## Findings
### <Finding ID — title>
Severity/category: <impact-based level/category>.
Locator/claim: <exact document section and disputed claim>.
Evidence/authority: <support and counterevidence with provenance>.
Impact: <reader/implementation consequence>.
Fix and eligibility: <canonical repair; authorization/protection limits>.
Disposition: <fixed/open/blocked/not applicable + reason>.
Recheck: <actual result and evidence>.

## Changes applied
<Paths and resolved findings; NONE for audit-only.>

## Verification results
| Command/review | Scope/environment | Actual result | Evidence | Limitations |
|---|---|---|---|---|
| <check> | <context> | <pass/fail/not run> | <locator> | <gap> |

## Reviewer and remaining gaps
<Independent auditor or fresh-read self-review; unresolved findings and evidence gaps.>

## Outcome
<Audit completed with findings / partial / blocked / verified clean; justify against coverage and required checks.>
```
