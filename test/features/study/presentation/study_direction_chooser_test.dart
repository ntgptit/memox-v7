import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/study/domain/models/study_direction_model.dart';
import 'package:memox/features/study/presentation/widgets/overlays/study_direction_chooser_widget.dart';
import 'package:memox/shared/widgets/mx_list_tile.dart';

import 'support/study_widget_harness.dart';

/// The sheet that asks which way a self-assess review will run (BR-203,
/// BR-207).
///
/// The card it leads to is the other surface the direction touches and lives in
/// `study_direction_card_test.dart` — split when the two together crossed the
/// guard's 400 lines.
void main() {
  group('the chooser (BR-203, BR-207)', () {
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
    testWidgets('offers exactly the three choices, and never `unknown`', (
      tester,
    ) async {
      await pumpChooser(tester, onSubmit: (_) async => null);

      expect(find.byType(MxListTile), findsNWidgets(3));
      expect(find.text('Korean first'), findsOneWidget);
      expect(find.text('Meaning first'), findsOneWidget);
      expect(find.text('Mixed'), findsOneWidget);
      expect(find.text('unknown'), findsNothing);
    });

    testWidgets('the copy names the exercise, not the schema', (tester) async {
      await pumpChooser(tester, onSubmit: (_) async => null);

      for (final leak in <String>[
        'front',
        'back',
        'Front',
        'Back',
        'self_assess',
        'sm2',
        'SM-2',
      ]) {
        expect(
          find.textContaining(leak),
          findsNothing,
          reason: '"$leak" is an implementation word',
        );
      }
    });

    testWidgets('one option is marked Recommended, inside its own line', (
      tester,
    ) async {
      // Inside the description rather than beside it — see the clipping test
      // below for what a trailing badge cost the row it marked.
      await pumpChooser(tester, onSubmit: (_) async => null);

      expect(find.textContaining('Recommended'), findsOneWidget);
      expect(
        find.textContaining('See the Korean, recall what it means.'),
        findsOneWidget,
      );
      expect(find.text('Recommended'), findsNothing);
    });

    testWidgets('selection is a glyph, not only a colour', (tester) async {
      await pumpChooser(tester, onSubmit: (_) async => null);

      // Korean first is selected on open — it is what every review did before
      // BR-203, so an unengaged learner gets the app they already have.
      expect(find.byIcon(Icons.radio_button_checked), findsOneWidget);
      expect(find.byIcon(Icons.radio_button_unchecked), findsNWidgets(2));

      await tester.tap(find.text('Mixed'));
      await tester.pump();

      expect(find.byIcon(Icons.radio_button_checked), findsOneWidget);
      final selected = tester.widget<MxListTile>(
        find.ancestor(
          of: find.text('Mixed'),
          matching: find.byType(MxListTile),
        ),
      );
      expect(selected.isSelected, isTrue);
    });

    testWidgets('a tap selects, and does not start (BR-207)', (tester) async {
      // The choice is locked for the whole session, so a mis-tap must not be
      // able to spend one.
      final submitted = <StudySessionDirection>[];
      await pumpChooser(
        tester,
        onSubmit: (direction) async {
          submitted.add(direction);
          return null;
        },
      );

      await tester.tap(find.text('Meaning first'));
      await tester.pump();

      expect(submitted, isEmpty);

      await tester.tap(find.text('Start review'));
      await tester.pump();

      expect(submitted, <StudySessionDirection>[
        StudySessionDirection.meaningToKorean,
      ]);
    });

    testWidgets('a second tap on Start is refused (BR-25)', (tester) async {
      // Starting a session pushes a route, and a second tap fits comfortably
      // inside the frame before that route is on screen.
      final submitted = <StudySessionDirection>[];
      final gate = Completer<Object?>();
      await pumpChooser(
        tester,
        onSubmit: (direction) {
          submitted.add(direction);

          return gate.future;
        },
      );

      await tester.tap(find.text('Start review'));
      await tester.pump();
      await tester.tap(find.text('Start review'), warnIfMissed: false);
      await tester.pump();

      expect(submitted, hasLength(1));

      gate.complete(null);
      await tester.pump();
    });

    testWidgets('the options lock while a start is in flight', (tester) async {
      // The choice must not change under a request already carrying the
      // previous one.
      final gate = Completer<Object?>();
      await pumpChooser(tester, onSubmit: (_) => gate.future);

      await tester.tap(find.text('Start review'));
      await tester.pump();

      final tile = tester.widget<MxListTile>(
        find.ancestor(
          of: find.text('Mixed'),
          matching: find.byType(MxListTile),
        ),
      );
      expect(tile.onTap, isNull);

      gate.complete(null);
      await tester.pump();
    });

    testWidgets('a refusal is shown and the selection is kept', (tester) async {
      // Losing the choice would charge the user for an error that was not
      // theirs — and this sheet is the last place the choice can be made.
      var shouldFail = true;
      final submitted = <StudySessionDirection>[];
      await pumpChooser(
        tester,
        onSubmit: (direction) async {
          submitted.add(direction);

          return shouldFail ? StateError('refused') : null;
        },
      );

      await tester.tap(find.text('Mixed'));
      await tester.pump();
      await tester.tap(find.text('Start review'));
      await tester.pump();

      expect(
        find.text('Could not start the review. Try again.'),
        findsOneWidget,
      );

      final tile = tester.widget<MxListTile>(
        find.ancestor(
          of: find.text('Mixed'),
          matching: find.byType(MxListTile),
        ),
      );
      expect(tile.isSelected, isTrue, reason: 'the choice survives a refusal');

      shouldFail = false;
      await tester.tap(find.text('Start review'));
      await tester.pump();

      expect(submitted, <StudySessionDirection>[
        StudySessionDirection.mixed,
        StudySessionDirection.mixed,
      ]);
      expect(find.text('Could not start the review. Try again.'), findsNothing);
    });

    testWidgets('every option keeps a 48dp target, in Vietnamese too', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await pumpChooser(
        tester,
        onSubmit: (_) async => null,
        locale: const Locale('vi'),
      );

      for (var index = 0; index < 3; index++) {
        expect(
          tester.getRect(find.byType(MxListTile).at(index)).height,
          greaterThanOrEqualTo(48),
        );
      }
      expect(tester.takeException(), isNull);
    });
  });
}
