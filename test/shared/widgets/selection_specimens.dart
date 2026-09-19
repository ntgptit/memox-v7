import 'package:flutter/material.dart';
import 'package:memox/core/theme/extensions/theme_context_extension.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/shared/widgets/mx_badge.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_filter_chip.dart';
import 'package:memox/shared/widgets/mx_pill_button.dart';

/// The selection-control specimens — pills and the quiet badge — split from
/// `golden_specimens.dart` at the 400-line guard (M100.36 Phase 5).

/// The pill group, over the hint it sits beside on the deck list.
///
/// **The reference line is the specimen, not decoration.** `MxPillButton` had no
/// golden at all until the weight it borrowed from the button was measured off a
/// device render — and a golden holding only pills would have recorded 600 as
/// correct, because a weight has nothing to be wrong against on its own. Both
/// rungs here are 14px, so the picture answers one question: does the control
/// out-shout the text it belongs to?
///
/// Selected and unselected together, because the label colour swaps with the
/// fill and only one of the two states would otherwise be pinned.
class PillGroupSpecimen extends StatelessWidget {
  const PillGroupSpecimen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Search your whole library',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const Wrap(
              spacing: AppSpacing.sm,
              children: <Widget>[
                MxPillButton(
                  label: 'All decks',
                  icon: Icons.filter_list,
                  isSelected: false,
                  onPressed: _noop,
                ),
                MxPillButton(
                  label: 'Due only',
                  icon: Icons.filter_list,
                  isSelected: true,
                  onPressed: _noop,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static void _noop() {}
}

/// Every pill state on the page, and the pair on a card.
///
/// **This is the picture #434 P1-2 and P1-3 could have been read from**: the
/// disabled pair share one grey (M3's own), the selected pill carries a tick
/// in a slot the unselected one also lays out — so the two rows line up glyph
/// for glyph — and none of them casts a shadow. The card row exists because
/// `surfaceContainerLow` on `surfaceContainerLow` is where the hairline is the
/// only boundary.
class PillStatesSpecimen extends StatelessWidget {
  const PillStatesSpecimen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: AppSpacing.md,
          children: <Widget>[
            Row(
              spacing: AppSpacing.sm,
              children: <Widget>[
                MxPillButton(label: 'All', isSelected: false, onPressed: _noop),
                MxPillButton(label: 'Due', isSelected: true, onPressed: _noop),
                MxPillButton(
                  label: 'New',
                  icon: Icons.circle_outlined,
                  isSelected: false,
                  onPressed: _noop,
                ),
              ],
            ),
            Row(
              spacing: AppSpacing.sm,
              children: <Widget>[
                MxPillButton(label: 'All', isSelected: false, onPressed: null),
                MxPillButton(label: 'Due', isSelected: true, onPressed: null),
                MxPillButton(
                  label: 'New',
                  icon: Icons.circle_outlined,
                  isSelected: false,
                  onPressed: null,
                ),
              ],
            ),
            MxCard.flat(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: Row(
                  spacing: AppSpacing.sm,
                  children: <Widget>[
                    MxPillButton(
                      label: 'Newest first',
                      isSelected: true,
                      onPressed: _noop,
                    ),
                    MxPillButton(
                      label: 'Random',
                      isSelected: false,
                      onPressed: _noop,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void _noop() {}
}

/// The filter chip group, over the hint it sits beside.
///
/// **Counts are the specimen**: one chip is selected and every chip but one
/// carries a count, so the picture pins the trailing numeral's weight and
/// dimming in both states, and the chip without one shows that a missing count
/// adds no gap. The reference line is the same as the pill's — a control must
/// not out-shout the text it belongs to.
class FilterChipGroupSpecimen extends StatelessWidget {
  const FilterChipGroupSpecimen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Filter your library',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const Wrap(
              spacing: AppSpacing.sm,
              children: <Widget>[
                MxFilterChip(
                  label: 'All',
                  count: 128,
                  isSelected: true,
                  onPressed: _noop,
                ),
                MxFilterChip(
                  label: 'Due',
                  count: 12,
                  isSelected: false,
                  onPressed: _noop,
                ),
                MxFilterChip(
                  label: 'New',
                  count: 0,
                  isSelected: false,
                  onPressed: _noop,
                ),
                MxFilterChip(
                  label: 'Flagged',
                  isSelected: false,
                  onPressed: _noop,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static void _noop() {}
}

/// Every filter chip state on the page: unselected, selected and disabled, with
/// and without a leading glyph and a count.
///
/// The unselected row is the only place `border-ghost` is drawn, so it is the
/// row that answers whether the hairline is visible on the page in each theme.
class FilterChipStatesSpecimen extends StatelessWidget {
  const FilterChipStatesSpecimen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: AppSpacing.md,
          children: <Widget>[
            Row(
              spacing: AppSpacing.sm,
              children: <Widget>[
                MxFilterChip(label: 'All', isSelected: false, onPressed: _noop),
                MxFilterChip(
                  label: 'Due',
                  count: 12,
                  isSelected: true,
                  onPressed: _noop,
                ),
                MxFilterChip(
                  label: 'New',
                  count: 3,
                  icon: Icons.circle_outlined,
                  isSelected: false,
                  onPressed: _noop,
                ),
              ],
            ),
            Row(
              spacing: AppSpacing.sm,
              children: <Widget>[
                MxFilterChip(label: 'All', isSelected: false, onPressed: null),
                MxFilterChip(
                  label: 'Due',
                  count: 12,
                  isSelected: true,
                  onPressed: null,
                ),
                MxFilterChip(
                  label: 'New',
                  count: 3,
                  icon: Icons.circle_outlined,
                  isSelected: false,
                  onPressed: null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static void _noop() {}
}

/// The quiet badge beside the words it annotates, on the page and on a card.
class BadgeSpecimen extends StatelessWidget {
  const BadgeSpecimen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: AppSpacing.md,
          children: <Widget>[
            Row(
              spacing: AppSpacing.sm,
              children: <Widget>[
                Text('quesadilla', style: context.texts.titleMedium),
                const MxBadge(label: 'Due tomorrow'),
              ],
            ),
            const MxCard.flat(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: Wrap(
                  spacing: AppSpacing.xs,
                  children: <Widget>[
                    MxBadge(label: 'food'),
                    MxBadge(label: 'chapter 3'),
                    MxBadge(label: 'nouns'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
