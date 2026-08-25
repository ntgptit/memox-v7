import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';

/// The guard that would have caught every theme gap this project has had.
///
/// **Four gaps shipped before this existed, and none of them was findable.** The
/// twelve `*Fixed` roles, `switchTheme`, `checkboxTheme` and `timePickerTheme`
/// all survived `flutter analyze`, seventy guard rules and six `design_audit`
/// violation codes — because every one of those looks at *colour the code
/// writes*, and a missing theme writes nothing. A decision not made leaves no
/// trace to scan for.
///
/// So this scans from the other end: it reads `lib/` for the Material widgets
/// the app actually builds, and asks the built `ThemeData` whether the matching
/// slot was ever filled. Two rules, and the second matters as much as the first:
///
/// * **rendered ⇒ themed.** Build a `SegmentedButton` and this goes red in the
///   same pull request, not four milestones later.
/// * **themed ∧ not rendered ⇒ on a named list.** Otherwise the fix for the
///   first rule is to theme everything, which is the decision-without-a-screen
///   `app_theme.dart` spends a paragraph refusing.
/// A `//` or `///` line, anchored at the end of the line.
///
/// **Named rather than inlined because the anchor was wrong and nothing
/// noticed.** It shipped as `r'^\s*//.*\$'`, and in a Dart raw string `\$` is a
/// backslash and a dollar — which the regex engine reads as a *literal dollar
/// sign*, not as end-of-line. So the pattern matched only comment lines that
/// happen to end in `$`, and every other comment survived into the scan. The
/// guard still passed, which is the part worth remembering: a stripper that
/// strips nothing makes the scan see *more*, and more is the direction that
/// does not fail. `finds nothing in prose alone` below is what would have
/// caught it.
final RegExp _lineComment = RegExp(r'^\s*//.*$', multiLine: true);

void main() {
  final theme = buildLightTheme();
  final bare = ThemeData();

  /// Whether a slot holds anything other than the empty object `ThemeData`
  /// falls back to.
  ///
  /// Every slot is non-null, so "declared" cannot be a null check. What it can
  /// be is a comparison against an untouched `ThemeData`: component themes
  /// default to a `const XxxThemeData()` carrying no decisions, and the
  /// per-state resolution happens later in the widget's own `_DefaultsM3`.
  /// Anything the app passed makes the two differ.
  bool declared(Object? Function(ThemeData) slot) => slot(theme) != slot(bare);

  /// Widget constructor → the `ThemeData` slot that dresses it.
  ///
  /// Keyed by the identifier a call site writes, because that is what a scan
  /// can see. Several widgets share one slot, which is why this is a map to a
  /// record rather than a set of names.
  final slots = <String, (String, Object? Function(ThemeData))>{
    'AppBar': ('appBarTheme', (t) => t.appBarTheme),
    'Badge': ('badgeTheme', (t) => t.badgeTheme),
    'BottomAppBar': ('bottomAppBarTheme', (t) => t.bottomAppBarTheme),
    'BottomNavigationBar': (
      'bottomNavigationBarTheme',
      (t) => t.bottomNavigationBarTheme,
    ),
    'Card': ('cardTheme', (t) => t.cardTheme),
    'CarouselView': ('carouselViewTheme', (t) => t.carouselViewTheme),
    'Checkbox': ('checkboxTheme', (t) => t.checkboxTheme),
    'CheckboxListTile': ('checkboxTheme', (t) => t.checkboxTheme),
    'Chip': ('chipTheme', (t) => t.chipTheme),
    'ChoiceChip': ('chipTheme', (t) => t.chipTheme),
    'FilterChip': ('chipTheme', (t) => t.chipTheme),
    'InputChip': ('chipTheme', (t) => t.chipTheme),
    'ActionChip': ('chipTheme', (t) => t.chipTheme),
    'DataTable': ('dataTableTheme', (t) => t.dataTableTheme),
    'showDatePicker': ('datePickerTheme', (t) => t.datePickerTheme),
    'showDateRangePicker': ('datePickerTheme', (t) => t.datePickerTheme),
    'Dialog': ('dialogTheme', (t) => t.dialogTheme),
    'AlertDialog': ('dialogTheme', (t) => t.dialogTheme),
    'Divider': ('dividerTheme', (t) => t.dividerTheme),
    'VerticalDivider': ('dividerTheme', (t) => t.dividerTheme),
    'Drawer': ('drawerTheme', (t) => t.drawerTheme),
    'NavigationDrawer': (
      'navigationDrawerTheme',
      (t) => t.navigationDrawerTheme,
    ),
    'DropdownMenu': ('dropdownMenuTheme', (t) => t.dropdownMenuTheme),
    'ElevatedButton': ('elevatedButtonTheme', (t) => t.elevatedButtonTheme),
    'ExpansionTile': ('expansionTileTheme', (t) => t.expansionTileTheme),
    'FilledButton': ('filledButtonTheme', (t) => t.filledButtonTheme),
    'FloatingActionButton': (
      'floatingActionButtonTheme',
      (t) => t.floatingActionButtonTheme,
    ),
    'IconButton': ('iconButtonTheme', (t) => t.iconButtonTheme),
    'ListTile': ('listTileTheme', (t) => t.listTileTheme),
    'MenuAnchor': ('menuTheme', (t) => t.menuTheme),
    'MenuBar': ('menuBarTheme', (t) => t.menuBarTheme),
    'NavigationBar': ('navigationBarTheme', (t) => t.navigationBarTheme),
    'NavigationRail': ('navigationRailTheme', (t) => t.navigationRailTheme),
    'OutlinedButton': ('outlinedButtonTheme', (t) => t.outlinedButtonTheme),
    'PopupMenuButton': ('popupMenuTheme', (t) => t.popupMenuTheme),
    'Radio': ('radioTheme', (t) => t.radioTheme),
    'RadioListTile': ('radioTheme', (t) => t.radioTheme),
    'SearchAnchor': ('searchViewTheme', (t) => t.searchViewTheme),
    'SearchBar': ('searchBarTheme', (t) => t.searchBarTheme),
    'SegmentedButton': ('segmentedButtonTheme', (t) => t.segmentedButtonTheme),
    'Slider': ('sliderTheme', (t) => t.sliderTheme),
    'SnackBar': ('snackBarTheme', (t) => t.snackBarTheme),
    'Switch': ('switchTheme', (t) => t.switchTheme),
    'SwitchListTile': ('switchTheme', (t) => t.switchTheme),
    'TabBar': ('tabBarTheme', (t) => t.tabBarTheme),
    'TextButton': ('textButtonTheme', (t) => t.textButtonTheme),
    'TextField': ('inputDecorationTheme', (t) => t.inputDecorationTheme),
    'TextFormField': ('inputDecorationTheme', (t) => t.inputDecorationTheme),
    'ToggleButtons': ('toggleButtonsTheme', (t) => t.toggleButtonsTheme),
    'showTimePicker': ('timePickerTheme', (t) => t.timePickerTheme),
    'Tooltip': ('tooltipTheme', (t) => t.tooltipTheme),
    'showModalBottomSheet': ('bottomSheetTheme', (t) => t.bottomSheetTheme),
    'showBottomSheet': ('bottomSheetTheme', (t) => t.bottomSheetTheme),
    'LinearProgressIndicator': (
      'progressIndicatorTheme',
      (t) => t.progressIndicatorTheme,
    ),
    'CircularProgressIndicator': (
      'progressIndicatorTheme',
      (t) => t.progressIndicatorTheme,
    ),
    'Scrollbar': ('scrollbarTheme', (t) => t.scrollbarTheme),
  };

  /// Slots the app fills for something no call site names.
  ///
  /// Two kinds, and both need a reason rather than a shrug.
  const allowedUnrendered = <String, String>{
    // Rendered, but by a parameter rather than a constructor — a scan for
    // `Tooltip(` cannot see `IconButton(tooltip: ...)`.
    'tooltipTheme': 'built by the `tooltip:` parameter on 21 call sites',
    // A safety net for a widget the app does not build, declared so an
    // untended or third-party one degrades on-palette. `app_theme.dart` names
    // each of these where it sets them.
    'cardTheme': 'safety net for a bare `Card`; MxCard paints itself',
    // The waiting room. Every entry here is justified in
    // `app_planned_themes.dart`, and this list is what stops it growing.
    'datePickerTheme': 'planned — reminder date, deferred history range',
    'segmentedButtonTheme': 'planned — deferred progress range switch',
    'sliderTheme': 'planned — SM-2 parameters, deferred in CLAUDE.md',
    'tabBarTheme': 'planned — deferred card History view',
  };

  /// Every **hand-written** Dart file under `lib/`, comments stripped.
  ///
  /// **Generated files are excluded, and the reason is not tidiness.** This app
  /// has a `cards` table, so `drift` generates a row class called `Card` — and
  /// `app_database.g.dart` constructs it four times. A scan that reads
  /// generated code therefore reports `Card` as rendered, concludes the app
  /// builds Material `Card`s, and marks `cardTheme` covered by a widget nobody
  /// draws. The collision is real rather than hypothetical: it was this guard's
  /// first failure.
  ///
  /// Comments go for the same class of reason. This file's own prose, and the
  /// theme files', name these widgets constantly — `buildSwitchTheme`'s doc says
  /// `Checkbox` four times. Matching prose would make the guard pass for the
  /// wrong reason, which is worse than failing.
  final sources = Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .where((f) => !RegExp(r'\.(g|freezed|drift)\.dart$').hasMatch(f.path))
      .map((f) => f.readAsStringSync())
      .map((s) => s.replaceAll(_lineComment, ''))
      .toList();

  Set<String> renderedNames() {
    final found = <String>{};

    for (final name in slots.keys) {
      // The optional `<...>` is load-bearing: `RadioListTile<SchedulerType>(`
      // and `showModalBottomSheet<bool>(` are how these are actually written,
      // and a name-then-paren pattern misses every generic call site — which
      // reported the radio and the bottom sheet as unrendered while both were
      // on screen.
      final call = RegExp('(?<![A-Za-z0-9_])$name\\s*(<[^()]*>)?\\s*\\(');
      if (sources.any(call.hasMatch)) found.add(name);
    }

    return found;
  }

  test('every Material widget the app renders has a theme', () {
    final missing = <String>[];

    for (final name in renderedNames()) {
      final (slot, read) = slots[name]!;
      if (!declared(read)) missing.add('$name -> ThemeData.$slot');
    }

    expect(
      missing,
      isEmpty,
      reason:
          'These widgets render with Material defaults, so their hover, focus '
          'and disabled colours come from ThemeData fallbacks that carry no '
          'seed. Declare the slot in app_theme.dart, or stop rendering the '
          'widget:\n  ${missing.join("\n  ")}',
    );
  });

  test('no theme is declared for a component nobody renders', () {
    final rendered = renderedNames().map((n) => slots[n]!.$1).toSet();
    final unexplained = <String>[];

    for (final entry in slots.values) {
      final slot = entry.$1;
      if (rendered.contains(slot)) continue;
      if (allowedUnrendered.containsKey(slot)) continue;
      if (declared(entry.$2)) unexplained.add(slot);
    }

    expect(
      unexplained,
      isEmpty,
      reason:
          'A theme for a component nobody renders is a decision made without a '
          'screen to check it against. Either give it a caller, or add it to '
          'allowedUnrendered with the reason:\n  ${unexplained.join("\n  ")}',
    );
  });

  test('nothing on the unrendered allowlist has quietly gained a caller', () {
    // The other direction of the same list. An entry that becomes rendered
    // should move out of the allowlist and into the ordinary rule above, or
    // its stated reason is now a false explanation sitting in the test that
    // is supposed to be checking.
    final rendered = renderedNames().map((n) => slots[n]!.$1).toSet();
    final stale = allowedUnrendered.keys.where(rendered.contains).toList();

    expect(
      stale,
      isEmpty,
      reason:
          'These are now rendered, so their allowlist reason is out of '
          'date:\n  ${stale.join("\n  ")}',
    );
  });

  test('the widgets with no slot at all are covered another way', () {
    // **The blind spot this guard cannot close with its own mechanism, named
    // rather than left implicit.** `DropdownButton` is a Material 2 survivor
    // with no `ThemeData` slot — `dropdownMenuTheme` belongs to the unrelated
    // `DropdownMenu` — so a widget-to-slot map has nothing to point at, and
    // the card importer builds two of them. It resolves from top-level colours
    // instead, and Material's `disabledColor` fallback is a hardcoded
    // `black38` with no seed in it.
    //
    // A code review found this while the guard reported full coverage, which
    // is the honest limit of the mechanism: it proves every widget *that has a
    // slot* is themed, and nothing about the ones that do not.
    expect(
      declared((t) => t.canvasColor),
      isTrue,
      reason: "the dropdown menu is back on Material's canvas",
    );
    expect(
      declared((t) => t.disabledColor),
      isTrue,
      reason: 'a disabled dropdown label is back on a hardcoded black38',
    );
  });

  test('finds nothing in prose alone', () {
    // The negative the comment stripper exists for, run against the stripper
    // rather than against `lib/`. Three of these appear verbatim in this
    // repository's own doc comments — `PopupMenuButton<CardListSort>(` is in
    // `app_planned_themes.dart` — so a scan that reads comments reports them
    // rendered no matter what the code does.
    const prose = '''
/// A `NavigationRail(` in a doc comment.
// PopupMenuButton<CardListSort>(
    // DataTable(
''';

    final stripped = prose.replaceAll(_lineComment, '');

    for (final name in <String>[
      'NavigationRail',
      'PopupMenuButton',
      'DataTable',
    ]) {
      expect(
        RegExp(
          '(?<![A-Za-z0-9_])$name\\s*(<[^()]*>)?\\s*\\(',
        ).hasMatch(stripped),
        isFalse,
        reason: '$name survived comment stripping — the anchor is wrong again',
      );
    }
  });

  test('the scan can actually see a widget, and can miss one', () {
    // A coverage guard that silently matched nothing would pass forever. This
    // pins both halves: a widget the app is known to build is found, and a
    // widget it is known not to build is not.
    final rendered = renderedNames();

    expect(
      rendered,
      contains('Switch'),
      reason: 'the reminder toggle builds one — the scan is broken',
    );
    expect(
      rendered,
      isNot(contains('NavigationRail')),
      reason:
          'AD-04 ships no large-screen layout, so finding one means either the '
          'app grew a rail or the scan matches prose',
    );
  });
}
