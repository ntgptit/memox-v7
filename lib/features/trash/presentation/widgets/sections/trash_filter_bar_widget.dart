import 'package:flutter/material.dart';

import '../../../../../core/theme/foundations/app_spacing.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_pill_button.dart';
import '../../states/trash_state.dart';

/// The Cards / Decks split, as chips on one list (wireframe T3).
///
/// **Not a `TabBar`.** Trash is almost always short, so two tabs would be two
/// nearly-empty screens where one screen has content — and `All` is the right
/// default, which a tab bar has no way to express.
class TrashFilterBarWidget extends StatelessWidget {
  const TrashFilterBarWidget({
    required this.filter,
    required this.onChanged,
    super.key,
  });

  final TrashFilter filter;
  final ValueChanged<TrashFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    // The group introduces itself to a screen reader before its options
    // (M100.36 11F, #434 P2-8); the pills keep their own selected state.
    return Semantics(
      container: true,
      label: l10n.trashFilterGroupLabel,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        // **No horizontal padding of its own.** The shell's subheader already
        // supplies the screen gutter, and adding `AppSpacing.lg` on top of it
        // put the first chip 16dp further in than every row below — G1 asks
        // for one left edge, and two paddings can only ever produce two.
        //
        // It scrolls rather than wraps: at 320dp with a large text scale three
        // chips do not fit, and a wrapped second line moves the list under the
        // reader's thumb every time the filter changes.
        child: Row(
          // One gap idiom for every pill group: the row's own `spacing`
          // (#434 P2-9).
          spacing: AppSpacing.sm,
          children: <Widget>[
            for (final entry in <(TrashFilter, String)>[
              (TrashFilter.all, l10n.trashFilterAll),
              (TrashFilter.cards, l10n.trashFilterCards),
              (TrashFilter.decks, l10n.trashFilterDecks),
            ])
              MxPillButton(
                label: entry.$2,
                isSelected: filter == entry.$1,
                onPressed: () => onChanged(entry.$1),
              ),
          ],
        ),
      ),
    );
  }
}
