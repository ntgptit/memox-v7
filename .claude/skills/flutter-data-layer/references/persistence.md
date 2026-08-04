# Cache, sync and secure storage

The database half of this file now lives in the `flutter-drift` skill, so that
one question has one answer: schema and `.drift` conventions, index design,
DAO/data-source boundaries, transactions, migrations and stream invalidation are
all there, together with what this project has already settled about them.

Load `flutter-drift` for any of that. What stays here is the policy that sits
*above* the database — what to cache, how to sync, and where secrets go.

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
