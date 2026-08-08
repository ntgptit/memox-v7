import 'package:flutter/material.dart';

import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
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

    final accent = switch (state) {
      GuessOptionState.correct => semantic.success,
      GuessOptionState.chosenWrong => semantic.danger,
      GuessOptionState.open || GuessOptionState.dimmed => null,
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

    return Semantics(
      // Colour and a glyph carry the verdict for people who can see them; this
      // carries it for everyone else.
      value: announcement,
      child: Opacity(
        opacity: state == GuessOptionState.dimmed
            ? AppGuessOption.dimmedOpacity
            : 1,
        child: Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Material(
            color: scheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              side: BorderSide(color: accent ?? semantic.borderSubtle),
            ),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: <Widget>[
                    _Badge(letter: badge, accent: accent),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        text,
                        style: context.texts.bodyLarge?.copyWith(
                          color: accent ?? scheme.onSurface,
                        ),
                      ),
                    ),
                    if (verdict != null) ...<Widget>[
                      const SizedBox(width: AppSpacing.sm),
                      Icon(
                        verdict,
                        size: AppGuessOption.badgeSize,
                        color: accent,
                      ),
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

    return Container(
      width: AppGuessOption.badgeSize,
      height: AppGuessOption.badgeSize,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: colour),
      ),
      child: ExcludeSemantics(
        // The letter is a handle for the eye, not a name. Announcing it would
        // read every option as "A, apple" and bury the meaning behind a seat
        // number that changes with the next shuffle (BR-127).
        child: Text(
          letter,
          style: context.texts.labelMedium?.copyWith(color: colour),
        ),
      ),
    );
  }
}

/// The two numbers this row decides, and neither of them is a colour.
abstract final class AppGuessOption {
  /// The badge circle, and the verdict glyph beside it at the same size.
  static const double badgeSize = 24;

  /// How far the three options nobody picked recede once the answer is in.
  ///
  /// **Readable, not erased.** They are still four of the five meanings the
  /// learner was choosing between, and a row faded past reading turns the
  /// after-answer screen into one line of feedback with no context around it.
  static const double dimmedOpacity = 0.5;
}
