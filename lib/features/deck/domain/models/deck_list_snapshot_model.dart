import 'package:freezed_annotation/freezed_annotation.dart';

import '../entities/deck_entity.dart';
import 'deck_path_segment_model.dart';
import 'deck_summary_model.dart';

part 'deck_list_snapshot_model.freezed.dart';

/// One level of the deck tree: where the user is, what is in it, and when the
/// numbers expire.
///
/// **One type for the root list and for the inside of a deck**, because they are
/// one screen. Opening a deck does not change what the user is looking at — it
/// changes which level of the same tree — and modelling the two separately is
/// what produced two screens that drifted apart. This replaced
/// `DeckListSnapshot` and `DeckDetail`, which between them described exactly
/// this and disagreed about how much of it to carry.
///
/// Every field comes from **one** statement (AD-13). The parent and its children
/// have to agree: the action set on screen is computed from the parent's
/// `content_type` and from whether the children are empty (BR-68) at the same
/// time, so two reads would let the screen render an action matrix from a deck
/// captured at one instant and a list captured at another.
@freezed
abstract class DeckListSnapshot with _$DeckListSnapshot {
  const factory DeckListSnapshot({
    /// The deck being looked *inside*, or null at the root of the tree.
    ///
    /// Null is not "missing" — it is the top level, which has no deck of its own.
    /// A deck that was asked for and does not exist surfaces as a
    /// `NotFoundFailure` on the stream instead, because a dead route and the home
    /// screen must not render the same way.
    required DeckEntity? parent,

    /// What is directly inside [parent] — or every root deck when it is null.
    required List<DeckSummary> decks,

    /// The path from the root down to, but not including, [parent] — root first.
    ///
    /// Empty at the root level, and empty again one level in: a root deck's own
    /// ancestry is nothing. The first non-empty case is level 3, which is also
    /// the first level where "where am I" stops being answerable from the title
    /// alone.
    ///
    /// From the same statement as everything else (AD-13). Read separately, a
    /// rename could land on the title and not on the breadcrumb, and the screen
    /// would show one deck under two names.
    required List<DeckPathSegment> ancestors,

    /// The earliest instant strictly after the read's `now` at which some card
    /// becomes due, or null when no card is scheduled to.
    ///
    /// Null is a real state with two causes — no cards at all, or every card
    /// already due — and both mean the same thing to the caller: there is nothing
    /// to wait for, so do not wait.
    required DateTime? nextDueAt,
  }) = _DeckListSnapshot;

  const DeckListSnapshot._();

  /// Whether this level is the top of the tree.
  bool get isRootLevel => parent == null;

  /// Whether the content type can be put back to `unset` (BR-68).
  ///
  /// Direct children only, and only for a sub-deck: a root's content type is
  /// invariant (BR-58), and the root *level* has no deck to reset at all. Cards
  /// are **not** counted here — this screen can only say "no child decks", and the
  /// repository is what refuses a reset on a deck that still holds cards. That is
  /// the right split: the UI offers, the repository decides.
  bool get mayOfferReset {
    final deck = parent;
    if (deck == null) return false;

    return !deck.isRoot && decks.isEmpty;
  }
}
