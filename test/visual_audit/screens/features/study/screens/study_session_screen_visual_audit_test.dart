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

import '../../../../audit_allowance.dart';
import '../../../../audit_model.dart';
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
    ),
    card: StudyCardModel(
      id: 'c1',
      front: 'ephemeral',
      back: 'short-lived',
      example: null,
      hint: null,
      pronunciation: null,
      backFolded: 'short-lived',
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
        expectedMatches: 2,
        rationale:
            'The Material ink layers of the Scaffold and the AppBar. The card '
            'itself is an MxCard with no ink of its own, and the reveal button '
            'is off-surface at this size; the overlay colours are asserted in '
            'app_theme_test.dart.',
      ),
    ],
  );
}
