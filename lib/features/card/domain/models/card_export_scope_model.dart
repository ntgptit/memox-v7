import '../../../../core/error/failure.dart';
import '../failures/card_export_failure.dart';

/// What an export covers (BR-174). Exactly two shapes, and there is no third
/// in v1.
///
/// **Sealed rather than a flag plus a nullable list.** A pair of
/// `isAll` and `ids` can represent "all cards, and also these seven", "the
/// selection, but the id set is null" and "the selection, but the id set is
/// empty" — three states the rule forbids and no type prevents. Every one of
/// them would have to be checked for, in every layer that touched it. A
/// sealed pair makes the switch exhaustive instead: adding a third scope one
/// day fails to compile until every dispatch has answered for it.
///
/// The scope is a **consequence of the entry point**, never a control on the
/// sheet (UC-11 step 1) — the overflow menu produces [CardExportWholeDeckScope]
/// and the selection bar produces [CardExportSelectionScope].
sealed class CardExportScope {
  const CardExportScope();
}

/// Every card held **directly** by the open deck (BR-174).
///
/// Independent of the filter, search term, sort and pagination the list
/// happens to be showing, and never a descendant deck's cards: the user asked
/// for the deck, not for the view of it they were looking at.
final class CardExportWholeDeckScope extends CardExportScope {
  const CardExportWholeDeckScope();
}

/// Exactly the ids materialized from selection mode (BR-167, BR-174).
///
/// Ids are **normalized on construction**, and an empty set is refused there
/// too: this is CLAUDE.md's "an input rule belongs to a type" applied to a
/// scope. A duplicate id that reached the repository would either duplicate a
/// row in the file or be de-duplicated by whichever layer noticed first, and
/// an empty set would produce a file with a header and no cards — both are
/// unrepresentable now rather than checked for later.
///
/// Order is deliberately not carried: BR-177 orders rows by `created_at ASC`
/// with an `id ASC` tie-break, in the repository, for both scopes. Tap order
/// is not a contract anyone agreed to.
final class CardExportSelectionScope extends CardExportScope {
  /// Normalizes [cardIds] to a distinct set, refusing an empty result with
  /// [CardExportProblem.emptyScope] (BR-174, UC-11 E5).
  factory CardExportSelectionScope(Iterable<String> cardIds) {
    final distinct = <String>{...cardIds};
    if (distinct.isEmpty) {
      throw const ValidationFailure(
        message: 'The export selection is empty.',
        problems: <Enum>{CardExportProblem.emptyScope},
      );
    }

    return CardExportSelectionScope._(Set<String>.unmodifiable(distinct));
  }

  const CardExportSelectionScope._(this.cardIds);

  /// Distinct, unmodifiable, never empty.
  final Set<String> cardIds;
}
