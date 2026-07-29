@Tags(<String>['golden', 'screen-audit'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/review/presentation/review_placeholder_screen.dart';
import 'package:memox/shared/widgets/app_empty_state_widget.dart';
import 'package:memox/shared/widgets/app_scaffold_widget.dart';

import '../../../memox_audit.dart';
import '../../../audit_allowance.dart';
import '../../../audit_model.dart';
import '../../../screen_auditor.dart';

/// Strict visual audit for `ReviewPlaceholderScreen`.
///
/// Companion of `lib/features/review/presentation/review_placeholder_screen.dart`,
/// at the mirrored path. `MX-VIS-001` checks that this file exists, imports that
/// screen, and calls the strict helper — a file that merely sits at the right
/// path proves nothing.
///
/// The bar is `complete`: every node either measured or covered by a scoped
/// allowance with a reason. PASS_WITH_UNRESOLVED fails.
void main() {
  memoxProductionScreenAuditTest(
    'review_placeholder_screen',
    () => const ReviewPlaceholderScreen(),
    anchors: <AuditAnchor>[
      AuditAnchor.type('shell', AppScaffoldWidget),
      AuditAnchor.type('empty_state', AppEmptyStateWidget),
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
            'Scaffold paints its background through a private ColoredBox. The '
            'value is scaffoldBackgroundColor, asserted in app_theme_test.dart.',
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
