import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_durations.dart';
import 'package:memox/core/theme/app_semantic_colors.dart';
import 'package:memox/core/theme/app_spacing.dart';
import 'package:memox/core/theme/app_stroke.dart';
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
    MatchTileState state = MatchTileState.idle,
    Brightness brightness = Brightness.light,
  }) async {
    final tile = MatchTileWidget(
      text: text,
      state: state,
      onTap: () {},
      isTerm: isTerm,
    );

    await tester.pumpWidget(
      wrapForTest(
        height == null ? tile : SizedBox(height: height, child: tile),
        brightness: brightness,
      ),
    );
    // Past the `AnimatedContainer`'s whole duration: its first frame still
    // holds the previous state's colours, and a skin assertion that reads it
    // passes for the wrong reason.
    await tester.pump();
    await tester.pump(AppDurations.normal);
  }

  BoxDecoration skinOf(WidgetTester tester) =>
      tester
              .widget<AnimatedContainer>(find.byType(AnimatedContainer).first)
              .decoration!
          as BoxDecoration;

  AppSemanticColors semanticOf(WidgetTester tester) => Theme.of(
    tester.element(find.byType(MatchTileWidget)),
  ).extension<AppSemanticColors>()!;

  Color? fillFor(WidgetTester tester) => skinOf(tester).color;

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

  group('a state changes the edge and the ink, never the surface', () {
    // **The contract of this round, stated as a relation.** Selected, wrong and
    // paired used to fill the tile — `primary`, `error`, a `success` tint — and
    // every answer touches two tiles, so on a ten-slot board a fifth of the
    // screen changed colour at once and a six-line meaning turned into a
    // warning panel. The hue, the mark and the `Semantics` value carry the
    // information; the area never did.
    for (final (label, state) in <(String, MatchTileState)>[
      ('selected', MatchTileState.selected),
      ('wrong', MatchTileState.wrong),
      ('paired', MatchTileState.paired),
    ]) {
      testWidgets('$label sits on the same surface as idle', (tester) async {
        await pumpTile(tester, text: term, isTerm: true);
        final idle = fillFor(tester);

        await pumpTile(tester, text: term, isTerm: true, state: state);

        expect(fillFor(tester), idle);
        expect(fillFor(tester), isNotNull);
      });

      testWidgets('$label paints no role colour behind its text', (
        tester,
      ) async {
        await pumpTile(tester, text: term, isTerm: true, state: state);

        final scheme = Theme.of(
          tester.element(find.byType(MatchTileWidget)),
        ).colorScheme;
        final semantic = semanticOf(tester);

        expect(fillFor(tester), isNot(scheme.primary));
        expect(fillFor(tester), isNot(scheme.error));
        expect(fillFor(tester), isNot(semantic.success));
        expect(fillFor(tester), isNot(semantic.danger));
        expect(fillFor(tester), isNot(semantic.primaryAccent));
      });
    }

    testWidgets('idle is a hairline in the control border', (tester) async {
      await pumpTile(tester, text: term, isTerm: true);

      final semantic = semanticOf(tester);
      expect(skinOf(tester).border!.top.color, semantic.borderControl);
      expect(skinOf(tester).border!.top.width, AppStroke.hairline);
      expect(
        textOf(tester, term).style?.color,
        Theme.of(
          tester.element(find.byType(MatchTileWidget)),
        ).colorScheme.onSurface,
      );
    });

    testWidgets('selected is primaryAccent on the edge and the label', (
      tester,
    ) async {
      // `primaryAccent`, not `primary`: this is a label on a surface now, and
      // `primary` is deliberately held below the card's headline so a filled
      // CTA never outshines it — 3.33:1 as bare text on the dark page.
      await pumpTile(
        tester,
        text: term,
        isTerm: true,
        state: MatchTileState.selected,
      );

      final accent = semanticOf(tester).primaryAccent;
      expect(skinOf(tester).border!.top.color, accent);
      expect(skinOf(tester).border!.top.width, AppStroke.input);
      expect(textOf(tester, term).style?.color, accent);
      expect(find.byType(Icon), findsNothing);
    });

    testWidgets('wrong is danger on the edge, the label and the ✕', (
      tester,
    ) async {
      await pumpTile(
        tester,
        text: term,
        isTerm: true,
        state: MatchTileState.wrong,
      );

      final danger = semanticOf(tester).danger;
      expect(skinOf(tester).border!.top.color, danger);
      expect(skinOf(tester).border!.top.width, AppStroke.input);
      expect(textOf(tester, term).style?.color, danger);
      expect(tester.widget<Icon>(find.byIcon(Icons.close)).color, danger);
    });

    testWidgets('paired is success on the edge, the label and the ✓', (
      tester,
    ) async {
      await pumpTile(
        tester,
        text: term,
        isTerm: true,
        state: MatchTileState.paired,
      );

      final success = semanticOf(tester).success;
      expect(skinOf(tester).border!.top.color, success);
      expect(skinOf(tester).border!.top.width, AppStroke.input);
      expect(textOf(tester, term).style?.color, success);
      expect(tester.widget<Icon>(find.byIcon(Icons.check)).color, success);
    });

    testWidgets('cleared paints nothing at all', (tester) async {
      // Still the one exception, and the reason is unchanged: nothing painted
      // is a truer hole than a colour that happens to match the page.
      await pumpTile(
        tester,
        text: term,
        isTerm: true,
        state: MatchTileState.cleared,
      );

      expect(fillFor(tester), isNull);
      expect(skinOf(tester).border!.top.width, AppStroke.hairline);
    });

    testWidgets('dark mode makes the same three choices', (tester) async {
      // The states are tokens, not values, so dark needs no second decision —
      // but the fill relation is the thing most likely to be broken by a
      // brightness-specific tweak, so it is checked in both.
      await pumpTile(
        tester,
        text: term,
        isTerm: true,
        brightness: Brightness.dark,
      );
      final idle = fillFor(tester);

      for (final state in <MatchTileState>[
        MatchTileState.selected,
        MatchTileState.wrong,
        MatchTileState.paired,
      ]) {
        await pumpTile(
          tester,
          text: term,
          isTerm: true,
          state: state,
          brightness: Brightness.dark,
        );
        expect(fillFor(tester), idle, reason: '$state changed the surface');
      }
    });
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
