import 'package:flutter/material.dart';

import '../../../../../core/theme/foundations/app_spacing.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_card.dart';
import '../../../../../shared/widgets/mx_progress_bar.dart';
import '../../../domain/models/deck_list_snapshot_model.dart';
import '../../../domain/models/deck_summary_model.dart';
import 'deck_summary_metrics_widget.dart';
import '../../../../../shared/widgets/mx_hero_card.dart';

/// The level's study status, as the screen's one hero (BR-150, BR-161).
///
/// At the root it answers "what is waiting today"; inside a deck it answers the
/// same question about that deck. They are the same question at different
/// scopes, so they are one block rather than a home screen and a header.
///
/// **Two lines, because the screen belongs to the list under it** (owner
/// review, 2026-08-25). Measured before the change: 320px of a 852px viewport
/// — 37.6% — which left one and a half deck cards on screen and put the third
/// below the fold. The panel now reads
///
/// ```
/// 15 cards due   8 overdue · 7 today
/// ▓▓▓▓▓▓▓▓░░░░░░░░░░  353 of 868 learned      41%
/// [        Study 15 due cards        ]
/// ```
///
/// What went is not data but *ranking*: the eyebrow (`TODAY` said nothing
/// "cards due" does not) and the New/Scheduled band left, because the deck rows
/// below already carry both.
///
/// **The panel has no control of its own.** It was dismissible, then it was
/// foldable; both existed because the panel was in the way of the list, and at
/// two facts it is not (owner decision, 2026-08-25; 2026-09-10). A level with
/// nothing studyable renders no panel at all — [hasStudyable] is the presence
/// rule outright, where it used to be what `auto` resolved to.
///
/// **Every number here is arithmetic over the snapshot the screen already has.**
/// A child's counts are its whole subtree, and sibling subtrees are disjoint, so
/// the level folds on [DeckListSnapshot] are the level's totals — no second
/// read, and therefore no chance of the panel and the list disagreeing about
/// the same instant (AD-13). A deck holds one kind of thing (BR-63), so a level
/// whose children are decks has no cards of its own to leave out of the sum.
///
/// **The surface is [MxCard], not a hand-rolled box.** Radius, border,
/// elevation and interaction states all come from the one shared surface, and
/// the panel has no control of its own: it states two facts and stops.
///
/// **It used to fold, and the fold is gone.** A chevron hid the learned caption
/// and a New/Scheduled row behind a disclosure. Opened on a library where
/// nothing has been studied yet, that disclosure paid out one repeat of the
/// number directly above it and two zeros — a control whose whole job was to
/// manage the volume of figures the deck rows already carry. Removing the
/// repetition left it nothing to manage.
///
/// What survives is what the rows cannot say between them: the level's total
/// workload, and how far the level as a whole has come. The learned caption
/// coming back to rest also returns it to a screen reader, which the fold had
/// quietly taken away.
class DeckLevelSummaryWidget extends StatelessWidget {
  const DeckLevelSummaryWidget({
    required this.snapshot,
    this.onStudyDue,
    super.key,
  });

  final DeckListSnapshot snapshot;

  /// Starts studying what the hero counts. Null hides the CTA — the panel
  /// stays honest on a level with nothing due.
  final VoidCallback? onStudyDue;

  /// Whether this level has anything to summarise.
  ///
  /// Exposed so the screen can leave the panel out entirely rather than render
  /// an empty one: a level with no decks has an empty state that already says
  /// more than "0 cards due" would.
  static bool hasContent(DeckListSnapshot snapshot) =>
      snapshot.decks.isNotEmpty;

  /// Whether anything on this level is waiting to be studied — new **or** due
  /// (BR-150).
  ///
  /// The presence rule. Exposed here rather than computed by the caller so that
  /// the number deciding whether the panel appears and the number the panel
  /// prints are the same fold over the same snapshot — a panel that appeared
  /// because of one count and then displayed another would be worse than one
  /// that never appeared.
  ///
  /// `any` rather than summing: the question is whether the sum is non-zero, and
  /// a card count cannot be negative, so the first studyable deck answers it.
  static bool hasStudyable(DeckListSnapshot snapshot) =>
      snapshot.decks.any((DeckSummary summary) => summary.hasStudyableCards);

  @override
  Widget build(BuildContext context) {
    // `MxHeroCard` measures outside the card, which is the only place the
    // answer is the card's width rather than its content's — see its doc for
    // the branch this app has already shipped wrong once.
    return MxHeroCard(builder: _panel);
  }

  /// The card itself, once the width question above has been answered.
  Widget _panel(BuildContext context, bool isCramped) {
    // **The page's own card, and the emphasis is in the content** (owner
    // brief, 2026-09-08: modern, legible, not colourful, for a study app).
    //
    // It was `MxCard.accent` — an indigo edge plus a step of extra
    // elevation — carrying the 2026-08-20 finding that the panel "did not
    // separate from the background at all". That reading was taken against a
    // *borderless* card; the recipe has had `AppElevation.card` since, so the
    // separation the accent was bought for is already paid for. What the edge
    // added on top was rank, and in dark it is the loudest line on the screen:
    // the only outlined card above six hairlined ones.
    //
    // Five of the app's seven hero-tier panels — both Progress panels, the
    // card-detail summary, the import outcome, the session summary — already
    // rest on this recipe and rank themselves by type: an eyebrow, a numeral,
    // a supporting line. This panel outranks its neighbours by a 34px numeral
    // and the screen's only filled button, which is more emphasis than a
    // 1px edge was ever supplying, and it now costs the page no second
    // surface vocabulary. See `docs/reviews/hero-panel-audit.md` §H2.
    // **The card's own padding again, and no `Stack`.** Both were bent around
    // the chevron: zero padding so the 48px target could take the corner, a
    // `Stack` so it could sit over the content without setting the figure
    // line's height. With the chevron gone the card can simply be padded.
    return MxCard.raised(child: _content(context, isCramped: isCramped));
  }

  Widget _content(BuildContext context, {required bool isCramped}) {
    final decks = snapshot.decks;
    final cardCount = decks.fold<int>(0, (sum, d) => sum + d.totalCardCount);
    final learnedCount = decks.fold<int>(
      0,
      (sum, d) => sum + d.learnedCardCount,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // **The eyebrow does not fit, and the number says by how much**
        // (measured 2026-09-10, owner brief). The reference opens its panel
        // with a small chip before the numeral and the owner asked for it. A
        // fourth band costs this panel 32.0px — a badge plus its gap — and
        // `deck_summary_compact_geometry_test` had 14.1px of slack, so card
        // three ends at 789.9 against a fold at 772. Over by 17.9.
        //
        // **Not a decoration problem.** Stripping the pill and drawing bare
        // uppercase text still costs about 22 and still misses by 8: what the
        // panel cannot afford is the band existing, not what is drawn in it.
        // The reference can afford one because its hero is tall by design —
        // chip, numeral, a sentence and a full-width CTA. This one is two
        // bands because 320px of a 852px viewport was the defect that started
        // the compaction.
        //
        // Left out rather than merged with the guard relaxed: three whole
        // cards is the rule that paid for every other decision on this panel.
        DeckSummaryMetricsWidget(snapshot: snapshot),
        // **The bar always arrives with its caption**, never as a bare rule
        // (owner review, 2026-08-25, third pass). It shipped label-less on the
        // brief's own instruction — "no label" — and a 41% fill between
        // `15 cards due` and the Study button states a proportion of nothing
        // the eye can name. A gauge with no referent is not quieter than a
        // labelled one, only smaller.
        //
        // It then spent a release behind the chevron, which took the learned
        // figure away from a screen reader as well — the one reader that had
        // been getting it. Back at rest, both readers get it, and it is the
        // one fact the deck rows cannot state between them: each row's bar
        // measures its own deck, none of them measures the level.
        if (cardCount > 0) ...<Widget>[
          // `md` between every band, not `lg` between some and `xl` between
          // others: the panel is two lines and a rule now, and a section
          // break inside three rows is a break between nothing.
          const SizedBox(height: AppSpacing.md),
          // The same progress tokens as every tile: track, fill, and success
          // only at 100%.
          MxProgressBar(
            size: MxProgressBarSize.sm,
            value: learnedCount / cardCount,
            label: context.l10n.deckLearnedProgressLabel(
              learnedCount,
              cardCount,
            ),
            valueLabel: context.l10n.deckLearnedPercentLabel(
              (learnedCount / cardCount * 100).round(),
            ),
          ),
        ],
        // The main task, on top of the screen instead of a scroll away
        // (owner mockup, 2026-08-20). At the root it opens the Study tab —
        // a session belongs to one root deck (BR-101), so a cross-deck
        // session cannot honestly be offered; inside a deck it starts that
        // deck's study. The caller decides which; null means nothing is
        // due and the button would be a promise with no cards behind it.
        //
        // **One label, because there is one destination left.** Both levels
        // used to share this button and it needed two labels: inside a deck
        // it starts that deck's session, at the root it landed on the Study
        // tab with nothing started — "promised a session and delivered an
        // index". The root case is gone rather than relabelled; the row's own
        // Study verb is the honest way to pick a deck, and it is now the
        // filled one. The caller passes null at the root, so only the
        // deck-level label remains.
        if (onStudyDue != null) ...<Widget>[
          const SizedBox(height: AppSpacing.md),
          MxHeroPrimary(
            label: context.l10n.deckSummaryStudyDueAction(
              snapshot.levelDueCardCount,
            ),
            onPressed: onStudyDue!,
            isCramped: isCramped,
          ),
        ],
      ],
    );
  }
}
