# AGENTS.md

## Project

This project is `code-verification-guard`, a portable YAML-first code standards verification tool.

Its purpose is to check a project's code and block or report patterns that the project owner or manager has defined as bad for that project. It helps make users, Codex, Claude, and other coding agents follow the project's declared rules, including coding standards, architecture boundaries, and workflow constraints.

Keep the Python engine generic. Concrete rules belong in YAML unless a new generic matcher, reporter, resource loader, CLI command, or validation capability is needed.

## Ownership — vendored into MemoX

This directory is **vendored into the MemoX repository and owned by it**. It is not an independent repository living inside MemoX, and it must not be treated as one:

- There is one source of truth for the guard: the copy committed here, in `ntgptit/memox-v7`. Changes to the engine, the common rules, or the MemoX rulesets are made **in place**, reviewed, and committed together with the MemoX change that motivated them — the same as any other file in MemoX.
- Do **not** `git clone` a separate `code-verification-guard` remote over this directory. A re-clone silently discards fixes made here — for example the `common.no_commented_out_code` false-positive fix and the `DateTime.now()`-in-comment fix, both of which live only in this vendored copy and are pinned by `tests/test_memox_false_positive_regressions.py`. The historical "refresh from upstream" procedure was exactly the two-source-of-truth trap that this ownership note removes.
- Do **not** commit nested `.git` metadata for this directory. It is tracked as ordinary files by the parent MemoX repository; there is no submodule and no inner repository.

The vendored version is recorded in `VERSION`. Bump it in the same commit whenever the engine, matchers, or common rules change, so a reviewer can see at a glance which guard a given MemoX commit ran against.

### If code ever needs to flow to another project

Copy files out of this directory into the other project and adapt them there; that other copy is then owned by that other project. Do not turn this directory back into a shared remote that MemoX pulls from — that reintroduces the divergence this note exists to prevent.

## References

Read only when the task touches that area:

- Core architecture: `docs/agent-architecture.md`
- YAML rules/scopes/profiles: `docs/agent-yaml-contract.md`
- Source distribution/resource behavior: `docs/agent-packaging.md`
- Extended verification gates: `docs/agent-verification.md`

## Default Check

For MemoX ruleset verification, run from the MemoX repository root:

```bash
python code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v7
```

Expected success:

```text
Code verification passed.
No violations found.
```

For any change to the Python engine, matchers, or rules in this directory, also run, from this directory:

```bash
python -m pytest -q
python -m compileall -q code_verification_guard
```

The MemoX CI (`.github/workflows/ci.yml`) runs the default check on every push and pull request, against this vendored copy — never against an external remote.

## Completion Report

Report:

1. Files changed
2. Command run
3. Result
4. Remaining risk
