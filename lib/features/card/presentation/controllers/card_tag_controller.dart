import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/state/submit_outcome.dart';
import '../../domain/entities/tag_entity.dart';
import '../providers/card_use_case_provider.dart';
import '../states/card_tag_state.dart';

part 'card_tag_controller.g.dart';

/// One card's tags, as a stream (BR-93).
///
/// A stream provider so the editor's chip strip re-renders the moment an add or
/// a remove lands, without the entry controller having to push the new list.
@riverpod
Stream<List<TagEntity>> cardTags(Ref ref, String cardId) =>
    ref.watch(watchCardTagsUseCaseProvider)(cardId);

/// Adding and removing one card's tags (UC-04, BR-93, BR-94).
///
/// Same contract as the other write controllers: refuse a second add while one
/// is in flight, validate nothing itself (the use case owns BR-93, the
/// repository owns BR-94), check `ref.mounted` after the await, and report a
/// [SubmitOutcome] the widget reacts to. An add reports `savedAndContinue` — the
/// field stays open for the next tag and clears its own draft, exactly like
/// save-and-add-another.
@riverpod
class CardTagEntry extends _$CardTagEntry {
  @override
  CardTagState build(String cardId) => const CardTagState();

  Future<void> add(String rawName) async {
    if (!state.canSubmit) return;

    state = const CardTagState(isSubmitting: true);
    try {
      await ref.read(addCardTagUseCaseProvider)(
        cardId: cardId,
        rawName: rawName,
      );
      if (!ref.mounted) return;
      state = const CardTagState(outcome: SubmitOutcome.savedAndContinue);
    } on Failure catch (failure) {
      if (!ref.mounted) return;
      state = cardTagFailure(failure);
    }
  }

  /// Removing a tag has no field to blame, so a failure surfaces as the
  /// operation's, not a problem under the input.
  Future<void> remove(String tagId) async {
    try {
      await ref.read(removeCardTagUseCaseProvider)(
        cardId: cardId,
        tagId: tagId,
      );
    } on Failure catch (failure) {
      if (!ref.mounted) return;
      state = CardTagState(failure: failure);
    }
  }

  /// Clears the last attempt so the field starts clean for the next tag.
  void reset() => state = const CardTagState();
}
