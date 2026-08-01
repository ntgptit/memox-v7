import 'package:flutter/material.dart';

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
/// **Filled, against the design kit's outlined pill.** The kit argues a column
/// of filled buttons stops the card being calm, which is true and was weighed:
/// the project owner chose emphasis, because Study is the card's primary action
/// and an outlined pill beside a filled due-chip lost to it. Recorded in
/// `docs/reviews/design-parity-checklist.md` as a deliberate divergence.
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
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll<Size>(Size(0, _kPillHeight)),
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
            // **`onPrimary` stated, not inherited.** `context.texts.labelMedium`
            // carries the theme's body colour, and passing it whole overrode the
            // foreground `FilledButton` had already resolved — dark ink on the
            // brand fill, which the visual audit measured at 2.33:1 against a
            // 4.5 floor. A style taken from the text theme has to say its colour
            // when it lands on a coloured surface.
            style: context.texts.labelMedium?.copyWith(
              color: context.colors.onPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
