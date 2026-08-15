import 'package:flutter/material.dart';

import '../../../../../core/theme/app_elevation.dart';
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

    // Flat with a hairline, like the deck card: two competing depths in one
    // scrolling column is what makes a list read as busy.
    return MxCard(
      elevation: AppElevation.none,
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
              style: context.texts.bodySmall?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          StudyHomeWorkloadItemWidget(deck: deck),
          // `md` above the verb: the seam between what the deck says and what
          // can be done about it is a section boundary inside the card, so it
          // gets one step more than the line breaks above it.
          const SizedBox(height: AppSpacing.md),
          Align(
            alignment: AlignmentDirectional.centerStart,
            // **The action is renamed, and the button owns the rename.** Every
            // row carries the same word, so a screen reader walking the list
            // would hear "Study" three times with nothing to tell the rows
            // apart; the deck name is what does. Passing it to the button
            // rather than wrapping the button keeps its role, its enabled state
            // and its ink — the wrapper version lost all three.
            child: MxActionButton(
              label: l10n.studyHomeStudyAction,
              semanticLabel: l10n.studyHomeStudySemanticLabel(deck.deckName),
              icon: Icons.play_arrow,
              variant: MxActionButtonVariant.secondary,
              onPressed: onStudy,
            ),
          ),
        ],
      ),
    );
  }
}
