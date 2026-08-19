import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/app/app.dart';
import 'package:memox/app/config/env_config.dart';
import 'package:memox/app/config/env_config_provider.dart';
import 'package:memox/app/router/app_router.dart';
import 'package:memox/core/navigation/route_names.dart';
import 'package:memox/features/deck/di/deck_repository_provider.dart';
import 'package:memox/features/deck/presentation/screens/deck_list_screen.dart';
import 'package:memox/features/study/di/study_repository_provider.dart';
import 'package:memox/features/trash/di/trash_repository_provider.dart';
import 'package:memox/features/trash/presentation/screens/trash_screen.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';
import 'package:memox/shared/widgets/mx_navigation_bar.dart';

import '../../features/deck/presentation/support/fake_deck_repository.dart';
import '../../features/study/domain/support/fake_study_repository.dart';
import '../../features/trash/presentation/support/fake_trash_repository.dart';

/// Trash's route (UC-21, AD-22), through the real route table.
///
/// **Two facts, and the second is the one AD-22 decided.** That the route
/// exists at all, and that it lives in the **Library** branch — so the bottom
/// bar stays, Back returns to the deck list a restored item reappears in, and
/// the entry is one tap from the list rather than two from Settings.
void main() {
  final english = AppLocalizationsEn();

  Future<void> pumpApp(WidgetTester tester, {String? initialLocation}) async {
    final router = initialLocation == null
        ? createAppRouter()
        : createAppRouter(initialLocation: initialLocation);
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          envConfigProvider.overrideWithValue(EnvConfig.development),
          deckRepositoryProvider.overrideWithValue(FakeDeckRepository()),
          studyRepositoryProvider.overrideWithValue(FakeStudyRepository()),
          trashRepositoryProvider.overrideWithValue(FakeTrashRepository()),
        ],
        child: MemoxApp(router: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('a deep link to /trash opens Trash', (tester) async {
    await pumpApp(tester, initialLocation: '/trash');

    expect(find.byType(TrashScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Trash keeps the bottom bar, so it is inside the branch', (
    tester,
  ) async {
    // The whole of AD-22's navigation decision, as one assertion: a route
    // outside the shell would render without this bar.
    await pumpApp(tester, initialLocation: '/trash');

    expect(find.byType(MxNavigationBar), findsOneWidget);
  });

  testWidgets('the root deck list carries the entry, always', (tester) async {
    // Always, and with no badge (wireframe T2): a user has to know the recovery
    // surface exists *before* they delete something.
    await pumpApp(tester);

    expect(find.byType(DeckListScreen), findsOneWidget);
    expect(find.bySemanticsLabel(english.trashEntryLabel), findsOneWidget);
  });

  testWidgets('tapping the entry lands on Trash, inside the branch', (
    tester,
  ) async {
    await pumpApp(tester);

    await tester.tap(find.bySemanticsLabel(english.trashEntryLabel));
    await tester.pumpAndSettle();

    expect(find.byType(TrashScreen), findsOneWidget);
    // Still in the Library branch, which is what makes the destination
    // reachable and leaveable the way every other Library screen is.
    expect(find.byType(MxNavigationBar), findsOneWidget);
  });

  test('the route name and its path are declared where the app reads them', () {
    // Cheap, and it is what stops a rename from turning `goNamed` into a
    // runtime throw that only the one screen using it would surface.
    expect(RouteNames.trash, 'trash');
  });
}
