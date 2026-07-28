import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'config/env_config.dart';
import 'config/env_config_provider.dart';

/// Single owner of application startup.
///
/// The entrypoints pick a config and call this; they hold no initialisation
/// logic of their own. Keeping startup in one function is what makes three
/// flavors share one path, and what lets a test drive startup with a fake
/// config instead of reproducing it.
///
/// M4.2 will open the database here, between config and `runApp`.
Future<void> bootstrap(EnvConfig config) async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    ProviderScope(
      // No explicit type argument: `Override` is internal to riverpod and is
      // not part of flutter_riverpod's public API.
      overrides: [envConfigProvider.overrideWithValue(config)],
      child: const MemoxApp(),
    ),
  );
}
