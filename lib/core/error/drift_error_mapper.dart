import 'package:drift/drift.dart';

import 'failure.dart';

/// Turns a persistence exception into a [Failure] at the repository boundary.
///
/// This file is the only place in the app allowed to know what a Drift
/// exception looks like. Above it, every layer speaks [Failure] — a
/// `DriftWrappedException` reaching a widget means this boundary was skipped.
///
/// It lives in `core/` rather than `domain/` precisely because it imports
/// Drift: `domain/` stays pure so AD-01's backend-readiness holds.
///
/// The mapping deliberately throws away the exception text. SQLite messages
/// read like `UNIQUE constraint failed: decks.name` — a table and column name,
/// which is exactly the kind of detail that must not reach a user. The original
/// is kept in [Failure.cause] for the log.
Failure mapDatabaseError(Object error) {
  // A conflict is worth distinguishing: it is the one database failure a user
  // can usually act on, by choosing a different name.
  if (_isConstraintViolation(error)) {
    return DatabaseFailure(
      message: 'That change conflicts with something already saved.',
      cause: error,
    );
  }

  if (error is DriftWrappedException) {
    return DatabaseFailure(message: _genericMessage, cause: error);
  }

  if (error is InvalidDataException) {
    return DatabaseFailure(message: _genericMessage, cause: error);
  }

  if (error is CouldNotRollBackException) {
    return DatabaseFailure(message: _genericMessage, cause: error);
  }

  return UnknownFailure(message: _genericMessage, cause: error);
}

const String _genericMessage = 'Could not save your changes. Please try again.';

/// SQLite reports constraint violations through the message rather than a
/// distinct type, so this is a text check by necessity — done here, on the
/// exception, and never on anything that reaches a user.
bool _isConstraintViolation(Object error) {
  final text = error.toString().toLowerCase();

  return text.contains('constraint failed') ||
      text.contains('unique constraint') ||
      text.contains('foreign key constraint');
}
