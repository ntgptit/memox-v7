import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// M4.12's "design parity below 3%", made executable.
///
/// **Why this is not a pixel comparison.** The checklist item reads "screens
/// with a design reference reach a pixel difference under 3%", and M4.10 and
/// M4.11 both recorded that it could not be applied — different scope on the two
/// sides of the comparison, then no card-list screen in the kit at all. There is
/// a deeper reason to stop trying: the design side renders in Chrome from CSS and
/// the app side renders through Skia. Antialiasing, font hinting and the kit's
/// CDN icon glyphs put a floor under the difference that no amount of parity work
/// moves, so a percentage from that comparison measures the renderers rather than
/// the design. A number that cannot reach its threshold no matter how correct the
/// app is, is not a gate.
///
/// **What is measured instead.** `docs/reviews/design-parity-checklist.md` pairs
/// every artefact in `design_system/` with what it maps to in `lib/`, one row
/// each, and each row carries a verdict. The parity number is the share of those
/// rows still recorded as an open **drift** — a real difference nobody has closed
/// or accepted. Same threshold, on a quantity that is about the design rather
/// than about two rasterisers.
///
/// **The token half is already covered elsewhere.** `css_token_parity_test.dart`
/// and `css_scale_parity_test.dart` compare `design_system/tokens/*.css` against
/// the Dart constants directly. This covers what a token comparison cannot see:
/// which token a component reaches for, states, layout and behaviour.
///
/// **What it cannot see** — worth stating because it already failed this way
/// once. The gate reads the checklist, so it is only as current as the review
/// that wrote it: nine rows sat at **drift** for three milestones after the code
/// had moved, and no test noticed, because the file said "drift" and the file is
/// what the file says. It stops a *known* difference being forgotten. Keeping the
/// file true to `lib/` is a reading task, not a test.
void main() {
  /// The share of reviewed rows allowed to be open drift.
  ///
  /// 3% of the current 80 rows is 2.4 — so two open rows pass and three fail.
  /// The number comes from `docs/checklist.md` 15.x, kept as written even though
  /// the quantity underneath it changed.
  const double maxDriftRatio = 0.03;

  /// A verdict opens with exactly one of these, in bold. Closed on purpose: an
  /// unrecognised word is a row that no longer says which of the six situations
  /// it is in, and the gate cannot count what it cannot classify.
  const Set<String> verdicts = <String>{
    'match',
    'resolved',
    'divergence',
    'design-gap',
    'blocked',
    'drift',
    'n/a',
  };

  /// The table rows live between these two headings. The bound matters: the
  /// divergence table further down numbers its rows `F3`, `F16`, `C10` in the
  /// same shape as a checklist ID, and counting those would inflate the
  /// denominator with rows that are summaries of rows already counted.
  const String firstHeading = '## A · Tokens';
  const String lastHeading = '## Excluded, deliberately';

  /// `| B2 | … | [x] | **resolved** … |`
  ///
  /// Anchored on the status box rather than on column position, because the
  /// tables have five columns in some sections and six in others, and a verdict
  /// may itself contain a pipe inside inline code.
  final RegExp rowPattern = RegExp(
    r'^\| ([A-Z]\d+) \|.* \[([x ])\] \| (.*?) \|?$',
  );
  final RegExp idPattern = RegExp(r'^\| ([A-Z]\d+) \|');
  final RegExp verdictPattern = RegExp(r'^\*\*(.+?)\*\*');

  late List<({String id, bool isReviewed, String verdict})> rows;

  setUpAll(() {
    final lines = File(
      'docs/reviews/design-parity-checklist.md',
    ).readAsLinesSync();

    final start = lines.indexWhere((line) => line.startsWith(firstHeading));
    final end = lines.indexWhere((line) => line.startsWith(lastHeading));
    expect(
      start >= 0 && end > start,
      isTrue,
      reason:
          'The checklist no longer has the headings this gate reads between '
          '("$firstHeading" … "$lastHeading"). Renaming a section silently '
          'empties the gate, so it fails here instead.',
    );

    rows = <({String id, bool isReviewed, String verdict})>[];
    for (final line in lines.getRange(start, end)) {
      if (!idPattern.hasMatch(line)) continue;

      final match = rowPattern.firstMatch(line);
      // A row with an ID but no status box: the gate would skip it and the row
      // would be reviewed by nobody, which is the one failure mode a checklist
      // cannot afford.
      expect(
        match,
        isNotNull,
        reason:
            'This row has an ID but no `[x]`/`[ ]` status box, so it is outside '
            'every count below:\n$line',
      );

      rows.add((
        id: match!.group(1)!,
        isReviewed: match.group(2) == 'x',
        verdict: match.group(3)!.trim(),
      ));
    }
  });

  test('every row is reviewed and carries a verdict from the closed set', () {
    expect(rows, isNotEmpty, reason: 'No rows parsed — see the heading check.');

    final ids = rows.map((row) => row.id).toList();
    expect(
      ids.toSet(),
      hasLength(ids.length),
      reason: 'Two rows share an ID, so one of them cannot be cited.',
    );

    final unreviewed = rows.where((row) => !row.isReviewed).map((r) => r.id);
    expect(
      unreviewed,
      isEmpty,
      reason:
          'Unreviewed rows cannot be counted as parity — an artefact nobody '
          'compared is not the same as one that matches.',
    );

    for (final row in rows) {
      final label = verdictPattern.firstMatch(row.verdict)?.group(1);
      expect(
        label,
        isNotNull,
        reason: '${row.id} does not open with a bold verdict:\n${row.verdict}',
      );
      expect(
        verdicts,
        contains(label),
        reason:
            '${row.id} opens with "$label", which is not one of the six the '
            'status key defines. Prose belongs after the verdict, not instead '
            'of it.',
      );
    }
  });

  test('open drift stays under 3% of the reviewed rows', () {
    final open = rows
        .where(
          (row) => verdictPattern.firstMatch(row.verdict)?.group(1) == 'drift',
        )
        .toList();
    final ratio = open.length / rows.length;

    expect(
      ratio,
      lessThan(maxDriftRatio),
      reason:
          'Design parity: ${open.length} of ${rows.length} rows are open drift '
          '(${(ratio * 100).toStringAsFixed(1)}%), over the '
          '${(maxDriftRatio * 100).toStringAsFixed(0)}% gate.\n'
          'Open: ${open.map((row) => row.id).join(', ')}\n'
          'Close each one by moving Dart to the design, or record it as a '
          'measured **divergence** in the table at the foot of the checklist. '
          'Relabelling without doing either is how the file went stale before.',
    );
  });
}
