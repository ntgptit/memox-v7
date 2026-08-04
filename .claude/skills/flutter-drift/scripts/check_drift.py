#!/usr/bin/env python3
"""Mechanical half of a Drift review.

Only checks what is decidable by reading the source. Everything that needs a
human — is this index justified, does this migration cope with existing rows —
is in `references/review-checklist.md` and deliberately not here: a checker that
guesses at judgement calls gets ignored, and then it stops catching the things it
was right about.

Two severities:
  ERROR  the code is wrong. Exits 1.
  NOTE   a human has to decide. Exits 0, still printed.

Usage: check_drift.py [--quiet] [--diff]
  --diff   only report findings in files changed against HEAD (staged+unstaged)
"""

from __future__ import annotations

import re
import subprocess
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[4]
LIB = REPO / "lib"

DRIFT_IMPORT = re.compile(r"""import\s+['"]package:drift/""")
DATABASE_IMPORT = re.compile(r"""import\s+['"][^'"]*core/database/[^'"]*['"]""")
DAO_IMPORT = re.compile(r"""import\s+['"][^'"]*_dao\.dart['"]""")
OPENS_DATABASE = re.compile(r"\b(driftDatabase\s*\(|NativeDatabase[.(])")
TRANSACTION_CALL = re.compile(r"\.(transaction|runInTransaction)\s*\(")
CUSTOM_READ = re.compile(r"\bcustom(Select|SelectQuery)\s*\(")
CUSTOM_WRITE = re.compile(r"\bcustom(Update|Insert|Statement)\s*\(")
SELECT_STAR = re.compile(r"\bSELECT\s+\*", re.IGNORECASE)
SCHEMA_VERSION = re.compile(r"int\s+get\s+schemaVersion\s*=>\s*(\d+)")

# A Dart string literal, single or triple quoted, captured so its body can be
# inspected for interpolated SQL.
DART_STRING = re.compile(
    r"""(?P<quote>'''|\"\"\"|'|")(?P<body>(?:\\.|(?!(?P=quote)).)*)(?P=quote)""",
    re.DOTALL,
)
SQL_VERB = re.compile(
    r"\b(SELECT\s+\w|INSERT\s+INTO|UPDATE\s+\w+\s+SET|DELETE\s+FROM|ORDER\s+BY|WHERE\s+\w)",
)
INTERPOLATION = re.compile(r"\$\{?\w")
CUSTOM_EXPRESSION = re.compile(r"\bCustomExpression\s*[<(]")
STRINGLY_SORT = re.compile(
    r"\b(?:String|String\?)\s+(sortColumn|sortBy|orderBy|sortDirection|orderColumn|sortField)\b",
)
WALL_CLOCK = re.compile(r"\bDateTime\.now\s*\(")
ASCII_FOLD = re.compile(r"\.lower\s*\(\s*\)|\blower\s*\(", re.IGNORECASE)
NOCASE = re.compile(r"COLLATE\s+NOCASE", re.IGNORECASE)
DATE_BETWEEN = re.compile(
    r"\bBETWEEN\s+:(\w*(?:from|start|begin|after)\w*)\s+AND\s+:(\w+)",
    re.IGNORECASE,
)

findings: list[tuple[str, str, str]] = []  # (severity, location, message)


def report(severity: str, location: str, message: str) -> None:
    findings.append((severity, location, message))


def rel(path: Path) -> str:
    return str(path.relative_to(REPO))


# Generated output. Scanning it reports drift's own code back at the author, who
# cannot change it and does not commit it — `app_database.g.dart` alone carries
# nine `customSelect`-without-`readsFrom` hits and three interpolated statements,
# all of them drift's chosen shape for a named query. Left in, the guard exits 1
# on every clone that has run build_runner, which is every clone that compiles.
GENERATED_SUFFIXES = (".g.dart", ".freezed.dart", ".drift.dart")


def is_generated(path: Path) -> bool:
    return path.name.endswith(GENERATED_SUFFIXES)


def dart_files(*globs: str) -> list[Path]:
    out: list[Path] = []
    for pattern in globs:
        out.extend(
            p
            for p in LIB.glob(pattern)
            if p.suffix == ".dart" and not is_generated(p)
        )
    return sorted(set(out))


def strip_dart_comments(text: str) -> str:
    """Drop comments so prose about SQL is not mistaken for SQL.

    Every file in this repo explains its query in a doc comment, and several
    quote the SQL they are arguing about. Scanning those would make the honest
    files the noisy ones.
    """
    text = re.sub(r"/\*.*?\*/", "", text, flags=re.DOTALL)
    return re.sub(r"^\s*//.*$", "", text, flags=re.MULTILINE)


def strip_sql_comments(sql: str) -> str:
    sql = re.sub(r"--[^\n]*", "", sql)
    return re.sub(r"/\*.*?\*/", "", sql, flags=re.DOTALL)


# ---------------------------------------------------------------- boundaries


def check_presentation_free_of_drift() -> None:
    """Drift must not be visible above the repository (AD-01).

    A row class in a widget is invisible until the backend lands, and then it is
    a UI rewrite — which is exactly why it has to be caught while it is free.
    """
    scope = dart_files("features/*/presentation/**/*.dart", "app/**/*.dart")
    for path in scope:
        # The composition root is the one place an implementation is named
        # outside its own layer — that is its whole job (CLAUDE.md, AD-13). It
        # binds a DAO to a contract, so it necessarily sees both.
        if "di" in path.parts:
            continue
        text = path.read_text(encoding="utf-8")
        for pattern, what in (
            (DRIFT_IMPORT, "package:drift"),
            (DATABASE_IMPORT, "core/database"),
            (DAO_IMPORT, "a DAO"),
        ):
            if pattern.search(text):
                report(
                    "ERROR",
                    rel(path),
                    f"presentation imports {what}; it may only speak domain types",
                )


def check_domain_free_of_drift() -> None:
    for path in dart_files("features/*/domain/**/*.dart"):
        text = path.read_text(encoding="utf-8")
        if DRIFT_IMPORT.search(text) or DATABASE_IMPORT.search(text):
            report(
                "ERROR",
                rel(path),
                "domain imports Drift; the contract must not know its implementation",
            )


def check_single_opener() -> None:
    """One file opens a database (AD-08).

    Two instances on one file do not share Drift's update bus, so streams from
    one go stale when the other writes.
    """
    allowed = LIB / "core" / "database" / "connection.dart"
    for path in dart_files("**/*.dart"):
        if path == allowed:
            continue
        text = path.read_text(encoding="utf-8")
        if OPENS_DATABASE.search(text):
            report(
                "ERROR",
                rel(path),
                "opens a database; only core/database/connection.dart may (AD-08)",
            )


def check_transactions_stay_in_data() -> None:
    """A rule that needs the data at the moment of writing runs inside the lock."""
    for path in dart_files("features/*/**/*.dart", "core/**/*.dart"):
        parts = path.parts
        if "data" in parts or "database" in parts:
            continue
        text = path.read_text(encoding="utf-8")
        for number, line in enumerate(text.splitlines(), start=1):
            if TRANSACTION_CALL.search(line) and not line.lstrip().startswith("///"):
                report(
                    "ERROR",
                    f"{rel(path)}:{number}",
                    "transaction started outside the data layer; the check would "
                    "sit outside the lock it protects",
                )


def check_custom_sql_declares_dependencies() -> None:
    """Drift cannot track SQL it did not parse."""
    for path in dart_files("**/*.dart"):
        text = path.read_text(encoding="utf-8")
        for match in CUSTOM_READ.finditer(text):
            window = text[match.start() : match.start() + 600]
            if "readsFrom" not in window:
                line = text[: match.start()].count("\n") + 1
                report(
                    "ERROR",
                    f"{rel(path)}:{line}",
                    "customSelect without readsFrom: the stream emits once and "
                    "then goes silent",
                )
        for match in CUSTOM_WRITE.finditer(text):
            window = text[match.start() : match.start() + 600]
            if "updates" not in window and "PRAGMA" not in window:
                line = text[: match.start()].count("\n") + 1
                report(
                    "NOTE",
                    f"{rel(path)}:{line}",
                    "raw write without `updates:` — confirm no stream depends on "
                    "the tables it changes",
                )


# --------------------------------------------------------------- dynamic SQL


def check_no_interpolated_sql() -> None:
    """SQL built by interpolation loses everything at once.

    Compile-time checking, drift's stream dependencies and injection safety all
    come from SQL that drift parsed. A column name or a clause spliced into a
    string has none of them — and a value spliced in is an injection whether or
    not today's caller happens to pass a UUID.
    """
    for path in dart_files("**/*.dart"):
        text = strip_dart_comments(path.read_text(encoding="utf-8"))
        for match in DART_STRING.finditer(text):
            body = match.group("body")
            if not SQL_VERB.search(body) or not INTERPOLATION.search(body):
                continue
            line = text[: match.start()].count("\n") + 1
            report(
                "ERROR",
                f"{rel(path)}:{line}",
                "SQL built by interpolation: bind values as variables and take "
                "structure from an enum or a $predicate template",
            )


def check_custom_expression() -> None:
    for path in dart_files("**/*.dart"):
        text = strip_dart_comments(path.read_text(encoding="utf-8"))
        for match in CUSTOM_EXPRESSION.finditer(text):
            line = text[: match.start()].count("\n") + 1
            window = text[match.start() : match.start() + 300]
            severity = "ERROR" if INTERPOLATION.search(window) else "NOTE"
            detail = (
                "CustomExpression built by interpolation — unparsed SQL carrying "
                "runtime input"
                if severity == "ERROR"
                else "CustomExpression bypasses drift's type checking; confirm the "
                "fragment is a constant and that drift genuinely cannot express it"
            )
            report(severity, f"{rel(path)}:{line}", detail)


def check_sort_is_not_stringly_typed() -> None:
    """A sort that arrives as a String is a column name the UI can choose."""
    for path in dart_files("**/*.dart"):
        text = strip_dart_comments(path.read_text(encoding="utf-8"))
        for match in STRINGLY_SORT.finditer(text):
            line = text[: match.start()].count("\n") + 1
            report(
                "NOTE",
                f"{rel(path)}:{line}",
                f"`{match.group(1)}` is a String: sorting should come from an enum "
                "with an exhaustive switch, so an unsupported order cannot be "
                "expressed",
            )


def check_no_wall_clock_in_data_layer() -> None:
    """DYN-09a: a query builder must be deterministic.

    Two predicates each calling `now()` are measured against two instants
    milliseconds apart, which is invisible until it puts a row on the wrong side
    of a due boundary. The clock is read once, at the use case, and passed down.
    """
    for path in dart_files("core/database/**/*.dart", "features/*/data/**/*.dart"):
        text = strip_dart_comments(path.read_text(encoding="utf-8"))
        for match in WALL_CLOCK.finditer(text):
            line = text[: match.start()].count("\n") + 1
            report(
                "ERROR",
                f"{rel(path)}:{line}",
                "DateTime.now() in the data layer: take the instant from "
                "clockProvider at the use case and pass it in",
            )


def check_ascii_folding() -> None:
    """DYN-05: SQLite folds ASCII only.

    `lower()` and `COLLATE NOCASE` leave every non-ASCII letter alone, so a
    Vietnamese or Korean app that relies on them is case-insensitive for half its
    content. `tags.drift` already documents this and folds at write time into
    `name_folded`; anything comparing with SQL-side folding should be held to the
    same standard.
    """
    for path in sorted(LIB.rglob("*.drift")):
        text = strip_sql_comments(path.read_text(encoding="utf-8"))
        for match in NOCASE.finditer(text):
            line = text[: match.start()].count("\n") + 1
            report(
                "NOTE",
                f"{rel(path)}:{line}",
                "COLLATE NOCASE folds ASCII only — fold at write time into a "
                "column instead, as tags.name_folded does (DYN-05)",
            )

    for path in dart_files("features/*/data/**/*.dart", "core/database/**/*.dart"):
        text = strip_dart_comments(path.read_text(encoding="utf-8"))
        for match in ASCII_FOLD.finditer(text):
            line = text[: match.start()].count("\n") + 1
            report(
                "NOTE",
                f"{rel(path)}:{line}",
                "SQL-side lower() folds ASCII only; if the other side of the "
                "comparison is folded in Dart the two disagree on non-ASCII "
                "text (DYN-05)",
            )


# -------------------------------------------------------------------- queries


def named_statements(path: Path) -> list[tuple[str, int, str]]:
    """Split a .drift file into (name, line, sql) for its named queries."""
    text = strip_sql_comments(path.read_text(encoding="utf-8"))
    out: list[tuple[str, int, str]] = []
    for match in re.finditer(r"^([a-zA-Z_]\w*)\s*:\s*$", text, flags=re.MULTILINE):
        start = match.end()
        end = text.find(";", start)
        body = text[start : end if end != -1 else len(text)]
        line = text[: match.start()].count("\n") + 1
        out.append((match.group(1), line, body))
    return out


def check_queries() -> None:
    for path in sorted(LIB.rglob("*.drift")):
        for name, line, sql in named_statements(path):
            flat = " ".join(sql.split())
            upper = flat.upper()
            has_limit = " LIMIT " in f" {upper} "
            has_order = " ORDER BY " in upper
            location = f"{rel(path)}:{line}"

            if has_limit and not has_order:
                report(
                    "ERROR",
                    location,
                    f"`{name}` has LIMIT without ORDER BY: 'the first N' is "
                    "undefined until 'first' is",
                )

            # `LIMIT 1` is exempt: a single-row probe (`ORDER BY depth DESC
            # LIMIT 1`) has no list to keep stable. A window that returns many
            # rows does, and that is where a missing tie-breaker shows up as a
            # row swapping places — or, under pagination, vanishing.
            single_row = re.search(r"\bLIMIT\s+1\b", upper) is not None
            if has_order and has_limit and not single_row:
                order = upper.split(" ORDER BY ", 1)[1].split(" LIMIT ")[0]
                if "$" not in order and not re.search(r"\bID\b", order):
                    report(
                        "NOTE",
                        location,
                        f"`{name}` orders without an id tie-breaker: rows sharing "
                        "the sort value can swap between reads",
                    )

            # DYN-03: BETWEEN is inclusive at both ends, so a day range written
            # this way needs an end-of-day value whose precision depends on the
            # storage mode — the boundary row is kept on one platform and
            # dropped on another.
            if (between := DATE_BETWEEN.search(flat)) is not None:
                report(
                    "NOTE",
                    location,
                    f"`{name}` uses BETWEEN over what looks like a time range "
                    f"(:{between.group(1)}): prefer half-open "
                    ">= :from AND < :to (DYN-03)",
                )

            if " JOIN " in upper and SELECT_STAR.search(flat):
                report(
                    "ERROR",
                    location,
                    f"`{name}` selects * inside a join; use `table.**` so drift "
                    "maps each row class, or list the columns",
                )


# ----------------------------------------------------------------- migrations


def check_schema_snapshots() -> None:
    app_database = LIB / "core" / "database" / "app_database.dart"
    if not app_database.exists():
        return
    match = SCHEMA_VERSION.search(app_database.read_text(encoding="utf-8"))
    if match is None:
        report("NOTE", rel(app_database), "could not read schemaVersion")
        return

    version = int(match.group(1))
    snapshots = REPO / "drift_schemas"
    for candidate in range(1, version + 1):
        if not (snapshots / f"drift_schema_v{candidate}.json").exists():
            report(
                "ERROR",
                "drift_schemas/",
                f"schemaVersion is {version} but no snapshot for v{candidate}; "
                "the migration test has nothing to upgrade from",
            )


def check_datetime_contract() -> None:
    """The storage mode is a contract the future backend inherits."""
    if (REPO / "build.yaml").exists():
        return
    tables = [p for p in LIB.rglob("*.drift") if re.search(r"\bDATETIME\b", p.read_text(encoding="utf-8"), re.IGNORECASE)]
    if not tables:
        return
    report(
        "NOTE",
        "build.yaml (absent)",
        "DATETIME columns exist with no build.yaml, so drift's default storage "
        "(epoch seconds, UTC flag not preserved) applies. Pin the mode before "
        "the first sync ships — changing it later rewrites every timestamp",
    )


# ---------------------------------------------------------------------- main


def changed_files() -> set[str] | None:
    try:
        out = subprocess.run(
            ["git", "diff", "--name-only", "HEAD"],
            cwd=REPO,
            capture_output=True,
            text=True,
            check=True,
        )
    except (subprocess.CalledProcessError, FileNotFoundError):
        return None
    return {line.strip() for line in out.stdout.splitlines() if line.strip()}


def main() -> int:
    argv = sys.argv[1:]
    quiet = "--quiet" in argv
    only_changed = "--diff" in argv

    for check in (
        check_presentation_free_of_drift,
        check_domain_free_of_drift,
        check_single_opener,
        check_transactions_stay_in_data,
        check_custom_sql_declares_dependencies,
        check_no_interpolated_sql,
        check_custom_expression,
        check_sort_is_not_stringly_typed,
        check_no_wall_clock_in_data_layer,
        check_ascii_folding,
        check_queries,
        check_schema_snapshots,
        check_datetime_contract,
    ):
        check()

    results = findings
    if only_changed:
        changed = changed_files()
        if changed is not None:
            results = [f for f in results if f[1].split(":")[0] in changed]

    errors = [f for f in results if f[0] == "ERROR"]
    notes = [f for f in results if f[0] == "NOTE"]

    if not quiet or errors:
        for severity, location, message in errors + notes:
            print(f"{severity}  {location}\n       {message}")

    if not quiet:
        print(
            f"\ndrift check: {len(errors)} error(s), {len(notes)} note(s)"
            f"{' — clean' if not errors else ''}"
        )

    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
