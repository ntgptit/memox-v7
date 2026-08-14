@Tags(<String>['golden', 'screen-audit'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/study/presentation/screens/study_home_screen.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_content_shell.dart';

import '../../../../audit_allowance.dart';
import '../../../../audit_model.dart';
import '../../../../audit_rules.dart';
import '../../../../memox_audit.dart';
import '../../../../screen_auditor.dart';
import '../../../../study_audit_harness.dart';
import '../../../../../features/study/domain/support/fake_study_home_repository.dart';

/// Strict visual audit for `StudyHomeScreen`.
///
/// Companion of the screen at the mirrored path; MX-VIS-001 checks this file
/// exists, imports the screen, and calls the strict helper.
///
/// **The state audited is Resume plus a mixed list**, because it is the state
/// with the most to measure: a tinted resume surface, a ranked list, three
/// workload metrics per row and two different action variants. The empty states
/// draw strictly less — one icon, two lines and a button — and the error state
/// is `MxErrorState`, which is pinned by the shared component goldens.
void main() {
  memoxProductionScreenAuditTest(
    'study_home_screen',
    () => studyHomeScreenWith(
      FakeStudyHomeRepository(
        initial: fakeStudyHome(resume: fakeStudyHomeResume()),
      ),
      const StudyHomeScreen(),
    ),
    // One surface column (M99.19a): the resume card and every deck row span it.
    // Opted in explicitly, because a layout rule is a screen's own declaration
    // rather than something the harness infers from seeing `MxCard`.
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
            'The Material ink layers of the Scaffold, the AppBar and the three '
            'action buttons — Resume plus one Study per listed deck. Splash and '
            'highlight paint into these; the overlay colours are asserted in '
            'app_theme_test.dart.',
      ),
      AuditSkipAllowance(
        itemId: 'shell',
        reason: SkipReason.customPainter,
        detailContains: '_ShapeBorderPainter',
        expectedMatches: 3,
        rationale:
            'The three action buttons draw their rounded shapes through a '
            'ShapeBorder painter. All three come from the component themes and '
            'are pinned by the mx_components goldens.',
      ),
    ],
  );
}
