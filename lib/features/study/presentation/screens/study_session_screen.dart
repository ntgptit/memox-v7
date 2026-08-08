import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/l10n_extension.dart';
import '../../../../shared/widgets/mx_content_shell.dart';
import '../../../../shared/widgets/mx_empty_state.dart';
import '../../../../shared/widgets/mx_error_state.dart';
import '../../../../shared/widgets/mx_loading_state.dart';
import '../../domain/models/study_action_model.dart';
import '../../domain/models/study_mode.dart';
import '../../domain/models/study_session_kind_model.dart';
import '../controllers/study_session_controller.dart';
import '../states/study_session_state.dart';
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
  /// Shuffles the board and the option order.
  ///
  /// Held by the state rather than made per build: a fresh `Random` every frame
  /// would re-deal the board on every rebuild, and the answer would move under
  /// the user's finger.
  final Random _random = Random();

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

    return MxContentShell(
      title: state.session == null
          ? context.l10n.studyStartLearning
          : context.studyMode(state.session!.currentMode),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: _body(state),
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
      return MxEmptyState(title: context.l10n.studySessionFinished);
    }

    final session = state.session;
    if (session == null) {
      return MxLoadingState(semanticsLabel: context.l10n.appTitle);
    }

    final view = studyModeView(
      mode: session.currentMode,
      state: state,
      random: _random,
      onAnswer: (action, {outcomeReason, comparisonVersion, hasUsedHint}) =>
          unawaited(
            _controller.answer(
              action,
              outcomeReason: outcomeReason,
              comparisonVersion: comparisonVersion,
              usedHint: hasUsedHint,
            ),
          ),
      // `browse` grades nothing, so moving on is the whole interaction
      // (BR-111). The controller sees the mode and turns this into
      // `markBrowsed`, discarding the action before it reaches any write.
      onContinue: () => unawaited(_controller.answer(_noAction)),
    );

    // A mode that cannot build content for this card renders nothing rather
    // than something broken (BR-99, BR-124). The session is not stuck: the
    // controller is still the thing that advances it.
    return view ?? MxEmptyState(title: context.l10n.studySessionFinished);
  }
}

/// The placeholder `browse` hands over, and which never reaches a write.
///
/// `answer` takes an action because five of the six modes produce one; `browse`
/// does not (BR-111), and the controller drops this before touching the
/// database. Named rather than written inline so the next reader asks what it is
/// instead of assuming `browse` grades cards as remembered.
const _noAction = StudyAction.remembered;
