import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/features/card/domain/failures/card_not_found_failure.dart';
import 'package:memox/features/card/domain/models/card_history_page_model.dart';
import 'package:memox/features/deck/domain/models/scheduler_type_model.dart';

import 'support/card_detail_harness.dart';
import 'support/fake_card_detail_repository.dart';

/// What the detail screen shows about the card itself, and how it recovers
/// when it cannot show anything (UC-12, M4.14 W3 faces 1, 2, 7 and 8).
///
/// Driven against a fake of the domain contract rather than a database: pumping
/// Drift from a widget test leaves its stream-notification timer pending at
/// teardown, and `flutter_test` then fails the test for that instead of for the
/// behaviour.
///
/// The timeline's own faces are `card_detail_history_faces_test.dart` — split
/// at the seam the guard's size ceiling exposed, and a real one: this file is
/// about the card, that one is about its history.
void main() {
  group('content (BR-183)', () {
    testWidgets('both faces and every filled optional field are shown in '
        'full', (tester) async {
      final repository = FakeCardDetailRepository()
        ..seededDetail = fakeCardDetail(
          front: '사과',
          back: 'quả táo',
          example: '사과를 먹어요',
          hint: 'a fruit',
          pronunciation: 'sa-gwa',
          tagNames: <String>['noun', 'food'],
          isFlagged: true,
        )
        ..pages.add(CardHistoryPageModel.empty);
      await pumpCardDetail(tester, repository);
      await tester.pumpAndSettle();

      expect(find.text('사과'), findsOneWidget);
      expect(find.text('quả táo'), findsOneWidget);
      expect(find.text('사과를 먹어요'), findsOneWidget);
      expect(find.text('a fruit'), findsOneWidget);
      expect(find.text('sa-gwa'), findsOneWidget);
      expect(find.text('noun'), findsOneWidget);
      expect(find.text('food'), findsOneWidget);
      expect(find.text('Flagged'), findsOneWidget);
    });

    testWidgets('an unfilled optional field draws no label at all', (
      tester,
    ) async {
      final repository = FakeCardDetailRepository()
        ..seededDetail = fakeCardDetail()
        ..pages.add(CardHistoryPageModel.empty);
      await pumpCardDetail(tester, repository);
      await tester.pumpAndSettle();

      expect(find.text('Example'), findsNothing);
      expect(find.text('Hint'), findsNothing);
      expect(find.text('Pronunciation'), findsNothing);
      expect(find.text('Flagged'), findsNothing);
    });

    testWidgets('very long content wraps instead of being clipped', (
      tester,
    ) async {
      final long = 'a very long meaning ' * 40;
      final repository = FakeCardDetailRepository()
        ..seededDetail = fakeCardDetail(back: long)
        ..pages.add(CardHistoryPageModel.empty);
      await pumpCardDetail(
        tester,
        repository,
        surfaceSize: const Size(320, 640),
      );
      await tester.pumpAndSettle();

      final text = tester.widget<Text>(find.text(long));
      // No `maxLines`, no ellipsis: the list row is allowed to truncate because
      // it answers "which card"; this screen answers "what does it say".
      expect(text.maxLines, isNull);
      expect(text.overflow, isNull);
      expect(tester.takeException(), isNull);
    });
  });

  group('current state (BR-183, AD-08)', () {
    testWidgets('an eight_box card shows its box and none of the sm2 '
        'fields', (tester) async {
      final repository = FakeCardDetailRepository()
        ..seededDetail = fakeCardDetail(currentBox: 3)
        ..pages.add(CardHistoryPageModel.empty);
      await pumpCardDetail(tester, repository);
      await tester.pumpAndSettle();

      expect(find.text('Box'), findsOneWidget);
      expect(find.text('Ease'), findsNothing);
      expect(find.text('Interval'), findsNothing);
      expect(find.text('Repetitions'), findsNothing);
    });

    testWidgets('an sm2 card shows ease, interval and repetitions and no '
        'box', (tester) async {
      final repository = FakeCardDetailRepository()
        ..seededDetail = fakeCardDetail(
          schedulerType: SchedulerType.sm2,
          currentBox: null,
          easeFactor: 2.5,
          intervalDays: 6,
          repetitions: 2,
        )
        ..pages.add(CardHistoryPageModel.empty);
      await pumpCardDetail(tester, repository);
      await tester.pumpAndSettle();

      expect(find.text('Box'), findsNothing);
      expect(find.text('Ease'), findsOneWidget);
      expect(find.text('2.50'), findsOneWidget);
      expect(find.text('6 days'), findsOneWidget);
      expect(find.text('Repetitions'), findsOneWidget);
    });

    testWidgets('a card that has not finished the learning chain says so '
        'rather than showing a blank date (BR-149)', (tester) async {
      final repository = FakeCardDetailRepository()
        ..seededDetail = fakeCardDetail()
        ..pages.add(CardHistoryPageModel.empty);
      await pumpCardDetail(tester, repository);
      await tester.pumpAndSettle();

      // Due and Learned travel together and share the placeholder; Last
      // answered is a different question and says so in its own words.
      expect(find.text('Not scheduled yet'), findsNWidgets(2));
      expect(find.text('Never answered'), findsOneWidget);
    });

    testWidgets('no aggregate is shown anywhere (BR-186)', (tester) async {
      final repository = FakeCardDetailRepository()
        ..seededDetail = fakeCardDetail()
        ..pages.add(fakeHistoryPage(count: 4));
      await pumpCardDetail(tester, repository);
      await tester.pumpAndSettle();

      // No percentage and no streak: a second definition of a statistic is one
      // that disagrees with the real one exactly when nobody is looking.
      expect(find.textContaining('%'), findsNothing);
    });
  });

  group('failure faces (BR-188, UC-12 E1/E3)', () {
    testWidgets('a card that is gone gets the not-found face and a way back '
        'to the list', (tester) async {
      final repository = FakeCardDetailRepository();
      await pumpCardDetail(tester, repository);
      repository.emitDetailError(
        const NotFoundFailure(
          message: 'That card no longer exists.',
          reason: CardNotFoundReason.cardGone,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Card not found'), findsOneWidget);
      expect(find.text('Back to cards'), findsOneWidget);
      // Nothing to edit, so the action is not offered.
      expect(find.byIcon(Icons.edit_outlined), findsNothing);

      await tester.tap(find.text('Back to cards'));
      await tester.pumpAndSettle();
      expect(find.text('card list'), findsOneWidget);
    });

    testWidgets('a card that disappears while it is open loses the Edit '
        'action too', (tester) async {
      final repository = FakeCardDetailRepository()
        ..seededDetail = fakeCardDetail()
        ..pages.add(CardHistoryPageModel.empty);
      await pumpCardDetail(tester, repository);
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.edit_outlined), findsOneWidget);

      repository.emitDetailError(
        const NotFoundFailure(
          message: 'That card no longer exists.',
          reason: CardNotFoundReason.cardGone,
        ),
      );
      await tester.pumpAndSettle();

      // Riverpod keeps the previous value on an `AsyncError`, so `hasValue`
      // stays true through this transition — which left the action on the
      // not-found face pointing at a card that is gone (M4.14 W3 face 8).
      expect(find.text('Card not found'), findsOneWidget);
      expect(find.byIcon(Icons.edit_outlined), findsNothing);
    });

    testWidgets('any other read failure gets the retryable error face', (
      tester,
    ) async {
      final repository = FakeCardDetailRepository();
      await pumpCardDetail(tester, repository);
      repository.emitDetailError(const DatabaseFailure(message: 'read failed'));
      await tester.pumpAndSettle();

      expect(find.text('This card could not be read.'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      expect(find.text('Card not found'), findsNothing);
    });

    testWidgets('no failure message names the card id or any SQL '
        '(BR-53)', (tester) async {
      final repository = FakeCardDetailRepository();
      await pumpCardDetail(tester, repository, cardId: 'secret-card');
      repository.emitDetailError(
        const NotFoundFailure(
          message: 'That card no longer exists.',
          reason: CardNotFoundReason.cardGone,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('secret-card'), findsNothing);
      expect(find.textContaining('SELECT'), findsNothing);
    });
  });

  group('editing is an explicit action (BR-189)', () {
    testWidgets('the app bar offers Edit, and it opens the editor', (
      tester,
    ) async {
      final repository = FakeCardDetailRepository()
        ..seededDetail = fakeCardDetail()
        ..pages.add(CardHistoryPageModel.empty);
      await pumpCardDetail(tester, repository);
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();

      expect(find.text('editor'), findsOneWidget);
    });
  });

  group('themes and scale', () {
    testWidgets('the screen renders in dark at 2.0 on a 320dp phone', (
      tester,
    ) async {
      final repository = FakeCardDetailRepository()
        ..seededDetail = fakeCardDetail(
          front: '안녕하세요',
          back: 'xin chào',
          tagNames: <String>['greeting'],
        )
        ..pages.add(fakeHistoryPage(count: 2, hasMore: true));
      await pumpCardDetail(
        tester,
        repository,
        theme: buildDarkTheme(),
        surfaceSize: const Size(320, 640),
        textScale: 2,
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('안녕하세요'), findsOneWidget);
    });
  });
}
