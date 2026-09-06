import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/navigation/route_names.dart';
import 'package:memox/features/study/presentation/screens/study_entry_screen.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';
import 'package:memox/shared/widgets/mx_content_shell.dart';

import '../../../visual_audit/study_audit_harness.dart';
import '../domain/support/fake_study_repository.dart';
import 'support/study_widget_harness.dart';

/// A deck-scoped screen says which deck it is scoped to.
///
/// **This was the only screen in the app titled with the product name**
/// (SC-C9-09, SC-C9-15). `context.l10n.appTitle` was the app-bar title, and it
/// is the only `appTitle` among the eighteen `MxContentShell` titles in
/// `lib/features/` — a string whose own ARB description scopes it to the
/// `MaterialApp` title and the Android task switcher. Arriving from a named
/// deck row in the Study tab, the back stack read `Study → MemoX`.
///
/// **Two reads, not one, and this file pins the reason.** AD-13's one-read rule
/// is about two facts a screen renders together; the counts are a `watch()`
/// stream over card state and the name is a property of the deck row, with
/// different lifetimes. Folding the name into `StudyEntrySummaryModel` would
/// re-emit it on every answered card — and it would take the title down with
/// the counts, which the failure-face test shows it does not.
void main() {
  final english = AppLocalizationsEn();

  Future<void> pumpEntry(
    WidgetTester tester, {
    FakeStudyRepository? repository,
  }) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      studyScreenWith(
        repository ?? FakeStudyRepository(),
        wrapForTest(
          const StudyEntryScreen(
            deckId: 'deck-1',
            optionsRouteName: RouteNames.deckStudyOptions,
            homeRouteName: RouteNames.study,
          ),
          isScrollable: false,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('the app bar names the deck', (tester) async {
    await pumpEntry(tester);

    expect(
      tester.widget<MxContentShell>(find.byType(MxContentShell)).title,
      'Korean',
    );
  });

  testWidgets('the product name appears nowhere on the screen', (tester) async {
    await pumpEntry(tester);

    // Not "not in the app bar" — nowhere. It was the app-bar title and, until
    // C3, the error face's heading too.
    expect(find.text(english.appTitle), findsNothing);
  });

  testWidgets('a rename reaches the app bar without remounting the screen', (
    tester,
  ) async {
    final repository = FakeStudyRepository();
    addTearDown(repository.deckContextChanges.close);
    await pumpEntry(tester, repository: repository);

    expect(
      tester.widget<MxContentShell>(find.byType(MxContentShell)).title,
      'Korean',
    );

    // The element the screen is mounted in, captured so the assertion below is
    // about *this* screen surviving rather than about a new one appearing with
    // the right name.
    final Element before = tester.element(find.byType(StudyEntryScreen));

    // A rename arriving from anywhere — a Drift `watch()` re-emitting after an
    // UPDATE. Nothing on this screen asked for it.
    repository.renameDeck('deck-1', 'Tiếng Hàn');
    await tester.pumpAndSettle();

    expect(
      tester.widget<MxContentShell>(find.byType(MxContentShell)).title,
      'Tiếng Hàn',
    );
    // **The point of making the read a stream.** A `Future` provider could only
    // have produced this by being invalidated, which means something had to
    // rebuild the route — and `StatefulShellRoute.indexedStack` keeps this
    // branch mounted precisely so that does not happen.
    expect(tester.element(find.byType(StudyEntryScreen)), same(before));
  });

  testWidgets('the fallback is this screen\'s own key, not the tab home\'s', (
    tester,
  ) async {
    // `studyHomeTitle` and `studyEntryTitle` are the same word in both locales,
    // which is exactly why the wrong one would never be noticed: this screen is
    // mounted in the Library branch as well as the Study one, so from Library
    // it is not the Study tab at all, and `studyHomeTitle`'s own description
    // says it belongs to UC-14.
    expect(english.studyEntryTitle, english.studyHomeTitle);
    expect(english.studyEntryTitle, isNot(english.appTitle));
  });
}
