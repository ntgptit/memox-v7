import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/card/presentation/screens/card_import_screen.dart';
import 'package:memox/features/study/presentation/screens/study_entry_screen.dart';
import 'package:memox/features/study/presentation/screens/study_home_screen.dart';
import 'package:memox/features/study/presentation/screens/study_options_screen.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';
import 'package:memox_widgetbook/screens/card_import_screen_use_case.dart';
import 'package:memox_widgetbook/screens/study_screens_use_case.dart';
import 'package:memox_widgetbook/support/catalog_route_stub.dart';
import 'package:widgetbook/widgetbook.dart';

import 'support/catalog_harness.dart';

/// The catalog's controls are pressed, not just built.
///
/// **A mount-only smoke test cannot see this class of defect, and did not.**
/// `catalog_smoke_test.dart` builds every use-case and asserts nothing threw —
/// which is true of a screen whose every navigation control throws the moment
/// it is touched, because building it touches none of them. Both screens below
/// shipped that way: mounted bare, `context.goNamed` finds no `GoRouter` above
/// it and throws `GoError`, so the deck path, the wizard's `✕`, `View cards`
/// and the study options button were all dead in the one place a reviewer is
/// expected to press them.
///
/// So these tests tap. Each one asserts the destination arrived **and** that
/// nothing was thrown: `takeException` is where a `GoError` from a tap ends
/// up, and without that line a test could pass on a screen that navigated and
/// exploded on the way.
void main() {
  final AppLocalizationsEn english = AppLocalizationsEn();

  WidgetbookComponent studyComponent(String name) => studyScreenComponents()
      .firstWhere((WidgetbookComponent component) => component.name == name);

  group('Study', () {
    testWidgets('the options action opens the options screen', (tester) async {
      await pumpUseCase(tester, studyComponent('StudyEntryScreen'));
      expect(find.byType(StudyEntryScreen), findsOneWidget);

      await tester.tap(find.bySemanticsLabel(english.studyOptionsTitle).first);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(StudyOptionsScreen), findsOneWidget);
    });

    testWidgets('and Back from the options returns to the entry', (
      tester,
    ) async {
      await pumpUseCase(tester, studyComponent('StudyEntryScreen'));
      await tester.tap(find.bySemanticsLabel(english.studyOptionsTitle).first);
      await tester.pumpAndSettle();

      // `pushNamed`, so the entry is still underneath — the property the
      // screen's own `_openOptions` depends on for its post-return refresh.
      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(StudyOptionsScreen), findsNothing);
      expect(find.byType(StudyEntryScreen), findsOneWidget);
    });

    testWidgets('a deck row on Study Home opens that deck', (tester) async {
      await pumpUseCase(tester, studyComponent('StudyHomeScreen'));
      expect(find.byType(StudyHomeScreen), findsOneWidget);

      // The row's own action, named the way a screen reader reads it. The deck
      // is `catalog-deck` — the one every other Study use-case is scoped to —
      // so the entry it opens is the one the catalogue has data for.
      await tester.tap(
        find.bySemanticsLabel(RegExp('Study Tiếng Hàn giao tiếp')),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(StudyEntryScreen), findsOneWidget);
    });
  });

  group('Card import', () {
    testWidgets('the deck path leaves the wizard for the deck', (tester) async {
      await pumpUseCase(tester, cardImportScreenComponent());
      expect(find.byType(CardImportScreen), findsOneWidget);

      // The whole strip is one target when `onUp` is set (SC-C4-07), and its
      // semantics label is what names it. Matched as a `RegExp` rather than a
      // bare string because the strip is one button: every step below it
      // merges into the node, so the label reads `Deck path` followed by the
      // whole path, and an exact match finds nothing.
      await tester.tap(
        find.bySemanticsLabel(RegExp(english.deckPathSemanticLabel)),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(CardImportScreen), findsNothing);
      expect(find.byType(CatalogRouteStubPage), findsOneWidget);
    });

    testWidgets('and Cancel pops to the list the wizard opened from', (
      tester,
    ) async {
      await pumpUseCase(tester, cardImportScreenComponent());

      await tester.tap(find.bySemanticsLabel(english.commonCancelAction).first);
      await tester.pumpAndSettle();

      // Nothing pasted, so there is no draft to confirm away — the exit is
      // immediate, and it is a pop rather than the deep-link fallback because
      // the router opened at the nested location the app uses.
      expect(tester.takeException(), isNull);
      expect(find.byType(CardImportScreen), findsNothing);
      expect(
        tester
            .widget<CatalogRouteStubPage>(find.byType(CatalogRouteStubPage))
            .routeName,
        'Card list',
      );
    });
  });
}
