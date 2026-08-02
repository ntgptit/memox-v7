import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../di/card_repository_provider.dart';
import '../../domain/usecases/create_card_use_case.dart';
import '../../domain/usecases/delete_card_use_case.dart';
import '../../domain/usecases/get_card_use_case.dart';
import '../../domain/usecases/set_card_flag_use_case.dart';
import '../../domain/usecases/add_card_tag_use_case.dart';
import '../../domain/usecases/remove_card_tag_use_case.dart';
import '../../domain/usecases/watch_card_tags_use_case.dart';
import '../../domain/usecases/update_card_use_case.dart';
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
/// The list reads and the card writes the editor and the list drive.
@riverpod
WatchCardsByDeckUseCase watchCardsByDeckUseCase(Ref ref) =>
    WatchCardsByDeckUseCase(ref.watch(cardRepositoryProvider));

@riverpod
WatchCardCountUseCase watchCardCountUseCase(Ref ref) =>
    WatchCardCountUseCase(ref.watch(cardRepositoryProvider));

@riverpod
CreateCardUseCase createCardUseCase(Ref ref) =>
    CreateCardUseCase(ref.watch(cardRepositoryProvider));

@riverpod
GetCardUseCase getCardUseCase(Ref ref) =>
    GetCardUseCase(ref.watch(cardRepositoryProvider));

@riverpod
UpdateCardUseCase updateCardUseCase(Ref ref) =>
    UpdateCardUseCase(ref.watch(cardRepositoryProvider));

@riverpod
DeleteCardUseCase deleteCardUseCase(Ref ref) =>
    DeleteCardUseCase(ref.watch(cardRepositoryProvider));

@riverpod
SetCardFlagUseCase setCardFlagUseCase(Ref ref) =>
    SetCardFlagUseCase(ref.watch(cardRepositoryProvider));

@riverpod
WatchCardTagsUseCase watchCardTagsUseCase(Ref ref) =>
    WatchCardTagsUseCase(ref.watch(cardRepositoryProvider));

@riverpod
AddCardTagUseCase addCardTagUseCase(Ref ref) =>
    AddCardTagUseCase(ref.watch(cardRepositoryProvider));

@riverpod
RemoveCardTagUseCase removeCardTagUseCase(Ref ref) =>
    RemoveCardTagUseCase(ref.watch(cardRepositoryProvider));
