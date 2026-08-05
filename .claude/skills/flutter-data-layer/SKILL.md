---
name: flutter-data-layer
description: Networking and persistence for this Flutter app. Today only the persistence half is live — dio is deliberately not a dependency (AD-05), so the networking guidance here is reference for the backend phase, not current work. Covers the future shared Dio client with auth/logging/error/token-refresh/request-ID interceptors, DTO-to-entity mapping, pagination and error-response contracts, offline and retry behaviour, Drift schema design with indexes and migrations, cache strategy with TTL and a declared source of truth, conflict resolution and sync, and secure storage of tokens. Use this skill when calling an API, adding or changing a repository implementation, designing database tables or writing a Drift migration, deciding what to cache or how to sync, handling offline state, or storing anything sensitive. Covers checklist phases 10 and 11.
---

# Data layer: networking and persistence

Covers checklist Phases 10 (networking) and 11 (database, cache, secure
storage).

The repository is the boundary. Above it, domain entities and `Failure`. Below
it, DTOs, Dio and Drift. Nothing from below crosses up — that single rule is
what keeps the UI testable and the domain framework-free.

Read `references/networking.md` for the Dio client and interceptor setup, and
`references/persistence.md` for cache and sync policy.

**For anything below the repository — `.drift` schema and queries, indexes,
migrations, DAOs, transactions, Drift stream invalidation, or reviewing a
database PR — load `flutter-drift` instead.** That skill owns the database in
depth and knows what this project has already settled; this one owns the
repository contract above it.

## Source of truth — already decided for this project

**memox is local-first with no backend yet (AD-01 in `docs/architecture.md`).**
Drift is the source of truth; reads come from `watch()` streams; there is no
remote data source and no cache layer. The Spring Boot backend arrives later,
and the repository contract is what lets it arrive without touching `domain/`
or `presentation/`.

That means the networking half of this skill —
`references/networking.md` — is **reference material for a later phase**, not
something to build now. `dio` is deliberately not a dependency yet (AD-05).

The generic reasoning below is kept because it is what makes the decision
reviewable when the backend lands.

**Offline-first** — the database is the source of truth. Reads always come from
Drift and are exposed as a stream, so the UI updates when data changes for any
reason. The network is a background process that fills the database. Writes go
to the database first with a pending-sync marker, then upload. This is more work
up front and dramatically better under bad connectivity.

**Online-first** — the network is the source of truth, the database is a cache
with a TTL. Reads try the network, fall back to cache, and say so in the UI when
they are showing stale data.

Whichever it is, write it in `docs/architecture.md`. And the UI must never
choose: a widget deciding "if offline read local else read remote" has pulled a
data-layer policy into presentation, and that policy will then differ per screen.

## Repository shape

```dart
final class DeckRepositoryImpl implements DeckRepository {
  const DeckRepositoryImpl(this._remote, this._local, this._mapper);

  @override
  Future<List<Deck>> getDecks() async {
    try {
      final dtos = await _remote.fetchDecks();
      await _local.upsertAll(dtos);
      return dtos.map(_mapper.toEntity).toList();
    } on DioException catch (e, s) {
      _logger.warning('fetchDecks failed', e, s);
      final cached = await _local.getAll();
      if (cached.isNotEmpty) return cached.map(_mapper.toEntity).toList();
      throw mapDioException(e);          // -> Failure
    } on DriftWrappedException catch (e, s) {
      _logger.error('local read failed', e, s);
      throw DatabaseFailure(message: 'Could not read local data', cause: e);
    }
  }
}
```

What that demonstrates: exceptions are caught at this boundary and only this
boundary; the original is logged with its stack trace and then discarded from
the user-facing path; the returned type is a domain entity, never a DTO.

Put `mapDioException` in `core/error/` and use it from every repository, so the
same status code cannot produce different failures in different features. Test
it directly (Phase 15.1) — it is high-traffic code that manual testing rarely
exercises.

## DTO and entity are different types

`*_model.dart` in `data/models/` is the wire shape: nullable where the server is
nullable, named as the server names things, `json_serializable` annotations.
`*_entity.dart` in `domain/entities/` is the shape the app reasons about:
non-nullable where the app requires a value, named in domain language.

The mapper between them is where you handle the server's inconsistencies — a
missing field, a date as a string, an enum value you have never seen. Handle an
unknown enum value by mapping to a known `unknown` variant rather than throwing;
a server adding a status should not crash the app for every existing user.

Skipping the split — passing DTOs to the UI — means every server field rename
becomes a UI change, and every nullable server field becomes a null check in a
widget.

## Non-negotiables for this layer

- Never log tokens, passwords, or anything listed as sensitive in
  `docs/product.md`. Redact by key name in the logging interceptor, not by
  remembering at each call site.
- Verbose HTTP logging is development-only, gated on `EnvConfig.logLevel`.
- Tokens go in `flutter_secure_storage`, never in SharedPreferences, and are
  cleared on logout along with any cached user data — otherwise the next user of
  the device sees the previous one's content.
- Never retry a non-idempotent mutation blindly. A retried POST can double-charge
  or double-create. Retry GETs; retry mutations only with an idempotency key the
  server honours.
- Wrap multi-step writes in a transaction, so a failure halfway does not leave
  half-applied state.
- Never delete user data on a schema migration.

## Checks before the data layer is done

Now (local-first, AD-05 in force):

- [ ] Source of truth declared in `docs/architecture.md` and followed everywhere.
- [ ] No Drift exception escapes a repository.
- [ ] Exception→failure mapping in one place, with tests.
- [ ] Generated row types never reach presentation.
- [ ] Sensitive fields redacted in logs; verbose logging off in production.
- [ ] Mutations are not blindly retried; duplicate submits are prevented.
- [ ] Indexes exist for the queries actually run.
- [ ] Migration tested from every released schema version.

When the backend lands (deferred with AD-05):

- [ ] No `DioException` escapes a repository; DTOs never reach presentation.
- [ ] Timeouts set for connect, receive and send.
- [ ] Token refresh handles concurrent 401s without a refresh storm.
- [ ] Requests cancelled when their screen goes away.
- [ ] Tokens in secure storage, cleared on logout.
