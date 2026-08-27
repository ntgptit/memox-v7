import 'package:flutter/material.dart';

import '../../../../../core/theme/app_ink.dart';
import '../../../../../core/theme/app_icon_size.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';

/// What the file holds, and what it does not (M4.13 W2 items 6–7, E4).
///
/// **One band, because the two sentences are one answer.** The reader is asking
/// a single question — "what am I actually getting?" — and W5 requires whatever
/// answers it to start and end on the sheet's two x-coordinates. Keeping the
/// pair in a named widget is also what lets the geometry test measure the band
/// the way it measures the scope summary: by type, not by hunting for a `Text`
/// that an icon has since inset.
///
/// **The hierarchy is the fix, not the icon.** These lines used to sit four
/// pixels apart in the same size, with the *info* one greyed — so the pair read
/// as one paragraph whose fainter half carried the surprise. The reader most
/// likely to skim it is precisely the one who came here believing an export is
/// a backup (BR-175). So the routine sentence steps back, the consequence keeps
/// full ink, and an `info_outline` glyph marks which is which.
///
/// **Info, not warning.** No error colour, no container, same type size: it is a
/// fact about what a transfer file *is*, and the user meets the consequence only
/// on re-import. The glyph is the shape this feature already uses for the job —
/// `card_import_source_step_widget.dart` and `card_import_result_widget.dart`
/// both mark an informational aside the same way.
class CardExportContentLinesWidget extends StatelessWidget {
  const CardExportContentLinesWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final texts = context.texts;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          // The six canonical fields, named in AD-20's order. The file's own
          // headers stay English whatever this sentence says (BR-179).
          l10n.cardExportIncludesLine,
          style: texts.bodySmall!.inked(context, AppInk.quiet),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(
              Icons.info_outline,
              size: AppIconSize.sm,
              color: colors.onSurfaceVariant,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                l10n.cardExportExcludesLine,
                // Full ink, unlike the line above it: this is the half a reader
                // is least expecting and most needs (E4).
                style: texts.bodySmall,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
