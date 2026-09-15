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
/// **Secondary, and the walk to it is recorded rather than repeated.** The full
/// history is in `docs/reviews/design-parity-checklist.md`: outlined (the kit)
/// lost to filled (owner), filled lost to tonal when a column of `primary`
/// fills sprayed the accent across every row, and the 2026-08-20 redesign
/// restored primary on the argument that the rest of the card had gone quieter
/// with it. M99.98 reversed that last step for the reason written at the
/// `variant:` below — the argument was true of one card and false of a screen
/// showing four. What the button *is* is stated there, next to the code that
/// sets it.
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
  const DeckStudyButtonWidget({
    required this.deckId,
    required this.deckName,
    super.key,
  });

  final String deckId;

  /// The deck this verb belongs to, for the screen-reader name only.
  ///
  /// The painted label stays the one word — every row shows `Study`, and a row
  /// that spelled out the deck would wrap on the narrowest screens the tile is
  /// measured at. The *announced* name carries it instead, which is the split
  /// `study_home_deck_item_widget.dart` already makes for the same list of the
  /// same decks in the Study tab.
  final String deckName;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: _kButtonMinWidth),
      // **The word alone** (owner review, 2026-08-20). The play glyph said
      // nothing the verb did not, and it cost the row width that the gauge
      // beside it needed at large text scales.
      child: MxActionButton(
        label: context.l10n.deckStudyAction,
        semanticLabel: context.l10n.deckRowStudySemanticLabel(deckName),
        // **A glyph again, and pointing rather than naming** (owner brief,
        // 2026-09-10). The 2026-08-20 review took one away and wrote why: "the
        // play glyph said nothing the verb did not, and it cost the row width
        // that the gauge beside it needed at large text scales."
        //
        // The first half is answered by the glyph itself — an arrow does not
        // restate `Study`, it says where the tap goes, which is the one thing
        // the word alone leaves out on a row that also opens the deck. The
        // second half is a measurement, and it was re-measured rather than
        // waved past: see the doc on this class for the 320dp figures and what
        // gives way there.
        icon: Icons.arrow_forward,
        iconSide: MxActionButtonIconSide.trailing,
        // **`primary`, reversing M99.98 — and the thing that changed is the
        // page, not the opinion.** That task counted the accent nine times in
        // the first viewport and made this verb outlined to spend less of it.
        // The count was right and the target was wrong: the loudest of the
        // nine was the root's `MxHeroPrimary`, and the comment above it in
        // `deck_level_summary_widget.dart` already admitted what that button
        // does at the root — it "promised a session and delivered an index",
        // landing on the Study tab with nothing started. So the screen spent
        // its whole accent budget on a signpost and dressed the control that
        // actually opens a session as an alternative.
        //
        // The root CTA is gone (it stays inside a deck, where it does start
        // that deck's session), which *lowers* the accent count rather than
        // raising it: one hero removed, one fill per row added. What is left
        // loud is the one control on the screen that does the thing the
        // screen is for.
        //
        // The other half of M99.98 stands and is why nothing else moved: the
        // deck wells, the gauges and the FAB stay tonal, so the fills have
        // something quiet to be legible against.
        //
        // **`tonal`, and this is where the walk finally lands** (owner brief,
        // 2026-09-10). The history above records the loop: outlined (the kit)
        // → filled (owner) → **tonal**, "when a column of `primary` fills
        // sprayed the accent across every row" → primary again at the
        // 2026-08-20 redesign → outlined at M99.98 → filled at M100.71.
        //
        // The project reached the right answer once already and lost it,
        // because `MxActionButtonVariant` had no tonal value to hold it. Every
        // later pass had to choose between a fill that repeats four times in a
        // viewport and an outline that says "alternative" on a row with
        // nothing to be an alternative to. M100.73 added the value that ends
        // the loop — the weight M3 defines for exactly this list.
        //
        // M100.71's finding is not undone by this: the root's hero CTA is
        // still gone, so the accent is still not spent on a signpost. What
        // changed is that the row's verb no longer has to spend it either.
        variant: MxActionButtonVariant.tonal,
        // **`dense`, and it is a return rather than a discovery.** The
        // 2026-08-20 review moved this verb from 32 up to 40 — "40 is on the
        // 4px grid and clears the 32 the pill used to paint". The 2026-09-10
        // brief measures the reference at ~34 and asks for the smaller body
        // back, from a page where the row's verb is the lightest thing on the
        // card rather than its loudest. M100.77 admitted `dense` as an option
        // beside `compact` for that reason: the two readings disagree and
        // neither is a rule, so the call site says which one this row wants.
        //
        // The floor is not part of the trade — 32 is the body, 48 is still
        // what a finger gets, and `mx_action_button_size_test` measures it.
        size: MxActionButtonSize.dense,
        onPressed: () => context.goNamed(
          RouteNames.deckStudy,
          pathParameters: <String, String>{RoutePathParams.deckId: deckId},
        ),
      ),
    );
  }
}
