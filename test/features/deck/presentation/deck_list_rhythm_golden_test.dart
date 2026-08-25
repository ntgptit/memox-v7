@Tags(<String>['golden', 'review'])
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_spacing.dart';
import 'package:memox/core/theme/app_typography.dart';
import 'package:memox/features/deck/domain/models/deck_summary_model.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';
import 'package:memox/features/deck/presentation/widgets/items/deck_tile_widget.dart';
import 'package:memox/features/deck/presentation/widgets/sections/deck_level_summary_widget.dart';
import 'package:memox/features/deck/presentation/widgets/sections/deck_list_toolbar_widget.dart';
import 'package:memox/shared/widgets/mx_navigation_bar.dart';

import '../../../support/study_render.dart';
import '../../../visual_audit/deck_audit_harness.dart';
import 'support/fake_deck_repository.dart';

/// The deck list's vertical rhythm, drawn on top of the deck list.
///
/// **A ruler, not a screen.** Every other golden in this repository answers
/// "does it still look like this". This one answers a question no screenshot
/// can: *are the gaps between the things on screen the numbers they were
/// supposed to be*. It renders the real root deck list, then rules a line
/// across the top and the bottom of every item and prints the distance between
/// consecutive items in the gap itself.
///
/// **Why a picture rather than only assertions.** A failing number tells you a
/// gap is wrong; the picture tells you which two things it is between, and
/// whether the one above or the one below moved. Both are here — the ruler is
/// the golden, and [_offScaleGaps] fails the run outright when a gap is not a
/// spacing token, so a drift cannot survive by nobody looking at the image.
///
/// **What it measures, and what it only draws.** The chain runs title →
/// subtitle → hero → heading row → first deck card, which is the sequence the
/// owner has open questions about. The remaining cards, the floating action and
/// the bottom bar keep their edges so the picture stays whole, but contribute no
/// number: card-to-card spacing was reviewed and accepted, and the other two
/// float over the list rather than sitting in it.
///
/// **Boxes, not ink.** The rules sit on layout edges, which is what a spacing
/// token controls. Where a box holds more air than its ink — the toolbar row is
/// 48 tall around a 12px label, because the sort control's touch target sets it
/// — the picture shows a gap of zero that reads as generous on the device, and
/// that difference is worth seeing rather than hiding.
///
/// This golden lives beside the feature rather than in `test/demo/goldens`, so
/// the screen gallery keeps showing screens.
void main() {
  /// The demo fixture, verbatim from `deck_screens_demo_test.dart`.
  ///
  /// Shared on purpose: the ruler has to measure the same screen the gallery
  /// publishes, or the two pictures describe different apps.
  List<DeckSummary> roots() => <DeckSummary>[
    fakeSummary(
      id: 'd1',
      name: 'Academic Word List',
      totalCardCount: 570,
      newCardCount: 46,
      dueCardCount: 12,
      overdueCardCount: 8,
      overdueDayCount: 7,
      learnedCardCount: 120,
      subDeckCount: 4,
    ),
    fakeSummary(
      id: 'd2',
      name: 'IELTS Writing Task 2',
      totalCardCount: 210,
      dueCardCount: 3,
      learnedCardCount: 145,
      subDeckCount: 2,
    ),
    fakeSummary(
      id: 'd3',
      name: 'Phrasal verbs',
      totalCardCount: 88,
      learnedCardCount: 88,
      subDeckCount: 1,
    ),
    fakeSummary(id: 'd4', name: 'Business email', subDeckCount: 3),
  ];

  testWidgets('deck list — vertical rhythm ruler', (tester) async {
    final app = ReviewApp(
      home: deckShellWith(FakeDeckRepository.withSummaries(roots())),
    );
    await pumpReview(tester, app);

    final bands = _bandsOf(tester);
    final report = _report(bands);
    debugPrint(report);

    // Re-pumped with the ruler over it. The same widget instance, so the screen
    // underneath is the one just measured rather than a second render of it.
    await tester.pumpWidget(
      ReviewApp(
        home: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            app.home,
            IgnorePointer(child: _RhythmRuler(bands: bands)),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    await matchesReviewGolden('goldens/deck_list_rhythm.png');
  });

  test('the heading row groups with the list it names, not with the panel '
      'above it', () {
    // **The rule this replaced was answering the wrong question.** For four
    // passes the gap under the heading carried "a section break no larger than
    // the 16 between two cards makes the heading read as the list's first
    // row" — true of a heading floating *between* two groups, and this one is
    // not floating: it belongs to the list.
    //
    // The ruler drew what that reading cost — 0 above the heading and 24 below
    // — and the owner named it: by proximity the reader groups `YOUR DECKS`
    // with the hero card, because the label sat against the thing it does not
    // describe and away from the cards it does. A grouping defect, not a
    // matter of taste, and no amount of "is this a token" could see it.
    //
    // So the rule is proximity: whatever sits above the heading must be
    // further away than what sits below it.
    expect(
      _gapAboveHeading,
      greaterThan(_gapBelowHeading),
      reason:
          'heading row sits ${_gapAboveHeading.toStringAsFixed(1)} below the '
          'hero and ${_gapBelowHeading.toStringAsFixed(1)} above its first '
          'card — a label has to be nearer the thing it names',
    );
  });

  test('every gap between stacked items is a spacing token', () {
    // The ruler's own assertion, and the reason this file is a test rather than
    // a screenshot. `AppSpacing.scale` is the whole vocabulary; a gap outside it
    // is either a number somebody typed or two paddings that summed by accident,
    // and both are exactly what the picture was drawn to catch.
    //
    // Overlapping items are skipped rather than asserted: the floating action
    // sits over the list by design and the bottom bar covers the scroll's tail,
    // so a negative distance there is the layout working.
    expect(
      _offScaleGaps,
      isEmpty,
      reason:
          'gaps off AppSpacing.scale: ${_offScaleGaps.join(', ')} — either fix '
          'the spacing or add the pair to _allowedOffScale with the reason it '
          'is a sum rather than a choice',
    );
  });
}

/// How the table marks a gap that is not a step: excused, or not.
String _marker(String? from, String to, double? gap) {
  if (gap == null || _isToken(gap)) return '';

  return _allowedOffScale.containsKey('$from -> $to')
      ? '   <-- off scale, excused'
      : '   <-- off scale';
}

/// Filled by the ruler test, read by the assertions that follow it.
final List<String> _offScaleGaps = <String>[];

/// The distance from the hero's foot to the heading row.
double _gapAboveHeading = 0;

/// The distance from the heading row's foot to the first deck card.
double _gapBelowHeading = 0;

/// One thing the screen stacks, and the box it occupies.
typedef _Band = ({String name, Rect rect, bool isInFlow});

List<_Band> _bandsOf(WidgetTester tester) {
  final bands = <_Band>[];

  void collect(String label, Finder finder, {bool isInFlow = true}) {
    final count = finder.evaluate().length;
    for (var i = 0; i < count; i++) {
      bands.add((
        name: count > 1 ? '$label ${i + 1}' : label,
        rect: tester.getRect(finder.at(i)),
        isInFlow: isInFlow,
      ));
    }
  }

  final english = AppLocalizationsEn();

  // **The bar is two bands, not one** (owner review, 2026-08-25). Its box tells
  // you where the chrome ends; what the eye actually reads is the title and the
  // line under it, and the distance between *those* is the decision. So the bar
  // keeps an edge for context and stays out of the chain.
  collect('App bar', find.byType(AppBar), isInFlow: false);
  // **Scoped to the bar.** `find.text('Library')` also matches the bottom
  // navigation's own label, and the first version of this chain measured a gap
  // to it — a number about a tab, printed as if it were about the header.
  collect(
    'Title',
    find.descendant(
      of: find.byType(AppBar),
      matching: find.text(english.decksTitle),
    ),
  );
  collect(
    'Subtitle',
    find.descendant(
      of: find.byType(AppBar),
      matching: find.text(english.deckHeaderStatsLabel(4, 868)),
    ),
  );
  collect('Hero', find.byType(DeckLevelSummaryWidget));
  collect('Heading row', find.byType(DeckListToolbarWidget));
  collect('Deck card', find.byType(DeckTileWidget));
  // **Drawn but not measured against.** Both of these sit *over* the list
  // rather than in it, so a distance from the thing above them is a number
  // about nothing — the first version of this ruler printed `11.9` for the gap
  // between the floating action and the fourth card, which measures the
  // button's own position and not any spacing decision.
  collect('Create', find.byType(FloatingActionButton), isInFlow: false);
  collect('Bottom bar', find.byType(MxNavigationBar), isInFlow: false);

  bands.sort((a, b) => a.rect.top.compareTo(b.rect.top));

  // **The chain stops at the first card** (owner review, 2026-08-25): the gaps
  // between cards were looked at and accepted, so printing them again is noise
  // over the one thing that is not yet settled. They keep their edges, and
  // `_cardGap` still reads the first pair, because the rule about the heading
  // needs a card gap to compare against.
  var seenFirstCard = false;
  for (var i = 0; i < bands.length; i++) {
    final band = bands[i];
    if (!band.name.startsWith('Deck card')) continue;
    if (!seenFirstCard) {
      seenFirstCard = true;
      continue;
    }
    bands[i] = (name: band.name, rect: band.rect, isInFlow: false);
  }

  return bands;
}

/// The table the picture draws, as text, for a terminal and for a diff.
String _report(List<_Band> bands) {
  final buffer = StringBuffer()
    ..writeln('deck list — vertical rhythm')
    ..writeln(
      '${'item'.padRight(14)}${'top'.padLeft(8)}'
      '${'bottom'.padLeft(9)}${'height'.padLeft(8)}${'gap'.padLeft(8)}',
    );

  _offScaleGaps.clear();
  double? previousBottom;
  String? previousName;
  for (final band in bands) {
    final gap = !band.isInFlow || previousBottom == null
        ? null
        : band.rect.top - previousBottom;
    buffer.writeln(
      '${band.name.padRight(14)}'
      '${band.rect.top.toStringAsFixed(1).padLeft(8)}'
      '${band.rect.bottom.toStringAsFixed(1).padLeft(9)}'
      '${band.rect.height.toStringAsFixed(1).padLeft(8)}'
      '${gap == null ? '—'.padLeft(8) : gap.toStringAsFixed(1).padLeft(8)}'
      '${_marker(previousName, band.name, gap)}',
    );
    if (gap != null && !_isToken(gap)) {
      final pair = '$previousName -> ${band.name}';
      if (!_allowedOffScale.containsKey(pair)) {
        _offScaleGaps.add('$pair = ${gap.toStringAsFixed(1)}');
      }
    }
    if (gap != null && previousName == 'Heading row') _gapBelowHeading = gap;
    if (gap != null && band.name == 'Heading row') _gapAboveHeading = gap;
    if (band.isInFlow) {
      previousBottom = band.rect.bottom;
      previousName = band.name;
    }
  }

  return buffer.toString();
}

/// Distances that are not steps and are allowed to stay, with the reason.
///
/// **One entry, and it is a sum rather than a choice.** From the subtitle's
/// foot to the hero measures 24.5: the app bar keeps 16.5 under its title block
/// and the summary section adds `sm` on top of that. The 16.5 is not a number
/// anybody typed — `MxContentShell._toolbarHeight` computes the bar from
/// `titleLarge * _lineFactor + sm + compactLineHeight + md`, and the half pixel
/// falls out of that multiplication. Chasing it would mean changing a shared
/// shell's height arithmetic to move a distance the eye reads as `xl`.
///
/// Keyed by the pair, so an entry cannot quietly cover a second gap that drifts
/// to the same value somewhere else on the screen.
const Map<String, String> _allowedOffScale = <String, String>{
  'Subtitle -> Hero':
      '16.5, and every pixel of it belongs to the bar: '
      'MxContentShell._toolbarHeight computes its height from '
      'titleLarge * _lineFactor + sm + compactLineHeight + md, which leaves '
      '16.5 under the subtitle. The summary section adds nothing on top of it '
      'any more. The half pixel is that multiplication, not a spacing choice.',
};

/// Whether a distance is one of the spacing steps, or an overlap.
///
/// Zero counts: two boxes that touch is a deliberate arrangement here — the
/// heading row's own height carries the air. A negative distance is an overlap,
/// which the floating action and the bottom bar both make on purpose.
bool _isToken(double gap) {
  if (gap <= 0) return true;

  return AppSpacing.scale.any((step) => (gap - step).abs() < 0.5);
}

/// Draws the ruler: a line on each edge, the name beside it, the distance in
/// the gap it measures.
///
/// **A widget, not a `CustomPainter`, and the reason is the first render.** A
/// `TextPainter` built inside a painter resolves its font itself, and in the
/// golden harness that means the fallback — every label came out a solid black
/// box. A `Text` under the app's own `MaterialApp` inherits the loaded family,
/// so the ruler reads.
class _RhythmRuler extends StatelessWidget {
  const _RhythmRuler({required this.bands});

  final List<_Band> bands;

  static const Color _edge = Color(0xCCE11D48);
  static const Color _ink = Color(0xFF0F172A);
  static const Color _tokenFill = Color(0xF2FDE68A);
  static const Color _offScaleFill = Color(0xF2FCA5A5);

  /// Off the scale, but carrying a reason in [_allowedOffScale]. A third colour
  /// rather than red, because the picture has to say what the test says — a red
  /// chip beside a passing run teaches a reader to distrust one of the two.
  static const Color _excusedFill = Color(0xF2FDBA74);
  static const Color _nameFill = Color(0xF2E0E7FF);

  @override
  Widget build(BuildContext context) {
    final labels = <Widget>[];

    for (final band in bands) {
      labels.add(
        Positioned(
          left: 4,
          // Above its own top line rather than below it: at `top + 1` the chip
          // covered the first line of whatever it names — the subtitle lost
          // three characters to its own label in the render before this.
          top: math.max(0, band.rect.top - 11),
          child: _chip(band.name, _nameFill, 9),
        ),
      );
    }

    double? previousBottom;
    String? previousName;
    for (final band in bands) {
      final gap = !band.isInFlow || previousBottom == null
          ? null
          : band.rect.top - previousBottom;
      // A zero is drawn too: two boxes that touch is a fact worth seeing, and
      // the hero and the heading row do exactly that.
      if (gap != null && gap >= 0) {
        labels.add(
          Positioned(
            right: 6,
            top: previousBottom! + gap / 2 - 8,
            child: _chip(
              gap.toStringAsFixed(gap == gap.roundToDouble() ? 0 : 1),
              _fillFor(previousName, band.name, gap),
              11,
            ),
          ),
        );
      }
      if (band.isInFlow) {
        previousBottom = band.rect.bottom;
        previousName = band.name;
      }
    }

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        CustomPaint(painter: _EdgeLines(bands)),
        ...labels,
      ],
    );
  }

  Color _fillFor(String? from, String to, double gap) {
    if (_isToken(gap)) return _tokenFill;

    return _allowedOffScale.containsKey('$from -> $to')
        ? _excusedFill
        : _offScaleFill;
  }

  Widget _chip(String text, Color background, double fontSize) => ColoredBox(
    color: background,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
      child: Text(
        text,
        textDirection: TextDirection.ltr,
        // **The family is stated.** A bare `TextStyle` falls back to the
        // harness default, which paints every glyph as a filled box — the
        // ruler's first two renders were unreadable for exactly that reason.
        style: TextStyle(
          fontFamily: AppTypography.bodyFamily,
          fontFamilyFallback: AppTypography.cjkFallback,
          color: _ink,
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          height: 1.2,
        ),
      ),
    ),
  );
}

/// The hairlines themselves — one on each edge of every band.
class _EdgeLines extends CustomPainter {
  const _EdgeLines(this.bands);

  final List<_Band> bands;

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = _RhythmRuler._edge
      ..strokeWidth = 1;
    for (final band in bands) {
      for (final y in <double>[band.rect.top, band.rect.bottom]) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
      }
    }
  }

  @override
  bool shouldRepaint(_EdgeLines oldDelegate) => oldDelegate.bands != bands;
}
