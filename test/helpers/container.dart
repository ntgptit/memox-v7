import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/app/config/env_config.dart';
import 'package:memox/app/config/env_config_provider.dart';

/// Builds a [ProviderContainer] for a test and disposes it automatically.
///
/// The `addTearDown` is the whole point. A container that is not disposed keeps
/// its providers — and any timers, subscriptions or streams they hold — alive
/// past the test that created it. The symptom is a later, unrelated test
/// failing or hanging, which is the most expensive kind of failure to trace.
/// Making disposal the default removes the chance to forget.
///
/// [envConfig] defaults to [EnvConfig.development] because `envConfigProvider`
/// throws when it is not overridden; every container would otherwise have to
/// repeat that override before it could read anything.
///
/// There is deliberately no `overrides` parameter. Riverpod's `Override` type
/// is not exported by `riverpod` or `flutter_riverpod`, so a helper cannot name
/// it in a signature. A test that needs extra overrides builds the container
/// itself — and must register its own `addTearDown(container.dispose)`:
///
/// ```dart
/// final container = ProviderContainer(
///   overrides: [
///     envConfigProvider.overrideWithValue(EnvConfig.staging),
///     someProvider.overrideWithValue(fake),
///   ],
/// );
/// addTearDown(container.dispose);
/// ```
ProviderContainer makeContainer({EnvConfig envConfig = EnvConfig.development}) {
  final container = ProviderContainer(
    overrides: [envConfigProvider.overrideWithValue(envConfig)],
  );
  addTearDown(container.dispose);

  return container;
}
