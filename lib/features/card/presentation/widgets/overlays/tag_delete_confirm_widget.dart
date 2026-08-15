import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_confirm_dialog.dart';
import '../../../domain/models/tag_catalog_entry_model.dart';
import '../../controllers/tag_write_controller.dart';
import '../../states/tag_catalog_state.dart';
import '../support/tag_labels_widget.dart';

/// The delete confirmation for one tag (UC-18 A3, BR-235).
///
/// The same shape as `showCardDeleteConfirm`: a `showX` entry point and a
/// `Consumer` that reads the delete controller. It does not close itself —
/// [MxConfirmDialog] stays mounted while the write runs so `isSubmitting` can
/// disable both actions, and the caller pops on `savedAndClose`.
///
/// **The message counts, and says what survives.** It names the tag and the
/// number of cards that lose it, then states outright that the cards stay
/// (M4.14 T8) — the count is already in [tag], read from the row the user is
/// looking at, so nothing is fetched to ask the question.
/// **The controller is reset from the tap that opens the dialog**, the same
/// discipline `showMxFormSheet` documents for every form: a previous attempt's
/// failure must not be the first thing the next one shows. `autoDispose` would
/// usually have collected it already, but "usually" is not a guarantee — a
/// second dialog opened while the first is still unmounting shares the
/// notifier.
Future<void> showTagDeleteConfirm(
  BuildContext context, {
  required TagCatalogEntry tag,
}) {
  ProviderScope.containerOf(
    context,
  ).read(tagDeleteProvider(tag.id).notifier).reset();

  return showDialog<void>(
    context: context,
    builder: (dialogContext) => _DeleteTagDialog(
      tag: tag,
      onClose: () => Navigator.of(dialogContext).pop(),
    ),
  );
}

class _DeleteTagDialog extends StatelessWidget {
  const _DeleteTagDialog({required this.tag, required this.onClose});

  final TagCatalogEntry tag;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final provider = tagDeleteProvider(tag.id);

    return Consumer(
      builder: (context, ref, child) {
        final submit = ref.watch(provider);

        ref.listen<TagCatalogSubmitState>(provider, (previous, next) {
          if (!next.shouldClose || (previous?.shouldClose ?? false)) return;
          onClose();
        });

        final failure = submit.failure;

        // Two sentences and two messages, not one with a count of zero:
        // "removed from 0 cards" is a sentence about nothing, and the
        // reassurance that cards survive is noise when none are involved.
        final question = tag.cardCount == 0
            ? context.l10n.tagDeleteConfirmMessageUnused(tag.name)
            : context.l10n.tagDeleteConfirmMessage(tag.name, tag.cardCount);

        return MxConfirmDialog(
          title: context.l10n.tagDeleteConfirmTitle,
          // **A failure is appended, never substituted.** Swapping the body out
          // took "The cards themselves stay" off screen while the destructive
          // action was still there to press — the one sentence a user needs
          // most at the moment something has just gone wrong (W5).
          message: failure == null
              ? question
              : '$question\n\n${context.tagCatalogWriteFailure(failure)}',
          confirmLabel: context.l10n.tagDeleteAction,
          cancelLabel: context.l10n.commonCancelAction,
          variant: MxConfirmDialogVariant.destructive,
          isSubmitting: submit.isSubmitting,
          onConfirm: () => ref.read(provider.notifier).submit(),
          onCancel: onClose,
        );
      },
    );
  }
}
