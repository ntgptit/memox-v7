import 'package:flutter/material.dart';

import '../../../../../core/theme/app_icon_size.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_empty_state.dart';
import '../../../domain/models/deck_content_type_model.dart';
import '../../../domain/models/deck_search_result_model.dart';

/// What a search found, or the fact that it found nothing.
///
/// A result row leads with **where the deck is**, not what it is called. Three
/// sub-decks in one library can all be "Nouns"; a list of bare names is a list
/// of identical rows the user has to open one at a time to tell apart.
class DeckSearchResultsWidget extends StatelessWidget {
  const DeckSearchResultsWidget({
    required this.results,
    required this.query,
    required this.scopeName,
    required this.onOpen,
    required this.onClear,
    super.key,
  });

  final List<DeckSearchResult> results;
  final String query;

  /// Already-localized: the deck's name, or the word for the whole library.
  final String scopeName;

  final ValueChanged<DeckSearchResult> onOpen;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) {
      return MxEmptyState(
        icon: Icons.search_off,
        title: context.l10n.deckSearchEmptyTitle(query),
        // Says what was searched, so an empty result is distinguishable from a
        // search that looked somewhere the user did not mean.
        message: context.l10n.deckSearchEmptyMessage(scopeName),
        actionLabel: context.l10n.deckSearchClearLabel,
        onAction: onClear,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Text(
            context.l10n.deckSearchMatchCountLabel(results.length, scopeName),
            style: context.texts.labelMedium?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ),
        for (final DeckSearchResult result in results) ...<Widget>[
          _DeckSearchRow(result: result, onOpen: () => onOpen(result)),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}

/// One match: its path, its name, and what kind of deck it is.
class _DeckSearchRow extends StatelessWidget {
  const _DeckSearchRow({required this.result, required this.onOpen});

  final DeckSearchResult result;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final holdsCards = result.deck.contentType == DeckContentType.card;

    return Semantics(
      button: true,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onOpen,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: context.colors.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: context.semanticColors.borderSubtle),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Icon(
                    holdsCards ? Icons.style_outlined : Icons.folder_outlined,
                    size: AppIconSize.sm,
                    color: context.colors.onSurfaceVariant,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        // Above the name, not after it: the path is what the eye
                        // needs first when two rows share a name.
                        if (result.ancestorNames.isNotEmpty)
                          Text(
                            result.ancestorNames.join(' › '),
                            style: context.texts.labelSmall?.copyWith(
                              color: context.colors.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        Text(
                          result.deck.name,
                          style: context.texts.bodyLarge,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  ExcludeSemantics(
                    child: Icon(
                      Icons.north_east,
                      size: AppIconSize.sm,
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
