import 'package:freezed_annotation/freezed_annotation.dart';

import '../entities/study_queue_item_entity.dart';

part 'study_turn_model.freezed.dart';

/// The card content one turn needs, and only that.
///
/// **Not `CardEntity`.** That belongs to the Card feature and carries the flag,
/// the tags, the timestamps and the folded columns — none of which a turn
/// renders. Taking the whole entity would make Study depend on every future
/// change to a card's shape, for four strings.
@freezed
abstract class StudyCardModel with _$StudyCardModel {
  const factory StudyCardModel({
    required String id,
    required String front,
    required String back,

    /// What `fill` asks about, and it is optional — which is why that stage
    /// takes fewer cards than the others (BR-114, BR-154).
    required String? example,

    required String? hint,
    required String? pronunciation,

    /// The folded front, which is what `fill` grades against (BR-134).
    ///
    /// **The term, not the meaning, and that is the whole direction of the
    /// mode.** `fill` shows the card's back — the English/Vietnamese gloss — and
    /// asks for the Korean term, so the string an answer is compared with is the
    /// folded *front*. Grading against [backFolded] marked a correct Korean
    /// answer wrong and a learner echoing the prompt right, which is a screen
    /// that looks entirely reasonable and teaches the wrong thing.
    ///
    /// Read from `cards.front_folded` rather than folded here: the column
    /// already exists, and a second fold in the presentation layer is a second
    /// policy that drifts from the one BR-135 versions.
    required String frontFolded,

    /// The folded back, for telling two meanings apart in `guess` (BR-123).
    /// Diacritics intact: `cong` is not `công`.
    required String backFolded,
  }) = _StudyCardModel;
}

/// How far the running round has got, and how far it goes.
///
/// **The round, not the stage and not the session.** A stage enrols a failed
/// card into the next round the moment it fails (BR-116), so a stage-wide total
/// grows while the user answers and the bar walks backwards. A round is a fixed
/// set for as long as it is being served, which is what makes it something to
/// measure against.
@freezed
abstract class StudyStageProgressModel with _$StudyStageProgressModel {
  const factory StudyStageProgressModel({
    /// Which round this is. The frame names it (§7.6): the design says
    /// `BOARD 1 OF 3`, and "board" is a word no rule owns — BR-115 and BR-117
    /// have only rounds, so the label says round.
    required int round,

    required int done,
    required int total,

    /// The cards of this round already answered.
    ///
    /// **`match` needs the identities, not just the count** (§4). Its board
    /// keeps a paired tile in place and stops it being a target, and the screen
    /// unmounts the board between turns — so a widget remembering its own ticks
    /// forgets them every card, and the same pair could be answered again.
    required List<String> completedCardIds,

    /// Every card of this round, in the order the round serves them (BR-156).
    ///
    /// **`match` deals its boards from this, not from the session's cards.** A
    /// board is at most [kMatchPairsPerBoard] pairs and the round is dealt into
    /// consecutive boards; dealing from the session instead is the same list
    /// only in round 1, and from round 2 it laid out every card in the session
    /// under a counter that was already down to the failures.
    ///
    /// **Defaulted rather than required, and the default is a fallback, not a
    /// blank.** Every repository read fills it; the widget tests that build a
    /// progress by hand care about the counter and would each grow a card list
    /// that says nothing. A caller finding it empty falls back to the card set
    /// it already has, which is what the board did before this existed.
    @Default(<String>[]) List<String> roundCardIds,
  }) = _StudyStageProgressModel;

  const StudyStageProgressModel._();

  /// This progress with one more card answered correctly.
  ///
  /// **`match` moves its own counter between fetches** — a board answers five
  /// pairs and re-reading the round after each one costs four reads and four
  /// unmounts of the board being played. Idempotent, because a rebuild between
  /// the write and this can carry a progress that already holds the card, and
  /// counting it twice puts `done` past `total` and deals a board that does not
  /// exist.
  StudyStageProgressModel withCleared(String cardId) =>
      completedCardIds.contains(cardId)
      ? this
      : copyWith(
          done: done + 1,
          completedCardIds: <String>[...completedCardIds, cardId],
        );

  /// 0 to 1, and 0 rather than NaN for a round with nothing in it.
  double get fraction => total <= 0 ? 0 : done / total;

  /// How many of this round's cards are still unanswered.
  int get remaining => total - done < 0 ? 0 : total - done;
}

/// One turn: where the card sits in the queue, what the card says, and how far
/// through the round it is.
///
/// **One read, not three** (AD-13). The screen needs all of it at once, and
/// fetching separately means the queue row, the card content and the counter can
/// come from either side of a write — which is how a screen ends up showing one
/// card's front with another's timer, or a bar drawn against a total from before
/// the answer that just landed.
@freezed
abstract class StudyTurnModel with _$StudyTurnModel {
  const factory StudyTurnModel({
    required StudyQueueItemEntity item,
    required StudyCardModel card,

    /// What the frame's counter and progress bar read from (§7.2). Not derived
    /// by the screen: a screen counting its own turns is a second copy of the
    /// queue, and the copy is the one the user sees when a write is refused.
    required StudyStageProgressModel progress,
  }) = _StudyTurnModel;

  const StudyTurnModel._();

  String get cardId => card.id;

  /// Whether [other] is the same turn, which is **not** the same card.
  ///
  /// **A card comes back** (BR-116). A stage enrols a card it was answered
  /// wrongly on into the next round, and that round serves the same `cardId` —
  /// so a mode widget asking "is this still the turn I was drawing?" by id
  /// alone answers yes to a turn the user has not answered yet, and keeps
  /// whatever it was holding: a revealed back, a typed answer, a settled
  /// outcome. All three of those shipped, and the last one drew "this turn is
  /// settled" over a live question with no way forward.
  ///
  /// It lives here rather than in each widget because three of them had already
  /// spelled it the short way, and a fourth would have too.
  bool isSameTurnAs(StudyTurnModel other) =>
      cardId == other.cardId && item.round == other.item.round;
}
