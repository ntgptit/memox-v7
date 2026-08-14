@Tags(<String>['golden', 'screen-audit'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/settings/presentation/screens/settings_placeholder_screen.dart';
import 'package:memox/shared/widgets/mx_content_shell.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_card.dart';

import '../../../../audit_rules.dart';
import '../../../../memox_audit.dart';
import '../../../../audit_allowance.dart';
import '../../../../audit_model.dart';
import '../../../../screen_auditor.dart';

/// Strict visual audit for `SettingsPlaceholderScreen`.
///
/// Companion of
/// `lib/features/settings/presentation/screens/settings_placeholder_screen.dart`,
/// at the mirrored path.
///
/// Presentation-only (AD-19), so it audits in isolation with nothing
/// overridden — see the Progress companion for the shape. It is still
/// presentation-only after M99.23: the daily-reminder row is a link, and the
/// screen it opens belongs to another feature.
void main() {
  memoxProductionScreenAuditTest(
    'settings_placeholder_screen',
    () => const SettingsPlaceholderScreen(),
    // This screen declares one surface column (M99.19a): every row of
    // cards spans it, or stacks. Opted in explicitly, because a layout
    // rule is a screen's own declaration — not something the harness
    // infers from seeing `MxCard`.
    surfaceFinder: find.byType(MxCard),
    additionalRules: const <AuditRule>[SurfaceColumnRule()],
    anchors: <AuditAnchor>[
      AuditAnchor.type('shell', MxContentShell),
      AuditAnchor.type('empty_state', MxEmptyState),
    ],
    allowances: const <AuditSkipAllowance>[
      AuditSkipAllowance(
        itemId: 'screen',
        reason: SkipReason.rasterOnly,
        detailContains: '_RenderColoredBox',
        rationale:
            'The page-transition backdrop of this route. '
            '_FadeForwardsPageTransition wraps every opaque route in a '
            'ColoredBox that paints Colors.transparent at rest and '
            'ColorScheme.surface only mid-transition. It is NOT the Scaffold '
            'background, which is asserted in app_theme_test.dart.',
      ),
      AuditSkipAllowance(
        itemId: 'shell',
        reason: SkipReason.rasterOnly,
        detailContains: '_RenderInkFeatures',
        // Three now: the Scaffold, the AppBar, and the transparent Material
        // inside the daily-reminder card — `ListTile` paints its ink onto the
        // nearest Material ancestor, and `MxCard` is a DecoratedBox, so the row
        // brings its own (M99.23).
        expectedMatches: 3,
        rationale:
            'The Scaffold and AppBar Material ink layers. Splash and highlight '
            'are painted onto Material, so no render object carries them.',
      ),
      AuditSkipAllowance(
        itemId: 'shell',
        reason: SkipReason.customPainter,
        detailContains: 'no painter',
        rationale:
            'A clip with no painter of its own, behind the daily-reminder row.',
      ),
    ],
  );
}
