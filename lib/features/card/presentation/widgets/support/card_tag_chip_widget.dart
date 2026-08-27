import 'package:flutter/material.dart';

import '../../../../../core/theme/app_ink.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/theme_context_extension.dart';

/// A read-only tag pill (BR-93).
///
/// A filled `surfaceMuted` pill — the deck list's quiet-container language —
/// rather than a hairline outline: the label is `onSurfaceVariant` on the muted
/// ground, which clears 4.5:1, and the fill lets a tag read as a chip at a
/// glance without a border competing with the card's own.
///
/// **Extracted when the detail screen became a second caller**, not when the
/// row was written: the card list's tile held this privately until there was a
/// real second use to show which parts actually vary. The answer was none of
/// them, so nothing was parameterised on the way out and both surfaces render
/// the identical pill.
class CardTagChipWidget extends StatelessWidget {
  const CardTagChipWidget({required this.name, super.key});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: context.semanticColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        name,
        style: context.texts.labelSmall!.inked(context, AppInk.quiet),
      ),
    );
  }
}
