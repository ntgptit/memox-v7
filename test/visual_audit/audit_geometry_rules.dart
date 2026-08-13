import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'audit_model.dart';
import 'audit_rules.dart';
import 'screen_auditor.dart';

/// The audit's geometry half: rules that read *where* things landed rather
/// than what colour they are. Split from `audit_rules.dart` for size only —
/// that file re-exports this one, so a screen audit keeps one import.
/// **Every row of surfaces spans the content column.**
///
/// The rule exists because of a defect that four gates missed and a human
/// found on a device: two cards sat in a `Wrap`, which sizes children to their
/// *intrinsic* width, so the row ended 25dp short of the column and read as
/// indented against every other band. `flutter analyze` and the guard read
/// source text and cannot see a laid-out rectangle. The colour rules above
/// read paint, not position. A golden compares a screen with yesterday's copy
/// of itself, so an edge that is wrong from the first render passes forever.
/// Geometry needed a gate of its own.
///
/// **Surfaces, not every box.** The caller decides what a surface is — in this
/// project, the one card component. That vocabulary is what keeps the rule
/// quiet: a row of chips or a breadcrumb is text with a background, not a band
/// of the page, and holding those to the column's edges would be noise.
///
/// The column is measured, never configured: its edges are the leftmost and
/// rightmost any surface reaches on this screen. A screen whose surfaces are
/// all deliberately narrow therefore passes — the rule judges *consistency*,
/// which is what the eye actually reads, not an absolute inset.
class SurfaceColumnRule implements AuditRule {
  const SurfaceColumnRule({this.epsilon = 0.5, this.rowOverlap = 0.5});

  /// A hairline. `Border.all` paints inside the box and antialiasing lands a
  /// fraction either way; anything above this is a layout decision.
  final double epsilon;

  /// How much two surfaces must overlap vertically to count as one row.
  ///
  /// Half the shorter one: cards in a row rarely have identical heights once
  /// one of them wraps, and a stricter test would split a row in two and then
  /// pass both halves.
  final double rowOverlap;

  @override
  String get name => 'surface-column';

  @override
  Iterable<AuditFinding> check(ScreenAudit audit) sync* {
    // Nested surfaces are the inner card's business, not the column's: a panel
    // inside a card is placed against *that* card's padding.
    final outer = audit.surfaces
        .where(
          (rect) => !audit.surfaces.any(
            (other) =>
                other != rect &&
                other.contains(rect.center) &&
                other.width > rect.width,
          ),
        )
        .toList();
    if (outer.length < 2) return;

    final left = outer.map((r) => r.left).reduce(math.min);
    final right = outer.map((r) => r.right).reduce(math.max);

    for (final row in _rows(outer)) {
      final union = row.reduce((a, b) => a.expandToInclude(b));
      final startsLate = union.left - left > epsilon;
      final endsEarly = right - union.right > epsilon;
      if (!startsLate && !endsEarly) continue;

      yield AuditFinding(
        rule: name,
        itemId: rootItemId,
        message:
            'a row of ${row.length} surface(s) at y=${union.top.round()} spans '
            '${union.left.round()}..${union.right.round()} while the column is '
            '${left.round()}..${right.round()} — a band either fills the '
            'column or stacks; sizing to content leaves dead space the eye '
            'reads as a wrong indent.',
        isBlocking: true,
      );
    }
  }

  /// Surfaces grouped into rows by vertical overlap, each row left-to-right.
  List<List<Rect>> _rows(List<Rect> surfaces) {
    final sorted = surfaces.toList()..sort((a, b) => a.top.compareTo(b.top));
    final rows = <List<Rect>>[];
    for (final rect in sorted) {
      final row = rows.isEmpty ? null : rows.last;
      if (row != null && _sharesRow(row.last, rect)) {
        row.add(rect);
        continue;
      }
      rows.add(<Rect>[rect]);
    }

    return rows;
  }

  bool _sharesRow(Rect a, Rect b) {
    final overlap = math.min(a.bottom, b.bottom) - math.max(a.top, b.top);

    return overlap > math.min(a.height, b.height) * rowOverlap;
  }
}
