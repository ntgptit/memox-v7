import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/app/config/env_config.dart';
import 'package:memox/app/config/env_config_provider.dart';
import 'package:memox/app/router/app_router.dart';
import 'package:memox/app/router/route_paths.dart';
import 'package:memox/core/time/clock_provider.dart';
import 'package:memox/core/time/time_zone_provider.dart';
import 'package:memox/features/progress/di/progress_repository_provider.dart';
import 'package:memox/features/progress/domain/repositories/progress_repository.dart';

// What every Progress audit scenario needs to stand a screen up.
//
// **Beside `deck_audit_harness.dart`, not under `screens/`.** MX-VIS-001 requires
// exactly one `*_visual_audit_test.dart` per production screen and derives its
// path from the screen's; a second file in that tree invites the question of
// which one is the companion. This is a harness, so it lives with the other
// audit harnesses.

/// The production route table at [location], with the database faked out.
///
/// The router is per-call because `GoRouter` carries navigation history and the
/// harness builds one screen per theme; sharing one would let the light run
/// decide where the dark run starts.
///
/// The clock and the offset are fixed for the same reason the widget harness
/// fixes them: every figure on this screen is defined by a window measured from
/// `now` in a local zone.
Widget progressShellWith(
  ProgressRepository repository, {
  String location = RoutePaths.progress,
}) {
  final router = createAppRouter(initialLocation: location);
  addTearDown(router.dispose);

  return ProviderScope(
    overrides: [
      envConfigProvider.overrideWithValue(EnvConfig.development),
      progressRepositoryProvider.overrideWithValue(repository),
      clockProvider.overrideWithValue(() => DateTime.utc(2026, 8, 13, 9)),
      utcOffsetProvider.overrideWithValue(() => const Duration(hours: 7)),
    ],
    child: Router.withConfig(config: router),
  );
}
