from __future__ import annotations

import hashlib
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path


SCRIPTS = Path(__file__).resolve().parents[1]
SCRIPT = SCRIPTS / "read_local_prompt_set.ps1"
PWSH = shutil.which("pwsh")

PROMPT_NAMES = (
    "implementation.md",
    "recursive-architecture-logic-review.md",
    "recursive-ui-ux-review.md",
)


@unittest.skipUnless(PWSH, "PowerShell 7 is required to exercise the handoff script")
class LocalPromptHandoffTest(unittest.TestCase):
    def setUp(self) -> None:
        self.temp = tempfile.TemporaryDirectory()
        root = Path(self.temp.name)
        # Spaces exercise LiteralPath and argument handling instead of only the
        # easy path shape used by the repository checkout.
        self.source = root / "source worktree"
        self.target = root / "target worktree"
        self._init_repository(self.source)
        self._init_repository(self.target)

        self.feature = "card-editor-ux-hardening"
        self.prompt_root = self.source / "docs" / "prompt" / self.feature
        self.prompt_root.mkdir(parents=True)
        self.contents = {
            PROMPT_NAMES[0]: "# Implementation\n\nTiếng Việt · 한국어\n",
            PROMPT_NAMES[1]: "# Architecture review\n\nAUDIT_ONLY first.\n",
            PROMPT_NAMES[2]: "# UI review\n\nInspect production states.\n",
        }
        for name, content in self.contents.items():
            (self.prompt_root / name).write_text(content, encoding="utf-8")

    def tearDown(self) -> None:
        self.temp.cleanup()

    @staticmethod
    def _init_repository(path: Path) -> None:
        path.mkdir(parents=True)
        subprocess.run(["git", "init", "-q", str(path)], check=True)

    def _hash(self, name: str) -> str:
        return hashlib.sha256((self.prompt_root / name).read_bytes()).hexdigest()

    def _arguments(
        self,
        *,
        target: Path | None = None,
        feature: str | None = None,
        implementation_hash: str | None = None,
        architecture_hash: str | None = None,
        ui_hash: str | None = None,
        verify_only: bool = False,
    ) -> list[str]:
        arguments = [
            str(PWSH),
            "-NoLogo",
            "-NoProfile",
            "-NonInteractive",
            "-File",
            str(SCRIPT),
            "-SourceRoot",
            str(self.source),
            "-FeatureName",
            feature or self.feature,
            "-ImplementationSha256",
            implementation_hash or self._hash(PROMPT_NAMES[0]),
            "-ArchitectureReviewSha256",
            architecture_hash or self._hash(PROMPT_NAMES[1]),
            "-UiUxReviewSha256",
            ui_hash or self._hash(PROMPT_NAMES[2]),
        ]
        if target is not None:
            arguments.extend(("-TargetRoot", str(target)))
        if verify_only:
            arguments.append("-VerifyOnly")
        return arguments

    def _run(self, **kwargs: object) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            self._arguments(**kwargs),
            cwd=self.target,
            capture_output=True,
            text=True,
            encoding="utf-8",
            errors="replace",
            check=False,
        )

    def test_verifies_then_emits_all_prompts_in_contract_order(self) -> None:
        result = self._run(target=self.target)

        self.assertEqual(0, result.returncode, result.stderr)
        self.assertIn("PROMPT_HANDOFF_VERIFIED", result.stdout)
        positions = [result.stdout.index(name) for name in PROMPT_NAMES]
        self.assertEqual(sorted(positions), positions)
        for content in self.contents.values():
            self.assertIn(content.strip(), result.stdout)
        self.assertIn("Tiếng Việt · 한국어", result.stdout)
        # Reading the prompts must not copy or stage anything in the target.
        status = subprocess.run(
            ["git", "-C", str(self.target), "status", "--porcelain"],
            capture_output=True,
            text=True,
            check=True,
        )
        self.assertEqual("", status.stdout)

    def test_default_target_is_the_current_git_worktree(self) -> None:
        result = self._run()

        self.assertEqual(0, result.returncode, result.stderr)
        self.assertIn(f"Target worktree: {self.target}", result.stdout)

    def test_verify_only_never_prints_prompt_content(self) -> None:
        result = self._run(target=self.target, verify_only=True)

        self.assertEqual(0, result.returncode, result.stderr)
        self.assertIn("PROMPT_HANDOFF_VERIFIED", result.stdout)
        self.assertNotIn("Tiếng Việt", result.stdout)
        self.assertNotIn("BEGIN LOCAL PROMPT", result.stdout)

    def test_missing_file_fails_before_any_prompt_content_is_emitted(self) -> None:
        ui_hash = self._hash(PROMPT_NAMES[2])
        (self.prompt_root / PROMPT_NAMES[2]).unlink()
        result = self._run(target=self.target, ui_hash=ui_hash)

        self.assertNotEqual(0, result.returncode)
        self.assertIn("Missing prompt file", result.stderr)
        self.assertNotIn("BEGIN LOCAL PROMPT", result.stdout)

    def test_hash_mismatch_fails_before_any_prompt_content_is_emitted(self) -> None:
        result = self._run(
            target=self.target,
            implementation_hash="0" * 64,
        )

        self.assertNotEqual(0, result.returncode)
        self.assertIn("SHA-256 mismatch", result.stderr)
        self.assertNotIn("BEGIN LOCAL PROMPT", result.stdout)

    def test_source_and_target_must_be_different_worktrees(self) -> None:
        result = self._run(target=self.source)

        self.assertNotEqual(0, result.returncode)
        self.assertIn("Source and target worktrees must differ", result.stderr)

    def test_feature_name_rejects_path_traversal(self) -> None:
        result = self._run(target=self.target, feature="../outside")

        self.assertNotEqual(0, result.returncode)
        self.assertIn("FeatureName", result.stderr)

    def test_source_argument_must_name_the_exact_git_root(self) -> None:
        nested = self.source / "docs"
        arguments = self._arguments(target=self.target)
        source_index = arguments.index("-SourceRoot") + 1
        arguments[source_index] = str(nested)

        result = subprocess.run(
            arguments,
            cwd=self.target,
            capture_output=True,
            text=True,
            encoding="utf-8",
            errors="replace",
            check=False,
        )

        self.assertNotEqual(0, result.returncode)
        self.assertIn("exact worktree root", result.stderr)


if __name__ == "__main__":
    unittest.main()
