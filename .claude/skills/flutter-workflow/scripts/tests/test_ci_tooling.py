from __future__ import annotations

import dataclasses
import importlib.util
import json
import os
import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


SCRIPTS = Path(__file__).resolve().parents[1]
REPO_ROOT = SCRIPTS.parents[3]


def _load(name: str):
    spec = importlib.util.spec_from_file_location(name, SCRIPTS / f"{name}.py")
    assert spec and spec.loader
    module = importlib.util.module_from_spec(spec)
    sys.modules[name] = module
    spec.loader.exec_module(module)
    return module


def _find_bash() -> str | None:
    """Git Bash, not WSL's — see DodCheckStampTest._bash."""
    shell = os.environ.get("SHELL", "")
    if shell.endswith(("bash", "bash.exe")) and Path(shell).exists():
        return shell
    git = shutil.which("git")
    if git:
        candidate = Path(git).parents[1] / "bin" / "bash.exe"
        if candidate.exists():
            return str(candidate)
    found = shutil.which("bash")
    return found if found and "System32" not in found else None


_BASH = _find_bash()


class DodCheckStampTest(unittest.TestCase):
    """The pass stamp: run twice on an unchanged tree, pay once.

    Running the gate again before commit, again before push and again before the
    PR is one tree state asked three times. The stamp exists so the repetition
    costs ~0.4s instead of 50-150s — and so it works without anyone having to
    remember, which is the part that failed every time it was written down.
    """

    SCRIPT = REPO_ROOT / ".claude/skills/flutter-workflow/scripts/dod_check.sh"
    STAMP = REPO_ROOT / ".dart_tool/dod_check_stamp"

    @staticmethod
    def _bash() -> str | None:
        """Git Bash, not WSL's.

        On Windows `shutil.which("bash")` finds `System32/bash.exe`, the WSL
        launcher, which cannot see the repository's drive path and fails with
        `execvpe(/bin/bash)`. The shell this project's scripts are written for
        ships beside git.
        """
        shell = os.environ.get("SHELL", "")
        if shell.endswith(("bash", "bash.exe")) and Path(shell).exists():
            return shell
        git = shutil.which("git")
        if git:
            candidate = Path(git).parents[1] / "bin" / "bash.exe"
            if candidate.exists():
                return str(candidate)
        found = shutil.which("bash")
        if found and "System32" not in found:
            return found
        return None

    def setUp(self) -> None:
        self._saved = self.STAMP.read_bytes() if self.STAMP.exists() else None
        self.STAMP.parent.mkdir(parents=True, exist_ok=True)

    def tearDown(self) -> None:
        if self._saved is None:
            self.STAMP.unlink(missing_ok=True)
        else:
            self.STAMP.write_bytes(self._saved)

    def _fingerprint(self) -> str:
        """Asked of the script, not recomputed here — a second definition would
        match the first only until one of them changed."""
        out = subprocess.run(
            [self._bash(), str(self.SCRIPT)],
            cwd=REPO_ROOT, capture_output=True, text=True,
            env={**os.environ, "PRINT_FINGERPRINT": "1"},
        )
        self.assertEqual(0, out.returncode, out.stderr)
        return out.stdout.strip()

    def _decide(self, *args: str) -> str:
        """Ask which way the stamp decides — never let the gate start.

        An earlier version of this test ran the script for real and killed it on
        a timeout. Killing the shell orphans `flutter test`, so the suite hung
        for seven minutes with the whole gate running behind it. The script
        answers the question directly now.
        """
        out = subprocess.run(
            [_BASH, str(self.SCRIPT), *args], cwd=REPO_ROOT,
            capture_output=True, text=True, timeout=60,
            env={**os.environ, "STAMP_DECISION_ONLY": "1"},
        )
        self.assertEqual(0, out.returncode, out.stderr)
        return out.stdout.strip()

    def _write_stamp(self, mode: str) -> None:
        self.STAMP.write_text(
            f"{mode}\t{self._fingerprint()}\t2026-01-01T00:00:00Z\n",
            encoding="utf-8",
        )

    @unittest.skipUnless(_BASH, "needs Git Bash")
    def test_an_unchanged_tree_is_not_verified_twice(self) -> None:
        self._write_stamp("full")
        self.assertEqual("reuse", self._decide())

    @unittest.skipUnless(_BASH, "needs Git Bash")
    def test_a_full_pass_answers_for_the_narrower_modes(self) -> None:
        """`full` is a superset of both, and this is the case that saves the
        most: the habit is to run the whole gate and then run a narrower one."""
        self._write_stamp("full")
        for args in (("--fast",), ("--changed",)):
            with self.subTest(args=args):
                self.assertEqual("reuse", self._decide(*args))

    @unittest.skipUnless(_BASH, "needs Git Bash")
    def test_a_narrow_pass_never_answers_for_the_full_gate(self) -> None:
        """The safety property. `--fast` runs the Deck + app subset; letting it
        stamp the full gate would turn a shortcut into a false clean bill."""
        self._write_stamp("fast")
        self.assertEqual("run", self._decide())

    @unittest.skipUnless(_BASH, "needs Git Bash")
    def test_force_ignores_a_valid_stamp(self) -> None:
        self._write_stamp("full")
        self.assertEqual("run", self._decide("--force"))


class VerificationPlanBuilderTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.module = _load("build_verification_plan")

    def _plan(self, *paths: str, force_full: bool = False):
        return self.module.build_plan(
            paths,
            root=REPO_ROOT,
            force_full=force_full,
        )

    def test_a_shared_widget_change_selects_the_golden_job(self) -> None:
        """#337's shape: six components relaid out, no picture redrawn.

        It passed every check in `ci.yml` because nothing there compares a
        committed PNG against a fresh render — the Windows golden job lives in
        `ci-full.yml`, which is `workflow_dispatch:` only. 26 goldens went
        stale on `main` and the screen gallery published a pre-#337 app.
        """
        plan = self._plan("lib/shared/widgets/mx_button_pair.dart")
        self.assertTrue(plan.needs_goldens)

    def test_a_change_to_the_pictures_themselves_selects_the_golden_job(self) -> None:
        """A PR that only regenerates goldens is the one whose claim needs
        checking most — and a PNG is not code, so `code_required` misses it."""
        plan = self._plan("test/demo/goldens/deck_list_empty_light.png")
        self.assertTrue(plan.needs_goldens)

    def test_a_demo_test_change_selects_the_golden_job(self) -> None:
        plan = self._plan("test/demo/deck_screens_demo_test.dart")
        self.assertTrue(plan.needs_goldens)

    def test_regenerating_pictures_runs_the_golden_job_and_nothing_else(self) -> None:
        """The shape of a golden-regeneration PR, which is the common one.

        Measured before this was classified: two of the last forty commits on
        `main` were exactly this — 26 and 31 PNGs, no Dart — and each ran five
        host shards, `flutter analyze` and the Widgetbook smoke test. A PNG can
        fail none of them. It was not a decision: `require_test_path` claims a
        code change first thing, then finds no rule for `.png` and falls
        through to `require_full("unrecognised test support path")`.
        """
        plan = self._plan(
            "test/demo/goldens/deck_list_empty_light.png",
            "test/demo/goldens/card_list_dark.png",
        )
        self.assertTrue(plan.needs_goldens)
        # The assertions that would have caught it: everything the pictures
        # cannot affect.
        self.assertFalse(plan.full_suite)
        self.assertFalse(plan.needs_static)
        self.assertFalse(plan.needs_host_tests)
        self.assertFalse(plan.needs_widgetbook)
        self.assertEqual(0, plan.shard_count)
        self.assertEqual("pixels", plan.risk)

    def test_a_picture_beside_its_widget_still_verifies_the_widget(self) -> None:
        """The narrowing must not survive contact with a real code change."""
        plan = self._plan(
            "test/demo/goldens/card_list_light.png",
            "lib/features/card/presentation/widgets/items/card_tile_widget.dart",
        )
        self.assertTrue(plan.needs_static)
        self.assertTrue(plan.needs_host_tests)
        self.assertTrue(plan.needs_goldens)

    def test_repository_furniture_verifies_nothing(self) -> None:
        """`.gitignore` and an issue template were selecting the whole suite.

        Both reached `require_full` — the first as an unclassified path, the
        second because `.github/` is a full-scope prefix and a markdown
        template is not a pipeline. One paragraph cost 1847s of runner time.
        """
        for path in (
            ".gitignore",
            ".editorconfig",
            ".vscode/settings.json",
            ".github/ISSUE_TEMPLATE/bug.md",
        ):
            with self.subTest(path=path):
                plan = self._plan(path)
                self.assertFalse(plan.full_suite)
                self.assertFalse(plan.needs_static)
                self.assertFalse(plan.needs_goldens)
                self.assertFalse(plan.needs_host_tests)

    def test_the_workflow_itself_still_runs_everything(self) -> None:
        """Not an oversight left in place — the one case where running the
        whole suite *is* the point. Changing what verification runs is a claim
        that the new pipeline works, and only a full run tests that claim.
        `.github/workflows/` stays full-scope; only its inert neighbours moved.
        """
        plan = self._plan(".github/workflows/ci.yml")
        self.assertTrue(plan.full_suite)

    def test_an_unclassified_path_still_widens_to_everything(self) -> None:
        """The fallback is the safe default and this change does not touch it.

        What was wrong was never the fallback — it was the paths reaching it
        that should have been classified.
        """
        plan = self._plan("tools/some_new_thing.py")
        self.assertTrue(plan.full_suite)

    def test_a_documents_only_change_does_not_pay_for_a_windows_runner(self) -> None:
        """The job is conditional for a reason: Windows minutes cost double."""
        plan = self._plan("design_audit/layout_review/SUMMARY.md")
        self.assertFalse(plan.needs_goldens)

    def test_normalization_preserves_dot_prefixed_directories(self) -> None:
        self.assertEqual(
            ".github/workflows/ci.yml",
            self.module.normalize_path(r"./.github\workflows\ci.yml"),
        )

    def test_newline_input_does_not_turn_a_known_path_into_full_scope(self) -> None:
        plan = self._plan(
            "\ufefflib/features/card/presentation/screens/card_list_screen.dart\r"
        )
        self.assertFalse(plan.full_suite)

    def test_prompt_only_change_uses_python_contract_path(self) -> None:
        plan = self._plan(
            "docs/prompt/progress-v1/implementation.md",
            "docs/prompt/progress-v1/recursive-ui-ux-review.md",
        )
        self.assertTrue(plan.prompt_only)
        self.assertTrue(plan.docs_only)
        self.assertFalse(plan.code_required)
        self.assertFalse(plan.needs_static)
        self.assertFalse(plan.needs_host_tests)
        self.assertFalse(plan.needs_widgetbook)

    def test_prompt_plus_normative_docs_stays_flutter_free(self) -> None:
        plan = self._plan(
            "docs/prompt/sample/implementation.md",
            "docs/wbs.md",
        )
        self.assertFalse(plan.prompt_only)
        self.assertTrue(plan.docs_only)
        self.assertFalse(plan.code_required)

    def test_presentation_change_adds_transitive_app_consumers(self) -> None:
        plan = self._plan(
            "lib/features/card/presentation/screens/card_list_screen.dart"
        )
        self.assertEqual(("card",), plan.affected_features)
        self.assertEqual(("presentation",), plan.affected_layers)
        self.assertTrue(plan.test_files)
        self.assertTrue(
            any(path.startswith("test/features/card/presentation/") for path in plan.test_files)
        )
        self.assertIn(
            "test/app/router/app_router_test.dart",
            plan.test_files,
        )
        self.assertIn(
            "test/integration/widgets/navigation_widget_test.dart",
            plan.test_files,
        )
        self.assertTrue(plan.needs_widgetbook)

    def test_data_change_adds_cross_feature_harness_consumers(self) -> None:
        plan = self._plan(
            "lib/features/card/data/repositories/card_repository_impl.dart"
        )
        self.assertEqual(("data",), plan.affected_layers)
        self.assertTrue(plan.test_files)
        self.assertTrue(
            any(path.startswith("test/features/card/data/") for path in plan.test_files)
        )
        self.assertIn(
            "test/features/deck/data/web/deck_repository_web_test.dart",
            plan.test_files,
        )
        self.assertFalse(plan.needs_widgetbook)

    def test_use_case_change_adds_data_flow_consumers(self) -> None:
        plan = self._plan(
            "lib/features/study/domain/usecases/start_study_session_use_case.dart"
        )
        self.assertEqual(("domain", "presentation"), plan.affected_layers)
        self.assertIn(
            "test/features/study/data/study_flow_test.dart",
            plan.test_files,
        )
        self.assertTrue(plan.needs_widgetbook)

    def test_public_domain_contract_expands_transitive_dependents(self) -> None:
        plan = self._plan(
            "lib/features/deck/domain/repositories/deck_repository.dart"
        )
        self.assertTrue(
            {"deck", "card", "study", "search", "progress", "trash"}
            <= set(plan.affected_features)
        )
        self.assertEqual(("data", "domain", "presentation"), plan.affected_layers)
        self.assertGreaterEqual(plan.shard_count, 2)

    def test_database_query_uses_declared_feature_owner(self) -> None:
        plan = self._plan("lib/core/database/queries/study.drift")
        self.assertIn("study", plan.affected_features)
        self.assertIn("progress", plan.affected_features)
        self.assertIn(
            "test/integration/flows/answer_kind_flow_test.dart",
            plan.test_files,
        )
        self.assertIn(
            "test/integration/flows/stored_not_inferred_flow_test.dart",
            plan.test_files,
        )
        self.assertIn(
            "test/database/invariants_after_flow_test.dart",
            plan.test_files,
        )
        self.assertFalse(plan.full_suite)

    def test_schema_change_promotes_to_full_suite(self) -> None:
        plan = self._plan("lib/core/database/tables/cards.drift")
        self.assertTrue(plan.full_suite)
        self.assertEqual(5, plan.shard_count)
        self.assertTrue(plan.needs_widgetbook)
        self.assertEqual(("test",), plan.local_test_targets)

    def test_shared_theme_router_native_and_dependency_changes_are_full(self) -> None:
        for path in (
            "lib/core/theme/app_theme.dart",
            "lib/presentation/shared/mx_card.dart",
            "lib/app/router/app_router.dart",
            "android/app/build.gradle.kts",
            "pubspec.yaml",
        ):
            with self.subTest(path=path):
                self.assertTrue(self._plan(path).full_suite)

    def test_ci_tooling_change_is_full_so_the_new_gate_proves_itself(self) -> None:
        plan = self._plan(".github/workflows/ci.yml")
        self.assertTrue(plan.full_suite)
        self.assertEqual(5, plan.shard_count)

    def test_test_only_change_runs_exact_tracked_test(self) -> None:
        path = "test/features/card/domain/card_text_test.dart"
        plan = self._plan(path)
        self.assertEqual((path,), plan.test_files)
        self.assertEqual(1, plan.shard_count)

    def test_golden_only_change_uses_runnable_surrogates(self) -> None:
        path = "test/shared/widgets/mx_components_golden_test.dart"
        plan = self._plan(path)
        self.assertNotIn(path, plan.test_files)
        self.assertTrue(plan.test_files)
        self.assertTrue(plan.needs_widgetbook)
        self.assertTrue(
            all(
                not self.module.is_golden_only_test(REPO_ROOT / test_path)
                for test_path in plan.test_files
            )
        )

    def test_untracked_test_is_part_of_the_local_sealed_plan(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            subprocess.run(["git", "init", "-q", str(root)], check=True)
            (root / "pubspec.yaml").write_text("name: memox\n", encoding="utf-8")
            tracked = root / "test" / "tracked_test.dart"
            tracked.parent.mkdir(parents=True)
            tracked.write_text("void main() { test('tracked', () {}); }\n", encoding="utf-8")
            subprocess.run(
                ["git", "-C", str(root), "add", "pubspec.yaml", "test/tracked_test.dart"],
                check=True,
            )
            untracked = root / "test" / "new_test.dart"
            untracked.write_text("void main() { test('new', () {}); }\n", encoding="utf-8")

            plan = self.module.build_plan(
                ["test/new_test.dart"],
                root=root,
            )

            self.assertIn("test/new_test.dart", plan.test_files)
            self.assertIn("test/new_test.dart", plan.local_test_targets)

    def test_the_worktree_scan_is_memoized_per_root_not_globally(self) -> None:
        """The cache that made this suite 43s → 8s must not answer for a
        different tree.

        A memo keyed by anything coarser than the resolved root would hand a
        temporary repository the main repository's file list, and every plan
        built against a fixture would silently describe memox instead. The
        second half is the one that matters: the first assertion passes under a
        global cache too.
        """
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            subprocess.run(["git", "init", "-q", str(root)], check=True)
            (root / "pubspec.yaml").write_text("name: memox\n", encoding="utf-8")
            solitary = root / "test" / "only_test.dart"
            solitary.parent.mkdir(parents=True)
            solitary.write_text("void main() { test('only', () {}); }\n", encoding="utf-8")

            repo_first = self.module.discover_tests(REPO_ROOT)
            fixture = self.module.discover_tests(root)
            repo_second = self.module.discover_tests(REPO_ROOT)

            self.assertEqual(repo_first, repo_second)
            self.assertEqual({"test/only_test.dart": 1}, fixture)
            self.assertGreater(len(repo_first), 1)

    def test_a_memoized_scan_is_not_shared_mutable_state(self) -> None:
        """`seal` builds sets from what it receives; a shared object would let
        one plan corrupt the next one built in the same process."""
        first = self.module.discover_tests(REPO_ROOT)
        first.clear()
        self.assertGreater(len(self.module.discover_tests(REPO_ROOT)), 1)

    def test_deleted_test_support_selects_its_layer(self) -> None:
        plan = self._plan("test/features/card/data/support/deleted_fixture.dart")
        self.assertTrue(plan.test_files)
        self.assertTrue(
            all(path.startswith("test/features/card/data/") for path in plan.test_files)
        )

    def test_widgetbook_only_change_skips_host_tests(self) -> None:
        plan = self._plan("widgetbook/lib/main.dart")
        self.assertTrue(plan.code_required)
        self.assertTrue(plan.needs_static)
        self.assertTrue(plan.needs_widgetbook)
        self.assertFalse(plan.needs_host_tests)

    def test_new_feature_without_tests_promotes_instead_of_trusting_widgetbook(self) -> None:
        plan = self._plan(
            "lib/features/not_yet_mapped/presentation/screens/new_screen.dart"
        )
        self.assertTrue(plan.full_suite)
        self.assertTrue(plan.needs_host_tests)

    def test_unknown_and_empty_changes_fail_safe_to_full(self) -> None:
        unknown = self._plan("tool/new_unclassified_binary")
        empty = self._plan()
        self.assertTrue(unknown.full_suite)
        self.assertEqual(("tool/new_unclassified_binary",), unknown.unmatched_paths)
        self.assertTrue(empty.full_suite)

    def test_force_full_disables_docs_fast_path(self) -> None:
        plan = self._plan("docs/wbs.md", force_full=True)
        self.assertTrue(plan.full_suite)
        self.assertTrue(plan.code_required)

    def test_sealed_plan_is_immutable_and_json_is_deterministic(self) -> None:
        first = self._plan(
            "lib/features/card/data/repositories/card_repository_impl.dart",
            "docs/wbs.md",
        )
        second = self._plan(
            "docs/wbs.md",
            "lib/features/card/data/repositories/card_repository_impl.dart",
        )
        self.assertEqual(first, second)
        self.assertEqual(first.to_json_dict(), second.to_json_dict())
        with self.assertRaises(dataclasses.FrozenInstanceError):
            first.risk = "docs"

    def test_shard_policy_is_one_two_or_five_and_never_empty(self) -> None:
        choose = self.module.choose_shard_count
        self.assertEqual(0, choose(0, 0, 240, 800))
        self.assertEqual(1, choose(240, 20, 240, 800))
        self.assertEqual(2, choose(700, 50, 240, 800))
        self.assertEqual(5, choose(1200, 50, 240, 800))

    def test_local_targets_never_pull_an_unselected_test_into_scope(self) -> None:
        compress = self.module.compress_test_targets
        selected = {
            "test/features/card/data/a_test.dart",
            "test/features/card/data/b_test.dart",
        }
        all_tests = selected | {"test/features/card/domain/c_test.dart"}
        self.assertEqual(
            ("test/features/card/data",),
            compress(selected, all_tests),
        )


class ImpactMapCoverageTest(unittest.TestCase):
    def _impact(self) -> dict[str, object]:
        return json.loads(
            (SCRIPTS / "verification_impact_map.json").read_text(encoding="utf-8")
        )

    def test_every_database_query_has_a_declared_owner(self) -> None:
        impact = self._impact()
        declared = set(impact["database_query_features"])
        actual = {path.stem for path in (REPO_ROOT / "lib/core/database/queries").glob("*.drift")}
        self.assertEqual(actual, declared & actual)

    def test_every_feature_is_a_node_in_the_dependency_graph(self) -> None:
        impact = self._impact()
        graph = impact["feature_dependencies"]
        nodes = set(graph)
        for dependents in graph.values():
            nodes.update(dependents)
        actual = {
            path.name
            for path in (REPO_ROOT / "lib/features").iterdir()
            if path.is_dir()
        }
        self.assertEqual(set(), actual - nodes)

    def test_every_feature_source_uses_a_known_top_level_layer(self) -> None:
        allowed = {"domain", "data", "di", "presentation"}
        bad: list[str] = []
        for path in (REPO_ROOT / "lib/features").rglob("*.dart"):
            relative = path.relative_to(REPO_ROOT).as_posix().split("/")
            if len(relative) < 4 or relative[3] not in allowed:
                bad.append(path.relative_to(REPO_ROOT).as_posix())
        self.assertEqual([], bad)

    def test_dependency_graph_closure_terminates_even_with_cycles(self) -> None:
        module = _load("build_verification_plan")
        plan = module.build_plan(
            ["lib/features/tag/domain/repositories/tag_repository.dart"],
            root=REPO_ROOT,
        )
        self.assertIn("tag", plan.affected_features)
        self.assertIn("card", plan.affected_features)


class AggregateGateTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.module = _load("check_ci_gate")

    def _evaluate(self, **overrides):
        values = {
            "classify_result": "success",
            "contracts_result": "success",
            "static_result": "success",
            "host_result": "success",
            "widgetbook_result": "success",
            "goldens_result": "success",
            "needs_contracts": True,
            "needs_static": True,
            "needs_host_tests": True,
            "needs_widgetbook": True,
            "needs_goldens": True,
        }
        values.update(overrides)
        return self.module.evaluate(**values)

    def test_full_path_passes_when_every_required_job_succeeds(self) -> None:
        self.assertEqual([], self._evaluate())

    def test_a_required_golden_job_that_did_not_run_fails_the_gate(self) -> None:
        """The gap #337 walked through: green everywhere, pixels never compared.

        A skipped golden job on a change that needs one is not a neutral
        result — it is the check that would have caught 26 stale pictures
        never having happened.
        """
        problems = self._evaluate(goldens_result="skipped", needs_goldens=True)
        self.assertEqual(1, len(problems))
        self.assertIn("golden comparison", problems[0])

    def test_golden_job_running_when_unselected_fails_the_gate(self) -> None:
        problems = self._evaluate(goldens_result="success", needs_goldens=False)
        self.assertEqual(1, len(problems))
        self.assertIn("golden comparison", problems[0])

    def test_docs_path_requires_only_contract_job(self) -> None:
        self.assertEqual(
            [],
            self._evaluate(
                static_result="skipped",
                host_result="skipped",
                widgetbook_result="skipped",
                goldens_result="skipped",
                needs_static=False,
                needs_host_tests=False,
                needs_widgetbook=False,
                needs_goldens=False,
            ),
        )

    def test_data_path_allows_widgetbook_to_be_skipped(self) -> None:
        self.assertEqual(
            [],
            self._evaluate(
                widgetbook_result="skipped",
                needs_widgetbook=False,
            ),
        )

    def test_required_cancelled_host_shard_fails_aggregate(self) -> None:
        problems = self._evaluate(host_result="cancelled")
        self.assertTrue(any("host-test shards" in problem for problem in problems))

    def test_unselected_job_running_is_a_gate_failure(self) -> None:
        problems = self._evaluate(
            widgetbook_result="success",
            needs_widgetbook=False,
        )
        self.assertTrue(any("expected skipped" in problem for problem in problems))


class FileShardSelectionTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.module = _load("select_test_shard")

    def test_files_are_atomic_disjoint_and_complete(self) -> None:
        files = [
            self.module.WeightedTestFile("a_test.dart", 10),
            self.module.WeightedTestFile("b_test.dart", 8),
            self.module.WeightedTestFile("c_test.dart", 6),
            self.module.WeightedTestFile("d_test.dart", 4),
        ]
        shards = self.module.partition(files, total_shards=2)
        flattened = [item.path for shard in shards for item in shard]
        self.assertCountEqual([item.path for item in files], flattened)
        self.assertEqual(len(flattened), len(set(flattened)))
        self.assertEqual([14, 14], [sum(item.weight for item in shard) for shard in shards])

    def test_partition_is_deterministic_for_input_order(self) -> None:
        files = [
            self.module.WeightedTestFile("c_test.dart", 1),
            self.module.WeightedTestFile("a_test.dart", 1),
            self.module.WeightedTestFile("b_test.dart", 1),
        ]
        self.assertEqual(
            self.module.partition(files, total_shards=2),
            self.module.partition(list(reversed(files)), total_shards=2),
        )

    def test_five_shards_are_non_empty_disjoint_complete_and_balanced(self) -> None:
        files = [
            self.module.WeightedTestFile(f"{weight}_test.dart", weight)
            for weight in range(1, 11)
        ]
        shards = self.module.partition(files, total_shards=5)
        flattened = [item.path for shard in shards for item in shard]
        shard_weights = [sum(item.weight for item in shard) for shard in shards]
        self.assertTrue(all(shards))
        self.assertCountEqual([item.path for item in files], flattened)
        self.assertEqual(len(flattened), len(set(flattened)))
        self.assertEqual([11, 11, 11, 11, 11], shard_weights)

    def test_json_filter_selects_only_the_sealed_plan_files(self) -> None:
        selected = {"test/features/card/domain/card_text_test.dart"}
        files = self.module.discover(REPO_ROOT, include_paths=selected)
        self.assertEqual(selected, {item.path for item in files})

    def test_json_filter_rejects_missing_or_untracked_file(self) -> None:
        with self.assertRaises(ValueError):
            self.module.discover(
                REPO_ROOT,
                include_paths={"test/does_not_exist_test.dart"},
            )


class WorkflowContractTest(unittest.TestCase):
    def test_ci_consumes_the_sealed_dynamic_plan(self) -> None:
        workflow = (REPO_ROOT / ".github/workflows/ci.yml").read_text(encoding="utf-8")
        self.assertIn("build_verification_plan.py", workflow)
        self.assertIn("--diff-filter=ACMRTD", workflow)
        self.assertIn("matrix: ${{ fromJSON(needs.classify.outputs.shard_matrix) }}", workflow)
        self.assertIn("--test-files-json \"$TEST_FILES_JSON\"", workflow)
        self.assertIn("--needs-widgetbook", workflow)
        self.assertIn("pub get (widgetbook catalog for root analyze)", workflow)
        self.assertNotIn("classify_ci_changes.py", workflow)

    def test_local_gate_fails_closed_when_required_tools_are_missing(self) -> None:
        script = (SCRIPTS / "dod_check.sh").read_text(encoding="utf-8")
        self.assertIn("--diff-filter=ACMRTD", script)
        self.assertIn(
            'FAILED+=("flutter unavailable for selected mandatory gates")',
            script,
        )
        self.assertIn('FAILED+=("document gate unavailable:', script)
        self.assertIn('FAILED+=("CI tooling tests unavailable:', script)
        self.assertNotIn('SKIPPED+=("format', script)
        self.assertNotIn('SKIPPED+=("test', script)


HEADER = """# {title}

| | |
|---|---|
| **Status** | active |
| **Purpose** | Test prompt |
| **Scope** | Test scope |
| **Source of truth for** | Test execution instructions |
| **Depends on** | `AGENTS.md` |
| **Updated by task** | TEST |
| **Last updated** | 2026-08-13 |

"""


class PromptContractTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.module = _load("check_prompt_contract")

    def setUp(self) -> None:
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)
        self.feature = self.root / "docs" / "prompt" / "sample"
        self.feature.mkdir(parents=True)
        self._write_valid_set()

    def tearDown(self) -> None:
        self.temp.cleanup()

    def _write_valid_set(self) -> None:
        (self.feature / "implementation.md").write_text(
            HEADER.format(title="Implementation")
            + "5Why. Check the worktree. Run verification and gate. Clean stop.\n",
            encoding="utf-8",
        )
        (self.feature / "recursive-architecture-logic-review.md").write_text(
            HEADER.format(title="Architecture review")
            + "Audit-only first. Check the worktree, business rules, architecture boundary, database persistence and failure handling. Apply fixes, test, then clean stop.\n",
            encoding="utf-8",
        )
        (self.feature / "recursive-ui-ux-review.md").write_text(
            HEADER.format(title="UI review")
            + "Audit-only production states in the production tree. Check the worktree. Use getRect and golden comparison, list approved divergence, auto-fix, test, and clean stop.\n",
            encoding="utf-8",
        )

    def test_valid_prompt_set_passes(self) -> None:
        self.assertEqual([], self.module.validate_prompt_root(self.root))

    def test_missing_review_file_fails(self) -> None:
        (self.feature / "recursive-ui-ux-review.md").unlink()
        messages = [problem.message for problem in self.module.validate_prompt_root(self.root)]
        self.assertTrue(any("missing prompt files" in message for message in messages))

    def test_run_file_is_rejected(self) -> None:
        (self.feature / "run.md").write_text("# Run\n", encoding="utf-8")
        messages = [problem.message for problem in self.module.validate_prompt_root(self.root)]
        self.assertTrue(any("unexpected prompt files" in message for message in messages))

    def test_ui_review_without_geometry_fails(self) -> None:
        path = self.feature / "recursive-ui-ux-review.md"
        path.write_text(
            path.read_text(encoding="utf-8").replace("getRect", "geometry"),
            encoding="utf-8",
        )
        messages = [problem.message for problem in self.module.validate_prompt_root(self.root)]
        self.assertTrue(any("getRect" in message for message in messages))

    def test_out_of_order_header_fails(self) -> None:
        path = self.feature / "implementation.md"
        text = path.read_text(encoding="utf-8")
        text = text.replace(
            "| **Purpose** | Test prompt |\n| **Scope** | Test scope |",
            "| **Scope** | Test scope |\n| **Purpose** | Test prompt |",
        )
        path.write_text(text, encoding="utf-8")
        messages = [problem.message for problem in self.module.validate_prompt_root(self.root)]
        self.assertTrue(any("header fields" in message for message in messages))


class PlanOutputsAreWiredIntoTheWorkflowTest(unittest.TestCase):
    """Every `needs_*` the plan emits must reach the jobs that read it.

    **This test exists because the wire was cut and nothing noticed.** The
    golden gate shipped with `needs_goldens` written to `$GITHUB_OUTPUT` and
    *not* declared in the `classify` job's `outputs:` map, so
    `needs.classify.outputs.needs_goldens` resolved to the empty string, the
    Windows job was skipped on a change that required it, and the only reason
    it surfaced was that `check_ci_gate.py` refused to parse `''` as a boolean.
    Had the gate been more forgiving, the job would have been silently dead —
    which is the exact failure it was added to prevent, one layer up.

    Parsed as text rather than with PyYAML on purpose: the job that runs these
    tests installs no Python dependencies, and a guard that cannot run is worse
    than one that is slightly blunt.
    """

    @classmethod
    def setUpClass(cls) -> None:
        cls.module = _load("build_verification_plan")
        cls.workflow = (REPO_ROOT / ".github/workflows/ci.yml").read_text(
            encoding="utf-8"
        )

    def _emitted_needs_keys(self) -> set[str]:
        plan = self.module.build_plan(
            ("lib/features/deck/presentation/screens/deck_list_screen.dart",),
            root=REPO_ROOT,
        )
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory) / "github_output"
            output.touch()
            self.module.write_github_output(output, plan)
            lines = output.read_text(encoding="utf-8").splitlines()
        return {
            line.split("=", 1)[0]
            for line in lines
            if line.startswith("needs_")
        }

    def _classify_outputs_block(self) -> str:
        start = self.workflow.index("    outputs:")
        end = self.workflow.index("    steps:", start)
        return self.workflow[start:end]

    def test_every_needs_flag_is_declared_as_a_classify_output(self) -> None:
        declared = self._classify_outputs_block()
        for key in sorted(self._emitted_needs_keys()):
            with self.subTest(key=key):
                self.assertIn(
                    f"{key}: ${{{{ steps.changes.outputs.{key} }}}}",
                    declared,
                    f"{key} is written to $GITHUB_OUTPUT but never exposed to "
                    f"downstream jobs, so any `if:` reading it is always false",
                )

    def test_every_needs_flag_is_handed_to_the_gate(self) -> None:
        for key in sorted(self._emitted_needs_keys()):
            flag = "--" + key.replace("_", "-")
            with self.subTest(key=key):
                self.assertIn(
                    f"{flag} '${{{{ needs.classify.outputs.{key} }}}}'",
                    self.workflow,
                    f"{flag} is not passed to check_ci_gate.py, so a job "
                    f"selected by {key} is never checked for having run",
                )


if __name__ == "__main__":
    unittest.main()
