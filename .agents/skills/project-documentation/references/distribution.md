# Distribution and version identity

## Verified host conventions

Checked 2026-09-22 against [official Codex documentation](https://developers.openai.com/codex/skills/):
repository discovery scans `.agents/skills` from current directory through repo root;
the documented user-level location is `~/.agents/skills`. Same-name skills are not
merged and both can appear. No repo-over-global name precedence is promised there.
Codex supports symlinked skill folders, but mutable links do not pin team releases
and Windows checkout permissions vary. This mechanism uses verified copies.

The installed skill-installer also supports `$CODEX_HOME/skills` (legacy
`~/.codex/skills`). Inspect these candidates too, but do not install another global
copy there by default. Inspect lists candidates, not which one the host chose;
`--active` must name the actually loaded path. Discovery refresh is host behavior.

## One authoring source

The existing repository-level generic skill directory doubles as canonical authoring
source. It contains no project context; global and other repo installs are managed
copies. Only edit canonical source. It can move to a dedicated skill repository
without content changes. Stable source_id, version and payload hashes are recorded
in `skill-manifest.json`; installed receipts retain canonical provenance. Commit/tag
plus manifest pins a release. No command fetches a remote or merges branches.

Canonical source → seal/version → install/sync/update → global/repository copies.
A verified global copy may transport the same release to another repo; its receipt
retains the original canonical source, rather than becoming a second author.

Use `python "SKILL_DIR/scripts/skill_distribution.py" --help`. Examples:

```text
... release --source CANONICAL --version 2.0.0
... install --source CANONICAL --scope global
... install --source CANONICAL --scope repository --root TARGET_REPO
... sync --source CANONICAL --scope global
... update --source CANONICAL --scope repository --root TARGET_REPO --version 2.1.0
... verify --source CANONICAL --root TARGET_REPO
... inspect --root TARGET_REPO --active ACTUALLY_LOADED_SKILL
```

`--global-root` selects an explicit alternative user skill directory, useful for
isolated tests. Mutations reject symlinks/junctions and overlapping source/target.
Install requires an absent target. Sync is idempotent for the same sealed release
and refuses drift/version differences. Update requires the source version explicitly,
an intact target with matching source_id and compatibility with any target pin.
Pins are adjusted separately and deliberately; updates never modify repo config.

Release runs only on canonical source, after tests/review, and refuses same-version
content changes or downgrades. Hashes normalize UTF-8 text CRLF to LF so checkout
conversion is not drift; binary bytes are exact. Added/deleted/modified payload files
are detected. Cache and installation receipt are excluded from payload; receipt
identity is checked separately. This is integrity checking, not a publisher signature.
Install/update stages and validates the new directory before swapping, retaining
old content on failure. No force overwrite or automatic reconciliation of edits.

MUST verify after distribution and in review/CI when keeping copies. Workflow entry
requires inspect. Different valid releases are still reported as mismatches. With
a pin, active bytes must match it. Without a pin, conflicting copies require explicit
path/authority review before writes. Never assume newest wins. A missing canonical
checkout permits pinned offline use but cannot prove upstream freshness.

Exit 0: mechanical integrity passed; 1: drift/missing expected copy/release or pin
mismatch; 2: invalid input or unsafe mutation. Inspect always exposes other candidates
and their conflicts even when the explicitly selected active copy satisfies its pin.
