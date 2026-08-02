import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/state/retry_policy.dart';
import '../providers/card_use_case_provider.dart';

part 'card_flag_controller.g.dart';

/// One card's flag, as the editor's toggle shows and drives it (BR-92).
///
/// A `Future<bool>`, seeded from `getCard`: the toggle needs the current mark to
/// render filled or hollow before the user touches it, and reading it here keeps
/// the editor from threading the flag through its own state. `noAutomaticRetry`
/// — a failed read shows as a disabled toggle, not a silent re-run.
///
/// [toggle] is optimistic: it flips the local value first so the icon responds
/// on the tap, then writes. A failed write reverts, because a mark that shows
/// flagged while the row is not is the one inconsistency BR-92 must not allow.
@Riverpod(retry: noAutomaticRetry)
class CardFlag extends _$CardFlag {
  @override
  Future<bool> build(String cardId) async =>
      (await ref.read(getCardUseCaseProvider)(cardId)).isFlagged;

  Future<void> toggle() async {
    final current = state.value;
    if (current == null) return; // not loaded yet — nothing to toggle
    final next = !current;

    state = AsyncData<bool>(next);
    try {
      await ref.read(setCardFlagUseCaseProvider)(
        cardId: cardId,
        isFlagged: next,
      );
    } on Failure {
      if (!ref.mounted) return;
      state = AsyncData<bool>(current);
    }
  }
}
