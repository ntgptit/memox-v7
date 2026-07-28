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

    return Directionality(
      textDirection: TextDirection.ltr,
      child: ColoredBox(
        color: const Color(0xFFFAF7FF),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF1C1B1F),
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF49454F),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
