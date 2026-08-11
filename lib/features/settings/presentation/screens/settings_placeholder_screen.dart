import 'package:flutter/material.dart';

import '../../../../l10n/l10n_extension.dart';
import '../../../../shared/widgets/mx_content_shell.dart';
import '../../../../shared/widgets/mx_empty_state.dart';

/// The Settings branch, before any setting exists.
///
/// **Presentation-only, and deliberately so** (AD-19). There is no preference
/// to persist and no domain to fake — the MVP has one local profile and no
/// options — so this screen holds no provider, no storage and no controls. The
/// branch exists for the contract: `/settings` is a stable deep link, the tab
/// keeps its own stack, and the real screen replaces this one without touching
/// the router or the shell.
///
/// No action button, for the same reason as the Progress placeholder: "not
/// built yet" is the whole message, and a control that repeats it is noise.
class SettingsPlaceholderScreen extends StatelessWidget {
  const SettingsPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MxContentShell(
      title: context.l10n.settingsTitle,
      body: MxEmptyState(
        icon: Icons.settings_outlined,
        title: context.l10n.settingsPlaceholderTitle,
      ),
    );
  }
}
