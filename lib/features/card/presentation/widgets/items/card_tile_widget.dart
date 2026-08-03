import 'package:flutter/material.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../domain/models/card_due_badge_model.dart';
import '../../../domain/models/card_list_item_model.dart';
import '../support/card_due_badge_widget.dart';
import '../support/card_state_widget.dart';

/// One card in the management list: a state dot, front over back with a state
/// label and tag chips, and — when set — a flag over a due badge (D5, W1 §4.3).
///
/// The build stays short by composing three parts — [_StateDot], [_CardFace],
/// [_TrailingBadges] — each of which owns one column of the row. Tapping opens
/// the editor, wired by the caller so the tile stays ignorant of the router
/// (AD-13).
const double _flagIconSize = 18;

/// The state dot's diameter — small, because colour and position carry it, not
/// size.
const double _stateDotSize = 10;

class CardTileWidget extends StatelessWidget {
  const CardTileWidget({
    required this.item,
    required this.now,
    required this.onTap,
    super.key,
  });

  final CardListItemModel item;

  /// The instant the due badge is measured against, from `cardListNowProvider`
  /// at the composition root — the tile never reads the wall clock (CLAUDE.md).
  final DateTime now;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final card = item.card;

    return Semantics(
      button: true,
      // Front and back, joined for the reader so the row is announced as one
      // card. Through the ARB so the join is a translator's decision.
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
              _StateDot(item: item),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: _CardFace(item: item)),
              const SizedBox(width: AppSpacing.sm),
              _TrailingBadges(item: item, now: now),
            ],
          ),
        ),
      ),
    );
  }
}

/// The leading colour dot for the card's display state (D5).
class _StateDot extends StatelessWidget {
  const _StateDot({required this.item});

  final CardListItemModel item;

  @override
  Widget build(BuildContext context) {
    // Sits on the front line's baseline band, not the top, so it reads as
    // belonging to the card rather than floating above it.
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Semantics(
        label: context.l10n.cardStateDotSemantics(
          context.cardStateLabel(item.state),
        ),
        child: Container(
          width: _stateDotSize,
          height: _stateDotSize,
          decoration: BoxDecoration(
            color: context.cardStateColor(item.state),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

/// The two lines of the user's text, and the state-and-tags line below them.
class _CardFace extends StatelessWidget {
  const _CardFace({required this.item});

  final CardListItemModel item;

  @override
  Widget build(BuildContext context) {
    final card = item.card;

    return Column(
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
        // The state label and the tag chips share the third line: a Wrap so a
        // card with many tags flows onto a second row at a narrow width rather
        // than overflowing (BR-94 caps it at ten).
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            Text(
              context.cardStateLabel(item.state),
              style: context.texts.labelSmall?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
            for (final tag in item.tagNames) _TagChip(name: tag),
          ],
        ),
      ],
    );
  }
}

/// The right column: the flag (when set) over the due badge, both right-aligned
/// so the eye finds "marked" and "when" in one place.
class _TrailingBadges extends StatelessWidget {
  const _TrailingBadges({required this.item, required this.now});

  final CardListItemModel item;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final dueLabel = context.dueBadgeLabel(dueBadgeOf(item.dueAt, now));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // Read-only here — the editor owns the toggle (BR-92). Present only when
        // set, so unflagged rows carry no decoration.
        if (item.card.isFlagged) ...<Widget>[
          Icon(
            Icons.flag,
            size: _flagIconSize,
            // `onSurface`, not `primary`: the accent measures 3.29:1 as a glyph
            // on the dark surface — below the 4.5:1 an icon needs as painted
            // text. The flag reads by shape; the colour only stays legible.
            color: context.colors.onSurface,
            semanticLabel: context.l10n.cardTileFlaggedSemantics,
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
        Semantics(
          label: context.l10n.cardDueBadgeSemantics(dueLabel),
          child: Text(
            dueLabel,
            style: context.texts.labelSmall?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

/// A read-only tag pill on the row (BR-93).
///
/// A hairline border rather than a fill: the label is `onSurfaceVariant` on the
/// card surface, which clears 4.5:1 as text, and a filled chip would put it on a
/// second ground to re-check. The border is non-text — 3:1 is enough — so
/// `borderSubtle` carries the pill shape without a contrast risk.
class _TagChip extends StatelessWidget {
  const _TagChip({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: context.semanticColors.borderSubtle),
        borderRadius: BorderRadius.circular(AppSpacing.sm),
      ),
      child: Text(
        name,
        style: context.texts.labelSmall?.copyWith(
          color: context.colors.onSurfaceVariant,
        ),
      ),
    );
  }
}
