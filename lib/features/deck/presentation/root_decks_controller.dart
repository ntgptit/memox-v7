import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../app/di/deck_repository_provider.dart';
import '../domain/deck_entity.dart';

part 'root_decks_controller.g.dart';

/// Every root deck, re-emitted whenever the tree changes (UC-06, A2).
///
/// A stream provider rather than a future: `watchRootDecks()` already re-emits
/// on every write, so a deck created on another screen reaches this list
/// without anyone asking for a refresh. That is also why the screen has no
/// pull-to-refresh — there is nothing a manual reload could produce that the
/// stream has not already delivered.
///
/// `autoDispose` (the `@riverpod` default) is deliberate here even though the
/// repository below is kept alive: the subscription is what costs something,
/// and it should end when the last screen watching it goes away.
///
/// Re-subscribing is `ref.invalidate(rootDecksProvider)`. That disposes this
/// provider and builds it again, which opens a *new* `watch()` on the DAO —
/// the reason the error state's retry button genuinely retries rather than
/// re-rendering the same dead stream.
///
/// This file is named `_controller` and not `_provider` on purpose: the guard's
/// `widget_ui_files` scope forbids `ref.watch(...RepositoryProvider)` and
/// exempts controllers, because a controller is exactly where that read
/// belongs. A `*_provider.dart` here would be reported, correctly.
@Riverpod(retry: noAutomaticRetry)
Stream<List<DeckEntity>> rootDecks(Ref ref) =>
    ref.watch(deckRepositoryProvider).watchRootDecks();

/// Turns off Riverpod 3's automatic retry ladder for this read.
///
/// The default is not neutral here. `ProviderContainer.defaultRetry` re-runs a
/// failed provider up to ten times with exponential backoff — and while it is
/// retrying the state is `AsyncLoading`, not `AsyncError`. On this screen that
/// means a failed read spins for roughly thirteen seconds before the user is
/// told anything went wrong, and then the screen may flip back out from under
/// them mid-sentence when a later attempt succeeds.
///
/// It is also the wrong shape of remedy: this read is a local SQLite query, not
/// a flaky network call. A database that cannot be read does not start working
/// because 6.4 seconds passed. The retry that belongs here is the one the user
/// can see and control — the button on the error state, which invalidates the
/// provider and opens a fresh `watch()`.
///
/// Returning `null` means "do not retry". It is a top-level function because an
/// annotation argument has to be a constant.
Duration? noAutomaticRetry(int retryCount, Object error) => null;
