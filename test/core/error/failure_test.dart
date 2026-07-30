import 'dart:io';

import 'package:drift/drift.dart' show DriftWrappedException;
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/drift_error_mapper.dart';
import 'package:memox/core/error/failure.dart';

void main() {
  const failures = <Failure>[
    NetworkFailure(message: 'No connection.'),
    UnauthorizedFailure(message: 'Please sign in again.'),
    ForbiddenFailure(message: 'You do not have access to this.'),
    ValidationFailure(message: 'Please check the highlighted fields.'),
    NotFoundFailure(message: 'That item no longer exists.'),
    ConflictFailure(message: 'That name is already in use.'),
    DatabaseFailure(message: 'Could not save your changes.'),
    CancelledFailure(message: 'Cancelled.'),
    UnknownFailure(message: 'Something went wrong.'),
  ];

  group('Failure', () {
    test('switch is exhaustive without a default branch', () {
      // If this stops compiling, a new Failure variant was added and every
      // switch in the app needs a decision — which is the entire reason the
      // hierarchy is sealed. A `default` branch would turn that compile error
      // into a silent "something went wrong" forever.
      String describe(Failure failure) => switch (failure) {
        NetworkFailure() => 'network',
        UnauthorizedFailure() => 'unauthorized',
        ForbiddenFailure() => 'forbidden',
        ValidationFailure() => 'validation',
        NotFoundFailure() => 'notFound',
        ConflictFailure() => 'conflict',
        DatabaseFailure() => 'database',
        CancelledFailure() => 'cancelled',
        UnknownFailure() => 'unknown',
      };

      expect(failures.map(describe).toSet(), hasLength(failures.length));
    });

    test('ValidationFailure carries typed problems, not field strings', () {
      const failure = ValidationFailure(
        message: 'Please check the highlighted fields.',
        problems: <Enum>{_TestProblem.nameEmpty},
      );

      expect(failure.problems, <Enum>{_TestProblem.nameEmpty});
      // Defaulting to empty keeps every call site from null-checking a map.
      expect(const NotFoundFailure(message: 'x').cause, isNull);
      expect(const ValidationFailure(message: 'x').problems, isEmpty);
    });

    test('no message leaks technical detail', () {
      for (final failure in failures) {
        for (final forbidden in <String>[
          'SELECT',
          'INSERT',
          'constraint failed',
          'Exception',
          '#0',
          'package:',
          'http',
          '.dart',
          '/',
        ]) {
          expect(
            failure.message,
            isNot(contains(forbidden)),
            reason: '${failure.runtimeType} exposes "$forbidden"',
          );
        }
      }
    });
  });

  group('mapDatabaseError', () {
    test('maps a Drift exception to DatabaseFailure and keeps the cause', () {
      final original = DriftWrappedException(
        message: 'writing to decks',
        cause: Exception('disk I/O error'),
        trace: StackTrace.current,
      );

      final failure = mapDatabaseError(original);

      expect(failure, isA<DatabaseFailure>());
      // The cause is what makes the log useful; dropping it would leave a
      // failure nobody can diagnose.
      expect(failure.cause, same(original));
    });

    test('maps a constraint violation to ConflictFailure (M4.9)', () {
      final failure = mapDatabaseError(
        Exception('UNIQUE constraint failed: decks.name'),
      );

      // A conflict is the one database failure a user can act on, so it gets
      // its own type rather than the generic DatabaseFailure.
      expect(failure, isA<ConflictFailure>());
      expect(failure.message.toLowerCase(), contains('conflict'));
    });

    test('table-driven: every known error shape maps to its failure type', () {
      final cases = <({Object error, Type expected})>[
        // Known conflicts → ConflictFailure.
        (
          error: Exception('UNIQUE constraint failed: decks.id'),
          expected: ConflictFailure,
        ),
        // A foreign key means the referenced row is gone, not that two values
        // clash. Every write checks its parent exists first, so this only
        // arrives when the row was deleted between that check and the write —
        // and "pick a different name" would be nonsense advice for it.
        (
          error: Exception('FOREIGN KEY constraint failed'),
          expected: NotFoundFailure,
        ),
        // NOT NULL and CHECK can only be our own defect: every column and every
        // enum value is written from a typed source. The user cannot act, so
        // they must not be told to try something different.
        (
          error: Exception('CHECK constraint failed: content_type'),
          expected: DatabaseFailure,
        ),
        (
          error: Exception('NOT NULL constraint failed: cards.front'),
          expected: DatabaseFailure,
        ),
        (
          error: DriftWrappedException(
            message: 'insert failed',
            cause: Exception('UNIQUE constraint failed: cards.id'),
            trace: StackTrace.empty,
          ),
          expected: ConflictFailure,
        ),
        // Other persistence errors → DatabaseFailure.
        (
          error: DriftWrappedException(
            message: 'writing to decks',
            cause: Exception('disk I/O error'),
            trace: StackTrace.empty,
          ),
          expected: DatabaseFailure,
        ),
        // Anything unrecognised → UnknownFailure, never a raw escape.
        (error: const FormatException('nonsense'), expected: UnknownFailure),
        (error: StateError('bad state'), expected: UnknownFailure),
      ];

      for (final testCase in cases) {
        final failure = mapDatabaseError(testCase.error);

        expect(
          failure.runtimeType,
          testCase.expected,
          reason: '${testCase.error} should map to ${testCase.expected}',
        );
        // The original always survives into the log path.
        expect(failure.cause, same(testCase.error));
      }
    });

    test('an unrecognised error still yields a Failure, never escapes', () {
      final failure = mapDatabaseError(const FormatException('nonsense'));

      expect(failure, isA<UnknownFailure>());
      expect(failure.cause, isA<FormatException>());
    });

    test('the mapped message never repeats the exception text', () {
      // SQLite says `UNIQUE constraint failed: decks.name` — a table and a
      // column name. That is precisely what must not reach a user.
      final failure = mapDatabaseError(
        Exception('UNIQUE constraint failed: decks.name'),
      );

      expect(failure.message, isNot(contains('decks')));
      expect(failure.message, isNot(contains('constraint')));
    });
  });

  test('core/error is pure Dart — failure.dart imports no Flutter', () {
    // The failure model is what domain code speaks. A Flutter import here would
    // make the whole error language unusable from `domain/`, which is where
    // AD-01's backend-readiness is actually won or lost.
    final source = File('lib/core/error/failure.dart').readAsStringSync();

    for (final forbidden in <String>[
      'package:flutter/',
      'package:drift/',
      'package:dio/',
    ]) {
      expect(source, isNot(contains(forbidden)));
    }
  });
}

/// A stand-in for a feature's problem enum.
///
/// `core/` must not import a feature, which is why `ValidationFailure.problems` is
/// typed `Set<Enum>`: the concrete values are declared by whichever feature threw.
enum _TestProblem { nameEmpty }
