import 'package:flutter/material.dart';

import '../../../../../core/theme/app_ink.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/theme_context_extension.dart';

/// One labelled group of the settings screen: a heading, then a card.
///
/// **The frame is shared so the three groups cannot drift apart** (wireframe
/// W5). Three groups each building their own heading and card is three chances
/// for one of them to pick a different gap, and four pixels between two cards
/// twenty-four apart is invisible to the eye and obvious in a `getRect`
/// assertion — which is to say, it ships.
///
/// The heading is a real `Text` in the tree, in reading order above its group.
/// That is what gives a screen-reader user the context to tell three rows all
/// labelled `System` apart (W6).
class SettingsSectionWidget extends StatelessWidget {
  const SettingsSectionWidget({
    required this.label,
    required this.child,
    super.key,
  });

  /// Already-localized. The screen owns the copy.
  final String label;

  final Widget child;

  /// The gap between a heading and the card it labels.
  ///
  /// Named because the geometry contract measures it and a literal in two
  /// places is two numbers that can disagree.
  static const double headingGap = AppSpacing.xs;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      Align(
        alignment: AlignmentDirectional.centerStart,
        // **The app's one section-heading treatment** (D18). It was
        // `labelLarge`, which resolves to the same Inter w600 14/20 as
        // `titleSmall` — the role the field labels *inside* the card use — so a
        // group heading and the field under it rendered identically and the
        // heading carried no hierarchy at all. This screen's own design preview
        // already had it right.
        // The **written** sentence is the accessible name; the uppercase is a
        // typographic treatment. Some TTS engines spell an all-caps run out
        // letter by letter, and these headings are what tell three rows all
        // labelled "System" apart.
        child: Semantics(
          label: label,
          excludeSemantics: true,
          child: Text(
            label.toUpperCase(),
            style: context.textStyles.sectionLabel.inked(context, AppInk.quiet),
          ),
        ),
      ),
      const SizedBox(height: headingGap),
      child,
    ],
  );
}
