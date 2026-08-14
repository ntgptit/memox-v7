import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/l10n_extension.dart';
import '../../../../shared/widgets/mx_content_shell.dart';
import '../../../../shared/widgets/mx_empty_state.dart';
import '../../../../shared/widgets/mx_error_state.dart';
import '../../../../shared/widgets/mx_loading_state.dart';
import '../../domain/models/study_direction_model.dart';
import '../../domain/models/study_mode.dart';
import '../../domain/models/study_session_kind_model.dart';
import '../../domain/models/study_turn_model.dart';
import '../controllers/study_browse_trail_controller.dart';
import '../controllers/study_session_controller.dart';
import '../controllers/study_session_summary_controller.dart';
import '../states/study_session_state.dart';
import '../../domain/models/recall_mode.dart';
import '../widgets/sections/study_blocked_section_widget.dart';
import '../widgets/sections/study_session_frame_section_widget.dart';
import '../widgets/sections/study_summary_section_widget.dart';
import '../widgets/support/study_mode_feedback_widget.dart';
import '../widgets/support/study_labels_widget.dart';
import '../widgets/support/study_mode_view_widget.dart';

/// One study session, from the first card to the last.
///
/// **The screen owns no rule.** Which card comes next, which stage follows, when
/// the session ends — the controller asks use cases and this renders what comes
/// back. What it does own is the one thing only a screen can: turning a stage
/// into the widget that shows it.
class StudySessionScreen extends ConsumerStatefulWidget {
  const StudySessionScreen({
    required this.deckId,
    required this.kind,
    this.reviewMode,
    this.direction,
    this.shouldResume = false,
    super.key,
  });

  final String deckId;
  final StudySessionKind kind;

  /// The recall direction chosen at the entry point (BR-182).
  ///
  /// Null for every session outside the rule, and for a resume — which reads the
  /// direction the session already carries rather than being told one (BR-186).
  final StudySessionDirection? direction;

  /// Continue the session already open for this deck, rather than opening a new
  /// one (BR-103). [kind] and [reviewMode] are then the resumed session's own,
  /// passed for the title before the load returns.
  final bool shouldResume;

  /// The mode the user chose, for a review session (BR-109). Null for a
  /// learning session, which walks the algorithm's whole sequence.
  final StudyMode? reviewMode;

  @override
  ConsumerState<StudySessionScreen> createState() => _StudySessionScreenState();
}

class _StudySessionScreenState extends ConsumerState<StudySessionScreen> {
  /// What is left of a `recall` turn, for the frame's top bar (§7.3).
  ///
  /// **A notifier rather than screen state.** The clock ticks at 10Hz; putting
  /// it in `setState` would rebuild the body with it, and a body that re-deals
  /// its board ten times a second moves the answer under the user's finger.
  /// Only the figure listens.
  final ValueNotifier<Duration> _recallRemaining = ValueNotifier<Duration>(
    kRecallTurnLimit,
  );

  @override
  void dispose() {
    _recallRemaining.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    // After the first frame: `start` writes state, and writing a provider during
    // a build is what Riverpod forbids.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(
        ref
            .read(studySessionControllerProvider(widget.deckId).notifier)
            .start(
              kind: widget.kind,
              reviewMode: widget.reviewMode,
              direction: widget.direction,
              shouldResume: widget.shouldResume,
            ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // **Said once, when it happens** (BR-82). A recoverable failure has to be
    // *told*, not merely survived: the ✕ did nothing visible, and a screen that
    // simply carries on reads as a dead button. The bar offers the one action
    // that makes sense — try again — and dismissing it leaves the user studying,
    // which is the other honest option.
    ref.listen(studySessionControllerProvider(widget.deckId), (previous, next) {
      if (next.error == null || next.turn == null) return;
      if (previous?.error == next.error) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(context.l10n.studyLeaveFailed),
            action: SnackBarAction(
              label: context.l10n.retryAction,
              onPressed: () => unawaited(_controller.leave()),
            ),
          ),
        );
    });

    final state = ref.watch(studySessionControllerProvider(widget.deckId));

    final session = state.session;

    // The frame is the five screens' shared chrome, and it needs a session to
    // say anything at all — before one opens there is no mode, no deck name and
    // no round to count. The transient states below draw without it rather than
    // drawing a frame full of blanks.
    final body = _body(state);
    final turn = state.turn;

    return PopScope(
      // **The other back arrow, and it took a device to find it.** Removing the
      // app bar closed one door — see the comment below — and left the one the
      // operating system opens: Android's back gesture popped the route and
      // left `study_sessions.status` at `in_progress`, which is precisely what
      // BR-82 forbids. Nothing on a host notices, because a host has no
      // gesture; `IT-PLAT-005` is the scenario that does.
      //
      // Refusing the pop rather than ending on the way out, because the ✕ does
      // not pop either: it ends the session and hands over the summary, and a
      // back gesture that skipped the summary would be a second, quieter
      // contract for the same action. Once the session is finished the screen
      // pops normally — the summary's own Back to deck is that pop.
      canPop: session == null || state.isFinished,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        unawaited(_controller.leave());
      },
      child: MxContentShell(
        // No app-bar title, and therefore no app bar at all: the frame's own top
        // bar carries the mode and the ✕, and a Material bar above it would be a
        // second bar naming the same screen — with a back arrow that pops the
        // route and leaves the session open, which is the one thing BR-82
        // forbids.
        //
        // **No gutter from the shell, and the frame applies its own.** The
        // session's top bar puts a 48×48 close button first; inside a 16px gutter
        // its glyph lands at 30 while the counter at the other end stops at the
        // gutter, and a row inset differently at each end reads as off-centre.
        // The bar therefore needs a region that starts at the safe-area edge, the
        // way `AppBar` gives its leading icon one. `EdgeInsets.zero` here, and
        // `StudySessionFrameSectionWidget` gutters the context line, the body and
        // the hint itself — from `mxScreenGutter`, so 320 still gets 12.
        padding: EdgeInsets.zero,
        body: session == null || turn == null || state.isFinished
            // The transient states draw without the frame, so nothing has
            // guttered them — they get it here rather than inheriting an
            // edge-to-edge region meant for one bar.
            ? Padding(
                padding: EdgeInsets.all(mxScreenGutter(context)),
                child: body,
              )
            : StudySessionFrameSectionWidget(
                mode: session.currentMode,
                kind: session.kind,
                cardCount: state.sessionCards.length,
                progress: turn.progress,
                timeLeft: session.currentMode == StudyMode.recall
                    ? _recallRemaining
                    : null,
                onClose: () => unawaited(_controller.leave()),
                // BR-155: the chrome keeps describing the live turn, so the one
                // line that speaks to the user has to say the card under it is
                // not that turn.
                hintOverride: _hintOverrideFor(
                  turn,
                  mode: session.currentMode,
                  isLookingBack: state.isLookingBackAt(
                    ref.watch(
                      studyBrowseTrailControllerProvider(widget.deckId),
                    ),
                  ),
                ),
                child: body,
              ),
      ),
    );
  }

  /// Which turn the body has finished asking about, if any (§8.11).
  ///
  /// **A key rather than a flag.** A boolean has to be cleared when the card
  /// changes, and the place that clears it is a second place that has to know
  /// what a new turn looks like. Comparing keys means a stale value is simply
  /// not the current turn, and answers itself.
  String? _resolvedTurnKey;

  /// One turn, named by the pair that makes it one: a round serves each card
  /// once, and the next round serves some of them again.
  static String _turnKey(StudyTurnModel turn) =>
      '${turn.item.round}:${turn.cardId}';

  /// The notifier, read at the moment a callback fires rather than during a
  /// build.
  ///
  /// `ref.read` inside `build()` takes a value without subscribing, which is
  /// how a screen ends up showing state it will never be told has changed —
  /// the guard rule `no_ref_read_in_build` exists for exactly that, and it
  /// caught this.
  StudySessionController get _controller =>
      ref.read(studySessionControllerProvider(widget.deckId).notifier);

  /// `browse`'s trail, which owns the offset rather than the queue (BR-155).
  StudyBrowseTrailController get _trail =>
      ref.read(studyBrowseTrailControllerProvider(widget.deckId).notifier);

  /// What replaces the mode’s usual hint, if anything.
  ///
  /// Two callers, in order. `browse` is looking back along its trail (BR-155):
  /// the counter and the bar still describe the live turn, so without a word
  /// here a card the user has already passed reads as the session having gone
  /// backwards. Otherwise, a body that has stopped asking says so (§8.11).
  String? _hintOverrideFor(
    StudyTurnModel turn, {
    required StudyMode mode,
    required bool isLookingBack,
  }) {
    if (isLookingBack) return context.l10n.studyBrowseLookingBack;
    if (_resolvedTurnKey != _turnKey(turn)) return null;

    return context.studyModeHintResolved(mode);
  }

  Widget _body(StudySessionState state) {
    // **An error with a card behind it is recoverable, and replacing the card
    // is what made it look otherwise.** A failed `EndStudySession` left the
    // session running with its turn intact, and this branch swapped the whole
    // body for "Nothing to review yet" — a message about an empty deck, shown
    // over a card the user could still answer. The full-body state is for the
    // case it was written for: an error with nothing to fall back on.
    //
    // A persistence failure on a *write* still lands here, because it ends the
    // session (BR-85) and so clears the turn — that behaviour is untouched.
    if (state.error != null && state.turn == null) {
      return MxErrorState(
        title: context.l10n.appTitle,
        message: context.l10n.studyNothingDueMessage,
      );
    }
    if (state.isOpening) {
      return MxLoadingState(semanticsLabel: context.l10n.appTitle);
    }
    // **Nothing is unmounted to fetch its replacement.** Advancing used to
    // replace the whole body, so every mode threw its card away, drew a
    // spinner and drew the next card — a full layout shift between two cards
    // that differ by one string, and, worse, the frame in which the answer the
    // user had just given was supposed to be readable. `browse` was exempted
    // from it first; the exemption was the right behaviour and the wrong
    // scope. The turn now stays in state for the whole fetch, and every mode
    // locks its own input while `isAdvancing` is true.
    //
    // A full-body loading state is left with one case, and it is the case
    // below: a session whose first read has not come back. Removing the
    // `isAdvancing` branch without adding this one turned the first moment of
    // every session into `StudyBlockedSectionWidget` — `studyModeView` returns
    // null with no turn, and the screen reads that as "this stage cannot build
    // content". Only the device suite saw it: on a host the first read resolves
    // inside the same frame the session opens in.
    if (state.isFinished) {
      // **Watched, not held.** The epilogue is a read the screen makes once the
      // session is over, so it belongs to a provider rather than to a field the
      // controller has to remember to fill from three places — one of them a
      // failure path, where forgetting shows the previous session's numbers.
      //
      // No summary means the read failed, not that nothing happened: the
      // session has ended either way, and inventing counts for it would be
      // worse than saying only that.
      return ref
          .watch(studySessionSummaryProvider(widget.deckId))
          .maybeWhen(
            data: (summary) => summary == null
                ? MxEmptyState(title: context.l10n.studySessionFinished)
                : StudySummarySectionWidget(
                    summary: summary,
                    onBackToDeck: () => Navigator.of(context).pop(),
                  ),
            orElse: () => MxLoadingState(semanticsLabel: context.l10n.appTitle),
          );
    }

    final session = state.session;
    if (session == null || state.turn == null) {
      return MxLoadingState(semanticsLabel: context.l10n.appTitle);
    }

    final trail = ref.watch(studyBrowseTrailControllerProvider(widget.deckId));
    final view = studyModeView(
      mode: session.currentMode,
      state: state,
      // The body knows when it has stopped asking; the frame owns the line that
      // says what to do next (§8.11). Keyed by the turn rather than reset on a
      // change, so there is no second place that has to notice a new card.
      onResolved: () {
        final resolved = state.turn;
        if (resolved == null) return;
        setState(() => _resolvedTurnKey = _turnKey(resolved));
      },
      onRecallTick: (remaining) => _recallRemaining.value = remaining,
      // BR-133's write half. The clock stops when the app goes to the
      // background (BR-128); without this the seconds it stopped at are lost
      // and the turn starts over at twenty the next time it is served — which
      // is the whole reason `remaining_ms` is a column.
      onRecallSuspend: ({required remaining, required isRevealed}) => unawaited(
        _controller.pause(
          remainingMs: remaining.inMilliseconds,
          isRevealed: isRevealed,
        ),
      ),
      // **Write, let the mode draw the answer, then move** — three steps, and
      // the screen owns the first and the last. The middle one belongs to the
      // mode, because only it knows when its verdict actually became visible:
      // a hold measured from the tap spends itself on the transaction, and one
      // measured from the write starts before anything is drawn (BR-157, §8.12).
      onAnswer:
          (action, {cardId, outcomeReason, comparisonVersion, hasUsedHint}) =>
              _controller.submitAnswer(
                action,
                cardId: cardId,
                outcomeReason: outcomeReason,
                comparisonVersion: comparisonVersion,
                usedHint: hasUsedHint,
              ),
      onFeedbackShown: ({required isCorrect}) => _controller.advance(
        minimumVisible: studyModeFeedback(
          session.currentMode,
        ).of(isCorrect: isCorrect),
      ),
      // `browse` grades nothing, so moving on is the whole interaction
      // (BR-111). The controller decides whether that means marking the card
      // browsed or stepping forward along the trail the user has swiped back
      // along — a screen that decided it would be the thing marking a card
      // browsed twice (BR-155).
      //
      // **`match` is the one mode that answers more than once per turn**, so it
      // writes and advances on its own schedule: a pair per write, and the
      // fetch only after the last pair of a board.
      onMatchAttempt: ({required cardId, required action}) =>
          _controller.submitAnswer(action, cardId: cardId),
      onMatchBoardComplete: _controller.advance,
      browseLookBack: trail,
      onContinue: () => unawaited(_trail.step(StudyBrowseStep.forward)),
      onLookBack: () => unawaited(_trail.step(StudyBrowseStep.back)),
    );

    // BR-124's blocking case, and it is **not** the finished state.
    //
    // A stage that cannot run at all no longer reaches here: `canRunOn` keeps it
    // out of the queue, so the session skips it (BR-99). What is left is one
    // card the stage could not build content for — no turn is written, the card
    // is not skipped, and the session therefore cannot move on by itself.
    //
    // It used to render `SizedBox.shrink()`, which is a blank screen: nothing to
    // read, nothing to tap, and force-quitting the only way out. Saying what
    // happened and offering to leave is the difference between a rule being
    // enforced and a rule being enforced silently.
    return view ??
        StudyBlockedSectionWidget(
          onLeave: () => unawaited(_controller.leave()),
        );
  }
}
