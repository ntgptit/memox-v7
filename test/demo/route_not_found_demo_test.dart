@Tags(<String>['golden', 'review'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/app/config/env_config.dart';
import 'package:memox/app/config/env_config_provider.dart';
import 'package:memox/core/time/clock_provider.dart';

import '../support/study_render.dart';
import '../visual_audit/deck_audit_harness.dart';

/// Device-faithful renders of the 404 fallback — the one production screen that
/// no route points at, and the last of the un-photographed four.
///
/// `RouteNotFoundScreen` is built by the router's `errorBuilder`, so the only
/// honest way to see it is to ask the production route table for a location
/// that matches nothing. Pumping the widget directly — which is what
/// `route_not_found_screen_visual_audit_test.dart` does, deliberately, to audit
/// it in isolation — cannot answer the question a picture is for: whether the
/// user who mistypes a deep link lands on a bare screen with no bottom bar. The
/// error route is built on the **root** navigator, above `StatefulShellRoute`,
/// so they do; that absence is the finding, and it is only visible through the
/// router.
void main() {
  /// The scope is here for the frame, not for the screen.
  ///
  /// `RouteNotFoundScreen` reads no provider at all: it composes
  /// `MxContentShell` and `MxErrorState`, and its only router call
  /// (`context.goNamed`) lives inside the retry callback, so nothing is
  /// evaluated until somebody taps. What needs pinning is the *router*, whose
  /// `redirect` reaches for `ProviderScope.containerOf` on the deck routes —
  /// unreached from a location that matches nothing, but one route table
  /// change away from being reached. The clock and the environment are fixed
  /// for the same reason every review render fixes them: the PNG must be
  /// byte-identical run to run.
  Widget scope(Brightness brightness) => ProviderScope(
    overrides: [
      envConfigProvider.overrideWithValue(EnvConfig.development),
      clockProvider.overrideWithValue(() => DateTime.utc(2026, 7, 29, 12)),
    ],
    child: ReviewApp(
      // A location no branch, no child route and no pattern claims. Not a
      // constant in `route_paths.dart` on purpose — the moment a path like
      // this were declared it would stop being unroutable.
      home: deckRouterAt('/no-such-place'),
      brightness: brightness,
    ),
  );

  testWidgets('route not found — the 404 fallback, light', (tester) async {
    await pumpReview(tester, scope(Brightness.light));

    await matchesReviewGolden('goldens/route_not_found_light.png');
  });

  testWidgets('route not found — the 404 fallback, dark', (tester) async {
    await pumpReview(tester, scope(Brightness.dark));

    await matchesReviewGolden('goldens/route_not_found_dark.png');
  });
}
