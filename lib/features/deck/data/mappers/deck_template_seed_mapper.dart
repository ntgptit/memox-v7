import 'package:drift/drift.dart' show Value;

import '../../../../core/database/app_database.dart';
import '../../domain/models/deck_template_model.dart';
import '../../domain/models/scheduler_type_model.dart';

/// Review-state initialisation per scheduler (BR-09 table).
const int _eightBoxInitialBox = 1;
const double _sm2InitialEaseFactor = 2.5;
const int _sm2InitialIntervalDays = 0;
const int _sm2InitialRepetitions = 0;

/// The card row a template card copies to.
///
/// **`front_folded` and `back_folded` are written here, with the text they
/// fold.** A card whose folded column disagrees with its text is invisible to
/// search while looking perfectly correct in the list — the exact defect
/// `CardRepositoryImpl` documents, and the copy path is a second place that
/// could produce it.
CardsCompanion templateCardCompanion(
  DeckTemplateCard card, {
  required String cardId,
  required String deckId,
  required DateTime now,
}) => CardsCompanion.insert(
  id: cardId,
  deckId: deckId,
  front: card.front.value,
  back: card.back.value,
  frontFolded: Value<String>(card.front.folded),
  backFolded: Value<String>(card.back.folded),
  example: Value<String?>(card.example?.value),
  createdAt: now,
  updatedAt: now,
);

/// The review state a copied card is born with (BR-09), per scheduler.
///
/// **A second copy of the card feature's `initialReviewStateFromScheduler`, and
/// deliberately so.** That one lives in `features/card/data/`, which this
/// feature may not import — features are islands below `domain/`. The
/// alternative was to move it into `core/`, which would make BR-09's table
/// shared infrastructure owned by neither feature. Two short mappers that a
/// test pins against each other is the cheaper of the two, and
/// `deck_template_repository_test.dart` asserts the columns rather than trusting
/// the duplication.
///
/// [SchedulerType.unknown] cannot arrive: the loader refuses a template whose
/// `default_scheduler_type` this build does not know, and the caller may only
/// override it with a real one. The branch throws rather than writing a row no
/// scheduler owns.
CardReviewStatesCompanion templateReviewStateCompanion(
  String cardId, {
  required ({SchedulerType type, int version, int generation}) scheduler,
}) {
  final base = CardReviewStatesCompanion.insert(
    cardId: cardId,
    schedulerType: scheduler.type.dbValue,
    schedulerVersion: scheduler.version,
    schedulerGeneration: scheduler.generation,
  );

  return switch (scheduler.type) {
    SchedulerType.eightBox => base.copyWith(
      currentBox: const Value<int?>(_eightBoxInitialBox),
    ),
    SchedulerType.sm2 => base.copyWith(
      easeFactor: const Value<double?>(_sm2InitialEaseFactor),
      intervalDays: const Value<int?>(_sm2InitialIntervalDays),
      repetitions: const Value<int?>(_sm2InitialRepetitions),
    ),
    SchedulerType.unknown => throw StateError(
      'A template cannot install with an unknown scheduler; the loader '
      'refuses one and the caller may only override with a real scheduler.',
    ),
  };
}
