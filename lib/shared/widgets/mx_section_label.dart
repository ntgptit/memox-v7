import 'package:flutter/material.dart';

import '../../core/theme/extensions/app_ink.dart';
import '../../core/theme/extensions/theme_context_extension.dart';

/// Which rung a section label is set at.
enum MxSectionLabelRung {
  /// `sectionLabel` — the app's one section-heading treatment (D18).
  standard,

  /// `sectionLabelSmall` — a face label inside a card, one step down.
  small,

  /// `listHeading` — the heading over a list, one weight up.
  list,
}

/// A heading set in caps, with the written sentence as its accessible name.
///
/// **All-caps had three policies** (A20.1 P2-02, §13): sixteen headings
/// uppercased a localized string and exposed the uppercase run to a screen
/// reader — some TTS engines spell an all-caps run out letter by letter —
/// one did it correctly (`settings_section_widget`, the pattern this widget
/// is), and one refused to uppercase at all. One widget, one policy: the
/// uppercase is a typographic treatment applied at paint, the accessible name
/// is the sentence the ARB wrote, and the node is a `header` so a reader can
/// jump to it.
///
/// **What is deliberately not a section label.** A format identifier — `CSV`,
/// `JSON` — is uppercase *as written* and a reader spelling it out is desired;
/// a state chip is a classification, not a heading; and a composed string
/// belongs to the screen that composed it. None of those come through here.
///
/// **Locales without case** are the translator's decision: `toUpperCase()` on
/// a string with no case is the identity, so this widget is correct there by
/// construction and adds nothing a translator has to undo.
class MxSectionLabel extends StatelessWidget {
  const MxSectionLabel({
    required this.label,
    this.detail,
    this.rung = MxSectionLabelRung.standard,
    this.emphasis = MxSectionLabelEmphasis.quiet,
    super.key,
  });

  /// Already-localized. Painted in caps; announced as written.
  final String label;

  /// A figure beside the label — `YOUR DECKS · 12` — painted as given and
  /// announced after the label. Never uppercased: it is data, not a heading.
  final String? detail;

  final MxSectionLabelRung rung;

  final MxSectionLabelEmphasis emphasis;

  @override
  Widget build(BuildContext context) {
    final styles = context.textStyles;
    final TextStyle base = switch (rung) {
      MxSectionLabelRung.standard => styles.sectionLabel,
      MxSectionLabelRung.small => styles.sectionLabelSmall,
      MxSectionLabelRung.list => styles.listHeading,
    };
    final AppInk ink = switch (emphasis) {
      MxSectionLabelEmphasis.quiet => AppInk.quiet,
      MxSectionLabelEmphasis.stated => AppInk.stated,
    };
    final String painted = detail == null
        ? label.toUpperCase()
        : '${label.toUpperCase()} · $detail';
    // `written` rather than the field name on the left of the ternary: the
    // i18n guard's regex cannot tell a ternary branch from a named argument.
    final String written = label;
    final String spoken = detail == null ? written : '$written · $detail';

    return Semantics(
      header: true,
      label: spoken,
      excludeSemantics: true,
      child: Text(
        painted,
        style: base.inked(context, ink),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

/// How loud the label is.
enum MxSectionLabelEmphasis {
  /// `onSurfaceVariant` — the usual heading over a group.
  quiet,

  /// `onSurface` — a panel's own title, which introduces the line under it
  /// rather than captioning it.
  stated,
}
