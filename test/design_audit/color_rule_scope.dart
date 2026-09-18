import 'color_usage_scan.dart';

/// Whether translucency at [site] is a rule R7 violation.
///
/// **One predicate, because two of them disagreed.** `color_source_rules_test.dart`
/// scoped R7 to fills and borders and let alpha through on a label; the audit
/// generator flagged every `opacity-modified-token` outside `shadow` and
/// `scrim`. The same disabled label was therefore conforming to the guard and a
/// V5 in the report at the same time, and the report carried a violation nobody
/// could act on — the fix it proposed was the thing the guard exists to permit.
///
/// The guard's scope is the correct one, and the reason is in the model rather
/// than in convenience: **R7 is about paint whose ground is unknown at build
/// time.** A fill or a border composites against whatever is behind the widget —
/// a card here, a sheet there — so one token renders as several values and none
/// of them was chosen. A label's ground is always the surface it is printed on,
/// which is known; alpha on disabled text is the Material idiom and
/// `--color-on-disabled` states it at 0.38 deliberately. An `overlayColor` must
/// be translucent or the ripple hides what it washes over, and a shadow or a
/// scrim *is* a wash over whatever is underneath.
///
/// `agreement` in `color_system_agreement_test.dart` is what keeps the two
/// callers on this one function.
bool isTranslucentFillViolation(ColorSite site) {
  if (site.sourceKind != 'opacity-modified-token') return false;
  if (site.elementKind != 'border' && site.elementKind != 'background') {
    return false;
  }

  // A shadow and a scrim are washes with no ground to blend against.
  // `elementKind` already separates them; this is belt and braces against a
  // slot being reclassified.
  if (site.file.endsWith('app_elevation.dart')) return false;

  // `border-ghost` (`hairlineEdge` in `app_decorations.dart`) is a
  // translucent EDGE rather than a shadow, and the registry states it that
  // way on purpose (`rgba(82,101,245,.14)` / `rgba(139,154,255,.16)`). The
  // argument is the same one `app_elevation.dart` already gets above: a
  // ground-agnostic token factory in `foundations/` cannot know which surface
  // a component will eventually draw this edge over, so it cannot precompute
  // a solid colour the way R7 asks a fill with a known ground to. R7 has to
  // catch the *consumer* that composites it against a background, not this
  // file.
  return !site.file.endsWith('app_decorations.dart');
}
