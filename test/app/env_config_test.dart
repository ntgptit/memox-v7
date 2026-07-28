import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/app/config/env_config.dart';
import 'package:memox/app/config/env_config_provider.dart';

void main() {
  const configs = <EnvConfig>[
    EnvConfig.development,
    EnvConfig.staging,
    EnvConfig.production,
  ];

  group('EnvConfig presets', () {
    test('the three flavors differ in every field that identifies them', () {
      // A copy-paste slip that leaves two flavors sharing a base URL is
      // invisible until someone points a staging build at production data.
      expect(configs.map((c) => c.environment).toSet(), hasLength(3));
      expect(configs.map((c) => c.appName).toSet(), hasLength(3));
      expect(configs.map((c) => c.apiBaseUrl).toSet(), hasLength(3));
    });

    test('log level tightens from development to production', () {
      expect(EnvConfig.development.logLevel, LogLevel.debug);
      expect(EnvConfig.staging.logLevel, LogLevel.info);
      expect(EnvConfig.production.logLevel, LogLevel.warning);
    });

    test('every apiBaseUrl is an unresolvable .invalid placeholder', () {
      // AD-05: there is no backend yet. `.invalid` is reserved by RFC 2606 and
      // can never resolve, so a premature request fails at DNS instead of
      // quietly reaching something real.
      for (final config in configs) {
        expect(
          Uri.parse(config.apiBaseUrl).host,
          endsWith('.invalid'),
          reason: '${config.environment} points at a resolvable host',
        );
      }
    });

    test('appName matches the Gradle app_name resource for each flavor', () {
      // Keeps the launcher label and the in-app name from drifting apart.
      expect(EnvConfig.development.appName, 'MemoX Dev');
      expect(EnvConfig.staging.appName, 'MemoX Staging');
      expect(EnvConfig.production.appName, 'MemoX');
    });
  });

  group('envConfigProvider', () {
    test('throws when read without an override', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // A silent default would let a production build quietly run on
      // development settings, and nothing would report it.
      //
      // Riverpod 3 wraps a provider's exception in ProviderException, which is
      // not exported from flutter_riverpod — so the assertion is on the
      // message rather than the type. Asserting only "it throws" would pass on
      // any unrelated failure, which is not what this test is for.
      expect(
        () => container.read(envConfigProvider),
        throwsA(
          predicate<Object>(
            (error) => error.toString().contains('without an override'),
            'reports the missing envConfigProvider override',
          ),
        ),
      );
    });

    test('returns the config it was overridden with', () {
      final container = ProviderContainer(
        overrides: [envConfigProvider.overrideWithValue(EnvConfig.staging)],
      );
      addTearDown(container.dispose);

      expect(container.read(envConfigProvider), same(EnvConfig.staging));
    });
  });
}
