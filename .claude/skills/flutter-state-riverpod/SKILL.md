---
name: flutter-state-riverpod
description: Riverpod 3.x provider and controller design for this Flutter app — when to use @riverpod codegen, Notifier vs AsyncNotifier, family and autoDispose, how to model screen state as an immutable sealed class covering initial/loading/loaded/empty/error/refreshing/submitting, separating data from task status, and running side effects like navigation, snackbars and dialogs without firing them on rebuild. Use this skill when creating or changing a provider or controller, modelling screen state, deciding where async work belongs, fixing an infinite rebuild or a provider that refuses to dispose, or when a controller is tempted to hold a BuildContext. Covers checklist phase 9.
---

# State management with Riverpod

Covers checklist Phase 9. Riverpod 3.x with code generation.

Riverpod 3 note: the generated per-provider `Ref` subclasses from 2.x are gone.
Write `Ref ref`, not `MyThingRef ref`. Examples found online for 2.x will not
compile.

## Provider design

Prefer `@riverpod` codegen — it produces the right provider type, correct
`autoDispose` behaviour and typed families without you choosing them by hand.

```dart
@riverpod
Future<List<Deck>> decks(Ref ref) async =>
    ref.watch(deckRepositoryProvider).getAll();

@riverpod
Future<Deck> deck(Ref ref, String deckId) async =>
    ref.watch(deckRepositoryProvider).findById(deckId);   // family, generated

@Riverpod(keepAlive: true)
DeckRepository deckRepository(Ref ref) =>
    DeckRepositoryImpl(ref.watch(deckLocalSourceProvider), ...);
```

`autoDispose` is the default under codegen and is usually right. `keepAlive` is
for things that are genuinely app-scoped — repositories, the Dio client, the
database, config. Screen data is not app-scoped; keeping it alive is how a user
sees another account's data after switching.

One provider, one responsibility, in the feature that owns it. A single
`providers.dart` holding everything becomes a merge-conflict magnet and forces
every consumer to import the whole file.

**Watch narrowly.** `ref.watch(bigProvider.select((s) => s.justThisField))`
rebuilds only when that field changes. Watching a whole object to read one field
rebuilds on every unrelated change — the same point Phase 17 makes about limiting
rebuild scope.

`ref.watch` in build, `ref.read` in callbacks. `ref.read` inside `build` reads a
value without subscribing, so the widget silently stops updating — a bug that
looks like "the data is stale" and is hard to trace back. `riverpod_lint` catches
it, which is why `custom_lint` must actually run.

## Modelling screen state

Every screen enumerates its states explicitly: initial, loading, loaded, empty,
error, refreshing, submitting. Whichever cannot occur, say so in the WBS entry
rather than leaving it undecided — an unlisted state is one nobody builds, and
empty is the one most often missed.

**Data and task status are separate concerns.** This is the rule that prevents
the most bugs. A single `isLoading` boolean cannot express "showing the list
while a delete is in flight", so screens that use one either block the whole UI
during a background operation or show nothing while refreshing.

```dart
@freezed
sealed class DeckListState with _$DeckListState {
  const factory DeckListState({
    @Default(AsyncValue<List<Deck>>.loading()) AsyncValue<List<Deck>> decks,
    @Default(false) bool isRefreshing,
    @Default(<String>{}) Set<String> deletingIds,   // per-item, not global
    String? actionError,
  }) = _DeckListState;
}
```

`deletingIds` being a set rather than a boolean is deliberate: it lets exactly
the affected row show a spinner while the rest of the list stays interactive,
and it makes concurrent deletes representable.

For simple screens, `AsyncValue<T>` alone is enough — do not build a bespoke
state class where `AsyncValue` already models loading/data/error. Add a wrapper
only when there is task status *beyond* the load.

Empty is not a separate `AsyncValue` case; it is `data` with an empty list. The
UI decides to render `AppEmptyState` — that is a presentation decision, not a
state-machine one.

State is immutable — `freezed`, or a hand-written class with `copyWith` and
value equality. A mutated-in-place object can compare equal to itself and the UI
will not rebuild, which presents as "the screen doesn't update" with no error.

## Controllers

```dart
@riverpod
class DeckListController extends _$DeckListController {
  @override
  DeckListState build() {
    // Kick off the initial load; build() must return synchronously.
    ref.listen(decksProvider, (_, next) {
      state = state.copyWith(decks: next);
    }, fireImmediately: true);
    return const DeckListState();
  }

  Future<void> delete(String id) async {
    if (state.deletingIds.contains(id)) return;   // guard: no duplicate submit

    state = state.copyWith(deletingIds: {...state.deletingIds, id});
    try {
      await ref.read(deleteDeckUseCaseProvider)(id);
      ref.invalidate(decksProvider);
    } on Failure catch (f) {
      state = state.copyWith(actionError: f.message);
    } finally {
      if (ref.mounted) {
        state = state.copyWith(
          deletingIds: state.deletingIds.difference({id}),
        );
      }
    }
  }
}
```

Points worth copying from that:

- **Guard against duplicate submits at the top.** Users double-tap. Without the
  guard you get two deletes, two error snackbars, or a half-updated list.
- **`ref.mounted` before setting state after an `await`.** If the screen was
  popped mid-request, assigning `state` on a disposed notifier throws.
- **Never store `BuildContext`.** A controller outlives the widget that created
  it; a held context is a leak and a crash. Controllers return results or set
  state — the widget decides what to show.
- **Catch `Failure`, not `Exception`.** The repository already mapped it. If a
  raw `DioException` reaches here, the repository has a bug.

## Side effects

Navigation, snackbars and dialogs must not happen in `build()`. `build` can run
many times for reasons unrelated to the event, so a snackbar fired there appears
repeatedly and a navigation there can loop.

Use `ref.listen` in the widget:

```dart
ref.listen<DeckListState>(deckListControllerProvider, (previous, next) {
  final error = next.actionError;
  if (error == null) return;
  if (previous?.actionError == error) return;   // don't re-fire on rebuild

  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
  ref.read(deckListControllerProvider.notifier).clearActionError();
});
```

The `previous == next` check matters: without it any rebuild that preserves the
error re-shows the snackbar. Clearing the error afterwards is the other half —
one-shot events should be consumed, or they fire again on the next unrelated
state change.

## Cancellation

Long requests from a screen the user has left should stop. Tie the Dio
`CancelToken` to the provider lifecycle:

```dart
@riverpod
Future<List<Deck>> searchDecks(Ref ref, String query) async {
  final token = CancelToken();
  ref.onDispose(token.cancel);
  return ref.watch(deckRepositoryProvider).search(query, cancelToken: token);
}
```

With a family provider this also cancels the previous query when the term
changes, which is what you want for search-as-you-type.

## Checks before state work is done

- [ ] Every screen state from the matrix is reachable and rendered.
- [ ] No single `isLoading` covering unrelated operations.
- [ ] State is immutable with value equality.
- [ ] No `BuildContext` in a controller.
- [ ] `ref.mounted` checked after every `await` that assigns state.
- [ ] Duplicate submissions guarded.
- [ ] Side effects in `ref.listen`, not `build`.
- [ ] One-shot events consumed so they do not re-fire.
- [ ] `select` used where only part of a state object is needed.
- [ ] `dart run custom_lint` clean — `flutter analyze` does not cover these rules.
