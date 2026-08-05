import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/card/presentation/widgets/items/card_tile_widget.dart';
import 'package:memox/features/deck/presentation/widgets/items/deck_tile_widget.dart';
import 'package:memox/shared/widgets/mx_search_field.dart';
import 'package:memox/shared/widgets/mx_text_field.dart';

import 'it_harness.dart';

/// The user-facing copy the scenarios drive, named once.
///
/// Taken from `lib/l10n/app_en.arb`. Scenarios assert meaning rather than
/// wording (execution guide §9), but the robot has to *find* things, and a
/// literal repeated across twenty tests is twenty edits when the copy changes.
abstract final class ItText {
  static const String newDeck = 'New deck';
  static const String createSubmit = 'Create';
  static const String cancel = 'Cancel';
  static const String eightBox = 'Eight boxes';
  static const String sm2 = 'SM-2';
  static const String decksEmpty = 'No decks yet';
  static const String addToThisDeck = 'Add to this deck';
  static const String newSubDeck = 'New sub-deck';
  static const String newCard = 'New card';
  static const String cardListEmptyAction = 'Add card';
  static const String saveCard = 'Save card';
  static const String deckActions = 'Deck actions';
  static const String rename = 'Rename';
  static const String delete = 'Delete';
  static const String move = 'Move';
  static const String resetContentType = 'Allow cards or decks again';
  static const String allowBoth = 'Allow both';
  static const String decksTab = 'Decks';
  static const String reviewTab = 'Review';
  static const String cardEditorClose = 'Close';
  static const String detailsToggle = 'Add details';
  static const String detailsLabel = 'Details';
  static const String deleteCard = 'Delete card';
  static const String flagCard = 'Flag card';
  static const String unflagCard = 'Remove flag';
  static const String addTagHint = 'Add tag';
}

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
    await _tester.tap(finder.first);
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

  /// Flings the tallest vertical scrollable back to its top.
  ///
  /// Lazy lists dispose what scrolls out of the viewport, so any "first row"
  /// reading taken after a scroll-down describes the cache, not the list.
  Future<void> scrollToTop() async {
    final vertical = find.byWidgetPredicate(
      (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
    );
    for (var i = 0; i < 6; i++) {
      final centre = _tallestCentre(vertical);
      if (centre == null) break;
      await _tester.dragFrom(centre, const Offset(0, 1200));
      await _tester.pump(const Duration(milliseconds: 60));
    }
    await _harness.settle();
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

  /// Presses Back until the deck row named [name] is on screen.
  ///
  /// Hard-coded back counts kept being wrong in three different ways at once:
  /// the redirect keeps a card deck's own level off the stack when the deck was
  /// already typed, puts it on when the first card was created this visit, and
  /// deleting a last child adds a navigation of its own. Walking until the row
  /// is visible states the intent — "get back to where this deck is listed" —
  /// instead of encoding one stack shape and breaking on the other two.
  Future<void> backUntilRowVisible(String name, {int maxBacks = 5}) async {
    for (var i = 0; i < maxBacks; i++) {
      // Let the page transition land before looking: checking mid-flight sees
      // no rows, walks one level too far, and ends up at the root explaining
      // that the row it climbed past does not exist.
      await _tester.pump(const Duration(milliseconds: 400));
      await _harness.settle();
      if (_deckRow(name).evaluate().isNotEmpty) return;
      // One more beat before popping: a level can be mid-transition when the
      // first look happens, and popping past the level being looked for is
      // how a three-back walk ends up at the root asking where its row went.
      await _tester.pump(const Duration(milliseconds: 700));
      await _harness.settle();
      if (_deckRow(name).evaluate().isNotEmpty) return;
      await _harness.pressBack();
    }
    expect(
      _deckRow(name),
      findsWidgets,
      reason: 'no "$name" row within $maxBacks backs; $visibleText',
    );
  }

  Finder _deckRow(String name) => find.descendant(
    of: find.byType(DeckTileWidget),
    matching: find.text(name),
  );

  /// Waits until the card list and its count agree, or times out.
  ///
  /// "Showing X of Y" is the product's own consistency line: the list and the
  /// total are two statements, and after a search or filter change the lighter
  /// count query lands first. Settling on frames alone returns in that gap, so
  /// an assertion right after reads rows the old query produced. Waiting for
  /// X == Y keys the barrier to the invariant itself — and if the product ever
  /// genuinely diverges, the timeout lets the caller's assertion say so.
  Future<void> waitCardListSteady() async {
    final deadline = DateTime.now().add(const Duration(seconds: 6));
    while (DateTime.now().isBefore(deadline)) {
      await _tester.pump(const Duration(milliseconds: 150));
      final showing = _tester
          .widgetList<Text>(find.textContaining('Showing '))
          .map((w) => w.data)
          .whereType<String>()
          .toList();
      if (showing.isEmpty) return;
      final match = RegExp(r'Showing (\d+) of (\d+)').firstMatch(showing.first);
      if (match == null) return;
      final shown = int.parse(match.group(1)!);
      final total = int.parse(match.group(2)!);
      if (shown <= total) return;
    }
  }

  /// Puts the deck level's due filter into the requested state.
  ///
  /// The control is a toggle that shows the state currently applied — "All
  /// decks" or "Due only" — so choosing means tapping only when the wanted
  /// label is not already the one on screen.
  Future<void> setDeckDueFilter({required bool dueOnly}) async {
    final wanted = dueOnly ? 'Due only' : 'All decks';
    if (find.text(wanted).evaluate().isNotEmpty) return;
    final other = dueOnly ? 'All decks' : 'Due only';
    await tapText(other);
  }

  /// Types into the card list's search field.
  Future<void> enterCardSearch(String query) async {
    final field = find.descendant(
      of: find.byType(MxSearchField),
      matching: find.byType(TextField),
    );
    expect(field, findsWidgets, reason: 'no card search field; $visibleText');
    await _tester.enterText(field.first, query);
    await _tester.pump(const Duration(milliseconds: 600));
    await _harness.settle();
    await waitCardListSteady();
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
    await _tester.tap(target.first);
    await _harness.settle();
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

  /// The front text of the first card row on screen.
  ///
  /// Order assertions read this instead of comparing `getRect` tops: a row that
  /// has scrolled off screen has no geometry to read, so the geometric version
  /// crashes on exactly the lists long enough to make ordering interesting.
  String? firstRowFront() {
    final tiles = find.byType(CardTileWidget);
    if (tiles.evaluate().isEmpty) return null;
    final texts = _tester.widgetList<Text>(
      find.descendant(of: tiles.first, matching: find.byType(Text)),
    );

    return texts.isEmpty ? null : texts.first.data;
  }

  /// Puts the deck sort into [label] — 'A-Z' or 'Recent'.
  ///
  /// The control is a toggle showing the sort currently applied, not a picker,
  /// so choosing a sort means tapping only when it is not already the one on
  /// screen. Tapping unconditionally would flip away from the wanted order.
  Future<void> chooseSort(String label) async {
    if (find.text(label).evaluate().isNotEmpty) return;
    final other = label == 'A-Z' ? 'Recent' : 'A-Z';
    await tapText(other);
  }

  /// Asserts that row [above] sits higher than row [below].
  ///
  /// Scrolls so both are built before comparing: on a lazy list, comparing
  /// rects of rows that were never built at the same time reads the recycler,
  /// not the order. Adjacent pairs are the honest unit — a full-list order
  /// assertion needs every row alive at once, which a phone screen cannot do.
  Future<void> expectRowOrder(String above, String below) async {
    await scrollToText(above);
    await scrollToText(below);
    final a = find.text(above);
    final b = find.text(below);
    expect(a, findsWidgets, reason: 'no "$above" row; $visibleText');
    expect(b, findsWidgets, reason: 'no "$below" row; $visibleText');
    expect(
      _tester.getRect(a.first).top < _tester.getRect(b.first).top,
      isTrue,
      reason: '"$above" is not above "$below"',
    );
  }

  /// The given [labels] in the order they appear down the screen.
  ///
  /// Reading positions rather than asserting one index at a time: an order is a
  /// single fact, and a failure should print the order it found instead of
  /// "expected Alpha at 0".
  List<String> verticalOrderOf(List<String> labels) {
    final present =
        labels.where((l) => find.text(l).evaluate().isNotEmpty).toList()..sort(
          (a, b) => _tester
              .getRect(find.text(a).first)
              .top
              .compareTo(_tester.getRect(find.text(b).first).top),
        );

    return present;
  }

  /// Opens the overflow menu of the deck **row** named [deckName].
  ///
  /// Anchored to the row that carries the name, not `find(...).last`. Standing
  /// inside a deck there are two actions controls on screen — the app bar's,
  /// which belongs to the deck you are *in*, and each row's. Taking the last
  /// match silently operated on the open deck instead of the row: a delete
  /// aimed at a child removed its parent, and the level afterwards read "No
  /// sub-decks yet" for a reason that had nothing to do with the scenario.
  Future<void> openDeckActions(String deckName) async {
    final menu = find.descendant(
      of: find.ancestor(
        of: find.text(deckName),
        matching: find.byType(DeckTileWidget),
      ),
      matching: find.bySemanticsLabel(RegExp(ItText.deckActions)),
    );
    expect(
      menu,
      findsWidgets,
      reason: 'no actions control on the "$deckName" row; $visibleText',
    );
    await _tester.tap(menu.first);
    await _harness.settle();
  }

  /// Opens the overflow menu of the deck currently open — the app bar's.
  ///
  /// This is the one that can offer a content-type reset: only the open level
  /// knows whether it is empty (deck_list_screen.dart:167 vs :393).
  Future<void> openCurrentDeckActions() async {
    final rowMenus = find.descendant(
      of: find.byType(DeckTileWidget),
      matching: find.bySemanticsLabel(RegExp(ItText.deckActions)),
    );
    final all = find.bySemanticsLabel(RegExp(ItText.deckActions));
    expect(all, findsWidgets, reason: 'no actions control; $visibleText');
    final rows = rowMenus.evaluate().toSet();
    final appBar = all.evaluate().where((e) => !rows.contains(e));
    expect(
      appBar,
      isNotEmpty,
      reason: 'no app-bar actions control; $visibleText',
    );
    await _tester.tap(find.byElementPredicate((e) => e == appBar.first));
    await _harness.settle();
  }
}
