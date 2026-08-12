import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_confirm_dialog.dart';
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
Future<void> showCardDeleteConfirm(
  BuildContext context, {
  required String cardId,
  required VoidCallback onDeleted,
}) => showDialog<void>(
  context: context,
  builder: (dialogContext) => _DeleteCardDialog(
    cardId: cardId,
    onDeleted: onDeleted,
    onClose: () => Navigator.of(dialogContext).pop(),
  ),
);

class _DeleteCardDialog extends StatelessWidget {
  const _DeleteCardDialog({
    required this.cardId,
    required this.onDeleted,
    required this.onClose,
  });

  final String cardId;
  final VoidCallback onDeleted;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final provider = cardDeleteProvider(cardId);

    return Consumer(
      builder: (context, ref, child) {
        final submit = ref.watch(provider);

        ref.listen<CardSubmitState>(provider, (previous, next) {
          if (!next.shouldClose || (previous?.shouldClose ?? false)) return;
          onClose();
          onDeleted();
        });

        return MxConfirmDialog(
          title: context.l10n.cardDeleteConfirmTitle,
          message: submit.failure != null
              ? context.l10n.cardDeleteFailed
              : context.l10n.cardDeleteConfirmMessage,
          confirmLabel: context.l10n.cardDeleteConfirmAction,
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
