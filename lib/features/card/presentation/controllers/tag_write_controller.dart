import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/state/submit_outcome.dart';
import '../providers/tag_use_case_provider.dart';
import '../states/tag_catalog_state.dart';

part 'tag_write_controller.g.dart';

/// Renaming one tag, which may turn out to be a merge (UC-18, BR-233, BR-234).
///
/// A command controller: `build` returns a [TagCatalogSubmitState] and the only
/// mutators are `submit` and `reset`, so a write and a read never share one
/// state (CQS). `family` on the tag id, so two rename sheets — one opened from
/// the catalog, one from a stale route — cannot share a spinner.
///
/// Reports `savedAndClose`: the sheet closes on success, unlike the add-tag
/// field which stays open for the next entry. Renaming the same tag twice in a
/// row is not a flow anybody has.
@riverpod
class TagRename extends _$TagRename {
  @override
  TagRenameSubmitState build(String tagId) => const TagRenameSubmitState();

  Future<void> submit(String rawName) async {
    if (!state.submit.canSubmit) return;

    state = const TagRenameSubmitState(
      submit: TagCatalogSubmitState(isSubmitting: true),
    );
    try {
      final outcome = await ref.read(renameTagUseCaseProvider)(
        tagId: tagId,
        rawName: rawName,
      );
      if (!ref.mounted) return;
      // The outcome lands on the **same** transition the sheet closes on, so
      // the confirmation copy is chosen from what the transaction did rather
      // than from what the form guessed it would do (BR-234).
      state = TagRenameSubmitState(
        submit: const TagCatalogSubmitState(
          outcome: SubmitOutcome.savedAndClose,
        ),
        outcome: outcome,
      );
    } on Failure catch (failure) {
      if (!ref.mounted) return;
      state = TagRenameSubmitState(submit: tagCatalogFailure(failure));
    }
  }

  void reset() => state = const TagRenameSubmitState();
}

/// Deleting one tag from every card that carries it (UC-18 A3, BR-235).
///
/// Its own command controller rather than a second method on [TagRename]: CQS
/// holds a command controller to build/submit/reset, so rename and delete are
/// two controllers, not two methods on one. Delete has no field to blame, so a
/// failure always surfaces as the operation's.
@riverpod
class TagDelete extends _$TagDelete {
  @override
  TagCatalogSubmitState build(String tagId) => const TagCatalogSubmitState();

  Future<void> submit() async {
    if (!state.canSubmit) return;

    state = const TagCatalogSubmitState(isSubmitting: true);
    try {
      await ref.read(deleteTagUseCaseProvider)(tagId);
      if (!ref.mounted) return;
      state = const TagCatalogSubmitState(outcome: SubmitOutcome.savedAndClose);
    } on Failure catch (failure) {
      if (!ref.mounted) return;
      state = TagCatalogSubmitState(failure: failure);
    }
  }

  void reset() => state = const TagCatalogSubmitState();
}
