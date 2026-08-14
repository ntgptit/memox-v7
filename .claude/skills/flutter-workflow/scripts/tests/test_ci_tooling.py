from __future__ import annotations

import dataclasses
import importlib.util
import json
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
            "needs_contracts": True,
            "needs_static": True,
            "needs_host_tests": True,
            "needs_widgetbook": True,
        }
        values.update(overrides)
        return self.module.evaluate(**values)

    def test_full_path_passes_when_every_required_job_succeeds(self) -> None:
        self.assertEqual([], self._evaluate())

    def test_docs_path_requires_only_contract_job(self) -> None:
        self.assertEqual(
            [],
            self._evaluate(
                static_result="skipped",
                host_result="skipped",
                widgetbook_result="skipped",
                needs_static=False,
                needs_host_tests=False,
                needs_widgetbook=False,
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


if __name__ == "__main__":
    unittest.main()
