import 'package:flutter/material.dart';

import '../../core/theme/extensions/app_ink.dart';
import '../../core/theme/foundations/app_radius.dart';
import '../../core/theme/foundations/app_spacing.dart';
import '../../core/theme/extensions/theme_context_extension.dart';

/// A quiet readout: a word in a muted pill.
///
/// **A badge is not a chip** (M100.36 11K, #434 §17). It has no focus, no
/// press, no selected state and no touch-target claim — it is rounded because
/// it is a label, not because it is a control — so it is a `Container` and
/// never `Chip`, `ActionChip` or `MxPillButton`. Three features had written
/// this exact recipe by hand: the card row's due label, the read-only tag on a
/// card, the card detail's tags. One primitive, so the fourth cannot drift.
///
/// **`surfaceMuted`, not a status container.** The recipe is the deck list's
/// quiet-container language for a fact that is neither good nor bad news: the
/// label is `onSurfaceVariant` on the muted ground, 5.61:1 light / 6.17:1
/// dark. A badge that carries a status — overdue, recommended, imported — is a
/// different sentence and keeps its own container beside its own row; those
/// are not this widget, and folding them in would make one primitive say
/// three things.
///
/// **Semantics are the caller's.** A due label wants "due tomorrow"; a tag
/// wants the tag; the widget cannot know which sentence it is in, so it paints
/// the words and merges nothing. Wrap it in `Semantics(label:)` where the
/// painted word is not the spoken one.
class MxBadge extends StatelessWidget {
  const MxBadge({required this.label, super.key});

  /// Already-localized.
  final String label;

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
        label,
        style: context.texts.labelSmall!.inked(context, AppInk.quiet),
      ),
    );
  }
}
