import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/features/settings/di/app_settings_repository_provider.dart';
import 'package:memox/features/settings/presentation/screens/settings_screen.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

import '../../domain/support/fake_app_settings_repository.dart';

/// Mounts `SettingsScreen` under a real theme, real localizations and a fake
/// repository.
///
/// **A real theme, not a bare `MaterialApp`.** Half of what this screen does is
/// read tokens, and a default theme would let a hardcoded colour pass a test it
/// should fail. Real localizations for the same reason: a widget that reached
/// for a literal instead of ARB would still render, and the test would agree.
///
/// [surface] and [textScale] are parameters because the wireframe's responsive
/// contract names specific combinations — 320dp at 2.0 in particular, where the
/// longest Vietnamese label meets the narrowest screen.
Future<void> pumpSettings(
  WidgetTester tester,
  FakeAppSettingsRepository repository, {
  Brightness brightness = Brightness.light,
  Locale locale = const Locale('en'),
  Size surface = const Size(390, 780),
  double textScale = 1,
  bool shouldSettle = true,
}) async {
  await tester.binding.setSurfaceSize(surface);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    ProviderScope(
      overrides: [appSettingsRepositoryProvider.overrideWithValue(repository)],
      child: MaterialApp(
        theme: brightness == Brightness.dark
            ? buildDarkTheme()
            : buildLightTheme(),
        locale: locale,
        localizationsDelegates: const <LocalizationsDelegate<Object>>[
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child ?? const SizedBox.shrink(),
        ),
        home: const SettingsScreen(),
      ),
    ),
  );
  // `pumpAndSettle` would never return on the loading state — `MxLoadingState`
  // runs a continuous spinner, and a screen that is still loading is exactly
  // one of the states this suite renders.
  if (shouldSettle) {
    await tester.pumpAndSettle();

    return;
  }
  await tester.pump();
}
