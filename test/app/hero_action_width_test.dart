import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_breakpoints.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/features/deck/domain/models/deck_list_snapshot_model.dart';
import 'package:memox/features/deck/domain/models/deck_path_segment_model.dart';
import 'package:memox/features/deck/domain/models/deck_summary_model.dart';
import 'package:memox/features/deck/presentation/widgets/sections/deck_level_summary_widget.dart';
import 'package:memox/features/study/presentation/widgets/sections/study_home_resume_section_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_action_button.dart';

import '../features/deck/presentation/support/fake_deck_repository.dart';
import '../features/study/domain/support/fake_study_home_repository.dart';

/// The two hero primaries agree on how wide they are.
///
/// **Both buttons say *start studying*, and they used to disagree by 2.6x.**
/// Measured off the 393dp goldens: Library's *Study 15 due cards* ran 329dp
/// edge to edge inside its card, Study Home's *Resume* hugged its label at
/// 127dp. They begin at the same x, so side by side they read as one element
/// that got cut short rather than as two decisions.
///
/// Study Home's rule was the one with a reason written down — stretch only
/// below the compact tier, where a hugging primary looks stranded — so at
/// M100.7 Library adopted it rather than the other way round.
///
/// **The trap this pins is a measurement, not a preference.** The rule reads
/// the *card's* width, and a `LayoutBuilder` placed inside the card's padding
/// sees 32dp less: at 393dp that is 329, under the 360 tier, so the stretched
/// branch runs on every phone and the rule silently does nothing. Study Home
/// shipped exactly that once — its own comment records that "the golden had
/// quietly stamped the wrong branch". A width assertion is the only thing that
/// catches it, because both branches build, lay out and render fine.
void main() {
  /// The reference device, and one below the tier. 393 gives each card 361dp
  /// after the 16dp page gutters — 1dp above the threshold, which is why this
  /// file exists rather than a comment.
  const double referenceWidth = 393;
  const double crampedWidth = 320;

  Widget host({required double width, required Widget child}) => MediaQuery(
    data: MediaQueryData(size: Size(width, 900)),
    child: MaterialApp(
      theme: buildLightTheme(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Padding(
          // The page gutter the shell applies, so `maxWidth` inside is the
          // card's width exactly as it is on the screen.
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Align(alignment: Alignment.topCenter, child: child),
        ),
      ),
    ),
  );

  Future<double> primaryWidth(
    WidgetTester tester,
    Widget widget,
    double width,
  ) async {
    tester.view.physicalSize = Size(width, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(host(width: width, child: widget));
    await tester.pump();

    return tester.getSize(find.byType(MxActionButton).first).width;
  }

  Widget libraryHero() => DeckLevelSummaryWidget(
    snapshot: DeckListSnapshot(
      parent: null,
      ancestors: <DeckPathSegment>[],
      nextDueAt: null,
      nextOverdueTickAt: null,
      decks: <DeckSummary>[
        fakeSummary(
          id: '1',
          name: 'Academic Word List',
          totalCardCount: 868,
          dueCardCount: 15,
        ),
      ],
    ),
    isExpanded: false,
    onToggleExpanded: () {},
    onStudyDue: () {},
  );

  Widget studyHero() => StudyHomeResumeSectionWidget(
    resume: fakeStudyHomeResume(),
    onResume: () {},
  );

  group('above the compact tier both primaries hug their label', () {
    testWidgets('Library', (tester) async {
      final width = await primaryWidth(tester, libraryHero(), referenceWidth);

      expect(
        width,
        lessThan(referenceWidth - 32 - 32),
        reason:
            'The Library hero primary is filling its card at $referenceWidth. '
            'Either the rule was removed, or the LayoutBuilder moved inside the '
            "card's padding and is seeing the content width — the failure Study "
            'Home already shipped once.',
      );
    });

    testWidgets('Study Home', (tester) async {
      final width = await primaryWidth(tester, studyHero(), referenceWidth);

      expect(width, lessThan(referenceWidth - 32 - 32));
    });
  });

  group('below the compact tier both stretch', () {
    testWidgets('Library', (tester) async {
      final width = await primaryWidth(tester, libraryHero(), crampedWidth);

      expect(
        width,
        greaterThan(crampedWidth - 32 - 32 - 1),
        reason:
            'At $crampedWidth the card is ${crampedWidth - 32}dp, under the '
            '${AppBreakpoints.compact} tier, so the primary should run the full '
            'width of the card rather than stranding itself at one end.',
      );
    });

    testWidgets('Study Home', (tester) async {
      final width = await primaryWidth(tester, studyHero(), crampedWidth);

      expect(width, greaterThan(crampedWidth - 32 - 32 - 1));
    });
  });

  test('the reference device sits just above the tier, not comfortably', () {
    // Pins the arithmetic the two groups above depend on. 393 minus two 16dp
    // gutters is 361, and the tier is 360: a one-pixel margin. If a future
    // gutter change eats that margin, both heroes flip to the stretched branch
    // silently and the groups above still pass — they assert the branch, not
    // the distance to it.
    const double cardAtReference = referenceWidth - 32;

    expect(AppBreakpoints.isCompact(cardAtReference), isFalse);
    expect(
      cardAtReference - AppBreakpoints.compact,
      lessThanOrEqualTo(2),
      reason:
          'The margin above the compact tier grew, so this file is no longer '
          'measuring the knife-edge it was written for — recheck which branch '
          'the reference device actually takes',
    );
  });
}
