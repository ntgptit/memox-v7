import 'package:freezed_annotation/freezed_annotation.dart';

part 'progress_path_segment_model.freezed.dart';

/// One step of the path from a root deck down to the deck a row stands for.
///
/// **Progress declares its own rather than importing Deck's `DeckPathSegment`.**
/// The two carry the same two fields today and that is a coincidence of what a
/// breadcrumb needs, not a shared contract: Deck's segment belongs to a
/// breadcrumb that is also a navigation target inside the deck tree, and coupling
/// a second feature to it would make any change to Deck's navigation a change to
/// this screen's read model (AD-17). Two lines of duplication is the cheaper
/// half of that trade.
///
/// Ordered **root first**, and the deck the row is about is never in its own
/// path — that is the row's own name, and carrying it twice would let one read
/// disagree with itself.
@freezed
abstract class ProgressPathSegment with _$ProgressPathSegment {
  const factory ProgressPathSegment({
    required String id,

    /// The name as it stood in the same snapshot as everything else on screen,
    /// so a rename lands on the title and on every row's path in one frame.
    required String name,
  }) = _ProgressPathSegment;

  const ProgressPathSegment._();
}
