import 'package:flutter/material.dart';

import '../../../../l10n/l10n_extension.dart';
import '../../../../shared/widgets/mx_content_shell.dart';
import '../../../../shared/widgets/mx_empty_state.dart';

/// The study feature's entry surface until the real session screen exists.
///
/// Branch 1 of the navigation shell. It is no longer the app's home — that is
/// the deck list (M4.10) — but it is a reachable destination with a tab of its
/// own, so it is a production screen and is held to MX-VIS-001 like any other.
/// M5.4 replaces it with the real session screen.
///
/// It is built from the shared components rather than raw widgets, which is
/// what proves those components work end to end before a real screen depends
/// on them. All copy comes from ARB.
class StudyPlaceholderScreen extends StatelessWidget {
  const StudyPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MxContentShell(
      title: context.l10n.appTitle,
      body: MxEmptyState(title: context.l10n.studyPlaceholderMessage),
    );
  }
}
