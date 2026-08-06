import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_pill_button.dart';
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
            // **A glyph, not a character.** The label used to open with `⚑`
            // (U+2691) and no font in the bundle carries it — Inter,
            // PlusJakartaSans and NotoSansKR all miss it — so the shipped
            // goldens render a tofu box in both themes. A device with a wider
            // system font might draw a flag, which makes it worse: the mark was
            // correct or not depending on where you looked. The card row beside
            // it already uses `Icons.flag`; this is the same flag.
            icon: Icons.flag,
          ),
        ],
      ),
    );
  }

  /// **`MxPillButton`, not a bare `FilterChip`.** This row was the one place in
  /// the app building a chip by hand, which cost it three things at once: the
  /// flag had to be a character because there was nowhere to put an icon, the
  /// label sat a rung above every other pill in the app, and the shared
  /// component's own fixes — the zeroed `labelPadding`, the composed icon gap —
  /// arrived everywhere except here.
  ///
  /// The control is also more accurate: these four are one-of-four, which is a
  /// `ChoiceChip`'s semantics, not a `FilterChip`'s independent on/off.
  Widget _pill(
    WidgetRef ref,
    String label,
    CardListFilter filter,
    CardListFilter active, {
    IconData? icon,
  }) => MxPillButton(
    label: label,
    icon: icon,
    isSelected: filter == active,
    onPressed: () => _selectFilter(ref, deckId, filter),
  );
}
