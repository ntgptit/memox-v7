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

/// One turn: where the card sits in the queue, and what the card says.
///
/// **One read, not two** (AD-13). The screen needs both at once, and fetching
/// them separately means the queue row and the card content can come from either
/// side of a write — which is how a screen ends up showing one card's front with
/// another's timer.
@freezed
abstract class StudyTurnModel with _$StudyTurnModel {
  const factory StudyTurnModel({
    required StudyQueueItemEntity item,
    required StudyCardModel card,
  }) = _StudyTurnModel;

  const StudyTurnModel._();

  String get cardId => card.id;
}
