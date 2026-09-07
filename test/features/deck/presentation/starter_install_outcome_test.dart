import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/deck/domain/models/scheduler_type_model.dart';
import 'package:memox/features/deck/domain/repositories/deck_template_repository.dart';
import 'package:memox/shared/widgets/mx_sheet_insets.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';

import 'support/starter_library_harness.dart';

/// The three things an install can finish as, and the footer each one leaves.
///
/// **Split from `starter_library_test.dart` at the size guard**, along the seam
/// that file already had: everything there is about the catalogue screen — its
/// rows, its rhythm, its failed read — and this is about what one install
/// *returns* and what the sheet does with it.
///
/// The matrix is the point:
///
/// | outcome | sheet | footer |
/// |---|---|---|
/// | `installed` | closes | — |
/// | failure | stays | `Add deck`, live for the retry |
/// | `alreadyPresent` | stays | `Close` — a retry reaches the same answer |
void main() {
  final english = AppLocalizationsEn();

  testWidgets('a row discloses name, size, language, source and the fixture '
      'notice (BR-87)', (tester) async {
    await pumpStarterLibrary(tester);

    expect(find.text('Everyday English'), findsOneWidget);
    expect(
      find.textContaining(english.starterLibraryCardCount(1)),
      findsOneWidget,
    );
    expect(
      find.textContaining(english.starterLibraryLocaleLabel('en')),
      findsOneWidget,
    );
    // **The language, not its code.** The row used to read `Language: en` —
    // the schema's value shown to a reader on the first screen an empty
    // library is offered. The names are endonyms and stay untranslated, for
    // the reason `settingsLanguageEnglish` records.
    expect(english.starterLibraryLocaleLabel('en'), 'Language: English');
    expect(english.starterLibraryLocaleLabel('ko'), 'Language: 한국어');
    expect(english.starterLibraryLocaleLabel('vi'), 'Language: Tiếng Việt');
    // A template in a language nobody has named yet still says something.
    expect(english.starterLibraryLocaleLabel('ja'), 'Language: ja');
    expect(
      find.text(english.starterLibrarySource('memox-fixture')),
      findsOneWidget,
    );
    // Not production content, and the screen says so rather than implying it.
    expect(find.text(english.starterLibraryFixtureNotice), findsOneWidget);
  });

  testWidgets('installing: scheduler defaults from the template, one write, '
      'sheet closes', (tester) async {
    final repository = await pumpStarterLibrary(tester);

    await tester.tap(find.text('Everyday English'));
    await tester.pumpAndSettle();

    // The sheet asks the one question a copy needs (BR-34).
    expect(
      find.text(english.starterLibrarySchedulerPrompt.toUpperCase()),
      findsOneWidget,
    );

    await tester.tap(find.text(english.starterLibraryInstallAction).last);
    await tester.pumpAndSettle();

    expect(repository.installs, hasLength(1));
    expect(repository.installs.single.schedulerType, SchedulerType.eightBox);
    expect(
      find.text(english.starterLibrarySchedulerPrompt.toUpperCase()),
      findsNothing,
    );
  });

  testWidgets('cancelling the sheet installs nothing', (tester) async {
    final repository = await pumpStarterLibrary(tester);

    await tester.tap(find.text('Everyday English'));
    await tester.pumpAndSettle();
    // Swipe the sheet away rather than confirming.
    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();

    expect(repository.installs, isEmpty);
  });

  group('a copy that found the deck already there (BR-37)', () {
    // The race the in-transaction check exists for: the catalogue row said the
    // template was not installed, and by the time the write ran it was. The
    // outcome is a *finished* write that copied nothing — not a failure, and
    // not an install.

    /// Scoped to the sheet: the catalogue row behind it carries the same
    /// `Add deck` label, so an unscoped `findsNothing` asks the wrong
    /// question and an unscoped `findsWidgets` answers itself.
    Finder inSheet(String label) => find.descendant(
      of: find.byType(MxSheetInsets),
      matching: find.text(label),
    );

    Future<void> install(WidgetTester tester) async {
      await tester.tap(find.text('Everyday English'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(english.starterLibraryInstallAction).last);
      await tester.pumpAndSettle();
    }

    testWidgets('says so, and stops offering the tap that cannot work', (
      tester,
    ) async {
      // **The retry was a loop.** Add deck stayed live under the notice, and
      // pressing it reached the same answer and painted the same band — an
      // action whose only effect was to prove it had no effect. It is replaced
      // by the one thing left to do rather than merely disabled, because a
      // greyed Add deck still says "adding is the thing here" about a deck
      // that is already added.
      await pumpStarterLibrary(
        tester,
        outcome: DeckTemplateInstallOutcome.alreadyPresent,
      );
      await install(tester);

      expect(
        find.text(english.starterLibraryAlreadyPresentTitle),
        findsOneWidget,
      );
      expect(
        find.text(english.starterLibraryCloseAction),
        findsOneWidget,
        reason: 'the terminal state needs a deterministic way out',
      );
      expect(
        inSheet(english.starterLibraryInstallAction),
        findsNothing,
        reason: 'nothing here can be added, so nothing may offer to add it',
      );
      // Not dressed as a failure: nothing rolled back.
      expect(find.text(english.starterLibraryInstallErrorTitle), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('and the way out actually closes the sheet', (tester) async {
      await pumpStarterLibrary(
        tester,
        outcome: DeckTemplateInstallOutcome.alreadyPresent,
      );
      await install(tester);

      await tester.tap(find.text(english.starterLibraryCloseAction));
      await tester.pumpAndSettle();

      expect(
        find.text(english.starterLibraryAlreadyPresentTitle),
        findsNothing,
      );
      // The catalogue, not the Library: nothing was added, so there is nothing
      // for the screen behind to pop back to.
      expect(find.text(english.starterLibraryTitle), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a fresh sheet does not inherit the terminal state', (
      tester,
    ) async {
      // The controller is autoDispose and the sheet is its only listener, so
      // closing it drops the state. Asserted rather than assumed: a `keepAlive`
      // added later would silently open the next install already finished, with
      // Close where Add deck belongs and no way to install anything.
      await pumpStarterLibrary(
        tester,
        outcome: DeckTemplateInstallOutcome.alreadyPresent,
      );
      await install(tester);
      await tester.tap(find.text(english.starterLibraryCloseAction));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Everyday English'));
      await tester.pumpAndSettle();

      expect(
        inSheet(english.starterLibraryInstallAction),
        findsOneWidget,
        reason: 'a new sheet starts able to install',
      );
      expect(
        find.text(english.starterLibraryAlreadyPresentTitle),
        findsNothing,
      );
    });

    testWidgets('an ordinary install still closes the sheet', (tester) async {
      // The counterpart, so the branch above cannot be satisfied by a sheet
      // that simply stopped closing.
      await pumpStarterLibrary(tester);
      await install(tester);

      expect(
        find.text(english.starterLibraryAlreadyPresentTitle),
        findsNothing,
      );
      expect(find.byType(MxSheetInsets), findsNothing);
      expect(find.text(english.starterLibraryCloseAction), findsNothing);
    });

    testWidgets('a real failure keeps the retry it can use', (tester) async {
      // The distinction the whole group turns on: failure retries,
      // alreadyPresent closes, installed closes normally.
      await pumpStarterLibrary(tester, failWith: 'disk full');
      await install(tester);

      expect(
        find.text(english.starterLibraryInstallErrorTitle),
        findsOneWidget,
      );
      expect(
        inSheet(english.starterLibraryInstallAction),
        findsOneWidget,
        reason: 'a retry here can genuinely succeed',
      );
      expect(
        find.text(english.starterLibraryAlreadyPresentTitle),
        findsNothing,
      );
      expect(find.text(english.starterLibraryCloseAction), findsNothing);
    });
  });
}
