import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/state/retry_policy.dart';
import '../../domain/models/tag_catalog_entry_model.dart';
import '../providers/tag_use_case_provider.dart';

part 'tag_catalog_controller.g.dart';

/// What the user has typed into the catalog's search field (UC-12, BR-182).
///
/// An input-state notifier, exactly like `CardListSearchQuery` — the UI owns the
/// value and the read is parameterized by it.
///
/// **It resets nothing, and that is the difference from the card list's.** The
/// card list is a growing window, so narrowing it leaves a window opened over a
/// set that no longer exists; the catalog is read whole, so there is no window
/// to reset. Not a family either: there is one catalog, not one per deck
/// (BR-182).
@riverpod
class TagCatalogSearchQuery extends _$TagCatalogSearchQuery {
  @override
  String build() => '';

  void update(String query) {
    if (query == state) return;
    state = query;
  }
}

/// Every tag with its card count, narrowed by the live search term (BR-182).
///
/// **One read that takes the term, not a watch the widget filters.** The count
/// and the membership have to describe the same instant, and the fold has to be
/// the stored column's — both of which are only true if the statement does the
/// narrowing. See `TagCatalogRepository.watchTagCatalog`.
///
/// `noAutomaticRetry` for the reason every async read here carries it: a retry
/// sits on `AsyncLoading`, so a failed local read would spin instead of reaching
/// the error state the screen draws (W3 face 5).
@Riverpod(retry: noAutomaticRetry)
Stream<List<TagCatalogEntry>> tagCatalog(Ref ref) => ref.watch(
  watchTagCatalogUseCaseProvider,
)(searchTerm: ref.watch(tagCatalogSearchQueryProvider));

/// The catalog with **no** search applied — every tag the owner has.
///
/// Its own subscription rather than a derived value, because the two answer
/// different questions and one of them must not move when the other does. The
/// filter overlay and the `Tags` pill both need the full list: the overlay
/// renders every tag to choose from, and the pill has to know which selected ids
/// still exist so a merged-away tag stops narrowing the list forever
/// (`TagFilter.retaining`). Reading the searched catalog for that would make the
/// applied filter depend on what someone last typed on a different screen.
@Riverpod(retry: noAutomaticRetry)
Stream<List<TagCatalogEntry>> allTags(Ref ref) =>
    ref.watch(watchTagCatalogUseCaseProvider)();
