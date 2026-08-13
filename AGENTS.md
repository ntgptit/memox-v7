# AGENTS.md

**Read [`CLAUDE.md`](CLAUDE.md) first, in full. It is the contract for this
repository, and nothing in it is specific to one agent.**

This file exists because different agents load a different filename — Claude
Code reads `CLAUDE.md`, Codex reads `AGENTS.md` — and for no other reason. It
deliberately restates none of the rules: `docs/document-conventions.md` says one
fact lives in exactly one place, and a second copy of the layering rules here
would be the copy that goes stale first. Everything below is a pointer or a fact
that only a non-Claude agent needs.

## Where the contract is

| What | Where |
|---|---|
| Constraints that apply in every phase | [`CLAUDE.md`](CLAUDE.md) |
| How documents are written and read | [`docs/document-conventions.md`](docs/document-conventions.md) |
| What is done, in flight, blocked | [`docs/wbs.md`](docs/wbs.md) · [`docs/wbs-study.md`](docs/wbs-study.md) |
| Business rules · architecture decisions · use cases | [`docs/business-rules.md`](docs/business-rules.md) · [`docs/architecture.md`](docs/architecture.md) · [`docs/use-cases.md`](docs/use-cases.md) |
| The two worked feature examples | [`lib/features/deck/README.md`](lib/features/deck/README.md) · [`lib/features/card/README.md`](lib/features/card/README.md) |

`CLAUDE.md`'s **Reading order** section tells you which of those to open for the
task in front of you. Follow it rather than reading everything.

## `.claude/` is committed, and it is not Claude-only

The directory is tracked in git like any other source. Two things live there
that every agent needs:

- **`.claude/skills/`** — prose, one file per area of the checklist. For an
  agent with a skill mechanism these load automatically; for one without, they
  are documents to open and read. Nothing in them requires Claude Code to
  execute. `flutter-workflow/SKILL.md` is the router when you do not know which
  phase you are in.
- **`.claude/skills/*/scripts/`** — the project's gates. These are plain Python
  and bash. They are the same scripts CI runs, so a green run here means the
  same thing it means in the pipeline.

Do not treat `.claude/` as another agent's configuration and skip it. The
architecture guard and the document-integrity guard live nowhere else.

## Before anything analyzes

Generated code is not committed. A fresh clone does not analyze, test or run
until it exists:

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

Hundreds of analyzer errors right after cloning almost always means this step
was skipped. `CLAUDE.md` says the same thing; it is repeated here because it is
the one instruction whose omission looks like a broken repository rather than a
missing step.

## The gate, in one command

```bash
.claude/skills/flutter-workflow/scripts/dod_check.sh
```

It runs format, analyze, the generated-code check, the architecture guard, the
document guard, the code-verification guard and the test suite — the mechanical
half of the Definition of Done. The judgement half is in `CLAUDE.md`, and so is
the rule that a new feature is not done until the device suite has run on an
emulator.

## Two habits that are easy to get wrong here

**Docs outrank code and tests.** When code and a test agree with each other and
disagree with a `BR-xx` or `AD-xx`, the document wins and the other two are the
bug. This has already happened more than once.

**Prose without a MUST/SHOULD/MAY keyword is explanation, not a rule.** Do not
derive a new constraint from a paragraph that was describing why something is
the way it is, and do not treat a code example in a document as a spec.

## Prompt delivery contract

When the user asks for an implementation prompt, the agent MUST write a prompt
set under `docs/prompt/<feature-name>/`, using a stable kebab-case feature name.
If that directory already exists, update its stable files in place instead of
creating timestamped or numbered copies unless the user explicitly asks to
preserve versions. Prompt artifacts are execution aids, not sources of truth
for product behaviour: they MUST cite the applicable BR/AD/UC/wireframe
documents and MUST NOT silently define rules that are absent from them.

The directory MUST contain these three standalone prompt files unless the user
explicitly opts out of one of them:

1. **`implementation.md`** — the decision-complete task: scope, source of
   truth, files or layers affected, required behavior, tests, verification and
   Definition of Done.
2. **`recursive-architecture-logic-review.md`** — an independent audit of
   business-rule parity, state transitions, dependency boundaries, persistence,
   failure handling and tests. It MUST reproduce concrete failures, auto-fix
   in-scope findings, rerun verification and repeat until its stated clean-stop
   condition is met; a report-only review is insufficient.
3. **`recursive-ui-ux-review.md`** — an independent audit of layout,
   hierarchy, interaction, accessibility, responsiveness and visual fidelity.
   It MUST declare the approved divergences from any supplied concept, render
   the real production states, inspect the resulting screenshots or goldens,
   auto-fix unapproved differences and repeat until its stated visual clean-stop
   condition is met. When no concept image exists, it MUST compare against the
   repository's wireframes, design tokens and user-facing behavior contract.
   For every supplied concept it MUST also extract a geometry contract — content
   gutters, shared edges, relative widths/heights, grid gaps and baselines at the
   relevant viewports — and pin material relationships with `getRect` widget
   assertions against the production tree. A newly generated or updated golden
   is a regression baseline, not evidence that the implementation matches the
   concept; accepting it requires a state-by-state comparison with the concept
   and an explicit list of approved differences.

The two review prompts MUST remain separate: architecture correctness is not
evidence of visual completion, and visual similarity is not evidence of correct
business behavior. Each prompt MUST be executable in a fresh agent session and
therefore MUST carry its own scope, source-of-truth reading list, worktree-safety
rules, verification commands or repository gate, and explicit stop criteria.

After writing the three prompt files, the chat response MUST stay short and MUST
include one copy-pasteable trigger prompt for a fresh AI-agent session. That
trigger names the three repository-relative files and orders the agent to use
this workflow: implementation completes first; two independent subagents then
run their architecture/logic and UI/UX **audit-only passes in parallel**; fixes
are applied sequentially, architecture/logic first and UI/UX second after it
re-reads the latest worktree; the coordinator runs the final gate last. Parallel
review agents MUST NOT edit the shared worktree at the same time. If subagents
are unavailable, run the same phases sequentially with a fresh re-read before
each review. The trigger MUST stop on a real blocker or failed required gate and
MUST NOT collapse the phase reports into an unsupported blanket `pass`.

The chat response SHOULD also link to the feature prompt directory, but MUST NOT
repeat the three full prompt bodies unless the user explicitly asks for inline
content or the files could not be written. Every prompt file under `docs/` MUST
follow `docs/document-conventions.md`, including the seven-field header. Do not
store the short trigger as a fourth `run.md`; it exists in chat specifically so
the user can paste it into the fresh session that must execute the three files.
