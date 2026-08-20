import 'package:flutter/material.dart';

import '../../../../../core/theme/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../domain/models/deck_content_type_model.dart';
import '../../../domain/models/deck_schedule_status_model.dart';
import 'deck_icon_area_widget.dart';

/// The deck's identity at a glance: one large icon, neutral in every schedule
/// state.
///
/// **The well answers "what", and the chips answer "when"** (owner review,
/// 2026-08-20). It used to carry the schedule: an outlined calendar at rest, a
/// filled one for today, a missed one in the error pair for a backlog. That
/// was the only carrier of urgency when the counts were plain words; now the
/// workload line states `8 overdue` on its own red ground, and a red square
/// beside a red chip said the same thing twice — with a glyph that reads as
/// *cancelled*, not as *late*. This amends BR-161's icon-pair sentence; the
/// day count still reaches a screen reader through [overdueDayCount].
///
/// **Still takes the classified state**, because the announcement depends on
/// it: a deck with a backlog gets a sentence naming cards and days, and a deck
/// without one gets none.
class DeckStatusIconWidget extends StatelessWidget {
  const DeckStatusIconWidget({
    required this.status,
    required this.contentType,
    required this.dueCardCount,
    required this.overdueDayCount,
    super.key,
  });

  final DeckScheduleStatus status;

  /// Which glyph the well shows: a stack of cards for a deck that holds them,
  /// a folder for one that holds decks. `unset` is a folder — it is what the
  /// deck is until its first child decides (BR-63).
  final DeckContentType contentType;

  final int dueCardCount;
  final int overdueDayCount;

  @override
  Widget build(BuildContext context) {
    final area = DeckIconArea(
      icon: contentType == DeckContentType.card
          ? Icons.style_outlined
          : Icons.folder_outlined,
      tint: context.colors.onPrimaryContainer,
    );

    if (status != DeckScheduleStatus.overdue) return area;

    // One sentence for the screen reader: the well is visual-only, and the day
    // count has no visual carrier anymore — this label is where "how long
    // missed" lives now.
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
