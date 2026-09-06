import 'dart:ui' show Size;

import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_editor_details_widget.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_editor_field_widget.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';
import 'package:memox/shared/widgets/mx_text_field.dart';

import 'support/card_editor_harness.dart';
import 'support/fake_card_repository.dart';

/// **One field grammar for one screen, in both of its modes** (SC-C6-02).
///
/// Create used to draw the same five card values as bare `MxTextField`s —
/// floating labels, no `Required` marker, the app-wide counter that only speaks
/// near the limit, and a 16sp front against edit's 22 — so the same semantic
/// field was two sizes depending on which branch of `CardEditorScreen` the user
/// had reached. The split was deliberate while create had not been reviewed;
/// what pins it now that it has is this file, because nothing else compares the
/// two modes and a rung is easy to drop back to its default.
void main() {
  final english = AppLocalizationsEn();

  FakeCardRepository seed() {
    final repository = FakeCardRepository();
    addTearDown(repository.dispose);

    return repository;
  }

  Future<void> pumpCreate(WidgetTester tester) =>
      pumpCardEditor(tester, seed(), cardId: null);

  /// The rendered value style of the `n`th field on screen, read off the
  /// `MxTextField` the composite wraps rather than off the composite: the
  /// emphasis is a value-only decision and this is where it lands.
  MxTextFieldEmphasis emphasisAt(WidgetTester tester, int index) =>
      tester.widget<MxTextField>(find.byType(MxTextField).at(index)).emphasis;

  group('create composes the editor field', () {
    testWidgets('two sides collapsed, five fields expanded', (tester) async {
      await pumpCreate(tester);

      expect(find.byType(CardEditorFieldWidget), findsNWidgets(2));
      expect(find.byType(CardEditorDetailsWidget), findsOneWidget);

      await tester.tap(find.text(kDetailsToggleLabel));
      await tester.pumpAndSettle();

      expect(find.byType(CardEditorFieldWidget), findsNWidgets(5));
    });

    testWidgets('both sides are marked Required, the details optional', (
      tester,
    ) async {
      await pumpCreate(tester);

      // Two, not five: the marker is a word rather than a colour, so it is
      // findable, and only the front and the back carry BR-08's obligation.
      expect(find.text(english.cardEditorFieldRequired), findsNWidgets(2));

      await tester.tap(find.text(kDetailsToggleLabel));
      await tester.pumpAndSettle();

      expect(find.text(english.cardEditorFieldRequired), findsNWidgets(2));
      expect(find.text(english.cardEditorFieldOptional), findsNWidgets(3));
    });

    testWidgets('the label row replaces the floating label', (tester) async {
      await pumpCreate(tester);

      // The editor's section grammar, upper-case and outside the box. The old
      // sentence-case `Front` / `Back` floating labels are gone from this mode,
      // which is the half of the change a size assertion cannot see.
      expect(find.text(english.cardEditorFrontFieldLabel), findsOneWidget);
      expect(find.text(english.cardEditorBackFieldLabel), findsOneWidget);
      expect(find.text(english.cardFrontLabel), findsNothing);
      expect(find.text(english.cardBackLabel), findsNothing);
    });

    testWidgets('the front is prominent and the back is not', (tester) async {
      await pumpCreate(tester);

      // The defect this file exists for: create inheriting the default would
      // put the front at `body` here and `prominent` in edit — one field, two
      // sizes, one screen.
      expect(emphasisAt(tester, 0), MxTextFieldEmphasis.prominent);
      expect(emphasisAt(tester, 1), MxTextFieldEmphasis.body);
    });

    testWidgets('holds at 320dp and text scale 2', (tester) async {
      // The front went 16 → 22 and gained a label row carrying a name, a
      // `Required` marker and a live counter, all above a box that now opens
      // three lines tall. That is the combination the narrowest supported
      // surface and the largest supported text break first, and the label row
      // has already been measured wrong once here
      // (`card_editor_field_widget.dart`).
      await pumpCardEditor(
        tester,
        seed(),
        cardId: null,
        surfaceSize: const Size(320, 640),
        textScale: 2,
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(CardEditorFieldWidget), findsNWidgets(2));
    });
  });

  group('edit is the mode create was matched to', () {
    testWidgets('draws the same five fields at the same two rungs', (
      tester,
    ) async {
      await pumpCardEditor(tester, seed());

      expect(find.byType(CardEditorFieldWidget), findsNWidgets(2));
      expect(emphasisAt(tester, 0), MxTextFieldEmphasis.prominent);
      expect(emphasisAt(tester, 1), MxTextFieldEmphasis.body);

      await tester.ensureVisible(find.text(kDetailsToggleLabel));
      await tester.pumpAndSettle();
      await tester.tap(find.text(kDetailsToggleLabel));
      await tester.pumpAndSettle();

      expect(find.byType(CardEditorFieldWidget), findsNWidgets(5));
    });
  });
}
