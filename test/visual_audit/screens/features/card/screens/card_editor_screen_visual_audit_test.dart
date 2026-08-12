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
      _coloredBox,
      ..._fieldsCreate,
      _inkLayersCreate,
      _shapesCreate,
      _selectionAnchorAllowance,
    ],
  );

  memoxProductionScreenAuditTest(
    'card_editor_screen_edit',
    _editorInEditMode,
    state: 'edit',
    anchors: <AuditAnchor>[AuditAnchor.type('shell', MxContentShell)],
    // The flag toggle loads its value after the card resolves; a second settle
    // lets it become enabled so the audit reads its token colour, not the
    // disabled-state blend.
    drive: _settleFlagToggle,
    allowances: const <AuditSkipAllowance>[
      _coloredBox,
      ..._fieldsEdit,
      _inkLayersEdit,
      _shapesEdit,
    ],
  );
}

Future<void> _settleFlagToggle(WidgetTester tester) => tester.pumpAndSettle();

/// The editor opened on an existing card (UC-04 A1): the two fields prefilled,
/// the BR-10 progress note, the save-changes button, and the danger zone.
Widget _editorInEditMode() {
  final repository = FakeCardRepository();
  repository.cardToGet = repository.card(
    'card-1',
    front: '감사합니다',
    back: 'thank you, to someone senior',
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

/// The Material ink and shape layers, whose count is the one thing that differs
/// between the two modes: create shows a close `IconButton` and two
/// `MxActionButton`s; edit adds a flag `IconButton` in the app bar, so it has one
/// more ink layer and one more shape painter. Split out of the shared list so the
/// count is exact per mode rather than fudged to fit both.
const AuditSkipAllowance _inkLayersCreate = AuditSkipAllowance(
  itemId: 'shell',
  reason: SkipReason.rasterOnly,
  detailContains: '_RenderInkFeatures',
  expectedMatches: 5,
  rationale:
      'The Material ink layers of the Scaffold, the AppBar, the close '
      'IconButton and the two action buttons. Splash and highlight paint into '
      'these layers; the overlay colours are asserted in app_theme_test.dart.',
);

const AuditSkipAllowance _inkLayersEdit = AuditSkipAllowance(
  itemId: 'shell',
  reason: SkipReason.rasterOnly,
  detailContains: '_RenderInkFeatures',
  expectedMatches: 6,
  rationale:
      'The five of create plus the app-bar flag IconButton (BR-92). Overlay '
      'colours are asserted in app_theme_test.dart.',
);

const AuditSkipAllowance _shapesCreate = AuditSkipAllowance(
  itemId: 'shell',
  reason: SkipReason.customPainter,
  detailContains: '_ShapeBorderPainter',
  expectedMatches: 3,
  rationale:
      'The two action buttons and the close IconButton draw their rounded '
      'shapes through ShapeBorder painters; the shapes come from the button and '
      'icon-button themes and are pinned by the mx_components goldens.',
);

const AuditSkipAllowance _shapesEdit = AuditSkipAllowance(
  itemId: 'shell',
  reason: SkipReason.customPainter,
  detailContains: '_ShapeBorderPainter',
  expectedMatches: 4,
  rationale:
      'The three of create plus the app-bar flag IconButton (BR-92); the shapes '
      'come from the icon-button theme and are pinned by the mx_components '
      'goldens.',
);

/// The route backdrop — constant across modes, so it carries no count. The
/// field LayoutBuilder is classified globally in render_classification.dart
/// since the hero grid made it a common sight (M99.14).
const AuditSkipAllowance _coloredBox = AuditSkipAllowance(
  itemId: 'screen',
  reason: SkipReason.rasterOnly,
  detailContains: '_RenderColoredBox',
  rationale:
      'The route backdrop MaterialApp paints around an opaque page; the surface '
      'value is asserted in app_theme_test.dart.',
);

/// The per-field raster nodes, counted per mode: create has two fields (front,
/// back); edit adds the tag-entry field, so its counts are one higher. Each
/// `MxTextField` contributes one decoration, one editable region, two editable
/// custom-paint layers (caret, selection) and one painter-less clip — none of
/// which carries a colour on a render object.
const List<AuditSkipAllowance> _fieldsCreate = <AuditSkipAllowance>[
  AuditSkipAllowance(
    itemId: 'shell',
    reason: SkipReason.rasterOnly,
    detailContains: '_RenderDecoration',
    expectedMatches: 2,
    rationale:
        'InputDecorator lays out each field; its border is a CustomPainter and '
        'its colours are asserted in app_theme_test.dart.',
  ),
  AuditSkipAllowance(
    itemId: 'shell',
    reason: SkipReason.rasterOnly,
    detailContains: 'RenderEditable paints',
    expectedMatches: 2,
    rationale: 'The editable region of each field; typed text is raster-only.',
  ),
  AuditSkipAllowance(
    itemId: 'shell',
    reason: SkipReason.rasterOnly,
    detailContains: '_RenderEditableCustomPaint',
    expectedMatches: 4,
    rationale: 'The caret and selection painters behind each field.',
  ),
  AuditSkipAllowance(
    itemId: 'shell',
    reason: SkipReason.customPainter,
    detailContains: 'no painter',
    expectedMatches: 2,
    rationale:
        'Each field clips through a CustomPaint with no painter of its own.',
  ),
];

const List<AuditSkipAllowance> _fieldsEdit = <AuditSkipAllowance>[
  AuditSkipAllowance(
    itemId: 'shell',
    reason: SkipReason.rasterOnly,
    detailContains: '_RenderDecoration',
    expectedMatches: 3,
    rationale:
        'Front, back and the tag-entry field (BR-93); each border is a '
        'CustomPainter with its colours asserted in app_theme_test.dart.',
  ),
  AuditSkipAllowance(
    itemId: 'shell',
    reason: SkipReason.rasterOnly,
    detailContains: 'RenderEditable paints',
    expectedMatches: 3,
    rationale: 'The editable region of the three fields; text is raster-only.',
  ),
  AuditSkipAllowance(
    itemId: 'shell',
    reason: SkipReason.rasterOnly,
    detailContains: '_RenderEditableCustomPaint',
    expectedMatches: 6,
    rationale: 'The caret and selection painters behind the three fields.',
  ),
  AuditSkipAllowance(
    itemId: 'shell',
    reason: SkipReason.customPainter,
    detailContains: 'no painter',
    expectedMatches: 3,
    rationale:
        'Each of the three fields clips through a painter-less CustomPaint.',
  ),
];
