import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_action_sheet.dart';
import '../../../../../shared/widgets/mx_form_sheet.dart';
import '../../../domain/failures/deck_validation_failure.dart';
import '../../../domain/entities/deck_entity.dart';
import 'deck_confirm_widget.dart';
import 'deck_reset_progress_widget.dart';
import 'deck_scheduler_change_widget.dart';
import 'deck_form_widget.dart';
import '../../controllers/deck_write_controller.dart';
import 'move_deck_sheet_widget.dart';
import '../../../../../shared/widgets/mx_sheet.dart';

/// Opens the per-deck action menu and everything it leads to.
///
/// A function rather than a widget because it is a sequence of modals, not a
/// piece of layout. Keeping it in one place is what stops the root list and the
/// detail screen growing two different action sets for the same deck — the bug
/// UC-08 warns about, where Create behaves differently depending on which screen
/// you reached the deck from.
///
/// Every action's *availability* is decided here from the deck's own state
/// (BR-58, BR-59, BR-66); every action's *legality* is decided by the
/// repository.
///
/// **There is no content-type action any more (BR-163).** It used to offer
/// "allow both kinds again" on an empty typed deck; the type is now system
/// state that the delete and move transactions maintain themselves, so the
/// sheet has one fewer thing to explain.
Future<void> showDeckActions(
  BuildContext context, {
  required DeckEntity deck,

  /// Called with the deletion's batch id, for the Undo affordance (BR-263).
  required ValueChanged<String?> onDeleted,

  /// Whether Reset learning progress is offered, and whether it has anything to
  /// take away (UC-07, A2).
  ///
  /// **Null means the caller cannot see the counts, so it does not offer it.**
  /// The level *inside* a deck reads its children, not the deck's own learned
  /// total — offering the action from there would mean guessing which of BR-50's
  /// two lists to show, and the guess would be a warning about nothing on a deck
  /// nobody has studied.
  bool? hasLearnedCards,

  /// The level's due-only view toggle, shown when the caller passes both.
  /// The filter lives in this menu now — it and sort wore the same pill
  /// clothes on the toolbar, and the rarer control moved off the row
  /// (owner mockup, 2026-08-20). A view toggle in an action menu is
  /// deliberate: it acts on the list the menu was opened over.
  bool? isDueFilterActive,
  VoidCallback? onToggleDueFilter,

  /// Reorder is only offered while the level is showing its persisted Manual
  /// order, so these targets are actual neighbouring siblings rather than a
  /// neighbour manufactured by a view-only sort.
  VoidCallback? onMoveEarlier,
  VoidCallback? onMoveLater,
}) async {
  final action = await showMxSheet<_DeckAction>(
    context,
    builder: (sheetContext) => MxActionSheet(
      title: sheetContext.l10n.deckActionsTitle,
      actions: <MxActionSheetAction>[
        if (isDueFilterActive != null && onToggleDueFilter != null)
          MxActionSheetAction(
            label: isDueFilterActive
                ? sheetContext.l10n.deckFilterAllLabel
                : sheetContext.l10n.deckFilterDueLabel,
            icon: Icons.filter_list,
            onPressed: () =>
                Navigator.of(sheetContext).pop(_DeckAction.toggleDueFilter),
          ),
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
        if (onMoveEarlier != null)
          MxActionSheetAction(
            label: sheetContext.l10n.deckMoveEarlierAction,
            icon: Icons.keyboard_arrow_up,
            onPressed: () =>
                Navigator.of(sheetContext).pop(_DeckAction.moveEarlier),
          ),
        if (onMoveLater != null)
          MxActionSheetAction(
            label: sheetContext.l10n.deckMoveLaterAction,
            icon: Icons.keyboard_arrow_down,
            onPressed: () =>
                Navigator.of(sheetContext).pop(_DeckAction.moveLater),
          ),
        // A root deck only, and offered whether or not the mode is locked:
        // UC-03 A1 keeps the section visible on a studied deck so the lock can
        // explain itself and point at Reset. Hiding it is what makes a user
        // believe the app cannot change study mode at all. A sub-deck has no
        // scheduler columns to write (BR-06), so it has no such action.
        if (deck.isRoot)
          MxActionSheetAction(
            label: sheetContext.l10n.deckSchedulerChangeAction,
            icon: Icons.tune,
            onPressed: () =>
                Navigator.of(sheetContext).pop(_DeckAction.scheduler),
          ),
        // A root deck only: the scheduler and the generation belong to the root
        // (BR-05), so there is no such operation one level down (UC-07 A4).
        if (deck.isRoot && hasLearnedCards != null)
          MxActionSheetAction(
            label: sheetContext.l10n.deckResetProgressAction,
            icon: Icons.restore,
            onPressed: () =>
                Navigator.of(sheetContext).pop(_DeckAction.resetProgress),
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
    case _DeckAction.toggleDueFilter:
      onToggleDueFilter?.call();
    case _DeckAction.rename:
      await showDeckRenameForm(context, deck: deck);
    case _DeckAction.move:
      await showDeckMoveSheet(context, deckId: deck.id);
    case _DeckAction.moveEarlier:
      onMoveEarlier?.call();
    case _DeckAction.moveLater:
      onMoveLater?.call();
    case _DeckAction.scheduler:
      await showDeckSchedulerSheet(context, deck: deck);
    case _DeckAction.resetProgress:
      await showDeckResetProgressConfirm(
        context,
        deck: deck,
        hasLearnedCards: hasLearnedCards ?? false,
      );
    case _DeckAction.delete:
      await showDeckDeleteConfirm(context, deck: deck, onDeleted: onDeleted);
  }
}

/// `scheduler` is BR-12's unlocked change (and, on a locked deck, the
/// explanation of why it is not available). `resetProgress` is UC-07 — Reset
/// learning progress, which is the only way past the lock. Both kept long names
/// after the content-type reset was removed (BR-163), because "reset" alone was
/// never enough to tell any two of them apart.
enum _DeckAction {
  toggleDueFilter,
  rename,
  move,
  moveEarlier,
  moveLater,
  scheduler,
  resetProgress,
  delete,
}

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
}) => showMxSheet<void>(
  context,
  builder: (sheetContext) => MoveDeckSheetWidget(
    deckId: deckId,
    onDone: () => Navigator.of(sheetContext).pop(),
  ),
);
