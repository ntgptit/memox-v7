import 'package:flutter/material.dart';

import '../../../../../shared/widgets/mx_card.dart';
import '../../../../../shared/widgets/mx_icon.dart';
import '../../../../../core/theme/foundations/app_spacing.dart';
import '../../../../../core/theme/extensions/theme_context_extension.dart';
import '../../../domain/models/card_export_scope_model.dart';
import '../support/card_export_labels_widget.dart';

/// The read-only scope line of the export sheet (M4.13 W2 item 3, E2).
///
/// **A statement, not a control.** The scope is decided by the entry point
/// (BR-174), so there is nothing to change here — a selector would let someone
/// who opened from `Export selected` export the whole deck by accident, which
/// is nobody's intent and a silent way to discard the selection they just
/// built. It stays in the semantics tree all the same: a screen-reader user
/// needs to hear what the export covers before pressing the primary.
///
/// **Its own flat card**, not a row loose on the sheet's background — the same
/// grammar Card Detail's bands read by (D20): a fact the user is here to
/// verify sits on a surface, not directly on the page.
class CardExportScopeSummaryWidget extends StatelessWidget {
  const CardExportScopeSummaryWidget({
    required this.scope,
    required this.deckCardCount,
    super.key,
  });

  final CardExportScope scope;

  /// The deck's own total, used only by the whole-deck scope.
  final int deckCardCount;

  @override
  Widget build(BuildContext context) {
    return MxCard.flat(
      padding: MxCardPadding.compact,
      child: Row(
        children: <Widget>[
          MxIcon(switch (scope) {
            CardExportWholeDeckScope() => Icons.style_outlined,
            CardExportSelectionScope() => Icons.checklist,
          }, size: MxIconSize.mdCompact),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              context.cardExportScopeLabel(scope, deckCardCount),
              // Two lines rather than an ellipsis: the count is the one thing
              // on this line the user is here to verify, and at double scale
              // the sentence does not fit one line at 320dp.
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: context.texts.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
