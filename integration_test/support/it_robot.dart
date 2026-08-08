import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/card/presentation/widgets/items/card_tile_widget.dart';
import 'package:memox/features/deck/presentation/widgets/items/deck_tile_widget.dart';
import 'package:memox/features/study/presentation/widgets/sections/fill_answer_section_widget.dart';
import 'package:memox/features/study/presentation/widgets/sections/guess_question_section_widget.dart';
import 'package:memox/features/study/presentation/widgets/sections/match_board_section_widget.dart';
import 'package:memox/features/study/presentation/widgets/sections/recall_timer_section_widget.dart';
import 'package:memox/features/study/presentation/widgets/sections/study_card_face_section_widget.dart';
import 'package:memox/shared/widgets/mx_search_field.dart';
import 'package:memox/shared/widgets/mx_text_field.dart';

import 'it_harness.dart';
import 'it_text.dart';

export 'it_text.dart';

part 'it_robot_lists.dart';
part 'it_robot_study.dart';

/// User-level actions the scenarios are written in terms of.
///
/// Every method here taps, types or scrolls something a user can see and hit.
/// None of them read a provider, call a controller or touch a DAO — the whole
/// point of the suite is that the claim "a user can do this" is tested by doing
/// it. Setup recipes from `00-agent-execution-guide.md` §5 are built from these
/// same actions, which is why a recipe that stops working is a real product
/// regression rather than a fixture that drifted.
final class ItRobot {
  ItRobot(this._tester, this._harness);

  final WidgetTester _tester;
  final ItHarness _harness;

  /// Every string currently on screen — the first thing to look at when a
  /// finder misses.
  List<String> get visibleText => _tester
      .widgetList<Text>(find.byType(Text))
      .map((t) => t.data)
      .whereType<String>()
      .toList();

  /// Prints a short, greppable snapshot of the screen.
  ///
  /// Kept to a handful of entries on purpose: the test reporter truncates long
  /// lines, and a dump that gets cut off is the one piece of evidence a
  /// multi-step scenario cannot afford to lose.
  void trace(String label) {
    final head = visibleText.take(6).join(' | ');
    // ignore: avoid_print
    print('TRACE[$label] $head');
  }

  /// Taps [finder], failing with what *was* on screen when it matches nothing.
  ///
  /// `tester.tap` on a missing finder reports "found 0 widgets" and stops
  /// there, which is the least useful moment to have no context.
  Future<void> tapText(String label) async {
    final finder = find.text(label);
    expect(
      finder,
      findsWidgets,
      reason: 'no "$label" on screen; visible text was $visibleText',
    );
    await _tapVisible(finder.first);
  }

  /// Taps [target] after making sure the tap can actually reach it.
  ///
  /// **"Found" and "tappable" are different facts, and three scenarios failed on
  /// the gap.** A widget below the fold is still built and still found, and
  /// `tester.tap` then presses its centre — which hit-tests whatever *is* there,
  /// the bottom navigation bar included. IT-CARD-005 pressed Save card on a form
  /// scrolled past the button and read the unchanged screen as a failed save;
  /// IT-ORG-012 pressed Load 50 more and opened the Study tab.
  ///
  /// `ensureVisible` is a no-op when nothing above the widget scrolls, so this
  /// costs nothing on the screens that never had the problem.
  Future<void> _tapVisible(Finder target) async {
    await _tester.ensureVisible(target);
    await _tester.pump();
    await _tester.tap(target);
    await _harness.settle();
  }

  /// Types into the [index]th *form* field.
  ///
  /// Scoped to `MxTextField` rather than `TextField`, because the deck list
  /// keeps its `MxSearchField` mounted behind the sheet — so a plain
  /// `find.byType(TextField).at(0)` types the deck name into the search box and
  /// the screen quietly becomes "no decks match" instead of a filled form.
  Future<void> enterNthField(int index, String value) async {
    final fields = find.descendant(
      of: find.byType(MxTextField),
      matching: find.byType(TextField),
    );
    expect(
      fields,
      findsWidgets,
      reason: 'no form field on screen; visible text was $visibleText',
    );
    await _tester.enterText(fields.at(index), value);
    await _harness.settle();
  }

  /// Types into the deck search field.
  ///
  /// Scoped to `MxSearchField` for the mirror of the reason `enterNthField` is
  /// scoped to `MxTextField`: the two must never be confused for one another.
  Future<void> enterSearch(String query) async {
    final field = find.descendant(
      of: find.byType(MxSearchField),
      matching: find.byType(TextField),
    );
    expect(
      field,
      findsWidgets,
      reason: 'no search field on screen; visible text was $visibleText',
    );
    await _tester.enterText(field.first, query);
    await _harness.settle();
  }

  /// Scrolls until [label] is on screen, then leaves it there.
  ///
  /// A control below the fold is not tappable, and `tester.tap` on it throws
  /// about hit-testing rather than about scrolling — which sends the reader
  /// looking for the wrong bug.
  Future<void> scrollToText(String label) async {
    final target = find.text(label);
    if (target.evaluate().isNotEmpty) return;
    // The *vertical* scrollable. Taking `.last` grabs the filter pill row,
    // which scrolls horizontally — dragging it moves nothing the caller wants
    // and the row stays off-screen with no error to explain why.
    final vertical = find.byWidgetPredicate(
      (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
    );
    if (vertical.evaluate().isEmpty) return;
    // Drag from the centre of the tallest vertical scrollable, by raw
    // coordinates. Two earlier shapes of this method both failed silently:
    // `scrollUntilVisible` with an identity-anchored finder lost its element
    // the moment the list rebuilt, every subsequent drag threw, and a blanket
    // catch reported "done" with the list still at pixel zero. A point on
    // screen needs no re-resolution, so each drag lands whatever the frame
    // rebuilt in between — and there is nothing left to swallow.
    for (var i = 0; i < 60 && target.evaluate().isEmpty; i++) {
      final centre = _tallestCentre(vertical);
      if (centre == null) break;
      await _tester.dragFrom(centre, const Offset(0, -260));
      await _tester.pump(const Duration(milliseconds: 60));
    }
    await _harness.settle();

    // **Existing is not the same as reachable.** The loop above stops the
    // moment the widget is *built*, and the last row of a list is built while
    // still lying under the bottom navigation bar — so a tap on its centre
    // hit-tests the bar instead. IT-ORG-012 tapped "Load 50 more" and landed on
    // the Study tab, then failed three assertions later on a screen it had
    // never meant to open.
    if (target.evaluate().isEmpty) return;
    await _tester.ensureVisible(target.first);
    await _harness.settle();
  }

  /// The global centre of the tallest vertical scrollable, or null.
  Offset? _tallestCentre(Finder scrollables) {
    RenderBox? best;
    var bestHeight = 0.0;
    for (final element in scrollables.evaluate()) {
      final render = element.renderObject;
      if (render is! RenderBox || !render.hasSize) continue;
      if (render.size.height > bestHeight) {
        bestHeight = render.size.height;
        best = render;
      }
    }
    if (best == null) return null;

    return best.localToGlobal(best.size.center(Offset.zero));
  }

  /// Backs out until the deck level's own create action is reachable.
  ///
  /// Choosing "New card" on an undecided deck navigates to the card editor,
  /// which sits under that deck's *card list* route. Backing out once lands on
  /// the card list — an empty one, which reads as "this deck holds cards" even
  /// though nothing was saved and `content_type` is still `unset`
  /// (card_repository_impl.dart:164 changes it only inside the create
  /// transaction). One more step up reaches the deck level itself.
  Future<void> backToDeckLevel() async {
    for (var i = 0; i < 3; i++) {
      if (find.text(ItText.addToThisDeck).evaluate().isNotEmpty) return;
      await _harness.pressBack();
    }
  }

  /// Dismisses a bottom sheet or menu without choosing anything.
  ///
  /// The choose-a-kind sheet and the deck row menu carry no Cancel button —
  /// they are dismissed by the system back gesture or a tap outside, which is
  /// what a user actually does. Only the deck *form* has a Cancel, because it
  /// has input worth confirming the loss of.
  Future<void> dismissSheet() => _harness.pressBack();

  // ---- setup recipes -------------------------------------------------------

  /// Taps the create action for the current level.
  ///
  /// The control changes shape with the level: an empty level offers a labelled
  /// button, a level with decks in it offers an icon in the app bar carrying the
  /// same label as semantics and tooltip. Both are the same action to a user, so
  /// the robot accepts either — a `find.text` alone silently stops working the
  /// moment the first deck exists.
  Future<void> tapCreateAction(String label) async {
    final byText = find.text(label);
    if (byText.evaluate().isNotEmpty) {
      await _tester.tap(byText.first);
      await _harness.settle();

      return;
    }
    final byLabel = find.bySemanticsLabel(RegExp(RegExp.escape(label)));
    expect(
      byLabel,
      findsWidgets,
      reason: 'no "$label" control on screen; visible text was $visibleText',
    );
    await _tester.tap(byLabel.last);
    await _harness.settle();
  }

  /// `SETUP-D-EB` / `SETUP-D-SM2`: one root deck with the chosen study mode.
  Future<void> createRootDeck(String name, {required String scheduler}) async {
    _harness.tick();
    await tapCreateAction(ItText.newDeck);
    await enterNthField(0, name);
    await tapText(scheduler);
    await tapText(ItText.createSubmit);
  }

  /// Opens a deck by tapping its **row**.
  ///
  /// Anchored to `DeckTileWidget` rather than `find.text(name).first`: the same
  /// name also appears in the breadcrumb and, one level down, in the app bar
  /// title. Tapping the first match re-opened the level already on screen and
  /// left the test one screen short of where it thought it was — which then
  /// failed somewhere else entirely.
  Future<void> openDeck(String name) async {
    final row = find.descendant(
      of: find.byType(DeckTileWidget),
      matching: find.text(name),
    );
    if (row.evaluate().isEmpty) {
      await tapText(name);

      return;
    }
    await _tester.tap(row.first);
    await _harness.settle();
  }

  /// `SETUP-TREE-UNSET` step: a sub-deck under the currently open deck.
  ///
  /// An unset deck asks what kind of child is being added; a deck already fixed
  /// to sub-decks goes straight to the form. Both routes are handled because
  /// which one appears is the very thing several scenarios are asserting, and a
  /// robot that assumed one would make those assertions vacuous.
  Future<void> createSubDeck(String name) async {
    _harness.tick();
    if (find.text(ItText.addToThisDeck).evaluate().isNotEmpty) {
      await tapText(ItText.addToThisDeck);
      await tapText(ItText.newSubDeck);
    } else {
      // A level that already lists decks moves the action into the app bar as
      // an icon — same shape-shift as "New deck" and "New card".
      await tapCreateAction(ItText.newSubDeck);
    }
    await enterNthField(0, name);
    await tapText(ItText.createSubmit);
  }

  /// `SETUP-TREE-CARD` step: the first card, which fixes the deck to cards.
  Future<void> createCard(String front, String back) async {
    // Distinct created_at per card — a frozen clock makes newest-first a
    // random-UUID coin flip (see ItHarness.tick).
    _harness.tick();
    if (find.text(ItText.cardListEmptyAction).evaluate().isNotEmpty) {
      await tapText(ItText.cardListEmptyAction);
    } else if (find.text(ItText.addToThisDeck).evaluate().isNotEmpty) {
      await tapText(ItText.addToThisDeck);
      await tapText(ItText.newCard);
    } else {
      // A card list that already has cards moves the action into the app bar,
      // where it is an icon carrying the label rather than a `Text`.
      await tapCreateAction(ItText.newCard);
    }
    await enterNthField(0, front);
    await enterNthField(1, back);
    await tapText(ItText.saveCard);
  }

  /// Expands the editor's optional-details section if it is still collapsed.
  ///
  /// The section is a disclosure: closed on a new card, already open when the
  /// card being edited has details saved. Both states are normal, so the robot
  /// only taps when the toggle is the thing on screen.
  Future<void> revealOptionalFields() async {
    await scrollToText(ItText.detailsToggle);
    if (find.text(ItText.detailsToggle).evaluate().isEmpty) return;
    await tapText(ItText.detailsToggle);
  }

  /// Opens [front] from the list and deletes it through the danger zone.
  Future<void> deleteOpenCard(String front) async {
    await scrollToText(front);
    await tapText(front);
    await scrollToText(ItText.deleteCard);
    await tapText(ItText.deleteCard);
    await tapText(ItText.delete);
  }

  /// Taps an icon control by the label it announces.
  ///
  /// Tries tooltip first, then semantics. The editor's close and flag buttons
  /// carry their label as a `tooltip`, which only becomes a semantics label
  /// once the tooltip widget builds — so looking for one alone misses the
  /// other depending on where the control lives.
  Future<void> tapBySemantics(String label) async {
    final byTooltip = find.byTooltip(label);
    if (byTooltip.evaluate().isNotEmpty) {
      await _tester.tap(byTooltip.last);
      await _harness.settle();

      return;
    }
    final target = find.bySemanticsLabel(RegExp(RegExp.escape(label)));
    expect(target, findsWidgets, reason: 'no "$label" control; $visibleText');
    await _tester.tap(target.last);
    await _harness.settle();
  }

  /// Taps the first widget whose text contains [fragment].
  ///
  /// Filter pills carry their count in the same string ("All 3", "⚑ Flagged 0"),
  /// so an exact match would have to know the number before reading it.
  Future<void> tapTextContaining(String fragment) async {
    final target = find.textContaining(fragment);
    expect(
      target,
      findsWidgets,
      reason: 'no "$fragment" on screen; $visibleText',
    );
    await _tapVisible(target.first);
  }

  /// Adds a tag through the editor's tag field.
  ///
  /// Taps the field before typing, every time: `receiveAction(done)` closes
  /// the live IME connection, so the `enterText` of the *next* call lands on a
  /// dead connection and the field silently keeps its old text (seen on device
  /// as the blank's "3/50" counter surviving into the following tag — the
  /// widget itself is fine, `card_tag_after_error_test.dart` proves it). The
  /// tap re-focuses the field and opens a fresh connection, and the guard
  /// below turns any regression of this from a wrong-label mystery back into
  /// an explicit failure.
  Future<void> addTag(String name) async {
    await scrollToText(ItText.addTagHint);
    final field = find.byWidgetPredicate(
      (w) => w is TextField && w.decoration?.hintText == ItText.addTagHint,
    );
    expect(field, findsWidgets, reason: 'no tag field; $visibleText');
    await _tester.tap(field.first);
    await _harness.settle();
    await _tester.enterText(field.first, name);
    await _tester.pump();
    final typed = _tester.widget<TextField>(field.first).controller?.text;
    expect(
      typed,
      name,
      reason: 'tag field did not take "$name" — IME connection was stale',
    );
    await _tester.testTextInput.receiveAction(TextInputAction.done);
    await _harness.settle();
  }
}
