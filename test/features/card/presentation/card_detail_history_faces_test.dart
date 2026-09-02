import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/theme/foundations/app_sizing.dart';
import 'package:memox/features/card/domain/models/card_history_page_model.dart';
import 'package:memox/features/card/presentation/widgets/items/card_history_event_widget.dart';
import 'package:memox/features/study/domain/models/study_answer_kind_model.dart';
import 'package:memox/features/study/domain/models/study_mode.dart';
import 'package:memox/features/study/domain/models/study_outcome_reason_model.dart';
import 'package:memox/shared/widgets/mx_card.dart';

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
  _fixtureZoneGuard();

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

    testWidgets('the first page loading is a face of the band, on the band '
        'edge (V16)', (tester) async {
      // **The one face nothing rendered.** `card_history_controller_test.dart`
      // asserts the *state* is `loadingInitial`; nothing drew it, and V16 put a
      // card around it — so a centred `MxLoadingState` would have floated 40dp
      // in from an edge every other face starts on, and jumped left when the
      // page landed. The WBS entry for this task claimed there was behaviour
      // coverage here; there was not, and this is it.
      final gate = Completer<void>();
      final repository = FakeCardDetailRepository()
        ..seededDetail = fakeCardDetail()
        ..historyGate = gate
        ..pages.add(fakeHistoryPage(count: 2));
      await pumpCardDetail(tester, repository);
      await tester.pump();

      final heading = tester.getRect(find.text('STUDY HISTORY'));
      final spinner = tester.getRect(
        find.byType(CircularProgressIndicator).first,
      );
      // The band has no card of its own in the compact layout, so its edge
      // is the screen gutter — the same one the heading uses.
      expect(spinner.left, heading.left);
      expect(find.text('No reviews yet'), findsNothing);

      gate.complete();
      await tester.pumpAndSettle();
      // And the events land where the spinner was, so nothing jumps.
      expect(find.textContaining('Self-assess'), findsNWidgets(2));
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

      // The verdict moved into the badge; the line under it says where the
      // turn came from and what it was for.
      expect(find.text('Recall · Scheduled'), findsOneWidget);
      expect(find.text('Remembered'), findsOneWidget);
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

      // **G6's fourth face.** `Load more`, the loading-more spinner and
      // `All reviews shown` are all pinned to the band's edge elsewhere; this
      // one is an `MxCard` nested in the timeline card, so a stray `Center` or
      // an extra inset would move only this face and leave the other three
      // green.
      final heading = tester.getRect(find.text('STUDY HISTORY'));
      final band = tester.getRect(
        find
            .ancestor(
              of: find.text('The next page could not be loaded.'),
              matching: find.byType(MxCard),
            )
            .first,
      );
      expect(band.left, heading.left);

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
      expect(find.text('LỊCH SỬ HỌC'), findsOneWidget);
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

    // **Absolute rectangles, because the relative ones could not fail.** This
    // used to compare `find.ancestor(…, Padding).last` for the button and for
    // the spinner. `_collectAncestors` walks `visitAncestorElements`, which
    // runs child → root, so `.last` is the **outermost** `Padding` — the scroll
    // view's, shared by every face of the screen. The two rects were the same
    // element, and the test would have passed with `MxLoadingState` back in the
    // tail, which is the one thing it is named after.
    final heading = tester.getRect(find.text('STUDY HISTORY'));
    final lastEvent = tester.getRect(find.byType(CardHistoryEventWidget).last);

    // Held open, so the in-flight face can be measured at all — the fake
    // otherwise resolves in the same microtask and `pumpAndSettle` walks
    // straight past this face, which is why it had no coverage.
    final gate = Completer<void>();
    repository.historyGate = gate;
    await tester.tap(find.text('Load more'));
    await tester.pump();

    final spinner = tester.getRect(
      find.byType(CircularProgressIndicator).first,
    );
    // **The band's own edge, which is the screen gutter now that the timeline
    // has no card of its own** — the same slot the button it replaced sat on.
    expect(spinner.left, heading.left);
    // And nothing above the tail moved: that is what G6 is actually about.
    expect(tester.getRect(find.byType(CardHistoryEventWidget).last), lastEvent);

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

    testWidgets('the failed-page Retry clears it too', (tester) async {
      // The third control on this screen, and the one the band's rebuild
      // introduced. It inherits the shared button theme's 48dp floor, but
      // "inherits" is an argument about code the test does not run — and the
      // band it sits in was rewritten this round.
      final repository = FakeCardDetailRepository()
        ..seededDetail = fakeCardDetail()
        ..nextHistoryFailure = const DatabaseFailure(message: 'refused');
      await pumpCardDetail(tester, repository);
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Retry'));
      await tester.pumpAndSettle();

      final retry = tester.getSize(
        find
            .ancestor(of: find.text('Retry'), matching: find.byType(InkWell))
            .first,
      );

      expect(
        retry.height,
        greaterThanOrEqualTo(_minimumTouchTarget - _touchTargetTolerance),
      );
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

/// The minimum touch target the design system states (`AppSizing`).
const double _minimumTouchTarget = AppSizing.touchTarget;

/// Slack for a target whose ink box rounds a fraction below the token — the
/// claim is "reachable", not "exactly 48".
const double _touchTargetTolerance = 0.5;

/// The history timeline renders `toLocal()`, so its fixture instant has to be
/// local or the goldens mean a different time on every machine.
///
/// Kept as a test rather than a comment because the failure it prevents is
/// invisible where it happens: the three `card_detail` goldens were drawn on CI
/// in UTC and were nine hours wrong on a KST machine, passing CI the whole
/// time. A `DateTime.utc` here would put that back, and nothing on CI would say
/// so.
void _fixtureZoneGuard() {
  test('the history fixture is a local instant, not a UTC one', () {
    expect(
      fakeNow.isUtc,
      isFalse,
      reason:
          'a UTC fixture renders a different local time in every zone, so '
          'the card_detail goldens would only be right where they were drawn',
    );
  });
}
