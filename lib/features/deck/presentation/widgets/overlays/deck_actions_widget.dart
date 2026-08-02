import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_action_sheet.dart';
import '../../../../../shared/widgets/mx_form_sheet.dart';
import '../../../domain/failures/deck_validation_failure.dart';
import '../../../domain/models/deck_content_type_model.dart';
import '../../../domain/entities/deck_entity.dart';
import 'deck_confirm_widget.dart';
import 'deck_form_widget.dart';
import '../../controllers/deck_write_controller.dart';
import 'move_deck_sheet_widget.dart';

/// Opens the per-deck action menu and everything it leads to.
///
/// A function rather than a widget because it is a sequence of modals, not a
/// piece of layout. Keeping it in one place is what stops the root list and the
/// detail screen growing two different action sets for the same deck — the bug
/// UC-08 warns about, where Create behaves differently depending on which screen
/// you reached the deck from.
///
/// Every action's *availability* is decided here from the deck's own state
/// (BR-58, BR-59, BR-66, BR-68); every action's *legality* is decided by the
/// repository. Reset, for example, is offered when this screen can see no child
/// decks, and refused by the repository if the deck still holds cards — which is
/// the only correct division, because this screen does not read the card
/// feature.
Future<void> showDeckActions(
  BuildContext context, {
  required DeckEntity deck,
  required bool mayOfferReset,
  required VoidCallback onDeleted,
}) async {
  final action = await showModalBottomSheet<_DeckAction>(
    context: context,
    builder: (sheetContext) => MxActionSheet(
      title: sheetContext.l10n.deckActionsTitle,
      actions: <MxActionSheetAction>[
        MxActionSheetAction(
          label: sheetContext.l10n.deckRenameAction,
          icon: Icons.edit_outlined,
          onPressed: () => Navigator.of(sheetContext).pop(_DeckAction.rename),
        ),
        // A root deck cannot be moved: it would need scheduler columns on a
        // non-root, which BR-06 forbids, and demoting a root is a new decision
        // rather than a move (UC-09 A2).
        if (!deck.isRoot)
          MxActionSheetAction(
            label: sheetContext.l10n.deckMoveAction,
            icon: Icons.drive_file_move_outlined,
            onPressed: () => Navigator.of(sheetContext).pop(_DeckAction.move),
          ),
        if (mayOfferReset && deck.contentType != DeckContentType.unset)
          MxActionSheetAction(
            label: sheetContext.l10n.deckResetContentTypeAction,
            icon: Icons.restart_alt,
            onPressed: () => Navigator.of(sheetContext).pop(_DeckAction.reset),
          ),
        MxActionSheetAction(
          label: sheetContext.l10n.deckDeleteAction,
          icon: Icons.delete_outline,
          variant: MxActionSheetActionVariant.destructive,
          onPressed: () => Navigator.of(sheetContext).pop(_DeckAction.delete),
        ),
      ],
    ),
  );

  if (!context.mounted || action == null) return;

  switch (action) {
    case _DeckAction.rename:
      await showDeckRenameForm(context, deck: deck);
    case _DeckAction.move:
      await showDeckMoveSheet(context, deckId: deck.id);
    case _DeckAction.reset:
      await showDeckResetContentTypeConfirm(context, deck: deck);
    case _DeckAction.delete:
      await showDeckDeleteConfirm(context, deck: deck, onDeleted: onDeleted);
  }
}

enum _DeckAction { rename, move, reset, delete }

/// The rename form (UC-03).
Future<void> showDeckRenameForm(
  BuildContext context, {
  required DeckEntity deck,
}) => showMxFormSheet(
  context,
  reset: (ref) =>
      ref.read(renameDeckControllerProvider(deck.id).notifier).reset(),
  builder: (sheetContext, ref, close) {
    final provider = renameDeckControllerProvider(deck.id);

    return MxFormHost<DeckValidationProblem>(
      state: ref.watch(provider),
      onDone: close,
      child: DeckFormWidget(
        title: sheetContext.l10n.deckRenameTitle,
        submitLabel: sheetContext.l10n.deckRenameSubmitAction,
        initialName: deck.name,
        state: ref.watch(provider),
        onSubmit: (name, _) => ref.read(provider.notifier).submit(name: name),
        onCancel: close,
      ),
    );
  },
);

/// The create-root-deck form (UC-02).
Future<void> showCreateRootDeckForm(BuildContext context) => showMxFormSheet(
  context,
  reset: (container) =>
      container.read(createRootDeckControllerProvider.notifier).reset(),
  builder: (sheetContext, ref, close) {
    final provider = createRootDeckControllerProvider;

    return MxFormHost<DeckValidationProblem>(
      state: ref.watch(provider),
      onDone: close,
      child: DeckFormWidget(
        title: sheetContext.l10n.deckCreateRootTitle,
        submitLabel: sheetContext.l10n.deckFormSubmitAction,
        // The only form that offers the choice, and it is mandatory (BR-11).
        isSchedulerRequired: true,
        state: ref.watch(provider),
        onSubmit: (name, scheduler) => ref
            .read(provider.notifier)
            .submit(name: name, schedulerType: scheduler),
        onCancel: close,
      ),
    );
  },
);

/// The create-sub-deck form (UC-08).
///
/// No scheduler section: a sub-deck inherits from its root and must leave the
/// scheduler columns null (BR-06).
Future<void> showCreateSubDeckForm(
  BuildContext context, {
  required String parentDeckId,
}) => showMxFormSheet(
  context,
  reset: (container) => container
      .read(createSubDeckControllerProvider(parentDeckId).notifier)
      .reset(),
  builder: (sheetContext, ref, close) {
    final provider = createSubDeckControllerProvider(parentDeckId);

    return MxFormHost<DeckValidationProblem>(
      state: ref.watch(provider),
      onDone: close,
      child: DeckFormWidget(
        title: sheetContext.l10n.deckCreateSubDeckTitle,
        submitLabel: sheetContext.l10n.deckFormSubmitAction,
        state: ref.watch(provider),
        onSubmit: (name, _) => ref.read(provider.notifier).submit(name: name),
        onCancel: close,
      ),
    );
  },
);

/// The move picker (UC-09).
Future<void> showDeckMoveSheet(
  BuildContext context, {
  required String deckId,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  builder: (sheetContext) => MoveDeckSheetWidget(
    deckId: deckId,
    onDone: () => Navigator.of(sheetContext).pop(),
  ),
);
