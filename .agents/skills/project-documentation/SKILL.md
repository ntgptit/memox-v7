---
name: project-documentation
description: Create, update, audit, and repair repository documentation against source evidence and discovered local conventions. Use for documentation sync, folder architecture, diagrams, terminology, and integrity; not product implementation.
---

# Project documentation

The skill defines HOW. Runtime repository context defines WHERE, WHAT and under
which constraints. Source and documents supply evidence; optional config supplies
deltas. Use this same skill unchanged across repositories.

`SKILL_DIR` means the absolute directory of the **actually loaded** SKILL.md;
`ROOT` is the target repository, never implicitly the skill installation folder.
Resolve both before substituting command arguments. Helpers need Python 3.10+;
Git is optional. Version and payload identity live in `skill-manifest.json`.

## Modes

| Mode | Input | Result |
|---|---|---|
| UPDATE | Task/change set and identified comparison base | Affected canonical docs and dependent references updated |
| AUDIT | Whole project by default, or explicit scope | Coverage and findings, no documentation writes |
| REPAIR | Findings and raw evidence | Confirmed eligible defects repaired and re-audited |
| FULL_SYNC | Explicit whole-project sync request | Discovery, source/docs audit, eligible repairs, review, verification |

MUST honor explicit scope/mode. Otherwise use UPDATE for documentation changes,
AUDIT for reviews, REPAIR for confirmed fixes. Ambiguity defaults to AUDIT.
Product implementation and schema changes remain outside documentation repair.

## 1. Inspect identity and bound the work

MUST identify the actual loaded path and inspect integrity, scope and overrides:

```text
python "SKILL_DIR/scripts/skill_distribution.py" inspect --root "ROOT" --active "SKILL_DIR"
```

For install/sync/update/pinning or conflicting copies, MUST read
[distribution.md](references/distribution.md). Do not assume host name precedence.
Resolve modified payload, conflicting copies or a repository pin mismatch before
writes; AUDIT reports them. Ordinary workflow runs MUST NOT update/install skills.

MUST record task, mode, initial scope, worktree state and relevant comparison base.
Preserve others' changes. A non-trivial plan starts with a concrete 5Why connecting
root causes, evidence gaps, tradeoffs and constraints to decisions. Refine the exact
editable-file list after discovery and before writing.

**Exit:** active skill identity and scope are known; missing canonical access or
conflicting selection is explicit, never assumed current.

## 2. Discover — mandatory for each new target

MUST read [discovery.md](references/discovery.md) and follow its ordered discovery.
Read applicable instructions first, including their reading order, then run:

```text
python "SKILL_DIR/scripts/scan_docs.py" --root "ROOT"
python "SKILL_DIR/scripts/repository_context.py" --root "ROOT"
```

Helpers return candidates, not approved standards. Complete runtime context by
reading the actual instructions, source, tests and docs. Read
[configuration.md](references/configuration.md) when an override exists or is needed.
Zero-config is normal; absent folders, databases or formal specs do not require a
new skill or a copied project structure.

**Exit:** every discovery dimension has evidence or explicit uncertainty; approved
rules remain distinct from observed/configured/inferred patterns and conflicts.

## 3. Investigate and classify

MUST read [documentation-contract.md](references/documentation-contract.md) and
[evidence-rules.md](references/evidence-rules.md). Build coverage from context:
folder responsibilities, boundaries, dependency direction, shared/core/feature
ownership where present, documentation authorities, terms, flows, and persistence
where applicable. UPDATE follows changed sources and dependent docs. Full modes
enumerate all first-party areas and exclusions. MUST build the contract's
behavior-to-document map; investigation coverage alone is not documentation coverage.
MUST resolve the applicable file set and per-file sections with
[output-contract.md](references/output-contract.md), including an output manifest.

Use scoped subagents for independent investigations when useful and compliant with
the target's runtime/model/spend policy; load applicable local agent presets.
Before dispatch MUST use [agent-handoff.md](references/templates/agent-handoff.md).
Investigators are read-only; the coordinator serializes edits. Dependent work
follows its inputs. If compliant delegation is unavailable, use sequential passes
and disclose that review is not independent.

MUST classify findings with [audit-rules.md](references/audit-rules.md). Existing
patterns can still have poor boundaries, duplicate ownership, inconsistent
architecture or stale documentation structure; discovery does not approve them.

**Exit:** coverage is inspected or explicitly unverified; findings and claims have
evidence, authority and exact edit eligibility. AUDIT skips step 4.

## 4. Write or repair

MUST update canonical content before creating files. Combine generic contract and
approved local conventions with optional deltas; do not fork the workflow per repo.
MUST read [template-rules.md](references/templates/template-rules.md) and each selected
full-file template before writing. Compose BR/UC record templates into their file
templates; do not emit outlines, empty scaffolds or only representative records.
With no docs, create the applicable catalog files at locations justified by discovery,
limited to the requested scope. Do not collapse the set to an entry document without
an explicit user/local consolidation rule. No docs directory or database is assumed.
Preserve protected/frozen authorities unless the task permits changing them.

MUST repair descriptive drift only with evidence, retaining product-rule conflicts
instead of changing rules to match bugs. Update metadata and inbound references.
On a business conflict, MUST ask the user and pause dependent edits under
[business conflict resolution](references/evidence-rules.md#business-conflicts-require-user-resolution).
Apply this as soon as a conflict is found in any phase; do not defer it to the final report.
Use deterministic generators for mechanical content; keep authored analysis separate.

**Exit:** each edit traces to evidence/scope, with no invented requirement or duplicate
authority; confirmed issues are fixed or explicitly unresolved.

## 5. Review and re-audit

MUST use an independent read-only auditor when compliant delegation is available,
giving raw evidence, request, context and final diff rather than a desired verdict.
Otherwise perform and label a fresh-read self-review. Write modes repeat detect →
classify → reproduce → eligible repair → re-audit. AUDIT only reviews findings.
Re-read the latest tree between handoffs. Stop a recurring unchanged failure or an
evidence/authority blocker, retaining its disposition; complete independent work.

**Exit:** each finding has a verified fix or reproducible unresolved disposition;
all changed claims and dependent references were rechecked. MUST apply the
business coverage completion gate in audit-rules.md before claiming write completion.

## 6. Verify and report

MUST run generic checks and the target's required gates using
[audit-rules.md](references/audit-rules.md#verification). Check final diff/worktree.
Report mode, expected/actual file counts and missing sections from the output manifest,
coverage/exclusions, edits, findings, evidence gaps, reviewer type and
actual command outcomes. Keep evidence in chat unless a persisted report was
requested, then follow that target's format.

**Exit:** AUDIT may complete with findings. Write modes are verified clean only with
no unresolved in-scope defect and passing required checks. Mechanical success does
not imply semantic correctness; blocked or partial verification stays explicit.
