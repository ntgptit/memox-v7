import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/time/clock_provider.dart';
import '../../features/trash/di/trash_repository_provider.dart';
import '../../features/trash/domain/usecases/purge_expired_trash_use_case.dart';

/// Runs the retention sweep at startup and on every resume (BR-264).
///
/// **Two of BR-264's three triggers live here; the third is the Trash list
/// itself.** They are three because the app has no background process: a job
/// that only ran when someone opened Trash would keep expired content for as
/// long as nobody looked, and a job that only ran at launch would keep it for
/// as long as the app stayed open.
///
/// **Idempotent by contract, which is what makes three triggers safe.** Two of
/// them can fire milliseconds apart — resume immediately followed by opening
/// Trash — and the second finds nothing to do.
///
/// **It does not block the first frame**, for the reason `FixtureSeederWidget`
/// gives: the sweep runs after mount, and everything watching the database is
/// watching a stream, so a row that goes simply disappears from whatever is on
/// screen.
///
/// **A failure is logged, not surfaced.** There is nothing the user can do
/// about it and nothing they asked for; the batch stays, and the next trigger
/// tries again. The log carries ids only — never card content (BR-267).
class TrashSweeperWidget extends ConsumerStatefulWidget {
  const TrashSweeperWidget({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<TrashSweeperWidget> createState() => _TrashSweeperWidgetState();
}

class _TrashSweeperWidgetState extends ConsumerState<TrashSweeperWidget>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // `addPostFrameCallback`, not a bare call: `initState` runs during build,
    // and reading a provider that builds a repository there is a modification
    // mid-build.
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_sweep()));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    // Resume is the trigger that matters most: an app left open over a weekend
    // crosses two retention boundaries without ever restarting.
    unawaited(_sweep());
  }

  Future<void> _sweep() async {
    try {
      final purged = await PurgeExpiredTrashUseCase(
        ref.read(trashRepositoryProvider),
      )(ref.read(clockProvider)());
      if (purged == 0) return;

      developer.log('trash sweep: $purged batch(es)', name: 'memox.startup');
    } on Object catch (error, stackTrace) {
      developer.log(
        'trash sweep failed',
        name: 'memox.startup',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
