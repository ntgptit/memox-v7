@Tags(<String>['golden', 'screen-audit'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/card/domain/models/card_state_model.dart';
import 'package:memox/features/card/presentation/screens/card_list_screen.dart';
import 'package:memox/shared/widgets/mx_content_shell.dart';

import '../../../../audit_allowance.dart';
import '../../../../audit_model.dart';
import '../../../../card_audit_harness.dart';
import '../../../../memox_audit.dart';
import '../../../../screen_auditor.dart';
import '../../../../../features/card/presentation/support/fake_card_repository.dart';

/// Strict visual audit for `CardListScreen` (UC-04 W1).
///
/// Companion of the screen at the mirrored path; MX-VIS-001 checks this exists,
/// imports the screen, and calls the strict helper. The loaded state is audited
/// because it is the one with content to measure — the list, the count line and
/// two tile faces.
///
/// Rendered directly (no router), so the allowances are the app's Material
/// chrome plus the tiles' ink, not the navigation shell — see
/// `card_audit_harness.dart`. Every one names its render type, its item and an
/// exact count, so a control added to the row surfaces as a miscount rather than
/// vanishing into a blanket permission.
void main() {
  // Two rows in different states, one flagged, so the audit measures the state
  // dots and label (D5) and the flag indicator (BR-92) as well as the face.
  FakeCardRepository loaded() => FakeCardRepository.loaded(
    <dynamic>[
      FakeCardRepository().listItem(
        'c1',
        front: 'ephemeral',
        back: 'short-lived',
        isFlagged: true,
        tagNames: <String>['noun', 'people'],
      ),
      FakeCardRepository().listItem(
        'c2',
        front: 'ubiquitous',
        back: 'everywhere',
        state: CardState.mastered,
      ),
    ].cast(),
    total: 214,
  );

  memoxProductionScreenAuditTest(
    'card_list_screen',
    () => cardScreenWith(loaded(), const CardListScreen(deckId: 'deck-1')),
    anchors: <AuditAnchor>[AuditAnchor.type('shell', MxContentShell)],
    allowances: const <AuditSkipAllowance>[
      // The MaterialApp's own surfaces, above the screen.
      AuditSkipAllowance(
        itemId: 'screen',
        reason: SkipReason.rasterOnly,
        detailContains: '_RenderColoredBox',
        rationale:
            'The route backdrop MaterialApp paints around an opaque page. It '
            'renders Colors.transparent at rest and ColorScheme.surface only '
            'mid-transition; the surface value is asserted in app_theme_test.dart.',
      ),
      // The shell: Scaffold, AppBar and the extended FAB.
      AuditSkipAllowance(
        itemId: 'shell',
        reason: SkipReason.rasterOnly,
        detailContains: '_RenderInkFeatures',
        expectedMatches: 4,
        rationale:
            'The Material ink layers of the Scaffold, the AppBar, the '
            'FloatingActionButton and one tappable card row that hosts an '
            'InkWell. Splash and highlight paint into these layers, so no render '
            'object carries them; the overlay colours are asserted in '
            'app_theme_test.dart.',
      ),
      AuditSkipAllowance(
        itemId: 'shell',
        reason: SkipReason.customPainter,
        detailContains: '_ShapeBorderPainter',
        rationale:
            'The FloatingActionButton draws its rounded shape through a '
            'ShapeBorder painter; the shape is set in floatingActionButtonTheme '
            'and pinned by the mx_components goldens.',
      ),
      AuditSkipAllowance(
        itemId: 'shell',
        reason: SkipReason.customPainter,
        detailContains: 'no painter',
        rationale:
            'A clip with no painter: an InkWell paints its clip through a '
            'CustomPaint with no painter of its own.',
      ),
      AuditSkipAllowance(
        itemId: 'shell',
        reason: SkipReason.unknownRenderType,
        detailContains: '_RenderChildOverflowBox',
        rationale:
            'The extended FAB lays out its label and icon in an OverflowBox, '
            'whose render object only sizes its child and paints no colour.',
      ),
    ],
  );
}
