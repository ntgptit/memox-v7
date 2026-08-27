import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_async_confirm_dialog.dart';
import '../../../../../shared/widgets/mx_confirm_dialog.dart';
import '../../../../../shared/widgets/mx_dialog_tone.dart';
import '../../../domain/models/tag_catalog_entry_model.dart';
import '../../controllers/tag_write_controller.dart';
import '../support/tag_labels_widget.dart';

/// The delete confirmation for one tag (UC-18 A3, BR-235).
///
/// The same shape as `showCardDeleteConfirm`: a `showX` entry point and a
/// `Consumer` that reads the delete controller. It does not close itself —
/// [MxAsyncConfirmDialog] stays mounted while the write runs so both actions
/// can go inert, and it pops on the `savedAndClose` transition.
///
/// **The message counts, and says what survives.** It names the tag and the
/// number of cards that lose it, then states outright that the cards stay
/// (M4.14 T8) — the count is already in [tag], read from the row the user is
/// looking at, so nothing is fetched to ask the question.
///
/// The reset-before-open discipline this dialog introduced now belongs to
/// [showMxAsyncConfirm], which applies it to all four confirmations rather than
/// only the one that remembered.
Future<void> showTagDeleteConfirm(
  BuildContext context, {
  required TagCatalogEntry tag,
}) => showMxAsyncConfirm(
  context,
  reset: (container) =>
      container.read(tagDeleteProvider(tag.id).notifier).reset(),
  builder: (dialogContext, close) => _DeleteTagDialog(tag: tag, onClose: close),
);

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
        final failure = submit.failure;

        // Two sentences and two messages, not one with a count of zero:
        // "removed from 0 cards" is a sentence about nothing, and the
        // reassurance that cards survive is noise when none are involved.
        final question = tag.cardCount == 0
            ? context.l10n.tagDeleteConfirmMessageUnused(tag.name)
            : context.l10n.tagDeleteConfirmMessage(tag.name, tag.cardCount);

        return MxAsyncConfirmDialog(
          state: submit,
          title: context.l10n.tagDeleteConfirmTitle,
          // **A failure is appended, never substituted.** Swapping the body out
          // took "The cards themselves stay" off screen while the destructive
          // action was still there to press — the one sentence a user needs
          // most at the moment something has just gone wrong (W5).
          message: failure == null
              ? question
              : '$question\n\n${context.tagCatalogWriteFailure(failure)}',
          confirmLabel: context.l10n.tagDeleteConfirmAction,
          cancelLabel: context.l10n.commonCancelAction,
          variant: MxConfirmDialogVariant.destructive,
          // A tag is gone for good — it has no Trash — so the severity axis
          // says `error` where the card and deck deletes say `warning`.
          tone: MxDialogTone.error,
          onConfirm: () => _submit(ref),
          onCancel: onClose,
          onDone: onClose,
        );
      },
    );
  }

  /// The notifier, read from the button press rather than during a build —
  /// see `card_confirm_widget.dart` for why this is a named method.
  void _submit(WidgetRef ref) =>
      unawaited(ref.read(tagDeleteProvider(tag.id).notifier).submit());
}
