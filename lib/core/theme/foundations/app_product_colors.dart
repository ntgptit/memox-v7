import 'package:flutter/material.dart';

/// MemoX product semantics Material has no honest role for — the v3 registry's
/// `MEMOX_SEMANTIC_COLOR` entries whose runtime disposition is `BIND_NOW`
/// (docs/superpowers/specs/2026-09-18-memox-v3-theme-prerequisite.md §5.1).
/// `AppSemanticColors` carries them into the theme.
///
/// **Two semantics may share an authored value and still be two semantics.**
/// `statusReviewing` equals `primary` and `statusMastered` equals `mastery`
/// today; each is its own literal, so moving one never moves the other.
///
/// **The PRESERVE_ONLY entries have no constant here on purpose** — `success`,
/// `warning`, `on-warning`, `streak`, `on-streak`, `mastery-fixed`,
/// `on-danger`, `text-muted`. No v3 consumer paints them, and a colour with no
/// caller is a colour nobody checks.
abstract final class AppProductColors {
  /// `mastery` — the accent StudyTopBar is handed in Recall and Fill sessions.
  static const Color masteryLight = Color(0xFF1F8A5B);
  static const Color masteryDark = Color(0xFF6FE0BD);

  /// `status-new` — a card never studied. StatusBadge dot, label and 12% tint.
  static const Color statusNewLight = Color(0xFF8C95B8);
  static const Color statusNewDark = Color(0xFF6B75A3);

  /// `status-learning` — StatusBadge, and MasteryRamp's fill below 34%.
  static const Color statusLearningLight = Color(0xFFF59E0B);
  static const Color statusLearningDark = Color(0xFFFFC658);

  /// `status-reviewing` — StatusBadge, and MasteryRamp's fill from 34% to 66%.
  static const Color statusReviewingLight = Color(0xFF5265F5);
  static const Color statusReviewingDark = Color(0xFF8B9AFF);

  /// `status-mastered` — StatusBadge, and MasteryRamp's fill from 67%.
  static const Color statusMasteredLight = Color(0xFF1F8A5B);
  static const Color statusMasteredDark = Color(0xFF6FE0BD);

  /// `error-fill` — the destructive button's solid fill. Not `error`: dark's
  /// fill is `#B0485C`, where `error` is `#FF8FA3`.
  static const Color errorFillLight = Color(0xFFDC2D4E);
  static const Color errorFillDark = Color(0xFFB0485C);

  /// `on-error-fill` — label and glyph on the fill above. Equal in both themes
  /// without being declared invariant: only `inverseSurface` and
  /// `onInverseSurface` carry that flag.
  static const Color onErrorFillLight = Color(0xFFFFFFFF);
  static const Color onErrorFillDark = Color(0xFFFFFFFF);
}
