import 'package:flutter/material.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_action_button.dart';
import '../../../domain/models/study_session_kind_model.dart';
import '../../../domain/models/study_session_status_model.dart';
import '../../../domain/models/study_session_summary_model.dart';

/// What the session came to, once it has ended.
///
/// **A session that stopped is not a session that finished.** The counts are the
/// same shape either way, and showing them under one heading turns "a write
/// failed and you lost your place" into "well done". So the heading comes from
/// [StudySessionSummaryModel.hasCompleted], and an early end says what happened
/// before it says how much got done.
///
/// **`learning` and `reviewing` report different numbers**, because they are
/// different questions. A learning session is measured by how many cards
/// finished the whole chain and became schedulable (BR-144); a review session by
/// how many cards it got through and how many it got wrong. Reporting both for
/// both would make one of the two numbers meaningless in each case.
class StudySummarySectionWidget extends StatelessWidget {
  const StudySummarySectionWidget({
    required this.summary,
    required this.onBackToDeck,
    super.key,
  });

  final StudySessionSummaryModel summary;
  final VoidCallback onBackToDeck;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          summary.hasCompleted
              ? l10n.studySummaryCompletedTitle
              : l10n.studySummaryStoppedTitle,
          style: context.texts.titleLarge,
          textAlign: TextAlign.center,
        ),
        if (_stoppedReason(context) case final String reason) ...<Widget>[
          const SizedBox(height: AppSpacing.sm),
          Text(
            reason,
            style: context.texts.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        Text(
          summary.kind == StudySessionKind.learning
              ? l10n.studySummaryLearned(summary.finishedCards)
              : l10n.studySummaryReviewed(summary.answeredCards),
          style: context.texts.bodyLarge,
          textAlign: TextAlign.center,
        ),
        if (summary.totalTurns > 0) ...<Widget>[
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.studySummaryWrong(summary.wrongTurns, summary.totalTurns),
            style: context.texts.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
        MxActionButton(
          label: l10n.studySummaryBackToDeck,
          onPressed: onBackToDeck,
        ),
      ],
    );
  }

  /// Why the session ended early, or null when it simply finished.
  ///
  /// Every reason of BR-80 that a user can be standing in front of gets a
  /// sentence. `interrupted` does not: a session closed because an earlier study
  /// day ended is closed before any screen opens, so nobody is here to read it.
  String? _stoppedReason(BuildContext context) => switch (summary.endReason) {
    StudySessionEndReason.userExit => context.l10n.studySummaryStoppedByExit,
    StudySessionEndReason.persistenceError =>
      context.l10n.studySummaryStoppedByError,
    StudySessionEndReason.schedulerReset ||
    StudySessionEndReason.staleGeneration =>
      context.l10n.studySummaryStoppedByReset,
    StudySessionEndReason.interrupted || null => null,
  };
}
