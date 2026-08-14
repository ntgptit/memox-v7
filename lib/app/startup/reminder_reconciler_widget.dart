import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/time/clock_provider.dart';
import '../../core/time/time_zone_provider.dart';
import '../../features/reminder/presentation/providers/reminder_use_case_provider.dart';
import '../reminder/reminder_platform_bootstrap.dart';

/// Makes the OS agree with the stored reminder choice, once per launch
/// (BR-190, BR-191).
///
/// **This is where a timezone change, a reboot and an app update are handled,
/// and none of them needs its own hook.** All three end with the app being
/// started; reconciling here derives the schedule from the database against the
/// offset in force *now*, which repairs every one of them with the same code.
/// BR-191's idempotency is what makes that safe to run on every launch.
///
/// **It does not block the first frame.** The work runs after mount, like the
/// fixture seeder: a reminder is a background concern and holding a white screen
/// for a plugin handshake would be the wrong trade.
///
/// **A failure is logged, not surfaced.** There is nothing the user can do about
/// a scheduler that would not answer at launch, and taking down startup for it
/// would hide whatever they opened the app to do. The next launch tries again —
/// which is the whole reason this is a reconcile rather than a one-time setup.
class ReminderReconcilerWidget extends ConsumerStatefulWidget {
  const ReminderReconcilerWidget({
    required this.child,
    required this.onOpenStudy,
    super.key,
  });

  final Widget child;

  /// Where a tapped reminder lands (BR-189).
  ///
  /// Passed in rather than resolved here: this widget sits *above* the router,
  /// so it has no `GoRouter` in scope, and the composition root is the half that
  /// knows which router the app is running.
  final void Function() onOpenStudy;

  @override
  ConsumerState<ReminderReconcilerWidget> createState() =>
      _ReminderReconcilerWidgetState();
}

class _ReminderReconcilerWidgetState
    extends ConsumerState<ReminderReconcilerWidget> {
  @override
  void initState() {
    super.initState();
    // `addPostFrameCallback`, not a bare call: `initState` runs during build,
    // and reading a provider that builds a repository there is a modification
    // mid-build.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => unawaited(_reconcile()),
    );
  }

  Future<void> _reconcile() async {
    try {
      await initializeReminderPlatform(onOpenStudy: widget.onOpenStudy);
      // The widget can be gone by the time the plugin handshake returns, and
      // reading a disposed ref throws.
      if (!mounted) return;

      await ref.read(reconcileReminderScheduleUseCaseProvider)(
        now: ref.read(clockProvider)(),
        utcOffset: ref.read(utcOffsetProvider)(),
      );
    } on Object catch (error, stackTrace) {
      // Width is deliberate: a missing plugin, a refused scheduler and a
      // database that will not open all land here, and none of them may take
      // down a launch whose real work is elsewhere.
      developer.log(
        'reminder reconcile failed',
        name: 'memox.startup',
        error: error,
        stackTrace: stackTrace,
        level: 900,
      );
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
