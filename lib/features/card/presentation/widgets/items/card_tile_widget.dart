import 'package:flutter/material.dart';

import '../../../../../core/theme/app_ink.dart';
import '../../../../../core/theme/app_elevation.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_card.dart';
import '../../../domain/models/card_due_badge_model.dart';
import '../../../domain/models/card_list_item_model.dart';
import '../support/card_due_badge_widget.dart';
import '../support/card_state_widget.dart';
import '../support/card_tag_chip_widget.dart';

/// One card in the management list: a state dot, front over back with a state
/// label and tag chips, and — when set — a flag over a due badge (D5, W1 §4.3).
///
/// **Built on `MxCard`, like the deck row.** Each card is its own bordered
/// surface with a gap to the next, not a flat row split by a hairline — the same
/// shape `deck_tile_widget.dart` uses, so the two lists read alike. The whole card
/// is the tap target (`MxCard` owns the ink); the build stays short by composing
/// [_StateDot], [_CardFace] and [_TrailingBadges], one per column.
///
/// **Colour follows the deck's rule, not the row's mock.** The dot carries the
/// state colour (a non-text mark clears the 3:1 bar); the label stays neutral
/// (`onSurfaceVariant` clears 4.5:1 as text where the state hues do not on both
/// themes). Tags and the due badge are quiet filled pills — the deck's chip
/// language — rather than the colour-per-state the reference draws.
const double _flagIconSize = 18;

/// The state dot's diameter — small, because colour and position carry it, not
/// size.
const double _stateDotSize = 10;

class CardTileWidget extends StatelessWidget {
  const CardTileWidget({
    required this.item,
    required this.now,
    required this.onTap,
    this.onLongPress,
    this.isSelectionMode = false,
    this.isSelected = false,
    super.key,
  });

  final CardListItemModel item;

  /// The instant the due badge is measured against, from `cardListNowProvider`
  /// at the composition root — the tile never reads the wall clock (CLAUDE.md).
  final DateTime now;
  final VoidCallback onTap;

  /// Enters selection mode (UC-04 A6). Null outside the list — the editor's
  /// preview has nothing to select.
  final VoidCallback? onLongPress;

  /// Whether the list is selecting. The row changes what a tap *means*, so it
  /// has to know: outside the mode a tap opens the read-only detail screen (M99.31, UC-19), inside it toggles.
  final bool isSelectionMode;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    // Selection is announced, not just tinted: a screen reader hears the state
    // and a colour-blind reader sees the check, so colour is never the only
    // signal (UC-04 A6).
    return Semantics(
      selected: isSelectionMode ? isSelected : null,
      label: isSelected ? context.l10n.cardSelectedSemanticLabel : null,
      child: MxCard(
        elevation: AppElevation.none,
        onTap: onTap,
        onLongPress: onLongPress,
        // A tinted surface *and* a border, both from tokens. The height does
        // not move between the two states — the check replaces the state dot
        // in the same column rather than being inserted beside it — so a list
        // does not reflow as the user selects.
        color: isSelected ? context.colors.secondaryContainer : null,
        borderColor: isSelected ? context.colors.secondary : null,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            isSelectionMode
                ? _SelectionMark(isSelected: isSelected)
                : _StateDot(item: item),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: _CardFace(item: item)),
            // No gap here — `_TrailingBadges` owns it, because it can render
            // nothing at all.
            _TrailingBadges(item: item, now: now),
          ],
        ),
      ),
    );
  }
}

/// The check that replaces the state dot while selecting.
///
/// **Same column, same footprint.** An indicator inserted beside the dot would
/// shift every row sideways the moment selection starts and back again when it
/// ends; swapping in place keeps the list still. Shape carries the state as
/// much as colour does — a filled check against an empty circle.
class _SelectionMark extends StatelessWidget {
  const _SelectionMark({required this.isSelected});

  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _stateDotSize,
      height: _stateDotSize,
      child: FittedBox(
        child: Icon(
          isSelected ? Icons.check_circle : Icons.circle_outlined,
          color: isSelected
              ? context.colors.secondary
              : context.colors.onSurfaceVariant,
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
          // titleMedium, not titleSmall: the front is the word the row is about
          // — the term being learned — so it carries the most visual weight, and
          // the back and the state line step down from it (D5 hierarchy).
          card.front,
          style: context.texts.titleMedium,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          // `onSurface`, a step darker than the state line below it: the meaning
          // is what the learner reads, so it takes the stronger of the two muted
          // tones and the state label keeps the lighter one.
          //
          // bodyMedium, not bodySmall: the back is the second most-read text on
          // the row — the answer being recalled — and at 12 it sat at caption
          // size, two roles below the 16 front. 14 keeps one full step of
          // hierarchy under the front while staying readable when scanning
          // long diacritic-heavy Vietnamese lists.
          card.back,
          style: context.texts.bodyMedium!.inked(context, AppInk.stated),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppSpacing.sm),
        // The state label and the tag chips share the third line: a Wrap so a
        // card with many tags flows onto a second row at a narrow width rather
        // than overflowing (BR-94 caps it at ten).
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            Text(
              // Uppercase **and** in the state's own colour. This became legal
              // when the row turned into a card: measured on the card surface
              // every state clears 4.5:1 — info 5.23/7.84, warning 4.58/8.58,
              // accent 7.27/5.51, success 5.20/8.10 (light/dark) — where on the
              // page ground warning sat at 4.33 and the label had to stay
              // neutral. Colour is still never alone: the dot and the word carry
              // the same fact.
              context.cardStateLabel(item.state).toUpperCase(),
              style: context.textStyles.stateChipLabel.inked(
                context,
                context.cardStateInk(item.state),
              ),
            ),
            for (final tag in item.tagNames) CardTagChipWidget(name: tag),
          ],
        ),
      ],
    );
  }
}

/// The trailing cluster: the flag (when set) and the due badge on **one line**,
/// right-aligned and top-aligned with the front word.
///
/// **Either mark can be absent, so the cluster carries its own leading gap.** A
/// never-scheduled card draws no badge and an unflagged one draws no flag, which
/// leaves rows with nothing to show here at all; a gap owned by the parent `Row`
/// would then sit against the card's edge holding space for nothing, and narrow
/// the front word by 8 for no reason.
class _TrailingBadges extends StatelessWidget {
  const _TrailingBadges({required this.item, required this.now});

  final CardListItemModel item;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    // Null for a card that has never been scheduled — the row's `NEW` label
    // already says so, and the badge used to say `now` beside it.
    final dueLabel = context.dueBadgeLabel(dueBadgeOf(item.dueAt, now));
    // Read-only here — the editor owns the toggle (BR-92). Present only when
    // set, so unflagged rows carry no decoration.
    final marks = <Widget>[
      if (item.card.isFlagged)
        Icon(
          Icons.flag,
          size: _flagIconSize,
          // `onSurface`, not `primary`: the accent measures 3.29:1 as a glyph
          // on the dark surface — below the 4.5:1 an icon needs as painted
          // text. The flag reads by shape; the colour only stays legible.
          color: context.colors.onSurface,
          semanticLabel: context.l10n.cardTileFlaggedSemantics,
        ),
      if (dueLabel != null) _DueBadge(label: dueLabel),
    ];
    if (marks.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.sm),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: AppSpacing.sm,
        children: marks,
      ),
    );
  }
}

/// The due label as a quiet filled pill.
///
/// `surfaceMuted`, not the deck's peach `streakContainer`: on a card row the
/// coloured chip pulled the eye to "when" over the word being learned, and the
/// reference draws this mark neutral. The label measures 5.61:1 light / 6.17:1
/// dark on the muted ground.
class _DueBadge extends StatelessWidget {
  const _DueBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: context.l10n.cardDueBadgeSemantics(label),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: context.semanticColors.surfaceMuted,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Text(
          label,
          style: context.texts.labelSmall!.inked(context, AppInk.quiet),
        ),
      ),
    );
  }
}
