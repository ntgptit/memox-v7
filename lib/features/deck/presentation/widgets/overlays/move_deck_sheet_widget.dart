import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/foundations/app_spacing.dart';
import '../../../../../core/theme/extensions/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_async_view.dart';
import '../../../../../shared/widgets/mx_empty_state.dart';
import '../../../../../shared/widgets/mx_error_state.dart';
import '../../../../../shared/widgets/mx_feedback_band.dart';
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
/// The disabled rows are a courtesy, not a guard. Submitting still calls
/// `moveDeck`, which re-runs every rule inside the transaction — the picker can be
/// stale, and a stale picker must never be able to widen what the database
/// accepts.
///
/// A plain widget wrapping a `Consumer`, rather than a consumer widget itself.
/// The scoped rebuild is the honest reason — only the list depends on the
/// providers — and it also keeps this file clear of the two-argument `build`
/// signature that the project guard misreads as a Riverpod 2 generated ref type.
class MoveDeckSheetWidget extends StatelessWidget {
  const MoveDeckSheetWidget({
    required this.deckId,
    required this.onDone,
    super.key,
  });

  final String deckId;

  /// Called once the move has landed, so the caller can close the sheet.
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return MxSheetInsets(
      child: Consumer(
        builder: (context, ref, child) {
          final submit = ref.watch(moveDeckControllerProvider(deckId));
          // A one-shot side effect driven by a state transition rather than
          // fired from a rebuild: `listen` runs on change, so the sheet closes
          // once instead of on every rebuild that happens to see the outcome.
          ref.listen<DeckSubmitState>(moveDeckControllerProvider(deckId), (
            previous,
            next,
          ) {
            if (next.shouldClose && !(previous?.shouldClose ?? false)) {
              onDone();
            }
          });

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                context.l10n.deckMoveTitle,
                style: context.texts.titleMedium,
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
                  value: ref.watch(deckMoveTargetsProvider(deckId)),
                  loadingLabel: context.l10n.deckMoveLoadingLabel,
                  data: (targets) => _TargetList(
                    targets: targets,
                    canSubmit: submit.canSubmit,
                    onChoose: (target) => ref
                        .read(moveDeckControllerProvider(deckId).notifier)
                        .submit(targetParentDeckId: target.deck.id),
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

class _TargetList extends StatelessWidget {
  const _TargetList({
    required this.targets,
    required this.canSubmit,
    required this.onChoose,
  });

  final List<DeckMoveTarget> targets;
  final bool canSubmit;
  final ValueChanged<DeckMoveTarget> onChoose;

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

    return ListView.builder(
      shrinkWrap: true,
      itemCount: targets.length,
      itemBuilder: (context, index) => _TargetRow(
        target: targets[index],
        isEnabled: canSubmit && targets[index].isEligible,
        onTap: () => onChoose(targets[index]),
      ),
    );
  }
}

class _TargetRow extends StatelessWidget {
  const _TargetRow({
    required this.target,
    required this.isEnabled,
    required this.onTap,
  });

  final DeckMoveTarget target;
  final bool isEnabled;
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
        leading: const Icon(Icons.folder_outlined),
        isEnabled: isEnabled,
        onTap: onTap,
      ),
    );
  }
}
