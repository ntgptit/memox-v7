import 'package:flutter/material.dart';

import '../../../../../core/theme/app_icon_size.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../domain/models/study_home_deck_model.dart';

/// What is waiting in one deck: `2 overdue` `5 due today` `12 new` (BR-201).
///
/// **Three metrics, always, zeroes included.** An absent metric is ambiguous in
/// exactly the way this line exists to prevent — "no overdue count" could mean
/// none overdue or could mean the screen does not track it, and a reader should
/// not have to know the convention. `0 overdue` `0 due today` `12 new` says
/// which, and it is also what makes the ordering legible: a row that dropped its
/// zeroes would look like it had fewer facts than the row above it rather than
/// smaller numbers.
///
/// **Colour is never the only signal.** Each metric carries a glyph *and* a word
/// as well as its ink, so the three read apart in greyscale, at any contrast
/// setting, and to anyone who does not perceive the hues. Overdue takes
/// `danger` — BR-161 settled that late is a red signal and distinct from due
/// today — due today takes the time-pressure ink the deck list already uses, and
/// new takes `info`. A zero rests on the neutral variant in every case: nothing
/// is urgent about none.
///
/// **One semantics node, not three.** A screen reader should hear the row's
/// workload as one phrase; three separate numbers with no relation between them
/// is what a badge soup sounds like.
class StudyHomeWorkloadItemWidget extends StatelessWidget {
  const StudyHomeWorkloadItemWidget({required this.deck, super.key});

  final StudyHomeDeckModel deck;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final semantic = context.semanticColors;
    final quiet = context.colors.onSurfaceVariant;

    return Semantics(
      // `container: true`, or the label has no node of its own to sit on and is
      // absorbed into whatever the card happens to merge — which is how this
      // first rendered as the deck name and nothing else.
      container: true,
      label: l10n.studyHomeWorkloadSemanticLabel(
        deck.overdueCount,
        deck.dueTodayCount,
        deck.newCount,
      ),
      child: ExcludeSemantics(
        child: Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            // **The app's own glyph for each fact, filled only when the count
            // is non-zero.** The first version picked three fresh icons —
            // `history`, `today`, `auto_awesome` — each of which appeared
            // exactly once in `lib/`, while the deck list and Progress already
            // had a glyph for the same three facts. One tab across, "new" was
            // an outlined sparkle and here a filled one; "overdue" was a
            // crossed-out calendar there and a clock here. Parity item E5 says
            // outlined at rest and filled when active, and a glyph filled at
            // zero breaks it silently — the gate reads the checklist's verdict
            // word, not the code.
            _Metric(
              // A day that has already passed, not a fault: `event_busy` is what
              // `deck_status_icon_widget.dart` uses for the same backlog.
              icon: deck.overdueCount > 0
                  ? Icons.event_busy
                  : Icons.event_busy_outlined,
              label: l10n.studyHomeOverdueLabel(deck.overdueCount),
              color: deck.overdueCount > 0 ? semantic.danger : quiet,
              isActive: deck.overdueCount > 0,
            ),
            _Metric(
              icon: deck.dueTodayCount > 0 ? Icons.event : Icons.event_outlined,
              label: l10n.studyHomeDueTodayLabel(deck.dueTodayCount),
              color: deck.dueTodayCount > 0
                  ? semantic.onStreakContainer
                  : quiet,
              isActive: deck.dueTodayCount > 0,
            ),
            _Metric(
              icon: deck.newCount > 0
                  ? Icons.auto_awesome
                  : Icons.auto_awesome_outlined,
              label: l10n.studyHomeNewLabel(deck.newCount),
              color: deck.newCount > 0 ? semantic.info : quiet,
              isActive: deck.newCount > 0,
            ),
          ],
        ),
      ),
    );
  }
}

/// One count, its glyph and its word — an atomic group.
///
/// A `Row` inside the `Wrap` rather than three loose children, so a narrow
/// screen or a large text scale breaks *between* metrics and can never strand a
/// number from the word that says what it counts.
class _Metric extends StatelessWidget {
  const _Metric({
    required this.icon,
    required this.label,
    required this.color,
    required this.isActive,
  });

  final IconData icon;
  final String label;
  final Color color;

  /// Whether this count is non-zero. Drives weight as well as ink, so the
  /// emphasis survives greyscale.
  final bool isActive;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      // `sm` — the step `AppIconSize` calls "inline with body text", which is
      // what this glyph is: it sits on a `bodySmall` baseline and must not
      // outweigh the number beside it.
      Icon(icon, size: AppIconSize.sm, color: color),
      const SizedBox(width: AppSpacing.xs),
      Flexible(
        child: Text(
          label,
          style: context.texts.bodySmall?.copyWith(
            color: color,
            fontWeight: isActive ? FontWeight.w600 : null,
          ),
          // **Two lines, because a truncated count is not a shortened count —
          // it is a wrong one.** `1024 overdue` clipped to `10…` reads as ten,
          // and `overdueCount` aggregates a whole subtree, so four digits is an
          // ordinary number for somebody who has been away. One line plus
          // ellipsis was the widget's quiet default and it fails silently: the
          // `Wrap`'s `runSpacing` already spaces a second line, so wrapping
          // costs the row nothing it was not already prepared for.
          maxLines: 2,
        ),
      ),
    ],
  );
}
