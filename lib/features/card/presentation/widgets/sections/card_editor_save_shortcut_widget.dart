import 'package:flutter/material.dart';

import '../../../../../core/theme/app_breakpoints.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_action_button.dart';
import '../../../../../shared/widgets/mx_icon_button.dart';

/// The app bar's Save — the concept's shortcut beside the title.
///
/// **It gives up its label before the title gives up its meaning.** At 320dp
/// and text scale 2.0 the bar has to hold a back arrow, a title, a flag and
/// this; measured in Vietnamese, the title slot came out 76.6dp against the
/// ~155 `Sửa thẻ` needs, so the bar rendered `Sử…` — a screen that no longer
/// says what it is. Dropping to an icon here returns about 50dp to the title.
///
/// **Both conditions come from foundations that already exist**, not from a
/// number chosen here: `AppBreakpoints.isCompact` is the app's narrow-screen
/// line, and "the reader has enlarged text at all" is a fact about the reader
/// rather than a threshold. The footer's Save keeps its full label in every
/// case — the shortcut is the half that may shrink.
///
/// It never shows a spinner. The footer owns saying that a save is running;
/// two spinners for one operation read as two operations.
class CardEditorSaveShortcutWidget extends StatelessWidget {
  const CardEditorSaveShortcutWidget({required this.onSave, super.key});

  /// `null` disables it — a pristine form, or a save already in flight. The
  /// same rule the footer's Save reads, from the same state.
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    final label = context.l10n.cardEditorSaveShortAction;
    final isTight =
        AppBreakpoints.isCompact(MediaQuery.sizeOf(context).width) &&
        MediaQuery.textScalerOf(context).scale(1) > 1;

    if (isTight) {
      return MxIconButton(
        icon: Icons.check,
        semanticLabel: label,
        onPressed: onSave,
      );
    }

    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: MxActionButton(label: label, onPressed: onSave),
    );
  }
}
