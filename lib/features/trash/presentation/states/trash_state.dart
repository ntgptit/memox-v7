import '../../../../core/state/submit_state.dart';
import '../../domain/entities/trash_batch_entity.dart';
import '../../domain/failures/trash_conflict_failure.dart';
import '../../domain/models/trash_item_type_model.dart';

/// Which kinds of item the Trash list is showing (wireframe T3).
///
/// A filter, not two lists: Trash is almost always short, so two tabs would be
/// two empty screens where one screen has content — and `all` is the right
/// default, which a `TabBar` has no way to express.
enum TrashFilter {
  all,
  cards,
  decks;

  /// Whether [type] passes this filter.
  bool admits(TrashItemType type) => switch (this) {
    all => true,
    cards => type == TrashItemType.card,
    decks => type == TrashItemType.deck,
  };
}

/// The rows the user has pointed at (BR-192).
///
/// **A selection notifier writes nothing**, exactly like Card's: each mutation
/// is its own command controller with its own submit state, so a spinner never
/// lives on the set and a refused write never has to un-select anything.
///
/// The ids are held rather than the entities, because the list is a live stream:
/// holding entities would keep a snapshot alive past the write that changed it,
/// and the ids are what every command takes anyway.
final class TrashSelectionState {
  const TrashSelectionState({this.batchIds = const <String>{}, this.itemType});

  final Set<String> batchIds;

  /// The kind the selection is locked to, or null when nothing is selected.
  ///
  /// BR-192: a restore or purge never mixes cards and decks, so the **first**
  /// selected row decides what the rest may be. Stored rather than derived from
  /// the ids, because deriving it needs the list — and the list is a stream
  /// that may have moved on since the row was tapped.
  final TrashItemType? itemType;

  bool get isActive => batchIds.isNotEmpty;

  bool contains(String batchId) => batchIds.contains(batchId);

  /// Whether [batch] may join the current selection (BR-192).
  bool admits(TrashBatchEntity batch) =>
      itemType == null || itemType == batch.itemType;
}

/// The status of one Trash write.
///
/// The shared [SubmitState], parameterised by nothing: Trash has no form and no
/// field-level problems — a refusal is a `Failure` carrying a
/// [TrashConflictReason], which the screen maps to copy. The type argument is
/// present because the shared state is generic, and `TrashConflictReason` is
/// the honest thing to name even though `problems` stays empty.
typedef TrashSubmitState = SubmitState<TrashConflictReason>;
