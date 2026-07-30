import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Where observer output goes. Injected so a test can read what was written.
///
/// Positional, nullable trailing arguments rather than a named-argument record:
/// the only two callers are in this file, and the shape needs to match nothing
/// else.
typedef ProviderLogSink =
    void Function(String message, Object? error, StackTrace? stackTrace);

/// Prefix on every line, so provider output can be filtered apart from the
/// startup logging in `app/bootstrap.dart`.
const String _logName = 'memox.providers';

/// Severity that `dart:developer` uses for a provider failure. Matches the
/// `package:logging` SEVERE level that `bootstrap.dart` already emits.
const int _severe = 1000;

/// Severity for a state change. `FINE` — below the default filter, because a
/// state change is chatter until you are looking for it.
const int _fine = 500;

/// Reports provider failures, and optionally every state change.
///
/// **Why this exists rather than relying on devtools.** Riverpod 3 already
/// installs a `DevtoolObserver` in debug builds, so the state *inspector* was
/// never missing. What was missing is output when nobody is looking at the
/// inspector — and one Riverpod 3 behaviour makes that expensive: a provider
/// that throws is retried automatically, ten times, with a backoff that reaches
/// 6.4 seconds. During those retries the state is `AsyncLoading`, so the screen
/// shows a spinner for roughly thirteen seconds and then an error, with nothing
/// anywhere naming the original exception. That cost real time during M4.10
/// before the cause was found; `providerDidFail` fires on every attempt, which
/// makes the same situation self-describing.
///
/// **What it must never do: print a value.** A provider's value can be a card,
/// a list of cards, or a note, and AD-08 forbids logging card content at any
/// level while explicitly permitting IDs. So a state change is reported as the
/// *type* of the old and new values, never the values —
/// `AsyncData<List<DeckEntity>>`, not the decks. `test/core/state/` asserts
/// that with content that would be unmistakable if it leaked.
final class MemoxProviderObserver extends ProviderObserver {
  const MemoxProviderObserver({
    this.shouldLogStateChanges = false,
    ProviderLogSink? sink,
  }) : _sink = sink ?? _developerLog;

  /// Whether to report every state change, not just failures.
  ///
  /// Off by default. Failures are always worth a line; a stream of transitions
  /// is worth one only while you are reading them, so `bootstrap` turns it on
  /// from `EnvConfig.logLevel` and nothing else does.
  final bool shouldLogStateChanges;

  final ProviderLogSink _sink;

  @override
  void providerDidFail(
    ProviderObserverContext context,
    Object error,
    StackTrace stackTrace,
  ) => _sink('${_describe(context)} failed', error, stackTrace);

  @override
  void didUpdateProvider(
    ProviderObserverContext context,
    Object? previousValue,
    Object? newValue,
  ) {
    if (!shouldLogStateChanges) return;

    _sink(
      '${_describe(context)} ${_shapeOf(previousValue)} -> '
      '${_shapeOf(newValue)}',
      null,
      null,
    );
  }

  /// The provider's name, or its type when it has none.
  ///
  /// Generated providers always carry a name, so the fallback is only reached by
  /// a hand-written provider — worth naming rather than printing nothing.
  String _describe(ProviderObserverContext context) =>
      context.provider.name ?? context.provider.runtimeType.toString();

  /// The *type* of a value, never the value.
  ///
  /// A list's length is included because "the list went from 3 to 0" is the
  /// question being asked most of the time, and a count is not content.
  String _shapeOf(Object? value) {
    if (value == null) return 'null';
    if (value is List<Object?>) return '${value.runtimeType}(${value.length})';

    return value.runtimeType.toString();
  }
}

/// The default sink.
///
/// `dart:developer` rather than a logging package, and deliberately not a shared
/// abstraction: `bootstrap.dart` has an eight-line private equivalent, and
/// unifying two small functions into a logging layer is the guess that file
/// already declined to make. When M7 introduces a real logger, this becomes one
/// call into it.
void _developerLog(String message, Object? error, StackTrace? stackTrace) =>
    developer.log(
      message,
      name: _logName,
      error: error,
      stackTrace: stackTrace,
      level: error == null ? _fine : _severe,
    );
