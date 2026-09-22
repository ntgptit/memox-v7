#!/usr/bin/env python3
"""Discover evidence candidates and inspect optional delta configuration; never execute it."""
from __future__ import annotations

import argparse
import copy
import fnmatch
import json
import subprocess
import sys
from pathlib import Path

sys.dont_write_bytecode = True
from scan_docs import inventory, repository_root

CONFIG_PATH = ".agents/project-documentation.json"
DEFAULTS = {
    "schema_version": 1, "context_files": [], "source_roots": [], "test_roots": [],
    "documentation_roots": [], "exclude_globs": [], "required_files": [],
    "canonical_locations": {}, "document_rules": [], "checks": [], "pin": {},
}
PATH_LISTS = ("context_files", "source_roots", "test_roots", "documentation_roots", "required_files")
LANGUAGES = {".py": "Python", ".rs": "Rust", ".go": "Go", ".js": "JavaScript",
             ".ts": "TypeScript", ".tsx": "TypeScript", ".java": "Java", ".kt": "Kotlin",
             ".cs": "C#", ".c": "C", ".cpp": "C++", ".rb": "Ruby", ".dart": "Dart",
             ".swift": "Swift", ".sh": "Shell"}
MANIFESTS = {"Cargo.toml", "go.mod", "package.json", "pyproject.toml", "requirements.txt",
             "pom.xml", "build.gradle", "build.gradle.kts", "pubspec.yaml", "Gemfile",
             "CMakeLists.txt", "Makefile", "Package.swift"}


def local_path(root: Path, value: str) -> Path:
    path = Path(value)
    if path.is_absolute() or ".." in path.parts or "\\" in value:
        raise ValueError(f"expected portable repository-relative path: {value}")
    result = (root / path).resolve()
    if not result.is_relative_to(root):
        raise ValueError(f"path escapes repository: {value}")
    return result


def string_list(value: object) -> bool:
    return isinstance(value, list) and all(isinstance(v, str) and v for v in value)


def load_config(root: Path, config: str | None = None) -> dict:
    path = local_path(root, config or CONFIG_PATH)
    if config and not path.is_file():
        raise ValueError(f"explicit config missing: {path}")
    overrides = json.loads(path.read_text(encoding="utf-8-sig")) if path.exists() else {}
    if not isinstance(overrides, dict) or set(overrides) - set(DEFAULTS):
        raise ValueError("configuration must be an object with supported delta keys")
    if path.exists() and (overrides.get("schema_version") != 1 or isinstance(overrides.get("schema_version"), bool)):
        raise ValueError("configuration requires schema_version: 1")
    effective = copy.deepcopy(DEFAULTS)
    for key, value in overrides.items():
        if key in PATH_LISTS or key == "exclude_globs":
            if not string_list(value):
                raise ValueError(f"{key} must be a list of nonempty strings")
            for item in value:
                local_path(root, item)
        if key in ("canonical_locations", "pin"):
            if not isinstance(value, dict) or not all(isinstance(k, str) and isinstance(v, str) and v for k, v in value.items()):
                raise ValueError(f"{key} must map strings to nonempty strings")
            if key == "pin" and set(value) - {"version", "digest", "source_id"}:
                raise ValueError("unknown pin field")
            if key == "canonical_locations":
                for location in value.values():
                    local_path(root, location.split("#", 1)[0])
        if key == "document_rules":
            if not isinstance(value, list):
                raise ValueError("document_rules must be a list")
            for rule in value:
                if not isinstance(rule, dict) or set(rule) - {"glob", "header_fields", "required_headings"}:
                    raise ValueError("invalid document rule")
                if not isinstance(rule.get("glob"), str) or not rule["glob"]:
                    raise ValueError("document rule needs glob")
                local_path(root, rule["glob"])
                for field in ("header_fields", "required_headings"):
                    if not string_list(rule.get(field, [])):
                        raise ValueError(f"{field} must be a string list")
        if key == "checks":
            if not isinstance(value, list):
                raise ValueError("checks must be a list")
            for check in value:
                if not isinstance(check, dict) or set(check) != {"name", "argv", "read_only"}:
                    raise ValueError("check needs name, argv and read_only only")
                if not isinstance(check["name"], str) or not check["name"] or not string_list(check["argv"]) or not check["argv"] or not isinstance(check["read_only"], bool):
                    raise ValueError("invalid check values")
        if isinstance(value, dict):
            effective[key].update(value)
            continue
        effective[key] = value
    return {"path": str(path) if path.exists() else None, "overrides": overrides,
            "effective": effective, "provenance": "CONFIGURED" if overrides else "generic defaults"}


def excluded(name: str, settings: dict) -> bool:
    return any(fnmatch.fnmatchcase(name, pattern) for pattern in settings["exclude_globs"])


def skill_payload(name: str) -> bool:
    return any(part in name for part in (".agents/skills/", ".codex/skills/", ".claude/skills/"))


def discover(root: Path, config: str | None = None) -> dict:
    settings = load_config(root, config)
    effective = settings["effective"]
    scan = inventory(root)
    files = [f for f in scan["files"] if not excluded(f, effective)]
    project_files = [f for f in files if not skill_payload(f)]
    instructions = [f for f in project_files if Path(f).stem.upper() in
                    {"AGENTS", "CLAUDE", "README", "CONTRIBUTING", "HACKING", "DEVELOPMENT", "CODEOWNERS"}]
    instructions = sorted(set(instructions + effective["context_files"]))
    code = [f for f in project_files if Path(f).suffix in LANGUAGES]
    tests = [f for f in code if set(Path(f).parts) & {"test", "tests", "spec", "specs"}
             or Path(f).stem.startswith("test_") or Path(f).stem.endswith("_test")]
    sources = [f for f in code if f not in tests]
    docs = [d for d in scan["documents"] if d["path"] in project_files]
    root_candidates = lambda values, hints: sorted(set(hints + [Path(v).parts[0] if len(Path(v).parts) > 1 else "." for v in values]))
    schemas = [s for s in scan["schema_sources"] if s["path"] in project_files]
    unknown = lambda detail: {"provenance": "UNKNOWN", "verification": "NEEDS_VERIFICATION", "next": detail}
    return {
        "repository": str(root), "head": scan["head"], "worktree_status": scan["worktree_status"],
        "configuration": settings, "coverage": scan["coverage"],
        "instructions_to_read": instructions,
        "missing_context_files": [f for f in instructions if not local_path(root, f).is_file()],
        "root_entries": sorted(set(Path(f).parts[0] for f in project_files)),
        "source_candidates": sources, "source_root_candidates": root_candidates(sources, effective["source_roots"]),
        "test_candidates": tests, "test_root_candidates": root_candidates(tests, effective["test_roots"]),
        "documentation": docs,
        "documentation_root_candidates": root_candidates([d["path"] for d in docs], effective["documentation_roots"]),
        "stack": {"provenance": "OBSERVED", "languages": sorted({LANGUAGES[Path(f).suffix] for f in code}),
                  "manifests_to_read": [f for f in project_files if Path(f).name in MANIFESTS]},
        "persistence": {"provenance": "OBSERVED" if schemas else "UNKNOWN", "schema_candidates": schemas,
                        "next": "Inspect dependencies and storage access; no schema file does not prove no persistence."},
        "architecture": unknown("Inspect imports, build wiring, accepted decisions and ownership; repetition is not approval."),
        "terminology": unknown("Read existing definitions and compare public types/behavior."),
        "documentation_conventions": {**unknown("Read authoritative instructions and compare actual documents."),
                                      "observed_header_fields": sorted({k for d in docs for k in d["metadata"]})},
        "canonical_locations": {"provenance": "CONFIGURED" if effective["canonical_locations"] else "UNKNOWN",
                                "values": effective["canonical_locations"]},
        "excluded": scan["excluded"] + [{"path": f, "reason": "configured exclusion"} for f in scan["files"] if excluded(f, effective)],
        "completion": "CANDIDATES_ONLY: agent must finish ordered semantic discovery before workflow execution",
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=Path.cwd())
    parser.add_argument("--config")
    args = parser.parse_args()
    try:
        print(json.dumps(discover(repository_root(args.root), args.config), ensure_ascii=True, indent=2, sort_keys=True))
        return 0
    except (OSError, ValueError, subprocess.CalledProcessError) as exc:
        print(json.dumps({"error": str(exc)}), file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
