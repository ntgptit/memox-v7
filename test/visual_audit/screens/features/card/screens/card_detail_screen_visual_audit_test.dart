@Tags(<String>['golden', 'screen-audit'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/card/domain/models/card_history_page_model.dart';
import 'package:memox/features/card/presentation/screens/card_detail_screen.dart';
import 'package:memox/features/study/domain/models/study_action_model.dart';
import 'package:memox/features/study/domain/models/study_answer_kind_model.dart';
import 'package:memox/features/study/domain/models/study_mode.dart';
import 'package:memox/shared/widgets/mx_content_shell.dart';

import '../../../../audit_allowance.dart';
import '../../../../audit_model.dart';
import '../../../../card_audit_harness.dart';
import '../../../../memox_audit.dart';
import '../../../../screen_auditor.dart';
import '../../../../../features/card/presentation/support/fake_card_detail_repository.dart';

Future<void> _settle(WidgetTester tester) => tester.pumpAndSettle();

/// Strict visual audit for `CardDetailScreen` (UC-19, M4.15).
///
/// Companion of the screen at the mirrored path; MX-VIS-001 checks this exists,
/// imports the screen, and calls the strict helper. The loaded state with
/// history is audited because it is the one with everything to measure — both
/// content faces, three optional fields, the tag chips, the schedule grid, a
/// generation heading and two timeline rows.
///
/// Rendered directly (no router), so the allowances are the app's Material
/// chrome rather than the navigation shell — see `card_audit_harness.dart`.
void main() {
  FakeCardDetailRepository loaded() {
    return FakeCardDetailRepository()
      ..seededDetail = fakeCardDetail(
        // Korean, because that is what this screen carries in use and Hangul is
        // what the audit then measures — full-width syllables set taller than
        // Latin, so the line heights and the contrast band are the real ones.
        front: '안녕하세요',
        back: 'hello / xin chào',
        example: '안녕하세요, 만나서 반갑습니다',
        hint: 'a polite greeting',
        pronunciation: 'annyeonghaseyo',
        tagNames: <String>['greeting', 'phrase'],
        isFlagged: true,
        currentBox: 3,
        learnedAt: fakeNow.subtract(const Duration(days: 12)),
        dueAt: fakeNow.add(const Duration(days: 2)),
        lastAnsweredAt: fakeNow.subtract(const Duration(days: 1)),
        answerCount: 7,
        lapseCount: 1,
      )
      ..pages.add(
        CardHistoryPageModel(
          events: <dynamic>[
            // Two generations, so the audit measures a group heading between
            // two runs rather than only the first heading of the band.
            fakeHistoryEvent(
              id: 'g2-1',
              schedulerGeneration: 2,
              previousBox: 2,
              nextBox: 3,
              nextDueAt: fakeNow.add(const Duration(days: 2)),
            ),
            fakeHistoryEvent(
              id: 'g1-1',
              answeredAt: fakeNow.subtract(const Duration(days: 30)),
              mode: StudyMode.fill,
              kind: StudyAnswerKind.learning,
              action: StudyAction.forgotten,
              usedHint: true,
              previousBox: null,
              nextBox: null,
            ),
          ].cast(),
          hasMore: true,
          nextCursor: null,
        ),
      );
  }

  memoxProductionScreenAuditTest(
    'card_detail_screen',
    () => cardDetailScreenWith(
      loaded(),
      const CardDetailScreen(deckId: 'deck-1', cardId: 'card-1'),
    ),
    anchors: <AuditAnchor>[AuditAnchor.type('shell', MxContentShell)],
    // The first history page lands a frame after the content stream, so give
    // the timeline a settle before capture — otherwise the band is still its
    // loading indicator.
    drive: _settle,
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
        // Three: the Scaffold, the AppBar and the Load more text button. Named
        // exactly, so a control added to this screen shows up as a miscount
        // rather than disappearing into a blanket permission.
        expectedMatches: 3,
        rationale:
            'The Material ink layers of the Scaffold, the AppBar, the app-bar '
            'Edit IconButton and the Load more text button. Splash and '
            'highlight paint into these layers; the overlay colours are '
            'asserted in app_theme_test.dart.',
      ),
      AuditSkipAllowance(
        itemId: 'shell',
        reason: SkipReason.customPainter,
        detailContains: '_ShapeBorderPainter',
        rationale:
            'The app-bar Edit IconButton draws its rounded shape through a '
            'ShapeBorder painter; the shape comes from the component theme and '
            'is pinned by the mx_components goldens.',
      ),
    ],
  );
}
