import '../../domain/models/card_history_cursor_model.dart';
import '../../domain/models/card_history_event_model.dart';

/// What the history timeline is doing right now (UC-19 UI states).
///
/// **Separate from the events themselves**, which is the split CLAUDE.md asks
/// for: one `isLoading` boolean shared by a first read and a load-more is what
/// makes a failed second page wipe the first one off the screen.
enum CardHistoryStatus {
  /// The first page is in flight and nothing has been shown yet.
  loadingInitial,

  /// A page has landed. Whether another exists is [CardHistoryState.hasMore].
  loaded,

  /// A further page is in flight; everything already shown stays on screen.
  loadingMore,

  /// The last request failed. Everything already shown stays on screen and the
  /// tail offers `Try again` (UC-19 E4).
  pageError,
}

/// The history half of the card detail screen.
///
/// **The cursor lives here, not in the widget.** Resuming is defined by the
/// last row read (BR-241), so the only place that can hold it correctly is the
/// same place that holds the rows.
class CardHistoryState {
  const CardHistoryState({
    this.events = const <CardHistoryEventModel>[],
    this.status = CardHistoryStatus.loadingInitial,
    this.nextCursor,
  });

  /// Newest first, accumulated across pages (BR-241).
  final List<CardHistoryEventModel> events;

  final CardHistoryStatus status;

  /// Where the next page resumes, or null when the history is exhausted.
  final CardHistoryCursor? nextCursor;

  /// Whether a `Load more` has anywhere to go.
  ///
  /// Read from the cursor rather than from a second flag: two fields that must
  /// agree are two fields that can disagree, and the repository already
  /// guarantees a cursor exists exactly while more rows do.
  bool get hasMore => nextCursor != null;

  bool get isLoadingInitial => status == CardHistoryStatus.loadingInitial;
  bool get isLoadingMore => status == CardHistoryStatus.loadingMore;
  bool get hasPageError => status == CardHistoryStatus.pageError;

  /// A card that has never been reviewed, once the first page has landed
  /// (BR-244). Not an error, and deliberately not the same thing as
  /// [isLoadingInitial] with nothing shown yet.
  ///
  /// **It asks for `loaded`, not merely "not loading".** Written the other way
  /// round it also answered `true` for a *failed* first page, and the widget
  /// had to repair it with `&& !state.hasPageError` at the call site — a
  /// predicate that only holds where somebody remembered to patch it is the
  /// shape that turns a read failure into "this card has no reviews", which is
  /// exactly what BR-244 separates.
  bool get isEmpty => events.isEmpty && status == CardHistoryStatus.loaded;

  /// Every page has been read (UC-19 A5) — the tail says so instead of offering
  /// a button with nothing behind it.
  bool get isComplete =>
      !hasMore && events.isNotEmpty && status == CardHistoryStatus.loaded;

  CardHistoryState copyWith({
    List<CardHistoryEventModel>? events,
    CardHistoryStatus? status,
    CardHistoryCursor? nextCursor,
    bool clearCursor = false,
  }) => CardHistoryState(
    events: events ?? this.events,
    status: status ?? this.status,
    // A nullable field cannot be cleared by passing null — that is
    // indistinguishable from "leave it alone" — so the end of the history is
    // said explicitly.
    nextCursor: clearCursor ? null : (nextCursor ?? this.nextCursor),
  );
}
