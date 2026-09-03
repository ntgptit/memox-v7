import 'package:flutter/material.dart';
import 'package:memox/core/theme/extensions/theme_context_extension.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/shared/widgets/mx_badge.dart';
import 'package:memox/shared/widgets/mx_card.dart';
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
