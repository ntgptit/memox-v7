# Flavors and environment configuration

Three flavors: `development`, `staging`, `production`. Each has its own app
name, application ID, API base URL, log level, feature flags and analytics
setting.

## Entrypoints

One file per flavor, each a few lines. This is why `bootstrap` is separate from
`main` — the three entrypoints differ only in the config they pass.

```
lib/
├── main_development.dart
├── main_staging.dart
├── main_production.dart
└── app/config/env_config.dart
```

```dart
// main_development.dart
void main() => bootstrap(EnvConfig.development);
```

Run and build with the flavor selected:

```bash
flutter run --flavor development -t lib/main_development.dart
flutter build appbundle --flavor production -t lib/main_production.dart
```

## Config shape

```dart
enum LogLevel { debug, info, warning, error }

final class EnvConfig {
  const EnvConfig({
    required this.name,
    required this.appName,
    required this.apiBaseUrl,
    required this.logLevel,
    required this.isAnalyticsEnabled,
    this.featureFlags = const <String, bool>{},
  });

  static const development = EnvConfig(...);
  static const staging = EnvConfig(...);
  static const production = EnvConfig(...);
}
```

Expose it through a provider overridden in `bootstrap`:

```dart
@Riverpod(keepAlive: true)
EnvConfig envConfig(Ref ref) => throw UnimplementedError('overridden in bootstrap');
```

Throwing in the default body is deliberate. It means forgetting the override
fails immediately and loudly at startup rather than silently handing out a
default that points at the wrong API.

## Secrets

Never in the repo. Locally, `--dart-define-from-file=env/dev.json` with `env/`
in `.gitignore`; in CI, the pipeline's secret store written to that file at
build time.

`String.fromEnvironment` must be read in a `const` context to be tree-shaken
correctly:

```dart
static const apiKey = String.fromEnvironment('API_KEY');
```

Development must not hold production credentials. Beyond the obvious leak risk,
it is how someone eventually runs a destructive test against live user data.

## Android

`android/app/build.gradle`:

```groovy
android {
  flavorDimensions "env"
  productFlavors {
    development { dimension "env"; applicationIdSuffix ".dev";     resValue "string", "app_name", "MemoX Dev" }
    staging     { dimension "env"; applicationIdSuffix ".staging"; resValue "string", "app_name", "MemoX Staging" }
    production  { dimension "env";                                 resValue "string", "app_name", "MemoX" }
  }
}
```

Then `android:label="@string/app_name"` in the manifest.

Distinct application IDs let all three install side by side — worth it the first
time you need to compare staging against production on one device.

## iOS

Xcode: one scheme per flavor, each mapped to a build configuration
(`Debug-development`, `Release-production`, …), with `PRODUCT_BUNDLE_IDENTIFIER`
and `PRODUCT_NAME` set per configuration via an `.xcconfig`.

This is fiddly and easy to half-finish. Verify by building each scheme and
checking the installed bundle ID, rather than assuming the Xcode UI applied what
you selected.

## Verifying

Before calling flavors done: install all three on one device simultaneously,
confirm each shows its own name and icon, confirm each points at its own API
base URL, and confirm production logs nothing above its configured level.
