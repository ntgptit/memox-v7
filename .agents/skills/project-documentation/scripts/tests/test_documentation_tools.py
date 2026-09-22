"""Behavioral fixtures for discovery, optional rules and portable document workflows."""
import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

sys.dont_write_bytecode = True
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from scan_docs import git, inventory
from repository_context import CONFIG_PATH, discover, load_config
from validate_docs import run_checks, supplemental, validate_file


class DocumentationToolsTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name).resolve()

    def write(self, name, content):
        path = self.root / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content, encoding="utf-8")
        return path

    def git_init(self):
        git(self.root, "init", "--quiet")
        git(self.root, "-c", "user.name=Fixture", "-c", "user.email=fixture@example.invalid",
            "commit", "--quiet", "--allow-empty", "-m", "fixture")

    def test_git_inventory_includes_untracked_excludes_ignored_and_repeats(self):
        self.git_init()
        self.write(".gitignore", "ignored/\n")
        self.write("guide/overview.md", "# Overview\n")
        self.write("engine/run.rs", "fn main() {}")
        self.write("ignored/private.md", "private")
        before = git(self.root, "status", "--porcelain=v1", "--untracked-files=all")
        first = inventory(self.root)
        self.assertEqual(first, inventory(self.root))
        self.assertIn("engine", first["folders"])
        self.assertEqual(["guide/overview.md"], [d["path"] for d in first["documents"]])
        self.assertEqual(before, git(self.root, "status", "--porcelain=v1", "--untracked-files=all"))

    def test_non_git_zero_config_discovery_does_not_invent_structure_or_database(self):
        self.write("Cargo.toml", '[package]\nname="fixture"\nversion="0.1.0"\n[[bin]]\nname="fixture"\npath="engine/run.rs"\n')
        self.write("engine/run.rs", 'fn main() { println!("hello"); }')
        self.write("checks/output_test.rs", '#[test] fn output() { assert_eq!(2 + 2, 4); }')
        context = discover(self.root)
        self.assertIsNone(context["head"])
        self.assertIsNone(context["configuration"]["path"])
        self.assertEqual(["Rust"], context["stack"]["languages"])
        self.assertEqual(["engine"], context["source_root_candidates"])
        self.assertEqual(["checks"], context["test_root_candidates"])
        self.assertEqual([], context["persistence"]["schema_candidates"])
        self.assertEqual("UNKNOWN", context["architecture"]["provenance"])
        self.assertFalse((self.root / "docs").exists())
        self.assertTrue(any(f["kind"] == "coverage" for f in supplemental(self.root, [])[1]))

    def test_equivalent_instructions_and_config_are_evidence_not_approval(self):
        self.write("HACKING.rst", "Conventions\n===========\nKeep computation pure.\n")
        self.write(CONFIG_PATH, json.dumps({"schema_version": 1, "source_roots": ["engine"],
                                          "canonical_locations": {"architecture": "HACKING.rst"}}))
        context = discover(self.root)
        self.assertIn("HACKING.rst", context["instructions_to_read"])
        self.assertEqual("CONFIGURED", context["canonical_locations"]["provenance"])
        self.assertEqual("UNKNOWN", context["documentation_conventions"]["provenance"])
        self.assertEqual([], load_config(self.root)["effective"]["required_files"])

    def test_links_unicode_references_fragments_and_examples(self):
        self.write("guide/target file.md", "# Đích\n\n## Repeat\n\n## Repeat\n")
        self.write("guide/topic.md", "# Topic\n[Unicode](target%20file.md#đích)\n[Duplicate](<target file.md#repeat-1>)\n[Root](/guide/target%20file.md)\n[Reference][target]\n[target]: <target file.md#đích>\nInline `[Example](missing.md)`\n```markdown\n[Example](missing.md)\n```\n")
        self.assertEqual([], validate_file(self.root, "guide/topic.md"))

    def test_audit_then_evidence_supported_repair(self):
        self.write("manual/current.md", "# Current\n")
        doc = self.write("README.md", "# Entry\n[Guide](manual/removed.md)\n")
        before = doc.read_bytes()
        issues = supplemental(self.root, [])[1]
        self.assertEqual(1, len(issues))
        self.assertEqual("link", issues[0]["kind"])
        self.assertEqual(before, doc.read_bytes())  # AUDIT is read-only.
        doc.write_text("# Entry\n[Guide](manual/current.md)\n", encoding="utf-8")
        self.assertEqual([], supplemental(self.root, [])[1])

    def test_optional_rules_and_required_files_are_not_global_defaults(self):
        self.write("README.md", "# Entry\n")
        self.assertEqual([], supplemental(self.root, [])[1])
        self.write(CONFIG_PATH, json.dumps({"schema_version": 1, "required_files": ["MANUAL.md"],
                         "document_rules": [{"glob": "README.md", "required_headings": ["Structure"]}]}))
        self.assertEqual({"missing", "heading"}, {f["kind"] for f in supplemental(self.root, [])[1]})

    def test_header_rules_are_configured_not_inferred_from_later_sections(self):
        rules = [{"glob": "*.md", "header_fields": ["State", "Owner"]}]
        self.write("README.md", "# Entry\n\n| **State** | current |\n| **Owner** | maintainers |\n\n## Decision\n| **State** | proposed |\n")
        self.assertEqual([], validate_file(self.root, "README.md", rules))

    def test_invalid_configuration_and_path_escape_fail_fast(self):
        for delta in ({"schema_version": 1, "workflow": "fork"},
                      {"schema_version": 1, "context_files": ["../outside"]},
                      {"schema_version": 1, "checks": "echo ok"}):
            self.write(CONFIG_PATH, json.dumps(delta))
            with self.assertRaises(ValueError):
                load_config(self.root)
        with self.assertRaises(ValueError):
            supplemental(self.root, ["../outside"], {"required_files": [], "exclude_globs": [], "document_rules": []})

    def test_discovery_never_executes_commands_and_audit_skips_mutators(self):
        check = {"name": "mutation", "argv": ["{python}", "-c", "open('side-effect','w').write('bad')"], "read_only": False}
        self.write(CONFIG_PATH, json.dumps({"schema_version": 1, "checks": [check]}))
        discover(self.root)
        self.assertFalse((self.root / "side-effect").exists())
        self.assertEqual("NEEDS_VERIFICATION", run_checks(self.root, [check], True, True)[0]["status"])
        self.assertFalse((self.root / "side-effect").exists())

    def test_configured_missing_or_failing_gate_is_not_clean(self):
        failing = {"name": "fixture", "argv": ["{python}", "-c", "raise SystemExit(1)"], "read_only": True}
        self.assertEqual("FAIL", run_checks(self.root, [failing], True, True)[0]["status"])
        failing["argv"] = ["nonexistent-fixture-command-123"]
        self.assertEqual("FAIL", run_checks(self.root, [failing], True, True)[0]["status"])

    def test_missing_link_fragment_and_reference_are_reported(self):
        self.write("target.md", "# Present\n")
        self.write("README.md", "# Entry\n[a](absent.md)\n[b](target.md#absent)\n[c][absent]\n")
        self.assertEqual(3, len(validate_file(self.root, "README.md")))


if __name__ == "__main__":
    unittest.main()
