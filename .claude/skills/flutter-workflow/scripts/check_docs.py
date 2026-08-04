#!/usr/bin/env python3
"""Specification integrity checker.

The docs in docs/ are a contract that code is written against, and the failure
mode that matters is a reference that points at the wrong thing — BR-13 citing
"BR-36" for reset after a renumber moved reset to BR-44. Nothing catches that at
runtime; it surfaces only when a human reads it and complies.

**Why Python and not the bash it replaced.** The checks are unchanged. The bash
version ran dozens of `awk`, `grep` and `find` forks and a per-file `grep` loop
in section D — on Windows git-bash each fork costs tens of milliseconds and the
whole thing took 134 seconds. This reads every document once, in one process.
The `.sh` beside it is a thin wrapper so every caller and every doc that names
it keeps working. C1/C2 still delegate to `verify_invariants.py` unchanged.

Usage: check_docs.py [--db <path-to-sqlite-db>] [--quiet]
Exit:  0 clean, 1 problems found.
"""

from __future__ import annotations

import argparse
import re
import subprocess
import sys
from functools import lru_cache
from pathlib import Path

# --- output ---------------------------------------------------------------

_TTY = sys.stdout.isatty()
_RED = "\033[31m" if _TTY else ""
_YEL = "\033[33m" if _TTY else ""
_GRN = "\033[32m" if _TTY else ""
_DIM = "\033[2m" if _TTY else ""
_OFF = "\033[0m" if _TTY else ""

_problems = 0
_quiet = False


def _fail(title: str, detail: str) -> None:
    global _problems
    _problems += 1
    print(f"{_RED}✗{_OFF} {title}\n    {detail}")


def _warn(title: str, detail: str) -> None:
    if not _quiet:
        print(f"{_YEL}!{_OFF} {title}\n    {detail}")


def _ok(msg: str) -> None:
    if not _quiet:
        print(f"{_GRN}✓{_OFF} {msg}")


def _head(msg: str) -> None:
    print(f"\n{_DIM}── {msg} {_OFF}")


# --- file helpers ---------------------------------------------------------

_REPO = Path.cwd()


@lru_cache(maxsize=None)
def _read(path: str) -> str:
    try:
        return (_REPO / path).read_text(encoding="utf-8")
    except OSError:
        return ""


@lru_cache(maxsize=None)
def _lines(path: str) -> tuple[str, ...]:
    return tuple(_read(path).splitlines())


def _docs_md() -> list[str]:
    """Contract documents checked by this repository.

    Core specifications live directly under ``docs/``. IT scenarios are the
    one intentionally nested contract: their catalog and agent execution guide
    must receive the same header/reference checks rather than becoming an
    unguarded island of prose.
    """
    paths = set((_REPO / "docs").glob("*.md"))
    paths.update((_REPO / "docs" / "it-scenarios").glob("*.md"))
    return sorted(p.relative_to(_REPO).as_posix() for p in paths)


BR_FILE = "docs/business-rules.md"
AD_FILE = "docs/architecture.md"
UC_FILE = "docs/use-cases.md"
WBS_FILE = "docs/wbs.md"
README_FILE = "docs/README.md"
DM_FILE = "docs/data-model.md"


# --- A. Document integrity ------------------------------------------------

_DEF_RE = {
    prefix: re.compile(rf"^(\| |#{{2,4}} )({prefix}-[0-9]+)")
    for prefix in ("BR", "AD", "UC")
}


def _defined_ids(path: str, prefix: str) -> list[str]:
    """Table rows `| BR-07` and headings `### BR-15 ·`, in document order."""
    pat = _DEF_RE[prefix]
    ids: list[str] = []
    for line in _lines(path):
        m = pat.match(line)
        if m:
            ids.append(m.group(2))
    return ids


def _ref_files() -> list[str]:
    files = set(_docs_md())
    files.add("CLAUDE.md")
    skills = _REPO / ".claude" / "skills"
    if skills.is_dir():
        for p in skills.rglob("*.md"):
            posix = p.as_posix()
            if p.name == "SKILL.md" or "/references/" in posix:
                files.add(p.relative_to(_REPO).as_posix())
    return sorted(f for f in files if (_REPO / f).is_file())


_CITE_RE = re.compile(r"\b(?:BR|AD|UC)-[0-9]+")


def _check_document_integrity() -> None:
    _head("A. Document integrity")

    br_defined = _defined_ids(BR_FILE, "BR")
    ad_defined = _defined_ids(AD_FILE, "AD")
    uc_defined = _defined_ids(UC_FILE, "UC")

    # duplicates
    before = _problems
    for prefix, ids in (("BR", br_defined), ("AD", ad_defined), ("UC", uc_defined)):
        seen: set[str] = set()
        for _id in ids:
            if _id in seen:
                file = {"BR": BR_FILE, "AD": AD_FILE, "UC": UC_FILE}[prefix]
                _fail("duplicate ID definition", f"{_id} defined more than once in {file}")
            seen.add(_id)
    if _problems == before:
        _ok("no duplicate BR / AD / UC definitions")

    # dangling references
    all_defined = set(br_defined) | set(ad_defined) | set(uc_defined)
    cited: set[str] = set()
    cite_where: dict[str, list[str]] = {}
    for f in _ref_files():
        for m in _CITE_RE.finditer(_read(f)):
            cid = m.group(0)
            cited.add(cid)
            cite_where.setdefault(cid, [])
            if f not in cite_where[cid]:
                cite_where[cid].append(f)
    dangling = sorted(cited - all_defined)
    if dangling:
        for _id in dangling:
            where = " ".join(cite_where.get(_id, []))
            _fail("reference to an ID that does not exist", f"{_id} cited in: {where} ")
    else:
        _ok(f"every cited BR / AD / UC id resolves ({len(cited)} distinct ids)")

    # numbering gaps (warn)
    for prefix, ids in (("BR", br_defined), ("AD", ad_defined), ("UC", uc_defined)):
        nums = sorted({int(re.search(r"[0-9]+", i).group()) for i in ids})
        gaps: list[int] = []
        prev = None
        for n in nums:
            if prev is not None and n != prev + 1:
                gaps.extend(range(prev + 1, n))
            prev = n
        if gaps:
            _warn(
                f"numbering gap in {prefix}",
                f"missing: {' '.join(map(str, gaps))} — deleted instead of "
                "marked BÃI BỎ?",
            )

    _check_wbs_tasks()
    _check_markers()
    _check_not_written_yet()
    _check_banned_coalesce()


_TASK_HEAD_RE = re.compile(r"^### ([TM][0-9]+(?:\.[0-9]+)?[a-z]?) ")
_TASK_TOKEN_RE = re.compile(r"^[TM][0-9]+(?:\.[0-9]+)?[a-z]?$")


def _wbs_task_ids() -> list[str]:
    return [m.group(1) for line in _lines(WBS_FILE) if (m := _TASK_HEAD_RE.match(line))]


def _check_wbs_tasks() -> None:
    task_ids = _wbs_task_ids()

    # duplicate task ids
    before = _problems
    seen: set[str] = set()
    for t in task_ids:
        if t in seen:
            _fail("duplicate WBS task ID", f"{t} appears more than once in {WBS_FILE}")
        seen.add(t)
    if _problems == before:
        _ok(f"no duplicate WBS task IDs ({len(task_ids)} tasks)")

    # dependencies resolve
    task_set = set(task_ids)
    edges: list[tuple[str, str]] = []
    cur = ""
    for line in _lines(WBS_FILE):
        if line.startswith("### "):
            parts = line.split()
            cur = parts[1] if len(parts) > 1 and _TASK_TOKEN_RE.match(parts[1]) else ""
            continue
        if cur and line.startswith("- **Dependencies:**"):
            rest = line[len("- **Dependencies:**") :]
            for tok in re.split(r"[^A-Za-z0-9.]+", rest):
                tok = tok.rstrip(".")
                if _TASK_TOKEN_RE.match(tok):
                    edges.append((cur, tok))
    dep_bad = before = _problems
    for task, dep in edges:
        if dep not in task_set:
            _fail(
                "WBS dependency points at a task that does not exist",
                f"{task} depends on {dep}, which is not defined in {WBS_FILE}",
            )
    if _problems == before:
        _ok(f"every WBS dependency resolves to a defined task ({len(edges)} edges)")

    _check_m_task_template()


_M_HEAD_RE = re.compile(r"^### (M[0-9]+(?:\.[0-9]+)?[a-z]?) ")
_M_REQUIRED = (
    "Status",
    "Goal",
    "Scope",
    "Editable documents",
    "Output",
    "Acceptance criteria",
    "Dependencies",
    "Tests required",
    "Checklist phases",
)
_AC_BOX_RE = re.compile(r"^\s*- \[[ x]\]")


def _check_m_task_template() -> None:
    bad: list[str] = []
    cur = ""
    seen: set[str] = set()
    ac = 0
    inac = False

    def finish() -> None:
        if not cur:
            return
        miss = [f for f in _M_REQUIRED if f not in seen]
        if miss:
            bad.append(f"{cur}: missing field(s): {', '.join(miss)}")
        elif ac == 0:
            bad.append(f"{cur}: Acceptance criteria block is empty")

    for line in _lines(WBS_FILE):
        if line.startswith("### "):
            finish()
            m = _M_HEAD_RE.match(line)
            cur = m.group(1) if m else ""
            seen = set()
            ac = 0
            inac = False
            continue
        if not cur:
            continue
        for field in _M_REQUIRED:
            if f"- **{field}:**" in line:
                seen.add(field)
        if line.startswith("- **Acceptance criteria:**"):
            inac = True
            continue
        if line.startswith("- **"):
            inac = False
        if inac and _AC_BOX_RE.match(line):
            ac += 1
    finish()

    if bad:
        for b in bad:
            _fail("M-task does not meet the WBS template", f"{b}  (§6.5)")
    else:
        _ok("every M-task carries the 9 required fields and a non-empty acceptance block")


_MARKER_RE = re.compile(r"\[cần xác nhận\]|\[TODO\]|\[TBD\]")


def _check_markers() -> None:
    hits: list[str] = []
    for f in _docs_md() + ["CLAUDE.md"]:
        for i, line in enumerate(_lines(f), start=1):
            if _MARKER_RE.search(line):
                hits.append(f"{f}:{i}:{line}")
    if hits:
        for h in hits:
            _fail("unresolved marker in MVP scope", h)
    else:
        _ok("no unresolved [cần xác nhận] / [TODO] / [TBD] markers")


_LISTED_DOC_RE = re.compile(r"`([a-z-]+\.md)`")


def _check_not_written_yet() -> None:
    lines = _lines(README_FILE)
    if not any(line.startswith("## Not written yet") for line in lines):
        return
    # Section from the heading to the next '## '.
    listed: set[str] = set()
    inside = False
    for line in lines:
        if line.startswith("## Not written yet"):
            inside = True
            continue
        if inside and line.startswith("## "):
            break
        if inside:
            listed.update(_LISTED_DOC_RE.findall(line))
    before = _problems
    for doc in sorted(listed):
        if (_REPO / "docs" / doc).is_file():
            _fail(
                "document exists but is listed as not written",
                f"docs/{doc} is in the 'Not written yet' section of {README_FILE}",
            )
    if _problems == before:
        _ok("'Not written yet' section matches reality")


_FENCE_COMMENT_RE = re.compile(r"^\s*(--|//|#)")
_COALESCE_RE = re.compile(
    r"COALESCE\(\s*([A-Za-z_][A-Za-z_0-9]*\.)?parent_deck_id"
)


def _fence_sql_lines() -> list[str]:
    """Non-comment lines inside fenced blocks of docs + skill references."""
    files = list(_docs_md())
    skills = _REPO / ".claude" / "skills"
    if skills.is_dir():
        files += [
            p.relative_to(_REPO).as_posix()
            for p in skills.rglob("*.md")
            if "/references/" in p.as_posix()
        ]
    out: list[str] = []
    for f in sorted(set(files)):
        infence = False
        for i, line in enumerate(_lines(f), start=1):
            if line.startswith("```"):
                infence = not infence
                continue
            if infence and not _FENCE_COMMENT_RE.match(line):
                out.append(f"{f}:{i}:{line}")
    return out


def _grep_tree(pattern: re.Pattern[str], roots: tuple[str, ...]) -> list[str]:
    out: list[str] = []
    for root in roots:
        base = _REPO / root
        if not base.is_dir():
            continue
        for p in base.rglob("*"):
            if not p.is_file():
                continue
            try:
                text = p.read_text(encoding="utf-8")
            except (OSError, UnicodeDecodeError):
                continue
            rel = p.relative_to(_REPO).as_posix()
            for i, line in enumerate(text.splitlines(), start=1):
                if pattern.search(line):
                    out.append(f"{rel}:{i}:{line}")
    return out


def _check_banned_coalesce() -> None:
    candidates = _fence_sql_lines()
    candidates += [
        h
        for h in _grep_tree(re.compile(r"COALESCE\(\s*parent_deck_id"), ("lib", "test"))
    ]
    banned = [c for c in candidates if _COALESCE_RE.search(c)]
    if banned:
        for b in banned:
            _fail(
                "banned root-resolution pattern used in SQL (BR-57)",
                f"{b}\n    COALESCE(parent_deck_id, id) returns the level-2 "
                "deck at depth 3. Use root_deck_id.",
            )
    else:
        _ok("no COALESCE(parent_deck_id, …) used in any SQL or source")


# --- A2. Document contract ------------------------------------------------

_REQUIRED_HEADER = (
    "Status",
    "Purpose",
    "Scope",
    "Source of truth for",
    "Depends on",
    "Updated by task",
    "Last updated",
)


def _check_document_contract() -> None:
    _head("A2. Document contract (document-conventions.md)")

    # every document declares the full header (first 20 lines)
    before = _problems
    for f in _docs_md():
        head20 = _lines(f)[:20]
        for k in _REQUIRED_HEADER:
            if any(f"| **{k}**" in line for line in head20):
                continue
            _fail("document header missing a field", f"{f} is missing: **{k}**  (§4)")
    if _problems == before:
        _ok(f"all {len(_docs_md())} documents declare the full 7-field header")

    # no two documents claim the same source of truth
    topic_owner: dict[str, str] = {}
    dupes: list[str] = []
    for f in _docs_md():
        for line in _lines(f):
            if "| **Source of truth for**" in line:
                cell = re.sub(r".*truth for\*\* \| ", "", line)
                cell = re.sub(r" \|$", "", cell)
                for topic in cell.split("·"):
                    topic = topic.strip()
                    if not topic:
                        continue
                    if topic in topic_owner and topic_owner[topic] != f:
                        dupes.append(f"{topic} → {topic_owner[topic]} AND {f}")
                    else:
                        topic_owner[topic] = f
                break
    if dupes:
        for d in dupes:
            _fail("two documents claim the same source of truth", f"{d}  (§5)")
    else:
        _ok("no topic is claimed as source of truth by two documents")

    _check_br_rows()
    _check_section_br()
    _check_uc_sections()
    _check_ad_sections()
    _check_it_scenario_contract()


_IT_DIR = "docs/it-scenarios"
_IT_CATALOG = f"{_IT_DIR}/scenario-catalog.md"
_IT_GUIDE = f"{_IT_DIR}/00-agent-execution-guide.md"
_IT_HEAD_RE = re.compile(r"^## (IT-[A-Z]+-[0-9]{3}) — .+$")
_IT_CATALOG_RE = re.compile(r"^\| (IT-[A-Z]+-[0-9]{3}) \|")
_IT_READINESS = {"READY", "FIXTURE-BLOCKED", "KNOWN-GAP"}
_IT_PROFILES = {
    "UI",
    "UI-RESTART",
    "UI-DEVICE",
    "DEV-LINK",
    "UI-FIXTURE",
    "UI-LARGE",
}
_IT_CLEANUPS = {"CLEAN-RESET", "CLEAN-DELETE-CREATED", "CLEAN-PRESERVE", "CLEAN-NONE"}


def _check_it_scenario_contract() -> None:
    """Keep the agent catalog complete and every scenario executable in shape."""
    if not (_REPO / _IT_CATALOG).is_file() or not (_REPO / _IT_GUIDE).is_file():
        _fail(
            "IT scenario agent contract is incomplete",
            f"expected both {_IT_GUIDE} and {_IT_CATALOG}",
        )
        return

    scenario_docs = sorted(
        p.relative_to(_REPO).as_posix()
        for p in (_REPO / _IT_DIR).glob("[0-9][0-9]-*.md")
    )
    headings: dict[str, tuple[str, int]] = {}
    ordered: list[tuple[str, str, int, int]] = []
    before = _problems

    for path in scenario_docs:
        lines = _lines(path)
        starts: list[tuple[str, int]] = []
        for index, line in enumerate(lines):
            match = _IT_HEAD_RE.match(line)
            if not match:
                continue
            scenario_id = match.group(1)
            if scenario_id in headings:
                previous = headings[scenario_id]
                _fail(
                    "duplicate IT scenario ID",
                    f"{scenario_id}: {previous[0]}:{previous[1]} and {path}:{index + 1}",
                )
            headings[scenario_id] = (path, index + 1)
            starts.append((scenario_id, index))

        for position, (scenario_id, start) in enumerate(starts):
            end = starts[position + 1][1] if position + 1 < len(starts) else len(lines)
            ordered.append((scenario_id, path, start, end))

    for scenario_id, path, start, end in ordered:
        block = _lines(path)[start:end]
        required = {
            "priority": any(re.match(r"^- \*\*Ưu tiên:\*\* P[012]$", line) for line in block),
            "precondition": any(line.startswith("- **Tiền điều kiện:**") for line in block),
            "step table": any(
                line == "| Bước | Thao tác người dùng | Kết quả mong đợi |" for line in block
            ),
        }
        for label, present in required.items():
            if not present:
                _fail(
                    "IT scenario missing agent-required field",
                    f"{path}:{start + 1}: {scenario_id} missing {label}",
                )

    catalog: dict[str, tuple[str, int]] = {}
    catalog_rows: dict[str, list[str]] = {}
    for line_number, line in enumerate(_lines(_IT_CATALOG), start=1):
        match = _IT_CATALOG_RE.match(line)
        if not match:
            continue
        scenario_id = match.group(1)
        cells = [cell.strip().strip("`") for cell in line.strip().strip("|").split("|")]
        if scenario_id in catalog:
            previous = catalog[scenario_id]
            _fail(
                "duplicate IT catalog ID",
                f"{scenario_id}: {_IT_CATALOG}:{previous[1]} and line {line_number}",
            )
        catalog[scenario_id] = (_IT_CATALOG, line_number)
        catalog_rows[scenario_id] = cells

    missing = sorted(set(headings) - set(catalog))
    extra = sorted(set(catalog) - set(headings))
    if missing:
        _fail("IT scenarios missing from catalog", ", ".join(missing))
    if extra:
        _fail("IT catalog points at missing scenarios", ", ".join(extra))

    setup_ids = set()
    for line in _lines(_IT_GUIDE):
        if not line.startswith("### "):
            continue
        setup_ids.update(re.findall(r"\bSETUP-[A-Z0-9-]+", line))
        setup_ids.update(re.findall(r"\bS-(?:PROGRESS|DUE|LARGE)\b", line))

    for scenario_id, cells in catalog_rows.items():
        if len(cells) != 7:
            _fail(
                "IT catalog row has wrong column count",
                f"{_IT_CATALOG}:{catalog[scenario_id][1]}: {scenario_id} has {len(cells)}, expected 7",
            )
            continue
        _id, file_name, readiness, profile, setup, cleanup, trace = cells
        scenario_path = f"{_IT_DIR}/{file_name}"
        if not (_REPO / scenario_path).is_file():
            _fail("IT catalog file does not exist", f"{scenario_id}: {scenario_path}")
        elif scenario_id in headings and scenario_path != headings[scenario_id][0]:
            _fail(
                "IT catalog points at the wrong scenario file",
                f"{scenario_id}: catalog={scenario_path}, actual={headings[scenario_id][0]}",
            )
        if readiness not in _IT_READINESS:
            _fail("invalid IT readiness", f"{scenario_id}: {readiness}")
        if profile not in _IT_PROFILES:
            _fail("invalid IT execution profile", f"{scenario_id}: {profile}")
        setup_base = setup.split(":", 1)[0]
        if setup_base not in setup_ids:
            _fail("undefined IT setup", f"{scenario_id}: {setup}")
        if cleanup not in _IT_CLEANUPS:
            _fail("invalid IT cleanup", f"{scenario_id}: {cleanup}")
        if not trace or trace == "—":
            _fail("IT scenario has no traceability", scenario_id)

    link_re = re.compile(r"\[[^]]+\]\(([^)#]+\.md)(?:#[^)]+)?\)")
    for path in _docs_md():
        if not path.startswith(f"{_IT_DIR}/"):
            continue
        parent = (_REPO / path).parent
        for line_number, line in enumerate(_lines(path), start=1):
            for target in link_re.findall(line):
                if not (parent / target).resolve().is_file():
                    _fail(
                        "broken IT scenario Markdown link",
                        f"{path}:{line_number}: {target}",
                    )

    if _problems == before:
        _ok(
            f"all {len(headings)} IT scenarios have unique IDs, required fields, "
            "and valid agent catalog rows"
        )


_BR_ROW_RE = re.compile(r"^\| BR-[0-9]+ \|")


def _check_br_rows() -> None:
    bad: list[str] = []
    for i, line in enumerate(_lines(BR_FILE), start=1):
        if _BR_ROW_RE.match(line):
            nf = len(line.split("|"))
            if nf < 7:
                col_id = line.split("|")[1].strip()
                bad.append(f"{BR_FILE}:{i}: {col_id} has {nf - 2} columns, needs 5")
    if bad:
        for b in bad:
            _fail(
                "BR row missing required columns",
                f"{b}  (§6.2: ID | Status | Rule | Enforced by | Related)",
            )
    else:
        _ok("every BR table row carries ID / Status / Rule / Enforced by / Related")


_SEC_BR_RE = re.compile(r"^### (BR-[0-9]+) ")


def _check_section_br() -> None:
    bad: list[str] = []
    cur = ""
    found = False
    for line in _lines(BR_FILE):
        m = _SEC_BR_RE.match(line)
        if m:
            cur = m.group(1)
            found = False
            continue
        if cur and "**Status:**" in line and "**Enforced by:**" in line:
            found = True
        if cur and (line.startswith("### ") or line.startswith("## ")):
            if not found:
                bad.append(cur)
            cur = ""
    if cur and not found:
        bad.append(cur)
    if bad:
        for s in bad:
            _fail("section-form BR missing Status / Enforced by", f"{s} in {BR_FILE}  (§6.2)")
    else:
        _ok("every section-form BR declares Status and Enforced by")


_UC_RE = re.compile(r"^## (UC-[0-9]+) ")
_UC_PARTS = (
    "Actor",
    "Trigger",
    "Preconditions",
    "Main flow",
    "Alternative flows",
    "Error flows",
    "Postconditions",
    "Business rules",
    "UI states",
)


def _check_uc_sections() -> None:
    bad: list[str] = []
    cur = ""
    seen: set[str] = set()

    def finish() -> None:
        if not cur:
            return
        miss = [p for p in _UC_PARTS if p not in seen]
        if miss:
            bad.append(f"{cur}: {', '.join(miss)}")

    for line in _lines(UC_FILE):
        m = _UC_RE.match(line)
        if m:
            finish()
            cur = m.group(1)
            seen = set()
            continue
        if cur:
            for part in _UC_PARTS:
                if f"**{part}" in line:
                    seen.add(part)
    finish()
    if bad:
        for u in bad:
            _fail("UC missing required section", f"{u}  (§6.3)")
    else:
        _ok("every UC carries all nine required sections")


_AD_RE = re.compile(r"^## (AD-[0-9]+) ")


def _check_ad_sections() -> None:
    bad: list[str] = []
    cur = ""
    s = a = d = False

    def finish() -> None:
        if not cur:
            return
        miss = ""
        if not s:
            miss += "Status "
        if not a:
            miss += "Affected-documents "
        if not d:
            miss += "Decision "
        if miss:
            bad.append(f"{cur}: missing {miss}")

    for line in _lines(AD_FILE):
        m = _AD_RE.match(line)
        if m:
            finish()
            cur = m.group(1)
            s = a = d = False
            continue
        if not cur:
            continue
        if line.startswith("| **Status**"):
            s = True
        if line.startswith("| **Affected documents**"):
            a = True
        if "**Quyết định" in line or "**Decision" in line:
            d = True
    finish()
    if bad:
        for x in bad:
            _fail("AD missing required field", f"{x}  (§6.1)")
    else:
        _ok("every AD declares Status, Affected documents and a Decision")


# --- B. Invariant coverage ------------------------------------------------

_INVARIANTS = (
    ("root deck has direct cards", r"WHERE d\.parent_deck_id IS NULL"),
    ("content_type=unset but has content", r"content_type = 'unset'"),
    ("content_type=card but has sub-decks", r"content_type = 'card'"),
    ("content_type=deck but has direct cards", r"content_type = 'deck'"),
    ("descendant points at wrong root", r"root_deck_id <> p\.root_deck_id"),
    ("cycle in the deck tree", r"WITH RECURSIVE"),
    ("card state scheduler/generation mismatch",
     r"s\.scheduler_generation <> root\.scheduler_generation"),
    ("session status × end_reason matrix", r"status = 'invalidated'"),
    ("relearning must not change schedule", r"review_kind = 'relearning'"),
)


def _check_invariant_coverage() -> None:
    _head("B. Invariant coverage in docs/data-model.md")
    if not (_REPO / DM_FILE).is_file():
        _fail("missing document", DM_FILE)
        return
    text = _read(DM_FILE)
    missing = False
    for label, pattern in _INVARIANTS:
        if not re.search(pattern, text):
            _fail("invariant not specified", f"no query in {DM_FILE} for: {label}")
            missing = True
    if not missing:
        _ok(f"all {len(_INVARIANTS)} data invariants have a query in {DM_FILE}")


# --- C. Data invariants (delegated, unchanged) ----------------------------

_VERIFIER = ".claude/skills/flutter-workflow/scripts/verify_invariants.py"


def _python() -> str | None:
    for cand in ("python3", "python"):
        try:
            subprocess.run([cand, "--version"], capture_output=True, check=True)
            return cand
        except (OSError, subprocess.CalledProcessError):
            continue
    return None


def _check_invariant_self_test() -> None:
    _head("C1. Invariant queries — do they parse and discriminate?")
    py = _python()
    if py is None:
        _warn("python3 not on PATH", "cannot self-test the invariant queries")
        return
    if not (_REPO / _VERIFIER).is_file():
        _warn("verifier missing", _VERIFIER)
        return
    result = subprocess.run([py, _VERIFIER], capture_output=True, text=True)
    if result.returncode == 0:
        n = len(re.findall(r"^\s+✓ Q[0-9]+", result.stdout, re.MULTILINE))
        _ok(f"{n} invariant queries parse, stay clean on valid data, and each fires on its own violation")
    else:
        out = result.stdout + result.stderr
        offending = [ln for ln in out.splitlines() if "✗" in ln or "LỖI" in ln][:5]
        _fail("invariant query self-test failed", "\n".join(offending))


def _check_data_invariants(db: str) -> None:
    _head("C2. Data invariants against a real database")
    if not db:
        print("  skipped — no --db given. Nothing here has been checked.")
        print("  Build the fixtures, then point this section at them:")
        print("    flutter test test/database/fixture_db_test.dart")
        print("    check_docs.sh --db build/invariant_fixture_clean.db")
        return
    if not Path(db).is_file():
        _fail("database not found", db)
        return
    py = _python()
    if py is None:
        _fail("python3 not on PATH", f"cannot run the data invariants against {db}")
        return
    result = subprocess.run([py, _VERIFIER, "--db", db], capture_output=True, text=True)
    if result.returncode == 0:
        n = len(re.findall(r"^  ✓ Q[0-9]+", result.stdout, re.MULTILINE))
        _ok(f"all {n} data invariants ran clean against {db}")
    else:
        out = result.stdout + result.stderr
        offending = [ln for ln in out.splitlines() if "✗" in ln][:6]
        _fail("data invariants violated", "\n".join(offending))


# --- D. Deck validation-flow ownership drift ------------------------------

_DECK_FLOW_PATTERNS = (
    ("widget trims/normalises the name", re.compile("trimmed-as-typed", re.I)),
    ("controller validates or trims",
     re.compile(r"\bcontrollers?\s+(validates|trims)\b", re.I)),
    ("widget sends a normalised name",
     re.compile(r"\bwidget\s+[^.]{0,30}normali[sz]ed\s+name", re.I)),
    ("repository re-validates the name",
     re.compile(r"\b(re-?validates)\b[^.]{0,20}\b(name|BR-01)\b", re.I)),
    ("removed BR-01 API cited as live",
     re.compile(r"(from|via)\s+[^.]{0,4}(DeckEntity\.nameProblem|DeckEntity\.validateName|`validateName)", re.I)),
)


def _deck_flow_files() -> list[str]:
    files: set[str] = set()
    for root in ("lib/features/deck", "test/features/deck"):
        base = _REPO / root
        if base.is_dir():
            files.update(p.relative_to(_REPO).as_posix() for p in base.rglob("*.dart"))
    files.update(_docs_md())
    files.add("CLAUDE.md")
    skills = _REPO / ".claude" / "skills"
    if skills.is_dir():
        files.update(p.relative_to(_REPO).as_posix() for p in skills.rglob("*.md"))
    snippet = ".vscode/memox.code-snippets"
    if (_REPO / snippet).is_file():
        files.add(snippet)
    return sorted(f for f in files if (_REPO / f).is_file())


def _check_deck_flow_drift() -> None:
    _head("D. Deck validation-flow ownership drift")
    scanned = 0
    hits = 0
    for f in _deck_flow_files():
        scanned += 1
        for i, line in enumerate(_lines(f), start=1):
            for label, pat in _DECK_FLOW_PATTERNS:
                if pat.search(line):
                    hits += 1
                    _fail(
                        f"stale deck validation-flow claim ({label})",
                        f"{f}:{i}:{line}\n    DeckName.parse in the use case owns "
                        "trim + BR-01; no other layer validates or trims the name.",
                    )
    if scanned == 0:
        _fail(
            "zero scope",
            "the deck validation-flow guard scanned no files — deck paths "
            "moved, so it now checks nothing",
        )
    elif hits == 0:
        _ok(f"no stale deck validation-flow claims ({scanned} files scanned; DeckName.parse is the one owner)")


# --- main -----------------------------------------------------------------


def main() -> int:
    global _quiet, _REPO
    parser = argparse.ArgumentParser(add_help=False)
    parser.add_argument("--db", default="")
    parser.add_argument("--quiet", action="store_true")
    args, _unknown = parser.parse_known_args()
    _quiet = args.quiet

    try:
        top = subprocess.run(
            ["git", "rev-parse", "--show-toplevel"],
            capture_output=True, text=True, check=True,
        ).stdout.strip()
        if top:
            _REPO = Path(top)
    except (OSError, subprocess.CalledProcessError):
        pass

    # Core documents must exist before anything else can be checked.
    core_missing = False
    for f in (BR_FILE, AD_FILE, UC_FILE, WBS_FILE, README_FILE):
        if not (_REPO / f).is_file():
            _fail("missing document", f)
            core_missing = True
    if core_missing:
        print("\ncannot continue without the core documents")
        return 1

    _check_document_integrity()
    _check_document_contract()
    _check_invariant_coverage()
    _check_invariant_self_test()
    _check_data_invariants(args.db)
    _check_deck_flow_drift()

    print("\n" + "-" * 60)
    if _problems == 0:
        print(f"{_GRN}✓{_OFF} specification is internally consistent")
        print()
        print("Not checked here: whether a rule is a good rule, and whether a citation")
        print("points at the semantically right rule. Both still need a human.")
        return 0
    print(f"{_RED}✗{_OFF} {_problems} problem(s)")
    return 1


if __name__ == "__main__":
    sys.exit(main())
