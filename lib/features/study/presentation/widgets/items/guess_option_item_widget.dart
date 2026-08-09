import 'package:flutter/material.dart';

import '../../../../../core/theme/app_durations.dart';
import '../../../../../core/theme/app_icon_size.dart';
import '../../../../../core/theme/app_motion_policy.dart';
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

/// One row of a `guess` question: a meaning, and afterwards a verdict.
///
/// **No A–E badge.** The handout draws a lettered circle on each row (§5) and it
/// was built; it is gone because of what it cost on a real deck. The circle plus
/// its gap took 44pt off every row on a screen 393pt wide, and the content this
/// app is for is not "apple" — it is "Deep sleep / Giấc ngủ sâu (Danh từ, trạng
/// thái ngủ ngon không bị gián đoạn…)". Those 44pt were a line of meaning on
/// every one of the five rows, spent on a seat number that changes with the next
/// shuffle (BR-127) and that nothing reads back — a turn is recorded by `cardId`
/// (BR-125), never by position. Ruling recorded in the handout's §5.
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
    required this.text,
    required this.state,
    required this.onTap,
    super.key,
  });

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
      // The row's fill sits 1.06:1 from the page, so the border is doing all
      // the separating — and a row is a control (WCAG 1.4.11), not a card.
      GuessOptionState.open ||
      GuessOptionState.dimmed => semantic.borderControl,
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
                padding: AppGuessOption.rowPadding,
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        text,
                        // **14 and regular, not 16 and semibold.** A meaning is
                        // a sentence, not a heading: real content here runs to
                        // "Deep sleep / Giấc ngủ sâu (Danh từ, trạng thái ngủ
                        // ngon không bị gián đoạn…)" and at 16/w600 five of
                        // those are a wall. `bodyMedium` also carries the 1.45
                        // line height, which is what makes the third line of a
                        // wrapped meaning readable rather than crowded.
                        style: context.texts.bodyMedium?.copyWith(
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

/// The numbers this row decides, and none of them is a colour.
abstract final class AppGuessOption {
  /// The inset around a row's text. Public because the section measures a row
  /// before it decides how much height the prompt card may keep — and a second
  /// copy of these numbers over there would drift the first time one changed.
  static const EdgeInsets rowPadding = EdgeInsets.symmetric(
    horizontal: AppSpacing.lg,
    vertical: AppSpacing.sm,
  );

  /// The border the row draws, counted on both edges.
  static const double rowBorder = 2;

  /// How tall this row wants to be for [text] at [width].
  ///
  /// **Measured, not guessed, and that is what keeps the screen still.** The
  /// section used to size the prompt card against a 48pt floor per row, which
  /// is right until a meaning wraps — and then the card kept its ceiling while
  /// the options ran off the bottom into a scroll. Asking the text how tall it
  /// is lets the card give way by exactly the amount the wrap costs.
  ///
  /// The same style and the same insets the row builds with, so the two cannot
  /// disagree: a measurement that drifts from the widget is worse than none,
  /// because it looks authoritative.
  static double naturalHeightOf(
    BuildContext context,
    String text, {
    required double width,
  }) {
    final style = context.texts.bodyMedium;
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout(maxWidth: width - rowPadding.horizontal - rowBorder);

    final content = painter.height + rowPadding.vertical + rowBorder;
    painter.dispose();
    final floor = MediaQuery.textScalerOf(context).scale(rowMinHeight);

    return content > floor ? content : floor;
  }

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
