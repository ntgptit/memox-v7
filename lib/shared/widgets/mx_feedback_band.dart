import 'package:flutter/material.dart';

import '../../core/theme/extensions/app_ink.dart';
import '../../core/theme/foundations/app_spacing.dart';
import '../../core/theme/extensions/theme_context_extension.dart';
import 'mx_card.dart';
import 'mx_icon.dart';
import 'mx_text_button.dart';

/// A failure the user has to read, in flow: an icon, a title, a message, and
/// optionally one action.
///
/// **Six copies of this existed** (M99.96). `MxCard.feedback` deliberately
/// leaves the body to its caller — the icon and the copy have to stay product
/// content so colour is never the only cue — but "the body is yours" was read
/// as "build it yourself", and six files then wrote the same
/// `Semantics(liveRegion) → Row(icon, Column(title, message))` by hand. They
/// agreed today because they were copied from each other; nothing made them
/// keep agreeing, and a seventh error state would have been a seventh copy.
///
/// This widget owns the arrangement and the announcement. The words, and the
/// action if there is one, stay with the caller — which is the part
/// `MxCard.feedback` was right to keep open.
///
/// **The live region lives here, not at the call site.** Announcing a failure
/// is a property of *being* a failure band, and a caller that forgot
/// `liveRegion` shipped a band a screen-reader user never hears — a defect
/// invisible in a golden and in a widget test that only looks for the text.
class MxFeedbackBand extends StatelessWidget {
  const MxFeedbackBand({
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.tone = MxFeedbackTone.danger,
    super.key,
  }) : assert(
         (actionLabel == null) == (onAction == null),
         'A band has an action or it does not. With only a label the link '
         'renders and does nothing; with only a callback it never renders at '
         'all — and either way the build below drops it silently, so the band '
         'looks deliberately action-free and no test fails. This is the pair '
         'rule MxEmptyState and MxErrorState already assert.',
       );

  /// Already-localized. What went wrong, in a few words.
  final String title;

  /// Already-localized. What it means, or what to do about it.
  final String message;

  /// Already-localized, and in every case so far *Try again*.
  ///
  /// **This was `final Widget? action` until M100.5, and the doc it replaces
  /// argued the case honestly — it just turned out to be wrong on the facts.**
  /// It read: *"A widget rather than a label and a callback: both bands that
  /// carry an action style their button against `onErrorContainer`, and a band
  /// that built the control itself would have to grow a parameter for every
  /// property a caller might need next."*
  ///
  /// Two bands became four, all four built the identical control down to
  /// `accent: context.colors.onErrorContainer`, and **not one of them ever
  /// needed a property the band could not have supplied.** The cost the doc
  /// was avoiding stayed hypothetical; the duplication it accepted did not.
  ///
  /// And the colour they were all carrying is the band's own: the icon and
  /// both lines of text already paint `AppInk.onErrorContainer`. The action
  /// was the one element not given it, because a hole cannot inherit.
  ///
  /// `isDestructive` was never the answer either. `danger` measures 4.50:1 on
  /// this ground in light and 4.53 in dark, so it was not a contrast problem —
  /// *Try again* simply is not a destructive action, and painting it
  /// danger-red says something untrue about what pressing it does.
  final String? actionLabel;

  /// Null means no action; see [actionLabel] for the pair rule.
  final VoidCallback? onAction;

  /// Which band this is. `danger` unless the caller has something that has
  /// *not* failed to say (A20.1 P1-13): the reminder screen forced an OS
  /// permission refusal into the danger band because it was the only one,
  /// while `warningContainer` sat unused in the palette.
  final MxFeedbackTone tone;

  @override
  Widget build(BuildContext context) {
    final texts = context.texts;
    final AppInk ink = switch (tone) {
      MxFeedbackTone.danger => AppInk.onErrorContainer,
      MxFeedbackTone.warning => AppInk.onWarningContainer,
    };
    final IconData icon = switch (tone) {
      MxFeedbackTone.danger => Icons.error_outline,
      MxFeedbackTone.warning => Icons.warning_amber_outlined,
    };
    final MxCardFeedbackTone cardTone = switch (tone) {
      MxFeedbackTone.danger => MxCardFeedbackTone.danger,
      MxFeedbackTone.warning => MxCardFeedbackTone.warning,
    };

    return Semantics(
      // `container: true` as well, so the title and the message announce as
      // one block rather than as two unrelated strings.
      container: true,
      liveRegion: true,
      child: MxCard.feedback(
        tone: cardTone,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            MxIcon(icon, ink: ink, size: MxIconSize.mdCompact),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(title, style: texts.titleSmall!.inked(context, ink)),
                  const SizedBox(height: AppSpacing.xs),
                  Text(message, style: texts.bodySmall!.inked(context, ink)),
                  if (actionLabel case final label?) ...<Widget>[
                    const SizedBox(height: AppSpacing.xs),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      // The band's ink, resolved here rather than asked of the
                      // caller — this widget is the only one that knows which
                      // ground the link is standing on.
                      child: MxTextButton(
                        label: label,
                        onPressed: onAction,
                        accent: ink,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The two things a feedback band can be.
enum MxFeedbackTone {
  /// A failure: `errorContainer`, the error glyph.
  danger,

  /// A condition to act on that has not failed: `warningContainer`, the
  /// warning glyph. Kept in the palette for this band (A20.1 §4Q / P1-13).
  warning,
}
