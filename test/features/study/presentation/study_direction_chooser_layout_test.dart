import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/study/domain/models/study_direction_model.dart';
import 'package:memox/features/study/presentation/widgets/overlays/study_direction_chooser_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';
import 'package:memox/l10n/generated/app_localizations_vi.dart';
import 'package:memox/shared/widgets/mx_list_tile.dart';

import 'support/study_widget_harness.dart';

/// What the direction sheet **measures**: one text column for three
/// options, one width, nothing cut short at the narrowest screen, and every
/// control labelled and reachable in both themes.
///
/// Split from `study_direction_chooser_test.dart` at the guard's 400-line
/// ceiling. That file keeps what the sheet *does* — which options exist, what
/// a tap starts, what a refusal keeps. Same harness, same widget.
void main() {
  group('the chooser geometry (BR-203)', () {
    Future<void> pumpChooser(
      WidgetTester tester, {
      required Future<Object?> Function(StudySessionDirection) onSubmit,
      Locale? locale,
      Brightness brightness = Brightness.light,
      TextScaler? textScaler,
    }) => tester.pumpWidget(
      wrapForTest(
        StudyDirectionChooserWidget(onSubmit: onSubmit),
        locale: locale,
        brightness: brightness,
        textScaler: textScaler,
      ),
    );

    /// Whether each option's title and description had to be cut short.
    ///
    /// **Read off the paragraph, not off the tile.** Every tile is the same
    /// width — `CrossAxisAlignment.stretch` guarantees it — so measuring tiles
    /// can never see the failure this exists for: `ListTile` gives its *text*
    /// whatever the leading and trailing widgets leave, and a badge on one row
    /// takes it from that row alone.
    List<bool> clipped(WidgetTester tester) => <bool>[
      for (var index = 0; index < 3; index++)
        for (final finder in <Finder>[
          find
              .descendant(
                of: find.byType(MxListTile).at(index),
                matching: find.byType(Text),
              )
              .first,
          find
              .descendant(
                of: find.byType(MxListTile).at(index),
                matching: find.byType(Text),
              )
              .at(1),
        ])
          (tester.renderObject(finder) as RenderParagraph).didExceedMaxLines,
    ];

    /// The width each option's title and description was laid out in.
    ///
    /// **Read off the paragraph, not off the tile.** Every tile is the same
    /// width — `CrossAxisAlignment.stretch` guarantees it — so measuring tiles
    /// can never see the failure this exists for: `ListTile` gives its *text*
    /// whatever the leading and trailing widgets leave, and a badge on one row
    /// takes it from that row alone.
    double columnOf(WidgetTester tester, int index, int line) =>
        (tester.renderObject(
                  find
                      .descendant(
                        of: find.byType(MxListTile).at(index),
                        matching: find.byType(Text),
                      )
                      .at(line),
                )
                as RenderParagraph)
            .constraints
            .maxWidth;

    ({List<double> titles, List<double> bodies}) textColumns(
      WidgetTester tester,
    ) => (
      titles: <double>[for (var i = 0; i < 3; i++) columnOf(tester, i, 0)],
      bodies: <double>[for (var i = 0; i < 3; i++) columnOf(tester, i, 1)],
    );

    testWidgets('no option is cut short on the narrowest screen', (
      tester,
    ) async {
      // **The assertion the badge used to fail, in both languages.** Marking the
      // recommended option with a `trailing` widget left it 112dp of text where
      // its neighbours had 200dp, so it was the only one whose description was
      // clipped — the option the app is suggesting was the option a learner
      // could not read. The marker now rides on the description itself, so all
      // three share one column (wireframe §9.1).
      for (final locale in <Locale?>[null, const Locale('vi')]) {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        await pumpChooser(tester, onSubmit: (_) async => null, locale: locale);

        expect(clipped(tester), everyElement(isFalse), reason: '$locale');
      }
    });

    testWidgets('every control is labelled and reachable, in both themes', (
      tester,
    ) async {
      // **The sweep this sheet did not have.** `labeledTapTargetGuideline` is
      // what says a control has a name; the tap-target guidelines are what say
      // it can be hit. Run in dark as well as light, because that is where this
      // sheet's ink problems have been.
      //
      // It would **not** have caught the 2.45:1 radio glyph, and it is worth
      // saying so: no guideline in `flutter_test` measures an icon's contrast —
      // `textContrastGuideline` measures text. That one is still only caught by
      // reading the tokens, which is what the audit did.
      for (final brightness in <Brightness>[
        Brightness.light,
        Brightness.dark,
      ]) {
        final handle = tester.ensureSemantics();
        await pumpChooser(
          tester,
          onSubmit: (_) async => null,
          brightness: brightness,
        );

        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        handle.dispose();
      }
    });

    testWidgets('the recommendation survives the ellipsis at 320dp × 2.0', (
      tester,
    ) async {
      // **`MxListTile` caps a subtitle at two lines, and at this size the line
      // needs about three.** So something is cut — the question is what. With
      // the marker trailing it was the marker, and the option the app
      // recommends carried no sign of it, which is the outcome choosing a
      // marker over a trailing badge was meant to avoid.
      //
      // **Measured on the laid-out paragraph, not on the span.** A
      // `find.textContaining` matches `RichText.text.toPlainText()`, which is
      // the string *before* layout — the ellipsis is applied by
      // `RenderParagraph` and never touches the span, so a finder-based
      // assertion passes with the marker trailing too and proves nothing. The
      // question "is this run of characters painted?" is a geometry question,
      // and `getBoxesForSelection` is what answers it.
      for (final locale in <Locale?>[null, const Locale('vi')]) {
        tester.view.physicalSize = const Size(320, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        await pumpChooser(
          tester,
          onSubmit: (_) async => null,
          locale: locale,
          textScaler: const TextScaler.linear(2),
        );

        final AppLocalizations l10n = locale?.languageCode == 'vi'
            ? AppLocalizationsVi()
            : AppLocalizationsEn();
        final String marker = l10n
            .studyDirectionRecommendedOption('')
            .split('—')
            .first
            .trim();

        final RenderParagraph paragraph = tester
            .renderObjectList<RenderParagraph>(
              find.descendant(
                of: find.byType(MxListTile).first,
                matching: find.byType(RichText),
              ),
            )
            .last;

        // The line really is cut — otherwise this test would be measuring a
        // case that cannot go wrong.
        expect(
          paragraph.didExceedMaxLines,
          isTrue,
          reason: 'the subtitle is truncated at $locale, which is the premise',
        );

        final List<ui.TextBox> boxes = paragraph.getBoxesForSelection(
          TextSelection(baseOffset: 0, extentOffset: marker.length),
        );
        expect(boxes, isNotEmpty, reason: 'the marker has a box at $locale');
        for (final ui.TextBox box in boxes) {
          expect(
            box.bottom,
            lessThanOrEqualTo(paragraph.size.height + 0.5),
            reason: 'the marker is inside the painted area at $locale',
          );
        }
      }
    });

    testWidgets('every option gets the same text column to write in', (
      tester,
    ) async {
      // **The exact quantity the badge changed**, and the one §9.1 names: at
      // 320dp the recommended row had 112dp against its neighbours' 200dp.
      // Measured at both scales and in both languages, because the trailing
      // widget's appetite grows with the text it holds — at 2.0 the badge alone
      // took a row down to about 41dp.
      for (final scaler in <TextScaler?>[null, const TextScaler.linear(2)]) {
        for (final locale in <Locale?>[null, const Locale('vi')]) {
          for (final width in <double>[320, 390]) {
            tester.view.physicalSize = Size(width, 800);
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.reset);

            await pumpChooser(
              tester,
              onSubmit: (_) async => null,
              locale: locale,
              textScaler: scaler,
            );

            final columns = textColumns(tester);
            expect(
              columns.titles.toSet(),
              hasLength(1),
              reason: 'titles at ${width}dp, $locale, scale $scaler',
            );
            expect(
              columns.bodies.toSet(),
              hasLength(1),
              reason: 'descriptions at ${width}dp, $locale, scale $scaler',
            );
          }
        }
      }
    });

    testWidgets('the three options share one width and one left edge', (
      tester,
    ) async {
      await pumpChooser(tester, onSubmit: (_) async => null);

      final rects = <Rect>[
        for (var index = 0; index < 3; index++)
          tester.getRect(find.byType(MxListTile).at(index)),
      ];

      expect(rects[1].left, rects[0].left);
      expect(rects[2].left, rects[0].left);
      expect(rects[1].width, rects[0].width);
      expect(rects[2].width, rects[0].width);
    });

    testWidgets('renders in dark mode without overflowing', (tester) async {
      await pumpChooser(
        tester,
        onSubmit: (_) async => null,
        brightness: Brightness.dark,
      );

      expect(tester.takeException(), isNull);
    });
  });
}
