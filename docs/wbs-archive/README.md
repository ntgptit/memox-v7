# WBS archive

Closed WBS entries, moved out of `../wbs.md` on 2026-09-08 (M100.65) so the
living ledger holds only living work. **Nothing here was edited on the way
out** — each entry is byte-identical to the one that left.

These files are still policed. `check_docs.py`'s `_wbs_ledgers()` globs this
directory, so a retired id cannot be reused and a live task may depend on one
that closed. They are deliberately outside `_docs_md()`, so they carry no
7-field header and claim no source of truth: a retired entry is a record, not
a contract.

| File | Milestone | Entries | Lines |
|---|---|---|---|
| `t0-t1-m2-m3.md` | harness, project foundation, architecture foundation | 29 | 1,351 |
| `m4.md` | router and Drift foundation, deck and card slices | 83 | 4,844 |
| `m5.md` | study vertical slice — UC-05 | 28 | 1,556 |
| `m99.md` | adhoc feature and hardening work | 96 | 7,023 |
| `m100.md` | design-system reconciliation and screen consistency | 63 | 4,658 |

**Where to look for what.** A task id tells you the file: `M4.10ap` is in
`m4.md`, `M99.62` in `m99.md`. To find every mention of a task across both the
ledger and the archive:

```bash
grep -rn "M99\.62" docs/wbs.md docs/wbs-archive/
```

## What is still checked, and what is not

`check_docs.py` treats these five files as part of the same task-id space as
`../wbs.md`: the **duplicate-id scan**, the **dependency graph** (a live task
may depend on an archived one, and the edge must resolve), and the
**section-level check** (a task heading written at `##` instead of `###` is
invisible to both) all run over every file `_wbs_ledgers()` returns, archive
included.

What does **not** run here is the **9-field template check**
(`_check_m_task_template`) — the one that requires every `M`-level entry to
carry Status, Goal, Scope, Editable documents, Output, Acceptance criteria,
Dependencies, Tests required and Checklist phases, with a non-empty
acceptance-criteria block. That check reads `docs/wbs.md` alone, by design: a
closed entry is an immutable record of what happened, not a live contract that
still has to satisfy an evolving template, and re-validating 299 already-closed
entries on every CI run would buy nothing. If the template itself changes,
archived entries stay written the way they were closed — the id and dependency
checks above are the guarantees that actually matter for a retired task, and
those still hold.
