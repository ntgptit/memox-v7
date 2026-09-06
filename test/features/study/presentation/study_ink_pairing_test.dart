import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/study/di/study_repository_provider.dart';
import 'package:memox/features/study/presentation/screens/study_options_screen.dart';
import 'package:memox/features/study/presentation/widgets/items/study_home_deck_item_widget.dart';
import 'package:memox/features/study/presentation/widgets/sections/study_home_resume_section_widget.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';

import '../domain/support/fake_study_repository.dart';
import 'support/study_home_harness.dart';
import 'support/study_widget_harness.dart';

/// Two inks that were paired with the wrong ground, and one paired with none.
///
/// **`onSecondaryContainer` on a surface fill** (SC-C9-04). Every line of the
/// resume card took an ink `app_ink.dart` scopes to "text on a tinted
/// container, never on the page", and whose only measured ground in
/// `app_ink_test.dart` is `scheme.secondaryContainer` — while the fill
/// `MxCard.tonal` actually paints is `semantic.surfaceEmphasis`, ΔE 9.21 away
/// in light. What that cost visibly is the assertion below: the deck name in
/// the hero and the deck name in the rows one section down are the same rung
/// and were ΔE 11.82 apart.
///
/// **`quiet` on one supporting note and nothing on its twin** (SC-C9-07). Two
/// 12sp `bodySmall` explanations, 80dp apart in one column on one page surface,
/// rendered at `onSurface` and `onSurfaceVariant`.
void main() {
  final english = AppLocalizationsEn();

  group('the resume card', () {
    testWidgets('paints its three lines on the ink its fill is measured for', (
      tester,
    ) async {
      final harness = StudyHomeHarness();
      addTearDown(harness.dispose);
      await harness.pump(tester);

      final scheme = Theme.of(
        tester.element(find.byType(StudyHomeResumeSectionWidget)),
      ).colorScheme;

      Color inkOf(Finder finder) => tester.widget<Text>(finder).style!.color!;

      final card = find.byType(StudyHomeResumeSectionWidget);
      for (final line in <Finder>[
        find.descendant(
          of: card,
          matching: find.text(english.studyHomeResumeTitle),
        ),
      ]) {
        expect(inkOf(line), scheme.onSurface);
      }
    });

    testWidgets('the hero deck name matches the row deck name exactly', (
      tester,
    ) async {
      final harness = StudyHomeHarness();
      addTearDown(harness.dispose);
      await harness.pump(tester);

      final heroName = tester
          .widgetList<Text>(
            find.descendant(
              of: find.byType(StudyHomeResumeSectionWidget),
              matching: find.byType(Text),
            ),
          )
          .map((t) => t.style?.color)
          .whereType<Color>()
          .toSet();

      final rowName = tester
          .widgetList<Text>(
            find.descendant(
              of: find.byType(StudyHomeDeckItemWidget).first,
              matching: find.byType(Text),
            ),
          )
          .map((t) => t.style?.color)
          .whereType<Color>();

      // Same rung, same screen, one section apart. The hero used to paint a
      // container ink and the row an un-inked `onSurface`, so the two names
      // were a different colour — measured ΔE 11.82 in light.
      expect(heroName, contains(rowName.first));
    });
  });

  testWidgets('both study-options notes speak at one ink', (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          studyRepositoryProvider.overrideWithValue(
            FakeStudyRepository()..isRootOverride = true,
          ),
        ],
        child: wrapForTest(
          const StudyOptionsScreen(deckId: 'd1'),
          isScrollable: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final nextSession = tester.widget<Text>(
      find.text(english.studyOptionsNextSessionNote),
    );
    final override = tester.widget<Text>(
      find.text(english.studyOptionsOverrideNote),
    );

    expect(nextSession.style!.color, override.style!.color);
    expect(
      nextSession.style!.fontSize,
      override.style!.fontSize,
      reason: 'both are the same rung; the defect was ink, not size',
    );
  });
}
