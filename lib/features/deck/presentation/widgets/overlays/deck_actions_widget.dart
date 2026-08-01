import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_action_sheet.dart';
import '../../../domain/models/deck_content_type_model.dart';
import '../../../domain/entities/deck_entity.dart';
import 'deck_confirm_widget.dart';
import 'deck_form_widget.dart';
import '../../states/deck_submit_state.dart';
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
}) => _showFormSheet(
  context,
  reset: (ref) =>
      ref.read(renameDeckControllerProvider(deck.id).notifier).reset(),
  builder: (sheetContext, ref, close) {
    final provider = renameDeckControllerProvider(deck.id);

    return _FormHost(
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
Future<void> showCreateRootDeckForm(BuildContext context) => _showFormSheet(
  context,
  reset: (container) =>
      container.read(createRootDeckControllerProvider.notifier).reset(),
  builder: (sheetContext, ref, close) {
    final provider = createRootDeckControllerProvider;

    return _FormHost(
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
}) => _showFormSheet(
  context,
  reset: (container) => container
      .read(createSubDeckControllerProvider(parentDeckId).notifier)
      .reset(),
  builder: (sheetContext, ref, close) {
    final provider = createSubDeckControllerProvider(parentDeckId);

    return _FormHost(
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

/// Wraps a form in a bottom sheet with the keyboard inset applied.
///
/// `isScrollControlled` plus the view insets, because without both the sheet is
/// capped at half the screen and the keyboard covers the submit button — a form
/// you cannot submit without dismissing the keyboard first.
Future<void> _showFormSheet(
  BuildContext context, {
  required Widget Function(BuildContext, WidgetRef, VoidCallback) builder,
  required void Function(ProviderContainer) reset,
}) {
  // Cleared here, from the tap that opens the form — not from a widget
  // life-cycle. Riverpod refuses a provider mutation during `build`, `initState`
  // or `dispose`, and resetting from `dispose` additionally races the
  // controller's own disposal: an autoDispose provider with no listeners left is
  // already gone by the time a scheduled callback runs.
  reset(ProviderScope.containerOf(context));

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: AppSpacing.lg + MediaQuery.viewInsetsOf(sheetContext).bottom,
      ),
      child: SingleChildScrollView(
        child: Consumer(
          builder: (consumerContext, ref, _) => builder(
            consumerContext,
            ref,
            () => Navigator.of(sheetContext).pop(),
          ),
        ),
      ),
    ),
  );
}

/// Closes its sheet the moment the operation reports success.
///
/// Takes the state and a callback rather than a provider, because the six write
/// controllers are six distinct generated provider types — three of them
/// families — and no single parameter type unifies them. Passing the values keeps
/// this widget honest about what it actually needs: a state to compare against,
/// and something to call.
///
/// **Resetting happens on open, not on close.** A reset scheduled from `dispose`
/// races the provider's own disposal: by the time the microtask runs, an
/// autoDispose controller with no listeners left is already gone, and touching
/// its `Ref` throws. Clearing at the point the form is shown is deterministic and
/// gives the same guarantee — a reopened form starts clean.
class _FormHost extends StatefulWidget {
  const _FormHost({
    required this.state,
    required this.onDone,
    required this.child,
  });

  final DeckSubmitState state;
  final VoidCallback onDone;
  final Widget child;

  @override
  State<_FormHost> createState() => _FormHostState();
}

class _FormHostState extends State<_FormHost> {
  @override
  void didUpdateWidget(_FormHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The transition, not the value: reacting to the outcome alone would fire on
    // every rebuild that happens to see it and pop the sheet more than once.
    //
    // And `shouldClose`, not "succeeded": a form that saved and stayed open for
    // the next entry reports `savedAndContinue`, and closing on that would be the
    // bug this distinction exists to prevent. Deck has no such form today; the
    // check is written this way so cloning it into one cannot go wrong silently.
    if (widget.state.shouldClose && !oldWidget.state.shouldClose) {
      widget.onDone();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
