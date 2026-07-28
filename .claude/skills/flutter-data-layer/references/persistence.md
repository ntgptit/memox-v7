# Drift, cache and secure storage

Location: `core/database/` for the database and migrations; DAOs live with their
feature in `features/<f>/data/local/`.

## Schema

```dart
class Decks extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 200)();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  // Offline-first bookkeeping — see "Sync" below.
  BoolColumn get isPendingSync => boolean().withDefault(const Constant(false))();
  IntColumn get version => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

class Cards extends Table {
  TextColumn get id => text()();
  TextColumn get deckId => text().references(Decks, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get dueAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
```

Use **client-generatable IDs** (UUID/ULID) rather than server auto-increment
integers. Offline creation needs an ID before the server has seen the row, and
retrofitting this later means rewriting every foreign key.

Foreign keys need enabling per connection — Drift does not do it for you:

```dart
beforeOpen: (details) async {
  await customStatement('PRAGMA foreign_keys = ON');
}
```

Without that, `references` and `onDelete: cascade` are documentation, not
behaviour.

## Indexes

Index the columns you actually filter, sort or join on. On a table of a few
hundred rows nothing is noticeable; at ten thousand, an unindexed filter is a
visible stutter.

```dart
@TableIndex(name: 'idx_cards_deck_due', columns: {#deckId, #dueAt})
class Cards extends Table { ... }
```

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

**Test migrations from every released version.** Drift's
`drift_dev schema dump` / `generate-migrations` produce fixtures for exactly
this. A migration bug only appears for users with existing data, which is
everyone except you.

## Cache strategy

Write this in `docs/architecture.md` — per data type, not once for the app:

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
