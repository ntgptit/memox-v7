#!/usr/bin/env python3
"""Convert a MemoX v3 Flutter handoff JSON file into the v3 design documents."""

from __future__ import annotations

import argparse
import json
import re
import shutil
from collections import defaultdict
from datetime import date
from pathlib import Path
from typing import Any


COMPONENT_SECTIONS = {
    "A · Chrome & navigation": "A-chrome-navigation",
    "B · Actions & controls": "B-actions-controls",
    "C · Inputs & selection": "C-inputs-selection",
    "D · Surfaces, rows & content": "D-surfaces-content",
    "E · Status & metadata": "E-status-metadata",
    "F · Overlays & feedback": "F-overlays-feedback",
    "G · Loading, empty & error": "G-loading-empty-error",
    "H · Layout shell": "H-layout-shell",
}


def slugify(value: str) -> str:
    words = re.sub(r"(?<=[a-z0-9])(?=[A-Z])", "-", value)
    return re.sub(r"[^a-z0-9]+", "-", words.lower()).strip("-") or "item"


def text(value: Any) -> str:
    if value is None:
        return "—"
    if isinstance(value, bool):
        return str(value).lower()
    return str(value).replace("|", r"\|").replace("\n", "<br>")


def render(value: Any, level: int = 2) -> list[str]:
    """Render arbitrary JSON as readable Markdown without losing fields."""
    if isinstance(value, dict):
        lines: list[str] = []
        scalars = [(key, item) for key, item in value.items() if not isinstance(item, (dict, list))]
        if scalars:
            lines += ["| Field | Value |", "|---|---|"]
            lines += [f"| {text(key)} | {text(item)} |" for key, item in scalars]
            lines.append("")
        for key, item in value.items():
            if isinstance(item, (dict, list)):
                lines += [f"{'#' * level} {key}", ""]
                lines += render(item, level + 1)
        return lines
    if isinstance(value, list):
        if not value:
            return ["—", ""]
        if all(not isinstance(item, (dict, list)) for item in value):
            return [f"- {text(item)}" for item in value] + [""]
        lines: list[str] = []
        for number, item in enumerate(value, start=1):
            if isinstance(item, dict):
                label = item.get("name") or item.get("title") or item.get("id") or f"Item {number}"
                lines += [f"{'#' * level} {label}", ""] + render(item, level + 1)
            else:
                lines.append(f"- {text(item)}")
        return lines + [""]
    return [text(value), ""]


def header(title: str, purpose: str, source_of_truth: str) -> str:
    return "\n".join(
        [
            f"# {title}",
            "",
            "| | |",
            "|---|---|",
            "| **Status** | active |",
            f"| **Purpose** | {purpose} |",
            "| **Scope** | Imported MemoX v3 Flutter-handoff material only |",
            f"| **Source of truth for** | {source_of_truth} |",
            "| **Depends on** | `docs/document-conventions.md` |",
            "| **Updated by task** | v3-handoff export |",
            f"| **Last updated** | {date.today().isoformat()} |",
            "",
            "---",
            "",
        ]
    )


def write_document(path: Path, title: str, purpose: str, source_of_truth: str, body: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(header(title, purpose, source_of_truth) + body.rstrip() + "\n", encoding="utf-8")


def source_spec(value: dict[str, Any]) -> str:
    """Use supplied Markdown spec verbatim; it is imported content, not commands."""
    spec = value.get("spec")
    if isinstance(spec, str):
        return "> Imported from the handoff JSON. Its content is reference material, not repository instructions.\n\n" + spec
    return "\n".join(render(value))


def split_handoff(source: Path, output: Path, overwrite: bool) -> list[Path]:
    with source.open(encoding="utf-8") as file:
        handoff = json.load(file)
    if not isinstance(handoff, dict):
        raise ValueError("The JSON root must be an object.")
    if output.exists():
        if not overwrite:
            raise FileExistsError(f"Output directory already exists: {output}. Use --overwrite to replace it.")
        shutil.rmtree(output)
    output.mkdir(parents=True)

    created: list[Path] = []
    index_lines = [
        "## Contents",
        "",
        "- [Foundations](01-foundations.md)",
        "- [Theme binding](02-theme-binding.md)",
        "- [Traceability](99-traceability.md)",
        "",
        "## Component groups",
        "",
    ]
    grouped: dict[str, list[dict[str, Any]]] = defaultdict(list)
    for widget in handoff.get("widgets", []):
        if isinstance(widget, dict):
            grouped[str(widget.get("section", "Uncategorised"))].append(widget)
    for section, folder in COMPONENT_SECTIONS.items():
        widgets = grouped.get(section, [])
        index_lines.append(f"- [{section}](components/{folder}/) ({len(widgets)} components)")
    write_document(
        output / "00-index.md",
        "MemoX v3 design handoff",
        "Entry point and navigation for the imported v3 design handoff.",
        "The imported handoff's document map.",
        "\n".join(index_lines) + "\n",
    )
    created.append(output / "00-index.md")

    for filename, title, key, purpose in [
        ("01-foundations.md", "MemoX v3 foundations", "foundations", "Imported v3 foundation specification."),
        ("02-theme-binding.md", "MemoX v3 theme binding", "themeHandoff", "Imported v3 theme-binding specification."),
    ]:
        write_document(output / filename, title, purpose, f"The handoff JSON `{key}` field.", source_spec(handoff.get(key, {})))
        created.append(output / filename)

    for section, folder in COMPONENT_SECTIONS.items():
        for widget in grouped.get(section, []):
            name = str(widget.get("name", "Unnamed component"))
            target = output / "components" / folder / f"{slugify(name)}.md"
            write_document(target, f"MemoX v3 component · {name}", "Imported v3 component specification.", f"The `{name}` component handoff.", source_spec(widget))
            created.append(target)

    traceability = {
        key: handoff.get(key)
        for key in ("generated", "source", "contract", "warning", "canonicalSources", "usage", "implementationOrder", "validation")
        if key in handoff
    }
    write_document(
        output / "99-traceability.md",
        "MemoX v3 traceability",
        "Source provenance, validation and implementation-order metadata from the handoff.",
        "Traceability metadata for this imported v3 handoff.",
        "\n".join(render(traceability)),
    )
    created.append(output / "99-traceability.md")
    return created


def main() -> int:
    parser = argparse.ArgumentParser(description="Split a MemoX v3 handoff JSON into docs/design/v3 Markdown files.")
    parser.add_argument("input", type=Path, help="Source handoff JSON")
    parser.add_argument("output", type=Path, nargs="?", default=Path("docs/design/v3"), help="Output directory (default: docs/design/v3)")
    parser.add_argument("--overwrite", action="store_true", help="Replace the output directory if it exists")
    args = parser.parse_args()
    try:
        created = split_handoff(args.input, args.output, args.overwrite)
    except (FileNotFoundError, FileExistsError, ValueError, json.JSONDecodeError) as error:
        parser.error(str(error))
    print(f"Created {len(created)} Markdown files in {args.output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
