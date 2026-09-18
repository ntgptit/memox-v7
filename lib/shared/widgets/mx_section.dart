import 'package:flutter/material.dart';

import '../../core/theme/extensions/theme_context_extension.dart';
import '../../core/theme/foundations/app_decorations.dart';
import '../../core/theme/foundations/app_spacing.dart';
import '../../core/theme/foundations/app_stroke.dart';
import 'mx_card.dart';
import 'mx_section_label.dart';

/// A labelled group of rows on one card: the shape `SettingsSectionWidget`
/// and `ReminderSettingsSectionWidget` each hand-rolled before this file
/// existed — an optional overline, a raised card with a hairline between
/// every pair of rows, and an optional note underneath.
///
/// **The card is composed, not repainted.** The row container is
/// `MxCard.raised(padding: MxCardPadding.none)` — the exact recipe
/// `ReminderSettingsSectionWidget` already resolves `surfaceContainerLowest`
/// through, clipped to the card's own radius. Re-deriving that fill here
/// would be a second widget owning a `ColorScheme` role `MxCard` already
/// owns.
///
/// **Rows must not draw their own separators.** This widget paints the
/// `border-ghost` hairline between consecutive rows itself, so a row that
/// also draws a bottom `Divider` doubles the line.
class MxSection extends StatelessWidget {
  const MxSection({required this.rows, this.title, this.note, super.key})
    : assert(rows.length > 0, 'MxSection needs at least one row');

  /// Already-localized. Painted uppercase by [MxSectionLabel]. Omit for an
  /// untitled group — the card still gets the section's own trailing gap.
  final String? title;

  /// One widget per row, in reading order. `MxSection` paints a hairline
  /// (`border-ghost`) between each consecutive pair — rows must not draw
  /// their own separators.
  final List<Widget> rows;

  /// Already-localized supporting copy under the card. Omit when there is
  /// nothing to add.
  final String? note;

  @override
  Widget build(BuildContext context) {
    final hairlineColor = AppDecorations.hairlineEdge(context.colors).color;
    return Padding(
      // **`lg`, unconditional, title or no title.** The design contract
      // classifies this as a fixed dimension of the component itself, not
      // caller-owned spacing — screens stack `MxSection`s directly in a
      // `Column` with no `SizedBox` between them.
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (title != null) ...<Widget>[
            MxSectionLabel(label: title!),
            // `sm`, not `xs` — the value `SettingsSectionWidget.headingGap`
            // settled repo-wide after a visible label-to-card inconsistency.
            const SizedBox(height: AppSpacing.sm),
          ],
          MxCard.raised(
            padding: MxCardPadding.none,
            // `MxCard` paints its surface with a `DecoratedBox`; a `ListTile`
            // row paints its own background and ink onto the nearest
            // `Material` ancestor, which without this would be one behind
            // the card. Transparent, so the card's own fill still shows.
            child: Material(
              type: MaterialType.transparency,
              child: Column(
                children: <Widget>[
                  for (var i = 0; i < rows.length; i++) ...<Widget>[
                    if (i > 0)
                      Divider(
                        height: AppStroke.hairline,
                        thickness: AppStroke.hairline,
                        color: hairlineColor,
                      ),
                    rows[i],
                  ],
                ],
              ),
            ),
          ),
          if (note != null) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              child: Text(note!, style: context.texts.bodySmall),
            ),
          ],
        ],
      ),
    );
  }
}
