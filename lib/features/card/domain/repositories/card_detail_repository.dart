import '../models/card_detail_model.dart';
import '../models/card_history_cursor_model.dart';
import '../models/card_history_page_model.dart';

/// The read side of one card: what it is now, and what has happened to it
/// (UC-12).
///
/// **Its own contract rather than two more methods on `CardRepository`.** That
/// one is card *management* — the list, the editor, the bulk writes — and it is
/// already the largest contract in the feature. This one reads two tables the
/// management surface never touches (`study_answers`) and is, by BR-182,
/// incapable of writing anything. Splitting them means a detail test fakes a
/// contract with two methods instead of twenty-six, and it means "this surface
/// cannot mutate" is visible in the type rather than asserted in prose.
///
/// Like its siblings it is written from what presentation needs: no Drift row,
/// companion or DAO type appears in a signature, and no Drift exception escapes
/// an implementation — failures arrive as the domain `Failure` hierarchy.
abstract interface class CardDetailRepository {
  /// One card's content, tags and current schedule, re-emitted on every change
  /// (BR-183, AD-01).
  ///
  /// **Watched, not read once** — unlike the editor's `getCard`, which takes a
  /// snapshot precisely so an incoming change cannot fight the text being
  /// typed. Nothing here is being typed, so the honest behaviour is the
  /// opposite: an edit made and come back from, a flag toggled elsewhere, or a
  /// tag added should land on this screen without a reload.
  ///
  /// A card that does not exist — or that is deleted while the screen is open —
  /// surfaces as a `NotFoundFailure` carrying `CardNotFoundReason.cardGone` on
  /// the stream (BR-188). The same reason the editor already uses, not a second
  /// one: it is the same event.
  Stream<CardDetailModel> watchCardDetail(String cardId);

  /// One page of the card's history, newest first (BR-184).
  ///
  /// A `Future`, not a stream, and that asymmetry with [watchCardDetail] is the
  /// point: pages accumulate on screen. A live query would have to re-emit
  /// every page the reader has already collected on every write, and appending
  /// to what a stream re-sends is how a row ends up on screen twice.
  ///
  /// [after] null asks for the first page. A non-null cursor asks for the rows
  /// strictly after it in `answered_at DESC, id DESC` order, so a review
  /// written between two calls lands above the window rather than inside it.
  ///
  /// Reads only. It writes nothing, marks nothing learned and touches no
  /// timestamp (BR-182).
  Future<CardHistoryPageModel> loadCardHistoryPage(
    String cardId, {
    CardHistoryCursor? after,
  });
}
