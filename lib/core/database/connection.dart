import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

/// The only place in `lib/` that opens a database (AD-08).
///
/// Everything else — bootstrap, features, repositories, DAOs — receives an
/// already-open `AppDatabase`. One opener is what makes the questions that
/// matter answerable in one file: where the file lives, whether the key is set,
/// whether foreign keys are on. Scattered across call sites, "is encryption
/// enabled" stops having a single answer, and AD-08 keeps encryption as a door
/// that can be opened later.
///
/// `driftDatabase` handles Android and web from one call: on Android it opens a
/// file in the app-private directory, on web it uses the WASM worker. Web is the
/// E2E channel (AD-04), so it must genuinely open — a build that quietly falls
/// back to a no-op database would let an E2E suite pass with no persistence at
/// all.
///
/// Nothing here logs a path, a query or a row. Card content, notes and learning
/// history are private (AD-08), and a database log is the easiest place to leak
/// all three at once.

/// Name of the on-device database file.
///
/// A constant because it is a migration-relevant fact: renaming it strands
/// every existing user's data behind a file nobody opens.
const String kDatabaseName = 'memox';

/// Opens the app's database for the current platform.
QueryExecutor openAppDatabaseConnection() {
  return driftDatabase(name: kDatabaseName);
}
