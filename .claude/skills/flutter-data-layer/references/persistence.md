# Drift, cache and secure storage

Location: `core/database/` for the database and migrations; DAOs live with their
feature in `features/<f>/data/local/`.

## Schema — SQL in `.drift` files

This project declares tables and queries in `.drift` files rather than Dart
table classes (decision AD-02 in `docs/architecture.md`). The reason worth
remembering: `drift_dev` analyses the SQL **at build time**, so a wrong column,
wrong type or bad join is a compile error rather than a runtime one.

```
lib/core/database/
├── app_database.dart      # @DriftDatabase, migration strategy
├── tables/
│   ├── decks.drift
│   └── cards.drift
└── queries/
    └── study.drift        # named queries for the review flow
```

```sql
-- tables/decks.drift
CREATE TABLE decks (
  id             TEXT     NOT NULL PRIMARY KEY,
  name           TEXT     NOT NULL,
  parent_deck_id TEXT     NULL REFERENCES decks(id) ON DELETE CASCADE,
  -- Denormalized root pointer. Every descendant carries the root's id; the root
  -- carries its own. This exists because resolving the root by walking
  -- parent_deck_id needs recursion, and the resolution sits inside the hottest
  -- query in the app.
  --
  -- NEVER write COALESCE(parent_deck_id, id) to find the root. It means
  -- "parent, or self if no parent", so at depth 3 it returns the level-2 deck.
  -- It is correct for a one-level tree, which is exactly what makes it
  -- dangerous — it works until someone nests one level deeper.
  root_deck_id   TEXT     NOT NULL,
  -- 'unset' | 'card' | 'deck'. A deck holds one kind of child, never both.
  -- Set by the first child created, not chosen at creation time.
  content_type   TEXT     NOT NULL,
  -- NULL means "belongs to the local profile". Nullable from day one so that
  -- adding auth later can backfill it without discarding offline-created data
  -- (AD-03).
  owner_id       TEXT     NULL,
  created_at     DATETIME NOT NULL,
  updated_at     DATETIME NOT NULL
) AS Deck;

CREATE INDEX idx_decks_parent ON decks (parent_deck_id);
CREATE INDEX idx_decks_root ON decks (root_deck_id);
```

Moving a subtree has to rewrite `root_deck_id` for every node in it, inside one
transaction. Missing a node produces a descendant pointing at the wrong root —
silent corruption, because queries still run and merely return less than they
should. `docs/data-model.md` carries the query that detects it.

```sql
-- tables/cards.drift
-- Content only. No scheduling columns — editing a card must not be able to
-- touch its schedule (BR-09), and separating the tables is what makes that
-- structurally impossible rather than merely intended.
CREATE TABLE cards (
  id         TEXT     NOT NULL PRIMARY KEY,
  deck_id    TEXT     NOT NULL REFERENCES decks(id) ON DELETE CASCADE,
  front      TEXT     NOT NULL,
  back       TEXT     NOT NULL,
  created_at DATETIME NOT NULL,
  updated_at DATETIME NOT NULL
) AS Card;

CREATE INDEX idx_cards_deck ON cards (deck_id);
```

```sql
-- tables/card_review_states.drift
-- One row per card, created with the card, destroyed and recreated on reset.
-- scheduler_type and scheduler_generation are duplicated from the root deck on
-- purpose: they turn "no card state from a stale generation" into something a
-- query can check, rather than something you have to trust.
CREATE TABLE card_review_states (
  card_id              TEXT     NOT NULL PRIMARY KEY REFERENCES cards(id) ON DELETE CASCADE,
  scheduler_type       TEXT     NOT NULL,
  scheduler_version    INTEGER  NOT NULL,
  scheduler_generation INTEGER  NOT NULL,
  due_at               DATETIME NULL,
  last_reviewed_at     DATETIME NULL,
  review_count         INTEGER  NOT NULL DEFAULT 0,
  lapse_count          INTEGER  NOT NULL DEFAULT 0,
  current_box          INTEGER  NULL,   -- eight_box only
  ease_factor          REAL     NULL,   -- sm2 only
  interval_days        INTEGER  NULL,   -- sm2 only
  repetitions          INTEGER  NULL    -- sm2 only
) AS CardReviewState;

CREATE INDEX idx_review_states_due ON card_review_states (due_at);
```

Per-scheduler columns are nullable and only the active scheduler's are filled.
The alternative — one JSON column holding scheduler state — is more flexible but
loses type-safety and cannot be queried, which contradicts the reason for
choosing `.drift` in the first place. A few NULL columns are much cheaper.

`AS Deck` names the generated row class. Without it you get `DecksData`, which
reads badly at every call site.

Named queries live beside the tables and generate typed methods:

```sql
-- queries/study.drift
-- Both queries aggregate over the whole tree via root_deck_id, so they work at
-- any nesting depth without recursion.
cardsDueForReview:
SELECT c.*, s.current_box AS current_box
FROM cards c
INNER JOIN card_review_states s ON s.card_id = c.id
INNER JOIN decks d ON d.id = c.deck_id
WHERE d.root_deck_id = :rootDeckId
  AND (s.due_at IS NULL OR s.due_at <= :now)
ORDER BY s.due_at ASC NULLS FIRST
LIMIT :limit;

dueCountPerRootDeck:
SELECT d.root_deck_id AS root_deck_id, COUNT(s.card_id) AS due_count
FROM decks d
LEFT JOIN cards c ON c.deck_id = d.id
LEFT JOIN card_review_states s
  ON s.card_id = c.id AND (s.due_at IS NULL OR s.due_at <= :now)
GROUP BY d.root_deck_id;
```

Both queries share one definition of "due". They must — a list screen counting
due cards differently from the session that fetches them produces a badge that
disagrees with reality, and it is the kind of bug nobody reports precisely.

Note what is **not** in this SQL: the interval table, and the rating→box mapping.
Those live in the scheduler config (AD-06). A day count inside a `WHERE` clause
is a magic number sitting outside the reach of the scheduler's unit tests, and it
is exactly where it will drift from the real table.

Name queries after the business verb (`cardsDueForReview`), not after the SQL
shape (`selectCardsWhereDue`) — the caller cares about the former.

Note `:now` is a **parameter**, not `CURRENT_TIMESTAMP`. Passing the time in is
what makes the query testable at an arbitrary point in time, and it matches the
same rule applied to the SRS use case (AD-06).

Wire them into the database:

```dart
@DriftDatabase(
  include: {
    'tables/decks.drift',
    'tables/cards.drift',
    'queries/study.drift',
  },
)
class AppDatabase extends _$AppDatabase { ... }
```

Use **client-generatable IDs** (UUID/ULID) rather than server auto-increment
integers. Offline creation needs an ID before any server has seen the row, and
retrofitting this later means rewriting every foreign key — which is why `uuid`
is a dependency from day one even though sync is far off.

Foreign keys need enabling per connection — Drift does not do it for you:

```dart
beforeOpen: (details) async {
  await customStatement('PRAGMA foreign_keys = ON');
}
```

Without that, `REFERENCES` and `ON DELETE CASCADE` are documentation, not
behaviour. Worth testing explicitly: delete a deck, assert its cards are gone.

## Indexes

Index the columns you actually filter, sort or join on. On a table of a few
hundred rows nothing is noticeable; at ten thousand, an unindexed filter is a
visible stutter.

Declare them in the `.drift` file next to the table, as shown above.

A composite index serves queries that use its columns left-to-right, so order
the columns by how you query. Verify rather than guess:

```sql
EXPLAIN QUERY PLAN SELECT * FROM cards WHERE deck_id = ? ORDER BY due_at;
```

`SCAN TABLE` in the output means the index is not being used.

## DAOs

One DAO per feature or aggregate, not one per table and not one giant DAO.
Select the columns you need; `SELECT *` on a wide table to read two fields is
wasted deserialisation on every row.

Multi-step writes go in a transaction so a mid-way failure cannot leave half the
change applied:

```dart
Future<void> replaceDeckCards(String deckId, List<CardsCompanion> cards) =>
    transaction(() async {
      await (delete(this.cards)..where((c) => c.deckId.equals(deckId))).go();
      await batch((b) => b.insertAll(this.cards, cards));
    });
```

For reactive UI, expose `watch()` streams. The screen then updates whenever the
data changes, from sync or from another screen, with no manual invalidation —
this is the main practical benefit of offline-first.

## Migrations

Every schema change increments `schemaVersion` and adds a step. Never delete or
recreate a table holding user data — a migration that drops data is
indistinguishable from data loss to the user.

```dart
@override
int get schemaVersion => 3;

@override
MigrationStrategy get migration => MigrationStrategy(
      onCreate: (m) => m.createAll(),
      onUpgrade: (m, from, to) async {
        if (from < 2) {
          await m.addColumn(decks, decks.isPendingSync);
        }
        if (from < 3) {
          await m.createIndex(idxCardsDeckDue);
        }
      },
      beforeOpen: (details) async {
        await customStatement('PRAGMA foreign_keys = ON');
      },
    );
```

Sequential `if (from < n)` blocks — not `else if`, and not a switch on `from`.
A user upgrading from version 1 to 3 must run both steps.

The `isPendingSync` step above is illustrative of exactly the migration this
project has deliberately deferred (AD-03): the sync bookkeeping columns are
cheap to add later precisely because this migration path is tested from the
start, which is what makes deferring them the right call rather than a gamble.

With `.drift` files, the migration API is unchanged — drift generates the same
Dart table symbols from SQL, so `m.addColumn(decks, decks.ownerId)` works
whether the table was declared in Dart or in SQL.

**Test migrations from every released version.** Drift's
`drift_dev schema dump` / `generate-migrations` produce fixtures for exactly
this. A migration bug only appears for users with existing data, which is
everyone except you.

## Cache strategy

**Not applicable while the project is local-first (AD-01).** There is no cache
because there is no remote — Drift is the source of truth, and a "TTL" on the
only copy of the data would be meaningless. This section applies from the
Spring Boot integration onward.

When that arrives, write the table below into `docs/architecture.md` — per data
type, not once for the whole app:

| Data | Cached | TTL | Source of truth | Stale behaviour |
|---|---|---|---|---|
| Deck list | yes | 5 min | server | show stale + refresh indicator |
| Deck content | yes | none | local | — |
| User profile | yes | 1 h | server | show stale |
| Search results | no | — | server | — |

Showing stale data with a refresh indicator beats a spinner over a blank screen:
the user sees something immediately and the update arrives behind it.

TTL lives in the repository. The UI never decides whether to read local or
remote — that policy belongs in one place, or it will drift per screen.

## Sync and conflicts

For offline-first, pick a conflict policy per entity and write it down:

- **Server wins** — simple, safe for reference data, silently discards local
  edits. Fine for things the user does not author.
- **Client wins** — for data only this device authors.
- **Last-write-wins** — needs a trustworthy timestamp. Device clocks are not
  trustworthy; use a server timestamp or a version counter.
- **Manual merge** — the only honest option for genuinely concurrent edits to
  the same field, and it needs UI, so only choose it where it is worth that.

A workable default: a monotonic `version` per row, incremented server-side. On
push, send the version you based the edit on; a mismatch means someone else
changed it, and the server returns 409 → `ConflictFailure`.

Sync flow: mark rows `isPendingSync` on local write → push pending rows when
connectivity returns → on success clear the flag and store the new version → on
conflict apply the declared policy. Keep the flag until the server confirms;
clearing it optimistically loses the edit if the push later fails.

## Secure storage

```dart
const _storage = FlutterSecureStorage(
  aOptions: AndroidOptions(encryptedSharedPreferences: true),
  iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
);
```

- Access and refresh tokens only. Not bulk data — secure storage is slow, and on
  Android it has size limits.
- Never store a raw password. If "remember me" is needed, store the token.
- SharedPreferences is not secure. Nothing sensitive goes there.
- **On logout, clear everything**: tokens, cached user data, and any
  feature-specific tables holding personal data. A device shared between users
  otherwise leaks the previous session's content.
- `KeychainAccessibility.first_unlock` keeps tokens readable for background
  refresh after a reboot without exposing them on a locked device.

If the database itself holds sensitive data, consider SQLCipher via
`sqlcipher_flutter_libs`. Decide this before launch — encrypting an existing
plaintext database in a migration is painful, and it is a decision better made
once in `docs/product.md` under sensitive data.
