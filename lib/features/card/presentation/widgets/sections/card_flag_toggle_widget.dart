import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_icon_button.dart';
import '../../controllers/card_flag_controller.dart';

/// The editor app-bar action that toggles the card's flag (BR-92).
///
/// **Three signals, so colour is never the only one.** The glyph changes shape
/// — outlined when the card is unflagged, filled when it is — the tone changes
/// it to `warning`, and the accessible name says which way the next tap goes.
/// The middle one used to be a raw `IconButton(color:)` inside a feature, which
/// is how a theme gets a fourth orange; it is [MxIconButtonTone.warning] now.
///
/// **The concept does not draw it, and it stays anyway.** BR-92 is a shipped
/// feature; a redesign that quietly removes the only way to reach it would be
/// deleting a capability under cover of a layout change.
///
/// It writes immediately. There is no save button here to wait for, and a flag
/// queued behind one would be a flag the user believes they have set.
class CardFlagToggleWidget extends ConsumerWidget {
  const CardFlagToggleWidget({
    required this.cardId,
    required this.onToggle,
    super.key,
  });

  final String cardId;
  final ValueChanged<bool>? onToggle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flag = ref.watch(cardFlagProvider(cardId));
    final isFlagged = flag.value ?? false;
    // The name states the *action*, not the state, because that is what a
    // button's name is for — and it is the state's only non-visual signal.
    final label = isFlagged
        ? context.l10n.cardEditorUnflagAction
        : context.l10n.cardEditorFlagAction;

    return MxIconButton(
      icon: isFlagged ? Icons.flag : Icons.flag_outlined,
      semanticLabel: label,
      tone: isFlagged ? MxIconButtonTone.warning : MxIconButtonTone.standard,
      // **Both conditions, because either one means inert.** `flag.isLoading`
      // is this widget's own read; a null [onToggle] is the screen saying a
      // flag write is already in flight. Checking only the first left a button
      // that hit-tested as enabled and then did nothing — the affordance lying
      // about itself, even though the controller made it harmless.
      onPressed: flag.isLoading || onToggle == null
          ? null
          : () => onToggle!.call(isFlagged),
    );
  }
}
