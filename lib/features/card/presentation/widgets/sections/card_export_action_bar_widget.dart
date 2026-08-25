import 'package:flutter/material.dart';

import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_action_button.dart';
import '../../../../../shared/widgets/mx_button_pair.dart';
import '../../states/card_export_state.dart';

/// The export sheet's action row (M4.13 W2 item 8, W5, E6, E7).
///
/// **`Cancel` sits beside the primary**, unlike the import wizard's bar: a
/// sheet has no app bar, so without it the only way out is the drag-down
/// gesture — no affordance, and nothing a screen reader can announce.
///
/// **The row is replaced in place, never the sheet.** Every phase renders the
/// same two-slot row, so the sheet does not change height as the state moves;
/// a sheet that jumps while the user is reading it loses their place, and at
/// 320dp it pushes content off screen (E7).
///
/// **The two buttons share the content column's edges.** `Cancel` starts it,
/// the primary ends it, and both are `Expanded` — a `Row` of intrinsic-width
/// buttons would sit inboard of every other band while measuring perfectly on
/// the row that holds them (W5). Below a measured threshold they stack
/// full-width with the primary on top, which is what 320dp at 2.0× needs.
class CardExportActionBarWidget extends StatelessWidget {
  const CardExportActionBarWidget({
    required this.phase,
    required this.cardCount,
    required this.onCancel,
    required this.onSubmit,
    super.key,
  });

  final CardExportPhase phase;

  /// The scope's card count — the `N` in `Export N cards`.
  final int cardCount;

  final VoidCallback onCancel;

  /// Runs the export. Null while one is in flight or when the scope can no
  /// longer produce one.
  final VoidCallback? onSubmit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    // The scope is gone: there is nothing to retry until the user picks again,
    // so the primary is *absent* rather than greyed (W3 state 7). One lone
    // outlined action makes that visible instead of leaving a dead button.
    if (phase == CardExportPhase.invalidScope) {
      return Row(
        children: <Widget>[
          Expanded(
            child: MxActionButton(
              label: l10n.cardExportCloseAction,
              variant: MxActionButtonVariant.secondary,
              onPressed: onCancel,
            ),
          ),
        ],
      );
    }

    final isGenerating = phase == CardExportPhase.generating;
    final cancel = MxActionButton(
      label: l10n.commonCancelAction,
      variant: MxActionButtonVariant.secondary,
      // Live even while generating: the request has not touched the database
      // (BR-178), so there is nothing to roll back and no reason to trap the
      // user behind a file they no longer want (W4).
      onPressed: onCancel,
    );
    final primary = MxActionButton(
      label: switch (phase) {
        CardExportPhase.generating => l10n.cardExportSubmittingLabel,
        CardExportPhase.retryableError => l10n.cardExportRetryAction,
        CardExportPhase.initial ||
        CardExportPhase.shared ||
        CardExportPhase.invalidScope => l10n.cardExportSubmitAction(cardCount),
      },
      // The sheet's one indeterminate indicator, and it keeps the button's
      // width so nothing beside it moves (E7).
      isLoading: isGenerating,
      // **`Exporting…` stays painted.** The button's default hides the label at
      // alpha 0 and lets semantics carry it, which is right for a button that
      // sizes to its own text and wrong here twice over: W6 asks for real text
      // rather than a mute spinner, and both buttons are `Expanded`, so the
      // width the default protects is already fixed by the row. Without this
      // the only visible difference between "about to export" and "exporting"
      // is that the words vanished.
      shouldKeepLabelWhileLoading: true,
      onPressed: isGenerating ? null : onSubmit,
    );

    // The row-or-stack decision, the even split and the matched heights are
    // `MxButtonPair`'s — this bar is where that behaviour was first written,
    // and it moved to the shared widget when every other action pair in the app
    // needed the same three properties. The threshold it defaults to is the one
    // measured here: `Export 128 cards` must not ellipsize into `Export…` on
    // the control that says what pressing it does.
    return MxButtonPair(secondary: cancel, primary: primary);
  }
}
