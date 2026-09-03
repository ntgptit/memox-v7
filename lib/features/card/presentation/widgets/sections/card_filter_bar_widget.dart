import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/foundations/app_spacing.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_action_button.dart';
import '../../../../../shared/widgets/mx_pill_button.dart';
import '../../../domain/models/card_list_filter_model.dart';
import '../../controllers/card_list_filter_controller.dart';
import '../../controllers/card_list_tag_filter_controller.dart';
import '../overlays/card_tag_filter_sheet_widget.dart';

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
class CardFilterBarWidget extends ConsumerStatefulWidget {
  const CardFilterBarWidget({required this.deckId, super.key});

  final String deckId;

  @override
  ConsumerState<CardFilterBarWidget> createState() =>
      _CardFilterBarWidgetState();
}

class _CardFilterBarWidgetState extends ConsumerState<CardFilterBarWidget> {
  String get deckId => widget.deckId;

  @override
  Widget build(BuildContext context) {
    final active = ref.watch(cardListFilterSelectionProvider(deckId));
    final all = ref.watch(cardAllCountProvider(deckId)).value;
    final due = ref.watch(cardDueCountProvider(deckId)).value;
    final fresh = ref.watch(cardNewCountProvider(deckId)).value;
    final flagged = ref.watch(cardFlaggedCountProvider(deckId)).value;

    // **The four state pills scroll; the Tags pill does not.**
    //
    // It was inside the scroller and that was a real defect, not a nicety: the
    // four pills already measured 341dp of a 361dp viewport at 393dp, so a
    // fifth put 66% of `Tags` — including every pixel of the word — past the
    // right edge, at *every* supported width. The one entry point to multi-tag
    // filtering was invisible at rest, and so was the count that is the whole
    // reason the pill carries one (M4.14 T3, T4, W1).
    //
    // Pinning it keeps it on the same bar, which T3 requires, and keeps it
    // visible without a second strip eating height at 320dp. The state pills
    // still scroll under their own `Expanded` box, so nothing overlaps.
    // **The gap belongs to the outer `Row`, not to the scroller.**
    // `SingleChildScrollView.padding` pads the *content*, so it is part of the
    // scrollable extent and only appears once the user has scrolled to the
    // end. This bar overflows at every supported width, so at rest the gap was
    // never drawn: measured 0.33dp between the clipped `Flagged` and the
    // pinned pill, where W1 asks for `AppSpacing.sm`. Two pills flush against
    // each other read as one broken control rather than as one scrolling past
    // another.
    return Row(
      spacing: AppSpacing.sm,
      children: <Widget>[
        Expanded(
          // **The group introduces itself** (M100.36 11F). Without a container
          // a screen reader met four loose siblings — "All, selected, button /
          // Due, button / …" — with no statement of what was being chosen
          // (#434 P2-8). The children keep their own selected state.
          child: Semantics(
            container: true,
            label: context.l10n.cardFilterGroupLabel,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
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
                    // The deck row's due state already means "when" with this
                    // clock (`deck_workload_line_widget.dart`); a second glyph
                    // for the same idea would be a second vocabulary to learn.
                    icon: Icons.schedule,
                  ),
                  _pill(
                    context,
                    ref,
                    context.l10n.cardFilterNew,
                    CardListFilter.isNew,
                    active,
                    count: fresh,
                    // An open circle, because that is what "not started" looks
                    // like beside the filled state dot each row carries.
                    // `fiber_new` was the obvious pick and is wrong: it draws
                    // the word NEW, directly beside the word New.
                    icon: Icons.circle_outlined,
                  ),
                  _pill(
                    context,
                    ref,
                    context.l10n.cardFilterFlagged,
                    CardListFilter.flagged,
                    active,
                    count: flagged,
                    // **A glyph, not a character.** The label used to open with
                    // `⚑` (U+2691) and no font in the bundle carries it —
                    // Inter, PlusJakartaSans and NotoSansKR all miss it — so
                    // the shipped goldens rendered a tofu box in both themes.
                    // The card row beside it already uses `Icons.flag`; this
                    // is the same flag.
                    icon: Icons.flag,
                  ),
                ],
              ),
            ),
          ),
        ),
        _TagsEntry(deckId: deckId),
      ],
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

/// The multi-tag filter's entry, last in the row (UC-18, M4.14 T3, T4).
///
/// **A fifth control on the existing bar, not a second bar.** This is where a
/// user already looks to narrow the list; another strip under it costs height
/// at 320dp and teaches a second vocabulary for one idea.
///
/// **A command, not a pill** (M100.36 4N, #434 P1-1). It opens a sheet; the
/// four pills beside it are one-of-four. It used to be an `MxPillButton` with
/// `isSelected: tags.isActive`, which put an independent toggle that opens a
/// dialog into an exclusive row wearing the same semantics node as its
/// neighbours — a screen reader met five identical controls. It is the app's
/// compact secondary action now: same 48 target, its own shape, `button`
/// semantics and no selected state. Whether a tag filter is *active* is said
/// by its content — the count in the label and in the spoken name — not by a
/// selection the row does not have.
class _TagsEntry extends ConsumerWidget {
  const _TagsEntry({required this.deckId});

  final String deckId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tags = ref.watch(cardListTagFilterProvider(deckId));

    return MxActionButton(
      label: tags.isActive
          ? context.l10n.tagFilterPillCount(tags.length)
          : context.l10n.tagFilterPillLabel,
      // The same glyph the catalog and its empty states use, so the two
      // surfaces read as one feature.
      icon: Icons.sell_outlined,
      variant: MxActionButtonVariant.secondary,
      size: MxActionButtonSize.compact,
      onPressed: () => showCardTagFilterSheet(context, deckId),
      semanticLabel: tags.isActive
          ? context.l10n.tagFilterPillSemantics(tags.length)
          : null,
    );
  }
}
