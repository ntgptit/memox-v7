import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/state/submit_outcome.dart';
import '../providers/card_use_case_provider.dart';
import '../states/card_submit_state.dart';

part 'card_create_controller.g.dart';

/// Creating one card (UC-04, W4).
///
/// The same shape as Deck's write controllers, and for the same reasons:
///
/// * refuses a second submit while the first is in flight
///   ([CardSubmitState.canSubmit]), so a double tap cannot create two cards;
/// * validates nothing itself — BR-07 and BR-08 live in `CardText`, applied by
///   the use case; an invalid form arrives as a `ValidationFailure` and
///   `cardSubmitFailure` turns it into the per-field problems the editor reads;
/// * checks `ref.mounted` after the await, because the route can pop mid-write;
/// * keeps the user's input on failure — it clears nothing, the widget holds
///   the text (UC-04 E3);
/// * navigates nothing and shows no snackbar — it reports a [SubmitOutcome] and
///   the screen reacts.
///
/// `family` on the deck id: which deck the card lands in is fixed by the route,
/// not chosen in the form.
@riverpod
class CardCreate extends _$CardCreate {
  @override
  CardSubmitState build(String deckId) => const CardSubmitState();

  /// [disposition] is what tells save from save-and-add-another (UC-04 A4):
  /// `close` reports `savedAndClose`, `addAnother` reports `savedAndContinue`
  /// and leaves `canSubmit` true so the emptied form can be filled again.
  Future<void> submit({
    required String rawFront,
    required String rawBack,
    SubmitDisposition disposition = SubmitDisposition.close,
  }) async {
    if (!state.canSubmit) return;

    state = const CardSubmitState(isSubmitting: true);
    try {
      await ref.read(createCardUseCaseProvider)(
        deckId: deckId,
        rawFront: rawFront,
        rawBack: rawBack,
      );
      if (!ref.mounted) return;
      state = CardSubmitState(outcome: disposition.outcome);
    } on Failure catch (failure) {
      if (!ref.mounted) return;
      state = cardSubmitFailure(failure);
    }
  }

  /// Clears the last attempt so the form starts clean on the next open, and
  /// after a save-and-add-another.
  void reset() => state = const CardSubmitState();
}
