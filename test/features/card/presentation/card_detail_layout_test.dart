import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_spacing.dart';
import 'package:memox/features/card/domain/models/card_history_page_model.dart';
import 'package:memox/features/card/presentation/widgets/items/card_box_progress_widget.dart';
import 'package:memox/features/card/presentation/widgets/items/card_history_event_widget.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_detail_summary_widget.dart';
import 'package:memox/features/deck/domain/models/scheduler_type_model.dart';

import 'support/card_detail_geometry.dart';
import 'support/card_detail_harness.dart';
import 'support/fake_card_detail_repository.dart';

/// The geometry relations that are about one particular width, locale or
/// fixture rather than about all three viewports (W5 G7…G12).
///
/// Split from `card_detail_alignment_test.dart` when that file crossed the
/// guard's size ceiling; the fixtures and finders both use live in
/// `support/card_detail_geometry.dart`, so the two cannot drift apart.
void main() {
  testWidgets('the metric grid is two columns where two fit', (tester) async {
    await pumpCardDetail(tester, loaded(), surfaceSize: const Size(390, 844));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Reviews'));
    await tester.pumpAndSettle();

    final due = tester.getRect(find.text('Due'));
    final learned = tester.getRect(find.text('Learned'));
    final lastAnswered = tester.getRect(find.text('Last answered'));

    // Two across: the second cell of a row starts to the right of the first,
    // and the third wraps back to the first column's edge.
    expect(learned.left, greaterThan(due.right));
    expect(lastAnswered.left, due.left);
    expect(lastAnswered.top, greaterThan(due.bottom));
  });

  testWidgets('the metric grid drops to one column at 320dp with 2.0 text', (
    tester,
  ) async {
    await pumpCardDetail(
      tester,
      loaded(),
      surfaceSize: const Size(320, 640),
      textScale: 2,
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Learned'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    final panel = tester.getRect(progressPanel());
    final due = tester.getRect(find.text('Due'));
    final learned = tester.getRect(find.text('Learned'));

    // One under the other, both on the panel's inner edge, and the value beside
    // each still inside the panel — a second column here would leave a cell
    // narrower than one word of `bodyMedium` at this scale.
    expect(learned.left, due.left);
    expect(learned.top, greaterThan(due.bottom));
    expect(
      tester.getRect(find.text('Not scheduled yet').first).right,
      lessThanOrEqualTo(panel.right - AppSpacing.lg),
    );
  });

  testWidgets('sm2 shows its own three metrics and no box track', (
    tester,
  ) async {
    await pumpCardDetail(
      tester,
      loaded(scheduler: SchedulerType.sm2, currentBox: null),
      surfaceSize: const Size(390, 844),
    );
    await tester.pumpAndSettle();

    expect(find.byType(CardBoxProgressWidget), findsNothing);
    await tester.ensureVisible(find.text('Repetitions'));
    await tester.pumpAndSettle();
    for (final label in <String>['Ease', 'Interval', 'Repetitions']) {
      expect(find.text(label), findsOneWidget);
    }
  });

  testWidgets('G5 · a generation boundary opens wider than the gap between two '
      'events', (tester) async {
    final repository = FakeCardDetailRepository()
      ..seededDetail = fakeCardDetail()
      ..pages.add(
        CardHistoryPageModel(
          events: <dynamic>[
            fakeHistoryEvent(id: 'g2-1', schedulerGeneration: 2),
            fakeHistoryEvent(id: 'g1-1'),
            fakeHistoryEvent(id: 'g1-2'),
          ].cast(),
          hasMore: false,
          nextCursor: null,
        ),
      );
    await pumpCardDetail(tester, repository, surfaceSize: const Size(390, 844));
    await tester.pumpAndSettle();

    final events = find.byType(CardHistoryEventWidget);
    final acrossGroups =
        tester.getRect(events.at(1)).top - tester.getRect(events.at(0)).bottom;
    final withinGroup =
        tester.getRect(events.at(2)).top - tester.getRect(events.at(1)).bottom;

    // The heading and its own gaps sit in the first measurement and not in the
    // second, which is what makes a reset read as a break rather than as one
    // more review.
    expect(acrossGroups, greaterThan(withinGroup));
  });

  for (final inset in <double>[0, 34]) {
    testWidgets('G7 · the last thing in the scroll clears the bottom inset, '
        'with a ${inset}dp system bar', (tester) async {
      await pumpCardDetail(
        tester,
        loaded(),
        surfaceSize: const Size(390, 844),
        bottomInset: inset,
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('All reviews shown'));
      await tester.pumpAndSettle();

      final tail = tester.getRect(find.text('All reviews shown'));
      final scroll = tester.getRect(find.byType(SingleChildScrollView));

      // `lg` at the foot (D21). **What this measures and what it does not:**
      // with a real `viewPadding.bottom` it proves the scroll view stops above
      // the system inset rather than running under it. It does not measure the
      // app's bottom navigation — this harness mounts the screen under a bare
      // router, not under the shell.
      expect(tail.bottom, lessThanOrEqualTo(scroll.bottom - AppSpacing.lg));
      expect(scroll.bottom, lessThanOrEqualTo(844 - inset));
    });
  }

  testWidgets('the summary keeps the badge clear of the term', (tester) async {
    for (final size in const <Size>[Size(390, 844), Size(412, 915)]) {
      await pumpCardDetail(tester, loaded(), surfaceSize: size);
      await tester.pumpAndSettle();

      // Scoped to the hero: the progress panel names its box too, and an
      // ambiguous finder would be measuring whichever one it happened to pick.
      // The pill, not the word inside it: the label is followed by the
      // position and then by the pill's own padding, so measuring the `Text`
      // would be measuring the wrong rectangle by ~39dp.
      final badge = tester.getRect(
        find
            .ancestor(
              of: find.descendant(
                of: find.byType(CardDetailSummaryWidget),
                matching: find.text('Box'),
              ),
              matching: find.byType(Container),
            )
            .first,
      );
      final hero = tester.getRect(heroCard());

      // **The trailing edge, always.** The badge used to ride on a `Wrap` whose
      // run was decided by the meaning's width, so a long back pushed it onto
      // its own line at the *leading* edge — beside the flag chip, reading as
      // one more mark. A `Row` anchors it, so this is now a fixed relation
      // rather than a lucky one.
      expect(
        badge.right,
        closeTo(hero.right - AppSpacing.lg, 1),
        reason: 'the badge left the trailing inset of the hero',
      );
      expect(badge.left, greaterThan(hero.left + AppSpacing.lg));
    }
  });

  testWidgets('the event timestamp closes on the card, not on the badge', (
    tester,
  ) async {
    await pumpCardDetail(tester, loaded(), surfaceSize: const Size(390, 844));
    await tester.pumpAndSettle();

    final card = tester.getRect(eventCards().first);
    final timestamp = tester.getRect(
      find.descendant(
        of: find.byType(CardHistoryEventWidget).first,
        matching: find.textContaining('9:41'),
      ),
    );

    // **The relation the `SizedBox(width: double.infinity)` exists for.** A
    // `Wrap` under a start-aligned `Column` shrinks to its content, so
    // `spaceBetween` silently did nothing and the timestamp sat against the
    // badge — 107dp short of here. Nothing but a golden noticed.
    expect(timestamp.right, closeTo(card.right - AppSpacing.md, 1));
  });

  testWidgets('the badge holds the trailing edge in Vietnamese at 320dp and '
      '2.0, and under a long term', (tester) async {
    for (final repository in <FakeCardDetailRepository>[
      loaded(),
      FakeCardDetailRepository()
        ..seededDetail = fakeCardDetail(
          front: '만나서 반갑습니다 반갑습니다',
          back: 'rất vui được gặp bạn, một câu chào dài để ép xuống nhiều dòng',
          currentBox: 3,
        )
        ..pages.add(CardHistoryPageModel.empty),
    ]) {
      await pumpCardDetail(
        tester,
        repository,
        locale: const Locale('vi'),
        surfaceSize: const Size(320, 640),
        textScale: 2,
      );
      await tester.pumpAndSettle();

      // The badge used to ride on a `Wrap` whose run was decided by the
      // *meaning*'s width, so a long back dropped it to the leading edge of its
      // own line. The narrowest surface with the longest locale is where that
      // would show first.
      final hero = tester.getRect(heroCard());
      final badge = tester.getRect(
        find
            .ancestor(
              of: find.descendant(
                of: find.byType(CardDetailSummaryWidget),
                matching: find.text('Hộp'),
              ),
              matching: find.byType(Container),
            )
            .first,
      );
      expect(badge.right, closeTo(hero.right - AppSpacing.lg, 1));
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('the state run reflows instead of overflowing at 320dp with 2.0 '
      'text', (tester) async {
    await pumpCardDetail(
      tester,
      loaded(isFlagged: true),
      locale: const Locale('vi'),
      surfaceSize: const Size(320, 640),
      textScale: 2,
    );
    await tester.pumpAndSettle();

    // Neither the flag chip nor a tag wraps its own text, so the run is the one
    // thing standing between the longest Vietnamese pair and a right overflow —
    // and an overflow here throws rather than clipping.
    expect(tester.takeException(), isNull);
    expect(
      tester.getRect(find.text('Đã đánh dấu')).right,
      lessThanOrEqualTo(tester.getRect(heroCard()).right),
    );
  });

  testWidgets('the connector runs unbroken between two events of one '
      'generation', (tester) async {
    await pumpCardDetail(tester, loaded(), surfaceSize: const Size(390, 844));
    await tester.pumpAndSettle();

    // The line above a dot and the line below the dot before it are separate
    // widgets, so "unbroken" is a claim about two rectangles meeting.
    final first = find.byType(CardHistoryEventWidget).at(0);
    final second = find.byType(CardHistoryEventWidget).at(1);
    // **By colour, not by position.** The event card holds `Container`s of its
    // own now — the badge is one — so "the last container in the row" is no
    // longer a piece of the connector.
    Rect segment(Finder row, bool wantLast) {
      final finder = find.descendant(of: row, matching: find.byType(Container));
      final rects = <Rect>[];
      for (var index = 0; index < tester.widgetList(finder).length; index++) {
        final container = tester.widget<Container>(finder.at(index));
        if (container.color != null) {
          rects.add(tester.getRect(finder.at(index)));
        }
      }

      return wantLast ? rects.last : rects.first;
    }

    final trailing = segment(first, true).bottom;
    final leading = segment(second, false).top;

    expect(leading, lessThanOrEqualTo(trailing + 0.5));
  });
}
