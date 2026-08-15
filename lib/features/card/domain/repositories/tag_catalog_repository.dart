import '../failures/tag_catalog_failure.dart';
import '../models/tag_catalog_entry_model.dart';
import '../models/tag_name_model.dart';

/// Contract for managing the tag catalog itself (UC-18, BR-230…BR-238).
///
/// **A second contract beside [CardRepository], not three more methods on it.**
/// The split follows the one `deck/` already makes for templates: one contract
/// per *source of data*, and these are two different sources of the same rows.
/// `CardRepository` reads and writes tags **through a card** — the chips on one
/// card, a tag added to a selection — so every one of its tag methods takes a
/// card id. Nothing here does: the catalog is the tag table seen on its own,
/// and its writes act on every card at once.
///
/// The practical consequence is what makes it worth the file: a test of the
/// catalog fakes three methods, not thirty, and `TagCatalogRepositoryImpl` can
/// prove by its own surface that it never writes a card row (BR-236).
///
/// Same boundary as every other contract here: no Drift row, companion or
/// exception crosses it, and failures arrive as the domain `Failure` hierarchy.
abstract interface class TagCatalogRepository {
  /// Every tag the owner has, with its active-card count, narrowed by
  /// [searchTerm] (BR-230).
  ///
  /// **One read, not a watch plus a client-side filter** (AD-13). The count and
  /// the membership have to describe the same instant: filtering a cached list
  /// in Dart would show a row whose count was read before a write beside a row
  /// whose count was read after it. It also keeps the fold in one place — the
  /// term goes through the same normalization the stored column went through,
  /// which is exactly the pairing `searchPredicate` had to be repaired into.
  ///
  /// A null or blank [searchTerm] is the resting state and matches every tag.
  /// Ordered by folded name then id, so the order and BR-93's identity agree.
  Stream<List<TagCatalogEntry>> watchTagCatalog({String? searchTerm});

  /// Renames a tag, merging it into an existing one if the new folded name is
  /// already taken (BR-233, BR-234).
  ///
  /// [name] is a [TagName], so BR-93's trim, length and control-character rules
  /// have already been applied — the signature says so.
  ///
  /// **The collision test and the write are one transaction, and that is not
  /// negotiable.** Whether this is a rename or a merge depends on what owns the
  /// folded name *at the moment of the write*; deciding it above the repository
  /// puts the check outside the transaction, and two renames racing onto the
  /// same name would then both take the no-collision path and leave two tags
  /// with one folded name — the exact duplicate `idx_tags_owner_folded` exists
  /// to prevent.
  ///
  /// Returns which of the two happened. A tag that has vanished surfaces as a
  /// `NotFoundFailure` carrying [TagCatalogProblem.tagMissing].
  Future<TagRenameOutcome> renameTag({
    required String tagId,
    required TagName name,
  });

  /// Unlinks a tag from every card and deletes the tag — one transaction, and
  /// **no card is touched** (BR-235, BR-236).
  ///
  /// Idempotent in effect for a tag with no links; a tag that is already gone
  /// surfaces as a `NotFoundFailure` carrying [TagCatalogProblem.tagMissing],
  /// because the caller asked to remove something and deserves to hear that the
  /// row it was looking at is stale.
  Future<void> deleteTag(String tagId);
}
