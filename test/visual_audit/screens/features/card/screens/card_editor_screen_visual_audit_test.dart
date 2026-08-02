@Tags(<String>['golden', 'screen-audit'])
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/card/presentation/screens/card_editor_screen.dart';
import 'package:memox/shared/widgets/mx_content_shell.dart';

import '../../../../audit_allowance.dart';
import '../../../../audit_model.dart';
import '../../../../card_audit_harness.dart';
import '../../../../memox_audit.dart';
import '../../../../screen_auditor.dart';
import '../../../../../features/card/presentation/support/fake_card_repository.dart';

/// Strict visual audit for `CardEditorScreen` in create mode (UC-04 W4).
///
/// The idle form is audited — two empty fields and the two save buttons — because
/// it is the state the user opens. Rendered directly (no router); the allowances
/// are the Material chrome, the two text fields and the two action buttons.
void main() {
  memoxProductionScreenAuditTest(
    'card_editor_screen',
    () => cardScreenWith(
      FakeCardRepository(),
      const CardEditorScreen(deckId: 'deck-1'),
    ),
    anchors: <AuditAnchor>[AuditAnchor.type('shell', MxContentShell)],
    // Create autofocuses the front field, which mounts the text-selection
    // toolbar anchor; edit does not, so that allowance is create's alone.
    allowances: const <AuditSkipAllowance>[
      ..._sharedAllowances,
      _selectionAnchorAllowance,
    ],
  );

  memoxProductionScreenAuditTest(
    'card_editor_screen_edit',
    _editorInEditMode,
    state: 'edit',
    anchors: <AuditAnchor>[AuditAnchor.type('shell', MxContentShell)],
    allowances: _sharedAllowances,
  );
}

/// The editor opened on an existing card (UC-04 A1): the two fields prefilled,
/// the BR-10 progress note, the save-changes button, and the danger zone.
Widget _editorInEditMode() {
  final repository = FakeCardRepository();
  repository.cardToGet = repository.card(
    'card-1',
    front: 'ephemeral',
    back: 'lasting a short time',
  );

  return cardScreenWith(
    repository,
    const CardEditorScreen(deckId: 'deck-1', cardId: 'card-1'),
  );
}

/// Create's alone: the autofocused front field mounts the text-selection
/// toolbar anchor (a `CompositedTransformFollower`), which only positions its
/// child and paints nothing. Edit opens without autofocus, so it never appears.
const AuditSkipAllowance _selectionAnchorAllowance = AuditSkipAllowance(
  itemId: 'screen',
  reason: SkipReason.unknownRenderType,
  detailContains: 'RenderFollowerLayer',
  rationale:
      'The text-selection toolbar anchor (CompositedTransformFollower) '
      'only positions its child and paints nothing.',
);

/// Shared by both modes: create and edit paint the same render tree — two
/// `MxTextField`s, a close `IconButton` and two `MxActionButton`s inside the
/// shell — so the same allowances resolve both. The only difference is the text
/// prefilled into the fields, which is raster-only either way.
const List<AuditSkipAllowance> _sharedAllowances = <AuditSkipAllowance>[
  AuditSkipAllowance(
    itemId: 'screen',
    reason: SkipReason.rasterOnly,
    detailContains: '_RenderColoredBox',
    rationale:
        'The route backdrop MaterialApp paints around an opaque page; the '
        'surface value is asserted in app_theme_test.dart.',
  ),
  AuditSkipAllowance(
    itemId: 'shell',
    reason: SkipReason.rasterOnly,
    detailContains: '_RenderInkFeatures',
    expectedMatches: 5,
    rationale:
        'The Material ink layers of the Scaffold, the AppBar, the close '
        'IconButton and the two action buttons. Splash and highlight paint '
        'into these layers; the overlay colours are asserted in '
        'app_theme_test.dart.',
  ),
  AuditSkipAllowance(
    itemId: 'shell',
    reason: SkipReason.customPainter,
    detailContains: '_ShapeBorderPainter',
    expectedMatches: 3,
    rationale:
        'The two action buttons and the close IconButton draw their rounded '
        'shapes through ShapeBorder painters; the shapes come from the '
        'button and icon-button themes and are pinned by the mx_components '
        'goldens.',
  ),
  // The two text fields. Each RenderEditable and its two custom-paint
  // layers (caret, selection) are raster-only; the field's border and
  // decoration paint no colour on a render object. Typed text and caret are
  // covered when a focused/error field audit lands in a later slice.
  AuditSkipAllowance(
    itemId: 'shell',
    reason: SkipReason.rasterOnly,
    detailContains: '_RenderDecoration',
    expectedMatches: 2,
    rationale:
        'InputDecorator lays out each field; its border is painted by a '
        'CustomPainter and its colours are asserted in app_theme_test.dart.',
  ),
  AuditSkipAllowance(
    itemId: 'shell',
    reason: SkipReason.rasterOnly,
    detailContains: 'RenderEditable paints',
    expectedMatches: 2,
    rationale:
        'The editable region of each field. Typed text and caret are '
        'raster-only, covered by a focused/error field audit in M5.',
  ),
  AuditSkipAllowance(
    itemId: 'shell',
    reason: SkipReason.rasterOnly,
    detailContains: '_RenderEditableCustomPaint',
    expectedMatches: 4,
    rationale:
        'The caret and selection painters behind the two fields, both '
        'raster-only and covered by the same M5 field-state audit.',
  ),
  AuditSkipAllowance(
    itemId: 'shell',
    reason: SkipReason.customPainter,
    detailContains: 'no painter',
    expectedMatches: 2,
    rationale:
        'Each field clips through a CustomPaint with no painter of its own.',
  ),
  AuditSkipAllowance(
    itemId: 'shell',
    reason: SkipReason.unknownRenderType,
    detailContains: '_RenderLayoutBuilder',
    rationale:
        'A LayoutBuilder inside the field decoration sizes its child and '
        'paints no colour.',
  ),
];
