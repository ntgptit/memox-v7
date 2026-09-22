#!/usr/bin/env python3
"""Read-only, deterministic inventory of Git-visible documentation and sources."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import subprocess
import sys
from pathlib import Path


def git(root: Path, *args: str) -> str:
    return subprocess.run(
        ["git", "-C", str(root), *args], check=True, capture_output=True,
        encoding="utf-8",
    ).stdout


def repository_root(path: Path) -> Path:
    root = path.resolve()
    if not root.is_dir():
        raise ValueError("--root must be an existing directory")
    try:
        actual = Path(git(root, "rev-parse", "--show-toplevel").strip()).resolve()
    except (OSError, subprocess.CalledProcessError):
        return root
    if root != actual:
        raise ValueError("--root must name the repository root")
    return root


def visible_files(root: Path) -> list[str]:
    try:
        names = git(root, "ls-files", "-z", "--cached", "--others", "--exclude-standard")
        return sorted(set(filter(None, names.split("\0"))))
    except (OSError, subprocess.CalledProcessError):
        names = []
        for folder, directories, files in os.walk(root, followlinks=False):
            directories[:] = sorted(d for d in directories if d not in FALLBACK_EXCLUDES
                                    and not (Path(folder) / d).is_symlink())
            names.extend((Path(folder) / f).relative_to(root).as_posix() for f in files)
        return sorted(names)


FALLBACK_EXCLUDES = {".git", "node_modules", ".venv", "venv", "__pycache__", "build", "dist", "target"}
DOCUMENT_SUFFIXES = {".md", ".mdx", ".rst", ".adoc"}
SCHEMA_SUFFIXES = {".drift", ".sql", ".prisma"}


def without_fences(text: str) -> str:
    """Preserve line numbers while hiding fenced examples and their links."""
    lines = []
    fence = ""
    for line in text.splitlines():
        match = re.match(r"^\s{0,3}(`{3,}|~{3,})", line)
        if not fence and match:
            fence = match[1]
            lines.append("")
            continue
        if fence:
            if re.match(r"^\s{0,3}" + re.escape(fence[0]) +
                        "{" + str(len(fence)) + r",}\s*$", line):
                fence = ""
            lines.append("")
            continue
        lines.append(line)
    return "\n".join(lines)


def metadata(text: str) -> dict[str, str]:
    # Only the opening header, not metadata belonging to later AD/UC sections.
    opening = re.split(r"^#{1,6} ", text, maxsplit=2, flags=re.MULTILINE)
    body = opening[1] if len(opening) > 1 else ""
    return dict(re.findall(r"^\|\s*\*\*([^*]+)\*\*\s*\|\s*(.*?)\s*\|\s*$",
                           body, re.MULTILINE))


def inventory(root: Path) -> dict:
    files = []
    documents = []
    folders = set()
    schemas = []
    excluded = []
    for name in visible_files(root):
        path = root / name
        if path.is_symlink() or not path.resolve().is_relative_to(root):
            excluded.append({"path": name, "reason": "symlink or outside root"})
            continue
        if not path.is_file():
            excluded.append({"path": name, "reason": "deleted or submodule; inspect separately"})
            continue
        files.append(name)
        folders.update(p.as_posix() for p in Path(name).parents if p != Path("."))
        if path.suffix.lower() not in DOCUMENT_SUFFIXES | SCHEMA_SUFFIXES:
            continue
        raw = path.read_bytes()
        digest = hashlib.sha256(raw).hexdigest()
        if path.suffix.lower() in SCHEMA_SUFFIXES:
            schemas.append({"path": name, "sha256": digest})
            continue
        text = raw.decode("utf-8-sig")
        prose = without_fences(text)
        documents.append({
            "path": name, "sha256": digest, "metadata": metadata(prose),
            "headings": [{"line": i, "text": match[1]} for i, line in
                         enumerate(prose.splitlines(), 1)
                         if (match := re.match(r"^#{1,6}\s+(.+?)\s*#*\s*$", line))],
            "mermaid_lines": [i for i, line in enumerate(text.splitlines(), 1)
                              if re.match(r"^\s*(`{3,}|~{3,})mermaid\s*$", line)],
        })
    try:
        head = git(root, "rev-parse", "HEAD").strip()
    except (OSError, subprocess.CalledProcessError):
        head = None
    try:
        status = git(root, "status", "--porcelain=v1", "--untracked-files=all").splitlines()
        coverage = "Git tracked and non-ignored untracked files; no submodule recursion"
    except (OSError, subprocess.CalledProcessError):
        status = None
        coverage = "Non-Git filesystem scan; excludes: " + ", ".join(sorted(FALLBACK_EXCLUDES))
    return {
        "format_version": 1,
        "notice": "Generated - do not edit by hand. Inventory is not semantic verification.",
        "generator": "project-documentation/scripts/scan_docs.py",
        "head": head,
        "worktree_status": status,
        "coverage": coverage,
        "files": files, "folders": sorted(folders), "documents": documents,
        "schema_sources": schemas, "excluded": excluded,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=Path.cwd())
    args = parser.parse_args()
    try:
        payload = inventory(repository_root(args.root))
    except (OSError, ValueError, subprocess.CalledProcessError) as exc:
        print(json.dumps({"error": str(exc)}), file=sys.stderr)
        return 2
    print(json.dumps(payload, ensure_ascii=True, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
