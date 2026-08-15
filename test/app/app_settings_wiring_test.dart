import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/app/app.dart';
import 'package:memox/app/config/env_config.dart';
import 'package:memox/app/config/env_config_provider.dart';
import 'package:memox/app/router/app_router.dart';
import 'package:memox/features/deck/di/deck_repository_provider.dart';
import 'package:memox/features/settings/di/app_settings_repository_provider.dart';
import 'package:memox/features/settings/domain/models/app_language_model.dart';
import 'package:memox/features/settings/domain/models/app_settings_model.dart';
import 'package:memox/features/settings/domain/models/app_theme_mode_model.dart';
import 'package:memox/features/study/di/study_repository_provider.dart';

import '../features/deck/presentation/support/fake_deck_repository.dart';
import '../features/settings/domain/support/fake_app_settings_repository.dart';
import '../features/study/domain/support/fake_study_repository.dart';

/// The seam between the stored settings and `MaterialApp` (BR-214, BR-215,
/// AD-19).
///
/// **Through the real root widget, not through a helper.** The claim is that
/// `MemoxApp` reads the feature's provider and hands the two values to
/// `MaterialApp`; asserting on a mapping function would prove the function and
/// say nothing about the wiring.
void main() {
  Future<MaterialApp> pumpRoot(
    WidgetTester tester,
    FakeAppSettingsRepository repository,
  ) async {
    final router = createAppRouter();
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          envConfigProvider.overrideWithValue(EnvConfig.development),
          appSettingsRepositoryProvider.overrideWithValue(repository),
          deckRepositoryProvider.overrideWithValue(FakeDeckRepository()),
          studyRepositoryProvider.overrideWithValue(FakeStudyRepository()),
        ],
        child: MemoxApp(router: router),
      ),
    );
    await tester.pumpAndSettle();

    return tester.widget<MaterialApp>(find.byType(MaterialApp));
  }

  group('theme', () {
    testWidgets('a stored system choice keeps following the platform', (
      tester,
    ) async {
      // `ThemeMode.system` and not a brightness resolved once: the app has to
      // keep following the platform rather than freezing at whatever it was on
      // the frame the row was read (BR-214).
      final app = await pumpRoot(tester, FakeAppSettingsRepository());

      expect(app.themeMode, ThemeMode.system);
    });

    testWidgets('a stored explicit choice wins over the platform', (
      tester,
    ) async {
      final app = await pumpRoot(
        tester,
        FakeAppSettingsRepository(
          initial: AppSettingsModel.defaults.copyWith(
            themeMode: AppThemeMode.dark,
          ),
        ),
      );

      expect(app.themeMode, ThemeMode.dark);
    });

    testWidgets('a write reaches MaterialApp without rebuilding the router', (
      tester,
    ) async {
      // BR-214: the change applies in the same run — no restart, and no new
      // `GoRouter`, because a new router means a lost navigation stack.
      final repository = FakeAppSettingsRepository();
      var app = await pumpRoot(tester, repository);
      final routerBefore = app.routerConfig;

      await repository.saveThemeMode(AppThemeMode.light);
      await tester.pumpAndSettle();
      app = tester.widget<MaterialApp>(find.byType(MaterialApp));

      expect(app.themeMode, ThemeMode.light);
      expect(app.routerConfig, same(routerBefore));
    });

    testWidgets('the theme change is instant, not a cross-fade', (
      tester,
    ) async {
      // A 200ms animation renders intermediate colours — a third theme on the
      // way between two — which BR-214 and the wireframe both rule out. It is
      // also what makes the cold-start resolution read as "the app started
      // dark" rather than as a fade somebody has to watch.
      final app = await pumpRoot(tester, FakeAppSettingsRepository());

      expect(app.themeAnimationDuration, Duration.zero);
    });
  });

  group('language', () {
    testWidgets('a stored system choice leaves the locale to the platform', (
      tester,
    ) async {
      // Null is how `MaterialApp` is told to resolve from the platform's
      // preferred locales over `supportedLocales` (BR-215).
      final app = await pumpRoot(tester, FakeAppSettingsRepository());

      expect(app.locale, isNull);
    });

    testWidgets('a stored explicit choice becomes the locale', (tester) async {
      final app = await pumpRoot(
        tester,
        FakeAppSettingsRepository(
          initial: AppSettingsModel.defaults.copyWith(
            language: AppLanguage.vietnamese,
          ),
        ),
      );

      expect(app.locale, const Locale('vi'));
    });

    testWidgets('a write reaches MaterialApp in the same run', (tester) async {
      final repository = FakeAppSettingsRepository();
      await pumpRoot(tester, repository);

      await repository.saveLanguage(AppLanguage.english);
      await tester.pumpAndSettle();

      expect(
        tester.widget<MaterialApp>(find.byType(MaterialApp)).locale,
        const Locale('en'),
      );
    });
  });

  group('before the first emission', () {
    testWidgets('the app renders on the defaults rather than not at all', (
      tester,
    ) async {
      // The accepted trade: a local SQLite read resolves within a frame or
      // two, and blocking the first frame on it would show a blank window
      // instead. `System` is also what every build before M99.28 did.
      final router = createAppRouter();
      addTearDown(router.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            envConfigProvider.overrideWithValue(EnvConfig.development),
            appSettingsRepositoryProvider.overrideWithValue(
              _NeverEmittingRepository(),
            ),
            deckRepositoryProvider.overrideWithValue(FakeDeckRepository()),
            studyRepositoryProvider.overrideWithValue(FakeStudyRepository()),
          ],
          child: MemoxApp(router: router),
        ),
      );
      await tester.pump();

      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.themeMode, ThemeMode.system);
      expect(app.locale, isNull);
    });
  });
}

/// A repository whose read never emits, for the first-frame case.
final class _NeverEmittingRepository extends FakeAppSettingsRepository {
  _NeverEmittingRepository();

  @override
  Stream<AppSettingsModel> watch() => const Stream<AppSettingsModel>.empty();
}
