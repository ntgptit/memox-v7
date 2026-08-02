import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/state/retry_policy.dart';
import '../../../../core/state/submit_outcome.dart';
import '../../domain/entities/tag_entity.dart';
import '../providers/card_use_case_provider.dart';
import '../states/card_tag_state.dart';

part 'card_tag_controller.g.dart';

/// One card's tags, as a stream (BR-93).
///
/// A query provider — build-only, so it stays a pure read of the data layer
/// (CQS). `noAutomaticRetry` for the same reason every async presentation read
/// carries it: a retry would sit on `AsyncLoading` instead of surfacing the
/// failure the chip strip should show.
@Riverpod(retry: noAutomaticRetry)
Stream<List<TagEntity>> cardTags(Ref ref, String cardId) =>
    ref.watch(watchCardTagsUseCaseProvider)(cardId);

/// Adding one tag to a card (UC-04, BR-93, BR-94).
///
/// A command controller: build returns a [CardTagSubmitState] and the only mutators
/// are `submit` and `reset`, so a write and a read never share one state (CQS).
/// `submit` reports `savedAndContinue` — the field stays open for the next tag
/// and clears its own draft, exactly like save-and-add-another.
@riverpod
class CardTagEntry extends _$CardTagEntry {
  @override
  CardTagSubmitState build(String cardId) => const CardTagSubmitState();

  Future<void> submit(String rawName) async {
    if (!state.canSubmit) return;

    state = const CardTagSubmitState(isSubmitting: true);
    try {
      await ref.read(addCardTagUseCaseProvider)(
        cardId: cardId,
        rawName: rawName,
      );
      if (!ref.mounted) return;
      state = const CardTagSubmitState(outcome: SubmitOutcome.savedAndContinue);
    } on Failure catch (failure) {
      if (!ref.mounted) return;
      state = cardTagFailure(failure);
    }
  }

  /// Clears the last attempt so the field starts clean for the next tag.
  void reset() => state = const CardTagSubmitState();
}

/// Removing one tag from a card (UC-04, BR-93).
///
/// Its own command controller rather than a second method on [CardTagEntry]:
/// CQS holds a command controller to build/submit/reset, so add and remove are
/// two controllers, not two methods on one. Removing has no field to blame, so a
/// failure surfaces as the operation's.
@riverpod
class CardTagRemove extends _$CardTagRemove {
  @override
  CardTagSubmitState build(String cardId) => const CardTagSubmitState();

  Future<void> submit(String tagId) async {
    if (!state.canSubmit) return;

    state = const CardTagSubmitState(isSubmitting: true);
    try {
      await ref.read(removeCardTagUseCaseProvider)(
        cardId: cardId,
        tagId: tagId,
      );
      if (!ref.mounted) return;
      state = const CardTagSubmitState(outcome: SubmitOutcome.savedAndClose);
    } on Failure catch (failure) {
      if (!ref.mounted) return;
      state = CardTagSubmitState(failure: failure);
    }
  }

  void reset() => state = const CardTagSubmitState();
}
