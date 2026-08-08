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

    /// The folded back, for grading `fill` and for telling two meanings apart
    /// in `guess` (BR-123, BR-134). Diacritics intact: `cong` is not `công`.
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
    required int done,
    required int total,
  }) = _StudyStageProgressModel;

  const StudyStageProgressModel._();

  /// 0 to 1, and 0 rather than NaN for a round with nothing in it.
  double get fraction => total <= 0 ? 0 : done / total;
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
}
