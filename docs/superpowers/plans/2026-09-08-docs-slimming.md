# Docs slimming implementation plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Shrink `docs/` from 71,361 lines across 183 files to a living set a person can hold, by retiring closed work into archives the guard still polices — and by closing the enforcement hole that let three task IDs collide unnoticed.

**Architecture:** Nothing is deleted and no ID is renamed. Closed entries move into sibling files; `check_docs.py` stops naming ledger files one by one and starts globbing a directory, so an archive stays inside the duplicate-ID and dependency graph. The enforcement fix lands *before* the first move, because moving 295 entries while the guard is blind to 30 of them is how the next collision gets written.

**Tech Stack:** Python 3.12 (`check_docs.py`, `unittest`), Markdown, GitHub Actions.

**Spec:** This plan is its own spec — every number in it was measured on `3fdd3d65` and the measurement command is quoted beside the number. No requirement below comes from a document that does not exist.

## The measurement this plan argues from

Taken on `docs/wbs.md` at `3fdd3d65`, worktree clean:

| Fact | Value | How it was measured |
|---|---|---|
| `docs/wbs.md` | 19,856 lines · 1.45 MB · 302 `### M/T` entries | `wc -l`, `grep -c '^### [TM][0-9]'` |
| Entries whose Status starts `done` | **295 · 19,312 lines · 97%** | status parse per entry (see below) |
| Entries not `done` | 7 · 503 lines | same |
| Genuinely in progress | **1** — `M99.29` | the other six are `descoped` ×3, `integrated`, `superseded`, and one stale |
| Task headings the guard can see | **282 of 312** | `_TASK_HEAD_RE` vs `^#{2,3} [TM][0-9]` |
| Duplicate task IDs present | **3** — `M99.53`, `M99.54`, `M99.55` | six distinct tasks sharing three numbers |
| Distinct BR/AD/UC IDs · citations | 315 · **14,789** | `grep -rhoE '\b(BR\|AD\|UC)-[0-9]+' docs .claude CLAUDE.md lib test` |

The status census is reproducible with:

```bash
python -X utf8 - <<'PY'
import io, re, collections
lines = io.open('docs/wbs.md', encoding='utf-8').read().split('\n')
hdrs = [(i, l) for i, l in enumerate(lines) if re.match(r'^### [TM][0-9]', l)]
done = collections.defaultdict(lambda: [0, 0]); openv = collections.defaultdict(lambda: [0, 0])
for k, (i, l) in enumerate(hdrs):
    end = hdrs[k+1][0] if k+1 < len(hdrs) else len(lines)
    body = '\n'.join(lines[i:end])
    ms = re.match(r'([TM][0-9]+)', l.split()[1]).group(1)
    m = re.search(r'^- \*\*Status:\*\*\s*\**(\S+)', body, re.M)
    st = (m.group(1) if m else 'none').strip().lower().strip('*')
    t = done if st.startswith('done') else openv
    t[ms][0] += 1; t[ms][1] += end - i
for ms in sorted(set(done) | set(openv), key=lambda s: (len(s), s)):
    print(ms, 'done', done.get(ms, [0,0]), 'open', openv.get(ms, [0,0]))
PY
```

Per-milestone, which is what sizes the archive files:

| Milestone | done entries | done lines | open entries | open lines |
|---|---|---|---|---|
| T0 · T1 | 8 | 236 | 0 | 0 |
| M2 | 9 | 474 | 0 | 0 |
| M3 | 12 | 669 | 0 | 0 |
| M4 | 83 | 4,854 | 3 | 101 |
| M5 | 28 | 1,756 | 0 | 0 |
| M99 | 96 | 7,050 | 2 | 268 |
| M100 | 59 | 4,273 | 2 | 134 |
| **Total** | **295** | **19,312** | **7** | **503** |

## Global Constraints

Every task's requirements implicitly include this section. Values are copied
verbatim from the code they describe.

- **No ID is renamed except the three that collide.** 14,789 citations across
  `docs/`, `lib/`, `test/`, `CLAUDE.md` and `.claude/skills/` resolve by ID, not
  by file path, so moving a definition between files breaks nothing. Renaming
  one breaks everything that cites it.
- **Nothing is deleted.** Content moves; git history is not the archive.
- **`check_docs.py` must stay green at every commit**, run as CI runs it:
  `python .claude/skills/flutter-workflow/scripts/check_docs.py --quiet`
- **The tooling tests must stay green**, run as CI runs them:
  `python -m unittest discover -s .claude/skills/flutter-workflow/scripts/tests -p 'test_*.py'`
- **Every new guard rule is fault-injected before it is trusted.** A rule that
  has never been seen to fail is a rule that has never been seen. This is the
  repo's own standard: `code-verification-guard-v2` runs its probes *before* its
  verdict for exactly this reason (`ci.yml`, "guard self-tests").
- **`_docs_md()` globs three places and only three:** `docs/*.md`,
  `docs/it-scenarios/*.md`, `docs/design-system/*.md`. A file placed there
  inherits the 7-field header contract (`Status`, `Purpose`, `Scope`,
  `Source of truth for`, `Depends on`, `Updated by task`, `Last updated`) and
  the "no two documents claim the same source of truth" rule. A file placed
  anywhere else under `docs/` inherits neither. **Archive directories are
  therefore placed outside that glob on purpose.**
- **Frozen documents.** `docs/product.md`, `docs/business-rules.md`,
  `docs/architecture.md`, `docs/use-cases.md` and `docs/data-model.md` carry
  Status `frozen for MVP`. CLAUDE.md forbids a task from editing one unless the
  task names it. Phase 4 names them; Phases 0–3 must not touch them.
- **Vietnamese is this repo's language for `docs/wbs.md`.** New WBS prose is
  written in Vietnamese; guard code, comments and commit messages stay English.

---

## File Structure

**Created**

| Path | Responsibility |
|---|---|
| `docs/wbs-archive/README.md` | Index: one line per archive file, what milestone it holds, how many entries |
| `docs/wbs-archive/t0-t1-m2-m3.md` | 29 closed entries, 1,379 lines — the harness and foundation milestones |
| `docs/wbs-archive/m4.md` | 83 closed entries, 4,854 lines |
| `docs/wbs-archive/m5.md` | 28 closed entries, 1,756 lines |
| `docs/wbs-archive/m99.md` | 96 closed entries, 7,050 lines |
| `docs/wbs-archive/m100.md` | 59 closed entries, 4,273 lines |
| `docs/reviews/archive/README.md` | Index: one line per retired audit — its ID, subject, and the task that consumed it |

**Modified**

| Path | Change |
|---|---|
| `.claude/skills/flutter-workflow/scripts/check_docs.py` | Widen the task-ID regex; add a wrong-heading-level rule; make the ledger set a glob |
| `.claude/skills/flutter-workflow/scripts/tests/test_check_docs.py` | New file — fault injection for all three rules |
| `docs/wbs.md` | Status correction; three renumbered entries; 295 entries move out; header and Progress summary rewritten |
| `docs/README.md` | `## What exists` gains the two archive directories |

Files that change together live together: the guard rule and its fault
injection are one task, never two.

---

## Phase 0 — The ledger tells the truth about today

One task. It is first because every later phase moves this file, and moving a
file that is already lying just relocates the lie.

### Task 1: Correct M100.61's status

**Files:**
- Modify: `docs/wbs.md` — the `### M100.61` entry
- Test: `python .claude/skills/flutter-workflow/scripts/check_docs.py --quiet`

**Interfaces:**
- Consumes: nothing
- Produces: nothing later tasks depend on. This is a content fix.

- [ ] **Step 1: Confirm the drift is real, not remembered**

```bash
git log --oneline -1 --grep='M100.61'
grep -n -A2 '^### M100.61' docs/wbs.md | head -5
```

Expected: the log shows `3fdd3d65 feat(deck,study): the two loud heroes join
the five quiet ones (M100.61) (#508)` while the entry still reads
`**Status:** in review (2026-09-08) — **bản thử, chưa merge theo yêu cầu chủ
dự án**`. If the log shows no such commit, stop — this task's premise is gone
and the plan needs re-measuring.

- [ ] **Step 2: Rewrite the Status line and the open acceptance criterion**

Replace the Status line with:

```markdown
- **Status:** done (2026-09-08) — merged as `3fdd3d65` (#508). Shipped as a
  trial for aesthetic review first; the owner approved it on the before/after
  gallery and it was merged in the same session.
```

And the last acceptance criterion, currently unchecked, becomes:

```markdown
  - [x] Chủ dự án review gallery trước–sau rồi mới quyết merge hay bỏ.
```

- [ ] **Step 3: Verify the guard still passes**

Run: `python .claude/skills/flutter-workflow/scripts/check_docs.py --quiet`
Expected: exit 0. The M-task template rule requires a non-empty acceptance
block; a `- [x]` box satisfies `_AC_BOX_RE` exactly as `- [ ]` did.

- [ ] **Step 4: Commit**

```bash
git add docs/wbs.md
git commit -m "docs(wbs): M100.61 says merged, because it is

The entry still read 'bản thử, chưa merge' after 3fdd3d65 landed it. A ledger
that lags the code is worse than no ledger: the next session trusts it.

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

## Phase 1 — Close the enforcement hole

Two tasks, in this order. The guard is widened first so it goes **red** on the
three real collisions; then the collisions are fixed and it goes green. Doing
it the other way round proves nothing.

### Task 2: The guard sees every task heading, and refuses one written at the wrong level

**Files:**
- Modify: `.claude/skills/flutter-workflow/scripts/check_docs.py:200-201` and `_check_wbs_tasks`
- Create: `.claude/skills/flutter-workflow/scripts/tests/test_check_docs.py`

**Interfaces:**
- Consumes: nothing
- Produces: `_TASK_HEAD_RE` matching a two-letter suffix; a new
  `_check_task_heading_level()` called from `_check_wbs_tasks()`. Task 3
  depends on this rule being live; Task 4 replaces the file list it iterates.

**Why both changes are one task:** they answer the same question — "which
headings are tasks?" — and splitting them would leave a commit where the guard
counts 303 headings but still cannot see three of them.

- [ ] **Step 1: Write the failing tests**

Create `.claude/skills/flutter-workflow/scripts/tests/test_check_docs.py`:

```python
from __future__ import annotations

import importlib.util
import sys
import unittest
from pathlib import Path

SCRIPTS = Path(__file__).resolve().parents[1]


def _load(name: str):
    spec = importlib.util.spec_from_file_location(name, SCRIPTS / f"{name}.py")
    assert spec and spec.loader
    module = importlib.util.module_from_spec(spec)
    sys.modules[name] = module
    spec.loader.exec_module(module)
    return module


check_docs = _load("check_docs")


class TaskHeadingRegexTest(unittest.TestCase):
    """The id shapes this ledger actually uses, not the ones it started with."""

    def test_a_one_letter_suffix_is_a_task(self) -> None:
        m = check_docs._TASK_HEAD_RE.match("### M4.10a · something")
        self.assertIsNotNone(m)
        self.assertEqual(m.group(1), "M4.10a")

    def test_a_two_letter_suffix_is_a_task(self) -> None:
        # 21 entries in docs/wbs.md are shaped this way (M4.10aa..M4.10at) and
        # the original `[a-z]?` could not see one of them, so none of them was
        # in the duplicate check or the dependency graph.
        m = check_docs._TASK_HEAD_RE.match("### M4.10aa · something")
        self.assertIsNotNone(m)
        self.assertEqual(m.group(1), "M4.10aa")

    def test_a_three_letter_suffix_is_not(self) -> None:
        # The bound is deliberate: `[a-z]*` would swallow a prose heading that
        # merely starts with an M and a number.
        self.assertIsNone(check_docs._TASK_HEAD_RE.match("### M4.10abc · x"))

    def test_the_token_form_agrees_with_the_heading_form(self) -> None:
        # A dependency names a bare token; if the two regexes disagree, a
        # legal id becomes an unresolvable dependency.
        self.assertIsNotNone(check_docs._TASK_TOKEN_RE.match("M4.10aa"))


class HeadingLevelTest(unittest.TestCase):
    """A dotted task id at `##` is a task hiding from the duplicate check."""

    def test_a_dotted_id_at_section_level_is_a_finding(self) -> None:
        bad = check_docs._wrong_level_task_headings(
            ("## M99.55 — Deck review", "### M99.55 · MxDialogTone")
        )
        self.assertEqual(bad, ["## M99.55 — Deck review"])

    def test_a_milestone_header_at_section_level_is_fine(self) -> None:
        # `## M4 · Router and Drift foundation` is a section, not a task: no
        # dot, no 9-field template, and it has been legal since M0.
        self.assertEqual(
            check_docs._wrong_level_task_headings(
                ("## M4 · Router and Drift foundation", "## M99 · Adhoc")
            ),
            [],
        )


if __name__ == "__main__":
    unittest.main()
```

- [ ] **Step 2: Run the tests to verify they fail**

Run:
```bash
python -m unittest discover -s .claude/skills/flutter-workflow/scripts/tests -p 'test_check_docs.py'
```
Expected: FAIL — `test_a_two_letter_suffix_is_a_task` fails with
`AssertionError: unexpectedly None`, and both `HeadingLevelTest` cases fail with
`AttributeError: module 'check_docs' has no attribute '_wrong_level_task_headings'`.

- [ ] **Step 3: Widen the two regexes**

In `check_docs.py`, replace lines 200-201:

```python
_TASK_HEAD_RE = re.compile(r"^### ([TM][0-9]+(?:\.[0-9]+)?[a-z]?) ")
_TASK_TOKEN_RE = re.compile(r"^[TM][0-9]+(?:\.[0-9]+)?[a-z]?$")
```

with:

```python
# **Two letters, because the ledger ran out of one.** `M4.10a`…`M4.10z` filled
# up during the deck redesign and the next twenty-one entries became
# `M4.10aa`…`M4.10at` — legal ids that this regex could not match, so twenty-one
# tasks sat outside the duplicate check and outside the dependency graph while
# the check reported success over the rest. The bound stays finite: `[a-z]*`
# would match a prose heading that happens to open with an M and a number.
_TASK_HEAD_RE = re.compile(r"^### ([TM][0-9]+(?:\.[0-9]+)?[a-z]{0,2}) ")
_TASK_TOKEN_RE = re.compile(r"^[TM][0-9]+(?:\.[0-9]+)?[a-z]{0,2}$")
```

- [ ] **Step 4: Add the heading-level rule**

Immediately after `_TASK_TOKEN_RE`, add:

```python
# A task id carries a dot (`M99.55`); a milestone section does not (`M99`).
# That is the whole difference, and it is enough to tell a task written at the
# wrong level from a section header that has been legal since M0.
_WRONG_LEVEL_RE = re.compile(r"^## [TM][0-9]+\.[0-9]+[a-z]{0,2} ")


def _wrong_level_task_headings(lines: tuple[str, ...] | list[str]) -> list[str]:
    """Task headings written at `##`, where the task rules cannot reach them.

    **This is not a style rule.** `_TASK_HEAD_RE` anchors on `### `, so a task
    written one level up is invisible to the duplicate-id check, to the
    dependency graph, and to the 9-field template check — all three at once.
    Three entries in `docs/wbs.md` were written that way and each collided with
    a real `###` task: `M99.53`, `M99.54` and `M99.55` named six different
    pieces of work between them, and the guard printed "no duplicate WBS task
    IDs" over the top of it.
    """
    return [line.rstrip() for line in lines if _WRONG_LEVEL_RE.match(line)]
```

- [ ] **Step 5: Call it from `_check_wbs_tasks`**

At the top of `_check_wbs_tasks()`, immediately after `task_ids = _wbs_task_ids()`, insert:

```python
    before_level = _problems
    for path in (WBS_FILE, STUDY_WBS_FILE):
        for heading in _wrong_level_task_headings(_lines(path)):
            _fail(
                "task heading written at section level",
                f"{path}: {heading[:72]}\n      "
                "a dotted task id belongs at '### '; at '##' it is invisible "
                "to the duplicate check, the dependency graph and the template "
                "check",
            )
    if _problems == before_level:
        _ok("no task heading is written at section level")
```

- [ ] **Step 6: Run the tests to verify they pass**

Run:
```bash
python -m unittest discover -s .claude/skills/flutter-workflow/scripts/tests -p 'test_check_docs.py'
```
Expected: PASS, 6 tests.

- [ ] **Step 7: Run the guard and expect it to go RED — this is the point**

Run: `python .claude/skills/flutter-workflow/scripts/check_docs.py --quiet`
Expected: **FAIL**, with six findings:

```
task heading written at section level
  docs/wbs.md: ## M99.55 — Deck review: đo những khung gallery chưa từng chụp
task heading written at section level
  docs/wbs.md: ## M99.54 — `MxButtonPair` hỏi hai nút thay vì đoán
task heading written at section level
  docs/wbs.md: ## M99.53 — Pixel comparison trở thành cổng của PR
```

plus, once those become `###` in Task 3, the duplicate rule. If the guard
passes here, the rule is not wired in — go back to Step 5.

- [ ] **Step 8: Commit the guard alone, red**

The guard is committed red on purpose: the commit that widens a rule and the
commit that cleans up after it are two different reviews, and squashing them
hides which one found what.

```bash
git add .claude/skills/flutter-workflow/scripts/check_docs.py \
        .claude/skills/flutter-workflow/scripts/tests/test_check_docs.py
git commit -m "fix(docs-guard): see the 30 task headings it was missing

_TASK_HEAD_RE allowed one optional letter after the number, so the 21
M4.10aa..M4.10at entries never entered the duplicate check or the dependency
graph. A separate hole: a dotted task id written at '##' is invisible to all
three task rules at once, and three entries are written that way.

The guard fails on this commit. That is the finding, not a regression.

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

### Task 3: The three collisions get their own numbers

**Files:**
- Modify: `docs/wbs.md:7920`, `:8034`, `:8075`

**Interfaces:**
- Consumes: `_wrong_level_task_headings` from Task 2 — it is what proves this task worked.
- Produces: task IDs `M100.62`, `M100.63`, `M100.64`. No later task depends on them.

- [ ] **Step 1: Confirm which of each pair is which**

```bash
grep -nE "^#{2,3} M99\.5[345]" docs/wbs.md
```

Expected exactly six lines: three at `##` (7920, 8034, 8075) and three at `###`
(12431, 12516, 12560). The `###` copies keep their numbers — they are already
in the dependency graph and may be cited. The `##` copies are renumbered.

- [ ] **Step 2: Renumber and re-level the three headings**

`docs/wbs.md:7920`:
```markdown
### M100.62 · Deck review: đo những khung gallery chưa từng chụp, rồi sửa cái đo được
```

`docs/wbs.md:8034`:
```markdown
### M100.63 · `MxButtonPair` hỏi hai nút thay vì đoán
```

`docs/wbs.md:8075`:
```markdown
### M100.64 · Pixel comparison trở thành cổng của PR
```

- [ ] **Step 3: Record the renumber inside each entry**

Immediately under each new heading, add a first bullet. For `M100.62`:

```markdown
- **Đổi số 2026-09-08.** Entry này từng mang số `M99.55` và được viết ở cấp
  `##`, nên guard không nhìn thấy nó: `M99.55` khi đó cũng là số của một task
  khác (`MxDialogTone`, dòng 12560). Sáu task dùng chung ba số và
  `check_docs.py` vẫn in "no duplicate WBS task IDs" vì nó chỉ thấy một nửa.
  Bản `###` giữ số cũ vì đã nằm trong đồ thị dependency; bản này nhận số mới.
```

For `M100.63`, the same paragraph with `M99.54` and *"Checkbox đã tick bị co
lại 4dp, dòng 12516"*. For `M100.64`, `M99.53` and *"`MxButtonPair`, dòng
12431"*.

- [ ] **Step 4: Verify each renumbered entry still meets the 9-field template**

Run: `python .claude/skills/flutter-workflow/scripts/check_docs.py --quiet`
Expected: **FAIL** if any of the three lacks a field — they were written at
`##` and so were never template-checked. `_M_REQUIRED` is: `Status`, `Goal`,
`Scope`, `Editable documents`, `Output`, `Acceptance criteria`, `Dependencies`,
`Tests required`, `Checklist phases`, plus at least one `- [ ]` or `- [x]` box.
Add whatever is missing from what the entry already says; do not invent
acceptance criteria that were never met — if the work is closed, write the
criteria it actually satisfied and tick them.

- [ ] **Step 5: Run the guard to verify it now passes**

Run: `python .claude/skills/flutter-workflow/scripts/check_docs.py --quiet`
Expected: exit 0, and the summary line now reads
`no duplicate WBS task IDs (312 tasks)` — up from 282, because the widened
regex and the re-levelled headings both feed it.

- [ ] **Step 6: Commit**

```bash
git add docs/wbs.md
git commit -m "docs(wbs): six tasks stop sharing three numbers

M99.53, M99.54 and M99.55 each named two unrelated pieces of work. The copy
written at '##' takes M100.62/63/64 and moves to '###'; the copy at '###'
keeps its number because it is already in the dependency graph. Each entry
records the number it used to carry.

The template check reaches all three for the first time.

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

## Phase 2 — The ledger keeps the living work; the archive keeps the rest

Three tasks. **Task 4 must land before any entry moves.**

### Task 4: The ledger set becomes a glob

**Files:**
- Modify: `.claude/skills/flutter-workflow/scripts/check_docs.py` — `WBS_FILE`/`STUDY_WBS_FILE` block and `_check_wbs_tasks`
- Modify: `.claude/skills/flutter-workflow/scripts/tests/test_check_docs.py`

**Interfaces:**
- Consumes: `_wrong_level_task_headings` (Task 2).
- Produces: `_wbs_ledgers() -> list[str]`. Tasks 5 and 6 rely on archive files
  being inside the duplicate-ID and dependency scan; nothing else calls it.

- [ ] **Step 1: Write the failing test**

Append to `test_check_docs.py`:

```python
class LedgerSetTest(unittest.TestCase):
    """Every file that can define a task id is in the duplicate scan."""

    def test_the_live_ledgers_are_in_the_set(self) -> None:
        ledgers = check_docs._wbs_ledgers()
        self.assertIn("docs/wbs.md", ledgers)
        self.assertIn("docs/wbs-study.md", ledgers)

    def test_an_archive_file_joins_without_a_code_change(self) -> None:
        # A glob rather than a list, because the alternative is what already
        # happened: `wbs-study.md` was added by name and became the only
        # companion the guard would ever know about.
        import tempfile, pathlib
        with tempfile.TemporaryDirectory() as tmp:
            root = pathlib.Path(tmp)
            (root / "docs" / "wbs-archive").mkdir(parents=True)
            (root / "docs" / "wbs.md").write_text("# x", encoding="utf-8")
            (root / "docs" / "wbs-archive" / "m4.md").write_text(
                "### M4.1 · x", encoding="utf-8"
            )
            original = check_docs._REPO
            try:
                check_docs._REPO = root
                self.assertIn("docs/wbs-archive/m4.md", check_docs._wbs_ledgers())
            finally:
                check_docs._REPO = original
```

- [ ] **Step 2: Run it to verify it fails**

Run:
```bash
python -m unittest discover -s .claude/skills/flutter-workflow/scripts/tests -p 'test_check_docs.py'
```
Expected: FAIL — `AttributeError: module 'check_docs' has no attribute '_wbs_ledgers'`.

- [ ] **Step 3: Add the glob**

In `check_docs.py`, after line 101 (`STUDY_WBS_FILE = "docs/wbs-study.md"`), add:

```python
WBS_ARCHIVE_DIR = "docs/wbs-archive"


def _wbs_ledgers() -> list[str]:
    """Every file that can define a WBS task id.

    **The duplicate rule and the dependency graph are only true over the whole
    set.** An id retired into the archive is still spent — reusing it names two
    pieces of work — and a live task may legitimately depend on one that closed.
    Both facts stop being checkable the moment a ledger file is outside this
    list.

    A glob, not another named constant. `STUDY_WBS_FILE` was added by name when
    the Study feature took its own ledger, and it has been the only companion
    the guard knows about ever since; the next archive file must not need a
    code change to be seen.

    The archive lives outside `_docs_md()`'s three globs on purpose: a retired
    entry is not a contract document and should not have to carry the 7-field
    header or claim a source of truth.
    """
    paths = [WBS_FILE, STUDY_WBS_FILE]
    archive = _REPO / WBS_ARCHIVE_DIR
    if archive.is_dir():
        paths.extend(
            sorted(p.relative_to(_REPO).as_posix() for p in archive.glob("*.md"))
        )
    return [p for p in paths if (_REPO / p).is_file()]
```

- [ ] **Step 4: Use it in the three places that iterate ledgers**

In `_check_wbs_tasks()`, replace `for path in (WBS_FILE, STUDY_WBS_FILE):` in
the duplicate scan with `for path in _wbs_ledgers():`.

Replace the `task_set` construction:

```python
    task_set = set(task_ids) | {
        m.group(1)
        for line in _lines(STUDY_WBS_FILE)
        if (m := _TASK_HEAD_RE.match(line))
    }
```

with:

```python
    task_set = {
        m.group(1)
        for path in _wbs_ledgers()
        for line in _lines(path)
        if (m := _TASK_HEAD_RE.match(line))
    }
```

And in the heading-level loop added in Task 2, replace
`for path in (WBS_FILE, STUDY_WBS_FILE):` with `for path in _wbs_ledgers():`.

- [ ] **Step 5: Run the tests to verify they pass**

Run:
```bash
python -m unittest discover -s .claude/skills/flutter-workflow/scripts/tests -p 'test_*.py'
```
Expected: PASS, all suites.

- [ ] **Step 6: Fault-inject against the real tree**

```bash
mkdir -p docs/wbs-archive
printf '### M99.29 · duplicate probe\n' > docs/wbs-archive/_probe.md
python .claude/skills/flutter-workflow/scripts/check_docs.py --quiet; echo "exit=$?"
rm docs/wbs-archive/_probe.md
```

Expected: exit **non-zero**, naming `M99.29 is defined 2 times` and printing
both locations. If it exits 0, the glob is not wired into the duplicate scan
and Phase 2 is unsafe — stop and fix Step 4.

- [ ] **Step 7: Commit**

```bash
git add .claude/skills/flutter-workflow/scripts/check_docs.py \
        .claude/skills/flutter-workflow/scripts/tests/test_check_docs.py
git commit -m "feat(docs-guard): the ledger set is a glob, not two names

An id retired into an archive is still spent, and a live task may depend on
one that closed — so the duplicate rule and the dependency graph have to see
the archive. A glob rather than a third named constant: wbs-study.md was added
by name and became the only companion this guard would ever know about.

Fault-injected: an id duplicated into docs/wbs-archive/ fails the check.

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

### Task 5: Move the closed milestones out, one commit each

**Files:**
- Create: `docs/wbs-archive/t0-t1-m2-m3.md`, `m4.md`, `m5.md`, `m99.md`, `m100.md`
- Modify: `docs/wbs.md`

**Interfaces:**
- Consumes: `_wbs_ledgers()` (Task 4).
- Produces: five archive files. Task 6 writes the index over them.

**Five commits, not one.** Each is independently reviewable and revertable, and
a bad move in M99 should not force M4 to be re-reviewed.

- [ ] **Step 1: Write the archive file header (no 7-field contract needed)**

Each archive file opens with exactly this, with the milestone substituted:

```markdown
# WBS archive — M4

Closed entries moved out of `docs/wbs.md` on 2026-09-08 (M100.65). **Nothing
was edited on the way**: each entry is byte-identical to the one that left the
ledger, and the ids are still in `check_docs.py`'s duplicate scan and
dependency graph through `_wbs_ledgers()`.

This file is not a contract document and carries no 7-field header — it sits
outside `_docs_md()`'s globs deliberately. The living ledger is `../wbs.md`.

---
```

- [ ] **Step 2: Move T0/T1/M2/M3 — the smallest milestone first**

Cut every `### T0`, `### T1`, `### M2.x` and `### M3.x` entry whose Status
starts `done` from `docs/wbs.md` (29 entries, 1,379 lines) and paste them, in
document order, under the header into `docs/wbs-archive/t0-t1-m2-m3.md`.

Leave the `## M2 · Project foundation` and `## M3 · Architecture and design
foundation` section headings in `docs/wbs.md`, each now holding a single line:

```markdown
Mọi task của milestone này đã đóng — xem `wbs-archive/t0-t1-m2-m3.md`.
```

- [ ] **Step 3: Verify nothing was lost or altered**

```bash
python -X utf8 - <<'PY'
import subprocess, re
old = subprocess.run(['git', 'show', 'HEAD:docs/wbs.md'],
                     capture_output=True, text=True, encoding='utf-8').stdout
new = open('docs/wbs.md', encoding='utf-8').read()
arch = open('docs/wbs-archive/t0-t1-m2-m3.md', encoding='utf-8').read()
ids = lambda s: re.findall(r'^### ([TM][0-9][^\s]*) ', s, re.M)
before, after = set(ids(old)), set(ids(new)) | set(ids(arch))
print('lost:', sorted(before - after))
print('gained:', sorted(after - before))
PY
```

Expected: both lists empty. A non-empty `lost` means an entry was dropped in
the cut — restore it before continuing.

- [ ] **Step 4: Run the guard**

Run: `python .claude/skills/flutter-workflow/scripts/check_docs.py --quiet`
Expected: exit 0, still `no duplicate WBS task IDs (312 tasks)` — the count
must not move, because nothing was deleted.

- [ ] **Step 5: Commit**

```bash
git add docs/wbs.md docs/wbs-archive/t0-t1-m2-m3.md
git commit -m "docs(wbs): T0, T1, M2 and M3 retire to the archive (M100.65)

29 closed entries, 1,379 lines, byte-identical. Their ids stay in the
duplicate scan and the dependency graph through _wbs_ledgers().

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

- [ ] **Step 6: Repeat Steps 2–5 for M4**

83 entries, 4,854 lines → `docs/wbs-archive/m4.md`. **Three M4 entries stay in
`docs/wbs.md`:** `M4.5`, `M4.6` and `M4.7` are `descoped`, not `done`, and a
descope is a live decision a reader needs in the ledger. Commit message body:
`83 closed entries, 4,854 lines. M4.5/4.6/4.7 stay: descoped is a live
decision, not closed work.`

- [ ] **Step 7: Repeat Steps 2–5 for M5**

28 entries, 1,756 lines → `docs/wbs-archive/m5.md`. Note in the commit that
`docs/wbs-study.md` is untouched and remains a live ledger.

- [ ] **Step 8: Repeat Steps 2–5 for M99**

96 entries, 7,050 lines → `docs/wbs-archive/m99.md`. **Two M99 entries stay:**
`M99.29` (`in-progress` — the one genuinely live task in the file) and `M99.32`
(`integrated`, which is not `done`).

- [ ] **Step 9: Repeat Steps 2–5 for M100**

59 entries, 4,273 lines → `docs/wbs-archive/m100.md`. **Two M100 entries stay:**
`M100.27` (`superseded`) and `M100.61` (now `done` after Task 1 — move it, it
is closed). Re-count before cutting: Task 1 changed M100.61's status, so the
`done` count for M100 is 60, not 59, and one fewer entry stays behind.

- [ ] **Step 10: Rewrite the ledger's header and Progress summary**

`docs/wbs.md` is now roughly 600 lines. Update its 7-field header:

```markdown
| **Purpose** | Sổ tiến độ — nguồn duy nhất cho việc gì **đang** làm, bị chặn, hoặc đã descope. Việc đã đóng nằm ở `wbs-archive/` |
| **Scope** | Task đang mở · blocker · technical debt · quyết định descope/superseded. Ngoài phạm vi: entry đã `done` — chúng ở `wbs-archive/`, vẫn trong đồ thị dependency qua `_wbs_ledgers()` |
| **Updated by task** | M100.65 |
| **Last updated** | 2026-09-08 |
```

And replace the Progress summary with the real counts:

```markdown
## Progress summary

| | Sổ sống | Archive | Tổng |
|---|---|---|---|
| Entry | 7 | 295 | 302 |
| Dòng | ~600 | 19,312 | ~19,900 |

**Đang chạy: một task** — `M99.29`. Sáu entry còn lại ở sổ sống mang trạng thái
cuối (`descoped` ×3, `integrated`, `superseded`) và ở lại vì chúng là quyết
định người đọc cần thấy, không phải việc đã xong.
```

- [ ] **Step 11: Full verification, then commit**

```bash
python .claude/skills/flutter-workflow/scripts/check_docs.py --quiet && echo "docs OK"
python -m unittest discover -s .claude/skills/flutter-workflow/scripts/tests -p 'test_*.py'
wc -l docs/wbs.md docs/wbs-archive/*.md
git add docs/wbs.md
git commit -m "docs(wbs): the ledger states what it now holds (M100.65)

7 open entries, ~600 lines, one of them actually in progress. The header and
the Progress summary said neither.

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

### Task 6: The archive gets an index and the docs README learns it exists

**Files:**
- Create: `docs/wbs-archive/README.md`
- Modify: `docs/README.md` — the `## What exists` section

**Interfaces:**
- Consumes: the five archive files from Task 5.
- Produces: nothing later tasks depend on.

- [ ] **Step 1: Write the index**

`docs/wbs-archive/README.md`:

```markdown
# WBS archive

Closed WBS entries, moved out of `../wbs.md` on 2026-09-08 (M100.65) so the
living ledger holds only living work. **Nothing here was edited on the way
out** — each entry is byte-identical to the one that left.

These files are still policed. `check_docs.py`'s `_wbs_ledgers()` globs this
directory, so a retired id cannot be reused and a live task may depend on one
that closed. They are deliberately outside `_docs_md()`, so they carry no
7-field header and claim no source of truth: a retired entry is a record, not
a contract.

| File | Milestone | Entries | Lines |
|---|---|---|---|
| `t0-t1-m2-m3.md` | harness, project foundation, architecture foundation | 29 | 1,379 |
| `m4.md` | router and Drift foundation, deck and card slices | 83 | 4,854 |
| `m5.md` | study vertical slice — UC-05 | 28 | 1,756 |
| `m99.md` | adhoc feature and hardening work | 96 | 7,050 |
| `m100.md` | design-system reconciliation and screen consistency | 60 | 4,273 |

**Where to look for what.** A task id tells you the file: `M4.10ap` is in
`m4.md`, `M99.62` in `m99.md`. To find every mention of a task across both the
ledger and the archive:

```bash
grep -rn "M99\.62" docs/wbs.md docs/wbs-archive/
```
```

Fill the Entries and Lines columns from the actual result of Task 5:

```bash
for f in docs/wbs-archive/*.md; do
  printf "%-24s %3d entries %6d lines\n" "$(basename "$f")" \
    "$(grep -c '^### [TM][0-9]' "$f")" "$(wc -l < "$f")"
done
```

- [ ] **Step 2: Add both archives to the docs index**

In `docs/README.md`, inside `## What exists`, add:

```markdown
- `wbs-archive/` — entry WBS đã đóng, tách khỏi `wbs.md` ở M100.65. Vẫn nằm
  trong kiểm trùng ID và đồ thị dependency; xem `wbs-archive/README.md`.
```

**Do not add it to `## Not written yet`** — `_check_not_written_yet()` fails
for any `` `name.md` `` listed there whose file exists.

- [ ] **Step 3: Verify**

Run: `python .claude/skills/flutter-workflow/scripts/check_docs.py --quiet`
Expected: exit 0.

- [ ] **Step 4: Commit**

```bash
git add docs/wbs-archive/README.md docs/README.md
git commit -m "docs(wbs): the archive says what is in it and why it is still guarded

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

## Phase 3 — Closed audits leave the working set

One task. `docs/reviews/` is 26 files and 24,221 lines — 34% of all doc lines,
the largest group after `wbs.md`. It is **outside** every glob in
`check_docs.py`, so this phase has no guard surface at all and is the cheapest
line reduction in the plan.

### Task 7: Retire the audits whose findings are already code

**Files:**
- Create: `docs/reviews/archive/README.md`
- Modify: `docs/README.md`
- Move: audit files into `docs/reviews/archive/`

**Interfaces:**
- Consumes: nothing.
- Produces: nothing.

- [ ] **Step 1: Classify every review by whether it is still consulted**

```bash
for f in docs/reviews/*.md; do
  n=$(basename "$f" .md)
  hits=$(grep -rl "$n" docs lib test .claude CLAUDE.md 2>/dev/null | grep -v "^docs/reviews/$n.md$" | wc -l)
  printf "%-46s %5d lines  cited by %2d files\n" "$n" "$(wc -l < "$f")" "$hits"
done | sort -k2 -rn
```

An audit cited by nothing but itself is a candidate. An audit cited from
`CLAUDE.md`, a skill, or `docs/design-system/v1-freeze.md` is **not** — those
are load-bearing. Record the classification in the index (Step 3); do not move
anything on a hunch.

- [ ] **Step 2: Move the uncited audits with `git mv`**

```bash
mkdir -p docs/reviews/archive
git mv docs/reviews/<name>.md docs/reviews/archive/<name>.md
```

`git mv`, not `cp` + `rm`: it keeps the rename in history so `git log
--follow` still reaches the original. Move one file per command so a mistake
is one `git mv` back.

- [ ] **Step 3: Write the index**

`docs/reviews/archive/README.md`:

```markdown
# Review archive

Audits whose findings have landed and which nothing in the working tree cites
any more. Moved 2026-09-08 (M100.66). Nothing was edited or deleted.

An audit leaves this directory the moment something needs it again — the test
is citation, not age. `docs/reviews/` keeps every audit still referenced by
`CLAUDE.md`, by a skill, or by a design-system contract.

| Audit | Subject | Closed by | Lines |
|---|---|---|---|
| `a7-icon-actions-menu-audit.md` | icon actions and overflow menus | … | 734 |
```

One row per moved file, with the task or PR that consumed its findings taken
from the audit's own header. Where the audit does not say, write `—` rather
than guessing.

- [ ] **Step 4: Verify no link broke**

```bash
grep -rn "docs/reviews/" docs lib test .claude CLAUDE.md 2>/dev/null \
  | grep -v "docs/reviews/archive/" \
  | while IFS=: read -r f n rest; do
      for p in $(echo "$rest" | grep -oE 'docs/reviews/[a-z0-9.-]+\.md'); do
        [ -f "$p" ] || echo "BROKEN $f:$n -> $p"
      done
    done
```

Expected: no output. Any `BROKEN` line means a moved file is still linked —
either move it back or update the link.

- [ ] **Step 5: Run the guard and commit**

```bash
python .claude/skills/flutter-workflow/scripts/check_docs.py --quiet && echo OK
git add -A docs/reviews docs/README.md
git commit -m "docs(reviews): audits nothing cites move to an archive (M100.66)

The test is citation, not age: an audit still referenced by CLAUDE.md, a skill
or a design-system contract stays in the working set. git mv, so --follow
still reaches the original.

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

## Phase 4 — The three frozen contracts

**Read this before starting Phase 4.** You asked for these in scope and the
plan delivers them, but the measurement does not support splitting them, and
saying so is part of the work:

- `business-rules.md` is **1,218 lines**, `architecture.md` **1,821**,
  `use-cases.md` **1,587**. Together they are 4,626 lines — **less than a
  quarter of `wbs.md` alone**, and Phases 2 and 3 already remove 43,533 lines
  between them.
- All three are `frozen for MVP`. CLAUDE.md: a task must not edit one unless
  the task names it, and the reason is that they are the contract the code is
  written against.
- All three are parsed by name: `BR_FILE`, `AD_FILE`, `UC_FILE` feed
  `_check_document_integrity`, `_check_br_rows`, `_check_section_br`,
  `_check_uc_sections`, `_check_ad_sections`. Splitting them means teaching
  five more guard functions to glob, each with its own fault injection.
- **14,789 citations** resolve against those five functions. A mistake here is
  not a messy diff; it is every BR/AD/UC reference in the repository going
  dangling at once.

**Recommendation: do Task 8 and stop.** It is the part of Phase 4 that is
worth doing on the measurement — it takes the three genuinely oversized
sections out without changing how any ID resolves. Task 9 is written out in
full because you asked for it; run it only if Task 8 leaves you still wanting
the split.

### Task 8: Extract the three oversized architecture sections

**Files:**
- Modify: `docs/architecture.md` — AD-14 (313 lines), AD-13 (154), AD-12 (95)
- Create: `docs/design-system/ad-14-color-and-depth.md`

**Interfaces:**
- Consumes: nothing.
- Produces: nothing. IDs do not move — only prose does.

**Why this is safe where Task 9 is not:** `_defined_ids(AD_FILE, "AD")` matches
`^(\| |#{2,4} )(AD-[0-9]+)`. The heading `## AD-14 · …` stays in
`architecture.md`; only the *body* under it moves, replaced by a pointer. Every
guard function still finds AD-14 exactly where it looks.

- [ ] **Step 1: Measure the three sections**

```bash
python -X utf8 - <<'PY'
import io, re
lines = io.open('docs/architecture.md', encoding='utf-8').read().split('\n')
h = [(i, l) for i, l in enumerate(lines) if l.startswith('## ')]
for k, (i, l) in enumerate(h):
    end = h[k+1][0] if k+1 < len(h) else len(lines)
    if end - i > 90:
        print(f'{end-i:5d}  line {i+1:5d}  {l[:70]}')
PY
```

Expected: `AD-14` at 313 lines, `AD-13` at 154, `AD-12` at 95. If the numbers
differ, the file has moved since measurement — use what the command prints.

- [ ] **Step 2: Move AD-14's body into the design-system tree**

Create `docs/design-system/ad-14-color-and-depth.md` with the 7-field header
(it lands inside `_docs_md()`'s `docs/design-system/*.md` glob, so the header
is mandatory):

```markdown
# AD-14 · Hệ màu và chiều sâu: seed, role, và cue theo mode

| | |
|---|---|
| **Status** | frozen for MVP |
| **Purpose** | Giữ toàn văn lý luận của AD-14, tách khỏi `architecture.md` để file đó đọc được |
| **Scope** | Seed, 45 role của `ColorScheme`, cue chiều sâu theo mode. Ngoài phạm vi: quyết định AD khác, giá trị token cụ thể |
| **Source of truth for** | Lý luận đầy đủ của AD-14 — quyết định vẫn được tuyên bố ở `../architecture.md` |
| **Depends on** | `../architecture.md` · `../document-conventions.md` |
| **Updated by task** | M100.67 |
| **Last updated** | 2026-09-08 |

<toàn bộ phần thân AD-14, nguyên văn>
```

`Source of truth for` must **not** repeat a topic `architecture.md` already
claims — `_check_document_contract` fails when two documents claim one topic.
The wording above says "lý luận đầy đủ của AD-14", which `architecture.md` does
not claim.

- [ ] **Step 3: Leave the decision in place, pointing at the reasoning**

In `docs/architecture.md`, `## AD-14 · …` keeps its heading and its first
paragraph — the decision itself — and gains:

```markdown
> Lý luận đầy đủ, các phương án bị loại và số đo: `design-system/ad-14-color-and-depth.md`.
```

- [ ] **Step 4: Verify no citation broke and no topic is claimed twice**

Run: `python .claude/skills/flutter-workflow/scripts/check_docs.py --quiet`
Expected: exit 0, including
`every cited BR / AD / UC id resolves (315 distinct ids)` — the count must not
change, and
`no topic is claimed as source of truth by two documents`.

- [ ] **Step 5: Commit**

```bash
git add docs/architecture.md docs/design-system/ad-14-color-and-depth.md
git commit -m "docs(architecture): AD-14's reasoning moves; its decision stays (M100.67)

313 of architecture.md's 1,821 lines were one AD. The heading and the decision
stay where every guard function and every citation looks for them; only the
reasoning moves.

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

- [ ] **Step 6: Repeat Steps 2–5 for AD-13 and AD-12 only if the file still reads long**

Re-run Step 1. `architecture.md` is now ~1,500 lines. If that is short enough,
stop — moving two more sections costs two more files for 249 lines.

### Task 9: Split the three frozen documents (run only if Task 8 was not enough)

**Files:**
- Modify: `.claude/skills/flutter-workflow/scripts/check_docs.py` — `_defined_ids` and five check functions
- Modify: `.claude/skills/flutter-workflow/scripts/tests/test_check_docs.py`
- Create: `docs/business-rules/*.md`, `docs/architecture/*.md`, `docs/use-cases/*.md`

**Interfaces:**
- Consumes: `_wbs_ledgers()` as the pattern to copy (Task 4).
- Produces: `_contract_files(kind: str) -> list[str]` where `kind` is `"BR"`,
  `"AD"` or `"UC"`.

- [ ] **Step 1: Write the failing test**

Append to `test_check_docs.py`:

```python
class ContractFileSetTest(unittest.TestCase):
    """A split contract is still one definition set."""

    def test_the_root_file_is_always_in_the_set(self) -> None:
        self.assertIn("docs/business-rules.md", check_docs._contract_files("BR"))

    def test_a_part_file_joins_without_a_code_change(self) -> None:
        import tempfile, pathlib
        with tempfile.TemporaryDirectory() as tmp:
            root = pathlib.Path(tmp)
            (root / "docs" / "business-rules").mkdir(parents=True)
            (root / "docs" / "business-rules.md").write_text("# x", encoding="utf-8")
            (root / "docs" / "business-rules" / "deck.md").write_text(
                "| BR-01 | active |", encoding="utf-8"
            )
            original = check_docs._REPO
            try:
                check_docs._REPO = root
                files = check_docs._contract_files("BR")
                self.assertIn("docs/business-rules/deck.md", files)
            finally:
                check_docs._REPO = original
```

- [ ] **Step 2: Run it to verify it fails**

Run:
```bash
python -m unittest discover -s .claude/skills/flutter-workflow/scripts/tests -p 'test_check_docs.py'
```
Expected: FAIL — `AttributeError: module 'check_docs' has no attribute '_contract_files'`.

- [ ] **Step 3: Add the contract-file glob**

After `_DEF_RE` in `check_docs.py`:

```python
_CONTRACT_ROOT = {"BR": BR_FILE, "AD": AD_FILE, "UC": UC_FILE}


def _contract_files(kind: str) -> list[str]:
    """The root contract document plus its part files.

    Same shape as `_wbs_ledgers`, same reason: a definition set that lives in
    more than one file is only checkable when the guard sees all of it. The
    part directory takes the root's stem — `docs/business-rules/` beside
    `docs/business-rules.md` — so the pairing needs no table.

    Part files land inside `_docs_md()` only if they sit directly under
    `docs/`; these sit one level down, so they inherit no header contract. The
    root keeps the header, and it keeps `Source of truth for`.
    """
    root = _CONTRACT_ROOT[kind]
    files = [root]
    part_dir = _REPO / root[: -len(".md")]
    if part_dir.is_dir():
        files.extend(
            sorted(p.relative_to(_REPO).as_posix() for p in part_dir.glob("*.md"))
        )
    return [f for f in files if (_REPO / f).is_file()]
```

- [ ] **Step 4: Route `_defined_ids` through it**

Replace `_defined_ids(path, prefix)` with a set-aware version:

```python
def _defined_ids(kind: str) -> list[str]:
    """Table rows `| BR-07` and headings `### BR-15 ·`, in document order."""
    pat = _DEF_RE[kind]
    ids: list[str] = []
    for path in _contract_files(kind):
        for line in _lines(path):
            if (m := pat.match(line)):
                ids.append(m.group(2))
    return ids
```

Update its three callers in `_check_document_integrity` from
`_defined_ids(BR_FILE, "BR")` to `_defined_ids("BR")`, and likewise for AD and
UC. Then update `_check_br_rows`, `_check_section_br`, `_check_uc_sections`
and `_check_ad_sections` to iterate `_contract_files(...)` instead of reading
one path.

- [ ] **Step 5: Run the tests and the guard against the unsplit tree**

```bash
python -m unittest discover -s .claude/skills/flutter-workflow/scripts/tests -p 'test_*.py'
python .claude/skills/flutter-workflow/scripts/check_docs.py --quiet; echo "exit=$?"
```

Expected: tests PASS, guard exit 0, and the integrity line still reads
`every cited BR / AD / UC id resolves (315 distinct ids)`. **The count is the
proof**: the refactor is complete only if it changes nothing before any file
moves.

- [ ] **Step 6: Fault-inject**

```bash
mkdir -p docs/business-rules
printf '| BR-01 | active | probe | x | y |\n' > docs/business-rules/_probe.md
python .claude/skills/flutter-workflow/scripts/check_docs.py --quiet; echo "exit=$?"
rm -r docs/business-rules
```

Expected: exit non-zero, `BR-01 defined more than once`. If it exits 0, the
glob is not reaching the duplicate check.

- [ ] **Step 7: Commit the guard refactor alone, before any content moves**

```bash
git add .claude/skills/flutter-workflow/scripts/check_docs.py \
        .claude/skills/flutter-workflow/scripts/tests/test_check_docs.py
git commit -m "feat(docs-guard): a contract's definition set may span files

_defined_ids read one hardcoded path per kind, so splitting business-rules.md
would have made all 14,789 BR/AD/UC citations dangle at once. Same shape as
_wbs_ledgers: the part directory takes the root's stem.

No file has moved yet, and the id count is unchanged at 315 — which is what
makes this commit reviewable on its own.

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

- [ ] **Step 8: Move one BR section and stop to check**

Move exactly one `##` section of `docs/business-rules.md` — start with
`## StudyMode` (lines 617-683, 67 lines) — into
`docs/business-rules/study-mode.md`, keeping the table's header row:

```markdown
# BR — StudyMode

Tách khỏi `../business-rules.md` ở M100.68. Trạng thái, cách đánh số và quyền
sở hữu không đổi: `../business-rules.md` vẫn là `Source of truth for` của
business rules, và `check_docs.py` đọc cả hai qua `_contract_files("BR")`.

| ID | Status | Rule | Enforced by | Related |
|---|---|---|---|---|
| BR-… | … | … | … | … |
```

In `docs/business-rules.md`, the `## StudyMode` heading stays with a pointer
line beneath it, so a reader scanning the contract still finds the topic.

- [ ] **Step 9: Verify, then decide whether to continue**

Run: `python .claude/skills/flutter-workflow/scripts/check_docs.py --quiet`
Expected: exit 0, still 315 distinct ids, and
`no numbering gap in BR` unchanged.

Then measure the result before moving a second section:

```bash
wc -l docs/business-rules.md docs/business-rules/*.md
```

One section removed 67 of 1,218 lines. **Continue only if that ratio is worth
24 more moves.** If it is not, revert this step and keep the guard refactor —
it is useful on its own and costs nothing.

- [ ] **Step 10: Commit**

```bash
git add docs/business-rules.md docs/business-rules/
git commit -m "docs(business-rules): StudyMode's rules move to a part file (M100.68)

One section, as a probe. The guard's id count is unchanged at 315, which is
the only evidence that a split contract is still one contract.

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

## Not in the scope you chose — measured after you answered

`docs/prompt/` is **108 files in 36 directories, 8,848 lines**: 12% of the doc
lines but **59% of the doc files**. Every directory is a three-file executable
prompt set for a feature that has shipped. `check_prompt_contract.py` validates
them and CI runs it only when `has_prompt_changes` is true, so an archive
directory would need the same glob treatment as Phase 2.

It is the largest remaining reduction in *file count*, and file count is what
makes a tree hard to navigate. It is listed here rather than planned because
you did not choose it — say the word and it becomes Phase 5, shaped exactly
like Phase 3.

---

## Expected result

| | Before | After Phases 0–3 | After Phase 4 (Task 8 only) |
|---|---|---|---|
| `docs/wbs.md` | 19,856 lines | ~600 | ~600 |
| `docs/reviews/` working set | 24,221 lines | depends on Step 1's classification | same |
| `docs/architecture.md` | 1,821 lines | 1,821 | ~1,508 |
| Task headings the guard sees | 282 / 312 | 312 / 312 | 312 / 312 |
| Duplicate task IDs | 3, unreported | 0 | 0 |
| BR/AD/UC ids resolving | 315 | 315 | 315 |
| Nothing deleted | — | ✓ | ✓ |

---

## Self-review

**Spec coverage.** Every item you selected has a task: `docs/wbs.md` + guard →
Tasks 2–6; `docs/reviews/` → Task 7; `business-rules.md` → Task 9 Steps 8–10;
`architecture.md` + `use-cases.md` → Task 8 and Task 9. The three duplicate IDs
→ Task 3, renumbering the `##` copies as you chose. Archive-by-milestone with
content intact → Task 5.

**Placeholder scan.** Two places carry a deliberate `…`: the review-archive
index table (Task 7 Step 3) and the BR part-file table (Task 9 Step 8). Both
are filled from a command given in the same step, because their content is the
output of the classification the step performs — writing rows here would be
inventing them.

**Type consistency.** `_wbs_ledgers()` (Task 4) and `_contract_files(kind)`
(Task 9) are the only new functions; both are defined before first use, both
return `list[str]` of repo-relative POSIX paths, and Task 9's docstring names
Task 4's function as the pattern it copies. `_wrong_level_task_headings`
(Task 2) is called in Task 2 Step 5 and re-pointed at `_wbs_ledgers()` in
Task 4 Step 4 — the only signature that changes across tasks, and the change is
stated in both places.
