import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_spacing.dart';
import 'package:memox/features/card/domain/models/card_history_page_model.dart';
import 'package:memox/features/card/presentation/widgets/items/card_history_event_widget.dart';

import 'support/card_detail_harness.dart';
import 'support/fake_card_detail_repository.dart';

/// The geometry contract of the detail screen (M4.14 W5).
///
/// **Measured with `getRect`, not eyeballed.** Every claim here is one a golden
/// cannot make: a golden says "these pixels", which changes whenever anything
/// legitimately changes, while "the state band starts at the same x as the
/// content band" survives a restyle and fails exactly when the layout drifts.
void main() {
  FakeCardDetailRepository loaded({int events = 3, bool hasMore = false}) =>
      FakeCardDetailRepository()
        ..seededDetail = fakeCardDetail(
          front: '안녕하세요',
          back: 'hello',
          example: 'an example sentence',
          tagNames: <String>['greeting'],
          currentBox: 3,
          // Distinct counts, so a value can be found by its own text: with both
          // at zero the finder matches two widgets and the assertion is about
          // whichever one it happened to pick.
          answerCount: 7,
          lapseCount: 1,
        )
        ..pages.add(
          events == 0
              ? CardHistoryPageModel.empty
              : fakeHistoryPage(count: events, hasMore: hasMore),
        );

  testWidgets('G1 · content, state and history share one left edge', (
    tester,
  ) async {
    await pumpCardDetail(tester, loaded());
    await tester.pumpAndSettle();

    final front = tester.getRect(find.text('안녕하세요'));
    final stateHeading = tester.getRect(find.text('Current state'));
    final historyHeading = tester.getRect(find.text('Study history'));

    expect(stateHeading.left, front.left);
    expect(historyHeading.left, front.left);
  });

  testWidgets('G2 · every value of the schedule grid starts at the same x', (
    tester,
  ) async {
    await pumpCardDetail(tester, loaded());
    await tester.pumpAndSettle();

    final dueLabel = tester.getRect(find.text('Due'));
    final reviewsLabel = tester.getRect(find.text('Reviews'));
    final reviews = tester.getRect(find.text('7'));

    // Labels share a left edge, and the value column clears the widest label —
    // a value column that started where each label happened to end would zigzag
    // down the grid.
    expect(reviewsLabel.left, dueLabel.left);
    expect(reviews.left, greaterThan(reviewsLabel.right));
  });

  testWidgets('G4 · every event text starts at the same x', (tester) async {
    await pumpCardDetail(tester, loaded());
    await tester.pumpAndSettle();

    final lines = find.textContaining('Self-assess · Scheduled');
    expect(lines, findsNWidgets(3));
    final lefts = <double>{
      for (var index = 0; index < 3; index++)
        tester.getRect(lines.at(index)).left,
    };

    // One x for every event, whatever it carries: a two-line event and a
    // four-line one must not indent differently.
    expect(lefts, hasLength(1));
  });

  for (final scale in <double>[1, 2]) {
    testWidgets('G3 · the marker sits on the first line at ${scale}x', (
      tester,
    ) async {
      await pumpCardDetail(tester, loaded(), textScale: scale);
      await tester.pumpAndSettle();

      // The event's first line is its timestamp, whatever the locale formats
      // it as — matching the text itself would pin the test to a date format.
      final timestamp = tester.getRect(
        find
            .descendant(
              of: find.byType(CardHistoryEventWidget).first,
              matching: find.byType(Text),
            )
            .first,
      );
      final marker = tester.getRect(
        find
            .descendant(
              of: find.byType(CardHistoryEventWidget).first,
              matching: find.byType(Container),
            )
            .first,
      );

      // Centred on the timestamp's line, not on the row: rows differ in height
      // with how many schedule lines they carry, and an inset that does not
      // scale leaves the dot floating above the text at 2.0.
      expect((marker.center.dy - timestamp.center.dy).abs(), lessThan(2));
    });
  }

  testWidgets('G6 · the tail sits on the same left edge as the events above '
      'it', (tester) async {
    await pumpCardDetail(tester, loaded(hasMore: true));
    await tester.pumpAndSettle();

    final heading = tester.getRect(find.text('Study history'));
    await tester.ensureVisible(find.text('Load more'));
    await tester.pumpAndSettle();
    final loadMore = tester.getRect(find.text('Load more'));

    // The tail sits on the band's own edge, not centred and not indented into
    // the events' text column — the marker column is the timeline's, and the
    // tail is not an event. The loading and error faces that replace it inherit
    // the slot, which `card_detail_history_faces_test.dart` measures.
    expect(loadMore.left, heading.left);
  });

  testWidgets('the schedule grid stacks rather than squeezing its value '
      'column at 320dp with 2.0 text', (tester) async {
    await pumpCardDetail(
      tester,
      loaded(),
      surfaceSize: const Size(320, 640),
      textScale: 2,
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    final dueLabel = tester.getRect(find.text('Due'));
    // `Due` and `Learned` share the placeholder, so the finder matches twice;
    // the first is the one under `Due`.
    final dueValue = tester.getRect(find.text('Not scheduled yet').first);

    // Side by side, the scaled label column would be 232 of the 288 available
    // and leave 44dp — less than one word at this scale, laid out past its
    // column with nothing throwing. Stacked, the value gets the whole width.
    expect(dueValue.left, dueLabel.left);
    expect(dueValue.width, greaterThan(120));
  });

  testWidgets('the schedule grid stays two columns where they fit', (
    tester,
  ) async {
    await pumpCardDetail(tester, loaded(), surfaceSize: const Size(390, 844));
    await tester.pumpAndSettle();

    final reviewsLabel = tester.getRect(find.text('Reviews'));
    final reviews = tester.getRect(find.text('7'));

    // The stacked fallback must not become the only path — at a normal scale
    // the pair fits and G2's alignment is what the grid is for. (At 2.0 even
    // 390 stacks: the scaled label column is 232 of 358, which is past the
    // threshold. That is the fallback doing its job, not a regression.)
    expect(reviews.left, greaterThan(reviewsLabel.right));
  });

  testWidgets('the screen narrows to the compact gutter below 360dp', (
    tester,
  ) async {
    await pumpCardDetail(tester, loaded(), surfaceSize: const Size(320, 640));
    await tester.pumpAndSettle();

    // `mxScreenGutter`, the same helper every other screen takes its gutter
    // from — a hardcoded 16 here put this screen 4dp wider than the list it is
    // opened from, on the width where those 4dp matter most.
    expect(tester.getRect(find.text('안녕하세요')).left, AppSpacing.md);
  });
}
