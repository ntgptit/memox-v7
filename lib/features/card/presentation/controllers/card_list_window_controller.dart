import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'card_list_window_controller.g.dart';

/// The first window, and every load-more step.
///
/// 50 is the number the wireframe draws, and it is a **window**, not a page: the
/// list re-reads the whole window on every change, so growing it is asking for a
/// larger first-N, never for a next page (see `card.drift`).
const int kCardWindowSize = 50;

/// How far the list has been scrolled open, as a row count.
///
/// **`autoDispose`, and that is the answer to "does the window reset on
/// re-entry".** It does: leaving the screen disposes this notifier, so the next
/// visit starts at [kCardWindowSize] again. Holding a deep scroll across a visit
/// would mean re-reading a 500-row window to render a screen the user opened
/// fresh — the cost the growing `LIMIT` exists to avoid, paid on every entry.
///
/// `family` on the deck id so two decks opened in one session do not share a
/// window; the shell keeps a pushed route alive, so this has to be per deck.
@riverpod
class CardListWindow extends _$CardListWindow {
  @override
  int build(String deckId) => kCardWindowSize;

  /// Opens the window by one step. The list re-subscribes at the new size.
  void grow() => state += kCardWindowSize;
}
