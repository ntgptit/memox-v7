import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_async_confirm_dialog.dart';
import '../../../../../shared/widgets/mx_confirm_dialog.dart';
import '../../../../../shared/widgets/mx_dialog_tone.dart';
import '../../controllers/card_write_controller.dart';
import '../../states/card_submit_state.dart';

/// The delete confirmation for one card (UC-04 A2, BR-163).
///
/// The same shape as `showDeckDeleteConfirm`: a `showX` entry point, and a
/// `Consumer` that reads the delete controller and reports back through
/// callbacks. It does not close itself — [MxConfirmDialog] stays mounted while
/// the delete runs so `isSubmitting` can disable both actions, and the caller
/// pops once the write reports `savedAndClose`.
///
/// **Counts nothing.** Unlike a deck, a card takes only itself and its own
/// history; the message is a fixed sentence, so there is no impact read
/// to make before asking.
/// [onDeleted] receives the deletion's batch id, which is what an Undo
/// affordance acts on (BR-263); it is null only when the write failed, which
/// the dialog has already reported.
Future<void> showCardDeleteConfirm(
  BuildContext context, {
  required String cardId,
  required ValueChanged<String?> onDeleted,
}) => showMxAsyncConfirm(
  context,
  reset: (container) =>
      container.read(cardDeleteProvider(cardId).notifier).reset(),
  builder: (dialogContext, close) =>
      _DeleteCardDialog(cardId: cardId, onDeleted: onDeleted, onClose: close),
);

class _DeleteCardDialog extends StatefulWidget {
  const _DeleteCardDialog({
    required this.cardId,
    required this.onDeleted,
    required this.onClose,
  });

  final String cardId;
  final ValueChanged<String?> onDeleted;
  final VoidCallback onClose;

  @override
  State<_DeleteCardDialog> createState() => _DeleteCardDialogState();
}

class _DeleteCardDialogState extends State<_DeleteCardDialog> {
  /// The batch the write created, held only until the dialog closes.
  String? _batchId;

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final CardSubmitState submit = ref.watch(
          cardDeleteProvider(widget.cardId),
        );

        // The type argument is inferred from `state` — the feature's problem
        // enum lives in its domain, and a presentation file naming it would be
        // an import for a word the compiler already knows.
        return MxAsyncConfirmDialog(
          state: submit,
          title: context.l10n.cardDeleteConfirmTitle,
          message: submit.failure != null
              ? context.l10n.cardDeleteFailed
              : context.l10n.cardDeleteConfirmMessage,
          confirmLabel: context.l10n.cardDeleteConfirmAction,
          cancelLabel: context.l10n.commonCancelAction,
          // Soft delete (BR-256): cautious, not destructive — see the
          // deck dialog for the whole argument. `warning` rather than `error`
          // on the severity axis for the same reason: it is recoverable.
          variant: MxConfirmDialogVariant.cautious,
          tone: MxDialogTone.warning,
          onConfirm: () => _submit(ref),
          onCancel: widget.onClose,
          onDone: _finish,
        );
      },
    );
  }

  /// The notifier, read from a button press rather than during a build.
  ///
  /// A named method for the reason `settings_reset_confirm_widget.dart` gives:
  /// the guard rule `no_ref_read_in_build` cannot tell a read that happens
  /// *during* a build from one declared there and fired later, and naming it
  /// makes the difference visible to a reader too.
  Future<void> _submit(WidgetRef ref) async {
    _batchId = await ref
        .read(cardDeleteProvider(widget.cardId).notifier)
        .submit();
  }

  /// The batch id was captured by [_submit] one frame before this runs.
  void _finish() {
    widget.onClose();
    widget.onDeleted(_batchId);
  }
}
