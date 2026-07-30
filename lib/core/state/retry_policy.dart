/// Retry policies for Riverpod providers.
///
/// **In `core/` because the reasoning is not feature-specific.** It started in
/// the deck feature, which would have forced the next feature that reads the
/// database to import `features/deck/presentation/…` — a cross-feature
/// presentation import that `check_architecture.sh` reports as an error.
library;

/// Turns off Riverpod 3's automatic retry ladder.
///
/// The default is not neutral. `ProviderContainer.defaultRetry` re-runs a failed
/// provider up to ten times with exponential backoff, and **while it is retrying
/// the state is `AsyncLoading`, not `AsyncError`**. On a screen that means a
/// failed read spins for roughly thirteen seconds before the user is told
/// anything went wrong, and may then flip out from under them when a later
/// attempt succeeds.
///
/// It is also the wrong remedy for a local read: a SQLite query is not a flaky
/// network call, and a database that cannot be read does not start working
/// because 6.4 seconds passed. The retry that belongs there is the one the user
/// can see and control — the button on the error state, which invalidates the
/// provider and opens a fresh read.
///
/// **Use it on every local database read.** Leave the default in place for
/// anything genuinely transient, which today is nothing: `dio` is deliberately
/// not a dependency (AD-05).
///
/// Returning `null` means "do not retry". It is a top-level function because an
/// annotation argument has to be a constant:
///
/// ```dart
/// @Riverpod(retry: noAutomaticRetry)
/// Stream<List<Thing>> things(Ref ref) => ...;
/// ```
Duration? noAutomaticRetry(int retryCount, Object error) => null;
