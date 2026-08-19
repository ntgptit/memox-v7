import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../di/card_detail_repository_provider.dart';
import '../../domain/usecases/load_card_history_page_use_case.dart';
import '../../domain/usecases/watch_card_detail_use_case.dart';

part 'card_detail_use_case_provider.g.dart';

/// The card detail surface's two use cases, wired to their own contract
/// (UC-19).
///
/// **Its own file rather than two more entries in `card_use_case_provider.dart`,
/// because they hang off a different repository.** Everything in that file
/// takes `cardRepositoryProvider`; putting these beside them would make the
/// wiring file read as though one contract served both, which is exactly what
/// `CardDetailRepository` exists not to be.
///
/// A wiring file is a `_provider` and never a `_controller` — the guard's widget
/// scopes exempt `_controller` from the ban on reading a repository directly,
/// and a file that only wires must not borrow that exemption.
@riverpod
WatchCardDetailUseCase watchCardDetailUseCase(Ref ref) =>
    WatchCardDetailUseCase(ref.watch(cardDetailRepositoryProvider));

@riverpod
LoadCardHistoryPageUseCase loadCardHistoryPageUseCase(Ref ref) =>
    LoadCardHistoryPageUseCase(ref.watch(cardDetailRepositoryProvider));
