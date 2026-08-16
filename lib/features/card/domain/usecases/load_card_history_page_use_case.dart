import '../models/card_history_cursor_model.dart';
import '../models/card_history_page_model.dart';
import '../repositories/card_detail_repository.dart';

/// Asking for the next slice of a card's history (UC-19 step 4 and step 6,
/// BR-241).
///
/// **One use case for the first page and for every page after it.** They differ
/// only in whether a cursor is present, and two entry points would be two
/// places for the ordering contract to be stated — which is exactly how a first
/// page and a load-more end up sorted differently and overlap by one row.
///
/// [after] is forwarded rather than defaulted: a dropped optional parameter
/// compiles and analyzes clean, and the card list has already paid for that
/// once (see `watch_card_list_items_use_case.dart`), so
/// `card_detail_use_cases_test.dart` asserts the cursor arrives.
class LoadCardHistoryPageUseCase {
  const LoadCardHistoryPageUseCase(this._repository);

  final CardDetailRepository _repository;

  Future<CardHistoryPageModel> call(
    String cardId, {
    CardHistoryCursor? after,
  }) => _repository.loadCardHistoryPage(cardId, after: after);
}
