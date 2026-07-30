import 'package:drift/drift.dart';
import 'package:sqlite3/common.dart';

import 'failure.dart';

/// Turns a persistence exception into a [Failure] at the repository boundary.
///
/// This file is the only place in the app allowed to know what a Drift or SQLite
/// exception looks like. Above it, every layer speaks [Failure] — a
/// `DriftWrappedException` reaching a widget means this boundary was skipped.
///
/// It lives in `core/` rather than `domain/` precisely because it imports Drift:
/// `domain/` stays pure so AD-01's backend-readiness holds.
///
/// The mapping deliberately throws away the exception text. SQLite messages read
/// like `UNIQUE constraint failed: decks.name` — a table and column name, which is
/// exactly the kind of detail that must not reach a user. The original is kept in
/// [Failure.cause] for the log.
///
/// **What actually arrives here.** The repositories check every business
/// condition *before* mutating and throw their own `ConflictFailure` or
/// `NotFoundFailure` — 25 such throws across Deck and Card. So a raw constraint
/// violation reaching this function means one of two things: a row changed between
/// the guard and the write, or there is a bug. Which of the two decides what the
/// user should be told, and that is why the three kinds below are told apart
/// rather than lumped into one "conflict".
Failure mapDatabaseError(Object error) {
  final kind = _constraintKindOf(error);
  if (kind != null) return _fromConstraint(kind, error);

  // A SQLite error that is not a constraint violation — a malformed statement, a
  // busy file, a corrupt page. It reached us from the database, so it is a
  // `DatabaseFailure`; `UnknownFailure` would be less true than what we know, and
  // that type is for errors with no persistence origin at all.
  if (error is SqliteException) {
    return DatabaseFailure(message: _genericMessage, cause: error);
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

/// The three kinds of constraint violation, separated because the user's next
/// move differs for each.
enum _ConstraintKind {
  /// A duplicate primary key or unique value. The user can act: choose another
  /// name. This is the only one that is genuinely a *conflict*.
  uniqueness,

  /// A foreign key pointing at a row that is not there. Every write that has a
  /// parent checks the parent exists first, so this means the row was deleted
  /// between that check and the write — the thing being changed is **gone**, not
  /// in conflict, and telling the user to pick a different value would be
  /// nonsense.
  missingReference,

  /// A `NOT NULL` or `CHECK` violation. Every column and every enum value is
  /// written from a typed source, so this can only be our own defect. The user
  /// cannot act on it and must not be told to try something different.
  schemaRule,
}

Failure _fromConstraint(_ConstraintKind kind, Object error) => switch (kind) {
  _ConstraintKind.uniqueness => ConflictFailure(
    message: 'That change conflicts with something already saved.',
    cause: error,
  ),
  _ConstraintKind.missingReference => NotFoundFailure(
    message: 'The item being changed no longer exists.',
    cause: error,
  ),
  _ConstraintKind.schemaRule => DatabaseFailure(
    message: _genericMessage,
    cause: error,
  ),
};

const String _genericMessage = 'Could not save your changes. Please try again.';

/// `SQLITE_CONSTRAINT`. Every constraint violation shares this primary code; the
/// extended code says which kind.
const int _sqliteConstraint = 19;

const int _constraintCheck = 1811; // SQLITE_CONSTRAINT_CHECK
const int _constraintForeignKey = 787; // SQLITE_CONSTRAINT_FOREIGNKEY
const int _constraintNotNull = 1299; // SQLITE_CONSTRAINT_NOTNULL
const int _constraintPrimaryKey = 1555; // SQLITE_CONSTRAINT_PRIMARYKEY
const int _constraintUnique = 2067; // SQLITE_CONSTRAINT_UNIQUE

/// Which kind of constraint failed, or null when the error is not one.
///
/// **The result code, not the message.** SQLite does report the kind numerically
/// — verified against a real database: a duplicate primary key is 1555, a foreign
/// key is 787, a `NOT NULL` is 1299, and all three share primary code 19 while a
/// syntax error is 1. Reading the code rather than the prose matters twice over:
/// the text is English and version-dependent, and all three kinds contain the
/// literal `constraint failed`, so a text match cannot separate the one the user
/// can act on from the two they cannot.
_ConstraintKind? _constraintKindOf(Object error) {
  final sqlite = _sqliteExceptionOf(error);
  if (sqlite != null) {
    if (sqlite.resultCode != _sqliteConstraint) return null;

    return switch (sqlite.extendedResultCode) {
      _constraintPrimaryKey || _constraintUnique => _ConstraintKind.uniqueness,
      _constraintForeignKey => _ConstraintKind.missingReference,
      _constraintNotNull || _constraintCheck => _ConstraintKind.schemaRule,
      // A constraint kind SQLite has and this list does not. Treated as our
      // defect rather than as a conflict: guessing "try another value" for an
      // unknown rule is the wrong guess more often than not.
      _ => _ConstraintKind.schemaRule,
    };
  }

  return _constraintKindFromText(error);
}

/// The typed exception, unwrapped from drift's wrapper if it is inside one.
SqliteException? _sqliteExceptionOf(Object error) {
  if (error is SqliteException) return error;
  final cause = error is DriftWrappedException ? error.cause : null;

  return cause is SqliteException ? cause : null;
}

/// The fallback for an error that carries no result code.
///
/// Kept because not every path produces a typed `SqliteException` — a wrapper, a
/// future drift version, or a test double can arrive with only a message. It
/// classifies by *kind* rather than treating every `constraint failed` as a
/// conflict, so the fallback reaches the same answer as the code path instead of
/// a more optimistic one.
_ConstraintKind? _constraintKindFromText(Object error) {
  final text = error.toString().toLowerCase();
  if (!text.contains('constraint')) return null;

  if (text.contains('unique constraint') ||
      text.contains('primary key constraint')) {
    return _ConstraintKind.uniqueness;
  }
  if (text.contains('foreign key constraint')) {
    return _ConstraintKind.missingReference;
  }
  if (text.contains('not null constraint') ||
      text.contains('check constraint')) {
    return _ConstraintKind.schemaRule;
  }

  // `constraint failed` with no kind named. Conservative on purpose.
  return text.contains('constraint failed') ? _ConstraintKind.schemaRule : null;
}
