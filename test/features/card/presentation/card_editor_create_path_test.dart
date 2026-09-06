import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_editor_breadcrumb_widget.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';
import 'package:memox/shared/widgets/mx_breadcrumb.dart';

import 'support/card_editor_harness.dart';
import 'support/fake_card_repository.dart';

/// Create says which deck the card is about to be written into.
///
/// **It said nothing** (SC-C9-02). The screen was "New flashcard" over two
/// empty fields, on a deep-linkable route, while both sibling surfaces in the
/// same feature that write content into a deck lead with the path: edit pins
/// this very widget, and the import wizard pins a breadcrumb of its own.
///
/// **The same widget rather than a second `MxBreadcrumb`**, because building
/// one at the call site is how the app grew a third up-navigation grammar the
/// last time (SC-C4-07): `MxBreadcrumb` ignores per-item taps unless `onUp` is
/// set, so a hand-rolled strip is inert. Reusing the section keeps `onUp`,
/// `onShowAll` and `collapseAfter` identical to edit's.
///
/// **And every crumb is a way out, so every crumb asks first.** Create gained
/// its exit guard in C4; crumbs that navigate around it are precisely what
/// dropped drafts silently in edit before the guard existed.
void main() {
  final english = AppLocalizationsEn();

  testWidgets('create pins the deck path, with its own leaf', (tester) async {
    final repository = FakeCardRepository();
    addTearDown(repository.dispose);
    await pumpCardEditor(tester, repository, cardId: null);

    expect(find.byType(CardEditorBreadcrumbWidget), findsOneWidget);
    expect(find.text('TOPIK II — Vocab'), findsOneWidget);

    // Its own leaf, not edit's: one screen is editing a card that exists, the
    // other is a card that does not yet.
    expect(find.text(english.cardEditorCreateBreadcrumbLabel), findsOneWidget);
    expect(find.text(english.cardEditorBreadcrumbLabel), findsNothing);
  });

  testWidgets('the strip is the one edit uses, up-navigation and all', (
    tester,
  ) async {
    final repository = FakeCardRepository();
    addTearDown(repository.dispose);
    await pumpCardEditor(tester, repository, cardId: null);

    final crumb = tester.widget<MxBreadcrumb>(find.byType(MxBreadcrumb));

    // The three properties a hand-built strip would have dropped.
    expect(crumb.onUp, isNotNull);
    expect(crumb.onShowAll, isNotNull);
    expect(crumb.collapseAfter, 3);
  });

  testWidgets('a crumb with a draft in the form asks before it leaves', (
    tester,
  ) async {
    final repository = FakeCardRepository();
    addTearDown(repository.dispose);
    await pumpCardEditor(tester, repository, cardId: null);

    await tester.enterText(find.byType(TextField).first, '사과');
    await tester.pumpAndSettle();

    await tester.tap(find.byType(MxBreadcrumb));
    await tester.pumpAndSettle();

    // The guard, not the navigation: an unguarded crumb dropped the draft
    // without a word.
    expect(find.text(english.cardEditorDiscardTitle), findsOneWidget);
  });
}
