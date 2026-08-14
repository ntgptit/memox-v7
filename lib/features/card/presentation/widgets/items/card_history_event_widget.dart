import 'package:flutter/material.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_stroke.dart';
import '../../../../../core/theme/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../domain/models/card_history_event_model.dart';
import '../support/card_history_labels_widget.dart';

/// One recorded turn on the timeline (BR-185, M4.14 W4).
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
/// (M4.14 W6).
///
/// The marker sits on the **first line's** band rather than the middle of the
/// row (M4.14 G3): rows differ in height with how many schedule lines they
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
              _Marker(isFirst: isFirst, isLast: isLast),
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
                      Text(
                        // Mode, then kind, then action: where the turn came
                        // from, what it was for, what was answered. Joined with
                        // the same separator the timestamp uses so the two
                        // lines read as one block.
                        <String>[
                          context.cardHistoryMode(event.mode),
                          context.cardHistoryKind(event.kind),
                          context.cardHistoryAction(event.action),
                        ].join(_inlineSeparator),
                        style: context.texts.bodyMedium,
                      ),
                      for (final line in scheduleLines)
                        Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.xs),
                          child: Text(
                            line,
                            style: context.texts.bodySmall?.copyWith(
                              color: context.colors.onSurfaceVariant,
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
/// The connector is what makes the band read as a timeline rather than a table;
/// the dot is `onSurfaceVariant` so the mark reads as content.
///
/// **The line is `borderControl`, not `borderSubtle`.** The subtle token was
/// measured against a *card* surface; this band has no card, so on the page
/// ground it falls to 1.38:1 in light — a line carrying the band's whole
/// structure, drawn at a weight nobody can see. `borderControl` is the token
/// minted for the 3:1 floor and measures 3.02:1 light / 3.41:1 dark there.
class _Marker extends StatelessWidget {
  const _Marker({required this.isLast, required this.isFirst});

  final bool isLast;

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
            decoration: BoxDecoration(
              color: context.colors.onSurfaceVariant,
              shape: BoxShape.circle,
            ),
          ),
          if (!isLast) Expanded(child: Center(child: line)),
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
