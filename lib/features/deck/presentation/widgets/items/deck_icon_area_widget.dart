import 'package:flutter/material.dart';

import '../../../../../core/theme/foundations/app_sizing.dart';
import '../../../../../shared/widgets/mx_icon.dart';
import '../../../../../core/theme/extensions/app_ink.dart';
import '../../../../../core/theme/foundations/app_radius.dart';
import '../../../../../core/theme/extensions/theme_context_extension.dart';

/// The card's leading glyph, in a neutral well.
///
/// Feature-local rather than shared: it exists to give the deck list a scannable
/// left column, and nothing else in the app has asked for one. Promoting it on the
/// first caller would be guessing at what varies — the second caller is what shows
/// whether the tint, the size or the shape is the part worth parameterising.
///
/// Sized to [AppSizing.touchTarget] even though it is not a target: it is
/// the one square in the row, and reusing the number the row's real controls use
/// keeps the icon, the title and the action optically aligned.
///
/// **The well is `surfaceMuted` — neutral, no brand hue of its own — and the
/// glyph alone carries the colour, as `AppInk.accent`.** Seven recipes were
/// tried, in this order, each replacing the last, all on 2026-09-10:
///
/// 1. `surfaceMuted` fill, `primary` glyph — this same pairing, tried once
///    before on an older palette and shelved on a report reading **2.31:1**
///    in dark against a 3.0 floor. Re-measured on today's tokens rather than
///    trusted from that report: **5.19:1** light, **8.43:1** dark — the
///    palette moved under the old number, and nothing here reads it as still
///    true. `deck_icon_area_test.dart` pins today's figures so the next
///    palette change is caught by a test, not by re-reading an old doc.
/// 2. `primaryContainer` / `onPrimaryContainer` — the M3 container pair,
///    contrast-safe, but read as barely a colour at all: **1.35:1** against
///    the light card face ("nhìn nhạt nhẽo quá").
/// 3. A 25% blend of `primary` into that container — 1.87:1, still not close
///    enough to the brand colour to be *it*.
/// 4. Solid `primary` fill, `onPrimary` glyph — read as the brand colour, but
///    as loud as [DeckStudyButtonWidget]'s own filled state.
/// 5. The same fill eased toward grey in HSL, hue and lightness held — first
///    20%, then 40% ("nổi bật hơn rồi nhưng làm nhạt đi hơn chút bằng độ bão
///    hòa", then "làm cho nhạt bớt nữa").
/// 6. No fill, a `primary` border instead — "nhìn cũng tởm lắm".
/// 7. **This one.** `surfaceMuted`, chosen again from a side-by-side of eight
///    options rather than guessed: the well itself carries no brand meaning,
///    and the glyph is the only accent-coloured mark on the card.
///
/// **Still not [DeckStudyButtonWidget]'s weight.** That button is a filled
/// surface (`secondaryContainer`, tonal, since M100.75); this well has none —
/// one filled control and one neutral-background identity mark stays the
/// hierarchy M99.98 asked this pairing to keep, whichever recipe answers "how
/// do we mark identity."
class DeckIconArea extends StatelessWidget {
  /// The well's square edge — [AppSizing.touchTarget], for the optical
  /// reason above.
  ///
  /// Public because the tile aligns other rows to the column this square
  /// creates: the workload line starts at `dimension + AppSpacing.md`, exactly
  /// where the title does. A copy of the number in the tile would drift the
  /// first time this well is resized.
  static const double dimension = AppSizing.touchTarget;

  const DeckIconArea({
    required this.icon,
    required this.tint,
    this.semanticLabel,
    this.wellColor,
    super.key,
  });

  final IconData icon;
  final AppInk tint;
  final String? semanticLabel;

  /// Null keeps the neutral fill. Pass one only to say the row is in a state
  /// the brand meaning would talk over.
  final Color? wellColor;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: wellColor ?? context.semanticColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: SizedBox.square(
        dimension: dimension,
        child: Center(
          child: MxIcon(icon, ink: tint, semanticLabel: semanticLabel),
        ),
      ),
    );
  }
}
