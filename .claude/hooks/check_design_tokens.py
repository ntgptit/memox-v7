"""PostToolUse hook: design-token check for the one file that was just edited.

The full guard (``guard/run.py check``) runs 66 rules over the whole tree and
is the real gate — but it runs at DoD/CI time, after the code is written. This
hook closes that latency gap: after every Edit/Write of a Dart file in a UI
scope it applies just the design-token regex rules to that single file, in
milliseconds, and reports violations back into the same working turn.

It reads the patterns from the registry YAML rather than duplicating them, so
the hook and the guard cannot drift apart.

Exit codes: 0 = clean or out of scope; 2 = violations (stderr is fed back to
the model). Any environment problem (missing yaml, unreadable registry) exits
0 — the hook is an accelerant, not the gate; CI still catches everything.
"""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

_REPO_ROOT = Path(__file__).resolve().parents[2]
_RULES_FILE = (
    _REPO_ROOT
    / "code-verification-guard-v2"
    / "registries"
    / "projects"
    / "memox-v7"
    / "rules"
    / "memox-design-token-rules.yaml"
)

# Mirrors the `ui_surfaces` scope in registries/projects/memox-v7/config/scopes.yaml.
_SCOPE_PATTERNS = (
    re.compile(r"^lib/features/[^/]+/presentation/.+\.dart$"),
    re.compile(r"^lib/shared/.+\.dart$"),
)
_GENERATED_SUFFIXES = (".g.dart", ".freezed.dart")


def _edited_file() -> Path | None:
    try:
        payload = json.load(sys.stdin)
    except (json.JSONDecodeError, ValueError):
        return None

    tool_input = payload.get("tool_input") or {}
    tool_response = payload.get("tool_response") or {}
    raw = tool_input.get("file_path") or tool_response.get("filePath")
    if not raw:
        return None
    return Path(raw)


def _in_scope(file_path: Path) -> bool:
    try:
        relative = file_path.resolve().relative_to(_REPO_ROOT).as_posix()
    except ValueError:
        return False
    if relative.endswith(_GENERATED_SUFFIXES):
        return False
    return any(pattern.match(relative) for pattern in _SCOPE_PATTERNS)


def _design_token_rules() -> list[dict]:
    import yaml

    registry = yaml.safe_load(_RULES_FILE.read_text(encoding="utf-8"))
    return [
        rule
        for rule in registry.get("rules", [])
        if rule.get("enabled") and rule.get("type") == "regex"
    ]


def main() -> int:
    file_path = _edited_file()
    if file_path is None or not _in_scope(file_path) or not file_path.exists():
        return 0

    try:
        rules = _design_token_rules()
        lines = file_path.read_text(encoding="utf-8").splitlines()
    except Exception:  # noqa: BLE001 — the hook must never block on env issues
        return 0

    findings: list[str] = []
    for rule in rules:
        compiled = [re.compile(p) for p in rule.get("patterns", [])]
        message = " ".join(str(rule.get("message", "")).split())
        for line_number, line in enumerate(lines, start=1):
            if any(pattern.search(line) for pattern in compiled):
                findings.append(
                    f"[{rule['id']}] {file_path}:{line_number}\n"
                    f"  {line.strip()}\n"
                    f"  {message}"
                )

    if not findings:
        return 0

    print(
        "Design-token check failed for the file just edited "
        "(same rules as the CI guard):\n\n" + "\n\n".join(findings),
        file=sys.stderr,
    )
    return 2


if __name__ == "__main__":
    sys.exit(main())
