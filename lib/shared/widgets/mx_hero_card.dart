import 'package:flutter/material.dart';

import '../../core/theme/app_breakpoints.dart';
import 'mx_action_button.dart';

/// The width question a hero panel has to answer, asked in the one place where
/// the answer is right.
///
/// **This is not a card, and deliberately does not draw one.** Four screens
/// open with a leading panel, and measured against each other they share almost
/// nothing: a card and a `Column`. Library stacks a disclosure over a figure
/// line, Study stacks an eyebrow over a deck name, Progress puts a metric well
/// beside a numeral, Card Detail runs tags and a divider and a field list. A
/// widget wrapping all four would be a pile of optional slots, which is the
/// shape M100.5 spent a milestone removing from `MxFeedbackBand`.
///
/// What they *do* share is one rule, and it is the one that already went wrong:
/// **a hero's primary stretches only below the compact tier.**
///
/// ## The trap this exists to make unreachable
///
/// The rule reads the **card's** width. A `LayoutBuilder` placed inside the
/// card's padding sees 32dp less — at a 393dp device that is 329, under the 360
/// tier — so the stretched branch runs on every phone and the rule silently
/// does nothing. Study Home shipped exactly that, and its own comment records
/// the diagnosis: *"the golden had quietly stamped the wrong branch"*. Both
/// branches build, lay out and render fine, so nothing failed.
///
/// M100.7 gave Library the same rule and, with it, a second copy of the same
/// trap. This widget is the third version and the last one: it sits **outside**
/// the card by construction, because the card is what its builder returns. A
/// caller cannot put the measurement in the wrong place without deleting this
/// widget first.
///
/// ```dart
/// MxHeroCard(
///   builder: (BuildContext context, bool isCramped) => MxCard.accent(
///     child: Column(
///       children: <Widget>[
///         const _Figures(),
///         MxHeroPrimary(label: '…', onPressed: …, isCramped: isCramped),
///       ],
///     ),
///   ),
/// )
/// ```
class MxHeroCard extends StatelessWidget {
  const MxHeroCard({required this.builder, super.key});

  /// Builds the panel. `isCramped` is the **card's** width against the compact
  /// tier — 361 at a 393dp device, 296 at 320 — not its content's.
  final Widget Function(BuildContext context, bool isCramped) builder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) =>
          builder(context, AppBreakpoints.isCompact(constraints.maxWidth)),
    );
  }
}

/// A hero panel's one primary action, at the width the tier asks for.
///
/// Stretched below the compact tier, where a hugging primary looks stranded;
/// hugging its label above it, where a stretched one reads as a banner rather
/// than as a button. The hero's column stretches its children, so the `Align`
/// is what un-stretches this one.
///
/// **Both heroes that have an action say the same thing** — *start studying* —
/// and before M100.7 they said it at 329dp and 127dp, from the same starting x,
/// so side by side they read as one element that got cut short. Sharing the
/// widget is what stops that drifting apart again; `hero_action_width_test.dart`
/// is what notices if it does.
///
/// [isCramped] comes from [MxHeroCard], which is the only thing that measures
/// it correctly.
class MxHeroPrimary extends StatelessWidget {
  const MxHeroPrimary({
    required this.label,
    required this.onPressed,
    required this.isCramped,
    this.icon,
    this.semanticLabel,
    super.key,
  });

  /// Already-localized. The screen owns the copy.
  final String label;

  final VoidCallback onPressed;

  /// See [MxHeroCard.builder] — the card's width against the compact tier.
  final bool isCramped;

  /// Drawn before the label.
  final IconData? icon;

  /// What a screen reader announces instead of [label].
  ///
  /// Study Home names the deck here, because a reader hearing *Resume* alone
  /// cannot tell which session it means.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final action = MxActionButton(
      label: label,
      semanticLabel: semanticLabel,
      icon: icon,
      onPressed: onPressed,
    );
    if (isCramped) return action;

    return Align(alignment: AlignmentDirectional.centerStart, child: action);
  }
}
