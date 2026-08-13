@Tags(<String>['golden', 'screen-audit'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/study/presentation/screens/study_entry_screen.dart';
import 'package:memox/shared/widgets/mx_content_shell.dart';
import 'package:memox/shared/widgets/mx_card.dart';

import '../../../../audit_allowance.dart';
import '../../../../audit_model.dart';
import '../../../../audit_rules.dart';
import '../../../../memox_audit.dart';
import '../../../../screen_auditor.dart';
import '../../../../study_audit_harness.dart';
import '../../../../../features/study/domain/support/fake_study_repository.dart';

/// Strict visual audit for `StudyEntryScreen`.
///
/// Companion of the screen at the mirrored path; MX-VIS-001 checks this file
/// exists, imports the screen, and calls the strict helper.
///
/// **The loaded state with both counts non-zero is the one audited.** It is the
/// only state with something to measure: two count pills and two entry buttons.
/// With nothing due the review entry is absent by rule (BR-145), so that state
/// has strictly less to check, not something different.
void main() {
  memoxProductionScreenAuditTest(
    'study_entry_screen',
    () => studyScreenWith(
      FakeStudyRepository(),
      const StudyEntryScreen(deckId: 'deck-1'),
    ),
    // This screen declares one surface column (M99.19a): every row of
    // cards spans it, or stacks. Opted in explicitly, because a layout
    // rule is a screen's own declaration — not something the harness
    // infers from seeing `MxCard`.
    surfaceFinder: find.byType(MxCard),
    additionalRules: const <AuditRule>[SurfaceColumnRule()],
    anchors: <AuditAnchor>[AuditAnchor.type('shell', MxContentShell)],
    drive: (tester) => tester.pumpAndSettle(),
    allowances: const <AuditSkipAllowance>[
      AuditSkipAllowance(
        itemId: 'screen',
        reason: SkipReason.rasterOnly,
        detailContains: '_RenderColoredBox',
        rationale:
            'The route backdrop MaterialApp paints around an opaque page. It '
            'renders Colors.transparent at rest and ColorScheme.surface only '
            'mid-transition; the surface value is asserted in app_theme_test.dart.',
      ),
      AuditSkipAllowance(
        itemId: 'shell',
        reason: SkipReason.rasterOnly,
        detailContains: '_RenderInkFeatures',
        expectedMatches: 5,
        rationale:
            'The Material ink layers of the Scaffold, the AppBar, the app-bar '
            'options IconButton and the two entry buttons. Splash and highlight '
            'paint into these; the overlay colours are asserted in '
            'app_theme_test.dart.',
      ),
      AuditSkipAllowance(
        itemId: 'shell',
        reason: SkipReason.customPainter,
        detailContains: '_ShapeBorderPainter',
        expectedMatches: 3,
        rationale:
            'The two entry buttons and the app-bar options IconButton draw '
            'their rounded shapes through a ShapeBorder painter; all three come '
            'from the component themes and are pinned by the mx_components '
            'goldens.',
      ),
    ],
  );
}
