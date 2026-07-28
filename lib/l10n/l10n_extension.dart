import 'package:flutter/widgets.dart';

import 'generated/app_localizations.dart';

/// Shorthand for reading localized strings: `context.l10n.appTitle`.
///
/// The single accessor exists so no call site has to remember whether the
/// lookup is `AppLocalizations.of` or `.maybeOf`, and so the codebase greps
/// cleanly for `context.l10n`.
extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
