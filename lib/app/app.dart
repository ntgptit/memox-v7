import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_theme.dart';
import '../l10n/generated/app_localizations.dart';
import '../l10n/l10n_extension.dart';
import 'mobile_frame_widget.dart';
import 'router/app_router.dart';

/// Root widget of the application.
///
/// Deliberately minimal. Each foundation piece arrives in its own task rather
/// than being stubbed here, so nothing has to be un-guessed later:
///
/// * theme and design tokens — M3.4, M3.5
/// * routing via `MaterialApp.router` — M4.1
class MemoxApp extends StatelessWidget {
  const MemoxApp({this.router, super.key});

  /// Overridden only by tests.
  ///
  /// Nullable rather than required so `const MemoxApp()` keeps working in
  /// `bootstrap()`, and so production has exactly one router — passing
  /// [appRouter] in from the entrypoint would let a future caller pass a
  /// different one and split navigation state without saying so.
  ///
  /// A test supplies its own because a `GoRouter` carries navigation history:
  /// one shared instance would let a route entered by one test decide where the
  /// next one starts.
  final GoRouter? router;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      // Resolved here, never constructed here. `createAppRouter()` in this
      // method would build a new router on every rebuild, discarding the
      // navigation stack each time.
      routerConfig: router ?? appRouter,
      // `onGenerateTitle` rather than `title`: the title has to be read after
      // localizations are in scope, and it changes when the locale does.
      onGenerateTitle: (context) => context.l10n.appTitle,
      localizationsDelegates: const <LocalizationsDelegate<Object>>[
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      // `themeMode` is deliberately not passed: MaterialApp already defaults
      // to ThemeMode.system, and stating it trips avoid_redundant_argument_values
      // — a lint this project promoted to error on purpose. Suppressing our own
      // lint to restate a default would be the worse trade. The behaviour is
      // pinned by test instead.
      // No `localeResolutionCallback` on purpose. Flutter's default resolution
      // already falls back to `supportedLocales.first` — which is `en`, the
      // template ARB — for an unsupported locale. A custom callback here was
      // written and then removed once a test proved it changed nothing.
      // `test/l10n/localization_test.dart` pins the behaviour either way.
      //
      // Phone-sized surface on web (AD-04). No-op on Android.
      builder: (context, child) =>
          MobileFrameWidget(child: child ?? const SizedBox.shrink()),
    );
  }
}
