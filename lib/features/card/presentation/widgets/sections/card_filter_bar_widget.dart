import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_pill_button.dart';
import '../../../domain/models/card_list_filter_model.dart';
import '../../controllers/card_list_filter_controller.dart';

/// The narrowest a filter pill may be, so four of unequal width read as one
/// control rather than four scattered ones. A multiple of 4, like every other
/// size in the app.
const double _minPillWidth = 76;

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

    // **A plain scrolling row, and the two things that are not here matter.**
    //
    // There is no `spaceBetween` and no `minWidth` on the row. Both were tried,
    // together, to stop the pills bunching at the left — and they work by
    // pushing the leftover width into the *gaps*, which is the wrong place:
    // four controls of one group read as four separate ones the further apart
    // they sit. The width floor on each pill (see `_pill`) spends that same
    // slack on the controls instead, and what is left over is 10 of 358 — under
    // 3% of the strip, at the end where nothing else sits.
    //
    // **No trailing gutter either.** It existed so the last pill would not sit
    // flush against the viewport edge when scrolled to the end; the subheader's
    // own gutter already keeps it off the screen edge.
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        // **`spacing` alone now — no `spaceBetween`.** Distributing the
        // slack was tried and it goes to the wrong place: whatever the row
        // has left over lands *between* the pills, and four controls of one
        // group read as separate the further apart they sit. With the width
        // floor below carrying most of that slack into the pills
        // themselves, what remains is 10 of 358 — under 3% of the strip,
        // invisible at the right-hand end — and the gap stays the 8 it is
        // everywhere else in the app.
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
  }) => ConstrainedBox(
    // **A floor per pill, so the space goes into the pills rather than between
    // them.** With four pills of 62 to 96 on a 358-wide strip, `spaceBetween`
    // had 56 to hand out and put 19 into each of the three gaps — pills that
    // belong to one control ended up nearly as far apart as they were wide.
    // Growing the narrow ones to a shared floor spends the same space on the
    // controls themselves and leaves the gaps near their 8 resting value.
    //
    // **The strip is 358 at a 390 screen, not 374.** The subheader gutters both
    // sides, so it is `390 - 2 * 16`. Sizing this against 374 was tried and put
    // the row 14 over, which shows up as the last pill clipped rather than as
    // anything failing. Flagged wants 96 of that, so the other three may have
    // `(358 - 96 - 24) / 3 = 79.4` — and 76 is the multiple of 4 below it.
    //
    // A floor, never a fixed width. A longer locale or a large text scale takes
    // a pill past it, the row exceeds the strip, and it scrolls — which is what
    // the `ConstrainedBox` around the row already allows for.
    constraints: const BoxConstraints(minWidth: _minPillWidth),
    child: MxPillButton(
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
    ),
  );
}
