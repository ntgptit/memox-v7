import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/study/presentation/widgets/items/match_tile_widget.dart';

import 'support/study_widget_harness.dart';

/// The board's two columns are two voices, and the tile is where that is decided.
///
/// **The golden could not have caught this on its own.** For as long as the
/// fixture gave every card a two-word meaning, term and meaning rendered at the
/// same length in the same weight and the picture looked deliberate — the board
/// only revealed itself once one card carried the gloss BR-08 actually allows.
/// These assertions hold the decision without needing that card to be present.
void main() {
  const term = '부끄러워하다';
  const meaning =
      'Be shy / Ngượng ngùng (Động từ, thể hiện sự e ngại trong giao tiếp)';

  Text textOf(WidgetTester tester, String data) =>
      tester.widget<Text>(find.text(data));

  TextTheme themeOf(WidgetTester tester) =>
      Theme.of(tester.element(find.byType(MatchTileWidget))).textTheme;

  Future<void> pumpTile(
    WidgetTester tester, {
    required String text,
    required bool isTerm,
    double? height,
  }) async {
    final tile = MatchTileWidget(
      text: text,
      state: MatchTileState.idle,
      onTap: () {},
      isTerm: isTerm,
    );

    await tester.pumpWidget(
      wrapForTest(
        height == null ? tile : SizedBox(height: height, child: tile),
      ),
    );
  }

  testWidgets('a term is the scanned voice: titleLarge, medium, two lines', (
    tester,
  ) async {
    await pumpTile(tester, text: term, isTerm: true);

    final style = textOf(tester, term).style!;
    expect(style.fontSize, themeOf(tester).titleLarge!.fontSize);
    expect(style.fontWeight, FontWeight.w500);
    expect(textOf(tester, term).maxLines, 2);
  });

  testWidgets('a meaning is the read voice: bodyMedium, regular, four lines', (
    tester,
  ) async {
    await pumpTile(tester, text: meaning, isTerm: false);

    final style = textOf(tester, meaning).style!;
    expect(style.fontSize, themeOf(tester).bodyMedium!.fontSize);
    expect(style.fontWeight, FontWeight.w400);
    expect(textOf(tester, meaning).maxLines, 4);
  });

  testWidgets('the term reads larger than the meaning it explains', (
    tester,
  ) async {
    // Stated as a relation rather than two numbers, because the hierarchy is
    // the decision — the roles may be retuned, the order may not invert.
    await pumpTile(tester, text: term, isTerm: true);
    final termSize = textOf(tester, term).style!.fontSize!;

    await pumpTile(tester, text: meaning, isTerm: false);
    final meaningSize = textOf(tester, meaning).style!.fontSize!;

    expect(termSize, greaterThan(meaningSize));
  });

  testWidgets('a meaning too long for its slot ellipsises, never overflows', (
    tester,
  ) async {
    // A tile's height belongs to the grid, so the longest meaning BR-08 admits
    // has to give way inside it. An overflow here would paint the board's own
    // stripe across a screen the user is meant to be reading.
    await pumpTile(tester, text: meaning, isTerm: false, height: 96);

    expect(tester.takeException(), isNull);
    expect(textOf(tester, meaning).overflow, TextOverflow.ellipsis);
  });
}
