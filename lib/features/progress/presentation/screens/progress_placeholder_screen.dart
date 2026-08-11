import 'package:flutter/material.dart';

import '../../../../l10n/l10n_extension.dart';
import '../../../../shared/widgets/mx_content_shell.dart';
import '../../../../shared/widgets/mx_empty_state.dart';

/// The Progress branch, before the progress feature exists.
///
/// **Presentation-only, and deliberately so** (AD-19). It reads no provider,
/// opens no repository and writes nothing: statistics have no business rules
/// yet, and a screen that invented some would be a spec written in the wrong
/// layer. What the branch buys today is the contract around it — `/progress`
/// is a stable deep link and the tab keeps its own navigation stack — so the
/// real feature lands inside a frame nothing else has to move for.
///
/// No action button: the honest state is "not built yet", and a control that
/// only says so again is noise. The copy carries the one fact a learner needs —
/// study activity is already being recorded, so nothing is lost by waiting.
class ProgressPlaceholderScreen extends StatelessWidget {
  const ProgressPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MxContentShell(
      title: context.l10n.progressTitle,
      body: MxEmptyState(
        icon: Icons.insights_outlined,
        title: context.l10n.progressPlaceholderTitle,
        message: context.l10n.progressPlaceholderMessage,
      ),
    );
  }
}
