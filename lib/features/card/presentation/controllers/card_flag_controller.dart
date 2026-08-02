import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/state/retry_policy.dart';
import '../../../../core/state/submit_outcome.dart';
import '../providers/card_use_case_provider.dart';
import '../states/card_submit_state.dart';

part 'card_flag_controller.g.dart';

/// One card's flag, as a stream (BR-92).
///
/// A query provider — build-only, a pure read of the data layer (CQS). The
/// editor's toggle renders filled or hollow from this, and because it is a
/// stream the icon flips the moment [SetCardFlag] writes, without an optimistic
/// guess a failed write would have to unwind. `noAutomaticRetry` — a failed read
/// shows as a disabled toggle, not a silent re-run.
@Riverpod(retry: noAutomaticRetry)
Stream<bool> cardFlag(Ref ref, String cardId) =>
    ref.watch(watchCardFlagUseCaseProvider)(cardId);

/// Setting one card's flag (UC-04, BR-92).
///
/// A command controller — build/submit/reset — so the write never shares a state
/// with the read above it. The widget passes the target value (the negation of
/// what [cardFlag] currently shows); the write lands, the stream re-emits, and
/// the icon follows.
@riverpod
class SetCardFlag extends _$SetCardFlag {
  @override
  CardSubmitState build(String cardId) => const CardSubmitState();

  Future<void> submit({required bool isFlagged}) async {
    if (!state.canSubmit) return;

    state = const CardSubmitState(isSubmitting: true);
    try {
      await ref.read(setCardFlagUseCaseProvider)(
        cardId: cardId,
        isFlagged: isFlagged,
      );
      if (!ref.mounted) return;
      state = const CardSubmitState(outcome: SubmitOutcome.savedAndClose);
    } on Failure catch (failure) {
      if (!ref.mounted) return;
      state = CardSubmitState(failure: failure);
    }
  }

  void reset() => state = const CardSubmitState();
}
