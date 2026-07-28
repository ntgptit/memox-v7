/// Which build of the app is running.
enum AppEnvironment { development, staging, production }

/// Lowest severity that startup logging will emit.
enum LogLevel { debug, info, warning, error }

/// Immutable, per-flavor configuration, chosen at the entrypoint.
///
/// Read it through `envConfigProvider`, never through a global. The reason is
/// not purity: a global mutable config cannot be substituted in a test, and
/// `kDebugMode` branches scattered through feature code cannot be substituted
/// at all. One provider means every layer reads it the same way and a test can
/// swap it in one line.
final class EnvConfig {
  const EnvConfig({
    required this.environment,
    required this.appName,
    required this.apiBaseUrl,
    required this.logLevel,
  });

  final AppEnvironment environment;

  /// User-visible application name. Mirrors the Gradle `app_name` resource, so
  /// the launcher label and the in-app name cannot drift apart.
  final String appName;

  /// Placeholder until the Spring Boot backend exists (AD-05).
  ///
  /// Every value uses the `.invalid` TLD, which RFC 2606 reserves so that it
  /// can never resolve. That is deliberate: if code starts making requests
  /// before the backend is agreed, it fails loudly at DNS instead of quietly
  /// reaching something unintended.
  final String apiBaseUrl;

  final LogLevel logLevel;

  static const EnvConfig development = EnvConfig(
    environment: AppEnvironment.development,
    appName: 'MemoX Dev',
    apiBaseUrl: 'https://dev.api.memox.invalid',
    logLevel: LogLevel.debug,
  );

  static const EnvConfig staging = EnvConfig(
    environment: AppEnvironment.staging,
    appName: 'MemoX Staging',
    apiBaseUrl: 'https://staging.api.memox.invalid',
    logLevel: LogLevel.info,
  );

  static const EnvConfig production = EnvConfig(
    environment: AppEnvironment.production,
    appName: 'MemoX',
    apiBaseUrl: 'https://api.memox.invalid',
    logLevel: LogLevel.warning,
  );
}
