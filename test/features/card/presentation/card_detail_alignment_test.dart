import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/features/card/presentation/widgets/items/card_box_progress_widget.dart';
import 'package:memox/features/card/presentation/widgets/items/card_history_event_widget.dart';
import 'package:memox/shared/widgets/mx_card.dart';

import 'support/card_detail_geometry.dart';
import 'support/card_detail_harness.dart';

/// The geometry contract of the compact-history layout, measured across the
/// three widths M4.15 W6 names (W5 G1…G6).
///
/// **Measured with `getRect`, not eyeballed.** A golden says "these pixels",
/// which changes whenever anything legitimately changes; "the progress panel and
/// the summary share one pair of outer edges" survives a restyle and fails
/// exactly when the layout drifts.
///
/// The relations that need one specific viewport rather than all three live in
/// `card_detail_layout_test.dart`, split off when this file crossed the guard's
/// size ceiling.
void main() {
  for (final (name, size, scale) in surfaces) {
    group('at $name', () {
      testWidgets('G1 · the summary and the progress panel share one pair of '
          'outer edges, and every event card shares the trailing one', (
        tester,
      ) async {
        await pumpCardDetail(
          tester,
          loaded(),
          surfaceSize: size,
          textScale: scale,
        );
        await tester.pumpAndSettle();

        // `mxScreenGutter`: `md` below 360dp, `lg` at or above it — the same
        // helper every other screen takes its gutter from.
        final gutter = size.width < 360 ? AppSpacing.md : AppSpacing.lg;
        final hero = tester.getRect(heroCard());
        final panel = tester.getRect(progressPanel());
        expect(hero.left, gutter);
        expect(panel.left, gutter);
        expect(hero.right, size.width - gutter);
        expect(panel.right, size.width - gutter);

        // **An event card is inset on the leading side and only there.** The
        // marker and its connector live in that inset — outside the card, as the
        // concept draws them — so the timeline's cards line up with each other
        // and close on the same trailing edge as the two bands above.
        final cards = tester.widgetList<MxCard>(eventCards()).length;
        expect(cards, 3);
        final lefts = <double>{};
        for (var index = 0; index < 3; index++) {
          final card = tester.getRect(eventCards().at(index));
          lefts.add(card.left);
          expect(card.right, size.width - gutter);
        }
        expect(lefts, hasLength(1));
        expect(lefts.single, greaterThan(gutter));
      });

      testWidgets('G1 · both section headers sit on the outer edge', (
        tester,
      ) async {
        await pumpCardDetail(
          tester,
          loaded(),
          surfaceSize: size,
          textScale: scale,
        );
        await tester.pumpAndSettle();

        final hero = tester.getRect(heroCard());
        final stateHeading = tester.getRect(find.text('CURRENT STATE'));
        await tester.ensureVisible(find.text('STUDY HISTORY'));
        await tester.pumpAndSettle();
        final historyHeading = tester.getRect(find.text('STUDY HISTORY'));

        // A heading titles the surface under it rather than living inside it,
        // so it lines up with the card's edge and not with the card's content.
        expect(stateHeading.left, hero.left);
        expect(historyHeading.left, hero.left);
      });

      testWidgets('the summary insets its content by one `lg`', (tester) async {
        await pumpCardDetail(
          tester,
          loaded(),
          surfaceSize: size,
          textScale: scale,
        );
        await tester.pumpAndSettle();

        expect(
          tester.getRect(find.text('안녕하세요')).left,
          tester.getRect(heroCard()).left + AppSpacing.lg,
        );
      });

      testWidgets('the eight-box track spends the panel evenly', (
        tester,
      ) async {
        await pumpCardDetail(
          tester,
          loaded(),
          surfaceSize: size,
          textScale: scale,
        );
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.byType(CardBoxProgressWidget));
        await tester.pumpAndSettle();

        final track = tester.getRect(find.byType(CardBoxProgressWidget));
        final panel = tester.getRect(progressPanel());
        // The track runs the full inner width, so its first and last steps sit
        // on the same edges as every other row of the panel.
        expect(track.left, panel.left + AppSpacing.lg);
        expect(track.right, panel.right - AppSpacing.lg);

        final steps = tester
            .widgetList<Container>(
              find.descendant(
                of: find.byType(CardBoxProgressWidget),
                matching: find.byType(Container),
              ),
            )
            .length;
        expect(steps, 8, reason: 'eight boxes, from the scheduler contract');

        final widths = <double>{};
        for (var index = 0; index < 8; index++) {
          widths.add(
            tester
                .getRect(
                  find
                      .descendant(
                        of: find.byType(CardBoxProgressWidget),
                        matching: find.byType(Container),
                      )
                      .at(index),
                )
                .width
                // Rounded, because `Expanded` distributes a remainder of a few
                // hundredths of a pixel and eight equal steps is a claim about
                // the design, not about float arithmetic.
                .roundToDouble(),
          );
        }
        expect(widths, hasLength(1));
      });

      testWidgets('G4 · every event card starts its text at the same x', (
        tester,
      ) async {
        await pumpCardDetail(
          tester,
          loaded(),
          surfaceSize: size,
          textScale: scale,
        );
        await tester.pumpAndSettle();

        final lines = find.textContaining('Self-assess');
        expect(lines, findsNWidgets(3));
        final lefts = <double>{
          for (var index = 0; index < 3; index++)
            tester.getRect(lines.at(index)).left,
        };
        expect(lefts, hasLength(1));
      });

      testWidgets(
        'G3 · the marker sits on the badge line, not the row centre',
        (tester) async {
          await pumpCardDetail(
            tester,
            loaded(),
            surfaceSize: size,
            textScale: scale,
          );
          await tester.pumpAndSettle();

          final row = find.byType(CardHistoryEventWidget).first;
          final badge = tester.getRect(find.text('Remembered').first);
          final marker = tester
              .widgetList<Container>(
                find.descendant(of: row, matching: find.byType(Container)),
              )
              .toList();
          final dotIndex = marker.indexWhere(
            (container) =>
                container.decoration is BoxDecoration &&
                (container.decoration! as BoxDecoration).shape ==
                    BoxShape.circle,
          );
          final dot = tester.getRect(
            find
                .descendant(of: row, matching: find.byType(Container))
                .at(dotIndex),
          );

          // Rows differ in height with how many schedule lines they carry, so a
          // dot centred on the row would wander down the connector as they do.
          expect((dot.center.dy - badge.center.dy).abs(), lessThan(4));
        },
      );

      testWidgets('G6 · the tail sits on the screen gutter, like the heading', (
        tester,
      ) async {
        await pumpCardDetail(
          tester,
          loaded(hasMore: true),
          surfaceSize: size,
          textScale: scale,
        );
        await tester.pumpAndSettle();

        final heading = tester.getRect(find.text('STUDY HISTORY'));
        await tester.ensureVisible(find.text('Load more'));
        await tester.pumpAndSettle();

        // The band has no card of its own any more, so its tail is back on the
        // screen's gutter — the same edge the heading uses.
        expect(tester.getRect(find.text('Load more')).left, heading.left);
      });
    });
  }
}
