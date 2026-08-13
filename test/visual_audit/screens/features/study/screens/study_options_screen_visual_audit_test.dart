@Tags(<String>['golden', 'screen-audit'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/study/presentation/screens/study_options_screen.dart';
import 'package:memox/shared/widgets/mx_content_shell.dart';
import 'package:memox/shared/widgets/mx_card.dart';

import '../../../../audit_allowance.dart';
import '../../../../audit_model.dart';
import '../../../../audit_rules.dart';
import '../../../../memox_audit.dart';
import '../../../../screen_auditor.dart';
import '../../../../study_audit_harness.dart';
import '../../../../../features/study/domain/support/fake_study_repository.dart';

/// Strict visual audit for `StudyOptionsScreen`.
///
/// Companion of the screen at the mirrored path; MX-VIS-001 checks this file
/// exists, imports the screen, and calls the strict helper.
///
/// **The loaded form with no error is the state audited.** It is the one with
/// everything on it: a labelled field, the two order pills, the BR-139 note and
/// the save button. The error state adds one line of `error` colour under a
/// field whose decoration is already measured here.
void main() {
  memoxProductionScreenAuditTest(
    'study_options_screen',
    () => studyScreenWith(
      FakeStudyRepository(),
      const StudyOptionsScreen(deckId: 'deck-1'),
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
            'The Material ink layers of the Scaffold, the AppBar, the two order '
            'pills and the save button. Splash and highlight paint into these; '
            'the overlay colours are asserted in app_theme_test.dart.',
      ),
      // The one card-limit field. Each MxTextField contributes a decoration, an
      // editable region, two editable custom-paint layers (caret, selection) and
      // one painter-less clip — the same set the card editor allows, for the
      // same reason: none of them carries a colour on a render object.
      AuditSkipAllowance(
        itemId: 'shell',
        reason: SkipReason.rasterOnly,
        detailContains: '_RenderDecoration',
        rationale:
            'InputDecorator lays out the field; its border is a CustomPainter '
            'and its colours are asserted in app_theme_test.dart.',
      ),
      AuditSkipAllowance(
        itemId: 'shell',
        reason: SkipReason.rasterOnly,
        detailContains: 'RenderEditable paints',
        rationale:
            'The editable region of the field; typed text is raster-only.',
      ),
      AuditSkipAllowance(
        itemId: 'shell',
        reason: SkipReason.rasterOnly,
        detailContains: '_RenderEditableCustomPaint',
        expectedMatches: 2,
        rationale: 'The caret and selection painters behind the field.',
      ),
      AuditSkipAllowance(
        itemId: 'shell',
        reason: SkipReason.unknownRenderType,
        detailContains: '_RenderChip',
        expectedMatches: 2,
        rationale:
            'The two order pills, MxPillButton over ChoiceChip; their colours '
            'come from ChipThemeData and are pinned by the mx_components chip '
            'goldens.',
      ),
      AuditSkipAllowance(
        itemId: 'shell',
        reason: SkipReason.rasterNotFlat,
        detailContains: 'covers only 0%',
        rationale:
            'The unselected order pill declares a surface tint its transparent '
            'rest state does not fill; the chip colours are pinned by the '
            'mx_components goldens.',
      ),
      AuditSkipAllowance(
        itemId: 'shell',
        reason: SkipReason.customPainter,
        detailContains: 'no painter',
        expectedMatches: 3,
        rationale:
            'A clip with no painter: the two order pills and the card-limit '
            'field each clip through a CustomPaint with no painter of its own.',
      ),
      AuditSkipAllowance(
        itemId: 'shell',
        reason: SkipReason.customPainter,
        detailContains: '_ShapeBorderPainter',
        rationale:
            'The save button draws its rounded shape through a ShapeBorder '
            'painter; the shape comes from the button theme and is pinned by '
            'the mx_components goldens.',
      ),
    ],
  );
}
