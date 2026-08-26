import 'package:flutter/material.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_stroke.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../domain/models/card_history_event_model.dart';
import '../support/card_history_labels_widget.dart';

/// One recorded turn on the timeline (BR-242, M4.15 W4).
///
/// **Every line is a stored value of that row.** Nothing on this widget compares
/// a before with an after to decide what to call the turn: BR-76 stores `kind`
/// and `action` precisely because that comparison is wrong for a `scheduled`
/// review of a box-8 card, and a widget that recomputed it would put the bug
/// back at the last possible moment.
///
/// **One semantics node, not six.** TalkBack should announce "14 Aug, 09:41.
/// Self-assess, Scheduled, Remembered. Box 2 → 3" as a sentence about a review;
/// six separate labels make the reader assemble the meaning themselves
/// (M4.15 W6).
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
    final outcomeColor = context.cardHistoryActionColor(event.action);

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
              _Marker(isFirst: isFirst, isLast: isLast, color: outcomeColor),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        timestamp,
                        style: context.texts.labelSmall?.copyWith(
                          color: context.colors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      _OutcomeLine(event: event, color: outcomeColor),
                      for (final line in scheduleLines)
                        Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.xs),
                          child: Text(
                            line.text,
                            style: context.texts.bodySmall?.copyWith(
                              color: line.isProgression
                                  // The ladder the reader is tracking, in the
                                  // same accent the schedule panel gives the
                                  // box above. `Next due` and `Schedule
                                  // unchanged` stay quiet: they are the
                                  // timetable, not a step along it.
                                  ? context.semanticColors.primaryAccent
                                  : context.colors.onSurfaceVariant,
                            ),
                          ),
                        ),
                      if (marks.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.xs),
                          child: Text(
                            marks.join(_inlineSeparator),
                            style: context.texts.labelSmall?.copyWith(
                              color: context.colors.onSurfaceVariant,
                            ),
                          ),
                        ),
                    ],
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

/// The dot, the connector under it, and the stub above it.
///
/// **The dot carries the outcome.** It used to be `onSurfaceVariant` on every
/// row, which made a column of dots decoration: the band had a shape and no
/// information in it. It is now the same colour as the action word on the line
/// beside it — success, warning or danger — so a reader scanning the timeline
/// sees where this card went wrong before reading a single word, and a reader
/// who cannot use colour reads the word (D5).
///
/// **The line is `borderSubtle` again.** It was `borderControl` because this
/// band had no card under it and the subtle token measures 1.38:1 against the
/// light *page*; the timeline now sits on a `surface` card, which is the ground
/// `borderSubtle` was measured against in the first place.
class _Marker extends StatelessWidget {
  const _Marker({
    required this.isLast,
    required this.isFirst,
    required this.color,
  });

  final bool isLast;

  /// The outcome's colour — see the class doc.
  final Color color;

  /// Whether the connector should start at this row. The line runs *between*
  /// events, so every row but the first opens with a stub above its dot —
  /// without it the line breaks for the height of the inset at every boundary.
  final bool isFirst;

  @override
  Widget build(BuildContext context) {
    // The dot centres on the timestamp's first line, so its offset is half of
    // that line minus half the dot — and the line grows with the text scaler,
    // so a constant inset leaves the dot floating above the text at 2.0.
    final firstLine = MediaQuery.textScalerOf(context).scale(_firstLineHeight);
    final inset = (firstLine - _markerSize) / 2;
    final line = Container(
      width: AppStroke.hairline,
      color: context.semanticColors.borderSubtle,
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

/// Where the turn came from, what it was for, and what was answered — one line,
/// three ranks.
///
/// **The action is the sentence and the other two are its context.** Mode and
/// kind used to be set exactly like the answer, so `Self-assess · Scheduled ·
/// Remembered` read as three equal facts and the only one a reader is scanning
/// for was buried in the middle of them. The answer keeps `bodyMedium`, takes
/// the weight and takes the outcome colour; the other two drop to `bodySmall` on
/// the muted ink.
///
/// **One `Text.rich`, not three `Text`s in a `Row`.** The three parts are one
/// sentence and must wrap as one at 320dp with a 2.0 scaler — a row of three
/// would either overflow or break in three places of its own choosing.
class _OutcomeLine extends StatelessWidget {
  const _OutcomeLine({required this.event, required this.color});

  final CardHistoryEventModel event;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final muted = context.texts.bodySmall?.copyWith(
      color: context.colors.onSurfaceVariant,
    );
    final answer = context.texts.bodyMedium;

    return Text.rich(
      TextSpan(
        children: <InlineSpan>[
          TextSpan(text: context.cardHistoryMode(event.mode), style: muted),
          TextSpan(text: _inlineSeparator, style: muted),
          TextSpan(text: context.cardHistoryKind(event.kind), style: muted),
          TextSpan(text: _inlineSeparator, style: muted),
          TextSpan(
            text: context.cardHistoryAction(event.action),
            // **`withWeight`, not `copyWith(fontWeight:)`.** The body face is a
            // variable font, so `copyWith` alone moves the declared weight
            // without moving the `wght` axis — it renders at the old weight and
            // reports the new one.
            style: answer == null
                ? null
                : AppTypography.withWeight(
                    answer,
                    FontWeight.w600,
                  ).copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

/// The separator between inline facts on one line.
///
/// Punctuation, not copy: a middle dot reads the same in every language this
/// app ships, so it is a constant here rather than a translated string.
const String _inlineSeparator = ' · ';

const double _markerColumnWidth = 12;
const double _markerSize = 8;

/// The line height of `labelSmall`, which is what the timestamp is set in.
///
/// Mirrored from `AppTypography` rather than read off the resolved style so the
/// marker's offset is a layout constant rather than a text measurement — the
/// two are the same number, and the doc is what keeps them so.
const double _firstLineHeight = 16;
