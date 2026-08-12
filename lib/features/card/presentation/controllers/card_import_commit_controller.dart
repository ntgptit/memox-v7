import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/failure.dart';
import '../../domain/repositories/card_import_repository.dart';
import '../providers/card_import_use_case_provider.dart';
import '../states/card_import_state.dart';

part 'card_import_commit_controller.g.dart';

/// The commit command (UC-10 step 7, BR-171): one write, its own submit
/// state, nothing else — the same shape as every command controller here.
///
/// No validation and no plan-building: the screen assembles the plan from
/// the preview it is already showing, and every in-transaction rule (BR-168,
/// BR-170, BR-172) belongs to the repository. A failure keeps the state so
/// the step renders `Try again` over an intact draft (UC-10 E5); a success
/// latches into the result the step's final view prints.
@riverpod
class CommitCardImport extends _$CommitCardImport {
  @override
  CardImportSubmitState build(String deckId) => const CardImportSubmitState();

  Future<void> submit(CardImportPlan plan) async {
    if (!state.canSubmit) return;

    state = const CardImportSubmitState(isSubmitting: true);
    try {
      final result = await ref.read(commitCardImportUseCaseProvider)(
        deckId: deckId,
        plan: plan,
      );
      if (!ref.mounted) return;
      state = CardImportSubmitState(result: result);
    } on Failure catch (failure) {
      if (!ref.mounted) return;
      state = CardImportSubmitState(failure: failure);
    }
  }

  void reset() => state = const CardImportSubmitState();
}
