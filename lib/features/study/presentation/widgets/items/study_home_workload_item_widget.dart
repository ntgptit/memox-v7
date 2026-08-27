import 'package:flutter/material.dart';

import '../../../../../core/theme/app_ink.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_metric_well.dart';
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
///
/// **In its one production call site that node is swallowed, on purpose.**
/// `StudyHomeDeckItemWidget` wraps the name, the algorithm and this row in a
/// single container whose sentence names the deck — because a workload phrase
/// that says whose it is not is the same problem one level out. The annotation
/// below is what this widget says when it stands alone, and it is kept so that
/// standing alone is not a silent regression.
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
              count: deck.overdueCount,
              word: l10n.studyHomeOverdueWord,
              color: deck.overdueCount > 0 ? AppInk.overdue : AppInk.quiet,
              wellColor: deck.overdueCount > 0
                  ? context.colors.errorContainer
                  : semantic.surfaceMuted,
              wellTint: deck.overdueCount > 0
                  ? context.colors.onErrorContainer
                  : quiet,
            ),
            _Metric(
              icon: deck.dueTodayCount > 0 ? Icons.event : Icons.event_outlined,
              count: deck.dueTodayCount,
              word: l10n.studyHomeDueTodayWord,
              color: deck.dueTodayCount > 0
                  ? AppInk.onDueContainer
                  : AppInk.quiet,
              wellColor: deck.dueTodayCount > 0
                  ? semantic.dueContainer
                  : semantic.surfaceMuted,
              wellTint: deck.dueTodayCount > 0
                  ? semantic.onDueContainer
                  : quiet,
            ),
            _Metric(
              icon: deck.newCount > 0
                  ? Icons.auto_awesome
                  : Icons.auto_awesome_outlined,
              count: deck.newCount,
              word: l10n.studyHomeNewWord,
              color: deck.newCount > 0 ? AppInk.info : AppInk.quiet,
              wellColor: semantic.surfaceMuted,
              wellTint: deck.newCount > 0 ? semantic.info : quiet,
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
    required this.count,
    required this.word,
    required this.color,
    required this.wellColor,
    required this.wellTint,
  });

  final IconData icon;
  final int count;
  final String word;

  /// The well behind the glyph and the glyph's own ink — the same pair the deck
  /// summary passes, so the two screens' anchors resolve to the same tokens.
  final Color wellColor;
  final Color wellTint;

  /// The metric's tint. It reaches the well and the word; the numeral stays
  /// neutral — see the build below.
  final AppInk color;

  /// Whether this count is non-zero. Drives weight and the filled glyph as well
  /// as ink, so the emphasis survives greyscale.
  bool get _isActive => count > 0;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.baseline,
    textBaseline: TextBaseline.alphabetic,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      // **The same anchor the deck summary and Progress use** (M99.26). This
      // was a bare glyph, which made the third screen in the app read as a
      // different grammar for the same kind of fact.
      MxMetricWell(icon: icon, tint: wellTint, wellColor: wellColor),
      const SizedBox(width: AppSpacing.xs),
      Flexible(
        child: Text.rich(
          TextSpan(
            children: <InlineSpan>[
              // **The numeral stays neutral and only the word takes the tint.**
              // Tinting both made the number itself a colour-coded signal, and
              // three differently-coloured numerals in one row read as three
              // kinds of number rather than three counts of the same kind.
              TextSpan(
                text: '$count ',
                style: context.texts.bodySmall!.inked(
                  context,
                  AppInk.stated,
                  isEmphasized: true,
                ),
              ),
              TextSpan(
                text: word,
                style: context.texts.bodySmall!.inked(
                  context,
                  color,
                  isEmphasized: _isActive,
                ),
              ),
            ],
          ),
          // **Two lines, because a truncated count is not a shortened count —
          // it is a wrong one.** `1024 overdue` clipped to `10…` reads as ten,
          // and `overdueCount` aggregates a whole subtree, so four digits is an
          // ordinary number for somebody who has been away.
          maxLines: 2,
        ),
      ),
    ],
  );
}
