import 'package:freezed_annotation/freezed_annotation.dart';

import 'study_mode_model.dart';

part 'study_entry_summary_model.freezed.dart';

/// Everything the entry point to a deck's study flow needs, in one read.
///
/// **One read, not three** (AD-13). The badge needs two numbers and the mode
/// chooser needs one per mode; fetching them separately means three snapshots,
/// and the screen can then draw a badge from before a write next to a chooser
/// from after it. A count that disagrees with the screen beside it is worse than
/// a slow count.
@freezed
abstract class StudyEntrySummaryModel with _$StudyEntrySummaryModel {
  const factory StudyEntrySummaryModel({
    /// Cards that have not finished the learning chain (BR-90, BR-142).
    required int newCount,

    /// Cards that finished it and have come due (BR-142, BR-151).
    ///
    /// Disjoint from [newCount] by definition since v5, not by the predicate
    /// being written as a subtraction.
    required int dueCount,

    /// How many of the due cards each mode could actually take (BR-154).
    ///
    /// **Not one number shared by every mode.** `fill` only accepts cards
    /// carrying an `example`, so a twenty-card review can be three cards long in
    /// that mode — and a chooser showing "20" against each of four modes would
    /// be lying about three of them.
    ///
    /// A mode missing from this map is one the deck's algorithm does not offer
    /// (BR-146); a mode present with `0` is offered but has nothing to work with
    /// and is disabled with its reason (BR-99).
    required Map<StudyMode, int> dueCountByMode,
  }) = _StudyEntrySummaryModel;
}
