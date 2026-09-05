@Tags(<String>['golden', 'screen-audit'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/study/domain/entities/study_queue_item_entity.dart';
import 'package:memox/features/study/domain/models/study_mode.dart';
import 'package:memox/features/study/domain/models/study_queue_item_status_model.dart';
import 'package:memox/features/study/domain/models/study_session_kind_model.dart';
import 'package:memox/features/study/domain/models/study_turn_model.dart';
import 'package:memox/features/study/presentation/screens/study_session_screen.dart';
import 'package:memox/shared/widgets/mx_content_shell.dart';
import 'package:memox/shared/widgets/mx_card.dart';

import '../../../../audit_allowance.dart';
import '../../../../audit_model.dart';
import '../../../../audit_rules.dart';
import '../../../../memox_audit.dart';
import '../../../../screen_auditor.dart';
import '../../../../study_audit_harness.dart';
import '../../../../../features/study/domain/support/fake_study_repository.dart';

/// Strict visual audit for `StudySessionScreen`.
///
/// Companion of the screen at the mirrored path; MX-VIS-001 checks this file
/// exists, imports the screen, and calls the strict helper.
///
/// **`self_assess` on a card already turned over is the state audited**, and it
/// is the richest one the screen has: the card surface, both faces, and the
/// algorithm's action buttons. `browse` has no buttons, `recall` is mid-clock,
/// and the graded modes draw content built from a card set — all of them show
/// strictly less chrome than this, or the same chrome under a different body.
void main() {
  StudyTurnModel turn() => const StudyTurnModel(
    item: StudyQueueItemEntity(
      sessionId: 'session-1',
      mode: StudyMode.selfAssess,
      round: 1,
      cardId: 'c1',
      position: 0,
      status: StudyQueueItemStatus.pending,
      availableAt: 0,
      answersInSession: 0,
      remainingMs: null,
      isRevealed: false,
      direction: null,
    ),
    progress: StudyStageProgressModel(
      round: 1,
      done: 0,
      total: 1,
      completedCardIds: <String>[],
    ),
    card: StudyCardModel(
      id: 'c1',
      front: '사과',
      back: 'apple / quả táo',
      example: null,
      hint: null,
      pronunciation: null,
      frontFolded: '사과',
      backFolded: 'apple / quả táo',
    ),
  );

  FakeStudyRepository loaded() =>
      FakeStudyRepository(stageExhausted: false)..nextTurn_ = turn();

  memoxProductionScreenAuditTest(
    'study_session_screen',
    () => studyScreenWith(
      loaded(),
      const StudySessionScreen(
        deckId: 'deck-1',
        kind: StudySessionKind.reviewing,
        reviewMode: StudyMode.selfAssess,
      ),
    ),
    // This screen declares one surface column (M99.19a): every row of
    // cards spans it, or stacks. Opted in explicitly, because a layout
    // rule is a screen's own declaration — not something the harness
    // infers from seeing `MxCard`.
    surfaceFinder: find.byType(MxCard),
    additionalRules: const <AuditRule>[SurfaceColumnRule()],
    anchors: <AuditAnchor>[AuditAnchor.type('shell', MxContentShell)],
    // The session opens on the frame after the first, so settle before capture
    // — otherwise the screen is still its loading state and the audit measures
    // a spinner instead of a card.
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
        // Two since the finished face gained a way out (SC-C1-12): the Scaffold
        // and the MxActionButton's own Material. Still no AppBar — the count
        // is the assertion that none appeared.
        expectedMatches: 2,
        rationale:
            'The Scaffold Material ink layer and the one MxActionButton draws '
            'for its ripple. There is no AppBar: this screen's top bar is the '
            'session frame, which carries the mode and the ✕ that ends the '
            'session (BR-82) — a Material bar above it would name the screen '
            'twice and offer a back arrow that pops the route with the session '
            'still open. The card is an MxCard with no ink of its own; the '
            'overlay colours are asserted in app_theme_test.dart and the '
            'button states in mx_action_button_state_matrix_test.dart.',
      ),
      // **New with the finished face's way out (SC-C1-12).** A session whose
      // epilogue read fails used to end in a title and nothing else, on the one
      // screen that has deliberately removed every other control — no AppBar,
      // no frame, no ✕. It now carries `MxEmptyState.actionLabel`/`onAction`,
      // and an `MxActionButton` draws its shape through a `CustomPainter`, so
      // the outline lives in no render object. The audit's own `customPainter`
      // doc names this case. The button's fill and label colours come from
      // `filledButtonTheme` and are asserted in `app_theme_test.dart`; its
      // states are pinned by `mx_action_button_state_matrix_test.dart`.
      AuditSkipAllowance(
        itemId: 'shell',
        reason: SkipReason.customPainter,
        detailContains: '_ShapeBorderPainter',
        expectedMatches: 1,
        rationale:
            'The one MxActionButton on this screen: the way out of a finished '
            'session whose summary could not be read. An action button draws '
            'its shape with a CustomPainter, so the outline exists in no '
            'render object; the fill and label come from filledButtonTheme, '
            'asserted in app_theme_test.dart.',
      ),
    ],
  );
}
