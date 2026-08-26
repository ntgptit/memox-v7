import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../controllers/card_flag_controller.dart';

/// The editor app-bar action that toggles the card's flag (BR-92).
///
/// **Both states name a colour, and neither of them is the default.** Off used
/// to pass `color: null`, which hands the glyph to the bar's `IconTheme` —
/// `onSurface`, the same ink the title is set in. So the control that is *not*
/// engaged was drawn at full strength beside a title, and the only thing
/// separating on from off was the difference between a hollow flag and a filled
/// one at 24px (owner review, 2026-08-26). `onSurfaceVariant` is the app's
/// resting ink for a secondary control, so off now recedes and the semantic
/// `warning` on carries a step in weight as well as in hue.
///
/// **The amber is `AppColors.warning`, and it looks nothing like it in light.**
/// The review read the painted glyph as a yellow belonging to no token; the
/// value is `warningDark` — `#E8D08E`, which is the amber the *dark* palette
/// asks for. Light resolves the same token to `#9A6A11`, a far deeper amber
/// held there because a flag has to clear 4.5:1 against a light bar. One token,
/// two values, which is the whole reason `AppSemanticColors` is read from the
/// context rather than from a constant.
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

    return IconButton(
      icon: Icon(isFlagged ? Icons.flag : Icons.outlined_flag),
      color: isFlagged
          ? context.semanticColors.warning
          : context.colors.onSurfaceVariant,
      onPressed: flag.isLoading ? null : () => onToggle?.call(isFlagged),
      tooltip: isFlagged
          ? context.l10n.cardEditorUnflagAction
          : context.l10n.cardEditorFlagAction,
    );
  }
}
