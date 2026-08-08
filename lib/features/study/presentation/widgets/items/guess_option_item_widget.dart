import 'package:flutter/material.dart';

import '../../../../../core/theme/app_durations.dart';
import '../../../../../core/theme/app_icon_size.dart';
import '../../../../../core/theme/app_motion_policy.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_stroke.dart';
import '../../../../../core/theme/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';

/// What one option looks like once the question has been answered.
///
/// **Four states, and the difference between the last two is the whole point.**
/// The right answer is always shown as right, whether or not the learner picked
/// it — a question that only marks what you chose leaves you knowing you were
/// wrong and not what was right. The option you picked wrongly is marked as
/// yours. Everything else recedes.
enum GuessOptionState { open, correct, chosenWrong, dimmed }

/// One row of a `guess` question: a letter, a meaning, and afterwards a verdict.
///
/// **The letter is the row's position, not the card's name** (BR-125). A turn is
/// recorded by `cardId`; the badge exists so a learner can say "C" out loud, and
/// it is rebuilt from the display order every time the options are shuffled. Any
/// code that read it back as an identifier would grade whichever card happened
/// to sit in that seat.
///
/// **No secondary description line** (§7.5). `cards` has no field for an
/// extended meaning, and borrowing `hint` — which belongs to `fill` (BR-136) —
/// would make one column mean two different things depending on the screen.
///
/// **A verdict fills the row, it does not merely outline it** (§8.9). The
/// handout tints the whole surface, and it is right to: outlined alone, the
/// answered state reads as four rows of the same weight with two coloured edges,
/// and the eye has to hunt for which is which. The tints are blended rather than
/// painted translucent — `color_source_rules_test` R7 — so one token is one
/// value over the surface the row actually sits on.
class GuessOptionItemWidget extends StatelessWidget {
  const GuessOptionItemWidget({
    required this.badge,
    required this.text,
    required this.state,
    required this.onTap,
    super.key,
  });

  /// The letter shown in the circle: A for the first row, B for the second.
  final String badge;

  /// Already-localized card content.
  final String text;

  final GuessOptionState state;

  /// Null once the question has been answered — BR-126 allows one turn, and a
  /// row that still responds is a row that invites a second.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final semantic = context.semanticColors;
    final ground = scheme.surfaceContainerLowest;

    final accent = switch (state) {
      GuessOptionState.correct => semantic.success,
      GuessOptionState.chosenWrong => semantic.danger,
      GuessOptionState.open || GuessOptionState.dimmed => null,
    };
    final fill = switch (state) {
      GuessOptionState.correct => Color.alphaBlend(
        semantic.success.withValues(alpha: AppGuessOption.correctFillAlpha),
        ground,
      ),
      GuessOptionState.chosenWrong => Color.alphaBlend(
        semantic.danger.withValues(alpha: AppGuessOption.wrongFillAlpha),
        ground,
      ),
      GuessOptionState.open || GuessOptionState.dimmed => ground,
    };
    final outline = switch (state) {
      GuessOptionState.correct => Color.alphaBlend(
        semantic.success.withValues(alpha: AppGuessOption.correctOutlineAlpha),
        ground,
      ),
      GuessOptionState.chosenWrong => Color.alphaBlend(
        semantic.danger.withValues(alpha: AppGuessOption.wrongOutlineAlpha),
        ground,
      ),
      GuessOptionState.open || GuessOptionState.dimmed => semantic.borderSubtle,
    };
    final verdict = switch (state) {
      GuessOptionState.correct => Icons.check,
      GuessOptionState.chosenWrong => Icons.close,
      GuessOptionState.open || GuessOptionState.dimmed => null,
    };
    final announcement = switch (state) {
      GuessOptionState.correct => context.l10n.studyGuessCorrectAnswer,
      GuessOptionState.chosenWrong => context.l10n.studyGuessYourAnswer,
      GuessOptionState.open || GuessOptionState.dimmed => null,
    };

    final radius = BorderRadius.circular(AppRadius.md);
    final motion = AppMotionPolicy.durationOf(context, AppDurations.normal);

    return Semantics(
      // Colour and a glyph carry the verdict for people who can see them; this
      // carries it for everyone else.
      value: announcement,
      child: Opacity(
        opacity: state == GuessOptionState.dimmed
            ? AppGuessOption.dimmedOpacity
            : 1,
        child: AnimatedContainer(
          duration: motion,
          curve: AppDurations.standard,
          constraints: const BoxConstraints(
            minHeight: AppGuessOption.rowMinHeight,
          ),
          decoration: BoxDecoration(
            color: fill,
            borderRadius: radius,
            border: Border.all(color: outline),
          ),
          child: Material(
            // The container paints the surface; this exists for the ripple.
            type: MaterialType.transparency,
            child: InkWell(
              onTap: onTap,
              borderRadius: radius,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  children: <Widget>[
                    _Badge(letter: badge, accent: accent),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        text,
                        // 16, and `titleMedium` is the step that is 16. The
                        // handout asks for w500, which is not a weight in this
                        // scale — inventing one for a single row is the drift
                        // `app_typography.dart` exists to stop.
                        style: context.texts.titleMedium?.copyWith(
                          color: accent ?? scheme.onSurface,
                        ),
                      ),
                    ),
                    if (verdict != null) ...<Widget>[
                      const SizedBox(width: AppSpacing.sm),
                      Icon(verdict, size: AppIconSize.sm, color: accent),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The circle holding the row's letter.
class _Badge extends StatelessWidget {
  const _Badge({required this.letter, required this.accent});

  final String letter;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final colour = accent ?? context.colors.onSurfaceVariant;

    return Opacity(
      // Just under full. The badge is a handle, not a verdict, and at full
      // strength it competes with the meaning beside it — which is the thing
      // being chosen between.
      opacity: AppGuessOption.badgeOpacity,
      child: Container(
        width: AppGuessOption.badgeSize,
        height: AppGuessOption.badgeSize,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: colour, width: AppStroke.input),
        ),
        child: ExcludeSemantics(
          // The letter is a handle for the eye, not a name. Announcing it would
          // read every option as "A, apple" and bury the meaning behind a seat
          // number that changes with the next shuffle (BR-127).
          child: Text(
            letter,
            style: context.texts.labelMedium?.copyWith(
              color: colour,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

/// The numbers this row decides, and none of them is a colour.
abstract final class AppGuessOption {
  /// The badge circle. The verdict glyph beside it is [AppIconSize.sm] — a
  /// smaller mark, because the badge names the row and the glyph only judges it.
  static const double badgeSize = 28;

  /// How far the badge sits behind the meaning it labels.
  static const double badgeOpacity = 0.85;

  /// The shortest a row may be. [AppSpacing.minimumTouchTarget] rather than the
  /// handout's 50: five of these are the only controls on the screen, and the
  /// floor for a control is a number this project already has.
  static const double rowMinHeight = AppSpacing.minimumTouchTarget;

  /// How far the three options nobody picked recede once the answer is in.
  ///
  /// **Readable, not erased.** They are still four of the five meanings the
  /// learner was choosing between, and a row faded past reading turns the
  /// after-answer screen into one line of feedback with no context around it.
  static const double dimmedOpacity = 0.36;

  /// How much of its verdict colour an answered row carries as fill, blended
  /// into the surface under it.
  ///
  /// The wrong row is quieter than the right one on purpose: the answer is what
  /// the learner has to take away, and the mistake is already marked by being
  /// the row with a cross on it.
  static const double correctFillAlpha = 0.14;
  static const double wrongFillAlpha = 0.1;

  /// The same for the outline. Heavier than the fill, because a hairline has a
  /// fraction of the area to say it with.
  static const double correctOutlineAlpha = 0.4;
  static const double wrongOutlineAlpha = 0.35;
}
