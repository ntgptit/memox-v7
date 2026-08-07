import 'package:freezed_annotation/freezed_annotation.dart';

part 'study_entry_summary_model.freezed.dart';

/// Everything the entry point to a deck's study flow needs, in one read.
///
/// **One read, not three** (AD-13). The badge needs two numbers and the mode
/// chooser needs one per mode; fetching them separately means separate
/// snapshots, and the screen can then draw a badge from before a write next to a
/// chooser from after it. A count that disagrees with the screen beside it is
/// worse than a slow count.
///
/// **Facts, not per-mode verdicts.** The last two fields are raw material, and
/// deliberately so: "how many cards can `fill` take" is that mode's policy, and
/// AD-18 puts a mode's policy in its handler rather than anywhere that would
/// have to branch on the mode to find it. The repository counts; the resolver
/// decides.
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

    /// How many of the due cards carry an `example`.
    ///
    /// What `fill` can actually take (BR-114), and the reason BR-154 forbids one
    /// shared number: `example` is optional, so a twenty-card review can be
    /// three cards long in that one mode.
    required int fillableCount,

    /// How many distinct meanings the due cards have, measured on
    /// `back_folded` (BR-123).
    ///
    /// What `guess` needs five of, and measured on the folded form because two
    /// cards that merely *display* differently are the same meaning and must
    /// never share an option set.
    required int distinctMeanings,
  }) = _StudyEntrySummaryModel;
}
