import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../di/progress_repository_provider.dart';
import '../../domain/usecases/watch_deck_activity_use_case.dart';

part 'progress_use_case_provider.g.dart';

/// The feature's one use case, wired to the repository.
///
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
