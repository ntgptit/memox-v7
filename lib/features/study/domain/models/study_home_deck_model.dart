import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../deck/domain/models/scheduler_type_model.dart';

part 'study_home_deck_model.freezed.dart';

/// One root deck on the Study tab, with the workload it is ranked by (BR-201).
///
/// A read model, not an entity. The counts are true at one instant and the deck
/// row is not; putting them on `DeckEntity` would put an expiring number onto
/// the type every write path also uses.
///
/// **Three counts, not one total** (BR-200, BR-162). They cost differently — a
/// card three days late is not the same errand as a card that came due this
/// morning, and neither is a card that has never been seen — so collapsing them
/// tells the reader nothing about what the next ten minutes will be like. They
/// are disjoint by construction: [overdueCount] and [dueTodayCount] partition
/// the Reviewing set of BR-142 at the local-day boundary, and [newCount] is the
/// other side of `learned_at`.
///
/// **Root decks only.** The scheduler, the generation and the session all belong
/// to the root (BR-06), and a session opened on a root covers its whole subtree
/// — so the subtree is what these counts aggregate (BR-57, AD-10).
@freezed
abstract class StudyHomeDeckModel with _$StudyHomeDeckModel {
  const factory StudyHomeDeckModel({
    required String deckId,
    required String deckName,

    /// The root's algorithm (BR-06). [SchedulerType.unknown] means a deck
    /// written by a newer build — listed, but the label is withheld rather than
    /// guessed.
    required SchedulerType schedulerType,

    /// Cards anywhere in this root's subtree, at any depth.
    ///
    /// The denominator that separates "nothing to do here today" from "there is
    /// nothing here" — two states with different next steps (BR-202).
    required int totalCardCount,

    /// Due cards whose `due_at` fell before the current local day began
    /// (BR-162): `learned_at IS NOT NULL AND due_at < startOfToday`.
    required int overdueCount,

    /// Due cards still inside today's local day (BR-162):
    /// `learned_at IS NOT NULL AND due_at >= startOfToday AND due_at <= now`.
    required int dueTodayCount,

    /// Cards that have not finished the learning chain (BR-90, BR-142).
    required int newCount,
  }) = _StudyHomeDeckModel;

  const StudyHomeDeckModel._();

  /// Every Reviewing card of the subtree — the total a session would draw from.
  ///
  /// Derived rather than carried, so the pair and their sum can never disagree:
  /// the split is presentation (BR-161), and it must not change what a session
  /// serves.
  int get dueCount => overdueCount + dueTodayCount;

  /// Whether anything is waiting in this deck right now (BR-150).
  ///
  /// The ranking key's own predicate, stated once: a row asking "is there
  /// anything here" three separate ways is a row where one of them drifts.
  bool get hasWorkload => dueCount > 0 || newCount > 0;

  /// Whether the deck can be opened at all.
  ///
  /// **Cards, not workload** (BR-201). A deck with nothing due is still a deck
  /// somebody can walk into — BR-29 makes "nothing pending" the schedule working
  /// rather than a locked door — and the entry screen says so honestly. A deck
  /// with no cards has nothing behind the action, so it does not get one.
  bool get isStudiable => totalCardCount > 0;
}

/// The order the Study tab lists decks in (BR-201).
///
/// **A comparator in `domain/`, not an `ORDER BY`.** The ranking keys are
/// integers SQL sorts perfectly well; the tie-break is the deck name folded for
/// comparison, and SQLite's `lower()` folds ASCII only — it leaves `Ô`, `Ê` and
/// `Đ` untouched, so a Vietnamese library would sort by whether a name happened
/// to start with a diacritic. Dart's `toLowerCase()` is Unicode-aware, which is
/// the same conclusion `CardText.folded` and `TagName.folded` reached (BR-93).
///
/// **The id is the last key, and it is not decoration.** Two decks with the same
/// workload and the same folded name would otherwise be ordered by whatever the
/// read happened to return, and a list that reshuffles two identical-looking
/// rows between two reads reads as a bug in the counts.
///
/// Decks with no workload sort last without a branch for them: `(0, 0, 0)` loses
/// every descending comparison to any row with something in it.
int compareStudyHomeDecks(StudyHomeDeckModel a, StudyHomeDeckModel b) {
  final byOverdue = b.overdueCount.compareTo(a.overdueCount);
  if (byOverdue != 0) return byOverdue;

  final byDueToday = b.dueTodayCount.compareTo(a.dueTodayCount);
  if (byDueToday != 0) return byDueToday;

  final byNew = b.newCount.compareTo(a.newCount);
  if (byNew != 0) return byNew;

  final byName = a.deckName.toLowerCase().compareTo(b.deckName.toLowerCase());
  if (byName != 0) return byName;

  return a.deckId.compareTo(b.deckId);
}
