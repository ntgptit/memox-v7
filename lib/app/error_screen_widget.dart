import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/widgets.dart';

import '../l10n/generated/app_localizations.dart';
import '../l10n/generated/app_localizations_en.dart';

/// Which failure the screen is reporting.
enum AppErrorKind {
  /// `bootstrap()` failed before the app could render.
  startup,

  /// A widget threw while building; this replaces Flutter's red screen.
  render,
}

/// The screen shown when something failed badly enough that normal UI cannot be
/// trusted.
///
/// It is built with `package:flutter/widgets.dart` only, and supplies its own
/// `Directionality` and text style. That is the point: it has to render when it
/// is standing in for a widget that failed, including above `MaterialApp`,
/// where `Theme`, `MediaQuery` and `Directionality` may not exist. A "nice"
/// error screen that itself throws leaves the user with a blank window, which
/// is indistinguishable from a hang.
///
/// It shows no exception, stack trace, widget name, URL or SQL — `CLAUDE.md`
/// forbids leaking those to users, and an error screen is exactly where they
/// leak by accident.
class ErrorScreenWidget extends StatelessWidget {
  const ErrorScreenWidget({required this.kind, super.key});

  final AppErrorKind kind;

  @override
  Widget build(BuildContext context) {
    // Localizations may not be in scope — this widget can replace one that
    // failed above the delegates. `AppLocalizations.of` asserts in that case
    // (the generator emits a non-nullable getter), so the lookup goes through
    // `Localizations.of`, which returns null instead. Falling back to the
    // generated English bindings keeps the strings in ARB rather than
    // hardcoding them into the one screen that must never fail.
    final l10n =
        Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizationsEn();

    final title = switch (kind) {
      AppErrorKind.startup => l10n.startupErrorTitle,
      AppErrorKind.render => l10n.unexpectedErrorTitle,
    };
    final message = switch (kind) {
      AppErrorKind.startup => l10n.startupErrorMessage,
      AppErrorKind.render => l10n.unexpectedErrorMessage,
    };

    // **Answers to the platform brightness, per MX-VIS-002 rule R8.** This
    // screen holds literals because it has no `Theme` to read — that much is
    // forced. What is not forced is being stuck in one mode: a dark-mode user
    // whose app has just failed got a full-screen white flash, which is the
    // worst possible moment for one.
    //
    // `PlatformDispatcher` rather than `MediaQuery.platformBrightnessOf`: this
    // widget can stand in for one that failed *above* `MaterialApp`, where no
    // inherited widget is guaranteed. The dispatcher is the one source that
    // survives having no element tree above it.
    final isDark =
        PlatformDispatcher.instance.platformBrightness == Brightness.dark;
    final palette = isDark ? _darkFallback : _lightFallback;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: ColoredBox(
        color: palette.background,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: palette.title,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: palette.message, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The three colours this screen needs, for one brightness.
///
/// A tiny value type rather than three parallel constants: the trio has to move
/// together, and three separate `isDark ? a : b` expressions is how a background
/// gets swapped and a text colour does not.
class _FallbackPalette {
  const _FallbackPalette({
    required this.background,
    required this.title,
    required this.message,
  });

  final Color background;
  final Color title;
  final Color message;
}

/// Chosen to match the real theme closely enough that the failure does not also
/// look like a different app — but declared here, because the theme is exactly
/// what is unavailable when this renders.
const _FallbackPalette _lightFallback = _FallbackPalette(
  background: Color(0xFFF4F5F8),
  title: Color(0xFF16182B),
  message: Color(0xFF565C72),
);

const _FallbackPalette _darkFallback = _FallbackPalette(
  background: Color(0xFF0A082D),
  title: Color(0xFFEDEEF5),
  message: Color(0xFFA6ABC2),
);
