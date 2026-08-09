import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/features/card/data/repositories/card_repository_impl.dart';
import 'package:memox/features/card/domain/failures/card_validation_failure.dart';
import 'package:memox/features/card/domain/models/card_text_model.dart';

/// `HOST-FLOW` for IT-ORG-012 — the half of the windowed list that a widget
/// test cannot reach.
///
/// **The screen half is already proven and is not repeated here.**
/// `card_list_screen_test.dart` shows the tail offering `Load 50 more` while
/// rows remain, saying "all shown" when they do not, and asking the repository
/// for a window one step larger on tap. All three run against a fake
/// repository, which is the right call for a screen — and is precisely why they
/// say nothing about the scenario's actual claim.
///
/// That claim is about SQL: grow the window over a 65-card deck and end up with
/// 65 distinct rows, none repeated, none dropped. A fake returns whatever the
/// test hands it, so it agrees with a `LIMIT` that has an unstable `ORDER BY`
/// just as readily as with one that does not — and an unstable order is exactly
/// how a growing `LIMIT` loses a row: card 50 sorts differently on the second
/// read, so it lands above the cut both times or below it both times, and the
/// user sees a duplicate or a hole with nothing in the logs.
void main() {
  const deckId = 'leaf';
  const cardCount = 65;
  const firstWindow = 50;

  late AppDatabase db;
  late CardRepositoryImpl repository;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    var next = 0;
    repository = CardRepositoryImpl(
      db,
      clock: () => DateTime.utc(2026, 8, 5, 9),
      idGenerator: () => 'card-${(next++).toString().padLeft(3, '0')}',
    );

    await db.customStatement(
      'INSERT INTO decks (id, name, root_deck_id, content_type, '
      'scheduler_type, scheduler_version, scheduler_generation, '
      'created_at, updated_at) '
      "VALUES ('root', 'Root', 'root', 'deck', 'eight_box', 1, 1, 0, 0)",
    );
    await db.customStatement(
      'INSERT INTO decks (id, name, parent_deck_id, root_deck_id, '
      'content_type, created_at, updated_at) '
      "VALUES ('$deckId', 'Leaf', 'root', 'root', 'card', 0, 0)",
    );

    for (var i = 0; i < cardCount; i++) {
      // Every card is written at the same instant on purpose. The default sort
      // is newest-first, so a shared `created_at` is the case where the sort
      // column alone cannot decide an order — and it is the realistic one, since
      // an import writes a whole deck inside one transaction.
      await repository.createCard(
        deckId: deckId,
        front: CardText.parse('front $i', side: CardSide.front).text!,
        back: CardText.parse('back $i', side: CardSide.back).text!,
      );
    }
  });

  tearDown(() => db.close());

  Future<List<String>> window(int limit) async {
    final items = await repository
        .watchCardListItems(deckId, limit: limit)
        .first;

    return items.map((item) => item.card.id).toList();
  }

  test('IT-ORG-012 · the first window is capped and the deck total is not '
      'capped with it', () async {
    expect(await window(firstWindow), hasLength(firstWindow));
    expect(
      await repository.watchFilteredCardCount(deckId).first,
      cardCount,
      reason:
          'the "showing 50 of 65" line needs a count over the whole deck — a '
          'denominator taken from the window would read "50 of 50" and hide '
          'the fifteen rows the user has not seen',
    );
  });

  test('IT-ORG-012 · growing the window keeps every row it already showed, in '
      'the order it showed them', () async {
    final first = await window(firstWindow);
    final second = await window(firstWindow * 2);

    expect(second, hasLength(cardCount));
    expect(
      second.take(firstWindow),
      first,
      reason:
          'a growing LIMIT re-reads from row one, so the rows already on '
          'screen must come back identical — anything else is the list '
          'reshuffling under a reader who was halfway down it',
    );
  });

  test('IT-ORG-012 · the full window holds every card exactly once', () async {
    final rows = await window(cardCount * 2);

    expect(rows.toSet(), hasLength(cardCount), reason: 'no row appears twice');
    expect(rows.toSet(), <String>{
      for (var i = 0; i < cardCount; i++)
        'card-${i.toString().padLeft(3, '0')}',
    }, reason: 'and none of the 65 is missing');
  });

  test('IT-ORG-012 · a window larger than the deck returns the deck, not an '
      'error', () async {
    // The tail's "all shown" state rests on this: the screen decides it by
    // comparing a full window against the count, so a limit past the end has to
    // be an ordinary read.
    expect(await window(1000), hasLength(cardCount));
  });
}
