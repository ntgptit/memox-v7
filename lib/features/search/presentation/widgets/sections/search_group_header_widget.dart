import 'package:flutter/material.dart';

import '../../../../../core/theme/app_ink.dart';
import '../../../../../core/theme/theme_context_extension.dart';
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
    return Semantics(
      header: true,
      // Rendered exactly as the ARB authored it. `toUpperCase()` on a localized
      // string is the translator's decision to make, not the widget's — it is
      // wrong for locales with no case and changes the width the layout was
      // measured at.
      child: Text(
        context.mxSearchGroupLabel(group),
        // **No `sectionLabelTracking`.** That token exists to open up 11px
        // *uppercase*, which is what every other section label in the app is;
        // this one renders as authored, so the extra 1.1px would be loosening
        // lowercase text the type scale has already spaced.
        // Through the wght axis — a bare `fontWeight:` paints the rung's
        // old weight.
        style: context.texts.labelSmall!.inked(
          context,
          AppInk.quiet,
          isEmphasized: true,
        ),
      ),
    );
  }
}
