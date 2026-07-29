import 'package:flutter/material.dart';

import '../../../l10n/l10n_extension.dart';
import '../../../shared/widgets/mx_empty_state.dart';
import '../../../shared/widgets/mx_content_shell.dart';

/// The review feature's entry surface until the real session screen exists.
///
/// Structural anchor for `features/review/presentation/`, and the app's home:
/// review is the only feature in the MVP, so the placeholder belongs to it
/// rather than to the app shell. M5.4 replaces this with the real session
/// screen; the route into it is wired in M4.1.
///
/// It is built from the shared components rather than raw widgets, which is
/// what proves those components work end to end before a real screen depends
/// on them. All copy comes from ARB.
class ReviewPlaceholderScreen extends StatelessWidget {
  const ReviewPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MxContentShell(
      title: context.l10n.appTitle,
      body: MxEmptyState(title: context.l10n.homePlaceholderMessage),
    );
  }
}
