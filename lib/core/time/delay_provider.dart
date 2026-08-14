import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'delay_provider.g.dart';

/// Cancels a scheduled callback. Calling it after the callback has run, or
/// twice, is a no-op — the same contract `Timer.cancel` has.
typedef DelayHandle = void Function();

/// Runs [action] once, [delay] from now, and hands back the way to call it off.
///
/// **A function rather than a `Timer`, so a test can supply one that does not
/// wait.** A debounce measured against the real event loop is only assertable
/// with `await Future.delayed`, which makes "did it fire at 249ms or at 250?"
/// a race rather than a test — and the whole point of a debounce boundary is
/// that the two sides of it behave differently.
typedef DelayScheduler =
    DelayHandle Function(Duration delay, void Function() action);

/// The wall-clock scheduler, as a value the rest of the tree can override.
///
/// **In `core/` for `clockProvider`'s reason, and beside it on purpose.** A
/// delay belongs to no feature: search debounces its query, and the next screen
/// that needs to wait before acting would otherwise reach into
/// `features/search/presentation/` — a cross-feature presentation import the
/// architecture guard reports as an error.
///
/// `keepAlive`, like the clock: it holds no state, so rebuilding it per screen
/// would allocate for nothing, and a scheduler that changed identity mid-screen
/// would leave the timers it had already armed unowned.
@Riverpod(keepAlive: true)
DelayScheduler delayScheduler(Ref ref) =>
    (Duration delay, void Function() action) {
      final timer = Timer(delay, action);

      return timer.cancel;
    };
