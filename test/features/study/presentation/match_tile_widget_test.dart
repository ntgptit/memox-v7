import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_spacing.dart';
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
  const term = '민망하다';
  const meaning =
      'Embarrassed, awkward / Ngại, khó xử, bối rối vì tình huống (Tính từ, '
      'dùng khi tình huống trở nên awkward hoặc khiến mình thấy ngại)';

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

  testWidgets('a term is the scanned voice: titleMedium, medium, two lines', (
    tester,
  ) async {
    await pumpTile(tester, text: term, isTerm: true);

    final style = textOf(tester, term).style!;
    expect(style.fontSize, themeOf(tester).titleMedium!.fontSize);
    expect(style.fontWeight, FontWeight.w500);
    // **The variation, not just the weight.** The faces here are variable, so a
    // `copyWith(fontWeight:)` that leaves `fontVariations` on the style's own
    // weight renders unchanged while every weight assertion passes — which is
    // the exact failure `AppTypography.withWeight` exists to prevent.
    expect(style.fontVariations, <FontVariation>[
      const FontVariation('wght', 500),
    ]);
    expect(textOf(tester, term).maxLines, AppMatchTile.termMaxLines);
  });

  testWidgets('a meaning is the read voice: bodySmall, regular, six lines', (
    tester,
  ) async {
    await pumpTile(tester, text: meaning, isTerm: false);

    final style = textOf(tester, meaning).style!;
    expect(style.fontSize, themeOf(tester).bodySmall!.fontSize);
    expect(style.fontWeight, FontWeight.w400);
    expect(textOf(tester, meaning).maxLines, AppMatchTile.meaningMaxLines);
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
    // stripe across a screen the user is meant to be reading. The height is
    // the floor the board itself uses, so this is the tightest real case.
    await pumpTile(
      tester,
      text: meaning,
      isTerm: false,
      height: AppMatchTile.minRowHeight,
    );

    expect(tester.takeException(), isNull);
    expect(textOf(tester, meaning).overflow, TextOverflow.ellipsis);
    expect(textOf(tester, meaning).maxLines, 6);
  });

  testWidgets('the tile insets its content evenly', (tester) async {
    // Even, and `sm` rather than `md` at the sides: six lines of meaning need
    // the width as much as the height, and eight logical pixels an end is
    // roughly a word per line on a half-width tile.
    await pumpTile(tester, text: meaning, isTerm: false);

    final padding = tester.widget<Padding>(
      find.descendant(of: find.byType(InkWell), matching: find.byType(Padding)),
    );

    expect(
      padding.padding,
      const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
    );
  });

  test('the row floor is what the typography above it implies', () {
    // **A contract between two files, not a decorative number.** `bodySmall` is
    // 12/16, the meaning gets six lines, and the tile insets `sm` top and
    // bottom: 6 × 16 + 2 × 8 = 112. The board reads this as the height below
    // which it scrolls instead of filling — so if the type role or the line
    // budget moves and this does not, the board silently starts ellipsising the
    // line it was sized to show.
    expect(AppMatchTile.minRowHeight, 112);
    expect(AppMatchTile.meaningMaxLines, 6);
    expect(AppMatchTile.termMaxLines, 2);
  });
}
