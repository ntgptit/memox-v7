import 'package:flutter/material.dart';

import '../../foundations/app_elevation.dart';
import '../../foundations/app_radius.dart';
import '../../foundations/app_semantic_colors.dart';
import '../../foundations/app_spacing.dart';

/// The overflow menu — `PopupMenuButton`, on four call sites: the card list's
/// import/export menu, the bulk-action bar, a tag row and the sort control.
///
/// **Found by `theme_coverage_test.dart` rather than by reading the code, and
/// that is the point of that test.** Two hand greps missed all four, because
/// every one is written `PopupMenuButton<CardListSort>(` and a name-then-paren
/// search does not match a generic call. Until this landed, four menus rendered
/// on `surfaceContainer` with a Material shadow and a 4px corner while every
/// other surface in the app sat on `surface` at `elevation: 0` with a hairline.
///
/// **The first pass then over-corrected**, giving the menu the dialog's paper
/// on the reasoning that a menu is a small sheet. A sheet has a scrim behind
/// it; a menu does not, so the two are only alike until you ask what separates
/// them from what is underneath. See the comments on `color` and `elevation`
/// for the measurement that settled it.
///
/// `AppRadius.md` rather than M3's 4: this app's corner scale starts at 8 and a
/// 4px menu beside a 12px button reads as a different kit.
PopupMenuThemeData buildPopupMenuTheme(
  ColorScheme scheme,
  AppSemanticColors semantic,
  TextTheme texts,
) => PopupMenuThemeData(
  // **A menu opens *over* a card, so it cannot be made of the same paper.**
  // On `surface` at `elevation: 0` it lifted off the card beneath it by
  // **0.00 L\*** in both modes — not a faint step, the same plane — with a
  // hairline at 1.46:1 as the only thing saying a second layer had appeared.
  // A dialog gets away with `surface` because a 48–72% scrim separates it;
  // a menu has no scrim.
  //
  // The old comment here cited AD-14 for "one depth mechanism". **AD-14 says
  // the opposite** — depth is a measurable target and each mode builds it from
  // what it has — and it was written because two doc comments had already been
  // read as a ban on elevation. This one had become the third.
  color: scheme.surfaceContainer,
  surfaceTintColor: Colors.transparent,
  // **Solved against AD-14's own floor: a card lifts off its page by 7.75 L\*,
  // so a menu must clear at least that off the card.** Dark gets 13.73 L\* from
  // the paper alone and paints nothing. Light's ladder is compressed near white
  // — `surfaceElevated` over `surface` is worth **0.32 L\*** — so the shadow
  // carries it: `card` (α 0.07) reaches only 6.13 and misses, `raised` (α 0.09)
  // reaches **7.81**, `overlay` overshoots to 12.03 and is anyway defined as
  // the level for a sheet across the whole screen, which a menu is not.
  elevation: AppElevation.raised,
  shadowColor: materialShadowColor(scheme),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(AppRadius.md),
    side: BorderSide(color: scheme.outlineVariant),
  ),
  labelTextStyle: WidgetStateProperty.resolveWith((states) {
    final base = texts.bodyMedium;
    if (states.contains(WidgetState.disabled)) {
      return base?.copyWith(color: semantic.onDisabled);
    }

    return base?.copyWith(color: scheme.onSurface);
  }),
  // The menu is a list of destinations, so its rows wash like rows rather than
  // like controls — the same weight `MxListTile` resolves.
  menuPadding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
);
