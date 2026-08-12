import 'package:flutter/material.dart';

import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';

/// The overdue day count as a compact chip: `+7d`, capped at `99+` (BR-161).
///
/// The chip rides the tile's status well. The hero states the same age in
/// words instead — `Overdue (+7d)` — because a chip beside one metric of a
/// grid gives that cell a different width and the columns stop aligning; the
/// cap threshold is shared via [capAt] so the two forms agree on when the
/// exact figure stops being worth printing.
///
/// Solid `error` with `onError` text: the badge belongs to the overdue state,
/// so it wears the same red family as the well it accompanies — a saturated
/// fill that stays legible over both the pale container and the card surface
/// (5.76:1 light / 6.8:1 dark). Past 99 the exact figure is noise at this size
/// and the cap says what matters — a long backlog.
///
/// **Visual shorthand only.** `+7d` is for eyes; every caller must put the
/// full `deckOverdueSemanticLabel` sentence on its own `Semantics` node and
/// exclude this chip, so a screen reader never hears the abbreviation.
class DeckOverdueBadgeWidget extends StatelessWidget {
  const DeckOverdueBadgeWidget({required this.days, super.key});

  final int days;

  /// Where the exact figure stops being readable at badge size. Public so
  /// the hero's parenthetical form caps at the same day.
  static const int capAt = 100;

  @override
  Widget build(BuildContext context) {
    final label = days >= capAt
        ? context.l10n.deckOverdueBadgeCapLabel
        : context.l10n.deckOverdueBadgeLabel(days);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colors.error,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
        child: Text(
          label,
          style: context.texts.labelSmall?.copyWith(
            color: context.colors.onError,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
        ),
      ),
    );
  }
}
