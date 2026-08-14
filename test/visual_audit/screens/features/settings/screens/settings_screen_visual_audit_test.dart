@Tags(<String>['golden', 'screen-audit'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/settings/presentation/screens/settings_screen.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_content_shell.dart';

import '../../../../audit_allowance.dart';
import '../../../../audit_model.dart';
import '../../../../audit_rules.dart';
import '../../../../memox_audit.dart';
import '../../../../screen_auditor.dart';
import '../../../../settings_audit_harness.dart';
import '../../../../../features/settings/domain/support/fake_app_settings_repository.dart';

/// Strict visual audit for `SettingsScreen`.
///
/// Companion of the screen at the mirrored path; MX-VIS-001 checks this file
/// exists, imports the screen, and calls the strict helper.
///
/// **The loaded screen at its defaults is the state audited.** It is the one
/// with everything on it: three groups, a labelled field, two order pills, the
/// BR-185 note, the save button and the reset action. The error states add a
/// band whose fill is `errorContainer` — a colour the audit already measures
/// wherever a band is rendered — and the saving state only greys controls the
/// button theme already owns.
void main() {
  memoxProductionScreenAuditTest(
    'settings_screen',
    () =>
        settingsScreenWith(FakeAppSettingsRepository(), const SettingsScreen()),
    // This screen declares one surface column (M99.19a): every row of cards
    // spans it, or stacks. Opted in explicitly, because a layout rule is a
    // screen's own declaration — not something the harness infers from seeing
    // `MxCard`.
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
        // Seven: the Scaffold, the AppBar, the save button, the reset link,
        // and the transparent Material each of the three radio groups puts
        // inside its card so its rows' ripples are not painted behind it.
        expectedMatches: 7,
        rationale:
            'Material ink layers. Splash and highlight are painted onto '
            'Material, so no render object carries them; the overlay colours '
            'are asserted in app_theme_test.dart.',
      ),
      AuditSkipAllowance(
        itemId: 'shell',
        reason: SkipReason.customPainter,
        detailContains: '_RadioPainter',
        // Eight radios: three themes, three languages and the two new-card
        // orders, which stopped being pills when W6's "not by colour alone"
        // was applied to them too.
        expectedMatches: 8,
        rationale:
            'The radio marks. Their fill comes from RadioThemeData, which '
            'app_radio_theme.dart measures against the 3:1 WCAG 1.4.11 floor '
            'and app_theme_test.dart pins.',
      ),
      // The card-limit field. It contributes a decoration, an editable region,
      // two editable custom-paint layers (caret, selection) and one
      // painter-less clip — the same set the study options screen allows, for
      // the same reason: none of them carries a colour on a render object.
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
        reason: SkipReason.customPainter,
        detailContains: 'no painter',
        expectedMatches: 4,
        rationale:
            'A clip with no painter: the card-limit field and the three radio '
            'groups each clip through a CustomPaint with no painter of its own.',
      ),
      AuditSkipAllowance(
        itemId: 'shell',
        reason: SkipReason.customPainter,
        detailContains: '_ShapeBorderPainter',
        // Two: the save button and the reset link both draw a rounded shape
        // through a ShapeBorder painter.
        expectedMatches: 2,
        rationale:
            'Buttons draw their rounded shape through a ShapeBorder painter; '
            'the shape comes from the button theme and is pinned by the '
            'mx_components goldens.',
      ),
    ],
  );
}
