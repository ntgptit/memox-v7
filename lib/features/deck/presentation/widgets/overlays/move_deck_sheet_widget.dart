import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/foundations/app_spacing.dart';
import '../../../../../core/theme/extensions/app_ink.dart';
import '../../../../../core/theme/extensions/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_action_button.dart';
import '../../../../../shared/widgets/mx_async_view.dart';
import '../../../../../shared/widgets/mx_empty_state.dart';
import '../../../../../shared/widgets/mx_error_state.dart';
import '../../../../../shared/widgets/mx_feedback_band.dart';
import '../../../../../shared/widgets/mx_icon.dart';
import '../../../../../shared/widgets/mx_list_tile.dart';
import '../../../domain/models/deck_move_target_model.dart';
import '../support/deck_labels_widget.dart';
import '../../controllers/deck_move_targets_controller.dart';
import '../../states/deck_submit_state.dart';
import '../../controllers/deck_write_controller.dart';
import '../../../../../shared/widgets/mx_sheet_insets.dart';

/// The move-target picker (UC-09).
///
/// Shows **every** deck, with the ineligible ones disabled and the reason beside
/// them, rather than silently omitting them. A picker that hides what it will not
/// accept leaves the user hunting for a deck that is right there in the tree;
/// naming the reason is also the only way "the target uses a different study
/// mode" ever becomes learnable (BR-74).
///
/// Indentation carries depth, because UC-09 requires two decks with the same name
/// to be distinguishable and a flat list of names cannot do that.
///
/// **A tap picks; the primary commits** (SC-C4-16). This used to move the deck on
/// the tap that landed on a row — a whole subtree relocated by one press, with
/// nothing drawn to say which target was current and no Undo behind it
/// (`deck_write_controller.dart` returns a batch id for delete only). The app's
/// other write-target picker, `trash_restore_target_sheet_widget`, already argues
/// the opposite shape and states why; two pickers for the same kind of action are
/// not allowed to disagree, and of the two it is this one — the irreversible one —
/// that had to move. The chooser sheets that still commit on tap (study mode,
/// study direction) start a session rather than write, so they are a different
/// grammar rather than a counter-example.
///
/// The disabled rows are a courtesy, not a guard. Submitting still calls
/// `moveDeck`, which re-runs every rule inside the transaction — the picker can be
/// stale, and a stale picker must never be able to widen what the database
/// accepts. That is also why the same `canSubmit && isEligible` still gates the
/// *selection*: picking a row the transaction would refuse must not become
/// reachable just because the commit moved to a button of its own.
///
/// Stateful, and the `Consumer` stays. The scoped rebuild is the honest reason —
/// only the list depends on the providers — and it also keeps this file clear of
/// the two-argument `build` signature that the project guard misreads as a
/// Riverpod 2 generated ref type.
class MoveDeckSheetWidget extends StatefulWidget {
  const MoveDeckSheetWidget({
    required this.deckId,
    required this.onDone,
    super.key,
  });

  final String deckId;

  /// Called once the move has landed, so the caller can close the sheet.
  final VoidCallback onDone;

  @override
  State<MoveDeckSheetWidget> createState() => _MoveDeckSheetWidgetState();
}

class _MoveDeckSheetWidgetState extends State<MoveDeckSheetWidget> {
  /// What the user has picked. Held by deck id rather than by target, because
  /// the list comes from a live stream and the object identity changes on every
  /// emission while the id does not — the same reason
  /// `_TrashRestoreTargetSheetState` holds an id.
  ///
  /// Nothing is preselected. A restore has an obvious default — where the batch
  /// came from — and a move has none: the deck's current parent is one of the
  /// rows this picker refuses.
  String? _selectedDeckId;

  @override
  Widget build(BuildContext context) {
    return MxSheetInsets(
      child: Consumer(
        builder: (context, ref, child) {
          final provider = moveDeckControllerProvider(widget.deckId);
          final submit = ref.watch(provider);
          // A one-shot side effect driven by a state transition rather than
          // fired from a rebuild: `listen` runs on change, so the sheet closes
          // once instead of on every rebuild that happens to see the outcome.
          ref.listen<DeckSubmitState>(provider, (previous, next) {
            if (next.shouldClose && !(previous?.shouldClose ?? false)) {
              widget.onDone();
            }
          });

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // The sheet's title announces as a header (A20.1 P1-01,
              // §23 #17).
              Semantics(
                header: true,
                child: Text(
                  context.l10n.deckMoveTitle,
                  style: context.texts.titleMedium,
                ),
              ),
              if (submit.failure != null) ...<Widget>[
                // The one grammar for an in-flow failure, as in every other
                // sheet in this unit — see `deck_form_widget.dart` for why the
                // bare red line went (SC-C3-19).
                //
                // The band sits above a `Flexible` list, so it takes height
                // from the targets rather than from the sheet. That is the
                // right way round: a refused move is the only reason to still
                // be looking at this list, and the list is scrollable while
                // the reason is not.
                const SizedBox(height: AppSpacing.lg),
                MxFeedbackBand(
                  title: context.l10n.deckWriteErrorTitle,
                  message: context.deckWriteFailure(submit.failure!),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              Flexible(
                child: MxAsyncView<List<DeckMoveTarget>>(
                  value: ref.watch(deckMoveTargetsProvider(widget.deckId)),
                  loadingLabel: context.l10n.deckMoveLoadingLabel,
                  data: (targets) => _TargetPicker(
                    targets: targets,
                    canSubmit: submit.canSubmit,
                    isSubmitting: submit.isSubmitting,
                    selectedDeckId: _selectedDeckId,
                    onSelect: (deckId) =>
                        setState(() => _selectedDeckId = deckId),
                    onConfirm: (deckId) => ref
                        .read(provider.notifier)
                        .submit(targetParentDeckId: deckId),
                  ),
                  error: (error, stackTrace) => MxErrorState(
                    title: context.l10n.deckWriteErrorTitle,
                    message: context.l10n.deckWriteErrorMessage,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// The targets, and the primary that commits the pick.
///
/// The pair lives inside the data face rather than beside the `MxAsyncView`,
/// the way `_Body` does in the restore sheet: a commit button under a spinner,
/// or under "nowhere to move this", is a control for a choice that does not
/// exist yet.
class _TargetPicker extends StatelessWidget {
  const _TargetPicker({
    required this.targets,
    required this.canSubmit,
    required this.isSubmitting,
    required this.selectedDeckId,
    required this.onSelect,
    required this.onConfirm,
  });

  final List<DeckMoveTarget> targets;
  final bool canSubmit;
  final bool isSubmitting;
  final String? selectedDeckId;
  final ValueChanged<String> onSelect;
  final ValueChanged<String> onConfirm;

  /// The picked target, or null when the selection no longer names an eligible
  /// row. The tree arrives as a live stream, so a deck picked a moment ago can
  /// have grown cards or become this deck's parent since; re-reading the
  /// selection out of the current list is what keeps the primary honest.
  DeckMoveTarget? get _chosen {
    for (final target in targets) {
      if (target.deck.id == selectedDeckId && target.isEligible) return target;
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    // Every deck rejected is the same situation as no decks at all, from where
    // the user stands: there is nowhere to put this one.
    if (targets.every((target) => !target.isEligible)) {
      return MxEmptyState(
        icon: Icons.drive_file_move_outlined,
        title: context.l10n.deckMoveEmptyTitle,
        message: context.l10n.deckMoveEmptyMessage,
      );
    }

    final chosen = _chosen;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Flexible(
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: targets.length,
            itemBuilder: (context, index) => _TargetRow(
              target: targets[index],
              isEnabled: canSubmit && targets[index].isEligible,
              isSelected: targets[index].deck.id == selectedDeckId,
              onTap: () => onSelect(targets[index].deck.id),
            ),
          ),
        ),
        // `lg`, the step the app's other list-then-commit sheets take
        // (trash_restore_target_sheet_widget.dart, study_direction_chooser_
        // widget.dart) rather than the `xl` this unit's forms take. The five
        // sheets `deck_sheet_footer_gap_test` holds at `xl` all step from a
        // settled content element — the scheduler picker — to their footer;
        // what steps here is a scrolling list, which is the boundary the
        // restore picker argued at `lg`.
        const SizedBox(height: AppSpacing.lg),
        MxActionButton(
          label: context.l10n.deckMoveAction,
          isLoading: isSubmitting,
          // Disabled rather than silently inert, and the gate is the resolved
          // target rather than the raw id: nothing picked, or a pick the tree
          // has since refused, both mean there is no move to make.
          onPressed: chosen == null || !canSubmit
              ? null
              : () => onConfirm(chosen.deck.id),
        ),
      ],
    );
  }
}

class _TargetRow extends StatelessWidget {
  const _TargetRow({
    required this.target,
    required this.isEnabled,
    required this.isSelected,
    required this.onTap,
  });

  final DeckMoveTarget target;
  final bool isEnabled;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final rejection = target.rejection;

    return Padding(
      // Depth as a leading inset, on the spacing scale so it stays on the grid.
      // The root is depth 1 and gets none.
      padding: EdgeInsetsDirectional.only(
        start: AppSpacing.md * (target.depth - 1),
      ),
      child: MxListTile(
        title: target.deck.name,
        subtitle: rejection == null
            ? null
            : context.deckMoveRejectionText(rejection),
        // Selected state is never colour alone — the same radio pair the
        // restore picker draws. The row used to lead with a folder glyph,
        // which said "deck" in a list where every row is a deck and said
        // nothing at all about which one was chosen.
        //
        // Inked only while the row can be picked. `MxIcon` holds whatever
        // `AppInk` it is handed, so an inked radio would stay lit on a refused
        // row whose title beside it has greyed out; a colourless `Icon` takes
        // the tile's own disabled `IconTheme` instead — the case `MxIcon`'s
        // note keeps a bare `Icon` legal for.
        leading: isEnabled
            ? MxIcon(
                isSelected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                ink: isSelected ? AppInk.accent : AppInk.quiet,
              )
            : const Icon(Icons.radio_button_unchecked),
        isEnabled: isEnabled,
        isSelected: isSelected,
        onTap: onTap,
      ),
    );
  }
}
