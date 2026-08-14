import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/navigation/route_names.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_confirm_dialog.dart';
import '../../../domain/models/deck_deletion_impact_model.dart';
import '../../../domain/entities/deck_entity.dart';
import '../../controllers/deck_deletion_impact_controller.dart';
import '../support/deck_labels_widget.dart';
import '../../states/deck_submit_state.dart';
import '../../controllers/deck_write_controller.dart';

/// The two confirmations a deck action can lead to: delete, and putting an empty
/// sub-deck's content type back to `unset`.
///
/// Split from `deck_actions_widget.dart` so neither file outgrows the project's
/// size limit, and along a real seam: that file decides *which* action the user
/// picked, this one asks *are you sure* and owns the state of the write that
/// follows. Both dialogs read a provider, which the menu itself does not.

/// The delete confirmation, with the impact read before it is shown (BR-04).
/// [onDeleted] receives the deletion's batch id, which is what an Undo
/// affordance acts on (BR-189). It is null only when the write failed, which
/// the dialog has already reported.
Future<void> showDeckDeleteConfirm(
  BuildContext context, {
  required DeckEntity deck,
  required ValueChanged<String?> onDeleted,
}) => showDialog<void>(
  context: context,
  builder: (dialogContext) => _DeleteDeckDialog(
    deck: deck,
    onDeleted: onDeleted,
    onClose: () => Navigator.of(dialogContext).pop(),
  ),
);

/// Reads the deletion impact, then asks (BR-04).
///
/// The read happens inside the dialog so the numbers are as fresh as the moment
/// the dialog opened, and so a failed read shows as a failed dialog rather than
/// a confirmation with blanks where the counts should be.
class _DeleteDeckDialog extends ConsumerStatefulWidget {
  const _DeleteDeckDialog({
    required this.deck,
    required this.onDeleted,
    required this.onClose,
  });

  final DeckEntity deck;
  final ValueChanged<String?> onDeleted;
  final VoidCallback onClose;

  @override
  ConsumerState<_DeleteDeckDialog> createState() => _DeleteDeckDialogState();
}

class _DeleteDeckDialogState extends ConsumerState<_DeleteDeckDialog> {
  late final Future<DeckDeletionImpact> _impact = ref.read(
    deckDeletionImpactProvider(widget.deck.id).future,
  );

  /// The batch the write created, held only until the dialog closes.
  String? _batchId;

  @override
  Widget build(BuildContext context) {
    final provider = deleteDeckControllerProvider(widget.deck.id);
    final submit = ref.watch(provider);

    ref.listen<DeckSubmitState>(provider, (previous, next) {
      if (!next.shouldClose || (previous?.shouldClose ?? false)) return;
      widget.onClose();
      // The batch id was captured by `onConfirm` below, one frame before this
      // fires. Reading it here rather than threading it through the state keeps
      // it as short-lived as it actually is.
      widget.onDeleted(_batchId);
    });

    return FutureBuilder<DeckDeletionImpact>(
      future: _impact,
      builder: (context, snapshot) {
        final impact = snapshot.data;
        final message = impact == null
            // Never a confirmation with the numbers missing: until the impact is
            // known the dialog cannot say what will be lost, and BR-04 makes
            // that statement the point of the dialog.
            ? context.l10n.deckDetailLoadingLabel
            : context.l10n.deckDeleteImpactMessage(
                impact.descendantDeckCount,
                impact.cardCount,
              );

        return MxConfirmDialog(
          title: context.l10n.deckDeleteConfirmTitle(widget.deck.name),
          message: submit.failure != null
              ? context.deckWriteFailure(submit.failure!)
              : message,
          confirmLabel: context.l10n.deckDeleteConfirmAction,
          cancelLabel: context.l10n.commonCancelAction,
          // Soft delete since v8: the deck goes to Trash and comes back
          // for thirty days, so it keeps the safe default focus and gives
          // the destructive colour back to the one dialog that means it
          // (BR-182, BR-192).
          variant: MxConfirmDialogVariant.cautious,
          isSubmitting: submit.isSubmitting || impact == null,
          onConfirm: () async {
            _batchId = await ref.read(provider.notifier).submit();
          },
          onCancel: widget.onClose,
        );
      },
    );
  }
}

/// Leaves a deck that has just been deleted, for the level that held it.
///
/// **Up one level, not back to the root.** A deleted deck's siblings are what
/// the user was browsing, so that is where they belong; being dropped at the
/// root reads as though more than the one deck had gone. A deleted *root* deck
/// has no level above it, so the root list is the honest destination there.
///
/// `goNamed`, not `pop`: the deck was reached by a deep link as often as by a
/// tap, and popping a stack that may have one entry leaves nowhere to land.
void leaveDeletedDeck(BuildContext context, DeckEntity deleted) {
  final parentId = deleted.parentDeckId;
  if (parentId == null) {
    context.goNamed(RouteNames.decks);
    return;
  }

  context.goNamed(
    RouteNames.deckDetail,
    pathParameters: <String, String>{RoutePathParams.deckId: parentId},
  );
}
