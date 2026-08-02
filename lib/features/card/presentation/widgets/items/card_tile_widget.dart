import 'package:flutter/material.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../domain/entities/card_entity.dart';

/// One card in the management list — front over back.
///
/// **Front and back, and not yet the state chip or the due badge.** Those read
/// the card's review state, which is a second read this list slice does not make
/// yet; the tile is built to grow a trailing column and a status line without
/// moving the two lines that are here, so the next slice adds rather than
/// reshapes. The wireframe's four-part row (W1 §4.3) is the target.
///
/// `MxCard` with [onTap] rather than an `MxListTile`: a card is two lines of the
/// user's own text at different weights, which a list tile's title/subtitle pair
/// would flatten. Tapping opens the editor — wired by the caller, so the tile
/// stays ignorant of the router (AD-13).
class CardTileWidget extends StatelessWidget {
  const CardTileWidget({required this.card, required this.onTap, super.key});

  final CardEntity card;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      // Front then back, joined for the reader so the pair is announced as one
      // card rather than two unrelated lines. Through the ARB so the join — the
      // pause between the two — is a translator's decision, not a `. ` literal.
      label: context.l10n.cardTileSemantics(card.front, card.back),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                card.front,
                style: context.texts.titleSmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                card.back,
                style: context.texts.bodySmall?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
