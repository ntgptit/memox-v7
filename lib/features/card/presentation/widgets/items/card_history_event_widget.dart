import 'package:flutter/material.dart';

import '../../../../../core/theme/app_ink.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_stroke.dart';
import '../../../../../core/theme/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_icon.dart';
import '../../../../../shared/widgets/mx_card.dart';
import '../../../domain/models/card_history_event_model.dart';
import '../support/card_action_tone_widget.dart';
import '../support/card_history_labels_widget.dart';

/// One recorded turn on the timeline (BR-242, M4.15 W4).
///
/// **Every line is a stored value of that row.** Nothing on this widget compares
/// a before with an after to decide what to call the turn: BR-76 stores `kind`
/// and `action` precisely because that comparison is wrong for a `scheduled`
/// review of a box-8 card, and a widget that recomputed it would put the bug
/// back at the last possible moment.
///
/// **A card per event, since the compact layout.** The band used to be one
/// surface holding a run of text rows; giving each turn its own card is what
/// makes the timeline scannable — the verdict badge and the timestamp share a
/// top row, and everything the row actually stores sits under them.
///
/// **One semantics node, not six.** TalkBack should announce "14 Aug, 09:41.
/// Self-assess, Scheduled, Remembered. Box 2 → 3" as a sentence about a review;
/// six separate labels make the reader assemble the meaning themselves
/// (M4.15 W6). The badge, the timestamp and the lines are inside that one node,
/// so the card reads as one event rather than as four announcements.
///
/// The marker sits on the **first line's** band rather than the middle of the
/// row (M4.15 G3): rows differ in height with how many schedule lines they
/// carry, and a centred dot would wander down the connector as they do.
class CardHistoryEventWidget extends StatelessWidget {
  const CardHistoryEventWidget({
    required this.event,
    required this.isFirst,
    required this.isLast,
    super.key,
  });

  final CardHistoryEventModel event;

  /// Whether the connector should start at this row — it runs between events,
  /// so it must not trail off the top of the first one under a heading.
  final bool isFirst;

  /// Whether the connector should stop under this row — the line runs between
  /// events, so it must not trail off the bottom of the last one.
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final timestamp = context.cardHistoryTimestamp(event.answeredAt);
    final scheduleLines = context.cardHistoryScheduleLines(event);
    final marks = context.cardHistoryMarks(event);
    final tone = context.cardActionTone(event.action);

    return Semantics(
      container: true,
      label: context.l10n.cardHistoryEventSemantics(
        timestamp,
        // **The spoken forms, not the drawn ones.** The visible lines use `→`
        // and `–` because those read in every language without translation; a
        // screen reader either says "right arrow" or says nothing at all, and
        // an event whose schedule change is announced as silence is the one
        // thing W6's "one comprehensible sentence" rules out.
        context.cardHistoryModeSemantics(event.mode),
        context.cardHistoryKind(event.kind),
        context.cardHistoryAction(event.action),
        <String>[
          ...context.cardHistoryScheduleLinesSemantics(event),
          ...marks,
        ].join(' '),
      ),
      child: ExcludeSemantics(
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _Marker(
                isFirst: isFirst,
                isLast: isLast,
                color: context.cardActionToneColor(tone),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: MxCard.flat(
                    // Flat, like every other surface in this column (D20). A
                    // shadow on each of eight event cards is a stack of shadows,
                    // which reads as a rendering fault rather than as depth.
                    radius: AppRadius.md,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        // **A `Wrap`, so the timestamp can never squeeze the
                        // badge** — and a `SizedBox` around it, or the
                        // alignment is a no-op. A `Wrap` under a start-aligned
                        // `Column` gets loose constraints and shrinks to its
                        // content, so `spaceBetween` had no free space to
                        // spread and the timestamp sat against the badge, 107dp
                        // short of the card's inner edge. The summary hero
                        // carries the same `SizedBox` for the same reason.
                        SizedBox(
                          width: double.infinity,
                          child: Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.xs,
                            children: <Widget>[
                              _ActionBadge(
                                label: context.cardHistoryAction(event.action),
                                tone: tone,
                              ),
                              Text(
                                timestamp,
                                style: context.texts.labelSmall!.inked(
                                  context,
                                  AppInk.quiet,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        ..._facts(context, event, scheduleLines, marks),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The verdict, as a glyph and a word inside a pill.
///
/// **Outlined, not filled, and that is a measurement.** A tinted fill is what
/// the concept draws, and the only container this palette could give all three
/// tones is `surfaceMuted` — where `warning` measures **4.00:1** in light,
/// under the 4.5:1 its own label needs. On the card's own `surface` every tone
/// clears it (success 5.20 / 8.10, danger 5.57 / 6.71, warning 4.58 / 11.24),
/// and the border carries the same colour at the same ratio, well past the 3:1
/// a graphic needs. So the pill keeps its shape and gives up its fill rather
/// than the palette gaining a colour.
///
/// **Not upper-cased.** The concept sets these in caps; `search_group_header`
/// already records why that is the translator's decision and not the widget's —
/// it is wrong for locales with no case, and it changes the width the layout was
/// measured at.
class _ActionBadge extends StatelessWidget {
  const _ActionBadge({required this.label, required this.tone});

  final String label;
  final CardActionTone tone;

  @override
  Widget build(BuildContext context) {
    final ink = context.cardActionToneColor(tone);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        // `AppStroke.hairline` is `Border.all`'s own default, so it is not
        // restated — the analyzer rejects that, and the badge's edge is the
        // same 1dp every other hairline in the app draws.
        border: Border.all(color: ink),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          MxIcon(
            context.cardActionToneIcon(tone),
            ink: context.cardActionToneInk(tone),
            size: MxIconSize.sm,
          ),
          const SizedBox(width: AppSpacing.xs),
          // `Flexible`, because a `Row` hands an unbounded main axis to a
          // non-flex child: without it a long action label makes the pill wider
          // than the card that holds it instead of wrapping inside it.
          Flexible(
            child: Text(
              label,
              style: context.texts.labelSmall!.inked(
                context,
                context.cardActionToneInk(tone),
                isEmphasized: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The dot, the connector under it, and the stub above it.
///
/// The connector is what makes the band read as a timeline rather than a list of
/// cards.
///
/// **The dot takes the turn's verdict colour** (V15), from the stored
/// `StudyAction` and never from a diff of the schedule. It repeats what the
/// badge beside it says in words, so nothing here is carried by colour alone.
///
/// **The line is `borderControl`, not `borderSubtle`.** The subtle token is
/// 1.38:1 against the light page and 1.45:1 against a card — a line carrying the
/// band's whole structure, drawn at a weight nobody can see. `borderControl` is
/// the token minted for the 3:1 floor and measures 3.02:1 light / 3.41:1 dark on
/// the page this connector is drawn on.
class _Marker extends StatelessWidget {
  const _Marker({
    required this.isLast,
    required this.isFirst,
    required this.color,
  });

  final bool isLast;

  /// Whether the connector should start at this row. The line runs *between*
  /// events, so every row but the first opens with a stub above its dot —
  /// without it the line breaks for the height of the inset at every boundary.
  final bool isFirst;

  /// The verdict colour of this row's action.
  final Color color;

  @override
  Widget build(BuildContext context) {
    // **The dot centres on the badge, not on the badge's text.** The badge is a
    // pill: its own `xs` padding and its hairline make it ten points taller than
    // the line inside it, and centring on the line put the dot five pixels above
    // where it belongs at every scale. The text line grows with the scaler and
    // the padding does not, so both halves are stated.
    final firstLine = MediaQuery.textScalerOf(context).scale(_firstLineHeight);
    final badgeHeight = firstLine + AppSpacing.xs * 2 + AppStroke.hairline * 2;
    final inset = AppSpacing.md + (badgeHeight - _markerSize) / 2;
    final line = Container(
      width: AppStroke.hairline,
      color: context.semanticColors.borderControl,
    );

    return SizedBox(
      width: _markerColumnWidth,
      child: Column(
        children: <Widget>[
          SizedBox(
            height: inset,
            child: isFirst ? null : Center(child: line),
          ),
          Container(
            width: _markerSize,
            height: _markerSize,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          if (!isLast) Expanded(child: Center(child: line)),
        ],
      ),
    );
  }
}

/// One before-after line of the schedule.
///
/// **The box line is the accented one, and it is found by its kind** (V15). It
/// is `eight_box`'s whole notion of progress, so it is the line a reader scans a
/// timeline for. SM-2's three lines stay quiet: ease, interval and repetitions
/// only mean something together, and picking one to accent would be inventing a
/// progress metric SM-2 does not define (BR-243).
/// The prose half of the card: the mode-and-kind line, the schedule lines,
/// and the marks — split out of `build` when the inked migration nudged it
/// past the guard's build-length ceiling.
List<Widget> _facts(
  BuildContext context,
  CardHistoryEventModel event,
  List<CardHistoryScheduleLine> scheduleLines,
  List<String> marks,
) => <Widget>[
  Text(
    // Where the turn came from and what it was for. The verdict itself is
    // the badge above, so this line no longer repeats it.
    <String>[
      context.cardHistoryMode(event.mode),
      context.cardHistoryKind(event.kind),
    ].join(_inlineSeparator),
    style: context.texts.bodySmall!.inked(context, AppInk.quiet),
  ),
  for (final line in scheduleLines)
    Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Text(line.text, style: _scheduleLineStyle(context, line.kind)),
    ),
  if (marks.isNotEmpty)
    Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Text(
        marks.join(_inlineSeparator),
        style: context.texts.labelSmall!.inked(context, AppInk.quiet),
      ),
    ),
];

TextStyle _scheduleLineStyle(
  BuildContext context,
  CardHistoryScheduleLineKind kind,
) {
  final base = context.texts.bodySmall!;
  if (kind != CardHistoryScheduleLineKind.box) {
    return base.inked(context, AppInk.quiet);
  }

  // 7.27:1 light and 5.51:1 dark on the event card — the accent as text, which
  // `ColorScheme.primary` is not on a dark surface.
  return base.inked(context, AppInk.accent, isEmphasized: true);
}

/// The separator between inline facts on one line.
///
/// Punctuation, not copy: a middle dot reads the same in every language this
/// app ships, so it is a constant here rather than a translated string.
const String _inlineSeparator = ' · ';

const double _markerColumnWidth = 12;
const double _markerSize = 8;

/// The line height of `labelSmall`, which is what the badge's label is set in.
///
/// Mirrored from `AppTypography` rather than read off the resolved style so the
/// marker's offset is a layout constant rather than a text measurement — the two
/// are the same number, and the doc is what keeps them so. The card's own top
/// padding is added on top of it, because the dot lines up with the badge inside
/// the card rather than with the card's edge.
const double _firstLineHeight = 16;
