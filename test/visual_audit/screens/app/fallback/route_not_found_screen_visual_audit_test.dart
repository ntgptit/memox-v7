@Tags(<String>['golden', 'screen-audit'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:memox/app/fallback/route_not_found_screen.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_content_shell.dart';

import '../../../memox_audit.dart';
import '../../../audit_allowance.dart';
import '../../../audit_model.dart';
import '../../../screen_auditor.dart';

/// Strict visual audit for `RouteNotFoundScreen`.
///
/// Companion of `lib/app/fallback/route_not_found_screen.dart`, at the mirrored
/// path.
///
/// The screen builds without a router in the tree: `context.goNamed` lives
/// inside the retry callback, so it is not evaluated until somebody taps. That
/// is what lets a fallback screen be audited in isolation rather than only
/// through the router that produced it.
void main() {
  memoxProductionScreenAuditTest(
    'route_not_found_screen',
    () => const RouteNotFoundScreen(),
    anchors: <AuditAnchor>[
      AuditAnchor.type('shell', MxContentShell),
      AuditAnchor.type('error_state', MxErrorState),
    ],
    allowances: const <AuditSkipAllowance>[
      // Every allowance below names one node, on one item, with a count. The
      // three are not decoration: `detailContains` stops a future painter from
      // joining silently, `itemId` stops it applying to another part of the
      // screen, and `expectedMatches` fails when the number changes at all.
      //
      // What is being promised: these are all raster-only surfaces whose colour
      // the render tree cannot report (M3.5c). They are covered by the design
      // tokens the widgets read and by `app_theme_test.dart`, and they become
      // measurable when this screen gains a pressed/focused state audit in M5.
      AuditSkipAllowance(
        itemId: 'screen',
        reason: SkipReason.rasterOnly,
        detailContains: '_RenderColoredBox',
        rationale:
            'The page-transition backdrop of this route. '
            '_FadeForwardsPageTransition wraps every opaque route in a '
            'ColoredBox that paints Colors.transparent at rest and '
            'ColorScheme.surface only mid-transition — verified in '
            'page_transitions_theme.dart of the pinned SDK. It is NOT the '
            'Scaffold background, which a Material paints into its own ink '
            'layer; that value is asserted in app_theme_test.dart.',
      ),
      AuditSkipAllowance(
        itemId: 'shell',
        reason: SkipReason.rasterOnly,
        detailContains: '_RenderInkFeatures',
        rationale:
            'The Scaffold Material ink layer. Splash and highlight are painted '
            'onto Material, so no render object carries them.',
      ),
      AuditSkipAllowance(
        itemId: 'error_state',
        reason: SkipReason.rasterOnly,
        detailContains: '_RenderInkFeatures',
        rationale:
            'The Go home button ink layer. Its overlayColor is asserted in '
            'app_theme_test.dart; the pressed state itself is audited in M5.',
      ),
      AuditSkipAllowance(
        itemId: 'error_state',
        reason: SkipReason.customPainter,
        detailContains: '_ShapeBorderPainter',
        rationale:
            'The OutlinedButton border is drawn by a CustomPainter and is not '
            'readable from the render tree (M3.5c). Its colour is asserted from '
            'ThemeData in app_theme_test.dart.',
      ),
    ],
  );
}
