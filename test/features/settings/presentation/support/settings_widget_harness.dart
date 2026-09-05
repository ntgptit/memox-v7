import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/app/app.dart';
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

  /// How much of the bottom of the screen a soft keyboard is covering. The
  /// default is none; a test about the keyboard passes the real height.
  double keyboardInset = 0,
}) async {
  await tester.binding.setSurfaceSize(surface);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  // **The view too, not only the surface.** `setSurfaceSize` resizes what the
  // tree is laid out into; it leaves `MediaQuery` reporting the test view's own
  // 800x600. Everything that branches on width reads `MediaQuery` —
  // `mxScreenGutter` and `CompactScaleWidget` both do — so without this a
  // `320dp` case laid itself out 320 wide while every width decision inside it
  // was still answering "roomy".
  tester.view.physicalSize = surface * tester.view.devicePixelRatio;
  addTearDown(tester.view.resetPhysicalSize);

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
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
            viewInsets: EdgeInsets.only(bottom: keyboardInset),
          ),
          // **The compact scale, because the real app applies it here too**
          // (`app.dart`'s `MaterialApp.builder`). Without it every `320dp`
          // case in this suite rendered the roomy theme, so the tier those
          // cases exist to exercise was the one thing they could not see —
          // which is how a card kept a fixed 16dp inner gutter while the rows
          // beside it stepped to 12.
          child: CompactScaleWidget(child: child ?? const SizedBox.shrink()),
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
