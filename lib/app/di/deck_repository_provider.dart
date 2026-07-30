import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/database/app_database_provider.dart';
import '../../features/deck/data/repositories/deck_repository_impl.dart';
import '../../features/deck/data/datasources/deck_dao.dart';
import '../../features/deck/domain/repositories/deck_repository.dart';

part 'deck_repository_provider.g.dart';

/// Where the concrete [DeckRepositoryImpl] is chosen, and the only place it is
/// named outside its own layer.
///
/// **It lives in `app/` because nowhere else may hold it.** `presentation/`
/// must not import `data/`, `domain/` must not import Riverpod, and `core/`
/// must not import a feature — so the composition root is the one spot in the
/// tree that can see both the contract and the implementation. Everything
/// above reads the return type, which is the domain contract; a screen that
/// watches this provider cannot tell Drift is behind it, which is the property
/// AD-01 needs when the backend lands.
///
/// `keepAlive` matches [appDatabaseProvider]: the repository is a thin wrapper
/// over the DAO and rebuilding it per screen would buy nothing and churn the
/// Drift streams underneath.
@Riverpod(keepAlive: true)
DeckRepository deckRepository(Ref ref) =>
    DeckRepositoryImpl(DeckDao(ref.watch(appDatabaseProvider)));
