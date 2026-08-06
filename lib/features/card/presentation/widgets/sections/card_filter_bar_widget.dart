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

    // **Spread across the width when the four fit, scrolled when they do not.**
    // A plain `Row` inside a horizontal scroll takes its intrinsic width, so the
    // pills bunched at the left and left a gap at the right that read as a
    // missing fifth pill. `spaceBetween` alone cannot fix that — inside a scroll
    // view the row has unbounded width, so there is no free space to distribute.
    //
    // Giving the row a `minWidth` of the viewport is what creates it: when the
    // pills are narrower than the strip the row stretches to fill it and the
    // gaps open evenly; when they are wider — a long locale, a large text scale
    // — the row keeps its intrinsic width and scrolls, exactly as before.
    //
    // **No trailing gutter any more.** It existed so the last pill would not sit
    // flush against the viewport edge when scrolled to the end. It also stopped
    // the row reaching the right-hand gutter when everything fits, which is the
    // whole point here; the subheader's own gutter already keeps the pill off
    // the screen edge.
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: constraints.maxWidth),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            // **Both, and they do different jobs.** `spacing` is the floor —
            // when the pills are wider than the strip and the row scrolls,
            // `spaceBetween` has no free space to hand out and the pills would
            // otherwise touch. `spaceBetween` then distributes whatever is left
            // over on a screen where they do fit. The `SizedBox` separators this
            // replaces could not do the second job: alignment would have spaced
            // the gaps as children too, so the pills and the spacers would have
            // drifted apart from each other.
            spacing: AppSpacing.sm,
            children: <Widget>[
              _pill(
                context,
                ref,
                context.l10n.cardFilterAll,
                CardListFilter.all,
                active,
                count: all,
                // The same glyph the deck's empty state uses for "cards".
                icon: Icons.style_outlined,
              ),
              _pill(
                context,
                ref,
                context.l10n.cardFilterDue,
                CardListFilter.due,
                active,
                count: due,
                // The deck row's due state already means "when" with this clock
                // (`deck_due_state_widget.dart`); a second glyph for the same idea
                // would be a second vocabulary to learn.
                icon: Icons.schedule,
              ),
              _pill(
                context,
                ref,
                context.l10n.cardFilterNew,
                CardListFilter.isNew,
                active,
                count: fresh,
                // An open circle, because that is what "not started" looks like
                // beside the filled state dot each row carries. `fiber_new` was the
                // obvious pick and is wrong: it draws the word NEW, directly beside
                // the word New.
                icon: Icons.circle_outlined,
              ),
              _pill(
                context,
                ref,
                context.l10n.cardFilterFlagged,
                CardListFilter.flagged,
                active,
                count: flagged,
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
        ),
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
    BuildContext context,
    WidgetRef ref,
    String label,
    CardListFilter filter,
    CardListFilter active, {
    required IconData icon,
    int? count,
  }) => MxPillButton(
    label: label,
    icon: icon,
    isSelected: filter == active,
    onPressed: () => _selectFilter(ref, deckId, filter),
    // **The count left the label, not the pill.** The row stopped fitting once
    // every pill carried an icon, and the visible number was the cheapest thing
    // to give up: the progress panel directly below repeats All, Due and New.
    // Nothing repeats Flagged, and a reader has none of the width problem that
    // caused this — so the number is still announced, on every pill.
    semanticLabel: count == null
        ? null
        : context.l10n.cardFilterSemantics(label, count),
  );
}
