import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/common.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/state/provider_observer.dart';
import 'package:memox/core/state/retry_policy.dart';

/// The observer, driven through a real container.
///
/// `ProviderObserverContext`'s constructor is `@internal`, so the hooks cannot be
/// called directly with a hand-made context — which is the better outcome: every
/// assertion here goes through the code path the app uses.
void main() {
  /// A distinctive string standing in for card content. If it ever reaches the
  /// log, `contains` finds it and no amount of careful reading was required.
  const String privateCardContent =
      'ほんやくする — to translate (private card content)';

  late List<String> lines;
  late List<Object> errors;

  MemoxProviderObserver observer({bool shouldLogStateChanges = false}) =>
      MemoxProviderObserver(
        shouldLogStateChanges: shouldLogStateChanges,
        sink: (message, error, stackTrace) {
          lines.add(message);
          if (error != null) errors.add(error);
        },
      );

  ProviderContainer containerWith(MemoxProviderObserver observed) {
    final container = ProviderContainer(
      observers: <ProviderObserver>[observed],
      // Without this the container's default retry re-runs every failing
      // provider ten times, so a one-failure test would assert against ten log
      // lines and take thirteen seconds to do it.
      retry: noAutomaticRetry,
    );
    addTearDown(container.dispose);

    return container;
  }

  setUp(() {
    lines = <String>[];
    errors = <Object>[];
  });

  group('failures', () {
    test('are reported with the provider name and the unwrapped error', () {
      final container = containerWith(observer());
      final failing = Provider<int>(
        (ref) => throw StateError('deck read failed'),
        name: 'failingProvider',
      );

      // `read` rethrows a `ProviderException` wrapping the original, not the
      // original — matched loosely on purpose, because the wrapper type is
      // riverpod's business and the assertion that matters is the next one.
      expect(() => container.read(failing), throwsA(isA<Exception>()));

      expect(lines, hasLength(1));
      expect(lines.single, contains('failingProvider'));
      expect(lines.single, contains('failed'));
      // The observer receives the exception the provider actually threw. That is
      // what makes the log line actionable: a `ProviderException` says only that
      // something upstream broke.
      expect(errors.single, isA<StateError>());
    });

    test('are reported even with state-change logging off', () {
      // The asymmetry is the design: an unexplained failure costs thirteen
      // seconds of spinner, so it is never the thing that gets filtered out.
      final container = containerWith(observer());
      final failing = Provider<int>(
        (ref) => throw StateError('boom'),
        name: 'quietModeProvider',
      );

      expect(() => container.read(failing), throwsA(isA<Exception>()));

      expect(lines, isNotEmpty);
    });
  });

  group('a Failure names its cause', () {
    // Without this the line read `deckListProvider failed` and the sink's
    // error printed `Instance of 'UnknownFailure'`: a migration that could not
    // run looked like an unexplained spinner.
    test('a SQLite cause reports its code and message', () {
      final container = containerWith(observer());
      final failing = Provider<int>(
        (ref) => throw DatabaseFailure(
          message: 'Could not save your changes. Please try again.',
          cause: SqliteException(
            extendedResultCode: 1,
            message: 'duplicate column name: sibling_position',
          ),
        ),
        name: 'migratingProvider',
      );

      expect(() => container.read(failing), throwsA(isA<Exception>()));

      expect(lines.single, contains('migratingProvider failed'));
      expect(lines.single, contains('SqliteException(1)'));
      expect(lines.single, contains('duplicate column name: sibling_position'));
    });

    test('never prints a bound parameter (AD-08)', () {
      final container = containerWith(observer());
      final failing = Provider<int>(
        (ref) => throw DatabaseFailure(
          message: 'Could not save your changes. Please try again.',
          cause: SqliteException(
            extendedResultCode: 2067,
            message: 'UNIQUE constraint failed: cards.id',
            causingStatement: 'INSERT INTO cards (front) VALUES (?)',
            parametersToStatement: <Object?>[privateCardContent],
          ),
        ),
        name: 'cardWriteProvider',
      );

      expect(() => container.read(failing), throwsA(isA<Exception>()));

      expect(lines.single, contains('UNIQUE constraint failed: cards.id'));
      expect(lines.single, isNot(contains(privateCardContent)));
      expect(lines.single, isNot(contains('INSERT INTO')));
    });

    test('any other cause is reduced to its type', () {
      final container = containerWith(observer());
      final failing = Provider<int>(
        (ref) => throw UnknownFailure(
          message: 'Could not save your changes. Please try again.',
          cause: StateError('failed for $privateCardContent'),
        ),
        name: 'unknownProvider',
      );

      expect(() => container.read(failing), throwsA(isA<Exception>()));

      expect(lines.single, contains('StateError'));
      expect(lines.single, isNot(contains(privateCardContent)));
    });
  });

  group('state changes', () {
    test('are silent unless asked for', () {
      final container = containerWith(observer());
      final counter = NotifierProvider<_Counter, int>(
        _Counter.new,
        name: 'counterProvider',
      );

      container.read(counter.notifier).increment();

      expect(lines, isEmpty);
    });

    test('report the provider and the shape of both values', () {
      final container = containerWith(observer(shouldLogStateChanges: true));
      final counter = NotifierProvider<_Counter, int>(
        _Counter.new,
        name: 'counterProvider',
      );

      container.read(counter.notifier).increment();

      expect(lines, hasLength(1));
      expect(lines.single, contains('counterProvider'));
      expect(lines.single, contains('int -> int'));
    });

    test('report a list length, because that is the usual question', () {
      final container = containerWith(observer(shouldLogStateChanges: true));
      final list = NotifierProvider<_Cards, List<String>>(
        _Cards.new,
        name: 'cardsProvider',
      );

      container.read(list.notifier).addAll(<String>['a', 'b', 'c']);

      expect(lines.single, contains('(0)'));
      expect(lines.single, contains('(3)'));
    });
  });

  group('AD-08: no content in the log, at any level', () {
    test('a state change reports the type, never the value', () {
      final container = containerWith(observer(shouldLogStateChanges: true));
      final list = NotifierProvider<_Cards, List<String>>(
        _Cards.new,
        name: 'cardsProvider',
      );

      container.read(list.notifier).addAll(<String>[privateCardContent]);

      expect(lines, hasLength(1));
      expect(lines.single, isNot(contains(privateCardContent)));
      expect(lines.single, isNot(contains('ほんやく')));
      // What it does say instead.
      expect(lines.single, contains('cardsProvider'));
      expect(lines.single, contains('(1)'));
    });

    test('a failure message carries no value either', () {
      // The error object itself goes to the sink separately, because a stack
      // trace is what makes a failure actionable. What must not happen is the
      // *message* line quietly growing a value someone pasted in while
      // debugging.
      final container = containerWith(observer());
      final failing = Provider<String>(
        (ref) => throw StateError('failed for $privateCardContent'),
        name: 'leakyProvider',
      );

      expect(() => container.read(failing), throwsA(isA<Exception>()));

      expect(lines.single, isNot(contains(privateCardContent)));
    });
  });
}

class _Counter extends Notifier<int> {
  @override
  int build() => 0;

  void increment() => state = state + 1;
}

class _Cards extends Notifier<List<String>> {
  @override
  List<String> build() => const <String>[];

  void addAll(List<String> cards) => state = <String>[...state, ...cards];
}
