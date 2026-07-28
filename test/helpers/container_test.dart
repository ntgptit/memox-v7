import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/app/config/env_config.dart';
import 'package:memox/app/config/env_config_provider.dart';

import 'container.dart';

void main() {
  group('makeContainer', () {
    test('supplies a config so envConfigProvider is readable', () {
      final container = makeContainer();

      expect(container.read(envConfigProvider), same(EnvConfig.development));
    });

    test('honours an explicit config', () {
      final container = makeContainer(envConfig: EnvConfig.production);

      expect(container.read(envConfigProvider), same(EnvConfig.production));
    });

    test('registers disposal, so a container cannot outlive its test', () {
      // Proving the tear-down ran requires observing it from outside the test
      // that created the container: the disposal happens after the body ends.
      // So capture the container here, and assert in a later test that it is
      // gone — a leaked container would still be readable.
      _leaked = makeContainer();

      expect(_leaked!.read(envConfigProvider), isNotNull);
    });

    test('the previous test\'s container really was disposed', () {
      expect(
        _leaked,
        isNotNull,
        reason: 'the previous test did not run — this assertion is meaningless',
      );
      // Reading a disposed container throws; if `addTearDown` had been
      // forgotten, this read would quietly succeed and the helper's only
      // guarantee would be untested.
      expect(() => _leaked!.read(envConfigProvider), throwsStateError);
    });
  });
}

/// Deliberately file-scoped: the assertion that matters happens in the test
/// *after* the one that creates the container.
ProviderContainer? _leaked;
