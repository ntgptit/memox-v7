import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../../core/theme/app_icon_size.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_content_shell.dart';
import '../../../../../shared/widgets/mx_session_top_bar.dart';
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
/// **One accent, and mode is told apart by the word on the chip** (§7.8). The
/// design gives modes two colour families; this app has no token meaning "which
/// mode is this", and the nearest green is `success`, which means *correct* — a
/// chip in it reads as a verdict handed down before the user has answered, and
/// on `match` the same colour would then mark both "this mode" and "this pair
/// was right" on one screen. That is why `MxSessionTopBar` takes a *word* and no
/// colour: there is nothing for a caller to vary.
///
/// **The bar itself is `MxSessionTopBar`, and it is not study's.** Nothing in it
/// is about cards — a way out, a name, a measure and a figure is what any
/// full-screen task shows. Keeping it here would have meant the next such screen
/// re-deriving the gap either side of the track, which is the drift §8.4 was
/// spent measuring.
///
/// **The frame gutters itself.** The bar's ✕ has to reach the screen edge, so
/// the screen passes `padding: EdgeInsets.zero` to `MxContentShell` and every
/// other band here applies [mxScreenGutter] on its own.
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
  Widget build(BuildContext context) {
    // The screen hands the frame an ungutter'd region so the bar's ✕ can reach
    // the edge (see `MxSessionTopBar`), which makes every *other* band here
    // responsible for its own gutter. Read once from the same helper the shell
    // uses, so the frame and the screens either side of it agree at 320 too.
    final gutter = mxScreenGutter(context);

    return Padding(
      // Vertical only, and it is the half of the screen padding the shell is no
      // longer applying. Horizontal is per band below, because exactly one band
      // must not have it.
      padding: EdgeInsets.symmetric(vertical: gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          MxSessionTopBar(
            label: context.studyMode(mode),
            progress: progress.fraction,
            trailing: _TrailingFigure(progress: progress, timeLeft: timeLeft),
            onClose: onClose,
            closeLabel: context.l10n.studyFrameClose,
          ),
          const SizedBox(height: AppSpacing.sm),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: gutter),
            child: _ContextLine(
              mode: mode,
              kind: kind,
              cardCount: cardCount,
              progress: progress,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: gutter),
              child: child,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: gutter),
            child: _HintLine(mode: mode, hintOverride: hintOverride),
          ),
        ],
      ),
    );
  }
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
      // **Uppercased here, not in the ARB.** The line is composed from two
      // strings and only one of them was written in caps, so `match` rendered
      // `5 CARDS DUE · Round 1 · 4 pairs left` — a sentence wearing half a
      // label. Doing it at the join makes the case a property of the line
      // rather than of whichever fragment a translator happened to shout, and
      // leaves the ARB holding words rather than styling.
      (extra == null ? base : '$base · $extra').toUpperCase(),
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

/// One line of instruction, and it changes with the mode.
///
/// **Centred, and one step below body size.** It is a caption under the card,
/// not a paragraph of the screen: left-aligned at body size it read as content
/// the card had spilled, and it is the only thing on this screen that is neither
/// the card nor the chrome measuring it.
///
/// The glyph comes from the mode (`studyModeHintIcon`) because the sentence does
/// — a direction and an instruction do not take the same mark.
class _HintLine extends StatelessWidget {
  const _HintLine({required this.mode, required this.hintOverride});

  final StudyMode mode;
  final String? hintOverride;

  @override
  Widget build(BuildContext context) {
    final hint = hintOverride ?? context.studyModeHint(mode);
    if (hint == null) return const SizedBox.shrink();

    final style = context.texts.bodySmall?.copyWith(
      color: context.colors.onSurfaceVariant,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Icon(
          context.studyModeHintIcon(mode),
          // **The icon step, not the line's font size.** Tying it to the text
          // put a 12px glyph beside 12px copy, and a mark that small reads as a
          // speck rather than as the thing that classifies the sentence.
          // [AppIconSize.sm] is the step named for exactly this — inline with
          // body text — and it is what the handout asks for.
          size: AppIconSize.sm,
          color: context.colors.onSurfaceVariant,
        ),
        const SizedBox(width: AppSpacing.sm),
        // `Flexible`, not `Expanded`: the row is centred, so a child that took
        // all the width would put the glyph back on the left margin and undo it.
        // Loose fit is still needed — at 320 with `textScaler` 2.0 the sentence
        // is wider than the screen and has to be allowed to wrap.
        Flexible(
          child: Text(hint, style: style, textAlign: TextAlign.center),
        ),
      ],
    );
  }
}
