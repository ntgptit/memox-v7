import 'package:flutter/material.dart';

import '../../../../../core/theme/app_button_themes.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/navigation/route_names.dart';
import '../../../../../core/theme/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';

/// The pill height the design draws. The *target* is not this — see below.
const double _kPillHeight = 32;

/// Start studying what is due in one deck.
///
/// **It opens the deck's study entry, at last.** It stood here since M4 showing
/// a "not built yet" snackbar — the project refuses enabled-looking controls
/// that go nowhere, and a button that answers honestly beat one that swallowed
/// the tap. M5.15 needed the path to exist to test it, and it was the last link
/// missing between a deck and a session.
///
/// It navigates by **name**, and to a route nested under the deck: Back returns
/// to the deck the session started from rather than to whatever the Study tab
/// last held.
///
/// **Primary again (owner mockup, 2026-08-20), reversing the tonal revision
/// of 2026-08-05.** The full history is in
/// `docs/reviews/design-parity-checklist.md`: outlined (the kit) lost to
/// filled (owner), filled lost to tonal when a column of `primary` fills
/// sprayed the accent across every row — and the redesign restores primary
/// *because the rest of the card got quieter with it*: the metric chips gave
/// up their containers, the `+Nd` badge is gone, and overdue's danger ink is
/// the only other accent left, so one primary verb per card now reads as the
/// hierarchy instead of competing with it.
///
/// **32 is what it paints; 48 is what a finger gets.** `AppSpacing` calls the
/// touch target a floor, and `MxBreadcrumb` already settled the same conflict
/// the same way — the kit's CSS says 36 there and its usage note says 48, and 48
/// won. `MaterialTapTargetSize.padded` keeps the pill's drawn height at 32 and
/// gives the hit area the floor.
class DeckStudyButtonWidget extends StatelessWidget {
  const DeckStudyButtonWidget({required this.deckId, super.key});

  final String deckId;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: () => context.goNamed(
        RouteNames.deckStudy,
        pathParameters: <String, String>{RoutePathParams.deckId: deckId},
      ),
      // The brand pair comes from the shared builder; only the pill's
      // geometry is stated here.
      style:
          buildFilledStyle(
            context.colors,
            context.semanticColors,
            fill: context.colors.primary,
            label: context.colors.onPrimary,
          ).copyWith(
            minimumSize: const WidgetStatePropertyAll<Size>(
              Size(0, _kPillHeight),
            ),
            padding: const WidgetStatePropertyAll<EdgeInsets>(
              EdgeInsets.symmetric(horizontal: AppSpacing.md),
            ),
            // A card corner, not a pill (owner review, 2026-08-20): the row
            // it sits in is built from rounded rectangles — the gauge, the
            // chips above it, the card itself — and a stadium among them read
            // as a borrowed component.
            shape: WidgetStatePropertyAll<OutlinedBorder>(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
            tapTargetSize: MaterialTapTargetSize.padded,
          ),
      // **The word alone** (owner review, 2026-08-20). The play glyph said
      // nothing the verb did not, and it cost the row width that the gauge
      // beside it needed at large text scales.
      child: Text(
        context.l10n.deckStudyAction,
        // **`onPrimary` stated, not inherited.** `context.texts.labelMedium`
        // carries the theme's body colour, and passing it whole overrode the
        // foreground the button had already resolved — the same kind of
        // override the visual audit once measured at 2.33:1 on the brand
        // fill. A style taken from the text theme has to say its colour when
        // it lands on a coloured surface.
        style: context.texts.labelMedium?.copyWith(
          color: context.colors.onPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
