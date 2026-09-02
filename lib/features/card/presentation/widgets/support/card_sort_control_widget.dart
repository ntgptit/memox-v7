import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../shared/widgets/mx_menu_button.dart';
import '../../../../../shared/widgets/mx_icon.dart';
import '../../../../../core/theme/extensions/app_ink.dart';
import '../../../../../core/theme/foundations/app_spacing.dart';
import '../../../../../core/theme/extensions/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../domain/models/card_list_sort_model.dart';
import '../../controllers/card_list_filter_controller.dart';

/// Picks the sort (D3).
///
/// A free function, not a closure in `build()`: `ref.read` inside a build reads
/// without subscribing and is the bug the guard forbids, so the command is
/// written where the guard can tell it apart — the shape `_growWindow` and
/// `_selectFilter` already use.
void _selectSort(WidgetRef ref, String deckId, CardListSort sort) =>
    ref.read(cardListSortSelectionProvider(deckId).notifier).select(sort);

/// The card list's sort control, sitting opposite the "showing N of M" line.
///
/// **A menu, not a second pill row.** The filters already own a row of pills; a
/// second row would double the chrome above the list and make two different
/// controls look like one set. A sort is one choice out of a short list, which is
/// what a menu is for — and it states the current choice in its own label, so the
/// order is readable without opening it.
class CardSortControlWidget extends ConsumerWidget {
  const CardSortControlWidget({required this.deckId, super.key});

  final String deckId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(cardListSortSelectionProvider(deckId));

    return MxMenuButton(
      tooltip: context.l10n.cardSortLabel,
      actions: <MxMenuAction>[
        for (final sort in CardListSort.values)
          MxMenuAction(
            label: _label(context, sort),
            isSelected: sort == active,
            onSelected: () => _selectSort(ref, deckId, sort),
          ),
      ],
      child: Semantics(
        button: true,
        label: context.l10n.cardSortLabel,
        child: Padding(
          // Vertical padding, not a bare row: the label is small text and this is
          // a tap target, so it takes room to be hit without growing the line.
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                _label(context, active),
                style: context.texts.labelSmall!.inked(context, AppInk.quiet),
              ),
              const MxIcon(Icons.expand_more, size: MxIconSize.sm),
            ],
          ),
        ),
      ),
    );
  }

  String _label(BuildContext context, CardListSort sort) => switch (sort) {
    CardListSort.newest => context.l10n.cardSortNewest,
    CardListSort.dueFirst => context.l10n.cardSortDueFirst,
  };
}
