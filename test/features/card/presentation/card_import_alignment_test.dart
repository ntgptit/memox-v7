import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/card/domain/models/card_transfer_format_model.dart';
import 'package:memox/features/card/domain/models/card_transfer_source_model.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';
import 'package:memox/shared/widgets/mx_card.dart';

import 'support/card_import_wizard_harness.dart';

/// **Every band of the wizard shares the content column's two edges.**
///
/// This is the check no other gate can make, and the reason it exists is a
/// bug all of them missed: the two source cards sat in a `Wrap`, which sizes
/// children to their *intrinsic* width, so the row ended 25dp short of the
/// column on a phone and read as indented against every other band.
/// `flutter analyze` and the guard read source text and cannot see a laid-out
/// rectangle; the visual audit reads colour, not geometry; and a golden only
/// compares a screen with yesterday's copy of itself, so an edge that is
/// wrong but *stable* is a golden that passes forever. The eye missed it on a
/// scaled-down PNG. Measurement did not (M99.19a review finding V9).
///
/// The rule: the content column has one inset, and every *band* honours it —
/// headings, cards, panels, and rows of cards, measured as the widgets a
/// reader sees, not as the invisible box holding them. Something narrower on
/// purpose (a chip hugging its text, a button inside a card, a heading
/// sharing its row with a counter) is not a band and is not measured here.
void main() {
  final h = installCardImportWizardHarness();
  final AppLocalizationsEn english = h.english;

  /// A hairline, not a design allowance: `Border.all` paints inside the box
  /// and antialiasing may land a fraction either way. Anything above this is
  /// a layout decision somebody made by accident.
  const double epsilon = 0.5;
  const phoneSurface = Size(390, 844);

  Finder cardHolding(Finder content) =>
      find.ancestor(of: content, matching: find.byType(MxCard)).first;

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
            '${first.left} — the content column has one left edge.',
      );
      expect(
        rect.right,
        moreOrLessEquals(first.right, epsilon: epsilon),
        reason:
            '${entry.key} ends at ${rect.right}, ${entries.first.key} at '
            '${first.right} — the content column has one right edge.',
      );
    }
  }

  /// The pair fills the column: left card starts it, right card ends it, and
  /// the two are the same width. Measured on the cards themselves — the row
  /// that holds them was full-width even while they were not, which is
  /// exactly how the original defect hid.
  void expectSourceCardsFillColumn(WidgetTester tester) {
    final column = tester.getRect(
      find.text(english.cardImportChooseSourceHeading.toUpperCase()),
    );
    final upload = tester.getRect(
      cardHolding(find.text(english.cardImportUploadOptionTitle)),
    );
    final paste = tester.getRect(
      cardHolding(find.text(english.cardImportPasteOptionTitle)),
    );

    expect(
      upload.left,
      moreOrLessEquals(column.left, epsilon: epsilon),
      reason: 'the first source card starts the column',
    );
    expect(
      paste.right,
      moreOrLessEquals(column.right, epsilon: epsilon),
      reason:
          'the second source card ends the column — it ended at '
          '${paste.right} against ${column.right}',
    );
    expect(
      upload.width,
      moreOrLessEquals(paste.width, epsilon: epsilon),
      reason: 'the two source cards are equal halves',
    );
    expect(
      upload.height,
      moreOrLessEquals(paste.height, epsilon: epsilon),
      reason: 'the two source cards are the same height',
    );
  }

  testWidgets('Source: heading, source cards, file summary and info panel '
      'share the column', (tester) async {
    h.picker.fileToPick = CardTransferFileSource(
      name: 'words.csv',
      bytes: Uint8List.fromList(utf8.encode('front,back\n사과,apple')),
      format: CardTransferFormat.csv,
    );
    await h.pump(tester, surface: phoneSurface);
    await tester.tap(find.text(english.cardImportChooseFileAction));
    await tester.pumpAndSettle();

    expectSourceCardsFillColumn(tester);
    expectSharedEdges(tester, <String, Finder>{
      'choose-a-source heading': find.text(
        english.cardImportChooseSourceHeading.toUpperCase(),
      ),
      'file summary card': cardHolding(find.text('words.csv')),
      'info panel': cardHolding(find.text(english.cardImportInfoTitle)),
    });
  });

  testWidgets('Source with no file: the chooser panel shares the column', (
    tester,
  ) async {
    await h.pump(tester, surface: phoneSurface);

    expectSourceCardsFillColumn(tester);
    expectSharedEdges(tester, <String, Finder>{
      'choose-a-source heading': find.text(
        english.cardImportChooseSourceHeading.toUpperCase(),
      ),
      'chooser panel': cardHolding(find.text(english.cardImportChoosePrompt)),
      'info panel': cardHolding(find.text(english.cardImportInfoTitle)),
    });
  });

  testWidgets('Source on the paste half: the box shares the column', (
    tester,
  ) async {
    await h.pump(tester, surface: phoneSurface);
    await tester.tap(find.text(english.cardImportPasteOptionTitle));
    await tester.pumpAndSettle();

    expectSourceCardsFillColumn(tester);
    expectSharedEdges(tester, <String, Finder>{
      'choose-a-source heading': find.text(
        english.cardImportChooseSourceHeading.toUpperCase(),
      ),
      'paste box': find.byType(TextField),
      'info panel': cardHolding(find.text(english.cardImportInfoTitle)),
    });
  });

  testWidgets('Source at 320dp: the cards stack and each fills the column', (
    tester,
  ) async {
    await h.pump(tester, surface: const Size(320, 852), textScale: 2);

    // Stacked, so both cards span the whole column rather than half of it.
    final column = tester.getRect(
      find.text(english.cardImportChooseSourceHeading.toUpperCase()),
    );
    for (final entry in <String, String>{
      'upload': english.cardImportUploadOptionTitle,
      'paste': english.cardImportPasteOptionTitle,
    }.entries) {
      final rect = tester.getRect(cardHolding(find.text(entry.value)));
      expect(rect.left, moreOrLessEquals(column.left, epsilon: epsilon));
      expect(
        rect.right,
        moreOrLessEquals(column.right, epsilon: epsilon),
        reason: '${entry.key} must fill the column once stacked',
      );
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('Preview: the mapping panel and the preview panel share the '
      'column, and the mapping heading sits inside its panel', (tester) async {
    // **The contract this asserts changed with the panel migration.** The
    // source line, the mapping heading and the row list used to be three
    // loose elements sharing the page column; they are two grouped panels
    // now — mapping (source line, sheet/header, column rows) and preview
    // (chips, policy, rows) — so what must share the column is the panels,
    // and what must *not* is their contents, which sit one panel-padding in.
    await h.pump(tester, surface: phoneSurface);
    await h.pasteAndPreview(tester, 'front,back\n사과,apple\n배,pear\n');

    final mappingPanel = cardHolding(
      find.text(english.cardImportPastedSourceLabel),
    );
    final previewPanel = cardHolding(find.text('사과'));
    expectSharedEdges(tester, <String, Finder>{
      'mapping panel': mappingPanel,
      'preview panel': previewPanel,
    });

    final panel = tester.getRect(mappingPanel);
    final heading = tester.getRect(
      find.text(english.cardImportMappingHeading.toUpperCase()),
    );
    expect(
      heading.left,
      greaterThan(panel.left),
      reason: 'the group label belongs to the panel, inset by its padding',
    );
    expect(heading.right, lessThan(panel.right));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Confirm: heading and the plan summary share the column', (
    tester,
  ) async {
    await h.pump(tester, surface: phoneSurface);
    await h.pasteAndPreview(tester, 'front,back\n사과,apple\n');
    await tester.tap(find.text(english.cardImportContinueAction));
    await tester.pumpAndSettle();

    expectSharedEdges(tester, <String, Finder>{
      'confirm heading': find.text(
        english.cardImportConfirmHeading.toUpperCase(),
      ),
      'plan summary card': cardHolding(
        find.text(english.cardImportConfirmImportRowLabel),
      ),
    });
  });

  testWidgets('Result: hero, summary and helper share the column', (
    tester,
  ) async {
    await h.pump(tester, surface: phoneSurface);
    await h.pasteAndPreview(tester, 'front,back\n사과,apple\n배,\n');
    await tester.tap(find.text(english.cardImportContinueAction));
    await tester.pumpAndSettle();
    await tester.tap(find.text(english.cardImportSubmitAction(1)));
    await tester.pumpAndSettle();

    expectSharedEdges(tester, <String, Finder>{
      'result hero': cardHolding(find.text(english.cardImportSkipsTitle)),
      'summary card': cardHolding(find.text(english.cardImportAddedRowLabel)),
      'helper panel': cardHolding(find.text(english.cardImportFixInvalidHint)),
    });
  });
}
