import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/navigation/route_names.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_action_button.dart';
import '../overlays/card_confirm_widget.dart';
import '../support/card_undo_widget.dart';

/// The editor's delete band: the one destructive action on a card (UC-04 A2).
///
/// Split out of `card_editor_screen.dart` at the 400-line guard, and the seam
/// is a real one — the screen owns the form, this owns the one action that
/// ends the screen and decides where the user lands afterwards.
///
/// **A rule and a quiet button, not a heading and a red block** (owner review,
/// 2026-08-26). Two things were wrong with the first version:
///
/// * *"Danger zone" is a settings-page convention from the web*, where it
///   fences off a group of irreversible operations under one heading. There is
///   one action here, and a heading over a single button names a section that
///   does not exist. The [Divider] does the whole job the heading was doing —
///   saying that what follows is not part of the form above it.
/// * *A full-width `error` fill directly under a full-width primary* made the
///   two actions the same weight, differing only in hue, and put the loudest
///   block on the screen under the least frequent action. The outlined variant
///   keeps the red — it still has to read as destructive — and drops the mass.
///   The delete is still confirmed before anything happens, so the quieter
///   affordance costs no safety.
class CardDangerZoneWidget extends ConsumerWidget {
  const CardDangerZoneWidget({
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Divider(color: context.semanticColors.borderSubtle),
        const SizedBox(height: AppSpacing.md),
        MxActionButton(
          label: context.l10n.cardEditorDelete,
          variant: MxActionButtonVariant.destructiveOutlined,
          icon: Icons.delete_outline,
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
        ),
      ],
    );
  }
}
