import 'package:flutter/material.dart';

import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_icon_button.dart';

/// The app bar's Save — the concept's shortcut beside the title.
///
/// **An icon, always, and the labelled pill was measured out of existence.**
/// The concept draws a word, and a word fits in exactly one configuration:
/// `Edit flashcard` needs 145.8dp at scale 1.0 and 195.4 at 2.0, and the bar
/// gives the title 94.4 at 320dp, 131.3 at 390 @2.0, 101.3 at 360 @2.0. The
/// title was short by 14 to 94 pixels almost everywhere, and at 390 @1.0 — the
/// one place it fits — the margin is **0.0**, which is a layout one font metric
/// away from breaking.
///
/// A first attempt shrank the label only when the screen was compact *and* the
/// reader had enlarged text. That was measured in Vietnamese, where `Sửa thẻ`
/// always fits; English is the language that does not, and it does not at
/// 320 @1.0 and at 360–412, neither of which the condition covers. A rule that
/// is right in one locale is not a rule.
///
/// The footer's `Save changes` is the full-word primary and is unaffected. This
/// one is a shortcut, and a shortcut that costs the screen its name is not
/// worth the word.
///
/// It never shows a spinner. The footer owns saying that a save is running;
/// two spinners for one operation read as two operations.
class CardEditorSaveShortcutWidget extends StatelessWidget {
  const CardEditorSaveShortcutWidget({required this.onSave, super.key});

  /// `null` disables it — a pristine form, or a save already in flight. The
  /// same rule the footer's Save reads, from the same state.
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) => MxIconButton(
    icon: Icons.check,
    semanticLabel: context.l10n.cardEditorSaveShortAction,
    onPressed: onSave,
  );
}
