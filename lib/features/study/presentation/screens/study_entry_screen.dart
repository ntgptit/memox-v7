import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/l10n_extension.dart';
import '../../../../shared/widgets/mx_async_view.dart';
import '../../../../shared/widgets/mx_content_shell.dart';
import '../../../../shared/widgets/mx_error_state.dart';
import '../../domain/entities/study_session_entity.dart';
import '../../domain/models/study_entry_summary_model.dart';
import '../../domain/models/study_mode.dart';
import '../../domain/models/study_session_kind_model.dart';
import '../controllers/study_entry_controller.dart';
import '../controllers/study_resume_controller.dart';
import '../controllers/study_review_modes_controller.dart';
import '../widgets/overlays/study_mode_chooser_widget.dart';
import '../widgets/overlays/study_resume_widget.dart';
import '../widgets/sections/study_entry_section_widget.dart';
import 'study_session_screen.dart';

/// The way into a deck's study flow.
///
/// Replaces the placeholder that stood here since M3. It shows the two counts of
/// BR-150, and offers only the ways in that are actually open: with nothing due,
/// there is no review entry at all (BR-29, BR-145).
class StudyEntryScreen extends ConsumerStatefulWidget {
  const StudyEntryScreen({required this.deckId, super.key});

  final String deckId;

  @override
  ConsumerState<StudyEntryScreen> createState() => _StudyEntryScreenState();
}

class _StudyEntryScreenState extends ConsumerState<StudyEntryScreen> {
  String get deckId => widget.deckId;

  @override
  void initState() {
    super.initState();

    // After the first frame, because reading the resume controller closes any
    // session left by an earlier study day, and a write during build is what
    // Riverpod forbids.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => unawaited(_offerResume()),
    );
  }

  /// Offers the three paths, and only when there is something to resume.
  ///
  /// **Nothing open means nothing is shown** — not an empty sheet, not a sheet
  /// with one button. The other two paths already live on this screen, so a
  /// sheet with no session to continue would be a second copy of the screen
  /// behind it.
  ///
  /// Learning and reviewing go through the ordinary path from here. Ending the
  /// open session is not done at this call site on purpose: it lives inside
  /// `StartStudySessionUseCase`, where no caller can forget it (BR-103).
  Future<void> _offerResume() async {
    final open = await _openSession();
    if (open == null || !mounted) return;

    final choice = await showModalBottomSheet<StudyResumeChoice>(
      context: context,
      builder: (sheetContext) => StudyResumeWidget(
        onChoice: (value) => Navigator.of(sheetContext).pop(value),
      ),
    );
    if (choice == null || !mounted) return;

    switch (choice) {
      case StudyResumeChoice.resume:
        await _open(
          context,
          kind: open.kind,
          reviewMode: open.currentMode,
          shouldResume: true,
        );
      case StudyResumeChoice.learn:
        await _open(context, kind: StudySessionKind.learning);
      case StudyResumeChoice.review:
        final summary = await ref.read(studyEntryProvider(deckId).future);
        if (!mounted) return;
        await _chooseMode(context, ref, summary);
    }
  }

  /// The open session, or null when there is none — **and also when the read
  /// failed**.
  ///
  /// Not a swallowed error: the counts on this screen come from the same
  /// repository through `MxAsyncView`, so a storage failure is already on
  /// screen as an error state. What this catch prevents is a sheet thrown on
  /// top of that error, offering to continue a session nobody could read. The
  /// two other paths stay correct either way, because ending the open session
  /// happens inside `StartStudySessionUseCase`, not here.
  Future<StudySessionEntity?> _openSession() async {
    try {
      return await ref.read(studyResumeProvider(deckId).future);
    } on Object {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) => MxContentShell(
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
          onLearn: () =>
              unawaited(_open(context, kind: StudySessionKind.learning)),
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
    final modes = await ref.read(studyReviewModesProvider(deckId).future);
    if (modes.isEmpty || !context.mounted) return;
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

  /// Opens a session, and refreshes this screen on both sides of it.
  ///
  /// **Before**, because both reads describe the deck as it stands *now*:
  /// leaving them cached would let a later visit offer to continue a session
  /// this one just ended, and the resume would fail on a session the database
  /// no longer has.
  ///
  /// **After**, because a session is exactly the thing that changes them. Coming
  /// back from finishing four cards to a screen still saying three are new is
  /// the summary and the counts disagreeing about the same minute — and the
  /// summary is the one that just told the truth.
  Future<void> _open(
    BuildContext context, {
    required StudySessionKind kind,
    StudyMode? reviewMode,
    bool shouldResume = false,
  }) async {
    _refresh();

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => StudySessionScreen(
          deckId: deckId,
          kind: kind,
          reviewMode: reviewMode,
          shouldResume: shouldResume,
        ),
      ),
    );

    if (!mounted) return;
    _refresh();
  }

  void _refresh() {
    ref.invalidate(studyResumeProvider(deckId));
    ref.invalidate(studyEntryProvider(deckId));
  }
}
