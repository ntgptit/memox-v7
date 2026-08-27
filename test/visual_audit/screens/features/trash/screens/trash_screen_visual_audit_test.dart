@Tags(<String>['golden', 'screen-audit'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/trash/presentation/screens/trash_screen.dart';
import 'package:memox/shared/widgets/mx_content_shell.dart';

import '../../../../audit_allowance.dart';
import '../../../../audit_model.dart';
import '../../../../memox_audit.dart';
import '../../../../screen_auditor.dart';
import '../../../../trash_audit_harness.dart';
import '../../../../../features/trash/presentation/support/fake_trash_repository.dart';

/// Strict visual audit for `TrashScreen`.
///
/// Companion of `lib/features/trash/presentation/screens/trash_screen.dart`, at
/// the mirrored path (MX-VIS-001).
///
/// **Two states, and they are the two that differ structurally**: a populated
/// list, and the empty state a first-time visitor sees. The selection bar and
/// the target picker are overlays over the first; they are covered by
/// `trash_screen_test.dart`, which can drive them.
///
/// No `surfaceFinder`: Trash draws rows directly on the page rather than on
/// `MxCard`, so it declares no surface column — the density decision the deck
/// list made does not apply to a list whose rows carry no elevation.
void main() {
  memoxProductionScreenAuditTest(
    'trash_screen',
    () => trashScreenWith(
      FakeTrashRepository(batches: trashAuditBatches()),
      const TrashScreen(),
    ),
    state: 'loaded',
    anchors: <AuditAnchor>[AuditAnchor.type('shell', MxContentShell)],
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
        // Counted, not guessed: the Scaffold, the AppBar, one per InkWell
        // host the loaded state actually mounts — and one extra per row,
        // because a row is now an MxPressable and brings its own transparent
        // Material instead of borrowing the shell one.
        expectedMatches: 12,
        rationale:
            'Material ink layers: the Scaffold and the AppBar from '
            'MxContentShell, one per MxIconButton, one per MxPillButton, and '
            'two per row — an MxPressable is a transparent Material plus an '
            'InkWell so a long press can start a selection. A Material paints background, splash and highlight into '
            'a layer no render object reports; the icon button states are '
            'pinned by the mx_icon_button_* goldens and the pill surfaces by '
            'app_theme_test.dart.',
      ),
      AuditSkipAllowance(
        itemId: 'shell',
        reason: SkipReason.customPainter,
        detailContains: '_ShapeBorderPainter',
        // One per MxIconButton: Select and Trash on the bar, Restore and the
        // row overflow on each of the two rows — minus the one the empty
        // state's absent Select accounts for elsewhere.
        expectedMatches: 5,
        rationale:
            'MxIconButton draws its rounded state layer with a CustomPainter, '
            'so the shape exists in no render object. It is the Material 3 '
            'shape and is pinned by the mx_icon_button_* goldens (M4.8).',
      ),
      AuditSkipAllowance(
        itemId: 'shell',
        reason: SkipReason.unknownRenderType,
        detailContains: '_RenderChip',
        // The three filter chips.
        expectedMatches: 3,
        rationale:
            'ChoiceChip lays out and paints through a private _RenderChip, so '
            'neither its fill nor its border is reachable from the render tree. '
            'Both come from chipTheme in app_theme.dart, and the selected and '
            'unselected fills are asserted to differ, in both themes, in '
            'mx_pill_button_test.dart.',
      ),
      AuditSkipAllowance(
        itemId: 'shell',
        reason: SkipReason.customPainter,
        detailContains: 'CustomPaint (no painter)',
        // One per MxPillButton, plus one per row MxPressable.
        expectedMatches: 5,
        rationale:
            "The rounded clip an InkWell paints for its ripple, one per "
            'MxPillButton and one per trash row. It has no painter to interrogate because the shape '
            'is the ripple boundary rather than a drawn stroke — the visible '
            'border is the DecoratedBox behind it, which the audit does read.',
      ),
      AuditSkipAllowance(
        itemId: 'shell',
        reason: SkipReason.rasterNotFlat,
        detailContains: 'covers only',
        rationale:
            'The shell fills the page with `surface` and the list then draws '
            'two rows of text over most of it, so no single colour reaches the '
            "raster check's 90% threshold. The declared value is the theme's "
            'own `surface`, asserted in app_theme_test.dart; what the raster '
            'cannot do here is confirm it, which is not the same as '
            'contradicting it.',
      ),
    ],
  );

  memoxProductionScreenAuditTest(
    'trash_screen',
    // No batches: the fake's default, which is what a first-time visitor sees.
    () => trashScreenWith(FakeTrashRepository(), const TrashScreen()),
    state: 'empty',
    anchors: <AuditAnchor>[AuditAnchor.type('shell', MxContentShell)],
    allowances: const <AuditSkipAllowance>[
      AuditSkipAllowance(
        itemId: 'screen',
        reason: SkipReason.rasterOnly,
        detailContains: '_RenderColoredBox',
        rationale:
            'The page-transition backdrop of this route, exactly as in the '
            'loaded state above.',
      ),
      AuditSkipAllowance(
        itemId: 'shell',
        reason: SkipReason.rasterOnly,
        detailContains: '_RenderInkFeatures',
        // Scaffold, AppBar and the three filter chips. No rows, and no Select
        // action: there is nothing to select.
        expectedMatches: 5,
        rationale:
            'Material ink layers: the Scaffold, the AppBar and one per '
            'MxPillButton. Same raster-only reason as the loaded state.',
      ),
      AuditSkipAllowance(
        itemId: 'shell',
        reason: SkipReason.unknownRenderType,
        detailContains: '_RenderChip',
        expectedMatches: 3,
        rationale:
            'The three filter chips, unreadable for the same reason as in the '
            'loaded state. They stay on an empty Trash on purpose: a filter '
            'that vanished when its result was empty would leave the user with '
            'no way back to All.',
      ),
      AuditSkipAllowance(
        itemId: 'shell',
        reason: SkipReason.customPainter,
        detailContains: 'CustomPaint (no painter)',
        expectedMatches: 3,
        rationale:
            "The InkWell ripple clip of each MxPillButton — see the loaded "
            'state for why it has no painter to read.',
      ),
      AuditSkipAllowance(
        itemId: 'shell',
        reason: SkipReason.rasterNotFlat,
        detailContains: 'covers only',
        rationale:
            'The empty state centres an icon and two lines of text on a page '
            'the shell fills with `surface`, and the raster check finds no '
            "colour at its 90% threshold. The declared value is the theme's own "
            '`surface`, asserted in app_theme_test.dart; the raster cannot '
            'confirm it here, which is not the same as contradicting it.',
      ),
    ],
  );
}
