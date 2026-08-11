import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_colors.dart';
import 'package:memox/core/theme/app_semantic_colors.dart';
import 'package:memox/features/deck/domain/models/deck_summary_model.dart';
import 'package:memox/features/deck/presentation/screens/deck_list_screen.dart';
import 'package:memox/features/deck/presentation/widgets/items/deck_study_button_widget.dart';
import 'package:memox/features/deck/presentation/widgets/items/deck_workload_line_widget.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';

import '../../../support/color_math.dart';
import 'support/deck_fixtures.dart';
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
      Finder onLine(String text) => find.descendant(
        of: find.byType(DeckWorkloadLineWidget),
        matching: find.text(text),
      );

      // Due: time-pressure container, never danger.
      final chip = tester.widget<DecoratedBox>(
        find
            .ancestor(
              of: onLine('7 ${english.deckDueMetricWord}'),
              matching: find.descendant(
                of: find.byType(DeckWorkloadLineWidget),
                matching: find.byType(DecoratedBox),
              ),
            )
            .first,
      );
      final chipFill = (chip.decoration as BoxDecoration).color;
      expect(chipFill, semantic.streakContainer);
      expect(chipFill, isNot(scheme.error));
      expect(chipFill, isNot(semantic.danger));

      final chipInk = tester
          .widget<Text>(onLine('7 ${english.deckDueMetricWord}'))
          .style
          ?.color;
      expect(chipInk, semantic.onStreakContainer);

      // New: info ink as a text metric — no container at all.
      final newInk = tester
          .widget<Text>(onLine('14 ${english.deckNewMetricWord}'))
          .style
          ?.color;
      expect(newInk, semantic.info);
      expect(newInk, isNot(scheme.primary));
      expect(newInk, isNot(semantic.success));

      // Study: the tonal pair, not primary and not any workload colour.
      final study = tester.widget<FilledButton>(
        find.descendant(
          of: find.byType(DeckStudyButtonWidget),
          matching: find.byType(FilledButton),
        ),
      );
      final studyFill = study.style?.backgroundColor?.resolve(<WidgetState>{});
      expect(studyFill, scheme.secondaryContainer);
      expect(studyFill, isNot(scheme.primary));
      expect(studyFill, isNot(semantic.streakContainer));
    });
  }

  test('the pairs this mapping leans on clear WCAG', () {
    // Body-size text, so 4.5:1 (WCAG 1.4.3). Asserted against the surfaces the
    // metrics actually sit on. If a palette edit ever fails one of these, the
    // fix is a token change or a role change — never a hex in the widget.
    final pairs = <String, (Color, Color)>{
      'info on light surface': (AppColors.infoLight, AppColors.surfaceLight),
      'info on dark surface': (AppColors.infoDark, AppColors.surfaceDark),
      'due ink on its container, light': (
        AppColors.onStreakContainerLight,
        AppColors.streakContainerLight,
      ),
      'due ink on its container, dark': (
        AppColors.onStreakContainerDark,
        AppColors.streakContainerDark,
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
