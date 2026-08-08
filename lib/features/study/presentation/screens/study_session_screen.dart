import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/l10n_extension.dart';
import '../../../../shared/widgets/mx_content_shell.dart';
import '../../../../shared/widgets/mx_empty_state.dart';
import '../../../../shared/widgets/mx_error_state.dart';
import '../../../../shared/widgets/mx_loading_state.dart';
import '../../domain/models/study_mode.dart';
import '../../domain/models/study_session_kind_model.dart';
import '../controllers/study_session_controller.dart';
import '../states/study_session_state.dart';
import '../../domain/models/recall_mode.dart';
import '../widgets/sections/study_blocked_section_widget.dart';
import '../widgets/sections/study_session_frame_section_widget.dart';
import '../widgets/sections/study_summary_section_widget.dart';
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
    this.shouldResume = false,
    super.key,
  });

  final String deckId;
  final StudySessionKind kind;

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
              shouldResume: widget.shouldResume,
            ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(studySessionControllerProvider(widget.deckId));

    final session = state.session;

    // The frame is the five screens' shared chrome, and it needs a session to
    // say anything at all — before one opens there is no mode, no deck name and
    // no round to count. The transient states below draw without it rather than
    // drawing a frame full of blanks.
    final body = _body(state);
    final turn = state.turn;

    return MxContentShell(
      // No app-bar title, and therefore no app bar at all: the frame's own top
      // bar carries the mode and the ✕, and a Material bar above it would be a
      // second bar naming the same screen — with a back arrow that pops the
      // route and leaves the session open, which is the one thing BR-82 forbids.
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
              hintOverride: state.isLookingBack
                  ? context.l10n.studyBrowseLookingBack
                  : null,
              child: body,
            ),
    );
  }

  /// The notifier, read at the moment a callback fires rather than during a
  /// build.
  ///
  /// `ref.read` inside `build()` takes a value without subscribing, which is
  /// how a screen ends up showing state it will never be told has changed —
  /// the guard rule `no_ref_read_in_build` exists for exactly that, and it
  /// caught this.
  StudySessionController get _controller =>
      ref.read(studySessionControllerProvider(widget.deckId).notifier);

  Widget _body(StudySessionState state) {
    if (state.error != null) {
      return MxErrorState(
        title: context.l10n.appTitle,
        message: context.l10n.studyNothingDueMessage,
      );
    }
    if (state.isOpening || state.isAdvancing) {
      return MxLoadingState(semanticsLabel: context.l10n.appTitle);
    }
    if (state.isFinished) {
      // No summary means the read failed, not that nothing happened. The
      // session has ended either way, and inventing counts for it would be
      // worse than saying only that.
      final summary = state.summary;
      if (summary == null) {
        return MxEmptyState(title: context.l10n.studySessionFinished);
      }

      return StudySummarySectionWidget(
        summary: summary,
        onBackToDeck: () => Navigator.of(context).pop(),
      );
    }

    final session = state.session;
    if (session == null) {
      return MxLoadingState(semanticsLabel: context.l10n.appTitle);
    }

    final view = studyModeView(
      mode: session.currentMode,
      state: state,
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
      onAnswer:
          (action, {cardId, outcomeReason, comparisonVersion, hasUsedHint}) =>
              unawaited(
                _controller.answer(
                  action,
                  cardId: cardId,
                  outcomeReason: outcomeReason,
                  comparisonVersion: comparisonVersion,
                  usedHint: hasUsedHint,
                ),
              ),
      // `browse` grades nothing, so moving on is the whole interaction
      // (BR-111). The controller decides whether that means marking the card
      // browsed or stepping forward along the trail the user has swiped back
      // along — a screen that decided it would be the thing marking a card
      // browsed twice (BR-155).
      onContinue: () =>
          unawaited(_controller.browseStep(StudyBrowseStep.forward)),
      onLookBack: () => unawaited(_controller.browseStep(StudyBrowseStep.back)),
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
