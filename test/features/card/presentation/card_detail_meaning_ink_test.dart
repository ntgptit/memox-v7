import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/card/domain/models/card_history_page_model.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_detail_summary_widget.dart';

import 'support/card_detail_harness.dart';
import 'support/fake_card_detail_repository.dart';

/// The meaning is the answer, so it is not the quietest thing on the card.
///
/// **The inversion this pins** (SC-C9-11). The back took `AppInk.quiet` — the
/// same ink as the `Example` / `Hint` / `Pronunciation` *labels* below it, and
/// one step lighter than those labels' un-inked values — so on the read-only
/// screen that exists to show what a card means (BR-240), the optional
/// supporting fields out-weighed the meaning. Measured through this harness:
/// front `onSurface` 24sp, back `onSurfaceVariant` 14sp, labels
/// `onSurfaceVariant` 11sp, values `onSurface` 14sp.
///
/// **Written as a relation, not as a colour.** "The back is `onSurface`" would
/// pass on a theme where every ink collapses to one value; "the back is not
/// lighter than the field values under it" is the property that was actually
/// broken, and it survives a re-theme.
void main() {
  FakeCardDetailRepository loaded() => FakeCardDetailRepository()
    ..seededDetail = fakeCardDetail(
      front: '사과',
      back: 'quả táo',
      example: '사과를 먹어요',
      hint: 'a fruit',
      pronunciation: 'sa-gwa',
    )
    ..pages.add(CardHistoryPageModel.empty);

  Color inkOf(WidgetTester tester, String text) => tester
      .widget<Text>(
        find.descendant(
          of: find.byType(CardDetailSummaryWidget),
          matching: find.text(text),
        ),
      )
      .style!
      .color!;

  testWidgets('the back outranks the optional fields it sits above', (
    tester,
  ) async {
    await pumpCardDetail(tester, loaded());
    await tester.pumpAndSettle();

    final scheme = Theme.of(
      tester.element(find.byType(CardDetailSummaryWidget)),
    ).colorScheme;

    // The meaning now carries the same ink as the front it answers, and as
    // the field values below — which is the row the card list already paints
    // this string at.
    expect(inkOf(tester, 'quả táo'), scheme.onSurface);
    expect(inkOf(tester, 'a fruit'), scheme.onSurface);

    // And the field *labels* stay the only quiet text in the band, which is
    // what keeps them reading as labels.
    expect(inkOf(tester, 'quả táo'), isNot(inkOf(tester, 'Hint')));
  });

  testWidgets('the hierarchy is still carried by rung, not by colour', (
    tester,
  ) async {
    await pumpCardDetail(tester, loaded());
    await tester.pumpAndSettle();

    final texts = Theme.of(
      tester.element(find.byType(CardDetailSummaryWidget)),
    ).textTheme;

    final front = tester.widget<Text>(
      find.descendant(
        of: find.byType(CardDetailSummaryWidget),
        matching: find.text('사과'),
      ),
    );
    final back = tester.widget<Text>(
      find.descendant(
        of: find.byType(CardDetailSummaryWidget),
        matching: find.text('quả táo'),
      ),
    );

    // 24sp over 14sp. Giving the back a darker ink does not flatten the hero,
    // because the hero never got its hierarchy from the colour step.
    expect(front.style!.fontSize, texts.headlineSmall!.fontSize);
    expect(back.style!.fontSize, texts.bodyMedium!.fontSize);
    expect(front.style!.fontSize, greaterThan(back.style!.fontSize!));
  });
}
