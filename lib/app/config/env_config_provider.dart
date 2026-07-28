import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'env_config.dart';

part 'env_config_provider.g.dart';

/// The running flavor's configuration.
///
/// The root implementation throws on purpose. There is no sensible default: a
/// silent fallback to development config would mean a production build could
/// quietly point at development settings, and nothing would report it. Failing
/// at the first read makes a missing override impossible to ship.
///
/// `bootstrap()` supplies the real value via `overrideWithValue`.
@Riverpod(keepAlive: true)
EnvConfig envConfig(Ref ref) {
  throw StateError(
    'envConfigProvider was read without an override. bootstrap() must override '
    'it with the EnvConfig chosen by the entrypoint.',
  );
}
