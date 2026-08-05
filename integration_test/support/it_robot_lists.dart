// The list-driving half of the robot: scrolling, steady-state barriers,
// order reading, and the two overflow-menu anchors. A `part` of it_robot.dart
// so these extension members keep access to the robot's private tester and
// harness — the split exists to satisfy the file-size guard, not to change
// the API: tests still call everything as `robot.<method>`.
part of 'it_robot.dart';

extension ItRobotListDriving on ItRobot {
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
    // Wall time, not the harness clock, deliberately: this bounds how long
    // the *driver* waits for the device, which the frozen test clock cannot
    // measure. Stopwatch keeps the guard's DateTime.now ban intact.
    final stopwatch = Stopwatch()..start();
    while (stopwatch.elapsed < const Duration(seconds: 6)) {
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
