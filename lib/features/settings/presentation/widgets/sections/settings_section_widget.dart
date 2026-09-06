import 'package:flutter/material.dart';

import '../../../../../core/theme/foundations/app_spacing.dart';
import '../../../../../shared/widgets/mx_section_label.dart';

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
  ///
  /// **`sm`, the app's one label-to-content step** (`m99-23-progress-overview.md`
  /// G7). At `xs` this screen bound its headings four pixels above their
  /// cards while every other surface using the same standard-rung
  /// `MxSectionLabel` bound them at twelve — with both screens separating
  /// their bands at `xl`, the heading-to-content ratio was 24:4 here and
  /// 24:12 everywhere else, so one component read as two (SC-C5-06). The
  /// value was settled for the whole cluster rather than for this screen:
  /// `sm` is the only one of the three written down as a rule, and the
  /// six card-feature call sites moved to it in the same commit.
  static const double headingGap = AppSpacing.sm;

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
        // `MxSectionLabel` is this pattern, promoted (A20.1 P2-02).
        child: MxSectionLabel(label: label),
      ),
      const SizedBox(height: headingGap),
      child,
    ],
  );
}
