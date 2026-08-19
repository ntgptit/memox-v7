import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../di/trash_repository_provider.dart';
import '../../domain/usecases/watch_trash_batches_use_case.dart';
import '../../domain/usecases/watch_trash_restore_targets_use_case.dart';
import '../../domain/usecases/restore_trash_batch_use_case.dart';
import '../../domain/usecases/undo_delete_use_case.dart';
import '../../domain/usecases/purge_trash_batches_use_case.dart';
import '../../domain/usecases/purge_expired_trash_use_case.dart';

part 'trash_use_case_provider.g.dart';

/// Dependency wiring only — no state, no commands (AD-14).
///
/// `_provider`, not `_controller`, and the distinction decides which guard rules
/// apply: anything that holds state or a command belongs in `controllers/`.

@riverpod
WatchTrashBatchesUseCase watchTrashBatchesUseCase(Ref ref) =>
    WatchTrashBatchesUseCase(ref.watch(trashRepositoryProvider));

@riverpod
WatchTrashRestoreTargetsUseCase watchTrashRestoreTargetsUseCase(Ref ref) =>
    WatchTrashRestoreTargetsUseCase(ref.watch(trashRepositoryProvider));

@riverpod
RestoreTrashBatchUseCase restoreTrashBatchUseCase(Ref ref) =>
    RestoreTrashBatchUseCase(ref.watch(trashRepositoryProvider));

@riverpod
UndoDeleteUseCase undoDeleteUseCase(Ref ref) =>
    UndoDeleteUseCase(ref.watch(trashRepositoryProvider));

@riverpod
PurgeTrashBatchesUseCase purgeTrashBatchesUseCase(Ref ref) =>
    PurgeTrashBatchesUseCase(ref.watch(trashRepositoryProvider));

@riverpod
PurgeExpiredTrashUseCase purgeExpiredTrashUseCase(Ref ref) =>
    PurgeExpiredTrashUseCase(ref.watch(trashRepositoryProvider));
