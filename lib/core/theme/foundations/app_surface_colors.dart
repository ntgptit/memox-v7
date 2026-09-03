import 'package:flutter/material.dart';

/// Every surface the app paints, as one family.
///
/// **`page` and `paper`, renamed from `background` and `surface` at M100.32.**
/// The old names encoded M3's model upside down: the app called the card
/// `surface` and kept the page in a token outside `ColorScheme`, so
/// `ColorScheme.surface` meant paper and every component that wanted the page
/// had to be handed a colour. `surface` is the page again — the base ground M3
/// defines — and `AppMaterialRoles.surfaceContainerLow` carries the paper,
/// which is the rung `_CardDefaultsM3` and `_BottomSheetDefaultsM3` both name.
/// No rendered colour moved; the names and the roles did.
///
/// **Split out of `AppColors` at M100.1**, which had grown to 513 lines against
/// the guard's 400 — the same debt `AppMaterialRoles` was carved off to repay at
/// M99.5, incurred again by M99.94…M100.0 adding four surface and border tokens
/// with the measurements that justify each. The measurements are the reason the
/// comments are long, and they are worth more than the line count; what was
/// wrong was keeping six roles in one file, not writing down why a colour is
/// what it is.
///
/// Nothing changed value in that move. M100.26 then moved every value: the
/// page is Tokyo's (`#F2F5F9` / `#070C27`), the light card is Tokyo's paper
/// with the trace of brand R9 asks for, the light inset and selected fills are
/// Tokyo's `alpha.black[10]` and `primary.lighter`, and the dark ladder keeps
/// its tones at Tokyo's navy hue (HSL ~231) instead of A2's violet (~245).
///
/// **The palette is Tokyo's since M100.26.** The owner asked for the theme to
/// match `ntgptit/tokyo-react-admin-dashboard`, and every value in this file is
/// now one of three things: a Tokyo literal, a Tokyo primitive flattened over a
/// Tokyo surface (its `alpha.black`/`primary.lighter` idiom, precomputed as
/// AD-14 requires), or the value this file already had re-hued onto a Tokyo
/// key with its tone and chroma kept — so every L\* step and ratio the tests
/// hold survived without a rule moving. Measurements quoted below that predate
/// M100.26 describe the A2 palette and are kept as the record of *why* a token
/// exists; the current numbers are the tests' output.
/// **The page and the card are Tokyo's verbatim (M100.27, kept by M100.28)** —
/// they may be, because no canonical role or ratio depends on their exact hex
/// the way `primary`'s consumers depend on `primary`; AD-14 ranks that order.
/// Light card and raised surface are pure `#FFFFFF` — Tokyo's paper — which
/// MX-VIS-002 R9 now exempts for exactly these four roles, since a tint the
/// owner has ruled out cannot be a rule. The dark card is `#111633`, 4.3 L\*
/// above the page rather than the 6 the ladder used to ask; the missing depth
/// is Tokyo's own cue, the rim in `shadowsFor`, and `app_palette_test.dart`
/// holds the pair at 4 L\* plus a 3:1 rim rather than at 6 alone.
abstract final class AppSurfaceColors {
  ///
  /// Four tiers. Dark climbs L* 3.9 -> 10.2 -> 16.9 -> 24.0 so a card reads as a
  /// card and an inset tile as an inset on the strength of the ladder alone.
  /// Light inverts it — the card is white and the rest sit below — which is the
  /// same ordering of PROMINENCE, built the only way white allows.
  ///
  /// **That the ladder can carry the hierarchy is not the same as a rule against
  /// shadows**, and this comment was read as one for two milestones. The project
  /// owner has since said the app needs real elevation to separate elements; see
  /// `shadowLight`/`shadowDark` and MX-VIS-002 rule R6. Nothing here forbids a
  /// shadow — it only explains why the ladder was built to work without one.

  /// Page background. The one component allowed a strong navy saturation.
  static const Color pageLight = Color(0xFFF2F5F9);

  static const Color pageDark = Color(0xFF070C27);

  /// Card and sheet — the flashcard surface.
  ///
  /// **Pure white, by owner decision at M100.27.** It is Tokyo's card value
  /// verbatim, and the light page (`pageLight`) carries the tint instead — the
  /// paper is the one light neutral the seed-relation rule exempts, and
  /// `color_system_rules_test` exempts it *by role* so the exemption follows
  /// the meaning rather than the hex.
  ///
  /// **Historical, and no longer true of this constant:** from M4.10i until
  /// M100.27 the value was `#FBFBFE`, `seed @ 0.02` over white, on the argument
  /// that a surface the whole app is built on should not be the one neutral
  /// with no relation to the seed. That reasoning was overruled, not forgotten;
  /// the doc said "not pure white" for two milestones after the token became
  /// exactly that.
  static const Color paperLight = Color(0xFFFFFFFF);

  static const Color paperDark = Color(0xFF111633);

  static const Color surfaceEmphasisLight = Color(0xFFF5F6FF);

  /// **Dark keeps the value it has today.** The reference concept is light-only
  /// ("LIGHT · TOKYO PURE"), and the complaint that started this was light: in
  /// dark `#332F58` carries a real violet and already reads as a callout. A dark
  /// value invented without a reference to measure against would be the guess
  /// this whole pass exists to avoid.
  static const Color surfaceEmphasisDark = Color(0xFF2A3159);

  /// The fill a *picked* card wears when its list uses the tint treatment.
  ///
  /// **Selecting something must not dim it** (M99.98). This shipped on
  /// `secondaryContainer` too, so a selected row rendered **darker and duller**
  /// than the unpicked white ones beside it, while the selected filter chip
  /// directly above wore the brand container — two answers to one question,
  /// on one screen. `#EAEBFD` is the reference concept's own pill value:
  /// lighter than the grey it replaces (93.45 against 91.30) and carrying
  /// nearly three times its chroma.
  ///
  /// The *edge* stays `secondary`: its 2.90:1 measurement is about a line on
  /// `surface`, which the fill never had a stake in.
  static const Color surfaceSelectedLight = Color(0xFFE6E9FF);

  /// Unchanged in dark, for the reason [surfaceEmphasisDark] is.
  static const Color surfaceSelectedDark = Color(0xFF2A3159);

  static const Color surfaceMutedLight = Color(0xFFE9EBEE);

  static const Color surfaceMutedDark = Color(0xFF21274C);

  /// Top of the ladder: a raised or selected surface.
  ///
  /// `seed @ 0.015` over white — one step lighter than [surfaceLight] and still
  /// carrying the hue. Both were `#FFFFFF` before M4.10i, which made the top two
  /// rungs of the light ladder the same rung.
  // `AppMaterialRoles.surfaceContainerLowestLight` and `surfaceBrightLight`
  // are this value under Material's names, derived there.
  static const Color surfaceElevatedLight = Color(0xFFFFFFFF);

  static const Color surfaceElevatedDark = Color(0xFF2F3660);
}
