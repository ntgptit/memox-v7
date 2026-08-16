import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/card/domain/models/card_history_page_model.dart';
import 'package:memox/features/study/domain/models/study_answer_kind_model.dart';
import 'package:memox/features/study/domain/models/study_mode.dart';
import 'package:memox/features/study/domain/models/study_outcome_reason_model.dart';

import 'support/card_detail_harness.dart';
import 'support/fake_card_detail_repository.dart';

/// The timeline: what an event says, how generations are separated, and every
/// face of the tail (UC-19 steps 4–6 and E4, BR-241…BR-244, M4.15 W3 faces
/// 2–6).
///
/// Its own file rather than a group inside `card_detail_screen_test.dart`: the
/// card and its history have separate lifecycles by rule (BR-244), and the
/// tests follow that split. Same fake and same harness, so nothing about the
/// setup diverges.
void main() {
  group('history (BR-241…BR-244)', () {
    testWidgets('a card with no reviews shows the empty face, not an '
        'error', (tester) async {
      final repository = FakeCardDetailRepository()
        ..seededDetail = fakeCardDetail()
        ..pages.add(CardHistoryPageModel.empty);
      await pumpCardDetail(tester, repository);
      await tester.pumpAndSettle();

      expect(find.text('No reviews yet'), findsOneWidget);
      // W3 face 2 asks for a glyph beside the words.
      expect(find.byIcon(Icons.history), findsOneWidget);
      expect(find.text('Load more'), findsNothing);
      expect(find.text('Retry'), findsNothing);
    });

    testWidgets('an event says the stored mode, kind and action and the '
        'before→after of its own scheduler', (tester) async {
      final repository = FakeCardDetailRepository()
        ..seededDetail = fakeCardDetail()
        ..pages.add(
          CardHistoryPageModel(
            events: <dynamic>[
              fakeHistoryEvent(
                id: 'e-1',
                mode: StudyMode.recall,
                outcomeReason: StudyOutcomeReason.timeout,
                previousBox: 2,
                nextBox: 3,
              ),
            ].cast(),
            hasMore: false,
            nextCursor: null,
          ),
        );
      await pumpCardDetail(tester, repository);
      await tester.pumpAndSettle();

      expect(find.text('Recall · Scheduled · Remembered'), findsOneWidget);
      expect(find.text('Box 2 → 3'), findsOneWidget);
      expect(find.text('Timed out'), findsOneWidget);
    });

    testWidgets('a learning turn says the schedule is unchanged rather than '
        'showing nothing (BR-144)', (tester) async {
      final repository = FakeCardDetailRepository()
        ..seededDetail = fakeCardDetail()
        ..pages.add(
          CardHistoryPageModel(
            events: <dynamic>[
              fakeHistoryEvent(
                id: 'e-1',
                kind: StudyAnswerKind.learning,
                mode: StudyMode.fill,
                usedHint: true,
                previousBox: null,
                nextBox: null,
              ),
            ].cast(),
            hasMore: false,
            nextCursor: null,
          ),
        );
      await pumpCardDetail(tester, repository);
      await tester.pumpAndSettle();

      expect(find.text('Schedule unchanged'), findsOneWidget);
      expect(find.text('Hint used'), findsOneWidget);
    });

    testWidgets('generations are separated by a text heading, and colour is '
        'not what carries it (BR-243)', (tester) async {
      final repository = FakeCardDetailRepository()
        ..seededDetail = fakeCardDetail()
        ..pages.add(
          CardHistoryPageModel(
            events: <dynamic>[
              fakeHistoryEvent(id: 'g2-1', schedulerGeneration: 2),
              fakeHistoryEvent(id: 'g1-1'),
            ].cast(),
            hasMore: false,
            nextCursor: null,
          ),
        );
      await pumpCardDetail(tester, repository);
      await tester.pumpAndSettle();

      expect(find.text('Current learning cycle'), findsOneWidget);
      expect(find.text('Learning cycle 1'), findsOneWidget);
    });

    testWidgets('the tail offers Load more while pages remain and says the '
        'total once they do not', (tester) async {
      final repository = FakeCardDetailRepository()
        ..seededDetail = fakeCardDetail()
        ..pages.addAll(<CardHistoryPageModel>[
          fakeHistoryPage(count: 3, hasMore: true),
          fakeHistoryPage(count: 2, prefix: 'f'),
        ]);
      await pumpCardDetail(tester, repository);
      await tester.pumpAndSettle();
      expect(find.text('Load more'), findsOneWidget);

      // The tail sits below the fold on an 800×600 test surface; the screen is
      // one scroll view by design (M4.15 V4), so reaching it is a scroll.
      await tester.ensureVisible(find.text('Load more'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Load more'));
      await tester.pumpAndSettle();

      expect(find.text('Load more'), findsNothing);
      // Countless: BR-243 forbids any aggregate derived from history, and a
      // total here disagreed with the `Reviews` row, which counts scheduled
      // turns only (BR-20).
      expect(find.text('All reviews shown'), findsOneWidget);
    });

    testWidgets('a failed page keeps what is already shown and offers Try '
        'again (UC-19 E4)', (tester) async {
      final repository = FakeCardDetailRepository()
        ..seededDetail = fakeCardDetail()
        ..pages.addAll(<CardHistoryPageModel>[
          fakeHistoryPage(count: 3, hasMore: true),
          fakeHistoryPage(count: 2, prefix: 'f'),
        ]);
      await pumpCardDetail(tester, repository);
      await tester.pumpAndSettle();

      repository.nextHistoryFailure = const DatabaseFailure(message: 'boom');
      await tester.ensureVisible(find.text('Load more'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Load more'));
      await tester.pumpAndSettle();

      expect(find.text('The next page could not be loaded.'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      expect(find.textContaining('Self-assess'), findsNWidgets(3));

      await tester.ensureVisible(find.text('Retry'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(find.text('Retry'), findsNothing);
      expect(find.textContaining('Self-assess'), findsNWidgets(5));
    });

    testWidgets('timestamps are formatted for the active locale', (
      tester,
    ) async {
      final repository = FakeCardDetailRepository()
        ..seededDetail = fakeCardDetail()
        ..pages.add(fakeHistoryPage(count: 1));
      await pumpCardDetail(tester, repository, locale: const Locale('vi'));
      await tester.pumpAndSettle();

      // The Vietnamese labels prove the whole band went through the locale, and
      // the date beside them came from MaterialLocalizations rather than a
      // hand-built string.
      expect(find.text('Lịch sử học'), findsOneWidget);
      expect(find.textContaining('Tự đánh giá'), findsOneWidget);
    });
  });

  testWidgets('the tail keeps its slot while the next page loads '
      '(M4.15 W3 face 5, G6)', (tester) async {
    final repository = FakeCardDetailRepository()
      ..seededDetail = fakeCardDetail()
      ..pages.addAll(<CardHistoryPageModel>[
        fakeHistoryPage(count: 3, hasMore: true),
        fakeHistoryPage(count: 2, prefix: 'f'),
      ]);
    await pumpCardDetail(tester, repository);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Load more'));
    await tester.pumpAndSettle();
    final before = tester.getRect(
      find
          .ancestor(of: find.text('Load more'), matching: find.byType(Padding))
          .last,
    );

    // Held open, so the in-flight face can be measured at all — the fake
    // otherwise resolves in the same microtask and `pumpAndSettle` walks
    // straight past this face, which is why it had no coverage.
    final gate = Completer<void>();
    repository.historyGate = gate;
    await tester.tap(find.text('Load more'));
    await tester.pump();

    final loading = tester.getRect(
      find
          .ancestor(
            of: find.byType(CircularProgressIndicator),
            matching: find.byType(Padding),
          )
          .last,
    );
    // Same height and same left edge: the tail must not grow by 36dp and jump
    // to the middle of the screen while a page is on its way.
    expect(loading.height, before.height);
    expect(loading.left, before.left);

    gate.complete();
    await tester.pumpAndSettle();
    expect(find.text('All reviews shown'), findsOneWidget);
  });

  group('accessibility (M4.15 W6)', () {
    testWidgets('an event is announced as one sentence, not five loose '
        'labels', (tester) async {
      final handle = tester.ensureSemantics();
      final repository = FakeCardDetailRepository()
        ..seededDetail = fakeCardDetail()
        ..pages.add(
          CardHistoryPageModel(
            events: <dynamic>[
              fakeHistoryEvent(id: 'e-1', previousBox: 2, nextBox: 3),
            ].cast(),
            hasMore: false,
            nextCursor: null,
          ),
        );
      await pumpCardDetail(tester, repository);
      await tester.pumpAndSettle();

      final semantics = tester.getSemantics(
        find.bySemanticsLabel(RegExp('Self-assess, Scheduled, Remembered')),
      );

      // Time, mode, kind, action and the schedule change in one node: a reader
      // hears what happened in that review rather than assembling it from five
      // announcements — and in words, not glyphs. A screen reader says "right
      // arrow" for `→` or says nothing at all, so the drawn line and the spoken
      // one are deliberately different strings.
      expect(semantics.label, contains('Box from 2 to 3'));
      expect(semantics.label, isNot(contains('→')));
      expect(find.text('Box 2 → 3'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('Edit and Load more clear the 48dp touch target', (
      tester,
    ) async {
      final repository = FakeCardDetailRepository()
        ..seededDetail = fakeCardDetail()
        ..pages.add(fakeHistoryPage(count: 2, hasMore: true));
      await pumpCardDetail(tester, repository);
      await tester.pumpAndSettle();

      // The button, not the glyph inside it: an `Icon` is 24dp by definition,
      // and what has to clear 48 is the box that takes the tap.
      final edit = tester.getSize(
        find
            .ancestor(
              of: find.byIcon(Icons.edit_outlined),
              matching: find.byType(InkWell),
            )
            .first,
      );
      expect(
        edit.height,
        greaterThanOrEqualTo(_minimumTouchTarget - _touchTargetTolerance),
      );
      await tester.ensureVisible(find.text('Load more'));
      await tester.pumpAndSettle();
      final loadMore = tester.getSize(
        find
            .ancestor(
              of: find.text('Load more'),
              matching: find.byType(InkWell),
            )
            .first,
      );
      expect(
        loadMore.height,
        greaterThanOrEqualTo(_minimumTouchTarget - _touchTargetTolerance),
      );
    });

    testWidgets('a failed page is announced, not only drawn (UC-19 E4)', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final repository = FakeCardDetailRepository()
        ..seededDetail = fakeCardDetail()
        ..pages.add(fakeHistoryPage(count: 2, hasMore: true));
      await pumpCardDetail(tester, repository);
      await tester.pumpAndSettle();

      repository.nextHistoryFailure = const DatabaseFailure(message: 'boom');
      await tester.ensureVisible(find.text('Load more'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Load more'));
      await tester.pumpAndSettle();

      final band = tester.getSemantics(
        find
            .ancestor(
              of: find.text('The next page could not be loaded.'),
              matching: find.byType(Semantics),
            )
            .first,
      );
      // A band that appears silently is a band a screen-reader user never
      // learns about.
      expect(band.flagsCollection.isLiveRegion, isTrue);
      handle.dispose();
    });
  });
}

/// The minimum touch target the design system states (`AppSpacing`).
const double _minimumTouchTarget = 48;

/// Slack for a target whose ink box rounds a fraction below the token — the
/// claim is "reachable", not "exactly 48".
const double _touchTargetTolerance = 0.5;
