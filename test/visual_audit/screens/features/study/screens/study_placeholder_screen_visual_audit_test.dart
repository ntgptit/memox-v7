@Tags(<String>['golden', 'screen-audit'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/study/presentation/screens/study_placeholder_screen.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_content_shell.dart';

import '../../../../memox_audit.dart';
import '../../../../audit_allowance.dart';
import '../../../../audit_model.dart';
import '../../../../screen_auditor.dart';

/// Strict visual audit for `StudyPlaceholderScreen`.
///
/// Companion of `lib/features/study/presentation/screens/study_placeholder_screen.dart`,
/// at the mirrored path. `MX-VIS-001` checks that this file exists, imports that
/// screen, and calls the strict helper — a file that merely sits at the right
/// path proves nothing.
///
/// The bar is `complete`: every node either measured or covered by a scoped
/// allowance with a reason. PASS_WITH_UNRESOLVED fails.
void main() {
  memoxProductionScreenAuditTest(
    'study_placeholder_screen',
    () => const StudyPlaceholderScreen(),
    anchors: <AuditAnchor>[
      AuditAnchor.type('shell', MxContentShell),
      AuditAnchor.type('empty_state', MxEmptyState),
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
        expectedMatches: 2,
        rationale:
            'The Material ink layers of the Scaffold and its AppBar. Splash and '
            'highlight are painted onto Material, so no render object carries '
            'them; the overlayColor they use is asserted in app_theme_test.dart.',
      ),
    ],
  );
}
