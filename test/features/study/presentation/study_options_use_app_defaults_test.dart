import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/study/di/study_repository_provider.dart';
import 'package:memox/features/study/presentation/screens/study_options_screen.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';

import '../domain/support/fake_study_repository.dart';
import 'support/study_widget_harness.dart';

/// `Use app defaults` on the deck's own options surface (BR-184, wireframe S6).
///
/// **On this screen and not on the app-wide Settings page.** The action affects
/// one deck, and a global page offering it would need a deck picker — a second
/// screen inside the first.
void main() {
  final english = AppLocalizationsEn();

  Future<void> pumpOptions(
    WidgetTester tester,
    FakeStudyRepository repository,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [studyRepositoryProvider.overrideWithValue(repository)],
        // `isScrollable: false`: this is a whole screen with its own
        // `Scaffold`, and the harness's default scroll view would hand it an
        // unbounded height — which is an assertion rather than a layout.
        child: wrapForTest(
          const StudyOptionsScreen(deckId: 'd1'),
          isScrollable: false,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('a deck with no override offers nothing to clear', (
    tester,
  ) async {
    // An action that would clear nothing is an action that teaches the user it
    // does nothing.
    await pumpOptions(tester, FakeStudyRepository());

    expect(find.text(english.studyOptionsUseAppDefaults), findsNothing);
    expect(find.text(english.studyOptionsOverrideNote), findsNothing);
  });

  testWidgets('a deck with an override says so and offers the action', (
    tester,
  ) async {
    // The note answers the question a user actually arrives with: why did
    // changing the app defaults not change this deck?
    await pumpOptions(tester, FakeStudyRepository()..isRootOverride = true);

    expect(find.text(english.studyOptionsOverrideNote), findsOneWidget);
    expect(find.text(english.studyOptionsUseAppDefaults), findsOneWidget);
  });

  testWidgets('tapping it clears the override through the repository', (
    tester,
  ) async {
    final repository = FakeStudyRepository()..isRootOverride = true;
    await pumpOptions(tester, repository);

    await tester.ensureVisible(find.text(english.studyOptionsUseAppDefaults));
    await tester.pumpAndSettle();
    await tester.tap(find.text(english.studyOptionsUseAppDefaults));
    await tester.pumpAndSettle();

    expect(repository.clearedOverrides, <String>['d1']);
  });

  testWidgets('it saves nothing — clearing is not a save of the current '
      'values', (tester) async {
    // Writing today's defaults onto the deck would look identical now and stop
    // being true the next time somebody edits Settings.
    final repository = FakeStudyRepository()..isRootOverride = true;
    await pumpOptions(tester, repository);

    await tester.ensureVisible(find.text(english.studyOptionsUseAppDefaults));
    await tester.pumpAndSettle();
    await tester.tap(find.text(english.studyOptionsUseAppDefaults));
    await tester.pumpAndSettle();

    expect(repository.savedOptions, isEmpty);
  });

  testWidgets('the screen stays open, which is the confirmation', (
    tester,
  ) async {
    // A save closes this screen; a clear does not — popping would leave the
    // user to come back in and check what the deck now uses.
    final repository = FakeStudyRepository()..isRootOverride = true;
    await pumpOptions(tester, repository);

    await tester.ensureVisible(find.text(english.studyOptionsUseAppDefaults));
    await tester.pumpAndSettle();
    await tester.tap(find.text(english.studyOptionsUseAppDefaults));
    await tester.pumpAndSettle();

    expect(find.byType(StudyOptionsScreen), findsOneWidget);
  });
}
