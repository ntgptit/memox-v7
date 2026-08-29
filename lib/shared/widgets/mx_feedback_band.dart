import 'package:flutter/material.dart';

import '../../core/theme/app_ink.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/theme_context_extension.dart';
import 'mx_card.dart';
import 'mx_icon.dart';

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
    this.action,
    super.key,
  });

  /// Already-localized. What went wrong, in a few words.
  final String title;

  /// Already-localized. What it means, or what to do about it.
  final String message;

  /// One control under the message — a retry, usually.
  ///
  /// A widget rather than a label and a callback: both bands that carry an
  /// action style their button against `onErrorContainer`, and a band that
  /// built the control itself would have to grow a parameter for every
  /// property a caller might need next.
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final texts = context.texts;

    return Semantics(
      // `container: true` as well, so the title and the message announce as
      // one block rather than as two unrelated strings.
      container: true,
      liveRegion: true,
      child: MxCard.feedback(
        tone: MxCardFeedbackTone.danger,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const MxIcon(
              Icons.error_outline,
              ink: AppInk.onErrorContainer,
              size: MxIconSize.mdCompact,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    title,
                    style: texts.titleSmall!.inked(
                      context,
                      AppInk.onErrorContainer,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    message,
                    style: texts.bodySmall!.inked(
                      context,
                      AppInk.onErrorContainer,
                    ),
                  ),
                  if (action case final control?) ...<Widget>[
                    const SizedBox(height: AppSpacing.xs),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: control,
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
