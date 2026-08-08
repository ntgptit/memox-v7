import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../deck/domain/models/scheduler_type_model.dart';

part 'study_deck_context_model.freezed.dart';

/// What a use case has to know about a deck before it can open a session.
///
/// **One read, not three** (AD-13). The root, the algorithm and the generation
/// are all properties of the same deck at the same instant; fetching them
/// separately means a session could be opened against a root that has just been
/// reset, with a generation read from before the reset.
@freezed
abstract class StudyDeckContextModel with _$StudyDeckContextModel {
  const factory StudyDeckContextModel({
    required String deckId,

    /// The name of the deck being studied — the branch the user opened, not the
    /// root. It rides along because the session frame shows it and the deck row
    /// is already being read; a second read for one string is a second snapshot.
    required String deckName,

    /// Resolved through `root_deck_id`, never by walking parents (BR-57).
    required String rootDeckId,

    /// The root's algorithm (BR-06). [SchedulerType.unknown] means a deck
    /// written by a newer build — readable, but not studiable.
    required SchedulerType schedulerType,

    required int schedulerGeneration,
  }) = _StudyDeckContextModel;
}
