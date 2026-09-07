import 'package:flutter/rendering.dart' show MatrixUtils;
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

/// Asserts that a screen reader walks the screen the way a reader does.
///
/// **The order is a separate fact from the labels.** Every accessibility sweep
/// in this repo asks whether a target is big enough and whether it carries a
/// name; none of them asks what order those names arrive in. They all pass on a
/// screen that announces its footer before its heading, because nothing looked.
///
/// **What this can actually fail on.** Flutter derives traversal from geometry,
/// so on a screen that only ever lays widgets out this assertion agrees with
/// the framework by construction. It earns its place on the day something
/// separates the two: an `OrdinalSortKey`, a `SemanticsSortKey`, an explicit
/// `sortKey` on a `Semantics` widget, or an `Overlay` whose contents outlive
/// the layout that placed them. This repo uses no sort key anywhere, and that
/// is a state worth holding rather than a coincidence worth discovering later
/// — `expectTraversalFollowsReadingOrder` is what turns it into a fact.
///
/// **Geometry comes from the semantics tree, not from a finder.** Resolving a
/// node's label back through `find.bySemanticsLabel` was tried and abandoned:
/// a label belongs to a node, and the widget the finder returns for it can be
/// an ancestor covering a different rectangle. It reported the card editor
/// reading its footer backwards, which it does not.
///
/// **Reading order, not raw top-to-bottom.** Two nodes on the same line are
/// compared left to right; only nodes on different lines must descend.
/// [rowTolerance] is what counts as "the same line" and absorbs the sub-pixel
/// drift of a baseline-aligned row.
void expectTraversalFollowsReadingOrder(
  WidgetTester tester, {
  double rowTolerance = 4,
}) {
  Rect globalRect(SemanticsNode node) {
    var rect = node.rect;
    for (
      SemanticsNode? current = node;
      current != null;
      current = current.parent
    ) {
      final transform = current.transform;
      if (transform != null) rect = MatrixUtils.transformRect(transform, rect);
    }

    return rect;
  }

  final placed = tester.semantics
      .simulatedAccessibilityTraversal()
      .where((node) => node.label.trim().isNotEmpty)
      .map((node) => (label: node.label.trim(), rect: globalRect(node)))
      .toList();

  for (var i = 1; i < placed.length; i++) {
    final previous = placed[i - 1];
    final current = placed[i];
    final onTheSameLine =
        current.rect.top < previous.rect.bottom - rowTolerance &&
        previous.rect.top < current.rect.bottom - rowTolerance;
    final where = '"${previous.label}" then "${current.label}"';

    if (onTheSameLine) {
      expect(
        current.rect.left,
        greaterThanOrEqualTo(previous.rect.left - rowTolerance),
        reason:
            'traversal runs backwards along a line: $where — a screen reader '
            'would read the right of the row before its left',
      );
      continue;
    }
    expect(
      current.rect.top,
      greaterThanOrEqualTo(previous.rect.top - rowTolerance),
      reason:
          'traversal runs back up the screen: $where — a screen reader would '
          'reach the lower element first and then jump above it',
    );
  }
}
