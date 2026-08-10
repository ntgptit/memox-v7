import 'fill_mode.dart';
import 'guess_mode.dart';
import 'match_mode.dart';
import 'recall_mode.dart';
import 'study_entry_summary_model.dart';
import 'study_lapse_policy_model.dart';
import 'study_turn_model.dart';

/// One of the six ways a card can be put in front of the user (BR-108).
///
/// **The set of modes belongs to the SRS algorithm, not to the deck and not to
/// the screen.** `eight_box` walks five of them, `sm2` walks two, and a UI that
/// hardcoded a list would be wrong for half the decks (BR-97). The algorithm
/// declares its own sequence; this enum only says what a mode *is*.
///
/// `unknown` exists for reading only, for the same reason `SchedulerType` has
/// one: a row written by a newer build must not take down the screen that reads
/// it. Writing it back is impossible by construction.
enum StudyMode {
  /// Front and back at once, no flip, no action, no history row (BR-111,
  /// BR-112). It is the only mode that grades nothing, which is why it can
  /// never appear in `study_answers.mode` and never appears as a review choice.
  browse('browse'),

  /// Flip, then the user picks the action themselves (BR-112).
  ///
  /// It takes the action **directly** rather than grading — the one mode where
  /// BR-107's binary-to-action mapping does not apply (BR-106).
  selfAssess('self_assess'),

  /// Pairs on a board. Needs at least two pairs to be worth playing (BR-153).
  match('match'),

  /// One question, five options, exactly one correct (BR-121).
  guess('guess'),

  /// Twenty seconds to recall it, and running out counts as wrong (BR-128,
  /// BR-107).
  recall('recall'),

  /// Type the answer; graded against the folded back, diacritics intact
  /// (BR-134).
  fill('fill'),

  /// A stored value this build does not recognise. Read-only.
  unknown(null);

  const StudyMode(this._dbValue);

  final String? _dbValue;

  /// The value stored in the database.
  ///
  /// Throws for [unknown]: a value nothing owns must never round-trip back into
  /// storage, where it would look like a decision somebody made.
  String get dbValue {
    final value = _dbValue;
    if (value == null) {
      throw StateError('StudyMode.unknown cannot be written to storage');
    }

    return value;
  }

  /// Whether this mode produces an action, and therefore a history row.
  ///
  /// Only [browse] does not (BR-111). Asking the mode is what keeps that rule
  /// in one place instead of in every caller's `if`.
  bool get producesAnswer => this != browse && this != unknown;

  /// Whether this mode grades to right/wrong and then asks the algorithm what
  /// that maps to (BR-106, BR-107).
  ///
  /// **Every mode that answers, except [selfAssess]** — which takes the action
  /// straight from the user and so needs no mapping at all. Written as the rule
  /// reads rather than as a list of four, because a list is a second place the
  /// set of modes lives and it drifts the day a seventh mode arrives.
  ///
  /// It happens to select the same four as [usesRounds]. That is a coincidence
  /// of the current algorithms, not one rule: rounds are about how a stage
  /// repeats, this is about where the action comes from, and merging them would
  /// make a future mode that grades without rounds impossible to express.
  bool get isBinaryGraded => producesAnswer && this != selfAssess;

  /// Whether this mode repeats by round rather than by BR-26's comeback.
  ///
  /// The four graded modes do (BR-115); [selfAssess] does not, and [browse] has
  /// nothing to repeat. Getting this backwards is not a small bug: a
  /// [selfAssess] queue driven by rounds would drop BR-26's ceiling of 3, and a
  /// [match] queue driven by BR-26 would never finish its failed set.
  bool get usesRounds => switch (this) {
    match || guess || recall || fill => true,
    browse || selfAssess || unknown => false,
  };

  /// Maps a stored value to the enum, tolerating values from newer schemas.
  static StudyMode fromDbValue(String value) {
    for (final mode in values) {
      if (mode._dbValue == value) return mode;
    }

    return unknown;
  }
}

/// What one mode knows that the shared flow does not (AD-18).
///
/// **Strategy, not Template Method.** The ten steps of a turn are the use case's
/// — seven of them are writes that have to share a transaction — so a base class
/// holding `process()` would have to hold a repository, and `domain/` would grow
/// I/O. What is left for a mode is what only it can answer, and that is this.
///
/// A handler never calls another handler; moving between stages is the shared
/// flow's decision.
abstract class StudyModeHandler {
  /// Handlers are stateless values, so every one of them is a `const`.
  const StudyModeHandler();

  /// What a wrong answer does to the queue row it was given on.
  ///
  /// **The rule that used to be an `if` in the repository.** A mode is the only
  /// thing that knows whether its card is still on screen after a wrong answer,
  /// and that is the whole difference between the four policies. Stating it
  /// here keeps the data layer executing a policy rather than recognising a
  /// mode, which is the second exhaustive branch AD-18 does not allow.
  StudyLapsePolicy get lapsePolicy;

  /// How many of the session's due cards this mode can actually take (BR-154).
  ///
  /// Zero means offered but unable to build content — disabled on the chooser
  /// **with its reason**, never hidden (BR-99). This is the rule that used to
  /// sit in the repository and then in the chooser widget; it belongs here,
  /// because it is the one thing that differs per mode and nothing else about
  /// counting rows does.
  int capacityFrom(StudyEntrySummaryModel summary);

  /// Whether this mode can put [card] in front of somebody at all (BR-114).
  ///
  /// **A card the mode cannot use is skipped, not dropped.** It stays in the
  /// deck, it still appears in every other stage, and — crucially — it has no
  /// row in this one to sit `pending` forever. That is what lets it finish the
  /// learning chain with the rest: completion asks "nothing pending anywhere",
  /// and a stage it never joined has nothing to answer for (BR-144).
  ///
  /// Defaulting to true is right for every mode but one: only `fill` needs a
  /// field the card may not have.
  bool canTake(StudyCardModel card) => true;

  /// Whether this mode can run **at all** on a session-s card set (BR-99).
  ///
  /// **A different question from [canTake], and the difference is the bug this
  /// exists to fix.** `canTake` asks about one card; this asks about the set.
  /// `match` needs two pairs and `guess` needs five distinct meanings — neither
  /// is a property any single card has, so a per-card check passes every card
  /// and the stage is laid out anyway. It then renders nothing and the session
  /// stops with no card, no message and no way forward.
  ///
  /// Answering it when the queue is written is what makes the stage *skipped*
  /// rather than *stuck*: with no rows it is exhausted, and the session advances
  /// past it exactly as it does past a `fill` stage no card could join (BR-114).
  /// The card set is fixed for the session-s whole life (BR-102), so the answer
  /// cannot change under it.
  bool canRunOn(List<StudyCardModel> cards) => true;
}

/// Every mode that needs nothing built: it takes whatever is due.
///
/// `browse` and `self_assess` both show one card and ask about it, so there is
/// no content to assemble and no threshold to clear. Giving them a shared
/// handler rather than two identical ones is what keeps the difference between
/// modes readable — the file that has something in it is the file with a rule.
///
/// `recall` has the same capacity and its own handler, because the clock is a
/// rule even though the card set is not.
///
/// **The policy is a constructor argument, and that is the one place the two
/// differ.** `browse` records nothing and `self_assess` retries on a gap, so
/// they are no longer identical — but they are identical in everything a
/// *handler* does, and splitting the class would duplicate the capacity rule to
/// carry one enum value. The resolver below is where the difference is stated,
/// which is where every other per-mode difference is stated too.
final class PlainModeHandler extends StudyModeHandler {
  const PlainModeHandler(this.lapsePolicy);

  @override
  final StudyLapsePolicy lapsePolicy;

  @override
  int capacityFrom(StudyEntrySummaryModel summary) => summary.dueCount;
}

/// The single exhaustive dispatch on [StudyMode] (AD-18).
///
/// **It lives beside the enum on purpose.** The guard names
/// `study_mode_resolver.dart` as the one file allowed to branch here, but the
/// naming rule forbids a `_resolver` suffix under `domain/` — the two rules
/// cannot both be satisfied by that filename. A `*_mode.dart` file satisfies
/// both, and the map from a value to its behaviour reads best next to the value.
///
/// Missing a branch is a compile error, which is the check a runtime registry
/// cannot make. [StudyMode.unknown] has none by construction: a mode this build
/// does not recognise cannot be run, only read.
StudyModeHandler? studyModeHandler(StudyMode mode) => switch (mode) {
  StudyMode.browse => const PlainModeHandler(StudyLapsePolicy.noAnswer),
  StudyMode.selfAssess => const PlainModeHandler(StudyLapsePolicy.spacedRetry),
  StudyMode.recall => const RecallModeHandler(),
  StudyMode.match => const MatchModeHandler(),
  StudyMode.guess => const GuessModeHandler(),
  StudyMode.fill => const FillModeHandler(),
  StudyMode.unknown => null,
};
