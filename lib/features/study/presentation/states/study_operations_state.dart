import 'dart:async';

import 'package:flutter/foundation.dart';

/// What a session has in flight, and which run of it those belong to.
///
/// **An epoch alone answers "may this result be shown?" and not "has it
/// finished?"** — and leaving needs both. When `leave` fails, the session is
/// still running and the screen has to come back; but a write that was open
/// when ✕ was pressed may still be open now, and unlocking the input on top of
/// it invites the same card to be answered twice. So the two questions are
/// tracked separately: [isCurrent] decides whether a result may reach the
/// screen, [settled] decides when it is safe to accept input again.
///
/// Single-flight per kind, which is what the controller already enforces: one
/// write and one read at a time. Nothing here cancels anything — a transaction
/// that has started still commits, because BR-25 wants it to.
final class StudyOperations {
  int _epoch = 0;
  Completer<void>? _write;
  Completer<void>? _read;

  /// The run an operation starting now belongs to.
  int get epoch => _epoch;

  /// Whether an operation begun at [at] may still write to the session's state.
  bool isCurrent(int at) => at == _epoch;

  /// Everything already in flight becomes stale. Called before leaving, so the
  /// terminal state belongs to the leaving alone.
  void invalidate() => _epoch += 1;

  /// Marks a write started. **Call the returned callback when it finishes**,
  /// in a `finally` — a completer left open makes [settled] wait forever.
  VoidCallback startWrite() => _start(() => _write, (c) => _write = c);

  /// The same for a read.
  VoidCallback startRead() => _start(() => _read, (c) => _read = c);

  /// Resolves once nothing is in flight.
  ///
  /// Awaiting a future that has already completed is free, and a kind with
  /// nothing running is null — so this is "wait for whatever is there", not
  /// "wait for something to be there".
  Future<void> settled() async {
    await _write?.future;
    await _read?.future;
  }

  VoidCallback _start(
    Completer<void>? Function() read,
    void Function(Completer<void>?) write,
  ) {
    final done = Completer<void>();
    write(done);

    return () {
      if (identical(read(), done)) write(null);
      if (!done.isCompleted) done.complete();
    };
  }
}
