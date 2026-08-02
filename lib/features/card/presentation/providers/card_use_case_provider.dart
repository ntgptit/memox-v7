import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../di/card_repository_provider.dart';
import '../../domain/usecases/create_card_use_case.dart';
import '../../domain/usecases/watch_card_count_use_case.dart';
import '../../domain/usecases/watch_cards_by_deck_use_case.dart';

part 'card_use_case_provider.g.dart';

/// The card feature's use cases, wired to the repository.
///
/// The same split `deck_use_case_provider.dart` documents: a file that only
/// wires dependencies is a `_provider`, never a `_controller` — the guard's
/// widget scopes exempt `_controller` from the ban on reading a repository
/// directly, so a wiring file must not borrow that exemption.
///
/// The two list reads and the one write the create editor needs. `update` and
/// `delete` land with the edit and delete slices that call them — a provider for
/// a use case nobody reads yet is a decision made without a screen to check it
/// against.
@riverpod
WatchCardsByDeckUseCase watchCardsByDeckUseCase(Ref ref) =>
    WatchCardsByDeckUseCase(ref.watch(cardRepositoryProvider));

@riverpod
WatchCardCountUseCase watchCardCountUseCase(Ref ref) =>
    WatchCardCountUseCase(ref.watch(cardRepositoryProvider));

@riverpod
CreateCardUseCase createCardUseCase(Ref ref) =>
    CreateCardUseCase(ref.watch(cardRepositoryProvider));
