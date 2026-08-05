import 'package:flutter/material.dart';

import '../../../../../core/theme/app_button_themes.dart';
import '../../../../../core/theme/app_icon_size.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';

/// The pill height the design draws. The *target* is not this — see below.
const double _kPillHeight = 32;

/// Start studying what is due in one deck.
///
/// **It says the feature is not built rather than doing nothing.** The project
/// refuses enabled-looking controls that go nowhere — `DeckNoticeWidget` exists
/// for exactly that reason — and until the review session lands (M5) there is no
/// session to start. A button that answers, even to say "not yet", is a
/// different thing from one that swallows the tap: the layout under review is
/// the real one, and the honesty is in the reply.
///
/// TODO(#89): replace the snackbar with the review session route. The button,
/// its label and the rule that it appears only when something is due are already
/// what M5 needs; only `onPressed` changes.
///
/// **Tonal, revised from filled (owner decision, 2026-08-05).** The history has
/// three steps, each recorded in `docs/reviews/design-parity-checklist.md`:
/// the kit argued *outlined* (a column of filled buttons stops the card being
/// calm), the owner first chose *filled* (Study is the card's primary action
/// and an outlined pill lost to the due chip beside it) — and the measured UI
/// review then showed the cost: with several decks due at once, a column of
/// `primary` fills sprays the screen's accent across every row. Tonal
/// (`secondaryContainer`) keeps the emphasis that beat outlined while leaving
/// `primary` to screen-level actions; the owner approved the revision.
///
/// **32 is what it paints; 48 is what a finger gets.** `AppSpacing` calls the
/// touch target a floor, and `MxBreadcrumb` already settled the same conflict
/// the same way — the kit's CSS says 36 there and its usage note says 48, and 48
/// won. `MaterialTapTargetSize.padded` keeps the pill's drawn height at 32 and
/// gives the hit area the floor.
class DeckStudyButtonWidget extends StatelessWidget {
  const DeckStudyButtonWidget({required this.dueCardCount, super.key});

  final int dueCardCount;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.deckStudyComingSoonMessage)),
      ),
      // The tonal pair comes from the theme's builder (one slot in ThemeData
      // belongs to the brand fill — see `buildFilledTonalStyle`); only the
      // pill's geometry is stated here.
      style: buildFilledTonalStyle(context.colors, context.semanticColors)
          .copyWith(
            minimumSize: const WidgetStatePropertyAll<Size>(
              Size(0, _kPillHeight),
            ),
            padding: const WidgetStatePropertyAll<EdgeInsets>(
              EdgeInsets.symmetric(horizontal: AppSpacing.md),
            ),
            shape: WidgetStatePropertyAll<OutlinedBorder>(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
            tapTargetSize: MaterialTapTargetSize.padded,
          ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: AppSpacing.xs,
        children: <Widget>[
          const Icon(Icons.play_arrow, size: AppIconSize.sm),
          Text(
            context.l10n.deckStudyAction,
            // **`onSecondaryContainer` stated, not inherited.** `context.texts.labelMedium`
            // carries the theme's body colour, and passing it whole overrode the
            // foreground `FilledButton` had already resolved — dark ink on the
            // tinted fill — the same override class the visual audit once
            // measured at 2.33:1 on the brand fill. A style taken from the text theme has to say its colour
            // when it lands on a coloured surface.
            style: context.texts.labelMedium?.copyWith(
              color: context.colors.onSecondaryContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
