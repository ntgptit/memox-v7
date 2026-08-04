# Schema conventions

Everything here is about decisions that are cheap now and expensive after
release. A column name can be changed in an afternoon while the app is
unreleased; afterwards it costs a migration, a snapshot, a test and a risk.

## Naming

| Thing | Form | Example |
|---|---|---|
| Table | plural `snake_case` | `decks`, `card_review_states`, `review_history` |
| Column | `snake_case` | `deck_id`, `created_at`, `is_flagged` |
| Primary key | `id` | `id TEXT NOT NULL PRIMARY KEY` |
| Foreign key | `<entity>_id` | `deck_id`, `card_id`, `session_id` |
| Timestamp | `<verb>_at` | `created_at`, `updated_at`, `first_review_at` |
| Boolean | `is_` / `has_` / `can_` | `is_flagged`, `has_completed` |
| Index | `idx_<table>_<cols>` | `idx_cards_deck_created` |
| Unique index | `uq_<table>_<cols>` | `uq_tags_owner_folded` |
| Named query | `lowerCamelCase` | `watchCardsByDeck`, `cardStateCountsByDeck` |

Three naming failures that are worth catching in review because they never get
fixed later:

- **A UI name on a database column.** `card_screen_title` ties a column to a
  widget that will be renamed twice before release. Name what the value *is*.
- **An ambiguous abbreviation.** `sts`, `flg`, `dt`, `cd` — every reader has to
  guess, and two readers guess differently.
- **A SQL keyword as an identifier.** `order`, `group`, `index`, `check` compile
  in some positions and fail in others, which is worse than failing everywhere.

## Primary keys

Use a client-generated UUID stored as `TEXT`, and generate it before the insert,
not inside it. Two reasons, and only the second is obvious:

- A device that creates a row offline must be able to reference it immediately —
  in a foreign key, in a log, in a queued mutation.
- When the backend arrives, rows already exist on devices. If IDs were assigned
  by the database, sync has to renumber them and rewrite every reference, on
  every device, once.

`INTEGER PRIMARY KEY AUTOINCREMENT` plus a `public_id TEXT UNIQUE` is a valid
alternative when rowid locality genuinely matters, but it means two identities
per row and every join has to pick one. Do not mix the two styles across
features; whichever is chosen, the API contract uses the same one.

## Nullability

Default to `NOT NULL`. Make a column nullable only when `NULL` is a *distinct
business state* you can name.

`NULL` must never stand in for:

| Instead of | Store |
|---|---|
| empty string | `''` with `NOT NULL`, or `NULL` — pick one and document which |
| `false` | `0` with `NOT NULL DEFAULT 0` |
| zero | `0` |
| "the UI has not loaded it yet" | nothing — that is presentation state |

When `NULL` *is* meaningful, say which meaning in a comment, because there are
four and they are not interchangeable: **not yet set**, **does not apply**,
**deliberately cleared**, **not yet synced**.

This project uses the distinction deliberately: `example`, `hint` and
`pronunciation` are `NULL` when never filled, and the domain folds `''` to `NULL`
so there is exactly one spelling of "empty" (BR-95). `due_at` is `NULL` for a card
that has never been scheduled, which is why "due" is `due_at IS NULL OR due_at <=
:now` and not just the comparison.

## Constraints

The schema is the last line that holds when a bug, a migration or a future
backend writes rows the UI never would. Form validation is a courtesy to the
user; a constraint is a guarantee to the program.

- **Foreign keys on every real relationship**, with an explicit `ON DELETE`.
  Choose it deliberately:
  - `CASCADE` — the child cannot exist without the parent (a review state without
    its card is garbage).
  - `RESTRICT` — deleting the parent is a mistake the user should be told about.
  - `SET NULL` — the relationship is optional and its absence is meaningful.

  `CASCADE` everywhere by reflex is how a single delete silently removes data
  nobody meant to lose.
- **`UNIQUE` for business invariants**, including composite uniqueness for
  many-to-many links. `card_tags(card_id, tag_id)` as a primary key is what makes
  "add a tag twice" an idempotent no-op instead of a constraint error the
  repository has to catch and interpret.
- **`CHECK` for simple invariants** that are true regardless of who writes:

  ```sql
  CHECK (is_flagged IN (0, 1))
  CHECK (current_box BETWEEN 1 AND 8)
  CHECK (completed_at IS NULL OR completed_at >= started_at)
  ```

A constraint added later has to cope with rows that already violate it — see
`migrations.md`. Adding it now is free; adding it in six months is a data-cleanup
project.

## Booleans

SQLite has no boolean type. This schema stores `INTEGER NOT NULL DEFAULT 0` with
`CHECK (x IN (0, 1))`, which keeps the column honest against writers that are not
this app. Drift maps it to `bool` on the Dart side.

## Timestamps

Store instants in **UTC**, convert to local only in presentation. A timestamp
formatted for display (`2026/08/04 19:30`) must never be stored — it is not
comparable, not sortable across locales, and not recoverable.

A date without a time — a birthday, a due *day* — is not an instant. Storing it as
a UTC timestamp makes it shift a day for some users. Store it as `TEXT` in
`YYYY-MM-DD` and say so in a comment.

**Never mix epoch seconds and epoch milliseconds** in one schema. If a column
holds one and a comparison assumes the other, everything is either in 1970 or in
55000 AD, and the query still runs.

The storage-mode contract for this repo is described in `project-baseline.md` —
read it before adding a `DATETIME` column, and write a round-trip test for any
new timestamp column (write, read back, assert equality including UTC-ness).

## Enums and status codes

Persist enums as **stable lowercase text codes**, never as ordinals.

```sql
-- good: meaning survives a reordering of the Dart enum
scheduler_type TEXT NOT NULL CHECK (scheduler_type IN ('eight_box', 'sm2'))

-- bad: inserting a value in the middle of the Dart enum silently rewrites history
scheduler_type INTEGER NOT NULL
```

The Dart side maps code ↔ enum in one converter, and the same codes go on the API
DTO when the backend arrives — one vocabulary, three layers.

Decide what happens on an **unknown code** before you need it. Reading a value
this build does not know is a real case the moment two app versions share a
database or a server. The options are reject, map to a known `unknown` variant,
or preserve the raw string; the wrong answer is a `switch` that throws inside a
list read and takes the whole screen down.

Test every code round-trips. It is a three-line test per enum and it catches the
typo that would otherwise corrupt rows silently.

## Where a fact belongs

Before adding a column, check it is not one of these:

| The fact | Belongs in |
|---|---|
| Derivable from other columns (a display band, a percentage) | a Dart projection, computed on read |
| An algorithm parameter (box intervals, SM-2 factors) | the scheduler in Dart — in SQL, tuning becomes a migration |
| UI state (window size, selected filter, expanded/collapsed) | a Riverpod provider |
| Different lifetime from the rest of the row (content vs schedule vs history) | its own table |

That last row is the one this schema is built around, and it is worth restating:
`cards` holds content, `card_review_states` holds the schedule, `review_history`
is append-only. They are separate because reset drops the schedule and keeps the
content and the history. A column added to the wrong one of the three breaks a
rule that no test in the feature you are working on will notice.
