import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/app/config/env_config.dart';
import 'package:memox/app/config/env_config_provider.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/time/delay_provider.dart';
import 'package:memox/features/search/di/library_search_repository_provider.dart';
import 'package:memox/features/search/domain/repositories/library_search_repository.dart';
import 'package:memox/features/search/presentation/screens/library_search_screen.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

/// A [DelayScheduler] a test drives by hand.
///
/// **The whole reason the seam exists.** A debounce measured against the real
/// event loop can only be asserted with `await Future.delayed`, which turns
/// "did it fire at 249ms or at 250?" into a race — and the two sides of the
/// boundary are exactly what has to differ.
final class FakeDelayScheduler {
  Duration? lastDelay;
  int cancellations = 0;
  void Function()? _pending;

  /// The scheduler to install in the container.
  DelayHandle schedule(Duration delay, void Function() action) {
    lastDelay = delay;
    _pending = action;

    return () {
      if (_pending != action) return;
      _pending = null;
      cancellations += 1;
    };
  }

  bool get hasPending => _pending != null;

  /// Runs whatever is armed. Advancing to 249ms is simply *not* calling this.
  void fire() {
    final void Function()? action = _pending;
    _pending = null;
    action?.call();
  }
}

/// A scheduler that runs the callback the moment it is armed, for tests whose
/// subject is not the debounce.
DelayHandle immediateScheduler(Duration delay, void Function() action) {
  action();

  return () {};
}

/// Pumps the search screen on its own, with [repository] behind it.
///
/// The router is absent on purpose: for the state matrix it would add nothing
/// but harder finders. What a row *reports* is asserted one level down, against
/// `LibrarySearchBodyWidget` and its typed `onOpen`
/// (`library_search_row_action_test.dart`); where the route itself is the
/// subject, `library_search_route_test.dart` mounts the real router.
Future<void> pumpSearchScreen(
  WidgetTester tester, {
  required LibrarySearchRepository repository,

  /// Replaces the debounce scheduler. The default runs immediately, so a test
  /// that is not about the debounce does not have to know there is one.
  DelayScheduler? scheduler,
  Size surface = const Size(393, 852),
  double textScale = 1,
  bool isDark = false,
  Locale locale = const Locale('en'),

  /// How much of the bottom of the screen a soft keyboard is covering. The
  /// default is none; a test about the keyboard passes the real height.
  double keyboardInset = 0,
}) async {
  tester.view.physicalSize = surface;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        envConfigProvider.overrideWithValue(EnvConfig.development),
        librarySearchRepositoryProvider.overrideWithValue(repository),
        delaySchedulerProvider.overrideWithValue(
          scheduler ?? immediateScheduler,
        ),
      ],
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: const <LocalizationsDelegate<Object>>[
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        theme: isDark ? buildDarkTheme() : buildLightTheme(),
        // **`copyWith`, never a fresh `MediaQueryData`.** A replacement zeroes
        // `size`, `padding` and `viewInsets` — so `MediaQuery.sizeOf` reads 0,
        // every shell in the tree takes its compact branch whatever the surface
        // says, and the parameterised viewports below silently exercise one
        // layout three times. Found by the UI review of M99.32.
        home: Builder(
          builder: (BuildContext context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(textScale),
              viewInsets: EdgeInsets.only(bottom: keyboardInset),
            ),
            child: const LibrarySearchScreen(),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}

/// The one text field on the screen.
Finder get searchInput => find.byType(TextField);

/// Types [text] into the field and lets the tree settle.
Future<void> typeSearch(WidgetTester tester, String text) async {
  await tester.enterText(searchInput, text);
  await tester.pumpAndSettle();
}
