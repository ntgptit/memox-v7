@Tags(<String>['golden', 'screen-audit'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/settings/presentation/screens/settings_placeholder_screen.dart';
import 'package:memox/shared/widgets/mx_content_shell.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';

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
/// overridden — see the Progress companion for the shape.
void main() {
  memoxProductionScreenAuditTest(
    'settings_placeholder_screen',
    () => const SettingsPlaceholderScreen(),
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
        // Two, not one: the shell mounts an AppBar for its title, and AppBar
        // brings a second Material with its own ink layer.
        expectedMatches: 2,
        rationale:
            'The Scaffold and AppBar Material ink layers. Splash and highlight '
            'are painted onto Material, so no render object carries them.',
      ),
    ],
  );
}
