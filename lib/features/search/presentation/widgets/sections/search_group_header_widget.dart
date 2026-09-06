import 'package:flutter/material.dart';

import '../../../../../shared/widgets/mx_section_label.dart';
import '../../../domain/models/search_result_model.dart';
import '../support/search_labels_widget.dart';

/// The label above one group of results.
///
/// **A header rather than two visually different lists.** Decks and cards open
/// onto different things, so the eye needs to know which kind a row is before it
/// decides to tap — and a label is cheaper chrome than two card treatments,
/// which is what the design asked for.
///
/// **No count.** The list is paged, so a number here would be the number
/// *loaded* rather than the number found, and a header reading "Decks · 20" over
/// a list with more behind it is a wrong answer confidently given. What is
/// complete is stated once, on the field, and only once everything is in.
class SearchGroupHeaderWidget extends StatelessWidget {
  const SearchGroupHeaderWidget({required this.group, super.key});

  final SearchResultGroup group;

  @override
  Widget build(BuildContext context) {
    // **The app's one section-heading treatment** (D18), at its default
    // `standard` rung: `sectionLabel` = 12 / w500 / tracking 1.1, uppercased at
    // paint, with the ARB sentence kept as the accessible name and the node
    // marked `header` — so the component supplies the `Semantics(header: true)`
    // this file used to wrap by hand.
    //
    // **Why this file no longer renders the string exactly as authored.** It
    // refused `toUpperCase()` on the grounds that the case of a localized
    // string "is the translator's decision to make, not the widget's". A19 §7
    // agreed and asked the shared component to adopt the rule; A20.1 P2-02
    // answered the argument instead of overriding it — uppercasing a caseless
    // string is the identity, and what a reader hears is the sentence, not the
    // shouting (`mx_section_label.dart:34-36`). What the refusal actually cost
    // was hierarchy: at `labelSmall` emphasised, this heading was the same 11px
    // and the same quiet ink as the path caption printed *inside* the rows it
    // heads, one weight step apart, so a group read as three peer caption lines
    // rather than a heading over a list.
    //
    // **Not `small`, not `list`.** `MxSectionLabelRung.small` is
    // `sectionLabelSmall` — labelSmall, 11px, the caption's own size — so it
    // would keep the very defect this closes; it is reserved for a face label
    // inside a card. `list` exists only because the deck toolbar's heading
    // shares its row with the sort control (`app_typography.dart:151-160`).
    // This header has no control beside it, so `standard` is the rung.
    return MxSectionLabel(label: context.mxSearchGroupLabel(group));
  }
}
