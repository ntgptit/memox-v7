import 'package:freezed_annotation/freezed_annotation.dart';

import 'study_home_deck_model.dart';
import 'study_home_resume_model.dart';

part 'study_home_model.freezed.dart';

/// Everything the Study tab shows, from one read (AD-13, BR-182).
///
/// **One statement, not two** — and the resume is why. The Resume card and the
/// deck list describe the same library at the same instant: read separately, a
/// session finished between the two reads leaves a Resume card advertising a
/// session the list below it has already counted as done. A screen showing one
/// fact from before a write and another from after it is worse than a slow
/// screen.
///
/// **It is a read model and nothing on it is an instruction.** Rendering this,
/// scrolling it, or switching to the tab that holds it must write nothing:
/// no session, no scheduler lock, no materialised queue (BR-101, BR-182).
@freezed
abstract class StudyHomeModel with _$StudyHomeModel {
  const factory StudyHomeModel({
    /// The session that may be continued, or null when there is none to offer.
    required StudyHomeResumeModel? resume,

    /// Every root deck of the library, already in the order BR-183 defines.
    ///
    /// **Ordered by the read, not by the widget.** Ranking is business — which
    /// deck the app puts in front of somebody first — and a list re-sorted in
    /// `build()` is a rule no test below the widget layer can reach.
    ///
    /// Roots with no cards are present. Dropping them here would make "the
    /// library holds decks but no cards" indistinguishable from "the library is
    /// empty", and those two states have different next steps (BR-184).
    required List<StudyHomeDeckModel> decks,

    /// The earliest instant strictly after the read's `now` at which some card
    /// becomes due, or null when no card is scheduled to.
    ///
    /// Null is a real state with two causes — nothing scheduled, or everything
    /// already due — and both mean the same thing to the caller: there is
    /// nothing to wait for, so do not set a timer.
    required DateTime? nextDueAt,

    /// The next local midnight, when any deck has due cards — null otherwise
    /// (BR-161, BR-162).
    ///
    /// The split's own clock. [nextDueAt] goes null exactly when every scheduled
    /// card is already due, which is precisely when the overdue/due-today
    /// boundary still has to move: a tab left open across midnight must
    /// re-measure even though no row changed. From the same read as the counts,
    /// so the numbers and the instant they expire describe one snapshot.
    required DateTime? nextOverdueTickAt,
  }) = _StudyHomeModel;

  const StudyHomeModel._();

  /// Whether the library holds no root deck at all — the first-run state, whose
  /// way forward is ready-made content (BR-184, UC-01).
  bool get isLibraryEmpty => decks.isEmpty;

  /// Whether there are decks but not a single card anywhere in them.
  ///
  /// A different screen from [isLibraryEmpty] because it has a different next
  /// step: the folders exist, so what is missing is cards, and the way forward
  /// is the Library rather than the starter catalog (BR-184).
  bool get hasNoCards =>
      decks.isNotEmpty && decks.every((deck) => deck.totalCardCount == 0);

  /// The decks the list actually offers, in order (BR-183).
  ///
  /// Roots with no cards are filtered out here rather than in SQL: the unfiltered
  /// set is what [hasNoCards] needs to tell the two empty states apart, and a
  /// query that had already dropped them could not.
  List<StudyHomeDeckModel> get studiableDecks =>
      decks.where((deck) => deck.isStudiable).toList(growable: false);
}
