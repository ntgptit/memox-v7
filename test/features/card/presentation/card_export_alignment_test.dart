import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/card/domain/failures/card_export_failure.dart';
import 'package:memox/features/card/domain/models/card_transfer_format_model.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_export_action_bar_widget.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_export_content_lines_widget.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_export_error_band_widget.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_export_format_options_widget.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_export_scope_summary_widget.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';
import 'package:memox/shared/widgets/mx_card.dart';

import 'support/card_export_sheet_harness.dart';

/// **The export sheet's geometry contract (wireframe M4.13 W5), measured.**
///
/// W5 was written *before* the sheet was built, because the equivalent
/// contract was missing at Card Import and the gap became review finding V9:
/// two option cards sat in a `Wrap`, which sizes children to their intrinsic
/// width, so the band ended 25dp short of the column while every other gate
/// stayed green. `flutter analyze` and the guard read source text and cannot
/// see a laid-out rectangle; the visual audit reads colour, not geometry; and
/// a golden only compares a screen with yesterday's copy of itself, so an edge
/// that is wrong but *stable* passes forever.
///
/// The rule: the sheet has one content column, and every band honours it —
/// title, scope summary, the format band, the two info lines, the error band
/// and the action row — measured as the widgets a reader sees, never as the
/// invisible box holding them.
void main() {
  final h = installCardExportSheetHarness();
  final AppLocalizationsEn english = h.english;

  /// A hairline, not a design allowance: `Border.all` paints inside the box
  /// and antialiasing may land a fraction either way.
  const double epsilon = 0.5;

  /// Wide enough that the sheet reaches its 640dp cap and the three options
  /// clear the row threshold — the only shape in which W5's `Expanded` clause
  /// can be exercised at all.
  const wideSurface = Size(900, 900);

  Finder cardHolding(Finder content) =>
      find.ancestor(of: content, matching: find.byType(MxCard)).first;

  Finder optionCard(CardTransferFormat format) =>
      cardHolding(find.text(format.fileExtension.toUpperCase()));

  void expectSharedEdges(WidgetTester tester, Map<String, Finder> bands) {
    final entries = bands.entries.toList();
    final first = tester.getRect(entries.first.value);
    for (final entry in entries.skip(1)) {
      final rect = tester.getRect(entry.value);
      expect(
        rect.left,
        moreOrLessEquals(first.left, epsilon: epsilon),
        reason:
            '${entry.key} starts at ${rect.left}, ${entries.first.key} at '
            '${first.left} — the sheet has one left edge.',
      );
      expect(
        rect.right,
        moreOrLessEquals(first.right, epsilon: epsilon),
        reason:
            '${entry.key} ends at ${rect.right}, ${entries.first.key} at '
            '${first.right} — the sheet has one right edge.',
      );
    }
  }

  /// Every band, as the widget a reader sees it as.
  ///
  /// **Two of these are measured by type and not by their text, and the reason
  /// is the same both times.** The scope summary and the content lines are
  /// icon-led, so their `Text` starts one glyph and one gap *inside* the
  /// column — 40.0 against the column's 16.0 — while the band itself starts at
  /// the column edge, which is what W5 is about. Measuring the inner `Text`
  /// there would fail a layout that is correct; measuring an invisible wrapper
  /// would pass one that is not. The band is the thing on screen.
  Map<String, Finder> bandsOf({required bool hasError}) => <String, Finder>{
    'title': find.text(english.cardExportEntryAction),
    'scope summary': find.byType(CardExportScopeSummaryWidget),
    'format heading': find.text(english.cardExportFormatHeading),
    'format options': find.byType(CardExportFormatOptionsWidget),
    'content lines': find.byType(CardExportContentLinesWidget),
    if (hasError) 'error band': find.byType(CardExportErrorBandWidget),
    'action row': find.byType(CardExportActionBarWidget),
  };

  testWidgets('initial: every band shares the content column', (tester) async {
    await h.pump(tester);
    await h.openWholeDeckExport(tester);

    expectSharedEdges(tester, bandsOf(hasError: false));
  });

  testWidgets('error: the band is part of the column, not a box inset into '
      'it', (tester) async {
    h.exports.nextReadFailure = const DatabaseFailure(
      message: 'read failed',
      reason: CardExportProblem.readFailed,
    );
    await h.pump(tester);
    await h.openWholeDeckExport(tester);
    await tester.tap(
      find.widgetWithText(FilledButton, english.cardExportSubmitAction(3)),
    );
    await tester.pumpAndSettle();

    expectSharedEdges(tester, bandsOf(hasError: true));
  });

  testWidgets('stacked: each format option fills the whole column', (
    tester,
  ) async {
    await h.pump(tester);
    await h.openWholeDeckExport(tester);

    final column = tester.getRect(find.text(english.cardExportFormatHeading));
    for (final format in CardTransferFormat.values) {
      final rect = tester.getRect(optionCard(format));
      expect(
        rect.left,
        moreOrLessEquals(column.left, epsilon: epsilon),
        reason: '${format.name} starts the column',
      );
      expect(
        rect.right,
        moreOrLessEquals(column.right, epsilon: epsilon),
        reason:
            '${format.name} must fill the column when stacked — it ended at '
            '${rect.right} against ${column.right}',
      );
    }
  });

  testWidgets('in a row: the three options fill the column, first to last, '
      'in equal widths', (tester) async {
    await h.pump(tester, surface: wideSurface);
    await h.openWholeDeckExport(tester);

    final column = tester.getRect(find.text(english.cardExportFormatHeading));
    final rects = <CardTransferFormat, Rect>{
      for (final format in CardTransferFormat.values)
        format: tester.getRect(optionCard(format)),
    };
    // Actually laid out as a row, or the rest of this proves nothing.
    expect(
      rects.values.map((rect) => rect.top).toSet(),
      hasLength(1),
      reason: 'the wide case must put the three options on one row',
    );

    final first = rects[CardTransferFormat.values.first]!;
    final last = rects[CardTransferFormat.values.last]!;
    expect(
      first.left,
      moreOrLessEquals(column.left, epsilon: epsilon),
      reason: 'the first option starts the column',
    );
    expect(
      last.right,
      moreOrLessEquals(column.right, epsilon: epsilon),
      reason:
          'the last option ends the column — it ended at ${last.right} '
          'against ${column.right}. This is the Wrap defect: the row is '
          'full-width while the cards are not.',
    );
    for (final entry in rects.entries) {
      expect(
        entry.value.width,
        moreOrLessEquals(first.width, epsilon: epsilon),
        reason: '${entry.key.name} is not an equal share of the row',
      );
      expect(
        entry.value.height,
        moreOrLessEquals(first.height, epsilon: epsilon),
        reason: '${entry.key.name} is not the same height as its neighbours',
      );
    }
  });

  testWidgets('action row: Cancel starts the column and the primary ends it', (
    tester,
  ) async {
    await h.pump(tester);
    await h.openWholeDeckExport(tester);

    final column = tester.getRect(find.byType(CardExportActionBarWidget));
    final cancel = tester.getRect(
      find.widgetWithText(OutlinedButton, english.commonCancelAction),
    );
    final primary = tester.getRect(
      find.widgetWithText(FilledButton, english.cardExportSubmitAction(3)),
    );

    expect(cancel.left, moreOrLessEquals(column.left, epsilon: epsilon));
    expect(primary.right, moreOrLessEquals(column.right, epsilon: epsilon));
    expect(
      cancel.width,
      moreOrLessEquals(primary.width, epsilon: epsilon),
      reason: 'both are Expanded, so the row cannot be two intrinsic buttons',
    );
    expect(cancel.top, moreOrLessEquals(primary.top, epsilon: epsilon));
  });

  testWidgets('320dp at 2.0x: the buttons stack full-width, primary on top', (
    tester,
  ) async {
    await h.pump(tester, surface: const Size(320, 852), textScale: 2);
    await h.openWholeDeckExport(tester);

    // **The title, not `CardExportActionBarWidget`.** Measuring the buttons
    // against the bar that holds them proves only that they fill their own
    // parent — which is exactly the invisible box W5 forbids measuring, and
    // exactly how Card Import's V9 stayed green while the band sat inboard of
    // the column. An action row inset from the body would have passed the old
    // form of this test.
    final column = tester.getRect(find.text(english.cardExportEntryAction));
    final cancelFinder = find.widgetWithText(
      OutlinedButton,
      english.commonCancelAction,
    );
    final primaryFinder = find.widgetWithText(
      FilledButton,
      english.cardExportSubmitAction(3),
    );

    expect(
      tester.getRect(primaryFinder).top,
      lessThan(tester.getRect(cancelFinder).top),
      reason: 'the action the user came for is not the one below the fold',
    );
    for (final entry in <String, Finder>{
      'primary': primaryFinder,
      'cancel': cancelFinder,
      // The format band is held to the same column at this size, which nothing
      // measured before: the old test only checked that it did not overflow.
      'csv option': optionCard(CardTransferFormat.csv),
      'content lines': find.byType(CardExportContentLinesWidget),
    }.entries) {
      final rect = tester.getRect(entry.value);
      expect(rect.left, moreOrLessEquals(column.left, epsilon: epsilon));
      expect(
        rect.right,
        moreOrLessEquals(column.right, epsilon: epsilon),
        reason: '${entry.key} must fill the column once stacked',
      );
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('320x568 at 2.0x: the action row stays on screen and every band '
      'is scrollable to', (tester) async {
    // **568 tall, not the 852 every other test in this feature uses.** The
    // design-system skill puts 320x568 first for a reason, and a bottom sheet
    // is the one surface in this app where viewport *height* changes behaviour:
    // a route is already a scroll view, a sheet grows until it hits the screen
    // and then has to decide what gives.
    await h.pump(tester, surface: const Size(320, 568), textScale: 2);
    await h.openWholeDeckExport(tester);

    expect(tester.takeException(), isNull);

    final action = tester.getRect(find.byType(CardExportActionBarWidget));
    expect(
      action.bottom,
      lessThanOrEqualTo(568 + epsilon),
      reason: 'the action row must stay within the screen it is pinned to',
    );
    expect(action.top, greaterThanOrEqualTo(0));

    // The two content lines sit below three tall option cards at this scale —
    // the sentence E4 exists for is below the fold, and "below the fold" is
    // only acceptable while "reachable" is true.
    final contentLines = find.byType(CardExportContentLinesWidget);
    expect(
      tester.getRect(contentLines).top,
      greaterThan(568),
      reason:
          'if this band is already on screen the drag below proves '
          'nothing — re-measure the viewport rather than deleting the check',
    );
    await tester.dragUntilVisible(
      contentLines,
      find.byType(SingleChildScrollView),
      const Offset(0, -80),
    );
    expect(find.text(english.cardExportExcludesLine), findsOneWidget);

    // **And the action row did not travel with it.** This is the half the
    // first version of this test missed: `action.bottom <= 568` stays true
    // even when the row is inside the scroll view, because it is only off
    // screen once the user scrolls. What "the body scrolls, the action row
    // does not" means is that scrolling moves one and not the other.
    expect(
      tester.getRect(find.byType(CardExportActionBarWidget)),
      action,
      reason:
          'the action row moved when the body scrolled, so it is part of '
          'the body and will leave the screen with it',
    );
  });

  for (final locale in <Locale?>[null, const Locale('vi')]) {
    final name = locale?.languageCode ?? 'en';
    testWidgets('320dp at 2.0x in $name: nothing overflows', (tester) async {
      await h.pump(
        tester,
        surface: const Size(320, 852),
        textScale: 2,
        locale: locale,
      );
      await h.openWholeDeckExport(
        tester,
        l10n: locale == null ? null : h.vietnamese,
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(CardExportFormatOptionsWidget), findsOneWidget);
    });
  }
}
