import 'package:flutter/material.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../domain/models/card_list_item_model.dart';
import '../support/card_state_widget.dart';

/// One card in the management list: a state dot, front over back with a state
/// label, and — when set — a flag (D5, W1 §4.3).
///
/// **The state dot leads the row and the label sits under the back line**, so a
/// vertical scan reads the column of dots for the deck's distribution while the
/// word names each card's state for anyone who cannot rely on colour. The due
/// badge on the right is the next slice; the row is built to grow it into the
/// trailing slot without moving what is here.
///
/// `InkWell` with [onTap] rather than an `MxListTile`: a card is two lines of the
/// user's own text at different weights, which a list tile's title/subtitle pair
/// would flatten. Tapping opens the editor — wired by the caller, so the tile
/// stays ignorant of the router (AD-13).
const double _flagIconSize = 18;

/// The state dot's diameter — small, because colour and position carry it, not
/// size.
const double _stateDotSize = 10;

class CardTileWidget extends StatelessWidget {
  const CardTileWidget({required this.item, required this.onTap, super.key});

  final CardListItemModel item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final card = item.card;
    final stateLabel = context.cardStateLabel(item.state);

    return Semantics(
      button: true,
      // Front, back and state, joined for the reader so the row is announced as
      // one card. Through the ARB so the joins are a translator's decision.
      label: context.l10n.cardTileSemantics(card.front, card.back),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // The dot sits on the front line's baseline band, not the top, so
              // it reads as belonging to the card rather than floating above it.
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Semantics(
                  label: context.l10n.cardStateDotSemantics(stateLabel),
                  child: Container(
                    width: _stateDotSize,
                    height: _stateDotSize,
                    decoration: BoxDecoration(
                      color: context.cardStateColor(item.state),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
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
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      stateLabel,
                      style: context.texts.labelSmall?.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              // The flag indicator, read-only here — the editor owns the toggle
              // (BR-92). Present only when set, so an unflagged row carries no
              // decoration and the flagged ones stand out in a vertical scan.
              if (card.isFlagged) ...<Widget>[
                const SizedBox(width: AppSpacing.sm),
                Icon(
                  Icons.flag,
                  size: _flagIconSize,
                  // `onSurface`, not `primary`: the accent measures 3.29:1 as a
                  // glyph on the dark surface — below the 4.5:1 the icon needs as
                  // painted text. The flag reads by its shape and position; the
                  // colour only has to stay legible (BR-92).
                  color: context.colors.onSurface,
                  semanticLabel: context.l10n.cardTileFlaggedSemantics,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
