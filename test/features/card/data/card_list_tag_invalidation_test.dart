import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/features/card/data/repositories/card_repository_impl.dart';
import 'package:memox/features/card/domain/failures/card_validation_failure.dart';
import 'package:memox/features/card/domain/models/card_text_model.dart';
import 'package:memox/features/card/domain/models/tag_name_model.dart';

/// The boundary IT-ORG-007/008 stopped at: after a tag write, does the card
/// list stream re-emit with the new tag names?
///
/// The row's chips come from a scalar subquery over `card_tags`/`tags` inside
/// the `cardListItems` named query. If drift's stream dependencies do not
/// cover tables referenced only from a subquery, a tag added in the editor
/// never reaches the row until something else touches `cards` — which is
/// exactly what the device showed.
void main() {
  test(
    'adding and removing a tag re-emits the list with new tag names',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final repository = CardRepositoryImpl(
        db,
        clock: () => DateTime.utc(2026, 8, 5, 9),
        idGenerator: _ids(),
      );

      await db.customStatement(
        "INSERT INTO decks (id, name, root_deck_id, content_type, "
        "scheduler_type, scheduler_version, scheduler_generation, "
        "created_at, updated_at) "
        "VALUES ('root', 'Root', 'root', 'deck', 'eight_box', 1, 1, 0, 0)",
      );
      await db.customStatement(
        "INSERT INTO decks (id, name, parent_deck_id, root_deck_id, "
        "content_type, created_at, updated_at) "
        "VALUES ('leaf', 'Leaf', 'root', 'root', 'card', 0, 0)",
      );
      final front = CardText.parse('abandon', side: CardSide.front).text!;
      final back = CardText.parse('từ bỏ', side: CardSide.back).text!;
      final card = await repository.createCard(
        deckId: 'leaf',
        front: front,
        back: back,
      );

      final emissions = <List<String>>[];
      final sub = repository
          .watchCardListItems('leaf', limit: 50)
          .listen((items) => emissions.add(items.first.tagNames));
      await pumpEventQueue();
      expect(emissions.last, isEmpty, reason: 'baseline row carries no tags');

      await repository.addCardTag(
        cardId: card.id,
        name: TagName.parse('IELTS').name!,
      );
      await pumpEventQueue();
      expect(
        emissions.last,
        contains('IELTS'),
        reason:
            'a tag write did not re-emit the list — the row would keep '
            'showing no chip until something else touched the cards table',
      );

      final tags = await repository.watchCardTags(card.id).first;
      await repository.removeCardTag(cardId: card.id, tagId: tags.single.id);
      await pumpEventQueue();
      expect(
        emissions.last,
        isEmpty,
        reason: 'a tag removal did not re-emit the list',
      );

      await sub.cancel();
    },
  );
}

String Function() _ids() {
  var n = 0;
  return () => 'id-${n++}';
}
