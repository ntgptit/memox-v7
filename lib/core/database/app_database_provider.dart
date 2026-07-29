import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'app_database.dart';

part 'app_database_provider.g.dart';

/// The one open [AppDatabase] the running app uses.
///
/// `keepAlive` because a database is not a per-screen resource. An autoDispose
/// provider would close the file the moment the last screen stopped watching
/// and reopen it on the next read — every open re-runs `beforeOpen`, and a
/// Drift `watch()` stream held across that boundary would be listening to a
/// closed executor.
///
/// It builds the connection through [AppDatabase.open], so
/// `core/database/connection.dart` stays the only place in `lib/` that opens
/// one (AD-08). This provider decides *lifetime*, not *configuration*.
@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) {
  final database = AppDatabase.open();

  // `unawaited` rather than passing `database.close` straight in: `onDispose`
  // takes a synchronous callback, so the future would be discarded silently —
  // which `discarded_futures` is promoted to an error to prevent.
  ref.onDispose(() {
    unawaited(database.close());
  });

  return database;
}
