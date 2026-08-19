#!/usr/bin/env python3
"""Build one immutable, fail-safe verification plan for a change set.

The plan grows monotonically: every rule may add checks, tests or downstream
features, but no rule can remove work selected by an earlier rule. Unknown and
high-risk paths promote the plan to the complete non-golden host suite.
"""

from __future__ import annotations

import argparse
import json
import posixpath
import re
import subprocess
import sys
from dataclasses import asdict, dataclass
from pathlib import Path, PurePosixPath
from typing import Iterable


SCRIPT_DIR = Path(__file__).resolve().parent
DEFAULT_IMPACT_MAP = SCRIPT_DIR / "verification_impact_map.json"
PROMPT_PREFIX = "docs/prompt/"
FEATURE_SOURCE_PREFIX = "lib/features/"
FEATURE_TEST_PREFIX = "test/features/"
LAYER_ORDER = ("domain", "data", "presentation")
PUBLIC_DOMAIN_BUCKETS = {
    "entities",
    "failures",
    "models",
    "repositories",
    "schedulers",
    "modes",
}


def normalize_path(raw: str) -> str:
    """Normalize separators without stripping a leading dot from `.github`."""
    value = raw.lstrip("\ufeff").rstrip("\r\n").replace("\\", "/")
    while value.startswith("./"):
        value = value[2:]
    return str(PurePosixPath(value)) if value else ""


@dataclass(frozen=True)
class VerificationPlan:
    changed_paths: tuple[str, ...]
    affected_features: tuple[str, ...]
    affected_layers: tuple[str, ...]
    reasons: tuple[str, ...]
    unmatched_paths: tuple[str, ...]
    test_files: tuple[str, ...]
    local_test_targets: tuple[str, ...]
    changed_count: int
    estimated_test_weight: int
    shard_count: int
    risk: str
    has_prompt_changes: bool
    prompt_only: bool
    docs_only: bool
    code_required: bool
    needs_contracts: bool
    needs_static: bool
    needs_host_tests: bool
    needs_widgetbook: bool
    full_suite: bool

    @property
    def shard_matrix(self) -> dict[str, list[dict[str, int]]]:
        total = max(1, self.shard_count)
        return {
            "include": [
                {"shard": index, "label": index + 1, "total": total}
                for index in range(total)
            ]
        }

    def to_json_dict(self) -> dict[str, object]:
        payload = asdict(self)
        payload["changed_paths"] = list(self.changed_paths)
        payload["affected_features"] = list(self.affected_features)
        payload["affected_layers"] = list(self.affected_layers)
        payload["reasons"] = list(self.reasons)
        payload["unmatched_paths"] = list(self.unmatched_paths)
        payload["test_files"] = list(self.test_files)
        payload["local_test_targets"] = list(self.local_test_targets)
        payload["shard_matrix"] = self.shard_matrix
        return payload


@dataclass(frozen=True)
class ImpactMap:
    feature_dependencies: dict[str, tuple[str, ...]]
    database_query_features: dict[str, tuple[str, ...]]
    full_scope_prefixes: tuple[str, ...]
    full_scope_files: frozenset[str]
    one_shard_max_weight: int
    two_shard_max_weight: int

    @classmethod
    def load(cls, path: Path = DEFAULT_IMPACT_MAP) -> "ImpactMap":
        raw = json.loads(path.read_text(encoding="utf-8"))
        if raw.get("version") != 1:
            raise ValueError("unsupported verification impact-map version")
        thresholds = raw["shard_weight_thresholds"]
        return cls(
            feature_dependencies={
                key: tuple(value)
                for key, value in raw["feature_dependencies"].items()
            },
            database_query_features={
                key: tuple(value)
                for key, value in raw["database_query_features"].items()
            },
            full_scope_prefixes=tuple(raw["full_scope_prefixes"]),
            full_scope_files=frozenset(raw["full_scope_files"]),
            one_shard_max_weight=int(thresholds["one"]),
            two_shard_max_weight=int(thresholds["two"]),
        )


class VerificationPlanBuilder:
    """Mutable accumulator whose only public operations widen verification."""

    def __init__(self, root: Path, impact_map: ImpactMap) -> None:
        self.root = root.resolve()
        self.impact_map = impact_map
        self.changed_paths: set[str] = set()
        self.features: set[str] = set()
        self.layers: set[str] = set()
        self.reasons: set[str] = set()
        self.unmatched_paths: set[str] = set()
        self.test_prefixes: set[str] = set()
        self.exact_test_files: set[str] = set()
        self.has_prompt_changes = False
        self.has_docs_changes = False
        self.has_code_changes = False
        self.requires_host_coverage = False
        self.needs_widgetbook = False
        self.full_suite = False

    def add_reason(self, reason: str) -> None:
        self.reasons.add(reason)

    def require_full(self, reason: str, *, unmatched_path: str | None = None) -> None:
        self.full_suite = True
        self.has_code_changes = True
        self.requires_host_coverage = True
        self.needs_widgetbook = True
        self.add_reason(reason)
        if unmatched_path:
            self.unmatched_paths.add(unmatched_path)

    def require_feature_layers(
        self, feature: str, layers: Iterable[str], reason: str
    ) -> None:
        normalized_layers = set(layers)
        self.has_code_changes = True
        self.requires_host_coverage = True
        self.features.add(feature)
        self.layers.update(normalized_layers)
        self.add_reason(reason)
        for layer in normalized_layers:
            self.test_prefixes.add(f"test/features/{feature}/{layer}/")
        if "presentation" in normalized_layers:
            self.needs_widgetbook = True

    def require_downstream(self, feature: str, reason: str) -> None:
        pending = [feature]
        visited: set[str] = set()
        while pending:
            current = pending.pop()
            if current in visited:
                continue
            visited.add(current)
            for dependent in self.impact_map.feature_dependencies.get(current, ()):
                if dependent not in visited:
                    pending.append(dependent)
        for affected in visited:
            self.require_feature_layers(affected, LAYER_ORDER, reason)

    def require_all_presentation(self, reason: str) -> None:
        self.has_code_changes = True
        self.requires_host_coverage = True
        self.layers.add("presentation")
        self.test_prefixes.update(
            {"test/features/", "test/app/", "test/shared/"}
        )
        self.needs_widgetbook = True
        self.add_reason(reason)

    def require_test_path(self, path: str, reason: str) -> None:
        self.has_code_changes = True
        self.requires_host_coverage = True
        self.add_reason(reason)
        if path.endswith("_test.dart") and (self.root / path).is_file():
            if is_golden_only_test(self.root / path):
                self.require_all_presentation(
                    "golden-only change requires non-golden presentation surrogates"
                )
                return
            self.exact_test_files.add(path)
            return
        parts = path.split("/")
        if len(parts) >= 4 and parts[:2] == ["test", "features"]:
            feature = parts[2]
            layer = parts[3] if parts[3] in LAYER_ORDER else ""
            if layer:
                self.require_feature_layers(feature, (layer,), reason)
                return
        if path.startswith("test/app/"):
            self.test_prefixes.add("test/app/")
            return
        if path.startswith("test/core/"):
            segment = parts[2] if len(parts) > 2 else ""
            self.test_prefixes.add(f"test/core/{segment}/" if segment else "test/core/")
            return
        if path.startswith("test/shared/"):
            self.test_prefixes.add("test/shared/")
            self.needs_widgetbook = True
            return
        self.require_full("unrecognised test support path", unmatched_path=path)

    def classify_path(self, path: str) -> None:
        self.changed_paths.add(path)

        if path.startswith(PROMPT_PREFIX):
            self.has_prompt_changes = True
            self.has_docs_changes = True
            self.add_reason("prompt delivery contract changed")
            return

        if path.startswith("docs/") or path in {"AGENTS.md", "CLAUDE.md", "README.md"}:
            self.has_docs_changes = True
            self.add_reason("documentation contract changed")
            return

        if path.startswith(".claude/") and path.endswith(".md"):
            self.has_docs_changes = True
            self.add_reason("agent workflow documentation changed")
            return

        if path in self.impact_map.full_scope_files or any(
            path.startswith(prefix) for prefix in self.impact_map.full_scope_prefixes
        ):
            self.require_full("high-risk or verification-infrastructure path changed")
            return

        if path.startswith("widgetbook/"):
            self.has_code_changes = True
            self.needs_widgetbook = True
            self.add_reason("Widgetbook catalog changed")
            return

        if path.startswith("test/"):
            self.require_test_path(path, "test or test support changed")
            return

        if path.startswith(FEATURE_SOURCE_PREFIX):
            self._classify_feature_source(path)
            return

        if path.startswith("lib/core/database/queries/") and path.endswith(".drift"):
            query_name = Path(path).stem
            features = self.impact_map.database_query_features.get(query_name)
            if not features:
                self.require_full("database query has no declared feature owner", unmatched_path=path)
                return
            for feature in features:
                self.require_downstream(feature, "database query contract changed")
            # Drift generation is gitignored, so a source-level Dart import
            # closure cannot see tests consuming the generated DAO methods.
            # These are the repository's cross-feature database contract
            # surfaces and must be added declaratively for every query change.
            self.test_prefixes.update({"test/database/", "test/integration/"})
            self.add_reason("database query cross-surface contracts selected")
            return

        if path.startswith("lib/core/database/"):
            self.require_full("database schema, migration or shared database path changed")
            return

        if path.startswith("lib/core/") or path.startswith("lib/main"):
            self.require_full("shared core or application entrypoint changed")
            return

        if path.startswith("lib/"):
            self.require_full("unrecognised production source path", unmatched_path=path)
            return

        if path.endswith(".md"):
            self.has_docs_changes = True
            self.add_reason("markdown documentation changed")
            return

        self.require_full("unrecognised changed path", unmatched_path=path)

    def _classify_feature_source(self, path: str) -> None:
        parts = path.split("/")
        if len(parts) < 5:
            self.require_full("feature source path has no recognised layer", unmatched_path=path)
            return
        feature, layer = parts[2], parts[3]
        if layer == "domain":
            bucket = parts[4] if len(parts) > 4 else ""
            if bucket in PUBLIC_DOMAIN_BUCKETS:
                self.require_downstream(feature, "public domain contract changed")
                return
            if bucket == "usecases":
                self.require_feature_layers(
                    feature,
                    ("domain", "presentation"),
                    "feature use case changed",
                )
                return
            self.require_feature_layers(
                feature, LAYER_ORDER, "domain implementation changed"
            )
            return
        if layer == "data":
            self.require_feature_layers(feature, ("data",), "feature data layer changed")
            return
        if layer == "presentation":
            self.require_feature_layers(
                feature, ("presentation",), "feature presentation changed"
            )
            return
        if layer == "di":
            self.require_feature_layers(
                feature, ("presentation",), "feature dependency wiring changed"
            )
            self.test_prefixes.add("test/app/")
            return
        self.require_full("feature source path has unknown layer", unmatched_path=path)

    def seal(self) -> VerificationPlan:
        runnable_tests = discover_tests(self.root)
        consumer_tests = discover_test_consumers(
            self.root,
            {path for path in self.changed_paths if path.endswith(".dart")},
            set(runnable_tests),
        )
        if consumer_tests:
            self.exact_test_files.update(consumer_tests)
            self.add_reason("import-derived transitive test consumers selected")
        if self.full_suite:
            selected = runnable_tests
        else:
            selected = {
                path: weight
                for path, weight in runnable_tests.items()
                if path in self.exact_test_files
                or any(path.startswith(prefix) for prefix in self.test_prefixes)
            }

        code_required = self.has_code_changes or self.full_suite
        needs_host_tests = code_required and bool(selected)
        if self.requires_host_coverage and not needs_host_tests:
            self.require_full("code change selected no executable verification")
            selected = runnable_tests
            needs_host_tests = bool(selected)

        estimated_weight = sum(selected.values())
        local_targets = compress_test_targets(set(selected), set(runnable_tests))
        shard_count = choose_shard_count(
            estimated_weight,
            len(selected),
            self.impact_map.one_shard_max_weight,
            self.impact_map.two_shard_max_weight,
        ) if needs_host_tests else 0

        changed = tuple(sorted(self.changed_paths))
        prompt_only = bool(changed) and all(
            path.startswith(PROMPT_PREFIX) for path in changed
        )
        docs_only = bool(changed) and not code_required
        risk = "full" if self.full_suite else "targeted" if code_required else "docs"
        return VerificationPlan(
            changed_paths=changed,
            affected_features=tuple(sorted(self.features)),
            affected_layers=tuple(sorted(self.layers)),
            reasons=tuple(sorted(self.reasons)),
            unmatched_paths=tuple(sorted(self.unmatched_paths)),
            test_files=tuple(sorted(selected)),
            local_test_targets=local_targets,
            changed_count=len(changed),
            estimated_test_weight=estimated_weight,
            shard_count=shard_count,
            risk=risk,
            has_prompt_changes=self.has_prompt_changes,
            prompt_only=prompt_only,
            docs_only=docs_only,
            code_required=code_required,
            needs_contracts=True,
            needs_static=code_required,
            needs_host_tests=needs_host_tests,
            needs_widgetbook=self.needs_widgetbook,
            full_suite=self.full_suite,
        )


def choose_shard_count(
    weight: int,
    file_count: int,
    one_shard_max_weight: int,
    two_shard_max_weight: int,
) -> int:
    if file_count <= 0:
        return 0
    if weight <= one_shard_max_weight or file_count == 1:
        return 1
    if weight <= two_shard_max_weight or file_count < 5:
        return min(2, file_count)
    return min(5, file_count)


def compress_test_targets(
    selected_files: set[str], all_test_files: set[str]
) -> tuple[str, ...]:
    """Compress an exact plan to safe local CLI targets.

    GitHub shards need exact files. Windows' command line cannot carry hundreds
    of them, so the local gate replaces a complete selected subtree with that
    directory while proving no unselected tracked test lives below it.
    """
    if not selected_files:
        return ()
    candidates: set[str] = set()
    for path in selected_files:
        for parent in PurePosixPath(path).parents:
            value = parent.as_posix()
            if value == "." or not value.startswith("test"):
                continue
            candidates.add(value)

    uncovered = set(selected_files)
    targets: list[str] = []
    for candidate in sorted(candidates, key=lambda value: (value.count("/"), value)):
        prefix = candidate + "/"
        tracked_below = {path for path in all_test_files if path.startswith(prefix)}
        if not tracked_below or not tracked_below <= selected_files:
            continue
        if any(
            candidate == chosen or candidate.startswith(chosen + "/")
            for chosen in targets
        ):
            continue
        targets.append(candidate)
        uncovered.difference_update(tracked_below)
    targets.extend(sorted(uncovered))
    return tuple(sorted(targets))


def discover_worktree_dart_files(root: Path) -> set[str]:
    """Return tracked plus existing untracked Dart files used by local gates."""
    paths: set[str] = set()
    for arguments in (
        ["ls-files", "-z", "--", "lib", "test"],
        ["ls-files", "--others", "--exclude-standard", "-z", "--", "lib", "test"],
    ):
        completed = subprocess.run(
            ["git", "-C", str(root), *arguments],
            check=True,
            capture_output=True,
        )
        paths.update(
            normalize_path(raw.decode("utf-8"))
            for raw in completed.stdout.split(b"\0")
            if raw and raw.decode("utf-8").endswith(".dart")
        )
    return {path for path in paths if (root / path).is_file()}


def is_golden_only_test(path: Path) -> bool:
    """Whether CI's `--exclude-tags golden` excludes the whole test file."""
    if not path.is_file():
        return False
    text = path.read_text(encoding="utf-8")
    prefix = text[:512]
    return bool(
        path.name.endswith("_golden_test.dart")
        or re.search(
            r"\A\s*@Tags\s*\([\s\S]*?['\"]golden['\"][\s\S]*?\)\s*(?:library\s*;)?",
            prefix,
        )
    )


def discover_tests(root: Path) -> dict[str, int]:
    paths = sorted(
        path
        for path in discover_worktree_dart_files(root)
        if path.startswith("test/")
        and path.endswith("_test.dart")
        and not is_golden_only_test(root / path)
    )
    declaration = re.compile(r"\b(?:testWidgets|testGoldens|test)\s*\(")
    return {
        path: max(1, len(declaration.findall((root / path).read_text(encoding="utf-8"))))
        for path in paths
    }


def _package_name(root: Path) -> str:
    pubspec = (root / "pubspec.yaml").read_text(encoding="utf-8")
    match = re.search(r"(?m)^name:\s*([A-Za-z0-9_]+)\s*$", pubspec)
    if not match:
        raise ValueError("pubspec.yaml has no package name")
    return match.group(1)


def _resolve_dart_uri(importer: str, uri: str, package_name: str) -> str | None:
    package_prefix = f"package:{package_name}/"
    if uri.startswith(package_prefix):
        return normalize_path(f"lib/{uri[len(package_prefix):]}")
    if ":" in uri:
        return None
    return normalize_path(posixpath.normpath(posixpath.join(posixpath.dirname(importer), uri)))


def discover_test_consumers(
    root: Path,
    changed_dart_paths: set[str],
    runnable_tests: set[str],
) -> set[str]:
    """Find runnable tests that transitively import a changed Dart source.

    Folder ownership remains the primary fast-path policy. This reverse import
    closure seals its blind spots: app/router tests, integration tests, and
    cross-feature harnesses are included even when they live outside the
    changed feature/layer directory.
    """
    if not changed_dart_paths:
        return set()
    dart_files = discover_worktree_dart_files(root)
    package_name = _package_name(root)
    directive = re.compile(r"\b(?:import|export|part)\s+['\"]([^'\"]+)['\"]")
    reverse: dict[str, set[str]] = {}
    for importer in dart_files:
        text = (root / importer).read_text(encoding="utf-8")
        for uri in directive.findall(text):
            dependency = _resolve_dart_uri(importer, uri, package_name)
            if dependency:
                reverse.setdefault(dependency, set()).add(importer)

    pending = list(changed_dart_paths)
    visited = set(changed_dart_paths)
    consumers: set[str] = set()
    while pending:
        dependency = pending.pop()
        for importer in reverse.get(dependency, set()):
            if importer in visited:
                continue
            visited.add(importer)
            pending.append(importer)
            if importer in runnable_tests:
                consumers.add(importer)
    return consumers


def build_plan(
    paths: Iterable[str],
    *,
    root: Path,
    impact_map: ImpactMap | None = None,
    force_full: bool = False,
) -> VerificationPlan:
    builder = VerificationPlanBuilder(root, impact_map or ImpactMap.load())
    normalized = sorted({normalize_path(path) for path in paths if normalize_path(path)})
    for path in normalized:
        builder.classify_path(path)
    if force_full or not normalized:
        reason = "manual full verification requested" if force_full else "empty change set"
        builder.require_full(reason)
    return builder.seal()


def _bool(value: bool) -> str:
    return "true" if value else "false"


def write_github_output(path: Path, plan: VerificationPlan) -> None:
    values = {
        "changed_count": str(plan.changed_count),
        "has_prompt_changes": _bool(plan.has_prompt_changes),
        "prompt_only": _bool(plan.prompt_only),
        "docs_only": _bool(plan.docs_only),
        "code_required": _bool(plan.code_required),
        "needs_contracts": _bool(plan.needs_contracts),
        "needs_static": _bool(plan.needs_static),
        "needs_host_tests": _bool(plan.needs_host_tests),
        "needs_widgetbook": _bool(plan.needs_widgetbook),
        "full_suite": _bool(plan.full_suite),
        "risk": plan.risk,
        "shard_count": str(plan.shard_count),
        "shard_matrix": json.dumps(plan.shard_matrix, separators=(",", ":")),
        "test_files_json": json.dumps(plan.test_files, separators=(",", ":")),
    }
    with path.open("a", encoding="utf-8") as output:
        for key, value in values.items():
            output.write(f"{key}={value}\n")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", type=Path, default=Path.cwd())
    parser.add_argument("--impact-map", type=Path, default=DEFAULT_IMPACT_MAP)
    parser.add_argument("--github-output", type=Path)
    parser.add_argument("--json-output", type=Path)
    parser.add_argument("--paths-file", type=Path)
    parser.add_argument("--force-full", action="store_true")
    parser.add_argument("--nul", action="store_true")
    args = parser.parse_args()

    raw = args.paths_file.read_bytes() if args.paths_file else sys.stdin.buffer.read()
    separator = b"\0" if args.nul else b"\n"
    paths = [item.decode("utf-8") for item in raw.split(separator) if item]
    plan = build_plan(
        paths,
        root=args.root.resolve(),
        impact_map=ImpactMap.load(args.impact_map),
        force_full=args.force_full,
    )
    if args.github_output:
        write_github_output(args.github_output, plan)
    payload = json.dumps(plan.to_json_dict(), ensure_ascii=False, separators=(",", ":"))
    if args.json_output:
        args.json_output.write_text(payload + "\n", encoding="utf-8")
    if not args.github_output and not args.json_output:
        print(payload)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
