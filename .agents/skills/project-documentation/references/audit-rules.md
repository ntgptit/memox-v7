# Audit and verification

## Coverage matrix

MUST mark each applicable concern inspected/clean, findings, or unverified with a
reason. Full modes enumerate all first-party documents/modules and exclusions;
sampling is partial. UPDATE can limit coverage to affected sources/dependents.

| Concern | Mechanical evidence | Semantic inspection |
|---|---|---|
| Missing docs | Discovered files; optional required files | Required knowledge has a home without a prescribed directory |
| Location/naming/headings/metadata | Inventory; configured checks | Approved conventions, meaningful sections, actual status |
| References/IDs | Local links; repository guards | Correct meaning, permanent IDs; unsupported syntax reviewed |
| Terminology | Definitions/types/data names | Consistent concepts, distinct meanings preserved |
| Duplicate content/ownership | Authority declarations, hashes/search | One current canonical home, historical records distinguished |
| Staleness/orphans | Source changes, inbound references | Current claims supported; audience/entry path established |
| Folder architecture | Tree/imports/build wiring | Responsibilities, cycles, dependencies, module/shared ownership |
| Conflicting conventions | Runtime provenance records | Observed patterns can still have poor/inconsistent boundaries |
| Rules/use cases | Relevant specs and tests | Preconditions, alternatives, errors, transitions, postconditions |
| Diagrams | Mermaid blocks/rendering | Material edges/states agree with intended/observed role |
| Persistence, if present | Schema/migration candidates | Fields/constraints/indexes/transactions/version agree |
| Unsupported claims | Evidence records | Inference is never silently a fact or approval |
| Generated docs | Provenance and deterministic rerun | Generator owns bytes; analysis stays separate |

## Output set completion gate

MUST reconcile every family and required section in
[output-contract.md](output-contract.md) against actual files and content. Check
conditional applicability, canonical locations, consolidation authority, expected
versus actual unique file counts, and missing/empty sections. Matching headings
without meaningful content is not a pass. UPDATE/REPAIR remain scoped to affected
families; report unrelated gaps separately without expanding writes.
MUST check every generated Markdown file against its selected full-file template
and mapped local sections. Reject unresolved placeholders, empty sample rows,
unexpanded record insertion points and omitted applicable fields. Template links
must not leak into product docs; destination links resolve from the output file.

## Business coverage completion gate

For BR/UC documents MUST apply the record-level review in
[business-records.md](templates/business-records.md#record-level-review), including
field completeness, evidence/confidence justification and reciprocal BR/UC links.

MUST review the behavior-to-document map defined in
[documentation-contract.md](documentation-contract.md#business-completeness-not-code-narration).
Reconcile it in both directions: every in-scope rule/scenario has an adequate
canonical explanation, and every material behavioral claim in changed docs has
supporting authority/evidence. Re-read raw requirements and source/test branches
to find omissions from the map itself; checking only the writer's rows is insufficient.

For each relevant condition, can a reader determine what is allowed, what happens,
what can fail and the resulting state without reading implementation code? A link
to the canonical explanation is sufficient; a link only to source is not. Report
missing alternatives, restrictions, exceptions or consequences as coverage defects,
even when headings and mechanical checks pass. Flag code narration that substitutes
for a behavioral explanation. Do not demand irrelevant dimensions or extra prose.

MUST NOT report write modes complete/clean while an in-scope item is missing,
conflicting or unverified. Report partial/blocked coverage with concrete gaps instead;
an unresolved disposition makes the audit accountable, not the documentation complete.
AUDIT may finish with findings and MUST distinguish audit completion from coverage
completion. Outside-scope reasons cannot silently narrow the requested scope.

## Findings and repair

MUST report run-local ID, severity, category, locator, claim, evidence, provenance/
authority, proposed canonical fix, eligibility, disposition and recheck. High severity
misleads implementation/operations; medium harms coverage/navigation/consistency;
low affects presentation without those consequences.

Reproduce, then repair only evidence-supported eligible documentation. Recheck latest
tree and inbound links. Missing proof, conflicting authority and protected files
retain explicit unresolved dispositions. Do not change a rule to match a source bug.
A recurring unchanged failure stops that repair loop. AUDIT never edits docs.
For business conflicts, MUST verify that the user was asked under
[the resolution protocol](evidence-rules.md#business-conflicts-require-user-resolution).
Record the question, pending/answered state and exact decision evidence; neither a
reviewer recommendation nor a green check can substitute for the user's answer.

## Verification

```text
python "SKILL_DIR/scripts/validate_docs.py" --root "ROOT"
```

Zero-config checks discovered Markdown links and reports absent documentation as a
coverage finding. Overrides add required files, format rules and commands. `--paths`
limits supplemental checks, not required-file coverage. Discovery never executes
commands. After inspecting command authority/implementation, `--run-checks` executes
configured argv without a shell; `--audit` additionally restricts to read-only checks.
Skipped required checks are incomplete, not pass. Also run mandatory gates found in
instructions/CI that are not configured. Preserve worktree changes from test/generator
side effects. No generic framework gate is required by this skill.

Exit 0: passed mechanical checks; 1: findings/incomplete verification; 2: invalid
input/config/environment. JSON lists coverage and remaining manual work. Git is
optional: non-Git scans report no revision and conservative build/vendor exclusions.

The Markdown parser handles ordinary inline links/images, reference definitions,
local/root-relative targets and common heading fragments. External URLs, HTML,
complex nested/escaped Markdown need separate review; code examples are ignored.
Mermaid rendering, semantic duplicate/stale/orphan checks, live schema extraction,
architecture quality and authority decisions remain agent/repository-tool work.

## Skill maintenance

Run `python -m unittest discover -s "SKILL_DIR/scripts/tests" -p "test_*.py"`
and the installed skill-creator validator. Exercise temporary repositories:
AUDIT finds a fixable defect without writes; UPDATE handles no docs directory or
database; REPAIR fixes a proven stale link; FULL_SYNC retains uncertain/conflicting
ownership; config stays distinguishable from approval; installs detect tampering,
wrong authority and pin mismatch. Record actual artifacts/outcomes, not only grep.
Self-review is not independent evaluation. After review, seal the source release,
explicitly synchronize managed copies and verify version/hash.
