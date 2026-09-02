import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_semantic_colors.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/features/card/domain/models/card_history_page_model.dart';
import 'package:memox/features/card/presentation/widgets/items/card_box_progress_widget.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_detail_summary_widget.dart';
import 'package:memox/features/deck/domain/models/scheduler_type_model.dart';
import 'package:memox/shared/widgets/mx_card.dart';

import 'support/card_detail_harness.dart';
import 'support/fake_card_detail_repository.dart';

/// The visual hierarchy of the compact layout — which role each piece of text
/// takes, and which stored value decides each colour (M4.15).
///
/// **Roles, not pixels.** A golden says "this is what it looked like", which is
/// true of a screen drawn wrong on the day it was drawn. These say "the front is
/// `headlineSmall`" and "the box track has eight steps", which stay true across
/// a re-theme and fail the moment somebody reaches past the token.
void main() {
  FakeCardDetailRepository loaded({
    String? example = '사과를 먹어요',
    bool isFlagged = true,
    SchedulerType scheduler = SchedulerType.eightBox,
    int? currentBox = 3,
    bool hasSm2Numbers = true,
    int tagCount = 1,
  }) => FakeCardDetailRepository()
    ..seededDetail = fakeCardDetail(
      front: '사과',
      back: 'quả táo',
      example: example,
      isFlagged: isFlagged,
      tagNames: <String>[for (var i = 0; i < tagCount; i++) 'tag-$i'],
      schedulerType: scheduler,
      currentBox: currentBox,
      easeFactor: scheduler == SchedulerType.sm2 && hasSm2Numbers ? 2.5 : null,
      intervalDays: scheduler == SchedulerType.sm2 && hasSm2Numbers ? 6 : null,
      repetitions: scheduler == SchedulerType.sm2 && hasSm2Numbers ? 2 : null,
      answerCount: 7,
      lapseCount: 1,
    )
    ..pages.add(CardHistoryPageModel.empty);

  TextStyle styleOf(WidgetTester tester, Finder finder) =>
      tester.widget<Text>(finder).style!;

  AppSemanticColors semanticOf(WidgetTester tester) => Theme.of(
    tester.element(find.byType(CardDetailSummaryWidget)),
  ).extension<AppSemanticColors>()!;

  ColorScheme schemeOf(WidgetTester tester) => Theme.of(
    tester.element(find.byType(CardDetailSummaryWidget)),
  ).colorScheme;

  group('summary typography', () {
    testWidgets('the front is the headline rung, not the review prompt', (
      tester,
    ) async {
      await pumpCardDetail(tester, loaded());
      await tester.pumpAndSettle();

      final theme = Theme.of(tester.element(find.text('사과')));
      final front = styleOf(tester, find.text('사과'));
      final back = styleOf(tester, find.text('quả táo'));

      // **`headlineSmall`, deliberately not `cardPrompt`.** That 30sp rung
      // belongs to the review card, where the term *is* the task and fills the
      // screen. Here it is one fact among several, and a summary that shouts is
      // a summary nobody reads past.
      expect(front.fontSize, theme.textTheme.headlineSmall!.fontSize);
      expect(front.fontSize, 24);
      // Not the 30sp prompt rung, stated as a number because that is the
      // regression: a later change reaching for `cardPrompt` here would still
      // be "a headline" to a looser assertion.
      expect(front.fontSize, isNot(30));
      // The back steps down a full rung and takes the muted ink, so the pair
      // reads as term-then-meaning rather than as two headings.
      expect(back.fontSize, theme.textTheme.bodyMedium!.fontSize);
      expect(back.color, theme.colorScheme.onSurfaceVariant);
      expect(back.fontSize! < front.fontSize!, isTrue);
    });

    testWidgets('an optional field labels quietly and answers in body text', (
      tester,
    ) async {
      await pumpCardDetail(tester, loaded());
      await tester.pumpAndSettle();

      final theme = Theme.of(tester.element(find.text('Example')));
      expect(
        styleOf(tester, find.text('Example')).fontSize,
        theme.textTheme.labelSmall!.fontSize,
      );
      expect(
        styleOf(tester, find.text('Example')).color,
        theme.colorScheme.onSurfaceVariant,
      );
      expect(
        styleOf(tester, find.text('사과를 먹어요')).fontSize,
        theme.textTheme.bodyMedium!.fontSize,
      );
    });

    testWidgets('the divider belongs to the optional group', (tester) async {
      await pumpCardDetail(tester, loaded());
      await tester.pumpAndSettle();
      final divider = find.descendant(
        of: find.byType(CardDetailSummaryWidget),
        matching: find.byType(Divider),
      );
      expect(divider, findsOneWidget);
      expect(
        tester.widget<Divider>(divider).color,
        semanticOf(tester).borderSubtle,
      );

      await pumpCardDetail(tester, loaded(example: null));
      await tester.pumpAndSettle();
      // A rule with nothing under it separates the meaning from the bottom of
      // the card.
      expect(
        find.descendant(
          of: find.byType(CardDetailSummaryWidget),
          matching: find.byType(Divider),
        ),
        findsNothing,
      );
    });
  });

  group('the scheduler badge says what the scheduler knows', () {
    testWidgets('eight_box states its position out of the contract maximum', (
      tester,
    ) async {
      await pumpCardDetail(tester, loaded());
      await tester.pumpAndSettle();

      final badge = find.descendant(
        of: find.byType(CardDetailSummaryWidget),
        matching: find.text('3 / 8'),
      );
      expect(badge, findsOneWidget);
      // The accent, and tabular figures so a two-digit box does not shift the
      // stroke beside it.
      expect(styleOf(tester, badge).color, schemeOf(tester).primary);
      expect(styleOf(tester, badge).fontFeatures, const <FontFeature>[
        FontFeature.tabularFigures(),
      ]);
    });

    testWidgets('sm2 states its name and gets no ladder', (tester) async {
      await pumpCardDetail(
        tester,
        loaded(scheduler: SchedulerType.sm2, currentBox: null),
      );
      await tester.pumpAndSettle();

      // SM-2 has no box to be three-eighths of the way up, and inventing one
      // for symmetry would be inventing a metric (BR-243, AD-08).
      expect(find.text('SM-2'), findsOneWidget);
      expect(find.byType(CardBoxProgressWidget), findsNothing);
      expect(find.textContaining('/ 8'), findsNothing);
    });
  });

  group('the ladder at its ends, and a scheduler missing its numbers', () {
    for (final box in <int>[1, 8]) {
      testWidgets('box $box renders the whole track with no gap', (
        tester,
      ) async {
        await pumpCardDetail(tester, loaded(currentBox: box));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.byType(CardBoxProgressWidget));
        await tester.pumpAndSettle();

        // **The two ends nobody had drawn.** At box 1 there is no completed
        // step and at box 8 there is no future one, so each end is the case
        // where one of the three colours drops out of the track entirely.
        final semantic = semanticOf(tester);
        final steps = find.descendant(
          of: find.byType(CardBoxProgressWidget),
          matching: find.byType(Container),
        );
        expect(tester.widgetList(steps).length, 8);
        Color colourAt(int index) =>
            (tester.widget<Container>(steps.at(index)).decoration!
                    as BoxDecoration)
                .color!;
        expect(colourAt(box - 1), schemeOf(tester).primary);
        expect(
          colourAt(box == 1 ? 1 : 0),
          box == 1 ? semantic.progressTrack : semantic.progressFill,
        );
        expect(tester.takeException(), isNull);
        // Two: the summary badge and the panel's own row. Both are meant to
        // be there — the concept states the position in both places too.
        expect(find.text('$box / 8'), findsNWidgets(2));
      });
    }

    testWidgets('an sm2 card that has recorded none of its numbers shows the '
        'shared fields and nothing else', (tester) async {
      await pumpCardDetail(
        tester,
        loaded(
          scheduler: SchedulerType.sm2,
          currentBox: null,
          hasSm2Numbers: false,
        ),
      );
      await tester.pumpAndSettle();

      // Every SM-2 fixture until now filled all three, so the `!= null` guards
      // had never run on their false side on this screen — and that is the
      // path that leaves the grid with an odd number of cells.
      for (final absent in <String>['Ease', 'Interval', 'Repetitions']) {
        expect(find.text(absent), findsNothing);
      }
      expect(find.text('Due'), findsOneWidget);
      expect(find.text('Lapses'), findsOneWidget);
      expect(find.byType(CardBoxProgressWidget), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('ten tags and a flag reflow instead of overflowing at 320dp '
        'with 2.0 text', (tester) async {
      await pumpCardDetail(
        tester,
        loaded(tagCount: 10),
        locale: const Locale('vi'),
        surfaceSize: const Size(320, 640),
        textScale: 2,
      );
      await tester.pumpAndSettle();

      // The hero now puts the flag and every tag in **one** `Wrap`, which is a
      // different reflow shape from the old separate tag row — and ten tags at
      // 2.0 is the case that actually exercises it.
      expect(tester.takeException(), isNull);
      final hero = tester.getRect(
        find.descendant(
          of: find.byType(CardDetailSummaryWidget),
          matching: find.byType(MxCard),
        ),
      );
      for (var index = 0; index < 10; index++) {
        expect(
          tester.getRect(find.text('tag-$index')).right,
          lessThanOrEqualTo(hero.right),
        );
      }
    });
  });

  group('the progress panel', () {
    testWidgets('counts are tabular and dates are not', (tester) async {
      await pumpCardDetail(tester, loaded());
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Reviews'));
      await tester.pumpAndSettle();

      const tabular = <FontFeature>[FontFeature.tabularFigures()];
      expect(styleOf(tester, find.text('7')).fontFeatures, tabular);
      expect(styleOf(tester, find.text('1')).fontFeatures, tabular);
      expect(
        styleOf(tester, find.text('Not scheduled yet').first).fontFeatures,
        isNull,
      );
    });

    testWidgets('no aggregate the concept drew survives BR-243', (
      tester,
    ) async {
      await pumpCardDetail(tester, loaded());
      await tester.pumpAndSettle();

      // Recall rate, correct streak and "since added" are in the concept and
      // forbidden here: a second definition of a statistic is one that will
      // disagree with the real one.
      expect(find.textContaining('%'), findsNothing);
      for (final absent in <String>[
        'Recall rate',
        'Correct streak',
        'Since added',
      ]) {
        expect(find.text(absent), findsNothing);
      }
    });

    testWidgets('the eight steps carry three roles, and the current one is '
        'taller', (tester) async {
      await pumpCardDetail(tester, loaded());
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byType(CardBoxProgressWidget));
      await tester.pumpAndSettle();

      final semantic = semanticOf(tester);
      final steps = find.descendant(
        of: find.byType(CardBoxProgressWidget),
        matching: find.byType(Container),
      );
      Color colourAt(int index) =>
          (tester.widget<Container>(steps.at(index)).decoration!
                  as BoxDecoration)
              .color!;

      expect(colourAt(0), semantic.progressFill);
      expect(colourAt(1), semantic.progressFill);
      expect(colourAt(2), schemeOf(tester).primary);
      expect(colourAt(3), semantic.progressTrack);
      expect(colourAt(7), semantic.progressTrack);

      // **Height, because in dark the colours coincide.** `progressFillDark`
      // and `primaryAccentDark` are both `focusRingDark`, so the current step is
      // told apart by its size and by the `3 / 8` above it — never by hue alone.
      final current = tester.getRect(steps.at(2)).height;
      expect(current, greaterThan(tester.getRect(steps.at(1)).height));
      expect(current, greaterThan(tester.getRect(steps.at(4)).height));
    });

    testWidgets('the track is announced as a position, not as eight boxes', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpCardDetail(tester, loaded());
      await tester.pumpAndSettle();

      // Eight coloured rectangles are not a sentence; the row and the track are
      // announced together as the one fact they jointly mean.
      // Spoken, not drawn: the stroke is punctuation and a screen reader
      // either says 'slash' or says nothing. **Two nodes, and that is the
      // fix** — the badge used to be announced as "Box" then "3 slash 8"
      // because only the track had a spoken form.
      expect(find.bySemanticsLabel('Box 3 of 8'), findsNWidgets(2));
      expect(find.text('3 / 8'), findsNWidgets(2));
      handle.dispose();
    });
  });

  group('the flag is a mark, not a control', () {
    testWidgets('it wears the due container and says the word beside the '
        'glyph', (tester) async {
      await pumpCardDetail(tester, loaded());
      await tester.pumpAndSettle();

      final semantic = semanticOf(tester);
      final chip = tester.widget<Container>(
        find
            .ancestor(
              of: find.text('Flagged'),
              matching: find.byType(Container),
            )
            .first,
      );
      expect((chip.decoration! as BoxDecoration).color, semantic.dueContainer);
      expect(
        styleOf(tester, find.text('Flagged')).color,
        semantic.onDueContainer,
      );
      // The glyph takes the chip's on-colour rather than `warning`, which
      // measures 4.04:1 here — above the 3:1 a graphic needs and below the
      // 4.5:1 the strict screen audit applies to anything reaching the render
      // tree as a text run, which a glyph does.
      expect(
        tester.widget<Icon>(find.byIcon(Icons.flag)).color,
        semantic.onDueContainer,
      );
    });

    testWidgets('it offers no tap and is not announced as a button', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpCardDetail(tester, loaded());
      await tester.pumpAndSettle();

      expect(
        find.ancestor(of: find.text('Flagged'), matching: find.byType(InkWell)),
        findsNothing,
      );
      expect(
        tester.getSemantics(find.text('Flagged')).flagsCollection.isButton,
        isFalse,
      );
      handle.dispose();
    });
  });

  group('the Edit action', () {
    for (final brightness in Brightness.values) {
      testWidgets('is a bare icon whose glyph carries it in '
          '${brightness.name}', (tester) async {
        await pumpCardDetail(
          tester,
          loaded(),
          theme: brightness == Brightness.light
              ? buildLightTheme()
              : buildDarkTheme(),
        );
        await tester.pumpAndSettle();

        final context = tester.element(find.byIcon(Icons.edit_outlined));
        final scheme = Theme.of(context).colorScheme;
        final icon = tester.widget<Icon>(find.byIcon(Icons.edit_outlined));
        final resolved = icon.color ?? IconTheme.of(context).color;

        // **This asserted the opposite, and the reason it gave is the reason
        // it changed.** It said the label is what identifies the button,
        // because `secondaryContainer` is only 1.14:1 against the bar — true,
        // and an argument against a *tonal fill with no word*, not against a
        // glyph. An icon button has no fill to be invisible: this ink is the
        // app bar's `foregroundColor`, which an `AppBar` pushes into the
        // `IconTheme` its actions read — so `onSurface`, not the
        // `onSurfaceVariant` the icon-button theme would have given it. It
        // measures 16.06:1 in light and 16.62:1 in dark on the bar's own
        // background.
        //
        // BR-246 wants edit to be a separate, explicit action that does not
        // out-weigh the content being read. It never asked for a word, and the
        // lighter control is the one that clause prefers.
        expect(find.text('Edit card'), findsNothing);
        expect(resolved, scheme.onSurface);
      });
    }

    testWidgets('it still names itself to a screen reader', (tester) async {
      // Dropping the word drops it from the screen, not from the semantics —
      // otherwise the action becomes unreachable for anyone who cannot see the
      // glyph, which is a worse outcome than the one this change fixed.
      final handle = tester.ensureSemantics();
      await pumpCardDetail(tester, loaded());
      await tester.pumpAndSettle();

      expect(
        find.bySemanticsLabel('Edit card'),
        findsOneWidget,
        reason: 'the label moved to the semantics, it did not disappear',
      );
      handle.dispose();
    });

    testWidgets('clears the Android tap target', (tester) async {
      await pumpCardDetail(tester, loaded());
      await tester.pumpAndSettle();

      // The glyph is 24dp; what has to clear 48 is the target around it.
      final size = tester.getSize(
        find
            .ancestor(
              of: find.byIcon(Icons.edit_outlined),
              matching: find.byType(InkWell),
            )
            .first,
      );
      expect(size.height, greaterThanOrEqualTo(47.5));
      expect(size.width, greaterThanOrEqualTo(47.5));
    });
  });
}
