import 'dart:math';

import '../../../deck/domain/models/scheduler_type_model.dart';
import 'study_mode.dart';
import 'study_session_kind_model.dart';

/// Which of a card's two faces a turn is looking at.
///
/// **A named face, not a boolean.** `isFront: false` at a call site says nothing
/// about what the other half then holds, and the two halves are not each other's
/// negation once a third face is imaginable. It also keeps the mapping in
/// [StudyRecallDirection] readable as a table rather than as a chain of
/// inversions.
enum StudyCardFace {
  /// `cards.front` — the Korean term (BR-08).
  front,

  /// `cards.back` — the meaning in the learner's language (BR-08).
  back,
}

/// The way **one turn** actually asks (BR-204).
///
/// **There is no `mixed` here, and that is the point.** Mixed is a choice about
/// a *session*; a card in front of somebody is being asked one way or the other,
/// never both. Splitting the two enums makes "render a mixed card" impossible to
/// write rather than merely wrong, which is what stopped the direction being
/// re-drawn on every rebuild.
///
/// `unknown` exists for reading only, for the reason [StudyMode] has one: a row
/// written by a newer build must not take down the screen that reads it. Writing
/// it back is impossible by construction.
enum StudyRecallDirection {
  /// The Korean term is the prompt; the meaning is the reveal. Recognition, and
  /// the only thing the app could measure before BR-203.
  koreanToMeaning('korean_to_meaning'),

  /// The meaning is the prompt; the Korean term is the reveal. Production.
  meaningToKorean('meaning_to_korean'),

  /// A stored value this build does not recognise. Read-only.
  unknown(null);

  const StudyRecallDirection(this._dbValue);

  final String? _dbValue;

  /// The value stored in the database.
  ///
  /// Throws for [unknown]: a value nothing owns must never round-trip back into
  /// storage, where it would look like a decision somebody made.
  String get dbValue {
    final value = _dbValue;
    if (value == null) {
      throw StateError('StudyRecallDirection.unknown cannot be written');
    }

    return value;
  }

  /// The face the learner is asked from (BR-204).
  ///
  /// [unknown] falls back to the front, which is what every build before BR-203
  /// did. A screen that cannot name the direction still has to draw a card, and
  /// drawing the historical default is the one answer that is never a surprise.
  StudyCardFace get promptFace => switch (this) {
    koreanToMeaning || unknown => StudyCardFace.front,
    meaningToKorean => StudyCardFace.back,
  };

  /// The face revealed on the flip — always the other one.
  ///
  /// Derived rather than tabulated a second time: two tables that must agree are
  /// two tables that can disagree, and the failure would be a card showing the
  /// same text twice.
  StudyCardFace get revealFace => promptFace == StudyCardFace.front
      ? StudyCardFace.back
      : StudyCardFace.front;

  /// Maps a stored value to the enum, tolerating values from newer schemas.
  static StudyRecallDirection fromDbValue(String value) {
    for (final direction in values) {
      if (direction._dbValue == value) return direction;
    }

    return unknown;
  }
}

/// What the learner chose before the session started (BR-203).
///
/// Fixed at the moment the session opens and locked for its whole life, the same
/// way `card_limit` and `scheduler_generation` are (BR-139, BR-45). Two turns of
/// one card inside one session must measure the same skill, or the history rows
/// they write cannot be told apart from a session that was consistent.
enum StudySessionDirection {
  /// Every card asks from the Korean term.
  koreanToMeaning('korean_to_meaning'),

  /// Every card asks from the meaning.
  meaningToKorean('meaning_to_korean'),

  /// Each card is assigned one of the two, once, when the queue is written
  /// (BR-205).
  mixed('mixed'),

  /// A stored value this build does not recognise. Read-only.
  unknown(null);

  const StudySessionDirection(this._dbValue);

  final String? _dbValue;

  /// The value stored in the database. Throws for [unknown] — see
  /// [StudyRecallDirection.dbValue].
  String get dbValue {
    final value = _dbValue;
    if (value == null) {
      throw StateError('StudySessionDirection.unknown cannot be written');
    }

    return value;
  }

  /// The direction every card of the session runs in, or null for [mixed].
  ///
  /// Null is the question "which one?" having no session-wide answer, which is
  /// exactly when [assignMixedDirections] is the one that answers it — per card,
  /// once.
  StudyRecallDirection? get fixedDirection => switch (this) {
    koreanToMeaning => StudyRecallDirection.koreanToMeaning,
    meaningToKorean => StudyRecallDirection.meaningToKorean,
    mixed || unknown => null,
  };

  /// Maps a stored value to the enum, tolerating values from newer schemas.
  static StudySessionDirection fromDbValue(String value) {
    for (final direction in values) {
      if (direction._dbValue == value) return direction;
    }

    return unknown;
  }
}

/// The direction offered as Recommended, and selected when the chooser opens.
///
/// **One constant for both, because they are one decision.** A suggestion is
/// worth making only if it is also what a learner who does not engage with the
/// question ends up with, and two constants would let those drift apart in
/// silence. Korean→Meaning is what every review did before BR-203, so taking the
/// suggestion — or ignoring the question — gives the app they already have.
///
/// It lives in `domain/` rather than beside the sheet because it is a product
/// decision, and because `presentation/support/` needs it to know which option's
/// description carries the marker; a constant owned by an overlay would have to
/// be imported backwards.
const StudySessionDirection kStudyRecommendedDirection =
    StudySessionDirection.koreanToMeaning;

/// The one place the feature's reachability is decided (BR-203).
///
/// **A predicate, in `domain/`, asked by everything.** The condition is a
/// conjunction of three facts that live in three different places — the session's
/// kind, the root deck's algorithm and the stage being run — and spelling it out
/// at each call site is how one of the three gets forgotten. The chooser, the use
/// case that refuses a direction it should not have been given, and the tests
/// that prove `eight_box` cannot reach any of it all ask this.
///
/// `self_assess` is the only mode where direction changes **how a card is asked**
/// and nothing else. `fill` grades against `front_folded` (BR-134) and `guess`
/// draws distractors by `back_folded` (BR-123); reversing either changes what is
/// graded. `eight_box` never runs `self_assess` in a review at all (BR-110,
/// BR-146), and a `learning` session's stages are not the user's to choose
/// (BR-109).
bool isReverseDirectionEligible({
  required StudySessionKind kind,
  required SchedulerType schedulerType,
  required StudyMode mode,
}) =>
    kind == StudySessionKind.reviewing &&
    schedulerType == SchedulerType.sm2 &&
    mode == StudyMode.selfAssess;

/// One direction per card of a [StudySessionDirection.mixed] queue (BR-205).
///
/// **Balanced first, then shuffled — not a coin per card.** Twenty independent
/// flips land 14–6 or worse about one time in sixteen, and a learner who asked
/// for a mix and got fourteen of one kind has been handed something else. Built
/// as `⌈n/2⌉` of one and `⌊n/2⌋` of the other, the contract is `|a - b| <= 1` for
/// every [count] — a property a test can assert without pinning a seed, which a
/// distribution cannot.
///
/// [random] decides two things and only two: which side gets the odd card when
/// [count] is odd, and the order. Both come from the injected generator the
/// repository already carries, so a test pins the deal exactly and nothing in
/// `presentation/` ever constructs one.
List<StudyRecallDirection> assignMixedDirections({
  required int count,
  required Random random,
}) {
  if (count <= 0) return const <StudyRecallDirection>[];

  // The odd card is drawn rather than always given to the same side: a fixed
  // winner makes every odd-sized session lean the same way, which over a
  // fortnight of daily nineteen-card reviews is a bias the learner can feel.
  final first = random.nextBool()
      ? StudyRecallDirection.koreanToMeaning
      : StudyRecallDirection.meaningToKorean;
  final second = first == StudyRecallDirection.koreanToMeaning
      ? StudyRecallDirection.meaningToKorean
      : StudyRecallDirection.koreanToMeaning;

  final firstCount = (count + 1) ~/ 2;

  return <StudyRecallDirection>[
    for (var index = 0; index < count; index++)
      index < firstCount ? first : second,
  ]..shuffle(random);
}
