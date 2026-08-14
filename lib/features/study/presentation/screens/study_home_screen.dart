import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/route_names.dart';
import '../../../../l10n/l10n_extension.dart';
import '../../../../shared/widgets/mx_async_view.dart';
import '../../../../shared/widgets/mx_content_shell.dart';
import '../../../../shared/widgets/mx_error_state.dart';
import '../../domain/models/study_home_deck_model.dart';
import '../../domain/models/study_home_model.dart';
import '../../domain/models/study_home_resume_model.dart';
import '../controllers/study_home_controller.dart';
import '../widgets/sections/study_home_body_section_widget.dart';
import 'study_session_screen.dart';

/// The Study tab (UC-12).
///
/// **It replaced a fixture.** The branch pointed at `kStudyBranchDeckId` — a
/// constant naming a row the development seeder happened to write — so the tab
/// showed one hard-coded deck to every user and, in any database that never had
/// that row, a study entry for a deck that did not exist. Nothing here names a
/// deck: the list is the library.
///
/// **Read-only until a tap** (BR-182, BR-101). Opening the tab, scrolling it and
/// switching away write nothing — not a session, not a scheduler lock, not a
/// materialised queue. That is a property of the wiring rather than a rule to
/// remember: the controller behind this screen reads `StudyHomeRepository`,
/// which has no method that writes. The two actions on the screen are the only
/// paths onward, and both need a finger.
///
/// **The two actions are different things and go to different places.** Resume
/// continues the session that is already open, so it opens the session screen
/// directly on the persisted turn (BR-103, BR-133) — it never creates a second
/// session. Study opens the deck's entry screen, where the choice between
/// learning and reviewing is made (BR-142, BR-146).
class StudyHomeScreen extends ConsumerStatefulWidget {
  const StudyHomeScreen({super.key});

  @override
  ConsumerState<StudyHomeScreen> createState() => _StudyHomeScreenState();
}

class _StudyHomeScreenState extends ConsumerState<StudyHomeScreen> {
  /// Whether a navigation started here is still in flight.
  ///
  /// **The double-tap guard, and it is not cosmetic.** Two taps land inside one
  /// frame easily on a slow device, and two pushes of the session screen would
  /// be two `StudySessionScreen`s each running `start()` on the same deck —
  /// which for the Study action is two `openSession` calls, and BR-101 says a
  /// session exists because the user asked for one, not two.
  ///
  /// A plain field rather than state: nothing on screen changes while it is set,
  /// and `setState` here would rebuild the list for a flag no widget reads.
  bool _isNavigating = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return MxContentShell(
      title: l10n.studyHomeTitle,
      // The body owns its gutters: the list is one scroll view and must run
      // edge to edge under the app-bar hairline.
      padding: EdgeInsets.zero,
      body: MxAsyncView<StudyHomeModel>(
        value: ref.watch(studyHomeProvider),
        loadingLabel: l10n.studyHomeLoadingLabel,
        // **Both flags, because two different things re-open this read.** A new
        // emission from the same stream — a session ending, a card answered —
        // is a *refresh*, and `skipLoadingOnRefresh` keeps the populated tab on
        // screen. Coming back to the foreground or crossing a due boundary
        // moves `studyHomeNowProvider`, which this stream watches, and that is a
        // *reload*: with the shared default the whole tab became a spinner and
        // the list lost its scroll offset, for a re-read that answers the same
        // question one instant later. The previous snapshot is the honest thing
        // to show while it lands.
        shouldSkipLoadingOnReload: true,
        // **No gutter of its own.** `MxErrorState` already centres itself
        // inside `AppSpacing.xl`, exactly as `MxEmptyState` does — and the two
        // appear on this same screen. Wrapping this one in the screen gutter as
        // well inset it to 40 against the empty states' 24, which at 320dp with
        // large text cost the error copy 24dp of width for nothing. Every other
        // `MxErrorState` call site in `lib/features/` passes it bare.
        error: (_, _) => MxErrorState(
          title: l10n.studyHomeErrorTitle,
          message: l10n.studyHomeErrorMessage,
          retryLabel: l10n.retryAction,
          // `invalidate`, not `refresh`: the retry wants a read from scratch and
          // nothing here needs the value as a return — the rebuild reads it
          // anyway.
          onRetry: () => ref.invalidate(studyHomeProvider),
        ),
        data: (home) => StudyHomeBodySectionWidget(
          home: home,
          // Only reachable when the snapshot carries one; the body does not
          // build the card otherwise.
          onResume: () => unawaited(_resume(home.resume)),
          onStudy: _study,
          onStarterLibrary: () => _go(RouteNames.starterLibrary),
          onOpenLibrary: () => _go(RouteNames.decks),
        ),
      ),
    );
  }

  /// Continues the open session, on the persisted turn (BR-103, BR-133).
  ///
  /// **The root navigator, so the session is the whole screen.** Pushed on the
  /// branch navigator it would sit inside the shell and keep the bottom bar,
  /// which offers a second way out of a session BR-82 gives exactly one — and a
  /// tab switch would leave the session open, so the app would then offer to
  /// resume something the user thought they had walked away from. This is the
  /// same push `StudyEntryScreen` makes, for the same reason.
  ///
  /// `shouldResume: true` routes the open through `ResumeStudySessionUseCase`,
  /// which reads the session that is there. [StudyHomeResumeModel.kind] and
  /// `currentMode` ride along only so the frame can name the stage before that
  /// read returns.
  Future<void> _resume(StudyHomeResumeModel? resume) async {
    if (resume == null || _isNavigating) return;
    _isNavigating = true;

    // `finally`, for the reason `_navigate` registers its release first: a push
    // that throws would otherwise leave the flag set and every button on this
    // screen dead until the tab is left. Held for the whole push rather than a
    // frame, because this one *can* be — a push returns a future to wait on.
    try {
      await Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute<void>(
          builder: (_) => StudySessionScreen(
            deckId: resume.deckId,
            kind: resume.kind,
            reviewMode: resume.currentMode,
            shouldResume: true,
            // **The id, not just the deck.** Resolving by deck asks "which
            // session is open here" and answers with the newest — a different
            // question from "the session on the card that was tapped". A second
            // session opened later on the same deck, or one an earlier study day
            // left behind, both answer the first and neither is what the tap
            // meant (BR-182, BR-103).
            resumeSessionId: resume.sessionId,
          ),
        ),
      );
    } finally {
      if (mounted) _isNavigating = false;
    }

    // No manual refresh on the way back. The stream under this screen watches
    // the session tables, so a session that ended has already moved the counts
    // and taken the Resume card with it — invalidating here would re-read what
    // the stream has delivered.
  }

  /// Opens one root deck's study entry, inside the Study branch.
  ///
  /// By **name**, to the route nested under `/study`: Back returns to this list
  /// rather than to whatever the Library tab last held, and the bottom bar
  /// stays.
  void _study(StudyHomeDeckModel deck) => _navigate(
    () => context.goNamed(
      RouteNames.studyDeck,
      pathParameters: <String, String>{RoutePathParams.deckId: deck.deckId},
    ),
  );

  void _go(String routeName) => _navigate(() => context.goNamed(routeName));

  /// Runs one `go` call at most once per frame.
  ///
  /// **The release is registered before the call, not after it.** Written the
  /// other way round, a `goNamed` that threw — an unregistered name, a missing
  /// path parameter — skipped the line that clears the flag, and every button on
  /// the screen stayed dead for as long as it was open, with no way back short
  /// of leaving the tab. Neither throw is reachable today; the ordering costs
  /// nothing and stops the class of failure rather than the instance.
  ///
  /// Released on the next frame rather than on a return: `goNamed` hands back no
  /// future, and holding the guard until this screen is disposed would make a
  /// Back that lands here find every button inert.
  ///
  /// **What this covers, precisely:** two taps inside one frame. Taps further
  /// apart do get through it — and open nothing extra, because `go` to a
  /// location already current replaces the same match list rather than pushing a
  /// second route. So BR-182's "two taps lead to one open" holds either way; the
  /// guard closes the same-frame half, and `study_home_widget_test.dart` asserts
  /// both halves rather than only the one the guard owns.
  void _navigate(VoidCallback go) {
    if (_isNavigating) return;
    _isNavigating = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _isNavigating = false;
    });

    go();
  }
}
