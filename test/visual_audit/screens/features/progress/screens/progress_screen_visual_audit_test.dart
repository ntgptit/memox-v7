@Tags(<String>['golden', 'screen-audit'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_content_shell.dart';

import '../../../../audit_allowance.dart';
import '../../../../audit_model.dart';
import '../../../../audit_rules.dart';
import '../../../../memox_audit.dart';
import '../../../../progress_audit_harness.dart';
import '../../../../screen_auditor.dart';

/// Strict visual audit for `ProgressScreen`.
///
/// Companion of
/// `lib/features/progress/presentation/screens/progress_screen.dart`, at the
/// mirrored path; MX-VIS-001 checks this file exists, imports the screen, and
/// calls the strict helper.
///
/// **Four of the five faces are audited**, in both themes: the loaded state,
/// the streak-held variant whose hero says something no other state says, the
/// lifetime-empty face and the error face. Loading is left out on purpose — it
/// is `MxLoadingState` alone inside the same shell, and it is asserted by
/// identity in `progress_screen_test.dart` rather than by colour here.
///
/// The audit renders at the harness's fixed viewport. The three widths the
/// wireframe requires (320 @ 2.0, 390, 412) and both locales are covered by
/// `progress_screen_geometry_test.dart`, which measures rects rather than
/// paints — the two halves of W6 are checked by the two suites that can each
/// see one of them.
///
/// The screen replaced a placeholder at M99.23. This file replaced that
/// placeholder's companion at the same time — the coverage check pairs a
/// companion with a screen **by file name**, so a renamed screen leaves an
/// orphan on one side and a missing companion on the other.
void main() {
  memoxProductionScreenAuditTest(
    'progress_screen',
    progressScreenWith,
    state: 'loaded',
    // This screen declares one surface column (M99.19a): the three sections
    // each span it. Opted in explicitly, because a layout rule is a screen's
    // own declaration — not something the harness infers from seeing `MxCard`.
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
            'mid-transition; the surface value is asserted in '
            'app_theme_test.dart.',
      ),
      AuditSkipAllowance(
        itemId: 'shell',
        reason: SkipReason.rasterOnly,
        detailContains: '_RenderInkFeatures',
        // Five, and each one is named: the Scaffold's Material, the AppBar's
        // own, one per range pill, and one for the tappable deck row. Since
        // M99.24 this state is the **composed** screen — the three overview
        // sections above the library level — so the two the overview alone
        // contributed are no longer the whole story.
        expectedMatches: 5,
        rationale:
            'The Scaffold and AppBar Material ink layers, plus one per InkWell '
            'host: the two range pills and the tappable deck row. Splash and '
            'highlight are painted onto Material, so no render object carries '
            'them; the pill surfaces are asserted in mx_pill_button_test.dart '
            'and the card surface in app_theme_test.dart.',
      ),
      AuditSkipAllowance(
        itemId: 'shell',
        reason: SkipReason.customPainter,
        detailContains: 'CustomPaint (no painter)',
        // The InkWell clip, one per host that has one: two pills, one card.
        expectedMatches: 3,
        rationale:
            'The rounded clip an InkWell paints for its ripple, one per '
            'MxPillButton and per tappable MxCard. It has no painter to '
            'interrogate because the shape is the ripple boundary rather than a '
            'drawn stroke — the visible border is the DecoratedBox behind it, '
            'which the audit does read.',
      ),
      AuditSkipAllowance(
        itemId: 'shell',
        reason: SkipReason.unknownRenderType,
        detailContains: '_RenderChip',
        expectedMatches: 2,
        rationale:
            'ChoiceChip lays out and paints through a private _RenderChip, so '
            'neither its fill nor its border is reachable from the render tree. '
            'Both come from chipTheme in app_theme.dart and the selected and '
            'unselected fills are asserted to differ, in both themes, in '
            'mx_pill_button_test.dart.',
      ),
      AuditSkipAllowance(
        itemId: 'shell',
        reason: SkipReason.unknownRenderType,
        detailContains: '_RenderPinnedHeaderSliver',
        rationale:
            'PinnedHeaderSliver lays its child out and paints nothing of its own — it has no colour, no border and no shape. The strip it pins is an MxSubheaderBand over a DecoratedBox whose surface colour the audit reads directly, one node below this one.',
      ),
      AuditSkipAllowance(
        itemId: 'shell',
        reason: SkipReason.rasterNotFlat,
        detailContains: 'covers only 0%',
        rationale:
            'The unselected range pill declares a surface tint that its resting '
            'state does not fill, and _RenderChip paints what it does fill '
            'through a private render object. Same case the deck level records '
            'for the same two pills.',
      ),
    ],
  );

  memoxProductionScreenAuditTest(
    'progress_screen',
    progressScreenStreakHeld,
    state: 'streak_held',
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
            'mid-transition; the surface value is asserted in '
            'app_theme_test.dart.',
      ),
      AuditSkipAllowance(
        itemId: 'shell',
        reason: SkipReason.rasterOnly,
        detailContains: '_RenderInkFeatures',
        // Same five as the loaded state above: this face differs only in what
        // the hero says.
        expectedMatches: 5,
        rationale:
            'The Scaffold and AppBar Material ink layers, plus one per InkWell '
            'host: the two range pills and the tappable deck row. Splash and '
            'highlight are painted onto Material, so no render object carries '
            'them; the pill surfaces are asserted in mx_pill_button_test.dart '
            'and the card surface in app_theme_test.dart.',
      ),
      AuditSkipAllowance(
        itemId: 'shell',
        reason: SkipReason.customPainter,
        detailContains: 'CustomPaint (no painter)',
        // The InkWell clip, one per host that has one: two pills, one card.
        expectedMatches: 3,
        rationale:
            'The rounded clip an InkWell paints for its ripple, one per '
            'MxPillButton and per tappable MxCard. It has no painter to '
            'interrogate because the shape is the ripple boundary rather than a '
            'drawn stroke — the visible border is the DecoratedBox behind it, '
            'which the audit does read.',
      ),
      AuditSkipAllowance(
        itemId: 'shell',
        reason: SkipReason.unknownRenderType,
        detailContains: '_RenderChip',
        expectedMatches: 2,
        rationale:
            'ChoiceChip lays out and paints through a private _RenderChip, so '
            'neither its fill nor its border is reachable from the render tree. '
            'Both come from chipTheme in app_theme.dart and the selected and '
            'unselected fills are asserted to differ, in both themes, in '
            'mx_pill_button_test.dart.',
      ),
      AuditSkipAllowance(
        itemId: 'shell',
        reason: SkipReason.unknownRenderType,
        detailContains: '_RenderPinnedHeaderSliver',
        rationale:
            'PinnedHeaderSliver lays its child out and paints nothing of its own — it has no colour, no border and no shape. The strip it pins is an MxSubheaderBand over a DecoratedBox whose surface colour the audit reads directly, one node below this one.',
      ),
      AuditSkipAllowance(
        itemId: 'shell',
        reason: SkipReason.rasterNotFlat,
        detailContains: 'covers only 0%',
        rationale:
            'The unselected range pill declares a surface tint that its resting '
            'state does not fill, and _RenderChip paints what it does fill '
            'through a private render object. Same case the deck level records '
            'for the same two pills.',
      ),
    ],
  );

  memoxProductionScreenAuditTest(
    'progress_screen',
    progressScreenEmpty,
    state: 'empty_lifetime',
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
            'mid-transition; the surface value is asserted in '
            'app_theme_test.dart.',
      ),
      AuditSkipAllowance(
        itemId: 'shell',
        reason: SkipReason.rasterOnly,
        detailContains: '_RenderInkFeatures',
        // Three here rather than two: the empty face adds a filled action, and
        // a button brings its own Material.
        expectedMatches: 3,
        rationale:
            'The Scaffold and AppBar Material ink layers, plus the call to '
            'action. Splash and highlight are painted onto Material, so no '
            'render object carries them.',
      ),
      AuditSkipAllowance(
        itemId: 'shell',
        reason: SkipReason.customPainter,
        detailContains: '_ShapeBorderPainter',
        rationale:
            'The action button draws its rounded shape through a ShapeBorder '
            'painter; the shape and its colours come from the component themes '
            'and are pinned by the mx_components goldens.',
      ),
    ],
  );

  memoxProductionScreenAuditTest(
    'progress_screen',
    progressScreenFailing,
    state: 'error',
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
            'mid-transition; the surface value is asserted in '
            'app_theme_test.dart.',
      ),
      AuditSkipAllowance(
        itemId: 'shell',
        reason: SkipReason.rasterOnly,
        detailContains: '_RenderInkFeatures',
        expectedMatches: 3,
        rationale:
            'The Scaffold and AppBar Material ink layers, plus the Retry '
            'action. Splash and highlight are painted onto Material, so no '
            'render object carries them.',
      ),
      AuditSkipAllowance(
        itemId: 'shell',
        reason: SkipReason.customPainter,
        detailContains: '_ShapeBorderPainter',
        rationale:
            'The action button draws its rounded shape through a ShapeBorder '
            'painter; the shape and its colours come from the component themes '
            'and are pinned by the mx_components goldens.',
      ),
    ],
  );
}
