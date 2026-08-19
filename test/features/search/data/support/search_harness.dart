import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/card/domain/entities/card_entity.dart';
import 'package:memox/features/card/domain/failures/card_validation_failure.dart';
import 'package:memox/features/card/domain/models/card_text_model.dart';
import 'package:memox/features/card/domain/models/tag_name_model.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/deck/domain/models/deck_name_model.dart';
import 'package:memox/features/deck/domain/models/scheduler_type_model.dart';
import 'package:memox/features/search/data/repositories/library_search_repository_impl.dart';
import 'package:memox/features/search/domain/models/search_cursor_model.dart';
import 'package:memox/features/search/domain/models/search_page_model.dart';
import 'package:memox/features/search/domain/models/search_query_model.dart';

import '../../../deck/data/support/deck_repository_harness.dart';

/// One real SQLite database, the deck and card repositories that write into it,
/// and the search repository that reads it back.
///
/// **Real SQLite rather than a fake**, because everything under test here is the
/// statement: `instr` semantics, the tag aggregate, the keyset comparison and
/// the folded columns are all properties of the SQL, and a fake would assert
/// only that this file believes what the SQL does.
final class SearchHarness {
  late DeckRepositoryHarness decks;
  late LibrarySearchRepositoryImpl repository;

  /// One page, read once. Streams re-emit on every write, so a test that wants
  /// "the answer right now" takes the first frame.
  Future<LibrarySearchPage> page(
    String query, {
    int pageSize = 20,
    LibrarySearchCursor after = LibrarySearchCursor.start,
  }) => repository
      .watchSearchPage(
        query: SearchQuery.parse(query),
        after: after,
        pageSize: pageSize,
      )
      .first;

  Future<DeckEntity> root(String name) => decks.deckRepository.createRootDeck(
    name: DeckName.parse(name).name!,
    schedulerType: SchedulerType.eightBox,
  );

  Future<DeckEntity> child(String name, String parentId) => decks.deckRepository
      .createSubDeck(name: DeckName.parse(name).name!, parentDeckId: parentId);

  /// A card in [deckId]. [after] advances the shared clock, which is how a test
  /// chooses which side of the `created_at` tie-break it is exercising.
  Future<CardEntity> card(
    String deckId,
    String front, {
    String? back,
    Duration after = Duration.zero,
    List<String> tags = const <String>[],
  }) async {
    decks.currentInstant = decks.currentInstant.add(after);
    final CardEntity created = await decks.cardRepository.createCard(
      deckId: deckId,
      front: CardText.parse(front, side: CardSide.front).text!,
      back: CardText.parse(back ?? '$front-back', side: CardSide.back).text!,
    );
    for (final String tag in tags) {
      await decks.cardRepository.addCardTag(
        cardId: created.id,
        name: TagName.parse(tag).name!,
      );
    }

    return created;
  }
}

/// Registers the database, the writers and the search repository per test.
SearchHarness installSearchHarness() {
  final harness = SearchHarness()..decks = installDeckRepositoryHarness();
  // Registered after the deck harness's own `setUp`, so `decks.db` is the
  // database this test is about rather than the previous test's.
  setUp(
    () => harness.repository = LibrarySearchRepositoryImpl(harness.decks.db),
  );

  return harness;
}
