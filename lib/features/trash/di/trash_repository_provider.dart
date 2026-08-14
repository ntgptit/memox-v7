import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/repositories/content_trash_repository.dart';
import '../domain/repositories/trash_repository.dart';

part 'trash_repository_provider.g.dart';

/// The two contracts Trash needs, declared as contracts and bound at the
/// composition root (AD-13).
///
/// **Two providers, because they have two audiences.** [trashRepositoryProvider]
/// serves the Trash screen; [contentTrashRepositoryProvider] is what the Deck
/// and Card repositories take so a delete becomes a batch (BR-182). Binding
/// them together would make every feature that deletes something depend on the
/// screen that lists what was deleted.
///
/// Both bodies throw for the reason `deckRepositoryProvider` explains at
/// length: `presentation/` may not name an implementation, so this layer states
/// the requirement and nothing more. A missing override is a `StateError` on
/// first read — the deck list mounts the delete path immediately, so a
/// forgotten binding fails on launch and in every widget test.
///
/// `keepAlive`, matching `appDatabaseProvider`: a repository is a thin wrapper
/// over a DAO and there is exactly one of it.
@Riverpod(keepAlive: true)
TrashRepository trashRepository(Ref ref) => throw StateError(
  'trashRepositoryProvider was read without an override. The composition root '
  'binds it — see trashRepositoryBinding in app/di/repository_bindings.dart. A '
  'test must override it with a fake.',
);

@Riverpod(keepAlive: true)
ContentTrashRepository contentTrashRepository(Ref ref) => throw StateError(
  'contentTrashRepositoryProvider was read without an override. The '
  'composition root binds it — see contentTrashRepositoryBinding in '
  'app/di/repository_bindings.dart. A test must override it with a fake.',
);
