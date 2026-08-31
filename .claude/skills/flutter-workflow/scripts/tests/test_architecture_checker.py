"""Fault-injection fixtures for `check_architecture.py`.

**The debt this pays was recorded at T0.1 and is the oldest open row in the
ledger:** *"`check_architecture.sh` chưa có test tự động — regression trong
checker âm thầm ngừng enforce boundary"*. A guard nobody tests is a guard that
can stop finding anything and still print a tick, which is worse than no guard
because the tick is believed.

The mitigation added at M4.10b — the checker prints how many files it scanned
and treats zero as a failure — closes the worst case, where the guard sees
nothing at all. It does not close the case this file is for: the guard scanning
everything and *recognising* nothing.

So each test builds a throwaway project, plants exactly one violation of a
named rule, and asserts the checker fails and says which rule. The clean
fixture proves the same tree passes without the plant, which is what makes each
failure attributable to the plant rather than to the fixture.

The checker resolves its root through `git rev-parse` and falls back to the
working directory; a temp dir outside any repository takes that fallback, which
is why these run there rather than inside this one.
"""

from __future__ import annotations

import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

SCRIPTS = Path(__file__).resolve().parents[1]
CHECKER = (
    SCRIPTS.parents[1] / "flutter-architecture" / "scripts" / "check_architecture.py"
)


class ArchitectureCheckerFixtureTest(unittest.TestCase):
    """One planted violation at a time, against a project that otherwise passes."""

    def _project(self, root: Path) -> None:
        """A minimal tree the checker accepts: pubspec, one feature, all layers
        named the way the rules require."""
        (root / "pubspec.yaml").write_text("name: fixture\n", encoding="utf-8")

        entities = root / "lib" / "features" / "deck" / "domain" / "entities"
        entities.mkdir(parents=True)
        (entities / "deck_entity.dart").write_text(
            "class DeckEntity {\n  const DeckEntity();\n}\n", encoding="utf-8"
        )

        repos = root / "lib" / "features" / "deck" / "data" / "repositories"
        repos.mkdir(parents=True)
        (repos / "deck_repository_impl.dart").write_text(
            "import '../../domain/entities/deck_entity.dart';\n\n"
            "class DeckRepositoryImpl {\n  const DeckRepositoryImpl();\n}\n",
            encoding="utf-8",
        )

        # `presentation/` and `di/` exist because the checker refuses a layer
        # that matches nothing — "every rule scoped to it passed without
        # inspecting anything" is its own wording. A fixture missing a layer
        # fails for that reason instead of the planted one, which is exactly
        # the unattributable failure the clean case below rules out.
        screens = root / "lib" / "features" / "deck" / "presentation" / "screens"
        screens.mkdir(parents=True)
        (screens / "deck_list_screen.dart").write_text(
            "import 'package:flutter/material.dart';\n\n"
            "class DeckListScreen extends StatelessWidget {\n"
            "  const DeckListScreen({super.key});\n\n"
            "  @override\n"
            "  Widget build(BuildContext context) => const SizedBox.shrink();\n"
            "}\n",
            encoding="utf-8",
        )

        di = root / "lib" / "features" / "deck" / "di"
        di.mkdir(parents=True)
        (di / "deck_repository_provider.dart").write_text(
            "class DeckRepositoryProvider {\n"
            "  const DeckRepositoryProvider();\n"
            "}\n",
            encoding="utf-8",
        )

    def _run(self, root: Path) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            [sys.executable, str(CHECKER)],
            cwd=root,
            capture_output=True,
            text=True,
            check=False,
        )

    def test_checker_exists_where_every_caller_names_it(self) -> None:
        # The wrapper, the docs and `dod_check.sh` all name this path. If it
        # moves, the tests below would pass by never running the real thing.
        self.assertTrue(CHECKER.is_file(), f"checker missing at {CHECKER}")

    def test_a_clean_project_passes(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self._project(root)

            result = self._run(root)

            self.assertEqual(
                result.returncode,
                0,
                msg=(
                    "the fixture itself is not clean, so every failure below "
                    f"would be unattributable.\n{result.stdout}\n{result.stderr}"
                ),
            )

    def test_a_domain_file_importing_flutter_is_caught(self) -> None:
        # The rule that matters most: `domain/` imports no Flutter. If this one
        # ever stops firing, the layering is unenforced and nothing says so.
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self._project(root)
            entity = (
                root
                / "lib"
                / "features"
                / "deck"
                / "domain"
                / "entities"
                / "deck_entity.dart"
            )
            entity.write_text(
                "import 'package:flutter/material.dart';\n\n"
                "class DeckEntity {\n  const DeckEntity();\n}\n",
                encoding="utf-8",
            )

            result = self._run(root)

            self.assertEqual(
                result.returncode,
                1,
                msg=f"a domain file imported Flutter and the checker was happy.\n{result.stdout}",
            )
            self.assertIn("deck_entity.dart", result.stdout + result.stderr)

    def test_a_missing_suffix_is_reported_as_a_warning_not_a_failure(self) -> None:
        # The folder does not replace the suffix — `entities/deck.dart` drops
        # the file out of the scopes several other rules select by name, so a
        # checker that stops naming it silently narrows every rule after it.
        #
        # **It warns rather than fails, and that is the checker's own design.**
        # `_check_suffixes` and `_check_file_sizes` both call `_warn`, which
        # prints without touching the violation count; only `_check_imports`
        # and the zero-scope guard call `_fail`. The first draft of this test
        # asserted exit 1 and was wrong about the tool rather than about the
        # code — the same mistake, four times in this run, of asserting what a
        # contract ought to say instead of measuring what it does.
        #
        # Pinned in both directions on purpose: if the suffix rule is ever
        # promoted to a failure this test goes red and the promotion has to be
        # deliberate, and if it stops printing at all this test goes red too.
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self._project(root)
            entities = root / "lib" / "features" / "deck" / "domain" / "entities"
            (entities / "deck_entity.dart").rename(entities / "deck.dart")

            result = self._run(root)
            output = result.stdout + result.stderr

            self.assertIn(
                "deck.dart",
                output,
                msg=f"the suffix rule stopped naming the file.\n{output}",
            )
            self.assertIn("_entity.dart", output, msg="the rule stopped saying what it wanted")
            self.assertEqual(
                result.returncode,
                0,
                msg=(
                    "the suffix rule became a failure. If that was deliberate, "
                    f"flip this assertion; if not, something else broke.\n{output}"
                ),
            )

    def test_a_project_with_no_lib_but_a_pubspec_fails(self) -> None:
        # The M4.10b mitigation, pinned: a skip before the project exists is
        # honest, a skip after it exists is the checker reporting success for
        # having looked at nothing.
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / "pubspec.yaml").write_text("name: fixture\n", encoding="utf-8")

            result = self._run(root)

            self.assertEqual(
                result.returncode,
                1,
                msg="pubspec without lib/ should be a failure, not a skip",
            )


if __name__ == "__main__":
    unittest.main()
