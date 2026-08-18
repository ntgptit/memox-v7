import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../di/deck_repository_provider.dart';
import '../../domain/usecases/create_root_deck_use_case.dart';
import '../../domain/usecases/create_sub_deck_use_case.dart';
import '../../domain/usecases/delete_deck_use_case.dart';
import '../../domain/usecases/get_deck_deletion_impact_use_case.dart';
import '../../domain/usecases/move_deck_use_case.dart';
import '../../domain/usecases/rename_deck_use_case.dart';
import '../../domain/usecases/change_unlocked_scheduler_use_case.dart';
import '../../domain/usecases/reset_learning_progress_use_case.dart';
import '../../domain/usecases/watch_deck_move_targets_use_case.dart';
import '../../domain/usecases/watch_deck_list_use_case.dart';

part 'deck_use_case_provider.g.dart';

/// The feature's use cases, wired to the repository.
///
/// **Why `providers/` and not `controllers/`.** A controller holds state and
/// exposes commands; every provider here holds nothing and exposes one use case.
/// The distinction is enforced rather than stylistic: the guard's widget scopes
/// exempt files by the `_controller` suffix from the rule that forbids
/// `ref.watch(...RepositoryProvider)`, so a file that only wires dependencies
/// must not borrow that exemption. `_provider` was added to the allowed
/// presentation suffixes at M4.10 for exactly this folder.
///
/// **Why here and not in `app/di/`.** `app/di/` holds the composition root — the
/// one place `DeckRepositoryImpl` is named, so the concrete implementation is
/// substitutable in a test from outside the feature. A use case has no
/// implementation to choose between: it is domain code with one constructor, and
/// what a test substitutes is the repository underneath it. Keeping these beside
/// the controllers that read them means a feature's wiring travels with the
/// feature.
///
/// All `autoDispose` — the generator default — and deliberately so, even though a
/// use case holds no state and could safely outlive a screen. `keepAlive` inside
/// `features/*/presentation/` is forbidden by
/// `test/app/provider_convention_test.dart`, and the rule is worth more absolute
/// than it would be with an exception for "providers that are cheap": constructing
/// one of these is a field assignment, so the exception would buy nothing and cost
/// the rule its teeth.

@riverpod
CreateRootDeckUseCase createRootDeckUseCase(Ref ref) =>
    CreateRootDeckUseCase(ref.watch(deckRepositoryProvider));

@riverpod
CreateSubDeckUseCase createSubDeckUseCase(Ref ref) =>
    CreateSubDeckUseCase(ref.watch(deckRepositoryProvider));

@riverpod
RenameDeckUseCase renameDeckUseCase(Ref ref) =>
    RenameDeckUseCase(ref.watch(deckRepositoryProvider));

@riverpod
DeleteDeckUseCase deleteDeckUseCase(Ref ref) =>
    DeleteDeckUseCase(ref.watch(deckRepositoryProvider));

/// The delete that reports its batch, for the one caller that offers Undo.
@riverpod
DeleteDeckForUndoUseCase deleteDeckForUndoUseCase(Ref ref) =>
    DeleteDeckForUndoUseCase(ref.watch(deckRepositoryProvider));

@riverpod
ResetLearningProgressUseCase resetLearningProgressUseCase(Ref ref) =>
    ResetLearningProgressUseCase(ref.watch(deckRepositoryProvider));

@riverpod
ChangeUnlockedSchedulerUseCase changeUnlockedSchedulerUseCase(Ref ref) =>
    ChangeUnlockedSchedulerUseCase(ref.watch(deckRepositoryProvider));

@riverpod
MoveDeckUseCase moveDeckUseCase(Ref ref) =>
    MoveDeckUseCase(ref.watch(deckRepositoryProvider));

@riverpod
WatchDeckListUseCase watchDeckListUseCase(Ref ref) =>
    WatchDeckListUseCase(ref.watch(deckRepositoryProvider));

@riverpod
GetDeckDeletionImpactUseCase getDeckDeletionImpactUseCase(Ref ref) =>
    GetDeckDeletionImpactUseCase(ref.watch(deckRepositoryProvider));

@riverpod
WatchDeckMoveTargetsUseCase watchDeckMoveTargetsUseCase(Ref ref) =>
    WatchDeckMoveTargetsUseCase(ref.watch(deckRepositoryProvider));
