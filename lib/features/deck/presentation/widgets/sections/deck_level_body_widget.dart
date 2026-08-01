import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/navigation/route_names.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_async_view.dart';
import '../../../domain/models/deck_list_snapshot_model.dart';
import '../../../domain/models/deck_search_result_model.dart';
import '../../controllers/deck_search_controller.dart';
import 'deck_level_error_widget.dart';
import 'deck_search_results_widget.dart';

/// Space under the last result. The same value the list beside it uses — see
/// `deck_list_screen.dart`.
///
/// It was `56 + lg + xl` here, to clear a floating action. M4.10ag deleted the
/// floating action and corrected the list's copy of this constant to `lg`; this
/// one was missed, so a search left 112px of empty space under its last row
/// while the list below it left 24. Two constants of the same name in one
/// feature is how that survived being read.
const double _kListBottomInset = AppSpacing.lg;

/// Either the level, or what a search of it found.
///
/// **Search replaces the level rather than filtering it in place.** The results
/// come from the whole subtree, so leaving the toolbar and the summary above
/// them would be chrome describing a list that is no longer on screen.
class DeckLevelBodyWidget extends ConsumerWidget {
  const DeckLevelBodyWidget({
    required this.snapshot,
    required this.buildLevel,
    super.key,
  });

  final DeckListSnapshot snapshot;

  /// The level's own body, built lazily so it costs nothing while searching.
  final Widget Function() buildLevel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final parentId = snapshot.parent?.id;
    final query = ref.watch(deckSearchQueryProvider(parentId));
    if (query.trim().isEmpty) return buildLevel();

    return MxAsyncView<List<DeckSearchResult>>(
      value: ref.watch(deckSearchResultsProvider(parentId)),
      loadingLabel: context.l10n.decksLoadingLabel,
      data: (results) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          _kListBottomInset,
        ),
        child: DeckSearchResultsWidget(
          results: results,
          query: query.trim(),
          scopeName:
              snapshot.parent?.name ?? context.l10n.deckSearchScopeLibrary,
          onOpen: (result) {
            ref.read(deckSearchQueryProvider(parentId).notifier).update('');
            context.goNamed(
              RouteNames.deckDetail,
              pathParameters: <String, String>{
                RoutePathParams.deckId: result.deck.id,
              },
            );
          },
          onClear: () =>
              ref.read(deckSearchQueryProvider(parentId).notifier).update(''),
        ),
      ),
      error: (error, stackTrace) => DeckLevelErrorWidget(
        error: error,
        title: snapshot.parent?.name,
        isRootLevel: snapshot.parent == null,
        onRetry: () => ref.invalidate(deckSearchResultsProvider(parentId)),
      ),
    );
  }
}
