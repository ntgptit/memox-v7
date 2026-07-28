import 'app/bootstrap.dart';
import 'app/config/env_config.dart';

/// production entrypoint. Picks a config and hands startup to bootstrap.
void main() => bootstrap(EnvConfig.production);
