import 'package:flutter/material.dart';

import '../../../../../core/theme/app_ink.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_action_button.dart';
import '../../../../../shared/widgets/mx_card.dart';
import '../../../domain/models/study_home_deck_model.dart';
import '../support/study_home_labels_widget.dart';
import 'study_home_workload_item_widget.dart';

/// One root deck on the Study tab: what it is, what is waiting, one way in.
///
/// **One action, and it is a button rather than the whole card.** The deck list
/// makes its whole tile tappable because opening a deck is browsing — cheap, and
/// reversible with Back. Here the tap leads into a study session, which is the
/// one thing on this screen that may write (BR-200, BR-101); a card that starts
/// it by being brushed against is a session nobody chose. So the surface is a
/// surface, and the verb is a verb.
///
/// **A deck with cards but nothing waiting keeps its button** (BR-201, BR-29).
/// Studying ahead is allowed and "nothing due" is the schedule working, so the
/// entry screen is where the honest answer belongs — not a greyed control that
/// says you cannot do the thing when the truth is there is nothing to do. A deck
/// with no cards at all has nothing behind the action and does not reach this
/// widget; the list filters it out.
///
/// **The verb shares the workload's band when there is room, and steps below it
/// when there is not.** Every row used to spend a full extra band on its one
/// button, which is what made a short list fill the viewport; the compact
/// arrangement trails the verb after the counts, Card Detail's density on a
/// task card. The decision is measured, not guessed: the threshold scales with
/// the user's text size, so large type stacks instead of squeezing three counts
/// against a button (wireframe G8/G15).
class StudyHomeDeckItemWidget extends StatelessWidget {
  const StudyHomeDeckItemWidget({
    required this.deck,
    required this.onStudy,
    super.key,
  });

  final StudyHomeDeckModel deck;
  final VoidCallback onStudy;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheduler = context.studyHomeSchedulerLabel(deck.schedulerType);

    final workload = l10n.studyHomeWorkloadSemanticLabel(
      deck.overdueCount,
      deck.dueTodayCount,
      deck.newCount,
    );

    // Flat with a hairline, like the deck card: two competing depths in one
    // scrolling column is what makes a list read as busy.
    //
    // **What the row says is one sentence, and it names its deck.** The card
    // has no `onTap` (S4), so nothing here owns a node on its own: the name,
    // the algorithm and the three counts each became a node of their own, and
    // a reader walking three decks heard "8 boxes" and "2 overdue, 5 due
    // today, 12 new" with nothing saying whose they were. The sentence node
    // spans the whole card — identity *and* counts, wherever the adaptive
    // layout puts them — and the button keeps its own role and name inside it.
    return MxCard.flat(
      child: Semantics(
        container: true,
        label: scheduler == null
            ? l10n.studyHomeDeckRowPlainSemanticLabel(deck.deckName, workload)
            : l10n.studyHomeDeckRowSemanticLabel(
                deck.deckName,
                scheduler,
                workload,
              ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ExcludeSemantics(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    deck.deckName,
                    style: context.texts.titleMedium,
                    // Two lines, then ellipsis. A deck named by a sentence must not push
                    // the workload line off the bottom of the card, and a name that
                    // wraps forever turns a scannable list into a wall.
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (scheduler != null) ...<Widget>[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      scheduler,
                      style: context.texts.bodySmall!.inked(
                        context,
                        AppInk.quiet,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            // The seam between what the deck *is* and what is waiting in it —
            // one step more than the line breaks inside the identity block.
            const SizedBox(height: AppSpacing.sm),
            _WorkloadActionArea(deck: deck, onStudy: onStudy),
          ],
        ),
      ),
    );
  }
}

/// The counts and the verb, arranged by measurement.
///
/// Inline when the row can honestly hold both — the counts lead, the verb
/// trails on the same band — and stacked with the verb one section step below
/// otherwise. `LayoutBuilder` rather than a viewport read: the row answers to
/// the width it was actually given, and the threshold is scaled by the text
/// factor so doubled type gets the stacked arrangement rather than a squeeze.
class _WorkloadActionArea extends StatelessWidget {
  const _WorkloadActionArea({required this.deck, required this.onStudy});

  final StudyHomeDeckModel deck;
  final VoidCallback onStudy;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    // **The workload's own node is excluded here, not swallowed by accident.**
    // The identity block above already announces the whole row as one sentence
    // that includes the counts, so the widget rendering them must stay silent
    // wherever the layout puts it — beside the verb or above it.
    final workload = ExcludeSemantics(
      child: StudyHomeWorkloadItemWidget(deck: deck),
    );
    // **The action is renamed, and the button owns the rename.** Every row
    // carries the same word, so a screen reader walking the list would hear
    // "Study" three times with nothing to tell the rows apart; the deck name
    // is what does. Passing it to the button rather than wrapping the button
    // keeps its role, its enabled state and its ink. Compact, like the deck
    // tile's Study verb: 40 drawn, and `padded` keeps the 48 target.
    final action = MxActionButton(
      label: l10n.studyHomeStudyAction,
      semanticLabel: l10n.studyHomeStudySemanticLabel(deck.deckName),
      icon: Icons.play_arrow,
      variant: MxActionButtonVariant.secondary,
      size: MxActionButtonSize.compact,
      onPressed: onStudy,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final threshold = MediaQuery.textScalerOf(
          context,
        ).scale(AppStudyHomeDeckCard.inlineActionMinWidth);
        if (constraints.maxWidth < threshold) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              workload,
              // One step more than the line breaks above: the seam between
              // what is waiting and what can be done about it (G8).
              const SizedBox(height: AppSpacing.md),
              Align(alignment: AlignmentDirectional.centerStart, child: action),
            ],
          );
        }

        return Row(
          children: <Widget>[
            Expanded(child: workload),
            const SizedBox(width: AppSpacing.md),
            action,
          ],
        );
      },
    );
  }
}

/// What the deck row decides for itself.
abstract final class AppStudyHomeDeckCard {
  /// The narrowest content width at which the counts and the verb share a
  /// band, at `textScaler` 1.0 — scaled by the live text factor before use.
  ///
  /// Chosen from the widths the app actually hands this row, all measured at
  /// the content level this `LayoutBuilder` sees (viewport minus gutters minus
  /// the card's own padding): a 393dp phone gives 329 and the inline
  /// arrangement, a 320dp screen gives 264 (its card is 296 wide) and stacks,
  /// and at text scale 2.0 the scaled threshold (640) stacks on every
  /// supported phone — which is wireframe R1's requirement stated as a number
  /// instead of a hope.
  static const double inlineActionMinWidth = 320;
}
