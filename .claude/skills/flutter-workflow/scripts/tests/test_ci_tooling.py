from __future__ import annotations

import importlib.util
import sys
import tempfile
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


class ChangeClassifierTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.module = _load("classify_ci_changes")

    def test_prompt_only_change_uses_fast_path(self) -> None:
        result = self.module.classify(
            ["docs/prompt/progress-v1/implementation.md", "docs/prompt/progress-v1/recursive-ui-ux-review.md"]
        )
        self.assertTrue(result.prompt_only)
        self.assertFalse(result.code_required)
        self.assertTrue(result.has_prompt_changes)

    def test_mixed_change_fails_safe_to_code_gate(self) -> None:
        result = self.module.classify(
            ["docs/prompt/progress-v1/implementation.md", "lib/main.dart"]
        )
        self.assertFalse(result.prompt_only)
        self.assertTrue(result.code_required)

    def test_empty_change_fails_safe_to_code_gate(self) -> None:
        result = self.module.classify([])
        self.assertTrue(result.code_required)
        self.assertFalse(result.prompt_only)

    def test_workflow_dispatch_forces_code_gate(self) -> None:
        result = self.module.classify(
            ["docs/prompt/progress-v1/implementation.md"], force_code=True
        )
        self.assertTrue(result.code_required)
        self.assertFalse(result.prompt_only)


class AggregateGateTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.module = _load("check_ci_gate")

    def _evaluate(self, **overrides):
        values = {
            "classify_result": "success",
            "prompt_result": "skipped",
            "static_result": "success",
            "host_result": "success",
            "widgetbook_result": "success",
            "has_prompt_changes": False,
            "prompt_only": False,
            "code_required": True,
        }
        values.update(overrides)
        return self.module.evaluate(**values)

    def test_code_path_passes_when_every_required_job_succeeds(self) -> None:
        self.assertEqual([], self._evaluate())

    def test_prompt_path_passes_with_code_jobs_skipped(self) -> None:
        self.assertEqual(
            [],
            self._evaluate(
                prompt_result="success",
                static_result="skipped",
                host_result="skipped",
                widgetbook_result="skipped",
                has_prompt_changes=True,
                prompt_only=True,
                code_required=False,
            ),
        )

    def test_mixed_path_requires_both_prompt_and_code_results(self) -> None:
        problems = self._evaluate(has_prompt_changes=True, prompt_result="failure")
        self.assertTrue(any("prompt contract" in problem for problem in problems))

    def test_cancelled_host_shard_fails_aggregate(self) -> None:
        problems = self._evaluate(host_result="cancelled")
        self.assertTrue(any("host-test shards" in problem for problem in problems))


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
        forward = self.module.partition(files, total_shards=2)
        backward = self.module.partition(list(reversed(files)), total_shards=2)
        self.assertEqual(forward, backward)


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
        path.write_text(path.read_text(encoding="utf-8").replace("getRect", "geometry"), encoding="utf-8")
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
