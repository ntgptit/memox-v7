import 'package:memox/features/card/domain/entities/card_entity.dart';
import 'package:memox/features/card/domain/failures/card_validation_failure.dart';
import 'package:memox/features/card/domain/models/tag_name_model.dart';

import '../../../deck/data/support/deck_repository_harness.dart';
import 'card_text_fixture.dart';

/// Seeds one card, its details and its tags through the real repository, on
/// the harness's shared database and clock.
///
/// Shared by the two export read tests rather than copied into both: the
/// ordering suite and the read-only suite have to agree on how a card gets
/// into the database, or one of them would be proving something about its own
/// fixture.
///
/// **[after] is opt-in.** Cards created in a row share one instant, which is
/// exactly the case BR-177's `id ASC` tie-break exists for; advancing the
/// clock is how a test chooses which half of the order it is exercising.
Future<CardEntity> seedExportCard(
  DeckRepositoryHarness h,
  String deckId,
  String front, {
  Duration after = Duration.zero,
  String? example,
  String? hint,
  String? pronunciation,
  List<String> tags = const <String>[],
}) async {
  h.currentInstant = h.currentInstant.add(after);
  final card = await h.cardRepository.createCard(
    deckId: deckId,
    front: cardText(front),
    back: cardText('$front-back', side: CardSide.back),
    example: example == null ? null : cardDetail(example),
    hint: hint == null ? null : cardDetail(hint, field: CardDetailField.hint),
    pronunciation: pronunciation == null
        ? null
        : cardDetail(pronunciation, field: CardDetailField.pronunciation),
  );
  for (final tag in tags) {
    await h.cardRepository.addCardTag(
      cardId: card.id,
      name: TagName.parse(tag).name!,
    );
  }

  return card;
}
