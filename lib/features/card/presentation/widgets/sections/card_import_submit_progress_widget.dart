import 'package:flutter/material.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_card.dart';

/// The one honest face of the commit (M4.12 state 5): a single indeterminate
/// loader, the count being written, and why the app must stay open.
///
/// Deliberately no determinate bar, no "29 of 47", no percentage: the write
/// is one atomic batch (BR-171) — there is no truthful per-card progress to
/// draw, and a fabricated one would be the first thing users learn to
/// distrust. This panel is also the *only* loader on screen; the action
/// bar's disabled "Importing…" label carries no second spinner.
class CardImportSubmitProgressWidget extends StatelessWidget {
  const CardImportSubmitProgressWidget({required this.count, super.key});

  /// How many cards the transaction is writing.
  final int count;

  @override
  Widget build(BuildContext context) {
    return MxCard(
      child: Column(
        children: <Widget>[
          const SizedBox(height: AppSpacing.md),
          Semantics(
            label: context.l10n.cardImportSubmittingLabel,
            child: const CircularProgressIndicator(),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            context.l10n.cardImportSubmittingTitle(count),
            style: context.texts.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            context.l10n.cardImportSubmittingBody,
            style: context.texts.bodyMedium?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}
