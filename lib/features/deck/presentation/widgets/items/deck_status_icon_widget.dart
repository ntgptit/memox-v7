import 'package:flutter/material.dart';

import '../../../../../core/theme/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../domain/models/deck_schedule_status_model.dart';
import 'deck_icon_area_widget.dart';

/// The deck's schedule at a glance: one large icon, three states (BR-161).
///
/// **The well answers "when", not "what" or "how far".** The identity glyphs
/// and the completion check both left this square during the status pass:
/// what a deck is made of is on the metadata line in words, completion is the
/// progress bar's whole job, and the one question a scanning eye actually
/// asks the column is whether anything is waiting. Shape and fill carry the
/// state alongside colour — outlined calendar, filled calendar, missed
/// calendar — so the three read apart in grayscale.
///
/// Overdue used to add a `+7d` day badge on the well's corner; the badge is
/// gone (owner mockup, 2026-08-20) — how *big* the backlog is matters more
/// than how old, and the workload line now carries the overdue count in
/// words. The day count survives here in the screen-reader sentence, which
/// always spoke in days (BR-105) rather than the shorthand.
///
/// **Takes the classified state, not the summary.** The status is computed
/// once by `deckScheduleStatusOf` — through `DeckSummary.scheduleStatus` for a
/// tile, through the level fold for the summary panel — and this widget only
/// dresses it. The two counts ride along for the screen-reader sentence,
/// which names the cards and the days rather than the shorthand.
class DeckStatusIconWidget extends StatelessWidget {
  const DeckStatusIconWidget({
    required this.status,
    required this.dueCardCount,
    required this.overdueDayCount,
    super.key,
  });

  final DeckScheduleStatus status;
  final int dueCardCount;
  final int overdueDayCount;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;

    final icon = switch (status) {
      DeckScheduleStatus.notDue => Icons.event_outlined,
      DeckScheduleStatus.dueToday => Icons.event,
      DeckScheduleStatus.overdue => Icons.event_busy,
    };
    final tint = switch (status) {
      DeckScheduleStatus.notDue => context.colors.onSurfaceVariant,
      // The streak pair, not the brand container (M99.14): the hero and the
      // workload words already speak due-today in the amber time-pressure
      // role, and a purple well beside a yellow "12 Due" read as two
      // different states. One state, one colour, everywhere it appears.
      DeckScheduleStatus.dueToday => semantic.onStreakContainer,
      // Red on purpose (owner decision, 2026-08-11, recorded on BR-161):
      // missed is a red-letter state, and only missed. The M3 error-container
      // pair carries its own contrast guarantee in both themes.
      DeckScheduleStatus.overdue => context.colors.onErrorContainer,
    };
    final well = switch (status) {
      DeckScheduleStatus.notDue => semantic.surfaceMuted,
      DeckScheduleStatus.dueToday => semantic.streakContainer,
      DeckScheduleStatus.overdue => context.colors.errorContainer,
    };

    final area = DeckIconArea(icon: icon, tint: tint, wellColor: well);

    if (status != DeckScheduleStatus.overdue) return area;

    // One sentence for the screen reader: the well itself is visual-only,
    // and the day count has no visual carrier anymore — this label is where
    // "how long missed" lives now.
    return Semantics(
      // Its own node: inside the card's tap target the label would otherwise
      // merge into the row's combined description and become unfindable as a
      // distinct announcement.
      container: true,
      label: context.l10n.deckOverdueSemanticLabel(
        dueCardCount,
        overdueDayCount,
      ),
      child: ExcludeSemantics(child: area),
    );
  }
}
