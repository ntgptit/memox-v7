/// Which theme the user picked (BR-186).
///
/// **The choice, not the resolved brightness.** `system` is a value in its own
/// right: resolving it to `light` at write time makes an explicit choice
/// indistinguishable from following the platform, and the stored value stops
/// being true the moment the OS setting changes (AD-11).
///
/// Pure Dart. Mapping this onto Flutter's `ThemeMode` belongs to the
/// composition root — `domain/` may not import Flutter, and this enum is the
/// reason that boundary is cheap to keep.
enum AppThemeMode {
  /// Follow the platform's current brightness, and keep following it.
  system('system'),

  light('light'),

  dark('dark');

  const AppThemeMode(this.dbValue);

  /// The value stored in `app_settings.theme_mode`.
  final String dbValue;

  /// BR-186's default, and the value a database written before v8 upgrades to.
  static const AppThemeMode fallback = AppThemeMode.system;

  /// Maps a stored value to the enum, falling back to [fallback].
  ///
  /// Tolerant, like `NewCardOrder.fromDbValue` and unlike the session enums: an
  /// unreadable appearance preference is not a reason to refuse to open the
  /// app. The worst case is the app following the platform, which is what it
  /// did before the column existed.
  static AppThemeMode fromDbValue(String value) {
    for (final mode in values) {
      if (mode.dbValue == value) return mode;
    }

    return fallback;
  }
}
