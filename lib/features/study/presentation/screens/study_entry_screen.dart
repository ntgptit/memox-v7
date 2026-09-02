import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/foundations/app_spacing.dart';
import '../../../../l10n/l10n_extension.dart';
import '../../../../shared/widgets/mx_async_view.dart';
import '../../../../shared/widgets/mx_content_shell.dart';
import '../../../../shared/widgets/mx_error_state.dart';
import '../../../../shared/widgets/mx_icon_button.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/study_session_entity.dart';
import '../../domain/failures/study_refusal_failure.dart';
import '../../domain/models/study_direction_model.dart';
import '../../domain/models/study_entry_summary_model.dart';
import '../../domain/models/study_mode.dart';
import '../../domain/models/study_review_options_model.dart';
import '../../domain/models/study_session_kind_model.dart';
import '../controllers/study_entry_controller.dart';
import '../controllers/study_resume_controller.dart';
import '../controllers/study_review_options_controller.dart';
import '../widgets/overlays/study_direction_chooser_widget.dart';
import '../widgets/overlays/study_mode_chooser_widget.dart';
import '../widgets/overlays/study_resume_widget.dart';
import '../widgets/sections/study_entry_section_widget.dart';
import 'study_options_screen.dart';
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
    actions: <Widget>[
      MxIconButton(
        icon: Icons.tune,
        semanticLabel: context.l10n.studyOptionsTitle,
        onPressed: () => unawaited(_openOptions(context)),
      ),
    ],
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
  /// answer, so `sm2` decks skip it entirely — and land instead on the direction
  /// question, which for those decks is the one real choice a review has
  /// (BR-203).
  Future<void> _chooseMode(
    BuildContext context,
    WidgetRef ref,
    StudyEntrySummaryModel summary,
  ) async {
    final options = await ref.read(studyReviewOptionsProvider(deckId).future);
    final modes = options.modes;
    if (modes.isEmpty || !context.mounted) return;
    if (modes.length == 1) {
      return _startReview(context, options: options, mode: modes.single);
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

    return _startReview(context, options: options, mode: chosen);
  }

  /// Starts a review in [mode], asking for a direction first when the deck's
  /// algorithm and the mode make that a real question (BR-203).
  ///
  /// **The eligibility question is the model's, not this screen's.** A widget
  /// spelling out "reviewing and sm2 and self_assess" is the copy that forgets a
  /// term, and the term it forgets is the one that puts a chooser in front of an
  /// `eight_box` deck.
  Future<void> _startReview(
    BuildContext context, {
    required StudyReviewOptionsModel options,
    required StudyMode mode,
  }) {
    if (!options.isDirectionChoiceRequiredFor(mode)) {
      return _open(context, kind: StudySessionKind.reviewing, reviewMode: mode);
    }

    return showModalBottomSheet<void>(
      context: context,
      // **Scroll-controlled, or the button that answers the question is off
      // screen.** Flutter caps an ordinary sheet at 9/16 of the display; at
      // 320dp with textScaler 2.0 this sheet's content is roughly 916dp against
      // that cap of 319, so `Start review` sat far below the fold with nothing
      // on Android saying there was more to scroll to.
      isScrollControlled: true,
      // **And a safe area, because the cap is gone.** The sheet's own
      // `SafeArea(top: false)` was written for a sheet Flutter stopped at
      // 9/16 of the display, which could never reach the top. Scroll-
      // controlled it can, and at 320dp × 2.0 it does — its 16dp top
      // padding is less than a modern cutout, so the title lost glyphs to
      // the status bar.
      useSafeArea: true,
      // The choice is locked for the session (BR-207), so it is confirmed rather
      // than taken on a tap — and a sheet that dismisses on a background tap
      // would still be dismissible, which is the correct way out of a question
      // the user has decided not to answer.
      builder: (sheetContext) => StudyDirectionChooserWidget(
        onSubmit: (direction) =>
            _startWithDirection(sheetContext, mode: mode, direction: direction),
      ),
    );
  }

  /// Confirms the review is still open to be started, then opens it.
  ///
  /// **The re-read is not ceremony, and it checks two things because UC-15 has
  /// two error flows.** The sheet has been on screen, and in that time a
  /// scheduler change or a Reset elsewhere can have taken `self_assess` away
  /// (E1, BR-13, BR-83) — or the last due card can have been answered, which
  /// BR-145 refuses (E2). Both used to reach the user the same wrong way: the
  /// sheet popped first, so the refusal surfaced as a full-screen error on the
  /// session screen, with the choice lost and no way back to it.
  ///
  /// The authoritative refusal still happens inside `openSession`'s transaction —
  /// this is the user-facing one, and it is what UC-15 promises.
  ///
  /// Returns null when the session was opened, and the failure otherwise — the
  /// chooser renders it and keeps the selection.
  Future<Object?> _startWithDirection(
    BuildContext sheetContext, {
    required StudyMode mode,
    required StudySessionDirection direction,
  }) async {
    try {
      ref
        ..invalidate(studyReviewOptionsProvider(deckId))
        ..invalidate(studyEntryProvider(deckId));

      final options = await ref.read(studyReviewOptionsProvider(deckId).future);
      if (!options.isDirectionChoiceRequiredFor(mode)) {
        return const ConflictFailure(
          message: 'This deck no longer offers that review',
          reason: StudyRefusalReason.modeNotSupportedByScheduler,
        );
      }

      final summary = await ref.read(studyEntryProvider(deckId).future);
      if (summary.dueCount <= 0) {
        return const ConflictFailure(
          message: 'Nothing to review',
          reason: StudyRefusalReason.nothingDueToReview,
        );
      }
    } on Object catch (error) {
      return error;
    }

    // The sheet outliving this await is the ordinary case; it going away is the
    // user having dismissed it, and there is then nothing to report to.
    if (!mounted || !sheetContext.mounted) return null;

    Navigator.of(sheetContext).pop();
    if (!mounted) return null;

    await _open(
      context,
      kind: StudySessionKind.reviewing,
      reviewMode: mode,
      direction: direction,
    );

    return null;
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

    /// The recall direction chosen for this session (BR-203). Null for every
    /// path the rule does not cover, and for a resume (BR-207).
    StudySessionDirection? direction,
    bool shouldResume = false,
  }) async {
    _refresh();

    // **The root navigator, so the session is the whole screen.** Pushed on the
    // branch navigator it sat inside the shell and kept the bottom bar, which
    // offers two ways out of a session that BR-82 says has exactly one: the ✕,
    // which ends it as `abandoned`/`user_exit`. A tab switch left the session
    // open and the app then offered to resume something the user thought they
    // had walked away from.
    await Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<void>(
        builder: (_) => StudySessionScreen(
          deckId: deckId,
          kind: kind,
          reviewMode: reviewMode,
          direction: direction,
          shouldResume: shouldResume,
        ),
      ),
    );

    if (!mounted) return;
    _refresh();
  }

  /// Opens the options, and re-reads on the way back.
  ///
  /// The card limit is one of the two numbers this screen is about, so coming
  /// back from changing it to a screen still showing the old one would be the
  /// same disagreement as returning from a session — see [_open].
  Future<void> _openOptions(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => StudyOptionsScreen(deckId: deckId),
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
