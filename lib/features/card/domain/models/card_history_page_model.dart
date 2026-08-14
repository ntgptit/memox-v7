import 'card_history_cursor_model.dart';
import 'card_history_event_model.dart';

/// How many events one page of a card's history carries (BR-184).
///
/// A domain constant rather than a number the screen passes in: the page size
/// is part of the read contract — it is what makes the cursor and the "is there
/// more" answer below mean anything — and letting a widget choose it would put
/// a performance decision in the layer least able to judge it.
const int kCardHistoryPageSize = 50;

/// One page of a card's history, and where the next one starts (BR-184).
///
/// **[hasMore] is answered by the read, not inferred from the length.** A page
/// that comes back short can mean "that was the last of them" or "the window
/// happened to end there", and those need different tails on screen — a
/// `Load more` versus the line that says the history is complete. The
/// repository asks for one row beyond the page and reports what it found, which
/// costs one row and removes the guess.
///
/// [nextCursor] is null exactly when [hasMore] is false: there is nowhere to
/// resume from once the last row has been read.
class CardHistoryPageModel {
  const CardHistoryPageModel({
    required this.events,
    required this.hasMore,
    required this.nextCursor,
  });

  /// An empty page that is also the end — the shape a card with no history at
  /// all comes back as (BR-187), named so no caller has to build it by hand and
  /// accidentally claim there is more.
  static const CardHistoryPageModel empty = CardHistoryPageModel(
    events: <CardHistoryEventModel>[],
    hasMore: false,
    nextCursor: null,
  );

  /// Newest first: `answered_at DESC, id DESC` (BR-184).
  final List<CardHistoryEventModel> events;

  final bool hasMore;

  /// The key the next page resumes after, or null at the end of the history.
  final CardHistoryCursor? nextCursor;
}
