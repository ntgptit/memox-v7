import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/navigation/route_names.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_action_button.dart';

/// So a one-word verb is not narrower than the chips above it. Deck-local, so
/// it constrains from outside rather than living in the shared button: the
/// minimum a verb needs is decided by what it sits next to.
///
/// **A layout constraint, not a second `buttonMinWidth`** (M100.36, #432
/// P2-4). The shared button keeps its 64 floor untouched; this is the deck
/// tile deciding how much of its own row the verb may take, the same way a
/// `ConstrainedBox` around any child would. 80 is on the 4px grid and off
/// every token ladder because it answers a question no ladder asks — "as
/// wide as the gauges beside it" — and `deck_tile_geometry_test.dart` pins
/// it as a floor rather than a value, so a wider label still wins.
const double _kButtonMinWidth = 80;

/// Start studying what is due in one deck.
///
/// **It opens the deck's study entry, at last.** It stood here since M4 showing
/// a "not built yet" snackbar — the project refuses enabled-looking controls
/// that go nowhere, and a button that answers honestly beat one that swallowed
/// the tap. M5.15 needed the path to exist to test it, and it was the last link
/// missing between a deck and a session.
///
/// It navigates by **name**, and to a route nested under the deck: Back returns
/// to the deck the session started from rather than to whatever the Study tab
/// last held.
///
/// **Primary again (owner mockup, 2026-08-20), reversing the tonal revision
/// of 2026-08-05.** The full history is in
/// `docs/reviews/design-parity-checklist.md`: outlined (the kit) lost to
/// filled (owner), filled lost to tonal when a column of `primary` fills
/// sprayed the accent across every row — and the redesign restores primary
/// *because the rest of the card got quieter with it*: the metric chips gave
/// up their containers, the `+Nd` badge is gone, and overdue's danger ink is
/// the only other accent left, so one primary verb per card now reads as the
/// hierarchy instead of competing with it.
///
/// **An `MxActionButton` since the raw-button guard landed (2026-08-27), and
/// the geometry moved with it.** This widget used to build the `FilledButton`
/// itself — brand pair from `buildFilledStyle`, 40-high `md`-cornered pill
/// geometry stated inline — which made it one of the two feature files
/// `memox_v7.design_system.no_raw_button` fired on the day the rule was
/// written. `MxActionButtonSize.compact` now owns that geometry (40 drawn, 48
/// hit, `label-md` at `buttonLabelWeight` — 700 since M100.30), so the next
/// screen that needs a chip-row button gets this one instead of copying a
/// style block. One real change rode along at the time: the old inline label
/// set `fontWeight: w600` without moving the variable font's `wght` axis, so
/// it *painted* 500 — compact goes through `AppTypography.withWeight`, which
/// is why the weight M100.30 raised actually reached the glyphs.
class DeckStudyButtonWidget extends StatelessWidget {
  const DeckStudyButtonWidget({required this.deckId, super.key});

  final String deckId;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: _kButtonMinWidth),
      // **The word alone** (owner review, 2026-08-20). The play glyph said
      // nothing the verb did not, and it cost the row width that the gauge
      // beside it needed at large text scales.
      child: MxActionButton(
        label: context.l10n.deckStudyAction,
        // **`secondary`, and the argument for `primary` was a per-card one**
        // (M99.98). "One primary verb per card reads as the hierarchy" is true
        // of a card; a screen shows three or four at once, and the Library's
        // first viewport then carried the accent nine times — the page CTA,
        // three filled row verbs, two progress fills, three deck icon wells —
        // at which point the colour says repetition, not emphasis. It also
        // cost the screen's one `MxCard.accent` its job: a hairline in the
        // brand family cannot out-rank three solid fills below it. Study Home
        // already drew this same verb outlined, so the two screens now agree
        // rather than disagreeing.
        variant: MxActionButtonVariant.secondary,
        size: MxActionButtonSize.compact,
        onPressed: () => context.goNamed(
          RouteNames.deckStudy,
          pathParameters: <String, String>{RoutePathParams.deckId: deckId},
        ),
      ),
    );
  }
}
