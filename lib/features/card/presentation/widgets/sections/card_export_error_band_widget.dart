import 'package:flutter/material.dart';

import '../../../../../core/error/failure.dart';
import '../../../../../core/theme/app_elevation.dart';
import '../../../../../core/theme/app_icon_size.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/theme_context_extension.dart';
import '../../../../../shared/widgets/mx_card.dart';
import '../support/card_export_labels_widget.dart';

/// The in-sheet error band (M4.13 W3 states 5–7, E8).
///
/// **The sheet stays open behind it.** Closing and firing a snackbar would
/// make the user rebuild the whole request — and with the selection scope,
/// possibly re-pick N cards — to find out what went wrong. So the band sits
/// above the action row, the scope and format above it are untouched, and the
/// action row decides whether the recovery is `Try again` or `Close`.
///
/// Icon **and** words: colour alone says nothing to a screen reader and
/// nothing to roughly one man in twelve. Neither line names a path, a file
/// name or a card (BR-180, BR-181) — the copy comes from the typed reason, and
/// the failure's own diagnostic message is never rendered.
///
/// **And a live region, because nothing else announces it.** The band appears
/// while focus is still on the primary, which merely relabels itself from
/// `Export 128 cards` to `Try again`; without this a screen-reader user is told
/// the button changed and never told the export failed.
/// `card_editor_screen.dart` marks its write failure the same way.
class CardExportErrorBandWidget extends StatelessWidget {
  const CardExportErrorBandWidget({required this.failure, super.key});

  final Failure failure;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Semantics(
      container: true,
      liveRegion: true,
      child: _band(context, colors),
    );
  }

  Widget _band(BuildContext context, ColorScheme colors) {
    return MxCard(
      color: colors.errorContainer,
      // Flat: the band sits inside the sheet's surface, and `MxCard`'s doc
      // calls a shadow stacked on a shadow a rendering fault rather than depth.
      // The error fill is already doing the separating here.
      elevation: AppElevation.none,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            Icons.error_outline,
            size: AppIconSize.mdCompact,
            color: colors.onErrorContainer,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  context.cardExportFailureTitle(failure),
                  style: context.texts.titleSmall?.copyWith(
                    color: colors.onErrorContainer,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  context.cardExportFailureLabel(failure),
                  style: context.texts.bodySmall?.copyWith(
                    color: colors.onErrorContainer,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
