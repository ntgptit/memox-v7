#!/usr/bin/env python3
"""Validate discovered documentation plus optional repository-specific checks."""

from __future__ import annotations

import argparse
import fnmatch
import json
import os
import re
import subprocess
import sys
from pathlib import Path
from urllib.parse import unquote, urlsplit

# An audit invocation must not create a cache beside the skill's sources.
sys.dont_write_bytecode = True
from scan_docs import DOCUMENT_SUFFIXES, metadata, repository_root, visible_files, without_fences
from repository_context import excluded, load_config, local_path, skill_payload


DESTINATION = r'(?:<([^>]+)>|([^\s()]+))(?:\s+"[^"\n]*")?'
INLINE_LINK = re.compile(r'!?\[[^\]\n]*\]\(\s*' + DESTINATION + r'\s*\)')
REFERENCE = re.compile(r'^\s{0,3}\[([^\]]+)\]:\s*' + DESTINATION, re.MULTILINE)


def heading_anchors(text: str) -> set[str]:
    anchors = set(re.findall(r'<a\s+(?:id|name)=["\']([^"\']+)', text))
    for match in re.finditer(r"^#{1,6}\s+(.+?)\s*#*\s*$", without_fences(text), re.MULTILINE):
        title = re.sub(r"<[^>]+>", "", match[1]).lower()
        base = re.sub(r"[^\w\- ]", "", title).replace(" ", "-")
        slug = base
        suffix = 0
        while slug in anchors:
            suffix += 1
            slug = f"{base}-{suffix}"
        anchors.add(slug)
    return anchors


def local_link_problem(root: Path, source: Path, destination: str) -> str | None:
    link = urlsplit(destination)
    if link.scheme or link.netloc:
        return None
    decoded = unquote(link.path)
    target = source if not decoded else source.parent / decoded
    if decoded.startswith("/"):
        target = root / decoded.lstrip("/")
    target = target.resolve()
    if not target.is_relative_to(root):
        return "local link escapes repository"
    if not target.exists():
        return "missing local target"
    if link.fragment and target.is_file() and target.suffix.lower() == ".md":
        if unquote(link.fragment) not in heading_anchors(target.read_text(encoding="utf-8-sig")):
            return "unresolved heading fragment (verify renderer for complex headings)"
    return None


def validate_file(root: Path, name: str, rules: list[dict] | tuple = ()) -> list[dict]:
    path = root / name
    text = path.read_text(encoding="utf-8-sig")
    prose = without_fences(text)
    findings = []

    def add(kind: str, message: str, line: int = 1) -> None:
        findings.append({"path": name, "line": line, "kind": kind, "message": message})

    for rule in rules:
        if not fnmatch.fnmatchcase(name, rule["glob"]):
            continue
        header = metadata(prose)
        fields = rule.get("header_fields", [])
        if fields and (list(header) != fields or not all(header.values())):
            add("header", "expected configured nonempty header fields in order")
        headings = set(re.findall(r"^#{1,6}\s+(.+?)\s*#*\s*$", prose, re.MULTILINE))
        for heading in rule.get("required_headings", []):
            if heading not in headings:
                add("heading", f"missing configured heading: {heading}")

    # Inline examples are prose about links, not active links. Preserve offsets.
    links_prose = re.sub(r"(`+)([^\n]*?)\1", lambda m: " " * len(m[0]), prose)
    definitions = {}
    for match in REFERENCE.finditer(links_prose):
        definitions[match[1].casefold()] = match[2] or match[3]
    targets = [(m.start(), m[1] or m[2]) for m in INLINE_LINK.finditer(links_prose)]
    targets.extend((m.start(), m[2] or m[3]) for m in REFERENCE.finditer(links_prose))
    for match in re.finditer(r'!?\[([^\]\n]+)\]\[([^\]\n]*)\]', links_prose):
        key = (match[2] or match[1]).casefold()
        if key not in definitions:
            add("link", "undefined reference label: " + key, prose.count("\n", 0, match.start()) + 1)
    for offset, destination in targets:
        problem = local_link_problem(root, path, destination)
        if problem:
            add("link", f"{destination}: {problem}", prose.count("\n", 0, offset) + 1)
    return findings


def supplemental(root: Path, paths: list[str], settings: dict | None = None) -> tuple[list[str], list[dict]]:
    settings = settings or load_config(root)["effective"]
    findings = [{"path": name, "line": 1, "kind": "missing", "message": "required document absent"}
                for name in settings["required_files"] if not local_path(root, name).is_file()]
    names = [name for name in visible_files(root) if not excluded(name, settings)]
    if not any(Path(name).suffix.lower() in DOCUMENT_SUFFIXES and not skill_payload(name) for name in names):
        findings.append({"path": ".", "line": 1, "kind": "coverage", "message": "no authored documentation discovered; review equivalent formats or create minimal entry in a write mode"})
    selected = []
    prefixes = []
    for item in paths:
        resolved = (root / item).resolve()
        if not resolved.is_relative_to(root):
            raise ValueError("--paths must stay inside the repository")
        if not resolved.exists():
            findings.append({"path": item, "line": 1, "kind": "missing", "message": "selected path absent"})
        prefixes.append(resolved.relative_to(root).as_posix().rstrip("/"))
    for name in names:
        path = root / name
        if path.suffix.lower() != ".md" or not path.is_file():
            continue
        if path.is_symlink() or not path.resolve().is_relative_to(root):
            continue
        if prefixes:
            if not any(p == "." or name == p or name.startswith(p + "/") for p in prefixes):
                continue
        elif skill_payload(name):
            continue
        selected.append(name)
        findings.extend(validate_file(root, name, settings["document_rules"]))
    return selected, findings


def run_checks(root: Path, checks: list[dict], execute: bool, audit: bool) -> list[dict]:
    results = []
    for check in checks:
        if not execute or (audit and not check["read_only"]):
            results.append({"name": check["name"], "status": "NEEDS_VERIFICATION",
                            "reason": "not requested" if not execute else "not declared read-only"})
            continue
        argv = [sys.executable if item == "{python}" else item for item in check["argv"]]
        try:
            completed = subprocess.run(argv, cwd=root, capture_output=True, encoding="utf-8",
                                       env={**os.environ, "PYTHONIOENCODING": "utf-8", "PYTHONDONTWRITEBYTECODE": "1"}, check=False)
            results.append({"name": check["name"], "status": "PASS" if completed.returncode == 0 else "FAIL",
                            "exit_code": completed.returncode, "stdout": completed.stdout, "stderr": completed.stderr})
        except OSError as exc:
            results.append({"name": check["name"], "status": "FAIL", "error": str(exc)})
    return results


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=Path.cwd())
    parser.add_argument("--paths", nargs="*", default=[], help="Supplemental scope only")
    parser.add_argument("--config")
    parser.add_argument("--run-checks", action="store_true")
    parser.add_argument("--audit", action="store_true")
    args = parser.parse_args()
    try:
        root = repository_root(args.root)
        config = load_config(root, args.config)
        selected, findings = supplemental(root, args.paths, config["effective"])
        checks = run_checks(root, config["effective"]["checks"], args.run_checks, args.audit)
        payload = {
            "supplemental_files": selected, "findings": findings,
            "repository_checks": checks, "configuration": config,
            "manual_review_required": "Semantics, unsupported Markdown/HTML, remote links, Mermaid, ownership, stale/duplicate/orphan claims",
        }
        print(json.dumps(payload, ensure_ascii=True, indent=2, sort_keys=True))
        return int(bool(findings) or any(check["status"] != "PASS" for check in checks))
    except (OSError, ValueError, subprocess.CalledProcessError) as exc:
        print(json.dumps({"error": str(exc)}), file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
