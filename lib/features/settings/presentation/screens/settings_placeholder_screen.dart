import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/route_names.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/l10n_extension.dart';
import '../../../../shared/widgets/mx_card.dart';
import '../../../../shared/widgets/mx_content_shell.dart';
import '../../../../shared/widgets/mx_empty_state.dart';
import '../../../../shared/widgets/mx_list_tile.dart';

/// The Settings branch, before the Settings feature exists.
///
/// **Still presentation-only** (AD-19). It holds no provider, no storage and no
/// control that persists anything: the one row below is a link, and the screen
/// it opens is owned by the reminder feature (M6 R1). That is what keeps this
/// file free of a second feature's presentation layer — a section embedded here
/// would be the cross-feature import the boundary check rejects.
///
/// **The row shows no value, and that is the same boundary** (M6 W1). Putting
/// `Off` or the chosen time in the trailing slot would mean watching the
/// reminder feature's own state from here. The value is one tap away on a
/// screen that states it plainly, which is the cheaper half of that trade.
///
/// The placeholder message stays: one link is not app settings, and removing
/// the message would imply the branch is finished.
class SettingsPlaceholderScreen extends StatelessWidget {
  const SettingsPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MxContentShell(
      title: context.l10n.settingsTitle,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          MxCard(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            // `Material` inside the card for the reason the reminder section
            // states: `MxCard` paints with a `DecoratedBox`, and `ListTile`
            // paints its ink onto the nearest `Material` ancestor — which
            // without this is behind the card, and Flutter asserts on it.
            child: Material(
              type: MaterialType.transparency,
              child: MxListTile(
                title: context.l10n.reminderTitle,
                leading: const Icon(Icons.notifications_none_outlined),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.goNamed(RouteNames.reminderSettings),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Expanded(
            child: MxEmptyState(
              icon: Icons.settings_outlined,
              title: context.l10n.settingsPlaceholderTitle,
            ),
          ),
        ],
      ),
    );
  }
}
