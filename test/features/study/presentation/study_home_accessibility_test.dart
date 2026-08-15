import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/app/app.dart';
import 'package:memox/app/config/env_config.dart';
import 'package:memox/app/config/env_config_provider.dart';
import 'package:memox/app/router/app_router.dart';
import 'package:memox/app/router/route_paths.dart';
import 'package:memox/core/time/clock_provider.dart';
import 'package:memox/core/time/time_zone_provider.dart';
import 'package:memox/features/deck/di/deck_repository_provider.dart';
import 'package:memox/features/study/di/study_home_repository_provider.dart';
import 'package:memox/features/study/di/study_repository_provider.dart';
import 'package:memox/features/study/presentation/widgets/items/study_home_deck_item_widget.dart';
import 'package:memox/features/study/presentation/widgets/items/study_home_workload_item_widget.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';

import '../../deck/presentation/support/fake_deck_repository.dart';
import '../domain/support/fake_study_home_repository.dart';
import '../domain/support/fake_study_repository.dart';

/// What Study Home owes somebody who is not looking at it (UC-14, R5…R7).
///
/// **Rendered through the real router, with semantics switched on.** The three
/// claims here — the counts are one phrase, the actions are named after their
/// deck, and no signal is carried by colour alone — were each recorded in the
/// wireframe with the *source* cited as their evidence. Quoting the widget that
/// is supposed to satisfy a rule is not verification of it; this file is.
void main() {
  final english = AppLocalizationsEn();
  final now = DateTime.utc(2026, 8, 13, 9);

  late FakeStudyHomeRepository repository;

  tearDown(() => repository.dispose());

  Future<void> pumpHome(WidgetTester tester) async {
    repository = FakeStudyHomeRepository(
      initial: fakeStudyHome(resume: fakeStudyHomeResume()),
    );
    final router = createAppRouter(initialLocation: RoutePaths.study);
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          envConfigProvider.overrideWithValue(EnvConfig.development),
          deckRepositoryProvider.overrideWithValue(FakeDeckRepository()),
          studyRepositoryProvider.overrideWithValue(FakeStudyRepository()),
          studyHomeRepositoryProvider.overrideWithValue(repository),
          clockProvider.overrideWithValue(() => now),
          utcOffsetProvider.overrideWithValue(() => const Duration(hours: 7)),
        ],
        child: MemoxApp(router: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('the three counts are heard as one phrase, not three numbers', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpHome(tester);

    final node = tester.getSemantics(
      find.byType(StudyHomeWorkloadItemWidget).first,
    );

    expect(node.label, english.studyHomeWorkloadSemanticLabel(2, 5, 12));
    // The individual labels are excluded rather than merged: three sibling
    // nodes reading "2 overdue", "5 due today", "12 new" is what a badge soup
    // sounds like, and nothing in it says the three belong to one deck.
    expect(
      find.descendant(
        of: find.byType(StudyHomeWorkloadItemWidget).first,
        matching: find.bySemanticsLabel(english.studyHomeOverdueLabel(2)),
      ),
      findsNothing,
    );
    handle.dispose();
  });

  testWidgets('every action is named after the deck it acts on', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpHome(tester);

    // Every row carries the same verb, so without the deck name a screen reader
    // walking the list hears "Study" three times with nothing to tell the rows
    // apart.
    expect(
      find.bySemanticsLabel(
        english.studyHomeResumeSemanticLabel('Everyday Korean'),
      ),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(
        english.studyHomeStudySemanticLabel('Everyday Korean'),
      ),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(
        english.studyHomeStudySemanticLabel('Kanji basics'),
      ),
      findsOneWidget,
    );
    handle.dispose();
  });

  testWidgets('a renamed action is still a button that can be activated', (
    tester,
  ) async {
    // `excludeSemantics` replaces the button's own node, so the wrapper has to
    // put back what it removed. A label with no `button` flag and no tap action
    // is a control TalkBack announces as text and cannot activate.
    final handle = tester.ensureSemantics();
    await pumpHome(tester);

    expect(
      tester.getSemantics(
        find.bySemanticsLabel(
          english.studyHomeStudySemanticLabel('Everyday Korean'),
        ),
      ),
      matchesSemantics(
        label: english.studyHomeStudySemanticLabel('Everyday Korean'),
        isButton: true,
        hasTapAction: true,
        // The state, not just the role. A renamed control that lost
        // `hasEnabledState` would be announced as actionable even while it is
        // inert — which is what the wrapper this replaced actually did.
        hasEnabledState: true,
        isEnabled: true,
        // Focusable follows enabled, the way the `Focus` under the button does.
        // A node that claimed to be a button and not to be focusable would
        // describe a control the rest of the tree cannot explain.
        isFocusable: true,
      ),
    );
    handle.dispose();
  });

  testWidgets('no count is told apart by colour alone', (tester) async {
    await pumpHome(tester);

    final row = find.byType(StudyHomeDeckItemWidget).first;

    // Each metric carries a glyph and a word as well as its ink, so the three
    // read apart in greyscale and to anyone who does not perceive the hues
    // (BR-201). The words are the counts themselves; the glyphs are these.
    for (final icon in <IconData>[
      Icons.history,
      Icons.today,
      Icons.auto_awesome,
    ]) {
      expect(
        find.descendant(of: row, matching: find.byIcon(icon)),
        findsOneWidget,
      );
    }
    for (final label in <String>[
      english.studyHomeOverdueLabel(2),
      english.studyHomeDueTodayLabel(5),
      english.studyHomeNewLabel(12),
    ]) {
      expect(
        find.descendant(of: row, matching: find.text(label)),
        findsOneWidget,
      );
    }
  });

  testWidgets('every action clears the tap-target guideline', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpHome(tester);

    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
  });
}
