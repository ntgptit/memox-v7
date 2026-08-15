import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../di/progress_repository_provider.dart';
import '../../domain/usecases/watch_progress_overview_use_case.dart';
import '../../domain/usecases/watch_deck_activity_use_case.dart';

part 'progress_use_case_provider.g.dart';

/// The feature's one use case, wired to the repository.
///
/// **`providers/` and not `controllers/`, because it holds nothing.** A file
/// under `presentation/` is a `_controller` when it holds state or a command and
/// a `_provider` only when it does dependency wiring. The distinction decides
/// which guard rules apply — the widget scopes exempt `_controller` files from
/// the rule that forbids reading a repository provider — so borrowing the wrong
/// suffix would quietly opt this file out of a rule it should obey.
///
/// `autoDispose` (the generator default) like every other use-case provider:
/// `test/app/provider_convention_test.dart` forbids `keepAlive` anywhere under
/// `features/*/presentation/`.
@riverpod
WatchProgressOverviewUseCase watchProgressOverviewUseCase(Ref ref) =>
    WatchProgressOverviewUseCase(ref.watch(progressRepositoryProvider));

/// **`providers/` and not `controllers/`** for the reason `deck_use_case_provider`
/// states: this file holds no state and exposes no command, and the guard's
/// scopes exempt `_controller` files from rules that a pure wiring file must not
/// borrow.
///
/// `autoDispose` — the generator default — because `keepAlive` anywhere under
/// `features/*/presentation/` is forbidden by `provider_convention_test.dart`,
/// and constructing this is a single field assignment.
@riverpod
WatchDeckActivityUseCase watchDeckActivityUseCase(Ref ref) =>
    WatchDeckActivityUseCase(ref.watch(progressRepositoryProvider));
