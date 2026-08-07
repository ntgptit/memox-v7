import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/l10n_extension.dart';
import '../../../../shared/widgets/mx_async_view.dart';
import '../../../../shared/widgets/mx_content_shell.dart';
import '../../../../shared/widgets/mx_error_state.dart';
import '../../../deck/domain/models/scheduler_type_model.dart';
import '../../di/study_repository_provider.dart';
import '../../domain/models/study_entry_summary_model.dart';
import '../../domain/models/study_mode.dart';
import '../../domain/models/study_scheduler.dart';
import '../../domain/models/study_session_kind_model.dart';
import '../controllers/study_entry_controller.dart';
import '../widgets/overlays/study_mode_chooser_widget.dart';
import '../widgets/sections/study_entry_section_widget.dart';
import 'study_session_screen.dart';

/// The way into a deck's study flow.
///
/// Replaces the placeholder that stood here since M3. It shows the two counts of
/// BR-150, and offers only the ways in that are actually open: with nothing due,
/// there is no review entry at all (BR-29, BR-145).
class StudyEntryScreen extends ConsumerWidget {
  const StudyEntryScreen({required this.deckId, super.key});

  final String deckId;

  @override
  Widget build(BuildContext context, WidgetRef ref) => MxContentShell(
    title: context.l10n.appTitle,
    body: Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: MxAsyncView<StudyEntrySummaryModel>(
        value: ref.watch(studyEntryProvider(deckId)),
        loadingLabel: context.l10n.appTitle,
        error: (_, _) => MxErrorState(
          title: context.l10n.appTitle,
          message: context.l10n.studyNothingDueMessage,
        ),
        data: (summary) => StudyEntrySectionWidget(
          summary: summary,
          onLearn: () => _open(context, kind: StudySessionKind.learning),
          onReview: () => unawaited(_chooseMode(context, ref, summary)),
        ),
      ),
    ),
  );

  /// Opens the chooser, or goes straight in when there is only one mode.
  ///
  /// BR-146: with a single available mode the chooser is a question with one
  /// answer, so `sm2` decks skip it entirely.
  Future<void> _chooseMode(
    BuildContext context,
    WidgetRef ref,
    StudyEntrySummaryModel summary,
  ) async {
    final scheduler = schedulerFor(await _schedulerTypeOf(ref));
    if (scheduler == null || !context.mounted) return;

    final modes = scheduler.reviewModes;
    if (modes.length == 1) {
      return _open(
        context,
        kind: StudySessionKind.reviewing,
        reviewMode: modes.single,
      );
    }

    final chosen = await showModalBottomSheet<StudyMode>(
      context: context,
      builder: (sheetContext) => StudyModeChooserWidget(
        modes: modes,
        summary: summary,
        onModeSelected: (mode) => Navigator.of(sheetContext).pop(mode),
      ),
    );

    if (chosen == null || !context.mounted) return;

    return _open(context, kind: StudySessionKind.reviewing, reviewMode: chosen);
  }

  Future<SchedulerType> _schedulerTypeOf(WidgetRef ref) async {
    final context = await ref.read(studyRepositoryProvider).deckContext(deckId);

    return context.schedulerType;
  }

  void _open(
    BuildContext context, {
    required StudySessionKind kind,
    StudyMode? reviewMode,
  }) {
    unawaited(
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => StudySessionScreen(
            deckId: deckId,
            kind: kind,
            reviewMode: reviewMode,
          ),
        ),
      ),
    );
  }
}
