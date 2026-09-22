"""Install/update integrity and portability through actual installed helper CLIs."""
import json
import shutil
import subprocess
import sys
import tempfile
import unittest
from unittest import mock
from pathlib import Path

sys.dont_write_bytecode = True
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from repository_context import CONFIG_PATH
from skill_distribution import (MANIFEST, NAME, RECEIPT, distribute, inspect_active,
                                inspect_copy, repo_skill, seal)


class DistributionTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.base = Path(self.temp.name).resolve()
        self.source = self.base / "canonical" / NAME
        self.source.mkdir(parents=True)
        (self.source / "SKILL.md").write_text(
            f"---\nname: {NAME}\ndescription: Fixture skill.\n---\n# Fixture\n", encoding="utf-8")
        self.repo = self.base / "different-repository"
        self.repo.mkdir()
        self.user = self.base / "user-skills"
        self.destination = self.user / NAME
        seal(self.source, "1.0.0")

    def install(self):
        return distribute(self.source, self.destination, "install", "global")

    def test_install_roundtrip_global_to_repo_and_idempotent_sync(self):
        release = self.install()
        repeated = distribute(self.source, self.destination, "sync", "global")
        self.assertEqual(release, repeated)
        copy = distribute(self.destination, repo_skill(self.repo), "install", "repository")
        self.assertEqual(release["digest"], copy["digest"])
        self.assertEqual(str(self.source), copy["canonical_source"])
        with self.assertRaises(ValueError):
            self.install()

    def test_changed_added_and_deleted_files_are_drift_and_never_overwritten(self):
        self.install()
        file = self.destination / "SKILL.md"
        original = file.read_bytes()
        file.write_bytes(original + b"modified\n")
        self.assertEqual("DRIFT", inspect_copy(self.destination)["status"])
        with self.assertRaises(ValueError):
            distribute(self.source, self.destination, "update", "global", "1.0.0")
        self.assertTrue(file.read_bytes().endswith(b"modified\n"))
        file.write_bytes(original)
        extra = self.destination / "extra.txt"
        extra.write_text("untracked payload")
        self.assertIn("extra.txt", inspect_copy(self.destination)["changed_files"])
        extra.unlink()
        file.unlink()
        self.assertEqual("INVALID", inspect_copy(self.destination)["status"])

    def test_same_version_changes_require_new_release_and_explicit_update(self):
        self.install()
        (self.source / "new-reference.md").write_text("# More\n")
        with self.assertRaises(ValueError):
            seal(self.source, "1.0.0")
        seal(self.source, "1.1.0")
        with self.assertRaises(ValueError):
            distribute(self.source, self.destination, "sync", "global")
        with self.assertRaises(ValueError):
            distribute(self.source, self.destination, "update", "global", "1.0.0")
        current = distribute(self.source, self.destination, "update", "global", "1.1.0")
        self.assertEqual("1.1.0", current["version"])
        self.assertTrue((self.destination / "new-reference.md").exists())

    def test_update_preserves_config_and_respects_repository_pin(self):
        target = repo_skill(self.repo)
        distribute(self.source, target, "install", "repository")
        config = self.repo / CONFIG_PATH
        config.write_text(json.dumps({"schema_version": 1, "pin": {"version": "1.0.0"}}))
        before = config.read_bytes()
        (self.source / "extra.md").write_text("# Added")
        seal(self.source, "1.1.0")
        with self.assertRaises(ValueError):
            distribute(self.source, target, "update", "repository", "1.1.0", {"version": "1.0.0"})
        self.assertEqual(before, config.read_bytes())
        self.assertEqual("1.0.0", inspect_copy(target)["version"])

    def test_failed_swap_restores_previous_installation(self):
        original = self.install()
        (self.source / "extra.md").write_text("# Added")
        seal(self.source, "1.1.0")
        rename = Path.rename

        def fail_stage(path, target):
            if path.name.startswith(f".{NAME}-stage-"):
                raise OSError("simulated rename failure")
            return rename(path, target)

        with mock.patch.object(Path, "rename", fail_stage):
            with self.assertRaises(OSError):
                distribute(self.source, self.destination, "update", "global", "1.1.0")
        self.assertEqual(original, inspect_copy(self.destination))

    def test_install_receipt_is_checked_and_cannot_author_release(self):
        self.install()
        with self.assertRaises(ValueError):
            seal(self.destination, "2.0.0")
        receipt = self.destination / RECEIPT
        value = json.loads(receipt.read_text())
        value["release"]["version"] = "9.0.0"
        receipt.write_text(json.dumps(value))
        self.assertEqual("INVALID", inspect_copy(self.destination)["status"])

    def test_line_ending_changes_do_not_create_false_drift(self):
        self.install()
        file = self.destination / "SKILL.md"
        file.write_bytes(file.read_bytes().replace(b"\r\n", b"\n").replace(b"\n", b"\r\n"))
        self.assertEqual("VALID", inspect_copy(self.destination)["status"])

    def test_source_overlap_and_foreign_authority_fail(self):
        with self.assertRaises(ValueError):
            distribute(self.source, self.source / "nested", "install", "repository")
        self.install()
        manifest = self.destination / MANIFEST
        value = json.loads(manifest.read_text())
        value["source_id"] = "urn:other-authority"
        manifest.write_text(json.dumps(value))
        receipt = self.destination / RECEIPT
        value = json.loads(receipt.read_text())
        value["release"]["source_id"] = "urn:other-authority"
        receipt.write_text(json.dumps(value))
        with self.assertRaises(ValueError):
            distribute(self.source, self.destination, "sync", "global")

    def test_inspect_shows_real_path_scope_overrides_and_conflicting_releases(self):
        explicit = inspect_active(self.repo, self.source, self.user)
        self.assertEqual("explicit", explicit["active"]["scope"])
        self.install()
        distribute(self.source, repo_skill(self.repo), "install", "repository")
        (self.source / "extra.md").write_text("# Added")
        seal(self.source, "1.1.0")
        distribute(self.source, self.destination, "update", "global", "1.1.0")
        report = inspect_active(self.repo, repo_skill(self.repo), self.user)
        self.assertFalse(report["ok"])
        self.assertTrue(report["conflicts"])
        config = self.repo / CONFIG_PATH
        config.write_text(json.dumps({"schema_version": 1, "pin": {"version": "1.0.0"}}))
        report = inspect_active(self.repo, repo_skill(self.repo), self.user)
        self.assertTrue(report["ok"])
        self.assertEqual("repository", report["active"]["scope"])
        self.assertEqual({"version": "1.0.0"}, report["repository_config"]["overrides"]["pin"])

    def test_portability_actual_skill_installed_unchanged_executes_other_repo_workflow(self):
        actual = Path(__file__).resolve().parents[2]
        portable = self.base / "portable-source" / NAME
        shutil.copytree(actual, portable, ignore=shutil.ignore_patterns("__pycache__", MANIFEST, RECEIPT))
        seal(portable, "2.0.0")
        installed = self.base / "portable-user" / NAME
        distribute(portable, installed, "install", "global")
        # Different language/layout, no database, no docs directory or config.
        (self.repo / "engine").mkdir()
        (self.repo / "engine" / "main.rs").write_text('fn main() { println!("hello"); }\n')
        (self.repo / "Cargo.toml").write_text('[package]\nname="fixture"\nversion="0.1.0"\n[[bin]]\nname="fixture"\npath="engine/main.rs"\n')
        (self.repo / "HACKING.rst").write_text("Conventions\n===========\nKeep computation pure.\n")

        def cli(script, *extra):
            process = subprocess.run([sys.executable, str(installed / "scripts" / script),
                                      "--root", str(self.repo), *extra], capture_output=True, text=True)
            return process, json.loads(process.stdout)

        process, context = cli("repository_context.py")
        self.assertEqual(0, process.returncode, process.stderr)
        self.assertIn("HACKING.rst", context["instructions_to_read"])
        self.assertEqual(["Rust"], context["stack"]["languages"])
        self.assertEqual([], context["persistence"]["schema_candidates"])
        # UPDATE artifact derives its paths from the inspected source, no new hierarchy.
        overview = self.repo / "README.md"
        overview.write_text("# Fixture command\n\nCurrent behavior: prints hello (engine/main.rs).\n\n## Folder responsibilities\nengine owns the executable.\n\n## Dependency direction\nNo external dependency is declared in Cargo.toml.\n\n## Verification\nInspect the entry point; no test suite was run.\n\n[Source](engine/old.rs)\n")
        before = overview.read_bytes()
        process, report = cli("validate_docs.py", "--audit")
        self.assertEqual(1, process.returncode)
        self.assertEqual("link", report["findings"][0]["kind"])
        self.assertEqual(before, overview.read_bytes())
        # REPAIR against concrete existing source; FULL_SYNC re-discovers/re-audits.
        overview.write_bytes(before.replace(b"engine/old.rs", b"engine/main.rs"))
        self.assertEqual(0, cli("repository_context.py")[0].returncode)
        self.assertEqual(0, cli("validate_docs.py")[0].returncode)
        self.assertEqual("VALID", inspect_copy(installed)["status"])
        self.assertEqual((portable / "SKILL.md").read_bytes(), (installed / "SKILL.md").read_bytes())
        self.assertFalse((self.repo / "docs").exists())
        self.assertFalse((self.repo / CONFIG_PATH).exists())


if __name__ == "__main__":
    unittest.main()
