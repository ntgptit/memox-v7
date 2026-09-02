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

  /// The page. `background` and `surface` are the same colour on purpose —
  /// M3 collapsed the two and this app followed at M100.26, so the pair below
  /// is one value written twice rather than a ladder with a rung nobody names.
  ///
  /// **Dark is the project owner's Tokyo Nebula page, verbatim.** `#0A0E27`
  /// and the card's `#131A3A` are the two anchors the whole dark ladder is
  /// built from; everything else on it is derived at their shared OKLCH hue
  /// (272.3 degrees) and chroma (0.057). What made this necessary is that the
  /// A4 table's dark surfaces were M3's *neutral* palette — `#141317` is
  /// R20 G19 B23, a warm grey at chroma 0.008 — and a grey ramp cannot produce
  /// a navy interface no matter which rung a component reads. Seven times the
  /// chroma is a different colour language, not a tuning difference.
  static const Color backgroundLight = Color(0xFFF7F9FF);

  static const Color backgroundDark = Color(0xFF0A0E27);

  /// The page again, under the role Material actually reads.
  ///
  /// **This used to be the card and is not any more.** Until M100.26 the app
  /// kept `background` below `surface` and drew cards on `surface`; M3 puts the
  /// page on `surface` and the card on `surfaceContainerLow`
  /// (`_CardDefaultsM3.color`). Anything still describing `surface` as "the
  /// flashcard surface" is describing the old model.
  static const Color surfaceLight = Color(0xFFF7F9FF);

  static const Color surfaceDark = Color(0xFF0A0E27);

  static const Color surfaceEmphasisLight = Color(0xFFF1F3FC);

  /// **Dark keeps the value it has today.** The reference concept is light-only
  /// ("LIGHT · TOKYO PURE"), and the complaint that started this was light: in
  /// dark `#332F58` carries a real violet and already reads as a callout. A dark
  /// value invented without a reference to measure against would be the guess
  /// this whole pass exists to avoid.
  static const Color surfaceEmphasisDark = Color(0xFF131A3A);

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
  static const Color surfaceSelectedLight = Color(0xFFD4DBFF);

  /// Unchanged in dark, for the reason [surfaceEmphasisDark] is.
  static const Color surfaceSelectedDark = Color(0xFF3F446B);

  static const Color surfaceMutedLight = Color(0xFFE5E8F1);

  static const Color surfaceMutedDark = Color(0xFF28304F);

  /// Top of the ladder: a raised or selected surface.
  ///
  /// `seed @ 0.015` over white — one step lighter than [surfaceLight] and still
  /// carrying the hue. Both were `#FFFFFF` before M4.10i, which made the top two
  /// rungs of the light ladder the same rung.
  // `AppMaterialRoles.surfaceContainerLowestLight` and `surfaceBrightLight`
  // are this value under Material's names, derived there.
  static const Color surfaceElevatedLight = Color(0xFFFFFFFF);

  static const Color surfaceElevatedDark = Color(0xFF3D4667);
}
