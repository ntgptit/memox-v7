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
