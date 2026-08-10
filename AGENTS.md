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
