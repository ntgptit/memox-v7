import 'package:flutter/material.dart';

import '../../../../../core/theme/extensions/app_ink.dart';
import '../../../../../core/theme/foundations/app_durations.dart';
import '../../../../../core/theme/foundations/app_elevation.dart';
import '../../../../../core/theme/foundations/app_motion_policy.dart';
import '../../../../../core/theme/foundations/app_radius.dart';
import '../../../../../core/theme/foundations/app_sizing.dart';
import '../../../../../core/theme/foundations/app_spacing.dart';
import '../../../../../core/theme/foundations/app_stroke.dart';
import '../../../../../core/theme/extensions/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_pressable.dart';
import '../../../../../shared/widgets/mx_icon.dart';

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
/// **A verdict is an edge, an ink and a mark — never a fill** (§8.9). The tint
/// was here first, on the argument that an outline alone leaves the eye hunting.
/// It does not: five rows of running text are a page, and colouring two of them
/// end to end turns a screen the learner is *reading* into a screen shouting at
/// them. `match` reached the same answer for the same reason, and a row whose
/// meaning runs to four lines has more area to shout with than a tile does.
///
/// What keeps it findable instead: the border steps up in weight, the text
/// takes the verdict's colour — the whole sentence, not a chip on it — and the
/// tick or cross sits at the end of the row.
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
    final ground = scheme.surfaceContainerLow;

    final AppInk? accent = switch (state) {
      GuessOptionState.correct => AppInk.success,
      GuessOptionState.chosenWrong => AppInk.danger,
      GuessOptionState.open || GuessOptionState.dimmed => null,
    };
    // The surface never moves. Every state sits on the row's own fill, and the
    // one that reads differently is the one that says so at its edge.
    //
    // **A resting row draws no edge at all, and the card's depth separates it
    // instead** (M100.69, owner decision on a rendered comparison).
    //
    // Two rounds were spent choosing *which* line to draw here — grey at
    // 4.05:1, then the brand edge at 3.27 — and the question underneath was
    // never which token. It was whether a resting answer row is a control that
    // owes WCAG 1.4.11 a 3:1 boundary, or a card identified by its content.
    // It is the second: five rows of running text are five surfaces holding
    // sentences, and this screen's job is to be *read* before it is answered.
    //
    // What this buys is the states. `success` and `danger` at
    // [AppStroke.control] are now the only edges on the screen rather than
    // heavier versions of one that all five rows already wore — the verdict
    // stops competing with the frame around it.
    //
    // Measured on the committed golden, not on the draft it was approved from:
    // a resting row reads **1.394:1** in light, on a shadow (`#D7DAE6`), and
    // **1.298:1** in dark, on the zero-blur `outlineVariant` rim
    // (`#272C48`) `AppElevation` paints there. That is the separation every
    // `MxCard` in this app has had since M99.94.
    final Color? outline = accent?.resolve(context);
    final outlineWidth = accent == null ? 0.0 : AppStroke.control;
    // A row that is saying something says it with the edge; one at rest says it
    // with depth. Never both, or one fact arrives on two channels.
    final elevation = accent == null ? AppElevation.card : AppElevation.none;
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
            color: ground,
            borderRadius: radius,
            // **The verdict's stroke sits outside the box** (M100.69). With a
            // resting row drawing no edge, an inside stroke would make the two
            // marked rows 3dp taller than the three that were not picked — so
            // answering a question would push every row below the verdict down
            // the screen, which is the shift §8.9 spent itself removing. The
            // same trick, for the same reason, as `MxSearchField`.
            border: outline == null
                ? null
                : Border.all(
                    color: outline,
                    width: outlineWidth,
                    strokeAlign: BorderSide.strokeAlignOutside,
                  ),
            boxShadow: shadowsFor(elevation, scheme),
          ),
          // MxPressable is the Material+InkWell pair in one piece; the
          // container above still paints the surface.
          child: MxPressable(
            onTap: onTap,
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
                      style: context.texts.bodyMedium!.inked(
                        context,
                        accent ?? AppInk.stated,
                      ),
                    ),
                  ),
                  if (verdict != null) ...<Widget>[
                    const SizedBox(width: AppSpacing.sm),
                    MxIcon(verdict, size: MxIconSize.sm, ink: accent!),
                  ],
                ],
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
    )..layout(maxWidth: width - rowPadding.horizontal);

    final content = painter.height + rowPadding.vertical;
    painter.dispose();

    // **The floor is not scaled, and the widget is why.** The row's floor is
    // `MxPressable`'s `BoxConstraints(minHeight: AppSizing.touchTarget)` — a
    // bare 48 — so a measurement that scaled the same number was measuring a
    // row the app does not build. It used to read
    // `MediaQuery.textScalerOf(context).scale(rowMinHeight)`, and under
    // Android's non-linear curve at the 2.0 setting that returns ~64.3 for 48,
    // because 48 sits where the table's growth has already fallen off. So the
    // helper reserved ~64 a row while the widget rendered ~59, and the prompt
    // card gave up the difference five times over for nothing.
    //
    // 48 is a touch target (WCAG 2.5.8, [AppSizing.touchTarget]), not a font
    // size. Text scaling belongs to the painter above — where it is applied,
    // through the real `TextScaler` — and the fingertip it is a floor for does
    // not grow when the type does.
    //
    // **No border term at all since M100.69, and that is a simplification the
    // change earned rather than one it needed.** A resting row draws no edge
    // and a verdict draws its edge *outside* the box, so the stroke is out of
    // the layout in every state — the row is exactly `max(48, padding + text)`
    // and the helper is exact for all four states instead of exact for two and
    // a ceiling for the other two.
    //
    // The ceiling it replaces was load-bearing while it existed: written the
    // other way round the helper answered 48 for a row that rendered at 50, an
    // under-reservation the section paid for by scrolling five options that are
    // supposed to be visible at once (BR-121).
    return content > rowMinHeight ? content : rowMinHeight;
  }

  /// The shortest a row may be. [AppSizing.touchTarget] rather than the
  /// handout's 50: five of these are the only controls on the screen, and the
  /// floor for a control is a number this project already has.
  static const double rowMinHeight = AppSizing.touchTarget;

  /// How far the three options nobody picked recede once the answer is in.
  ///
  /// **Readable, not erased.** They are still four of the five meanings the
  /// learner was choosing between, and a row faded past reading turns the
  /// after-answer screen into one line of feedback with no context around it.
  ///
  /// It was 0.36, which is under the 4.5:1 body text needs against this surface
  /// — the rows the learner was *comparing* were the ones that disappeared. The
  /// verdict rows no longer carry a fill, so recession is the only thing
  /// separating them and it can afford to be gentle.
  static const double dimmedOpacity = 0.7;
}
