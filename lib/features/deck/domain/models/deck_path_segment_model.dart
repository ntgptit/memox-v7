import 'package:freezed_annotation/freezed_annotation.dart';

part 'deck_path_segment_model.freezed.dart';

/// One step on the path from the root down to the deck currently open.
///
/// **Not a [DeckEntity], on purpose.** An ancestor is read for exactly two
/// reasons — to be named, and to be navigated to — so the query returns exactly
/// two columns for it. Widening this to the full entity would mean either
/// selecting eleven columns per ancestor that nobody reads, or constructing an
/// entity with invented `contentType` and timestamps. The second is worse than
/// the first: a half-built entity is indistinguishable from a real one at every
/// call site that receives it.
///
/// The list this appears in is ordered **root first** and excludes the deck the
/// user is currently in — that one is `DeckListSnapshot.parent`, and carrying it
/// twice would let one read disagree with itself.
@freezed
abstract class DeckPathSegment with _$DeckPathSegment {
  const factory DeckPathSegment({
    required String id,

    /// The name as it stood in the same snapshot as everything else on screen.
    /// A rename lands on the breadcrumb and the title in the same frame.
    required String name,
  }) = _DeckPathSegment;

  const DeckPathSegment._();
}
