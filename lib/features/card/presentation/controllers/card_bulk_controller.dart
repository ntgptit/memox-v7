import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/state/submit_outcome.dart';
import '../../domain/models/tag_name_model.dart';
import '../providers/card_use_case_provider.dart';
import '../states/card_submit_state.dart';

part 'card_bulk_controller.g.dart';

/// The submit lifecycle the four bulk commands share: guard, flag, write,
/// report.
///
/// A free function rather than a base class — Riverpod generates a private
/// base per notifier, so the shared part has to be something they call.
Future<void> _runBulk({
  required CardSubmitState current,
  required Future<void> Function() write,
  required bool Function() isMounted,
  required void Function(CardSubmitState next) emit,
}) async {
  if (!current.canSubmit) return;

  emit(const CardSubmitState(isSubmitting: true));
  try {
    await write();
    if (!isMounted()) return;
    emit(const CardSubmitState(outcome: SubmitOutcome.savedAndClose));
  } on Failure catch (failure) {
    if (!isMounted()) return;
    // The selection survives a refusal — the screen keeps it so the user can
    // read why and retry (BR-167).
    emit(CardSubmitState(failure: failure));
  }
}

/// Moves a selection into another deck (UC-04 A5, BR-165).
///
/// **One command per controller, each with its own submit state.** Four bulk
/// actions behind one notifier would share a submitting flag, and the spinner
/// would appear on whichever action the user did not press.
///
/// No validation here: every rule BR-165 states needs the tree as it stands at
/// the moment of writing, so it lives inside the repository's transaction.
@riverpod
class MoveCards extends _$MoveCards {
  @override
  CardSubmitState build(String deckId) => const CardSubmitState();

  Future<void> submit({
    required List<String> cardIds,
    required String targetDeckId,
  }) => _runBulk(
    current: state,
    write: () => ref.read(moveCardsUseCaseProvider)(
      cardIds: cardIds,
      targetDeckId: targetDeckId,
    ),
    isMounted: () => ref.mounted,
    emit: (next) => state = next,
  );

  void reset() => state = const CardSubmitState();
}

/// Deletes a selection (UC-04 A6, BR-166). The confirmation happened before
/// this is reached.
@riverpod
class DeleteCards extends _$DeleteCards {
  @override
  CardSubmitState build(String deckId) => const CardSubmitState();

  Future<void> submit(List<String> cardIds) => _runBulk(
    current: state,
    write: () => ref.read(deleteCardsUseCaseProvider)(cardIds),
    isMounted: () => ref.mounted,
    emit: (next) => state = next,
  );

  void reset() => state = const CardSubmitState();
}

/// Sets or clears the flag on a selection (BR-92, BR-166) — explicit, never a
/// toggle read off the first card.
@riverpod
class SetCardsFlag extends _$SetCardsFlag {
  @override
  CardSubmitState build(String deckId) => const CardSubmitState();

  Future<void> submit({
    required List<String> cardIds,
    required bool isFlagged,
  }) => _runBulk(
    current: state,
    write: () => ref.read(setCardsFlagUseCaseProvider)(
      cardIds: cardIds,
      isFlagged: isFlagged,
    ),
    isMounted: () => ref.mounted,
    emit: (next) => state = next,
  );

  void reset() => state = const CardSubmitState();
}

/// Adds one tag to a selection (BR-93, BR-94, BR-166).
@riverpod
class AddTagToCards extends _$AddTagToCards {
  @override
  CardSubmitState build(String deckId) => const CardSubmitState();

  Future<void> submit({required List<String> cardIds, required TagName name}) =>
      _runBulk(
        current: state,
        write: () => ref.read(addTagToCardsUseCaseProvider)(
          cardIds: cardIds,
          name: name,
        ),
        isMounted: () => ref.mounted,
        emit: (next) => state = next,
      );

  void reset() => state = const CardSubmitState();
}
