@Tags(<String>['golden', 'screen-audit'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/card/domain/models/deck_context_model.dart';
import 'package:memox/features/card/presentation/screens/card_import_screen.dart';

import '../../../../audit_allowance.dart';
import '../../../../audit_model.dart';
import '../../../../card_audit_harness.dart';
import '../../../../memox_audit.dart';
import '../../../../screen_auditor.dart';
import '../../../../../features/card/presentation/support/fake_card_repository.dart';

/// The deck the wizard is importing into, for the context chip and breadcrumb.
const DeckContextModel importDeckContext = DeckContextModel(
  deckName: 'Korean · TOPIK I',
  ancestors: <DeckBreadcrumbSegment>[
    DeckBreadcrumbSegment(id: 'ko', name: 'Korean'),
  ],
);

/// Strict visual audit for `CardImportScreen` (UC-10, wireframe M4.12).
///
/// The Source step is audited — it is the state the wizard opens on, and the
/// only one reachable without a parsed document. Rendered directly: the
/// source step reads only draft providers, whose defaults are exactly this
/// state.
void main() {
  memoxProductionScreenAuditTest(
    'card_import_screen',
    () => cardScreenWith(
      FakeCardRepository()..deckContextToShow = importDeckContext,
      const CardImportScreen(deckId: 'deck-1'),
    ),
    anchors: <AuditAnchor>[AuditAnchor.type('wizard', Scaffold)],
    allowances: const <AuditSkipAllowance>[
      AuditSkipAllowance(
        itemId: 'screen',
        reason: SkipReason.rasterOnly,
        detailContains: '_RenderColoredBox',
        rationale:
            'The page-transition backdrop MaterialApp paints around an opaque '
            'route. At rest it paints Colors.transparent; mid-transition it '
            'paints ColorScheme.surface, a palette token asserted in '
            'app_theme_test.dart.',
      ),
      AuditSkipAllowance(
        itemId: 'wizard',
        reason: SkipReason.rasterOnly,
        detailContains: '_RenderInkFeatures',
        expectedMatches: 8,
        rationale:
            'The Material ink layers of the Scaffold, the AppBar, the close '
            'IconButton, the two tappable source cards, the two static MxCard '
            'panels and the action buttons. Splash and highlight paint into '
            'these layers; the overlay colours are asserted in '
            'app_theme_test.dart.',
      ),
      AuditSkipAllowance(
        itemId: 'wizard',
        reason: SkipReason.customPainter,
        detailContains: '_ShapeBorderPainter',
        expectedMatches: 3,
        rationale:
            'The close IconButton, the disabled Preview FilledButton and the '
            'Choose-file OutlinedButton draw their rounded shapes through '
            'ShapeBorder painters; the shapes come from the button themes and '
            'are pinned by the mx_components goldens.',
      ),
      AuditSkipAllowance(
        itemId: 'wizard',
        reason: SkipReason.customPainter,
        detailContains: 'CustomPaint (no painter)',
        expectedMatches: 3,
        rationale:
            'Material 3 buttons mount an empty CustomPaint per control as the '
            'ink-sparkle attachment point; with no painter installed it draws '
            'nothing, so there is no colour to read or misread.',
      ),
    ],
  );
}
