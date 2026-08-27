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
    return MxCard.flat(
      // Flat, like every other card in a scrolling body (D20). A raised card
      // here would be the only shadow on the screen.
      padding: EdgeInsets.zero,
      // `Material` inside the card, and it is not decoration: `MxCard` paints
      // its surface with a `DecoratedBox`, and `ListTile` paints its background
      // and ink onto the nearest `Material` ancestor — which without this is the
      // Scaffold, *behind* the card. Flutter asserts on exactly that
      // arrangement. Transparent, so the card's own colour still shows.
      child: Material(
        type: MaterialType.transparency,
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
      ),
    );
  }
}
