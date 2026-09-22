#!/usr/bin/env python3
"""Seal, install, synchronize, update, verify and inspect one generic skill release."""
from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import shutil
import sys
import tempfile
from pathlib import Path

sys.dont_write_bytecode = True
from repository_context import load_config
from scan_docs import repository_root

NAME = "project-documentation"
SOURCE_ID = "urn:agent-skill:project-documentation"
MANIFEST = "skill-manifest.json"
RECEIPT = ".installation.json"


def digest(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def normalized(data: bytes) -> bytes:
    try:
        text = data.decode("utf-8")
    except UnicodeDecodeError:
        return data
    if "\0" in text:
        return data
    return text.replace("\r\n", "\n").encode("utf-8")


def json_bytes(value: object) -> bytes:
    return (json.dumps(value, ensure_ascii=True, indent=2, sort_keys=True) + "\n").encode("utf-8")


def no_links(path: Path) -> Path:
    absolute = path.absolute()
    for part in (absolute, *absolute.parents):
        if part.is_symlink() or (hasattr(part, "is_junction") and part.is_junction()):
            raise ValueError(f"symlink/junction not supported for managed payload: {part}")
    return absolute.resolve()


def payload(root: Path) -> dict[str, str]:
    root = no_links(root)
    if not (root / "SKILL.md").is_file():
        raise ValueError(f"missing SKILL.md: {root}")
    entry = (root / "SKILL.md").read_text(encoding="utf-8-sig")
    if not re.match(r"\A---\s*\n", entry) or not re.search(r"^name:\s*" + NAME + r"\s*$", entry, re.MULTILINE):
        raise ValueError("SKILL.md name must match manifest identity")
    files = {}
    for path in sorted(root.rglob("*")):
        relative = path.relative_to(root)
        if "__pycache__" in relative.parts or path.suffix == ".pyc":
            continue
        no_links(path)
        if not path.is_file() or relative.as_posix() in {MANIFEST, RECEIPT}:
            continue
        files[relative.as_posix()] = digest(normalized(path.read_bytes()))
    return files


def version_tuple(value: str) -> tuple[int, int, int]:
    if not re.fullmatch(r"(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)", value):
        raise ValueError("version must be a stable major.minor.patch release")
    return tuple(map(int, value.split(".")))


def read_manifest(root: Path) -> dict:
    data = json.loads((root / MANIFEST).read_text(encoding="utf-8-sig"))
    if not isinstance(data, dict) or set(data) != {"format_version", "name", "version", "source_id", "files", "digest"}:
        raise ValueError(f"invalid manifest schema: {root}")
    if data["format_version"] != 1 or data["name"] != NAME or not isinstance(data["source_id"], str) or not data["source_id"]:
        raise ValueError("invalid manifest identity")
    version_tuple(data["version"])
    if not isinstance(data["files"], dict) or not data["files"]:
        raise ValueError("manifest needs file hashes")
    for path, file_hash in data["files"].items():
        if not isinstance(path, str) or Path(path).is_absolute() or ".." in Path(path).parts or "\\" in path:
            raise ValueError("invalid manifest payload path")
        if not isinstance(file_hash, str) or not re.fullmatch(r"[a-f0-9]{64}", file_hash):
            raise ValueError("invalid file hash")
    if data["digest"] != digest(json_bytes(data["files"])):
        raise ValueError("manifest aggregate hash mismatch")
    return data


def identity(data: dict) -> dict:
    return {key: data[key] for key in ("name", "version", "source_id", "digest")}


def inspect_copy(root: Path) -> dict:
    result = {"path": str(root.resolve()), "status": "MISSING"}
    if not root.exists():
        return result
    try:
        no_links(root)
        manifest = read_manifest(root)
        result.update(identity(manifest))
        actual = payload(root)
        changes = [key for key in sorted(set(actual) | set(manifest["files"]))
                   if actual.get(key) != manifest["files"].get(key)]
        result.update(status="DRIFT" if changes else "VALID", changed_files=changes)
        if (root / RECEIPT).exists():
            receipt = json.loads((root / RECEIPT).read_text(encoding="utf-8-sig"))
            if not isinstance(receipt, dict) or receipt.get("release") != identity(manifest) or not isinstance(receipt.get("canonical_source"), str) or not receipt["canonical_source"] or receipt.get("scope") not in {"global", "repository"}:
                raise ValueError("receipt release/provenance mismatch")
            result.update(scope=receipt.get("scope"), canonical_source=receipt["canonical_source"], managed=True)
            return result
        result.update(scope="canonical", canonical_source=str(root.resolve()), managed=False)
    except (OSError, ValueError, TypeError) as exc:
        result.update(status="INVALID", error=str(exc))
    return result


def seal(source: Path, version: str) -> dict:
    source = no_links(source)
    version_tuple(version)
    if (source / RECEIPT).exists():
        raise ValueError("installed copies cannot author releases; edit canonical source")
    files = payload(source)
    manifest = {"format_version": 1, "name": NAME, "version": version,
                "source_id": SOURCE_ID, "files": files, "digest": digest(json_bytes(files))}
    if (source / MANIFEST).exists():
        old = read_manifest(source)
        if old["source_id"] != SOURCE_ID:
            raise ValueError("foreign source authority")
        if old == manifest:
            return inspect_copy(source)
        if version_tuple(version) <= version_tuple(old["version"]):
            raise ValueError("changed releases require a strictly greater version")
    (source / MANIFEST).write_bytes(json_bytes(manifest))
    return inspect_copy(source)


def pin_errors(pin: dict, candidate: dict) -> list[str]:
    return [f"pin {key}: expected {value}, got {candidate.get(key)}"
            for key, value in pin.items() if candidate.get(key) != value]


def remove_stage(path: Path, parent: Path) -> None:
    checked = no_links(path)
    boundary = no_links(parent)
    if checked.parent != boundary or not checked.name.startswith(f".{NAME}-"):
        raise ValueError("temporary cleanup path outside managed parent")
    if checked.exists():
        shutil.rmtree(checked)


def distribute(source: Path, destination: Path, action: str, scope: str,
               version: str | None = None, pin: dict | None = None) -> dict:
    source = no_links(source)
    destination = no_links(destination)
    if destination == source or destination.is_relative_to(source) or source.is_relative_to(destination):
        raise ValueError("source and destination must not overlap")
    candidate = inspect_copy(source)
    if candidate["status"] != "VALID":
        raise ValueError(f"source is not an intact sealed release: {candidate}")
    problems = pin_errors(pin or {}, candidate)
    if problems:
        raise ValueError("; ".join(problems))
    current = inspect_copy(destination)
    if action == "install" and destination.exists():
        raise ValueError("install refuses an existing destination")
    if action == "update" and (not destination.exists() or version != candidate["version"]):
        raise ValueError("update needs an existing copy and explicit --version matching source")
    if destination.exists():
        if current["status"] != "VALID" or not current.get("managed"):
            raise ValueError("target is modified, invalid or unmanaged; reconcile at canonical source")
        if current["source_id"] != candidate["source_id"]:
            raise ValueError("different authority; automatic reconciliation refused")
        if identity(current) == identity(candidate):
            return current
        if action != "update":
            raise ValueError("sync cannot change release; use update with an explicit version")
        if current["version"] == candidate["version"]:
            raise ValueError("same version with different bytes; author a new release")
    destination.parent.mkdir(parents=True, exist_ok=True)
    parent = no_links(destination.parent)
    stage = Path(tempfile.mkdtemp(prefix=f".{NAME}-stage-", dir=parent))
    backup = None
    try:
        manifest = read_manifest(source)
        for name in [*manifest["files"], MANIFEST]:
            target = stage / name
            if not target.resolve().is_relative_to(stage.resolve()):
                raise ValueError("payload traversal refused")
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes((source / name).read_bytes())
        (stage / RECEIPT).write_bytes(json_bytes({
            "notice": "Generated installation receipt; edit only canonical skill source.",
            "canonical_source": candidate["canonical_source"],
            "release": identity(candidate), "scope": scope,
        }))
        if inspect_copy(stage)["status"] != "VALID":
            raise ValueError("staged copy verification failed")
        if destination.exists():
            # Recheck after staging to avoid overwriting a concurrently edited copy.
            if inspect_copy(destination) != current:
                raise ValueError("destination changed during install/update")
            backup = Path(tempfile.mkdtemp(prefix=f".{NAME}-backup-", dir=parent))
            backup.rmdir()
            destination.rename(backup)
        try:
            stage.rename(destination)
        except OSError:
            if backup is not None:
                backup.rename(destination)
                backup = None
            raise
        if backup is not None:
            remove_stage(backup, parent)
        return inspect_copy(destination)
    finally:
        if stage.exists():
            remove_stage(stage, parent)


def global_root() -> Path:
    return Path.home() / ".agents" / "skills"


def repo_skill(root: Path) -> Path:
    return root / ".agents" / "skills" / NAME


def inspect_active(root: Path, active: Path, user_root: Path, config: str | None = None) -> dict:
    settings = load_config(root, config)
    user_paths = {(user_root / NAME).resolve(),
                  (Path(os.environ.get("CODEX_HOME", str(Path.home() / ".codex"))) / "skills" / NAME).resolve()}
    repository_paths = {repo_skill(root).resolve()}
    cwd = Path.cwd().resolve()
    if cwd.is_relative_to(root):
        repository_paths.update(repo_skill(p).resolve() for p in (cwd, *cwd.parents) if p.is_relative_to(root))
    paths = {active.resolve()} | repository_paths | user_paths
    candidates = [inspect_copy(p) for p in sorted(paths, key=str) if p.exists() or p == active.resolve()]
    chosen = inspect_copy(active)
    chosen["role"] = "managed copy" if chosen.get("managed") else "canonical source"
    chosen["scope"] = "explicit"
    if active.resolve() in repository_paths:
        chosen["scope"] = "repository"
    if active.resolve() in user_paths:
        chosen["scope"] = "global"
    errors = pin_errors(settings["effective"]["pin"], chosen)
    conflicts = [c for c in candidates if c["path"] != chosen["path"] and
                 (c["status"] != "VALID" or any(c.get(k) != chosen.get(k) for k in ("version", "digest", "source_id")))]
    return {"active": chosen, "selection": "explicit --active; host selection is not inferred",
            "repository_config": settings, "candidates": candidates, "conflicts": conflicts,
            "pin_errors": errors,
            "ok": chosen["status"] == "VALID" and not errors and (bool(settings["effective"]["pin"]) or not conflicts)}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("action", choices=["release", "install", "sync", "update", "verify", "inspect"])
    parser.add_argument("--source", type=Path)
    parser.add_argument("--active", type=Path)
    parser.add_argument("--root", type=Path, default=Path.cwd())
    parser.add_argument("--global-root", type=Path, default=global_root())
    parser.add_argument("--scope", choices=["global", "repository"])
    parser.add_argument("--version")
    parser.add_argument("--config")
    args = parser.parse_args()
    try:
        if args.action == "release":
            if args.source is None or args.version is None:
                raise ValueError("release requires --source and --version")
            result = seal(args.source, args.version)
        elif args.action == "inspect":
            if args.active is None:
                raise ValueError("inspect requires the actually loaded --active directory")
            result = inspect_active(repository_root(args.root), args.active, args.global_root, args.config)
        elif args.action == "verify":
            if args.source is None:
                raise ValueError("verify requires explicit --source authority")
            root = repository_root(args.root)
            copies = {"canonical": inspect_copy(args.source), "global": inspect_copy(args.global_root / NAME),
                      "repository": inspect_copy(repo_skill(root))}
            reference = copies["canonical"]
            errors = pin_errors(load_config(root, args.config)["effective"]["pin"], copies["repository"])
            result = {"copies": copies, "pin_errors": errors,
                      "ok": not errors and all(c["status"] == "VALID" and all(c.get(k) == reference.get(k) for k in
                                               ("version", "digest", "source_id")) for c in copies.values())}
        else:
            if args.source is None or args.scope is None:
                raise ValueError("install/sync/update require --source and --scope")
            pin = {}
            destination = args.global_root / NAME
            if args.scope == "repository":
                root = repository_root(args.root)
                destination = repo_skill(root)
                pin = load_config(root, args.config)["effective"]["pin"]
            result = distribute(args.source, destination, args.action, args.scope, args.version, pin)
        print(json.dumps(result, ensure_ascii=True, indent=2, sort_keys=True))
        return 0 if result.get("ok", result.get("status") == "VALID") else 1
    except (OSError, ValueError, TypeError) as exc:
        print(json.dumps({"error": str(exc)}), file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
