import 'package:flutter/material.dart';

import '../../../../../core/theme/foundations/app_sizing.dart';
import '../../../../../shared/widgets/mx_pressable.dart';
import '../../../../../core/theme/extensions/app_ink.dart';
import '../../../../../core/theme/foundations/app_durations.dart';
import '../../../../../core/theme/foundations/app_motion_policy.dart';
import '../../../../../core/theme/foundations/app_radius.dart';
import '../../../../../core/theme/foundations/app_spacing.dart';
import '../../../../../core/theme/foundations/app_stroke.dart';
import '../../../../../core/theme/typography/app_typography.dart';
import '../../../../../core/theme/extensions/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';

/// What a tile on the board can be showing (§4, §8.8).
///
/// **Five, and two of them are transient.** `paired` and `wrong` are held for a
/// fixed beat by the board and then give way — `paired` to [MatchTileState
/// .cleared], `wrong` back to [MatchTileState.idle]. Nothing persists either,
/// because neither is a fact about the card: the queue records the answer, and
/// these two say only that the app saw the tap.
enum MatchTileState {
  idle,
  selected,

  /// The pair just landed. Green, ticked, and on its way out.
  paired,

  /// This pair was wrong. Red, crossed, and on its way back to [idle].
  wrong,

  /// Paired and finished with — the slot stays, the content is gone.
  cleared,
}

/// One tile, in whichever of the five states it is.
///
/// **A state changes the edge and the ink. It never changes the surface.**
/// Selected, wrong and paired all sit on the same `surfaceContainerLowest` an
/// idle tile sits on, and say what they are with a heavier outline, a coloured
/// label and — for the two results — a mark.
///
/// **Filling the tile was the thing that made the board unreadable.** Every
/// answer touches *two* tiles, so a solid state doubled its own area; on a
/// ten-slot board that is a fifth of the screen changing colour at once, and a
/// six-line meaning under a solid `error` stops being a sentence and becomes a
/// warning panel. The information was never in the area — it is in the hue, the
/// mark and the `Semantics` value, all three of which a 1.5px edge carries
/// exactly as well while the board stays still.
///
/// **Colours come from `ColorScheme` and `AppSemanticColors`, never from this
/// file.** Selected is `primary`, which the tile needs *as a label on a
/// surface*. That was not possible while the dark tone was a fill tone reading
/// 3.33:1 as bare text on the page; since M100.18 it reads 11.36:1. Wrong is
/// `danger`, never a second red. Paired is `success`, and only because it means
/// exactly what `success` means: this answer was right. It is not the mode's
/// colour and not decoration (§7.8). The handout calls that role `mastery`; this
/// app already spends `success` on it — `card_state_widget.dart` paints
/// `CardState.mastered` with it — so the two names are one token.
///
/// **Neither result is marked by colour alone.** `paired` carries a tick and
/// `wrong` a cross, and both carry a `Semantics` value — a board whose only
/// answer is a hue answers nobody using a screen reader, and fails WCAG 1.4.1
/// for everyone who cannot tell the two hues apart.
class MatchTileWidget extends StatelessWidget {
  const MatchTileWidget({
    required this.text,
    required this.state,
    required this.onTap,
    this.isTerm = true,
    super.key,
  });

  final String text;
  final MatchTileState state;
  final VoidCallback? onTap;

  /// Which side of the board this is, and therefore how loud it reads: a term
  /// is what the eye scans for, a meaning is what it checks against.
  final bool isTerm;

  bool get _isCleared => state == MatchTileState.cleared;

  @override
  Widget build(BuildContext context) {
    final skin = _TileSkin.of(context, state);
    // **The board's two columns carry the same hierarchy `browse` carries**
    // (BR-08): the front is the Korean term, capped at 60 characters and there
    // to be scanned; the back is the meaning, up to 240, and there to be read.
    //
    // **The smaller role does not make the meaning the lesser column.** A tile's
    // height belongs to the grid, so type size here buys *capacity*: at
    // `bodySmall` a real gloss — two languages, a part of speech, a usage note —
    // fits six lines inside the same slot that held four at `bodyMedium`, and a
    // meaning cut mid-sentence is worth less than one a size smaller. The term
    // drops with it, to `titleMedium` at `w500`: it only has to be found, and it
    // is the only Hangul on its side of the board.
    //
    // `withWeight` rather than `copyWith(fontWeight:)` — the faces here are
    // variable, so the weight has to move in `fontVariations` too or the render
    // stays at the style's own weight while every test agrees it changed.
    final style =
        (isTerm
                ? AppTypography.withWeight(
                    context.texts.titleMedium!,
                    FontWeight.w500,
                  )
                : context.texts.bodySmall)
            ?.copyWith(color: skin.foreground.resolve(context));
    final radius = BorderRadius.circular(AppRadius.md);
    // **Only the transition is reduced, never the beat a state is held for.**
    // The hold is feedback; the crossfade is decoration, and `AppMotionPolicy`
    // is written for exactly that line — it says an animation that decorates a
    // state change may go, not that the feedback may.
    final motion = AppMotionPolicy.durationOf(context, AppDurations.normal);

    return Semantics(
      selected: state == MatchTileState.selected,
      // The tick and the cross mark these for people who can see them; this is
      // what marks them for everyone else. A cleared slot keeps saying it, or a
      // screen reader loses the pair off the board altogether.
      value: switch (state) {
        MatchTileState.paired ||
        MatchTileState.cleared => context.l10n.studyMatchPaired,
        MatchTileState.wrong => context.l10n.studyMatchWrong,
        _ => null,
      },
      child: AnimatedContainer(
        duration: motion,
        curve: AppDurations.standard,
        decoration: BoxDecoration(
          color: skin.background,
          borderRadius: radius,
          border: Border.all(color: skin.outline, width: skin.outlineWidth),
        ),
        // A cleared tile is finished, not merely busy: BR-116 has already
        // recorded it and a second tap could only record it twice. A tile
        // still showing its result is not a target either — that answer is
        // in flight.
        child: MxPressable(
          onTap: _isTappable ? onTap : null,
          child: Padding(
            // Even on all four sides, and `sm` because six lines of meaning
            // need the width as much as the height. `md` at the sides cost
            // eight logical pixels of every line — which is a word per line
            // on a 175-wide tile, and the six-line budget was bought to hold
            // words.
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Center(
              child: AnimatedOpacity(
                // The content leaving *is* the pair disappearing. The slot
                // does not move, so nothing anyone was reaching for shifts.
                opacity: _isCleared ? 0 : 1,
                duration: motion,
                curve: AppDurations.standard,
                child: _content(context, skin, style),
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool get _isTappable =>
      state == MatchTileState.idle || state == MatchTileState.selected;

  Widget _content(
    BuildContext context,
    _TileSkin skin,
    TextStyle? style,
  ) => Row(
    mainAxisSize: MainAxisSize.min,
    mainAxisAlignment: MainAxisAlignment.center,
    children: <Widget>[
      if (skin.mark case final mark?) ...<Widget>[
        // The mark tracks the label's own size, which no MxIconSize step
        // names; the closed-set spelling is the skin's ink resolving.
        Icon(
          mark,
          size: style?.fontSize,
          color: skin.foreground.resolve(context),
        ),
        const SizedBox(width: AppSpacing.xs),
      ],
      Flexible(
        child: Text(
          text,
          style: style,
          textAlign: TextAlign.center,
          // The row's height is the grid's to decide, so text gives way rather
          // than pushing the board out of shape.
          maxLines: isTerm
              ? AppMatchTile.termMaxLines
              : AppMatchTile.meaningMaxLines,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ],
  );
}

/// What one state looks like, resolved against the theme.
///
/// A type rather than five locals in `build()`: the values are one decision each
/// and they have to agree — a foreground picked for a fill it is not sitting on
/// is the bug this shape makes hard to write. The fill is now the *same* in four
/// of the five states, which makes that agreement easier to keep and the
/// remaining exception, [MatchTileState.cleared], easier to see.
class _TileSkin {
  const _TileSkin({
    required this.background,
    required this.outline,
    required this.outlineWidth,
    required this.foreground,
    required this.mark,
  });

  factory _TileSkin.of(BuildContext context, MatchTileState state) {
    final scheme = context.colors;
    final semantic = context.semanticColors;
    final ground = scheme.surfaceContainerLow;
    // **The page, read from the scaffold rather than guessed at.** `surface` is
    // not it: measured in dark, the page is `(10, 8, 45)`, `surface` is
    // `(26, 24, 56)` and `surfaceContainerLowest` — the tile's own fill — is
    // `(10, 3, 38)`. A cleared slot painted `surface` came out *lighter* than
    // the page it was meant to be a hole in, which reads as a new tile rather
    // than an emptied one.
    final page = Theme.of(context).scaffoldBackgroundColor;

    // The three live states differ from idle in exactly two ways: which colour
    // the edge and the ink take, and that the edge steps up from a hairline to
    // an input's weight. Written once, because three near-identical constructor
    // calls are three places for the fill to drift apart.
    _TileSkin marked(AppInk ink, IconData? mark) => _TileSkin(
      background: ground,
      outline: ink.resolve(context),
      // `input`, not `focus`: 2px is the ring that says *keyboard focus is
      // here*, and a board where half the tiles wore it would leave the focus
      // indicator nothing of its own to say.
      outlineWidth: AppStroke.input,
      foreground: ink,
      mark: mark,
    );

    return switch (state) {
      MatchTileState.selected => marked(AppInk.accent, null),
      MatchTileState.wrong => marked(AppInk.danger, Icons.close),
      MatchTileState.paired => marked(AppInk.success, Icons.check),
      // A cleared slot sits on the *page*, not on the tile surface: the hole is
      // what says the pair is gone, and a tile-coloured hole is just a tile
      // with no words on it. The outline is faint rather than absent — with
      // four of five pairs cleared, the tile still in play would otherwise
      // float in an empty page with nothing left to say the grid is a grid.
      MatchTileState.cleared => _TileSkin(
        // **Null, not the page colour.** Nothing painted is a truer hole than
        // a colour that happens to match, and it stays a hole if the surface
        // behind the board ever changes. The outline still has to be solid —
        // R7 — so *that* is blended against the page.
        background: null,
        outline: Color.alphaBlend(
          semantic.borderControl.withValues(
            alpha: AppMatchTile.clearedOutlineAlpha,
          ),
          page,
        ),
        outlineWidth: AppStroke.hairline,
        foreground: AppInk.stated,
        mark: null,
      ),
      MatchTileState.idle => _TileSkin(
        background: ground,
        // A tile is the control here, and its fill is 1.03:1 from the dark page
        // — the outline is the whole grid (WCAG 1.4.11).
        outline: semantic.borderControl,
        outlineWidth: AppStroke.hairline,
        foreground: AppInk.stated,
        mark: null,
      ),
    };
  }

  /// Null paints nothing, which is what a cleared slot wants. Every other state
  /// paints the same surface — a state is an edge and an ink, not a fill.
  final Color? background;

  final Color outline;

  /// How heavy that edge is. The only geometry a state is allowed to change,
  /// and it changes it by half a pixel — enough to read as deliberate, small
  /// enough that nothing beside the tile moves.
  final double outlineWidth;

  final AppInk foreground;
  final IconData? mark;
}

/// The numbers this tile decides for itself, and none of them is a colour.
abstract final class AppMatchTile {
  /// How long a correct pair stays marked before its content leaves.
  ///
  /// **A beat, not a pause.** Long enough that the eye registers *right* rather
  /// than merely *gone* — a disappearance on its own reads the same as a missed
  /// tap to someone who was guessing. Short enough that two of them never sit on
  /// the board at once, which is the clutter that made keeping them there
  /// permanently the wrong answer.
  ///
  /// **A hold is how long a state is *visible*; a transition is how long it
  /// takes to arrive.** They were confused while this was
  /// [AppDurations.slow] — 320ms against a 200ms crossfade, which left 120ms
  /// where the colour was actually standing still. `AppDurations` is a scale
  /// for *motion*, and the longest thing in it is deliberately short; borrowing
  /// its top rung for a legibility budget is how the budget ended up at a third
  /// of what it needed. 500ms is 300ms of the state at rest.
  static const Duration successFlash = Duration(milliseconds: 500);

  /// How long a wrong pair stays marked before the board goes back to idle.
  ///
  /// Longer than [successFlash] because there is more to read: the user has to
  /// find *which two* tiles were wrong together, and a pair is two glances,
  /// where a correct pair is a confirmation of something already known.
  ///
  /// **It holds colour, it does not hold input.** Reaching for the next tile
  /// clears it early, and a write in flight never freezes the board — a board
  /// of five pairs answered wrong four times would otherwise spend three
  /// seconds refusing taps it has no reason to refuse.
  static const Duration wrongHold = Duration(milliseconds: 700);

  /// How much of `borderSubtle` a cleared slot keeps.
  ///
  /// Under half, so emptied slots recede behind the pairs still in play while
  /// the grid stays legible as a grid.
  static const double clearedOutlineAlpha = 0.45;

  /// How many lines the Korean term is given. Sixty characters of Hangul at
  /// `titleMedium` reach the second line and no further.
  static const int termMaxLines = 2;

  /// How many lines the meaning is given.
  ///
  /// Six, because that is what BR-08's 240 characters actually take at
  /// `bodySmall` on a half-width tile: an English gloss, a native one, and the
  /// parenthetical that says which of the two a learner should use. Four cut
  /// that mid-sentence, and an ellipsis in the middle of a usage note is
  /// indistinguishable from a deck with bad data.
  static const int meaningMaxLines = 6;

  /// The shortest a row is allowed to get before the board stops filling the
  /// height and starts scrolling.
  ///
  /// **112, and every part of it is [meaningMaxLines].** `bodySmall` is 12/16 —
  /// six lines is 96 — and the tile insets `AppSpacing.sm` top and bottom:
  /// `6 × 16 + 2 × 8 = 112`. So this is not a chosen number but the height the
  /// typography above already implies, and the two move together or the board
  /// silently starts ellipsising the sixth line it was sized to show.
  ///
  /// It was [AppSizing.touchTarget] while the meaning had four lines and
  /// the floor was only about a thumb. A tile is still a control, and 112 clears
  /// 48 with room to spare; what changed is that the tap target stopped being
  /// the binding constraint.
  static const double minRowHeight = 112;
}
