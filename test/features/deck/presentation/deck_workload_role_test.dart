import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_colors.dart';
import 'package:memox/core/theme/app_material_roles.dart';
import 'package:memox/core/theme/app_semantic_colors.dart';
import 'package:memox/features/deck/domain/models/deck_content_type_model.dart';
import 'package:memox/features/deck/domain/models/deck_summary_model.dart';
import 'package:memox/features/deck/presentation/screens/deck_list_screen.dart';
import 'package:memox/features/deck/presentation/widgets/items/deck_icon_area_widget.dart';
import 'package:memox/features/deck/presentation/widgets/items/deck_study_button_widget.dart';
import 'package:memox/features/deck/presentation/widgets/items/deck_tile_widget.dart';
import 'package:memox/features/deck/presentation/widgets/items/deck_workload_line_widget.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';

import '../../../support/color_math.dart';
import 'support/deck_screen_harness.dart';
import 'support/fake_deck_repository.dart';

/// Which semantic role each part of the workload row actually wears — asserted
/// per theme, by role and not by hex, because a repainted palette must not
/// rewrite these tests as long as the *mapping* holds.
///
/// The one numeric block at the end is different in kind: it measures the two
/// pairs this design leans on (`info` on the surfaces, the due chip's ink on
/// its container) against WCAG 4.5:1, so a future palette edit that keeps the
/// role but breaks the ratio fails here rather than in a review screenshot.
void main() {
  final english = AppLocalizationsEn();

  DeckSummary mixed() => fakeSummary(
    id: 'd1',
    name: 'Nouns',
    totalCardCount: 60,
    newCardCount: 14,
    dueCardCount: 7,
    learnedCardCount: 22,
  );

  for (final (label, isDark) in <(String, bool)>[
    ('light', false),
    ('dark', true),
  ]) {
    testWidgets('the roles hold in $label', (tester) async {
      await pumpDeckScreen(
        tester,
        repository: FakeDeckRepository.withSummaries(<DeckSummary>[mixed()]),
        screen: const DeckListScreen(),
        isDark: isDark,
      );

      final context = tester.element(find.byType(DeckWorkloadLineWidget));
      final semantic = Theme.of(context).extension<AppSemanticColors>()!;
      final scheme = Theme.of(context).colorScheme;

      // Scoped to the workload line: the summary states the same words above
      // the list, and an unscoped text finder matches both.
      Finder onLine(Finder matching) => find.descendant(
        of: find.byType(DeckWorkloadLineWidget),
        matching: matching,
      );

      /// The ground a chip's label is painted on.
      Color fillUnder(Finder label) =>
          (tester
                      .widget<DecoratedBox>(
                        find
                            .ancestor(
                              of: label,
                              matching: find.byType(DecoratedBox),
                            )
                            .first,
                      )
                      .decoration
                  as BoxDecoration)
              .color!;

      // Chips, not coloured words (owner review, 2026-08-20): each count has
      // its own ground, and no icon rides the line.
      expect(onLine(find.byType(Icon)), findsNothing);

      final dueLabel = onLine(find.text(english.deckTileDueChipLabel(7)));
      final dueStyle = tester.widget<Text>(dueLabel).style;
      expect(dueStyle?.color, semantic.onStreakContainer);
      expect(fillUnder(dueLabel), semantic.streakContainer);
      expect(dueStyle?.color, isNot(semantic.danger));
      expect(dueStyle?.color, isNot(scheme.error));

      // **New is neutral.** It wore `info` blue, which was the one metric in
      // the app that read as a hyperlink — and new cards are not a warning,
      // so the chip is the muted surface with the quiet ink on it.
      final newLabel = onLine(find.text(english.deckTileNewChipLabel(14)));
      final newStyle = tester.widget<Text>(newLabel).style;
      expect(newStyle?.color, scheme.onSurfaceVariant);
      expect(fillUnder(newLabel), semantic.surfaceMuted);
      expect(newStyle?.color, isNot(semantic.info));
      expect(newStyle?.color, isNot(scheme.primary));
      expect(newStyle?.color, isNot(semantic.success));
      // One typography across the group: same size, same weight — the chips
      // read level, and only the ground differs.
      expect(dueStyle?.fontSize, newStyle?.fontSize);
      expect(dueStyle?.fontWeight, FontWeight.w600);
      expect(newStyle?.fontWeight, FontWeight.w600);

      // Study: the card's one primary verb (owner mockup, 2026-08-20) — the
      // chips gave up their containers, so the brand fill no longer competes.
      final study = tester.widget<FilledButton>(
        find.descendant(
          of: find.byType(DeckStudyButtonWidget),
          matching: find.byType(FilledButton),
        ),
      );
      final studyFill = study.style?.backgroundColor?.resolve(<WidgetState>{});
      expect(studyFill, scheme.primary);
      expect(studyFill, isNot(semantic.streakContainer));
    });
  }

  group('the well: identity, not schedule (amends BR-161)', () {
    Future<DeckIconArea> pumpIcon(
      WidgetTester tester, {
      required int due,
      required int newCards,
      required int learned,
      int overdueDays = 0,
      int total = 60,
      DeckContentType contentType = DeckContentType.deck,
    }) async {
      await pumpDeckScreen(
        tester,
        repository: FakeDeckRepository.withSummaries(<DeckSummary>[
          fakeSummary(
            id: 'd1',
            name: 'Nouns',
            contentType: contentType,
            totalCardCount: total,
            newCardCount: newCards,
            dueCardCount: due,
            overdueDayCount: overdueDays,
            learnedCardCount: learned,
          ),
        ]),
        screen: const DeckListScreen(),
      );

      return tester.widget<DeckIconArea>(find.byType(DeckIconArea));
    }

    ColorScheme schemeOf(WidgetTester tester) =>
        Theme.of(tester.element(find.byType(DeckIconArea))).colorScheme;

    /// Every schedule state, one well. The chips carry urgency now, so a
    /// second carrier here would say it twice — in a glyph that reads
    /// *cancelled* rather than *late* (owner review, 2026-08-20).
    for (final (name, due, days) in <(String, int, int)>[
      ('not due', 0, 0),
      ('due today', 7, 0),
      ('overdue', 5, 3),
    ]) {
      testWidgets('$name keeps the brand well and the folder glyph', (
        tester,
      ) async {
        final icon = await pumpIcon(
          tester,
          due: due,
          newCards: 0,
          learned: 30,
          overdueDays: days,
        );
        final scheme = schemeOf(tester);
        final semantic = Theme.of(
          tester.element(find.byType(DeckIconArea)),
        ).extension<AppSemanticColors>()!;

        expect(icon.icon, Icons.folder_outlined);
        expect(icon.tint, scheme.onPrimaryContainer);
        // `wellColor` null means the brand container — no state override.
        expect(icon.wellColor, isNull);
        expect(icon.icon, isNot(Icons.event_busy));
        expect(icon.icon, isNot(Icons.event));
        expect(semantic.danger, isNotNull);
      });
    }

    testWidgets('a deck of cards shows a stack of cards', (tester) async {
      final icon = await pumpIcon(
        tester,
        due: 5,
        newCards: 0,
        learned: 20,
        contentType: DeckContentType.card,
      );

      expect(icon.icon, Icons.style_outlined);
    });

    testWidgets('100% learned and nothing due is still the same well', (
      tester,
    ) async {
      // Completion belongs to the progress bar; the square answers what the
      // deck is, and that does not change with the schedule.
      final icon = await pumpIcon(tester, due: 0, newCards: 0, learned: 60);

      expect(icon.icon, Icons.folder_outlined);
      expect(find.byIcon(Icons.check_circle), findsNothing);
    });

    testWidgets('new-only keeps Study on', (tester) async {
      await pumpIcon(tester, due: 0, newCards: 14, learned: 22);

      expect(find.byType(DeckStudyButtonWidget), findsOneWidget);
    });
  });

  group('the overdue chip on the workload line', () {
    Future<void> pumpOverdue(
      WidgetTester tester, {
      required int overdueCards,
      int days = 7,
    }) => pumpDeckScreen(
      tester,
      repository: FakeDeckRepository.withSummaries(<DeckSummary>[
        fakeSummary(
          id: 'd1',
          name: 'Backlog',
          totalCardCount: 60,
          dueCardCount: 12,
          overdueCardCount: overdueCards,
          overdueDayCount: days,
          learnedCardCount: 30,
        ),
      ]),
      screen: const DeckListScreen(),
    );

    // Scoped to the tile: the level summary above the list states the same
    // split for the level, and this group is about the tile's line. The
    // summary's own copy is asserted in `deck_summary_overdue_test.dart`.
    Finder onTile(Finder matching) =>
        find.descendant(of: find.byType(DeckTileWidget), matching: matching);

    testWidgets('the backlog leads the line in the danger ink, and the due '
        'chip counts only today', (tester) async {
      // The `+7d` badge over the icon is gone (owner mockup, 2026-08-20):
      // it said how *old* the backlog was but not how *big*, and "12 due"
      // hid that eight of the twelve had already missed their day.
      await pumpOverdue(tester, overdueCards: 8);

      final context = tester.element(find.byType(DeckWorkloadLineWidget));
      final scheme = Theme.of(context).colorScheme;

      final overdue = onTile(find.text(english.deckSummaryOverduePart(8)));
      expect(overdue, findsOneWidget);
      final style = tester.widget<Text>(overdue).style;
      // The error *container* pair, because the count sits on its own ground
      // now rather than as ink on the card (owner review, 2026-08-20).
      expect(style?.color, scheme.onErrorContainer);
      expect(style?.fontWeight, FontWeight.w600);
      final chip =
          tester
                  .widget<DecoratedBox>(
                    find
                        .ancestor(
                          of: overdue,
                          matching: find.byType(DecoratedBox),
                        )
                        .first,
                  )
                  .decoration
              as BoxDecoration;
      expect(chip.color, scheme.errorContainer);

      expect(
        onTile(find.text(english.deckTileDueChipLabel(4))),
        findsOneWidget,
        reason: 'the split closes: 12 due = 8 overdue + 4 today',
      );
      expect(onTile(find.text(english.deckTileDueChipLabel(12))), findsNothing);
    });

    testWidgets('the day count survives in the status square sentence', (
      tester,
    ) async {
      await pumpOverdue(tester, overdueCards: 8);

      expect(
        onTile(find.bySemanticsLabel(english.deckOverdueSemanticLabel(12, 7))),
        findsOneWidget,
        reason: 'a screen reader still hears both units: cards and days',
      );
    });

    testWidgets('nothing overdue: the line opens with the due chip', (
      tester,
    ) async {
      await pumpOverdue(tester, overdueCards: 0, days: 0);

      expect(
        onTile(find.text(english.deckSummaryOverduePart(0))),
        findsNothing,
      );
      expect(
        onTile(find.text(english.deckTileDueChipLabel(12))),
        findsOneWidget,
      );
    });
  });

  test('the pairs this mapping leans on clear WCAG', () {
    // Body-size text, so 4.5:1 (WCAG 1.4.3). Asserted against the surfaces the
    // metrics actually sit on. If a palette edit ever fails one of these, the
    // fix is a token change or a role change — never a hex in the widget.
    final pairs = <String, (Color, Color)>{
      'info on light surface': (AppColors.infoLight, AppColors.surfaceLight),
      'info on dark surface': (AppColors.infoDark, AppColors.surfaceDark),
      // The whole due metric — clock and words — sits directly on the
      // surface in the streak ink. Measured 7.22:1 light / 8.58:1 dark when
      // the well was dropped; this holds the pair to the body-text floor.
      'due ink on light surface': (
        AppColors.onStreakContainerLight,
        AppColors.surfaceLight,
      ),
      'due ink on dark surface': (
        AppColors.onStreakContainerDark,
        AppColors.surfaceDark,
      ),
      // **The three workload chips**, each on its own ground (owner review,
      // 2026-08-20). Container pairs carry their own guarantee, but the floor
      // is asserted here rather than assumed: these are the card's only
      // coloured surfaces now, and a palette edit that broke one would show up
      // as a legible-looking screenshot and an unreadable device.
      'overdue chip, light': (
        AppMaterialRoles.onErrorContainerLight,
        AppMaterialRoles.errorContainerLight,
      ),
      'overdue chip, dark': (
        AppMaterialRoles.onErrorContainerDark,
        AppMaterialRoles.errorContainerDark,
      ),
      'new chip, light': (
        AppColors.textSecondaryLight,
        AppColors.surfaceMutedLight,
      ),
      'new chip, dark': (
        AppColors.textSecondaryDark,
        AppColors.surfaceMutedDark,
      ),
      // **Study Home's overdue count, which is `danger` as *ink* rather than
      // as a fill** — a pairing the app did not have before M5.26 and which
      // its wireframe (S12) states without measuring. Body-size text on the
      // card surface, so the same 4.5 floor as the rest of this table.
      'danger ink on light surface': (
        AppColors.dangerLight,
        AppColors.surfaceLight,
      ),
      'danger ink on dark surface': (
        AppColors.dangerDark,
        AppColors.surfaceDark,
      ),
    };

    for (final MapEntry(key: name, value: (fore, back)) in pairs.entries) {
      expect(
        contrast(fore, back),
        greaterThanOrEqualTo(4.5),
        reason: '$name must carry body text',
      );
    }

    // The gauge is informational graphics, so 3:1 (WCAG 1.4.11): fill against
    // its own track, in both themes.
    expect(
      contrast(AppColors.progressFillLight, AppColors.progressTrackLight),
      greaterThanOrEqualTo(3),
    );
    expect(
      contrast(AppColors.progressFillDark, AppColors.progressTrackDark),
      greaterThanOrEqualTo(3),
    );
  });
}
