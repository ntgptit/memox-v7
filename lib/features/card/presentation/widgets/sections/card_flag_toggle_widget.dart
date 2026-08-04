import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../controllers/card_flag_controller.dart';

/// The editor app-bar action that toggles the card's flag (BR-92).
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
      color: isFlagged ? context.semanticColors.warning : null,
      onPressed: flag.isLoading ? null : () => onToggle?.call(isFlagged),
      tooltip: isFlagged
          ? context.l10n.cardEditorUnflagAction
          : context.l10n.cardEditorFlagAction,
    );
  }
}
