import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/navigation/route_names.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_action_button.dart';
import '../overlays/card_confirm_widget.dart';
import '../support/card_undo_widget.dart';

/// The editor's delete action: the one destructive thing a card offers
/// (UC-04 A2).
///
/// Split out of `card_editor_screen.dart` at the 400-line guard, and the seam
/// is a real one — the screen owns the form, this owns the one action that
/// ends the screen and decides where the user lands afterwards.
///
/// **It was `CardDangerZoneWidget`, and it was a heading plus a filled red
/// button.** Both halves said the same thing twice and neither of them was
/// weight: `Danger zone` is the vocabulary of a settings page's last section,
/// and a filled `error` button is the loudest control the app can draw — the
/// same loudness as the `Save changes` this screen actually wants pressed. The
/// heading existed to explain a hierarchy the button was contradicting. Now
/// the button carries it alone, outlined
/// ([MxActionButtonVariant.destructiveSecondary]), and there is nothing left
/// for a heading to say.
///
/// What did **not** change: the confirmation, the soft delete, the Undo window
/// (BR-256) and where a deleted card leaves you. A visual demotion that also
/// quietly made deletion easier would be the worst possible trade.
class CardDeleteActionWidget extends ConsumerWidget {
  const CardDeleteActionWidget({
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

  /// Leaves a deleted card through the **deck**, not by popping to the card
  /// list — deleting the last card puts the deck back to `unset` (BR-163), and
  /// an `unset` deck has no card list. The router decides which screen that
  /// means: `_cardDeckRedirect` sends a deck that still holds cards back to
  /// the list, and leaves an `unset` one on the deck. `goNamed`, not `pop`:
  /// the editor is reached by deep link as often as by a tap, and popping a
  /// one-entry stack leaves nowhere to land.
  void _leaveDeletedCard(BuildContext context) => context.goNamed(
    RouteNames.deckDetail,
    pathParameters: <String, String>{RoutePathParams.deckId: deckId},
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MxActionButton(
      label: context.l10n.cardEditorDelete,
      variant: MxActionButtonVariant.destructiveSecondary,
      onPressed: isDisabled
          ? null
          : () => showCardDeleteConfirm(
              context,
              cardId: cardId,
              onDeleted: (batchId) {
                _leaveDeletedCard(context);
                showCardMovedToTrash(context, ref, batchId: batchId);
              },
            ),
    );
  }
}
