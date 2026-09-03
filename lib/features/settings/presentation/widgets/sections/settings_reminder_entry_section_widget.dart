import 'package:flutter/material.dart';

import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_icon.dart';
import '../../../../../shared/widgets/mx_card.dart';
import '../../../../../shared/widgets/mx_list_tile.dart';

/// The way into the daily reminder (wireframe M6 W1, UC-17).
///
/// **A label and a chevron, and deliberately no state.** Showing `Off` or the
/// chosen time here would make `features/settings/presentation/` watch
/// `features/reminder/`'s state — the cross-feature dependency M6 R1 and
/// `check_architecture` both refuse. The state is one tap away, on a screen
/// whose whole job is to say it.
///
/// The screen this opens belongs to the reminder feature and is reached by
/// route name, so nothing here imports it: `core/navigation` is the only thing
/// both features speak (AD-13).
class SettingsReminderEntrySectionWidget extends StatelessWidget {
  const SettingsReminderEntrySectionWidget({required this.onOpen, super.key});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return MxCard.raised(
      // Raised, like every sibling section on this screen (the D20 note that
      // once stood here described a flat card the code had already left).
      // `MxListTile` carries its own transparent `Material` since M100.36, so
      // the shim that used to sit here is gone.
      padding: MxCardPadding.none,
      child: MxListTile(
        title: context.l10n.reminderTitle,
        leading: const Icon(Icons.notifications_outlined),
        // Sized and coloured explicitly, and excluded from semantics, like
        // the app's other navigation chevron: a screen reader announcing
        // "chevron right" after the row's own label adds nothing, and the
        // `ListTile` defaults it happens to agree with today are not a
        // contract.
        trailing: const ExcludeSemantics(child: MxIcon(Icons.chevron_right)),
        onTap: onOpen,
      ),
    );
  }
}
