import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_icon_button.dart';
import '../../../../../shared/widgets/mx_progress_bar.dart';
import '../../../domain/models/study_mode.dart';
import '../../../domain/models/study_session_kind_model.dart';
import '../../../domain/models/study_turn_model.dart';
import '../support/study_labels_widget.dart';

/// The chrome all five study screens share: top bar, context line, hint line.
///
/// **Built once because it is one thing, not five.** Every mode shows the same
/// four facts — which mode is running, how far the round has got, which deck and
/// which kind of session, and what to do next — and a mode widget that drew its
/// own would be five chances for them to disagree.
///
/// **The ✕ is not a back arrow** (BR-82). Leaving ends the session as
/// `abandoned`/`user_exit`; popping the route would leave it open, and the next
/// time the user came back the app would offer to resume something they thought
/// they had closed.
///
/// **One accent, and mode is told apart by the word on the pill** (§7.8). The
/// design gives modes two colour families; this app has no token meaning "which
/// mode is this", and the nearest green is `success`, which means *correct* — a
/// pill in it reads as a verdict handed down before the user has answered, and
/// on `match` the same colour would then mark both "this mode" and "this pair
/// was right" on one screen.
class StudySessionFrameSectionWidget extends StatelessWidget {
  const StudySessionFrameSectionWidget({
    required this.mode,
    required this.kind,
    required this.cardCount,
    required this.progress,
    required this.onClose,
    required this.child,
    this.hintOverride,
    this.timeLeft,
    super.key,
  });

  final StudyMode mode;
  final StudySessionKind kind;

  /// How many cards the session holds — the figure the context line shows and
  /// the one the bar is measured against. Fixed for the session's life
  /// (BR-102).
  final int cardCount;

  /// Read from the turn, never counted here (§7.2). A screen keeping its own
  /// tally is a second copy of the queue, and the copy is the one the user sees
  /// the moment a write is refused.
  final StudyStageProgressModel progress;

  /// What is left of a `recall` turn, ticking (BR-128, §7.3).
  ///
  /// **A listenable rather than a value** so a clock at 10Hz rebuilds the figure
  /// and nothing else. Rebuilding the whole frame would rebuild the body with
  /// it, and a body that re-deals its board ten times a second moves the answer
  /// under the user's finger.
  ///
  /// Null for every other mode, and then the counter takes this place — the two
  /// are never needed at once, because how many cards remain is already in the
  /// bar beside it.
  final ValueListenable<Duration>? timeLeft;

  final VoidCallback onClose;

  /// Replaces the mode's own hint for as long as it is non-null.
  ///
  /// **The hint says what to do next, so a screen doing something other than the
  /// mode's usual thing has to be able to say so.** `browse` uses it while the
  /// user is looking back along the trail (BR-155): the counter and the bar
  /// still describe the live turn, and without a word here a card the user has
  /// already passed reads as the session having gone backwards.
  final String? hintOverride;

  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      _TopBar(
        mode: mode,
        progress: progress,
        timeLeft: timeLeft,
        onClose: onClose,
      ),
      const SizedBox(height: AppSpacing.sm),
      _ContextLine(
        mode: mode,
        kind: kind,
        cardCount: cardCount,
        progress: progress,
      ),
      const SizedBox(height: AppSpacing.lg),
      Expanded(child: child),
      const SizedBox(height: AppSpacing.lg),
      _HintLine(mode: mode, hintOverride: hintOverride),
    ],
  );
}

/// How many cards this session holds, and which set they are (§7.2, BR-142).
///
/// **It used to say `<deck> · Learning`, and that is what it was changed from.**
/// The deck was chosen two screens ago and the word "Learning" repeats the mode
/// chip beside it — between them they told a learner nothing to act on. The size
/// of the session does: it is the number the progress bar is measured against.
///
/// **One set, never two.** The design's `12 NEW · 11 REVIEW` cannot be built:
/// BR-142 gives a session exactly one of the two card sets, so a line showing
/// both would be describing two sessions.
///
/// Uppercase here and not on the old line, because nothing in it is content the
/// user typed — uppercasing a deck name is editing what somebody wrote.
class _ContextLine extends StatelessWidget {
  const _ContextLine({
    required this.mode,
    required this.kind,
    required this.cardCount,
    required this.progress,
  });

  final StudyMode mode;
  final StudySessionKind kind;
  final int cardCount;
  final StudyStageProgressModel progress;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final base = kind == StudySessionKind.learning
        ? l10n.studyFrameSetLearning(cardCount)
        : l10n.studyFrameSetReviewing(cardCount);
    final extra = context.studyModeContext(
      mode,
      round: progress.round,
      remaining: progress.remaining,
    );

    return Text(
      extra == null ? base : '$base · $extra',
      style: context.texts.labelSmall?.copyWith(
        color: context.colors.onSurfaceVariant,
        letterSpacing: AppTypography.sectionLabelTracking,
      ),
      textAlign: TextAlign.center,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.mode,
    required this.progress,
    required this.timeLeft,
    required this.onClose,
  });

  final StudyMode mode;
  final StudyStageProgressModel progress;
  final ValueListenable<Duration>? timeLeft;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Row(
      children: <Widget>[
        // **Compact, and the progress track is the reason.** At the full 48 the
        // ✕, the pill and the figure left the track about half the row, which
        // reads as an indicator rather than a measure. It gives up width only —
        // the button keeps its 48 of height, so a thumb still has the whole bar
        // to land in vertically.
        MxIconButton(
          icon: Icons.close,
          semanticLabel: l10n.studyFrameClose,
          onPressed: onClose,
          isCompact: true,
        ),
        const SizedBox(width: AppSpacing.xs),
        // **`flex: 0`, and the zero is the whole point.** These two size to
        // their content, and a bare `Flexible` defaults to `flex: 1` — so each
        // was *allocated* a third of the free space, used what it needed, and
        // the remainder collected as dead space at the end of the row. Measured
        // at 393 wide: a 108px track with 118px of nothing after the counter.
        // At zero they are laid out first and `Expanded` below takes everything
        // that is left, which is what makes the track read as a measure rather
        // than an indicator.
        //
        // They are still `Flexible` rather than bare children: at 320px with
        // `textScaler` 2.0 the pill and the figure together overran the row by
        // 19px, and loose fit is what lets them give that back.
        Flexible(flex: 0, child: _ModePill(mode: mode)),
        const SizedBox(width: AppSpacing.sm),
        // Bare track: the bar's own header would put the same figure above it,
        // and the figure already sits at the end of this row. It announces
        // nothing either — the trailing figure carries the one announcement, so
        // a screen reader hears the count once rather than twice.
        Expanded(
          child: MxProgressBar(
            value: progress.fraction,
            size: MxProgressBarSize.sm,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          flex: 0,
          child: _TrailingFigure(progress: progress, timeLeft: timeLeft),
        ),
      ],
    );
  }
}

/// The counter, or the clock that replaces it on a `recall` turn (§7.3).
class _TrailingFigure extends StatelessWidget {
  const _TrailingFigure({required this.progress, required this.timeLeft});

  final StudyStageProgressModel progress;
  final ValueListenable<Duration>? timeLeft;

  @override
  Widget build(BuildContext context) {
    final clock = timeLeft;
    if (clock == null) {
      // Labelled, because "8 / 12" read out on its own says nothing about what
      // is being counted. The bar beside it is silent for the same reason.
      return Semantics(
        label: context.l10n.studyFrameProgressLabel,
        value: context.l10n.studyFrameProgress(progress.done, progress.total),
        child: ExcludeSemantics(
          child: _Figure(
            text: context.l10n.studyFrameProgress(
              progress.done,
              progress.total,
            ),
          ),
        ),
      );
    }

    return ValueListenableBuilder<Duration>(
      valueListenable: clock,
      builder: (context, remaining, _) =>
          // Spelled out, not a bare number: BR-128's clock has to be readable by
          // a screen reader, and "12" announced alone says nothing about what it
          // counts. The same string carries the meaning for both.
          _Figure(text: context.l10n.studyFrameTimeLeft(remaining.inSeconds)),
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    maxLines: 1,
    softWrap: false,
    overflow: TextOverflow.ellipsis,
    style: context.texts.labelMedium?.copyWith(
      color: context.colors.onSurface,
      fontWeight: FontWeight.w600,
      // Tabular figures so a counter ticking 9 -> 10 does not shift the row.
      fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
    ),
  );
}

/// The mode's name, as a label rather than a control.
///
/// **Not `MxPillButton` with a null callback.** That component renders a null
/// callback as *disabled* — the label drops to 38% alpha and leaves the palette
/// — and this is not a control that has been switched off, it is a name. The
/// same mistake cost the entry screen its two counters in M5.7.
class _ModePill extends StatelessWidget {
  const _ModePill({required this.mode});

  final StudyMode mode;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: context.semanticColors.surfaceMuted,
      borderRadius: BorderRadius.circular(AppRadius.pill),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      child: Text(
        context.studyMode(mode),
        style: context.texts.labelMedium?.copyWith(
          // `primaryAccent` is the brand hue *as text* — the variant held light
          // enough to pass AA on a dark surface, which `primary` is not.
          color: context.semanticColors.primaryAccent,
          fontWeight: FontWeight.w600,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    ),
  );
}

/// One line of instruction, and it changes with the mode.
class _HintLine extends StatelessWidget {
  const _HintLine({required this.mode, required this.hintOverride});

  final StudyMode mode;
  final String? hintOverride;

  @override
  Widget build(BuildContext context) {
    final hint = hintOverride ?? context.studyModeHint(mode);
    if (hint == null) return const SizedBox.shrink();

    return Row(
      children: <Widget>[
        Icon(
          Icons.check_circle_outline,
          size: context.texts.bodyMedium?.fontSize,
          color: context.colors.onSurfaceVariant,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            hint,
            style: context.texts.bodyMedium?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
