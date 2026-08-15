/// Which language the user picked (BR-215).
///
/// **A choice among three, not a locale.** The column holds `system`, `en` or
/// `vi` and nothing else — there is no script, variant or region in the app's
/// `supportedLocales`, and a type that accepted a full BCP-47 tag would be a
/// type somebody writes `vi-VN` into.
///
/// `system` is a value, for the same reason it is one in [AppThemeMode]:
/// resolving it at write time destroys the difference between "follow the
/// platform" and "the platform happened to be English that day".
///
/// Pure Dart. Turning [languageCode] into a Flutter `Locale` is the composition
/// root's job.
enum AppLanguage {
  /// Let the platform's preferred locales choose, through Flutter's own
  /// resolution over `supportedLocales` (BR-215).
  system('system', null),

  english('en', 'en'),

  vietnamese('vi', 'vi');

  const AppLanguage(this.dbValue, this.languageCode);

  /// The value stored in `app_settings.language`.
  final String dbValue;

  /// The IETF language subtag to force, or null to let the platform decide.
  ///
  /// Null for [system] rather than a sentinel string: "no locale" is exactly
  /// what `MaterialApp.locale` takes to mean "resolve from the platform", so
  /// the absence maps straight through instead of needing a branch at the root.
  final String? languageCode;

  /// BR-215's default, and the value a database written before v9 upgrades to.
  static const AppLanguage fallback = AppLanguage.system;

  /// Maps a stored value to the enum, falling back to [fallback].
  ///
  /// Tolerant for the same reason [AppThemeMode.fromDbValue] is: the fallback
  /// is what the app did before the column existed.
  static AppLanguage fromDbValue(String value) {
    for (final language in values) {
      if (language.dbValue == value) return language;
    }

    return fallback;
  }
}
