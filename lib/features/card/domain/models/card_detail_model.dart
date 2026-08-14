import '../entities/card_entity.dart';
import '../entities/card_study_state_entity.dart';
import 'card_state_model.dart';

/// Everything the card detail screen reads about a card that is *not* its
/// history (BR-183).
///
/// **One projection, from one statement** (AD-13). Content, tags and the
/// current schedule are shown together in one frame, so reading them as three
/// subscriptions would let the screen draw a front from after an edit beside a
/// tag strip from before it. The list row already learned this — see
/// `CardListItemModel` — and detail has one more part to keep in step.
///
/// **History is deliberately not here.** It is append-only, paginated and has a
/// lifecycle of its own (BR-184, BR-187): editing content changes this model
/// and must change nothing about the events, which is a property that survives
/// only while the two are separate reads.
///
/// [tagNames] are names, not `TagEntity`s, for the same reason the list row
/// carries names: this surface displays tags and never acts on one, so it needs
/// nothing that identifies a tag row (BR-93). Adding and removing tags belongs
/// to the editor, which reads them through its own stream.
class CardDetailModel {
  const CardDetailModel({
    required this.card,
    required this.studyState,
    this.tagNames = const <String>[],
  });

  final CardEntity card;
  final CardStudyStateEntity studyState;
  final List<String> tagNames;

  /// The four-way display state (BR-89…BR-91), derived on read exactly as the
  /// list row derives it — one function, so the two surfaces cannot disagree
  /// about what a card's state is.
  CardState get state => cardStateOf(studyState);
}
