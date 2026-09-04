import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/foundations/app_breakpoints.dart';
import '../core/theme/schemes/app_compact_scale.dart';
import '../core/theme/app_theme.dart';
import '../features/settings/domain/models/app_language_model.dart';
import '../features/settings/domain/models/app_settings_model.dart';
import '../features/settings/domain/models/app_theme_mode_model.dart';
import '../features/settings/presentation/controllers/app_settings_controller.dart';
import '../l10n/generated/app_localizations.dart';
import '../l10n/l10n_extension.dart';
import 'mobile_frame_widget.dart';
import 'router/app_router.dart';
import '../core/theme/schemes/app_bold_text.dart';

/// Root widget of the application.
///
/// Deliberately minimal. Each foundation piece arrives in its own task rather
/// than being stubbed here, so nothing has to be un-guessed later:
///
/// * theme and design tokens — M3.4, M3.5
/// * routing via `MaterialApp.router` — M4.1
/// * theme mode and locale from stored settings — M99.28
///
/// **The settings seam runs one way** (AD-13, AD-19). Theme and locale live on
/// `MaterialApp`, which is `app/`, while the values that decide them belong to
/// a feature — and a feature may never import `app/`. So the feature declares a
/// provider and this file reads it; nothing is instantiated here, and the
/// repository behind it is bound in `app/di/repository_bindings.dart` like
/// every other one.
class MemoxApp extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    // `AsyncValue.value`, and the fallback is `AppSettingsModel.defaults` rather
    // than an invented pair. Before the first emission — and if the read fails
    // — the app follows the platform for both, which is exactly what "System"
    // means and what every build before M99.28 did unconditionally (BR-214,
    // BR-215). A spinner in place of the app while a local SQLite row is read
    // would be a blank window instead of a one-frame resolution, which is the
    // trade `FixtureSeederWidget` already refused for the deck list.
    //
    // A failed read is not swallowed: the settings screen renders the error
    // through the same provider. What is refused here is letting a broken
    // settings row take the whole app down with it.
    final settings =
        ref.watch(appSettingsProvider).value ?? AppSettingsModel.defaults;

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
      // **Read by `MaterialApp` off `MediaQuery.highContrast`, not off a
      // setting of ours.** The platform owns this flag — Android's "High
      // contrast text", and the equivalent elsewhere — so there is no third
      // entry in `AppThemeMode` and nothing to store: BR-214 is about the
      // light/dark choice the user makes *in the app*, and this is orthogonal
      // to it. A user on `system` in the dark with high contrast on gets
      // `highContrastDarkTheme`, which is the pairing these two slots exist to
      // express.
      //
      // Leaving them null — which is what shipped until M99.48 — is not a
      // neutral default. It means the app renders identically for someone who
      // asked for stronger contrast, and the request fails silently.
      highContrastTheme: buildHighContrastLightTheme(),
      highContrastDarkTheme: buildHighContrastDarkTheme(),
      // The stored choice, resolved to Flutter's own enum here and nowhere
      // else. `AppThemeMode.system` becomes `ThemeMode.system`, which is what
      // makes the app keep following the platform rather than freezing at
      // whatever it was on the frame this was read (BR-214).
      themeMode: _themeModeOf(settings.themeMode),
      // Instant, not a cross-fade. Material's 200ms theme animation renders
      // intermediate colours — literally a third theme on the way between two
      // — which BR-214 and the M99.28 wireframe both rule out. It is also what
      // makes the cold-start resolution above read as "the app started dark"
      // rather than as a fade somebody has to watch.
      themeAnimationDuration: Duration.zero,
      // Null for `system`, which is how `MaterialApp` is told to resolve from
      // the platform's preferred locales over `supportedLocales` (BR-215).
      locale: _localeOf(settings.language),
      // No `localeResolutionCallback` on purpose. Flutter's default resolution
      // already falls back to `supportedLocales.first` — which is `en`, the
      // template ARB — for an unsupported locale. A custom callback here was
      // written and then removed once a test proved it changed nothing.
      // `test/l10n/localization_test.dart` pins the behaviour either way.
      //
      // Phone-sized surface on web (AD-04). No-op on Android.
      //
      // The compact scale sits *inside* the frame, not around it: on web the
      // frame overrides `MediaQuery` down to 393x852, and a width test placed
      // above it would read the browser window and decide the app is roomy
      // even though it renders at phone size.
      builder: (context, child) => MobileFrameWidget(
        child: CompactScaleWidget(
          child: BoldTextWidget(child: child ?? const SizedBox.shrink()),
        ),
      ),
    );
  }
}

/// The stored theme choice as Flutter's enum.
///
/// A `switch` in the composition root rather than a getter on [AppThemeMode]:
/// `domain/` may not import Flutter, and this three-line mapping is the whole
/// price of that boundary. Exhaustive, so a fourth choice fails to compile here
/// instead of silently resolving to the system default.
ThemeMode _themeModeOf(AppThemeMode mode) => switch (mode) {
  AppThemeMode.system => ThemeMode.system,
  AppThemeMode.light => ThemeMode.light,
  AppThemeMode.dark => ThemeMode.dark,
};

/// The stored language choice as a [Locale], or null to follow the platform.
///
/// Built from [AppLanguage.languageCode] rather than from a second `switch`, so
/// adding a language is one line in the enum and nothing here.
Locale? _localeOf(AppLanguage language) {
  final code = language.languageCode;

  return code == null ? null : Locale(code);
}

/// Applies [applyBoldText] when the OS reports its Bold text setting
/// (A20.1 P1-11).
///
/// Inside [CompactScaleWidget], so the emboldened theme is the compact one
/// where the width asks for it — the two transforms compose in either order,
/// but the outer one must see the inner one's output.
class BoldTextWidget extends StatelessWidget {
  const BoldTextWidget({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!MediaQuery.boldTextOf(context)) return child;

    return Theme(data: applyBoldText(Theme.of(context)), child: child);
  }
}

/// Applies [applyCompactScale] when the surface is narrower than
/// [AppBreakpoints.compact].
///
/// A widget rather than a branch in `buildLightTheme()`, because the theme is
/// built once at startup and the width is not known then — and on a foldable it
/// changes while the app is running.
class CompactScaleWidget extends StatelessWidget {
  const CompactScaleWidget({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    // `sizeOf`, so this rebuilds on rotation and unfold rather than reading a
    // width captured on the first frame.
    if (!AppBreakpoints.isCompact(MediaQuery.sizeOf(context).width)) {
      return child;
    }

    return Theme(data: applyCompactScale(Theme.of(context)), child: child);
  }
}
