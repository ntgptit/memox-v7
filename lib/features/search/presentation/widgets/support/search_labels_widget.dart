import 'package:flutter/widgets.dart';

import '../../../../../l10n/l10n_extension.dart';
import '../../../domain/models/search_result_model.dart';

/// Presentation mapping both search sections need, in the one bucket that is
/// meant to be read across the others (AD-15).
///
/// **A `_widget.dart` file with no widget in it, deliberately.** Deck's
/// `deck_labels_widget.dart` made the same call and the rename away from it was
/// reverted: the suffix is what puts a file inside the scope of the widget
/// rules, so a `_extension.dart` here would quietly leave those rules covering
/// one file fewer.
extension SearchLabels on BuildContext {
  /// A deck path as one line: `Korean › Nouns › Food`.
  ///
  /// **One separator, defined once, and it comes from the ARB.** Two rows
  /// drawing the trail with two different glyphs is the kind of difference
  /// nobody reports and everybody notices — and the deck row and the card row
  /// are two files. The glyph is localized rather than hardcoded because this
  /// string is user-visible twice: it is drawn, and it is read aloud between
  /// every pair of names inside the row's semantic label. `MxBreadcrumb` solved
  /// the same problem with a decorative *icon*; a text separator has no such
  /// escape, so it belongs to the translator.
  String mxDeckPathLine(List<String> path) =>
      path.join(l10n.librarySearchPathSeparator);

  /// The name of the group a row belongs to — the section header, and what a
  /// screen reader announces before the row itself.
  String mxSearchGroupLabel(SearchResultGroup group) => switch (group) {
    SearchResultGroup.decks => l10n.librarySearchDecksGroupLabel,
    SearchResultGroup.cards => l10n.librarySearchCardsGroupLabel,
  };
}
