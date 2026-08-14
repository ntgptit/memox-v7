import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../trash/di/trash_repository_provider.dart';
import '../../../trash/domain/usecases/undo_delete_use_case.dart';

part 'card_undo_provider.g.dart';

/// Reversing the deletion this feature just made (BR-189).
///
/// **Declared here rather than borrowed from Trash.** A feature may depend on
/// another feature's *domain* contract — which is what
/// `trashRepositoryProvider` exposes — but not on its `presentation/`, so the
/// use case is wired once per feature that offers Undo. Three lines of
/// duplication buys each feature a `presentation → use case` edge instead of a
/// widget reaching for a repository (AD-12).
@riverpod
UndoDeleteUseCase cardUndoUseCase(Ref ref) =>
    UndoDeleteUseCase(ref.watch(trashRepositoryProvider));
