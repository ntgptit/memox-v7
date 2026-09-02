import 'package:flutter/material.dart';

/// Every surface the app paints, as one family.
///
/// **Split out of `AppColors` at M100.1**, which had grown to 513 lines against
/// the guard's 400 — the same debt `AppMaterialRoles` was carved off to repay at
/// M99.5, incurred again by M99.94…M100.0 adding four surface and border tokens
/// with the measurements that justify each. The measurements are the reason the
/// comments are long, and they are worth more than the line count; what was
/// wrong was keeping six roles in one file, not writing down why a colour is
/// what it is.
///
/// Nothing here changed value. This file is a move.
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
  static const Color backgroundLight = Color(0xFFF7F9FE);

  static const Color backgroundDark = Color(0xFF0A0E27);

  /// Card and sheet — the flashcard surface.
  ///
  /// **Not pure white, since M4.10i.** `#FFFFFF` carries no hue at all, so the
  /// one surface the whole app is built on had no relation to the seed while
  /// every other neutral did — the audit's largest finding, and the reason light
  /// mode read as a different palette from dark. `#FBFBFE` is `seed @ 0.02` over
  /// white: hue 240, chroma 0.012, nowhere near the light canvas's tint budget.
  ///
  /// It costs lightness. A tinted card is a *darker* card, so the surface step
  /// drops from 3.46 L\* to 2.15 — which was the argument for leaving it alone
  /// while the step was the only depth cue light had. It is not any more: the
  /// shadow's alpha was re-solved to 0.07 and the total lift is 8.04 L\* against
  /// dark's 6.58.
  static const Color surfaceLight = Color(0xFFF7F9FE);

  static const Color surfaceDark = Color(0xFF0A0E27);

  static const Color surfaceEmphasisLight = Color(0xFFF1F4FB);

  /// **Dark keeps the value it has today.** The reference concept is light-only
  /// ("LIGHT · TOKYO PURE"), and the complaint that started this was light: in
  /// dark `#332F58` carries a real violet and already reads as a callout. A dark
  /// value invented without a reference to measure against would be the guess
  /// this whole pass exists to avoid.
  static const Color surfaceEmphasisDark = Color(0xFF1B2249);

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
  static const Color surfaceSelectedLight = Color(0xFFE3E7FA);

  /// Unchanged in dark, for the reason [surfaceEmphasisDark] is.
  static const Color surfaceSelectedDark = Color(0xFF333C6B);

  static const Color surfaceMutedLight = Color(0xFFE2E7F3);

  static const Color surfaceMutedDark = Color(0xFF2C356E);

  /// Top of the ladder: a raised or selected surface.
  ///
  /// `seed @ 0.015` over white — one step lighter than [surfaceLight] and still
  /// carrying the hue. Both were `#FFFFFF` before M4.10i, which made the top two
  /// rungs of the light ladder the same rung.
  // `AppMaterialRoles.surfaceContainerLowestLight` and `surfaceBrightLight`
  // are this value under Material's names, derived there.
  static const Color surfaceElevatedLight = Color(0xFFFFFFFF);

  static const Color surfaceElevatedDark = Color(0xFF353D7E);
}
