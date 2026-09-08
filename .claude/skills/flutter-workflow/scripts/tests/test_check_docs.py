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


class DependencyGraphSpansAllLedgersTest(unittest.TestCase):
    """The dependency graph must read every ledger, not just docs/wbs.md.

    `_wbs_ledgers()` was widened to cover the archive so a retired id stays
    inside the duplicate check and the dependency graph — both halves of one
    property. It is easy to widen only the id set and leave the edge-collection
    loop reading a single file; that leaves every dependency line inside the
    archive uninspected while the checker still prints success.
    """

    def test_a_bad_dependency_inside_the_archive_is_caught(self) -> None:
        import contextlib
        import io
        import pathlib
        import tempfile

        with tempfile.TemporaryDirectory() as tmp:
            root = pathlib.Path(tmp)
            (root / "docs" / "wbs-archive").mkdir(parents=True)
            (root / "docs" / "wbs.md").write_text(
                "### M1.1 · Task A\n\n- **Status:** done\n",
                encoding="utf-8",
            )
            # M9.9's dependency on M2.2 is unresolvable — M2.2 is defined
            # nowhere. This line lives only in the archive, so a loop that
            # reads only docs/wbs.md can never see it.
            (root / "docs" / "wbs-archive" / "x.md").write_text(
                "### M9.9 · Task B\n\n"
                "- **Status:** done\n"
                "- **Dependencies:** M1.1, M2.2\n",
                encoding="utf-8",
            )

            original_repo = check_docs._REPO
            original_problems = check_docs._problems
            check_docs._read.cache_clear()
            check_docs._lines.cache_clear()
            try:
                check_docs._REPO = root
                check_docs._problems = 0
                buf = io.StringIO()
                with contextlib.redirect_stdout(buf):
                    check_docs._check_wbs_tasks()
                output = buf.getvalue()
            finally:
                check_docs._REPO = original_repo
                check_docs._problems = original_problems
                check_docs._read.cache_clear()
                check_docs._lines.cache_clear()

            self.assertIn("M9.9", output)
            self.assertIn("M2.2", output)
            self.assertIn("does not exist", output)
            # The failure must name the archive file the edge came from —
            # otherwise a reader is sent looking in docs/wbs.md.
            self.assertIn("docs/wbs-archive/x.md", output)


if __name__ == "__main__":
    unittest.main()
