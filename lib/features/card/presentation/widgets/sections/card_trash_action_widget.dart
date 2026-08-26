import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/navigation/route_names.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_action_button.dart';
import '../../../../../shared/widgets/mx_card.dart';
import '../overlays/card_confirm_widget.dart';
import '../support/card_undo_widget.dart';

/// The editor's soft-delete: a card that explains where the flashcard goes, and
/// a button that starts it (UC-04 A2, BR-256).
///
/// **It was `CardDangerZoneWidget`, and three things about that were wrong.**
///
/// The heading said `Danger zone` — the vocabulary of a settings page's last
/// section, a technical label standing in for a sentence about what happens.
/// The button was a filled `error` fill, which is the loudest control the app
/// can draw and exactly the weight of the `Save changes` this screen actually
/// wants pressed. And the copy said the review history is removed, which is
/// **false**: BR-256 keeps the card, its study state and its history in Trash
/// until the user empties it.
///
/// **Neutral secondary, not destructive, and that is BR-266 rather than
/// taste.** The destructive role belongs to permanent purge. Spending it on a
/// reversible move means that when the user later meets the one action that
/// cannot be undone, the colour has nothing left to say.
///
/// The confirmation, the batch id, the Undo window and where a moved card
/// leaves you are all unchanged — a visual demotion that also quietly made
/// deletion easier would be the worst possible trade.
class CardTrashActionWidget extends ConsumerWidget {
  const CardTrashActionWidget({
    required this.deckId,
    required this.cardId,
    required this.isDisabled,
    super.key,
  });

  final String deckId;
  final String cardId;

  /// True while a save is in flight: two writes racing on one card is not a
  /// state the confirmation should be able to create.
  final bool isDisabled;

  /// Leaves a moved card through the **deck**, not by popping to the card
  /// list — moving the last card puts the deck back to `unset` (BR-163), and
  /// an `unset` deck has no card list. The router decides which screen that
  /// means: `_cardDeckRedirect` sends a deck that still holds cards back to
  /// the list, and leaves an `unset` one on the deck. `goNamed`, not `pop`:
  /// the editor is reached by deep link as often as by a tap, and popping a
  /// one-entry stack leaves nowhere to land.
  void _leaveMovedCard(BuildContext context) => context.goNamed(
    RouteNames.deckDetail,
    pathParameters: <String, String>{RoutePathParams.deckId: deckId},
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MxCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            context.l10n.cardEditorTrashTitle,
            style: context.texts.titleSmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            context.l10n.cardEditorTrashDescription,
            style: context.texts.bodySmall?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          // **Sized to its label, not stretched.** The column is `stretch`, so
          // the button came out 326dp — full bleed across the card, which reads
          // as the section's primary action. The concept draws it about 41% of
          // the card, deliberately smaller than the Save it shares a screen
          // with. `Align` opts this one child out of the column's stretch.
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: MxActionButton(
              label: context.l10n.cardEditorTrashAction,
              icon: Icons.delete_outline,
              variant: MxActionButtonVariant.secondary,
              onPressed: isDisabled
                  ? null
                  : () => showCardDeleteConfirm(
                      context,
                      cardId: cardId,
                      onDeleted: (batchId) {
                        _leaveMovedCard(context);
                        showCardMovedToTrash(context, ref, batchId: batchId);
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
