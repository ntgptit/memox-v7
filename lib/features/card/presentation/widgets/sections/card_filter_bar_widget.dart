import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../domain/models/card_list_filter_model.dart';
import '../../controllers/card_list_filter_controller.dart';

/// Selects a filter (D3).
///
/// A free function, not a closure in `build()`: `ref.read` inside a build reads
/// without subscribing and is the bug the guard forbids, so the command is
/// written where the guard can tell it apart — the same shape the list screen's
/// `_growWindow` uses.
void _selectFilter(WidgetRef ref, String deckId, CardListFilter filter) =>
    ref.read(cardListFilterSelectionProvider(deckId).notifier).select(filter);

/// The filter pills over the card list (D3): All, Due, New, ⚑ Flagged.
///
/// A filter narrows the `WHERE`, never the order, so selecting one is a pure read
/// change — the controller swaps the filter and resets the window. Each pill
/// carries its own count from its own statement; the label reads it once loaded,
/// showing the base word until then rather than a flickering zero.
class CardFilterBarWidget extends ConsumerWidget {
  const CardFilterBarWidget({required this.deckId, super.key});

  final String deckId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(cardListFilterSelectionProvider(deckId));
    final all = ref.watch(cardAllCountProvider(deckId)).value;
    final due = ref.watch(cardDueCountProvider(deckId)).value;
    final fresh = ref.watch(cardNewCountProvider(deckId)).value;
    final flagged = ref.watch(cardFlaggedCountProvider(deckId)).value;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      // Trailing gutter inside the scroll: without it the last pill (Flagged)
      // ends flush against the viewport edge, so scrolled to the end it looks
      // clipped rather than finished.
      padding: const EdgeInsets.only(right: AppSpacing.lg),
      child: Row(
        children: <Widget>[
          _pill(
            ref,
            context.l10n.cardFilterAll(all ?? 0),
            CardListFilter.all,
            active,
          ),
          const SizedBox(width: AppSpacing.sm),
          _pill(
            ref,
            context.l10n.cardFilterDue(due ?? 0),
            CardListFilter.due,
            active,
          ),
          const SizedBox(width: AppSpacing.sm),
          _pill(
            ref,
            context.l10n.cardFilterNew(fresh ?? 0),
            CardListFilter.isNew,
            active,
          ),
          const SizedBox(width: AppSpacing.sm),
          _pill(
            ref,
            context.l10n.cardFilterFlagged(flagged ?? 0),
            CardListFilter.flagged,
            active,
          ),
        ],
      ),
    );
  }

  Widget _pill(
    WidgetRef ref,
    String label,
    CardListFilter filter,
    CardListFilter active,
  ) => FilterChip(
    label: Text(label),
    selected: filter == active,
    onSelected: (_) => _selectFilter(ref, deckId, filter),
  );
}
