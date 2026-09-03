import 'm3_role_binding_guard_test.dart' show RoleBinding;

/// The slot-by-slot binding contract, split out of the guard at M100.32.
///
/// **The guard crossed the 400-line ceiling when M100.32 pinned five more
/// slots**, and the seam is the one this repository always cuts on: the AST
/// machinery is one thing and the table it walks is another. They change for
/// different reasons — the machinery when Dart's analyzer API moves, the table
/// every time a component's canonical role is pinned or corrected.

const String _nav =
    'lib/core/theme/components/navigation/app_navigation_bar_theme.dart';
const String _chip = 'lib/core/theme/components/selection/app_chip_theme.dart';
// The three that left `app_planned_themes.dart` at M100.31, each to the
// family it belongs to. One constant each, because a guard that pointed at a
// grab-bag could not say which component it was reading.
const String _segmented =
    'lib/core/theme/components/selection/app_segmented_button_theme.dart';
const String _tabs =
    'lib/core/theme/components/navigation/app_tab_bar_theme.dart';
const String _buttons =
    'lib/core/theme/components/actions/app_button_themes.dart';
const String _fab = 'lib/core/theme/components/actions/app_fab_theme.dart';
const String _card = 'lib/core/theme/components/surfaces/app_card_theme.dart';
const String _appBar =
    'lib/core/theme/components/navigation/app_app_bar_theme.dart';
const String _toggles =
    'lib/core/theme/components/selection/app_toggle_themes.dart';
const String _inputs = 'lib/core/theme/components/inputs/app_input_theme.dart';
const String _listTile =
    'lib/core/theme/components/content/app_list_tile_theme.dart';

const List<RoleBinding> roleBindings = <RoleBinding>[
  // --- restored at M100.32 -------------------------------------------------
  //
  // Three slots that had left their canonical role, each for a reason that was
  // recorded and each still a substitution. They are pinned here first because
  // a guard that only covers what was never wrong is a guard that never fired.
  RoleBinding(
    component: 'FloatingActionButton',
    slot: 'backgroundColor',
    file: _fab,
    scope: 'buildFloatingActionButtonTheme',
    requires: <String>['primaryContainer'],
    refuses: <String>['primary', 'secondaryContainer', 'tertiaryContainer'],
    because:
        '_FABDefaultsM3.backgroundColor is primaryContainer. It was `primary` '
        'from an owner mockup (2026-08-20); if the FAB needs more brand, the '
        'primaryContainer family moves — this slot does not.',
  ),
  RoleBinding(
    component: 'FloatingActionButton',
    slot: 'foregroundColor',
    file: _fab,
    scope: 'buildFloatingActionButtonTheme',
    requires: <String>['onPrimaryContainer'],
    refuses: <String>['onPrimary'],
    because: '_FABDefaultsM3.foregroundColor is onPrimaryContainer.',
  ),
  RoleBinding(
    component: 'Card',
    slot: 'color',
    file: _card,
    scope: 'buildCardTheme',
    requires: <String>['surfaceContainerLow'],
    refuses: <String>['surface', 'surfaceContainerLowest', 'surfaceContainer'],
    because:
        '_CardDefaultsM3.color is surfaceContainerLow. `surface` passed for as '
        'long as the app read `surface` as the paper; it is the page since '
        'M100.32, and the paper has its own rung.',
  ),
  RoleBinding(
    component: 'AppBar',
    slot: 'backgroundColor',
    file: _appBar,
    scope: 'buildAppBarTheme',
    requires: <String>['surface'],
    refuses: <String>['surfaceContainer', 'surfaceContainerLow'],
    because:
        '_AppBarDefaultsM3.backgroundColor is surface, which is the page. The '
        'builder took a `background` colour past the scheme until M100.32.',
  ),
  RoleBinding(
    component: 'AppBar',
    slot: 'foregroundColor',
    file: _appBar,
    scope: 'buildAppBarTheme',
    requires: <String>['onSurface'],
    refuses: <String>['onSurfaceVariant'],
    because: '_AppBarDefaultsM3.foregroundColor is onSurface.',
  ),
  RoleBinding(
    component: 'NavigationBar',
    slot: 'backgroundColor',
    file: _nav,
    scope: 'buildNavigationBarTheme',
    requires: <String>['surfaceContainer'],
    refuses: <String>['surface', 'surfaceContainerHigh'],
    because:
        '_NavigationBarDefaultsM3.backgroundColor is surfaceContainer; the '
        'bar took the page colour until M100.22.',
  ),
  RoleBinding(
    component: 'NavigationBar',
    slot: 'indicatorColor',
    file: _nav,
    scope: 'buildNavigationBarTheme',
    requires: <String>['secondaryContainer'],
    refuses: <String>['primaryContainer'],
    because:
        '_NavigationBarDefaultsM3.indicatorColor is secondaryContainer. If '
        'the indicator does not read against the bar, move the tone in '
        'AppMaterialRoles — not this binding.',
  ),
  RoleBinding(
    component: 'NavigationBar',
    slot: 'iconTheme',
    file: _nav,
    scope: 'buildNavigationBarTheme',
    requires: <String>['onSecondaryContainer', 'onSurfaceVariant'],
    refuses: <String>['onPrimaryContainer'],
    because:
        'The active glyph sits inside the indicator and takes its `on` '
        'role.',
  ),
  RoleBinding(
    component: 'NavigationBar',
    slot: 'labelTextStyle',
    file: _nav,
    scope: 'buildNavigationBarTheme',
    requires: <String>['onSurface', 'onSurfaceVariant'],
    refuses: <String>['onPrimaryContainer', 'onSecondaryContainer'],
    because:
        'The active label sits *below* the indicator, on the bar, so M3 '
        'inks it onSurface rather than with the pill.',
  ),
  RoleBinding(
    component: 'ChoiceChip',
    slot: '_restingFill',
    file: _chip,
    scope: '_restingFill',
    requires: <String>['secondaryContainer', 'surfaceContainerLow'],
    refuses: <String>['primaryContainer'],
    because:
        '_ChoiceChipDefaultsM3.color fills a selected chip with '
        'secondaryContainer.',
  ),
  RoleBinding(
    component: 'ChoiceChip',
    slot: '_labelColorFor',
    file: _chip,
    scope: '_labelColorFor',
    requires: <String>['onSecondaryContainer', 'onSurfaceVariant'],
    refuses: <String>['onPrimaryContainer'],
    because:
        '_ChoiceChipDefaultsM3.labelStyle pairs the fill with its own ink.',
  ),
  RoleBinding(
    component: 'ChoiceChip',
    slot: 'side',
    file: _chip,
    scope: 'buildChipTheme',
    requires: <String>['outlineVariant'],
    refuses: <String>['primary', 'outline'],
    because:
        'Unselected is outlineVariant and selected is transparent. A focus '
        'ring here left the canonical role on `selected + focused`; the cue '
        'belongs in the fill.',
  ),
  RoleBinding(
    component: 'SegmentedButton',
    slot: 'backgroundColor',
    file: _segmented,
    scope: 'buildSegmentedButtonTheme',
    requires: <String>['secondaryContainer'],
    refuses: <String>['primaryContainer'],
    because:
        '_SegmentedButtonDefaultsM3 fills a selected segment with '
        'secondaryContainer.',
  ),
  RoleBinding(
    component: 'SegmentedButton',
    slot: 'foregroundColor',
    file: _segmented,
    scope: 'buildSegmentedButtonTheme',
    requires: <String>['onSecondaryContainer', 'onSurface'],
    refuses: <String>['onPrimaryContainer', 'onSurfaceVariant'],
    because:
        'An unselected segment is onSurface — the navigation answer '
        '(onSurfaceVariant) had been taken by mistake.',
  ),
  RoleBinding(
    component: 'SegmentedButton',
    slot: 'side',
    file: _segmented,
    scope: 'buildSegmentedButtonTheme',
    requires: <String>['outline'],
    refuses: <String>['primary', 'outlineVariant'],
    because:
        '_SegmentedButtonDefaultsM3.side has no focus branch. The keyboard '
        'cue is the overlay.',
  ),
  // **TextButton and TabBar are the two `primaryInk` reached first (M100.27),
  // and neither had a row here.** The runtime contract compares resolved
  // colours, so a token equal to `primary` passed it; only the source shows
  // which name the slot reads. `accent` is the argument the text-link resolver
  // takes its resting, hovered and pressed colour from, so it is the slot.
  RoleBinding(
    component: 'TextButton',
    slot: 'accent',
    file: _buttons,
    scope: 'buildTextButtonTheme',
    requires: <String>['primary'],
    refuses: <String>['secondary', 'tertiary', 'onSurfaceVariant'],
    because:
        '_TextButtonDefaultsM3.foregroundColor is primary. A text link is bare '
        'text on a surface; if the role fails 4.5:1 there, the palette moves.',
  ),
  RoleBinding(
    component: 'TabBar',
    slot: 'labelColor',
    file: _tabs,
    scope: 'buildTabBarTheme',
    requires: <String>['primary'],
    refuses: <String>[
      'secondary',
      'tertiary',
      'onSurfaceVariant',
      'onSecondaryContainer',
    ],
    because:
        '_TabBarDefaultsM3.labelColor is primary: the selected label sits on '
        'the page, not on a container, so it is the accent as ink.',
  ),
  RoleBinding(
    component: 'TabBar',
    slot: 'indicatorColor',
    file: _tabs,
    scope: 'buildTabBarTheme',
    requires: <String>['primary'],
    refuses: <String>['secondary', 'tertiary', 'secondaryContainer'],
    because: '_TabBarDefaultsM3.indicatorColor is primary.',
  ),
  RoleBinding(
    component: 'OutlinedButton',
    slot: 'foregroundColor',
    file: _buttons,
    scope: 'buildOutlinedButtonTheme',
    requires: <String>['primary'],
    refuses: <String>['secondary', 'onSurfaceVariant'],
    because:
        '_OutlinedButtonDefaultsM3.foregroundColor is primary. The retired '
        '`secondaryAction` token was a second name for it, and M100.27\'s '
        '`primaryInk` was another — a role that fails a ratio is answered by '
        'retuning the palette (M100.28), never by a substitute token.',
  ),
  RoleBinding(
    component: 'OutlinedButton',
    slot: 'side',
    file: _buttons,
    scope: 'buildOutlinedButtonTheme',
    requires: <String>['outline', 'primary'],
    refuses: <String>['outlineVariant'],
    because:
        'outline at rest and primary on focus — this is the one component '
        'whose border role M3 itself changes with focus, so both are required.',
  ),
  RoleBinding(
    component: 'Switch',
    slot: 'thumbColor',
    file: _toggles,
    scope: 'buildSwitchTheme',
    requires: <String>['outline', 'onPrimary'],
    refuses: <String>['onSurfaceVariant'],
    because:
        '_SwitchDefaultsM3 rests the thumb on outline. It read '
        'onSurfaceVariant to dodge a contrast failure that M100.22 fixed in the '
        'palette instead.',
  ),
  RoleBinding(
    component: 'Switch',
    slot: 'trackColor',
    file: _toggles,
    scope: 'buildSwitchTheme',
    requires: <String>['surfaceContainerHighest', 'primary'],
    refuses: <String>['surfaceContainerHigh'],
    because:
        'The resting track is surfaceContainerHighest. `surfaceMuted` was '
        'surfaceContainerHigh — one rung low.',
  ),
  RoleBinding(
    component: 'Switch',
    slot: 'trackOutlineColor',
    file: _toggles,
    scope: 'buildSwitchTheme',
    requires: <String>['outline'],
    refuses: <String>['primary'],
    because:
        '_SwitchDefaultsM3.trackOutlineColor is transparent when selected '
        'and outline otherwise, with no focus branch. Reading focus first put a '
        'focused-on switch on a boundary M3 says should not exist.',
  ),
  RoleBinding(
    component: 'Checkbox',
    slot: 'side',
    file: _toggles,
    scope: 'buildCheckboxTheme',
    requires: <String>['onSurfaceVariant', 'onSurface'],
    refuses: <String>['primary', 'outline'],
    because:
        '_CheckboxDefaultsM3.side decides `selected` before any '
        'interaction state and inks focus the same onSurface as hover.',
  ),

  // --- pinned at M100.36 ---------------------------------------------------
  //
  // The four families the deep audits (#431–#434) found unguarded. Each row
  // held on the day it was written; the guard is what keeps it held.
  //
  // **FilledButton reads its pair through `MxFilledPair`, and the slot is a
  // switch arm, not a named argument.** M100.31 closed the builder to an enum
  // so a caller could not hand it two loose colours; the price is that the
  // role is named inside `fillOf` / `labelOf` rather than beside a
  // `backgroundColor:` label. `scope` therefore points at the enum method and
  // `slot` at the arm — `m3_role_binding_guard_test.dart` resolves both.
  RoleBinding(
    component: 'FilledButton fill',
    slot: 'brand',
    file: _buttons,
    scope: 'MxFilledPair.fillOf',
    requires: <String>['primary'],
    refuses: <String>['primaryContainer', 'secondary', 'secondaryContainer'],
    because:
        '_FilledButtonDefaultsM3.backgroundColor is primary. The brand '
        'button is the one place the accent is a fill.',
  ),
  RoleBinding(
    component: 'FilledButton label',
    slot: 'brand',
    file: _buttons,
    scope: 'MxFilledPair.labelOf',
    requires: <String>['onPrimary'],
    refuses: <String>['onPrimaryContainer', 'onSurface', 'surface'],
    because: '_FilledButtonDefaultsM3.foregroundColor is onPrimary.',
  ),
  RoleBinding(
    component: 'FilledButton fill',
    slot: 'destructive',
    file: _buttons,
    scope: 'MxFilledPair.fillOf',
    requires: <String>['error'],
    refuses: <String>['errorContainer', 'primary', 'tertiary'],
    because:
        'A destructive action is a FilledButton on the error pair — `error` is '
        '`danger` at the palette level, so this is not a second red.',
  ),
  RoleBinding(
    component: 'FilledButton label',
    slot: 'destructive',
    file: _buttons,
    scope: 'MxFilledPair.labelOf',
    requires: <String>['onError'],
    refuses: <String>['onErrorContainer', 'onPrimary', 'onSurface'],
    because: 'The label that travels with `error` is `onError`.',
  ),
  // The slot #432 §5 was opened for: the state layer must be the *pair's*
  // `on` role, never the brand. Two rows, because a swap on one pair while
  // the other stays correct is exactly the shape the defect had.
  RoleBinding(
    component: 'FilledButton state layer',
    slot: 'brand',
    file: _buttons,
    scope: 'MxFilledPair.stateLayerOf',
    requires: <String>['onPrimary'],
    refuses: <String>['primary', 'onSurface', 'onPrimaryContainer'],
    because:
        '_FilledButtonDefaultsM3.overlayColor is onPrimary at 0.08/0.10. A '
        '`primary` layer on a `primary` fill is a no-op that cancelled the '
        'blend it was stacked under (#432 §3.2).',
  ),
  RoleBinding(
    component: 'FilledButton state layer',
    slot: 'destructive',
    file: _buttons,
    scope: 'MxFilledPair.stateLayerOf',
    requires: <String>['onError'],
    refuses: <String>['primary', 'error', 'onSurface', 'onErrorContainer'],
    because:
        'The layer over `error` is `onError`. `primary` here painted indigo '
        'over red and rotated the fill 345.7° → 338.5° on every press.',
  ),
  RoleBinding(
    component: 'TextField',
    slot: 'enabledBorder',
    file: _inputs,
    scope: 'buildInputDecorationTheme',
    requires: <String>['outline'],
    refuses: <String>['outlineVariant', 'onSurface', 'primary'],
    because:
        '_InputDecoratorDefaultsM3.outlineBorder rests on outline. The '
        'hairline (outlineVariant, once `borderSubtle`) measured 1.38:1 and '
        'an empty field is identified by its edge alone.',
  ),
  RoleBinding(
    component: 'TextField',
    slot: 'focusedBorder',
    file: _inputs,
    scope: 'buildInputDecorationTheme',
    requires: <String>['primary'],
    refuses: <String>['secondary', 'tertiary', 'onSurface'],
    because: '_InputDecoratorDefaultsM3.outlineBorder is primary on focus.',
  ),
  RoleBinding(
    component: 'TextField',
    slot: 'errorBorder',
    file: _inputs,
    scope: 'buildInputDecorationTheme',
    requires: <String>['error'],
    refuses: <String>['onErrorContainer', 'errorContainer', 'tertiary'],
    because: '_InputDecoratorDefaultsM3.outlineBorder is error under error.',
  ),
  RoleBinding(
    component: 'TextField',
    slot: 'focusedErrorBorder',
    file: _inputs,
    scope: 'buildInputDecorationTheme',
    requires: <String>['error'],
    refuses: <String>['onErrorContainer', 'errorContainer', 'primary'],
    because:
        '_InputDecoratorDefaultsM3.outlineBorder stays `error` when focused '
        'and errored — M3 tells focus apart by the stroke (1 → 2), never by '
        'a third hue. `onErrorContainer` is its *hover*-under-error colour '
        'and was proposed for this slot once; refused here so the answer is '
        'the stroke, per M100.36 4C.',
  ),
  RoleBinding(
    component: 'ListTile',
    slot: 'iconColor',
    file: _listTile,
    scope: 'buildListTileTheme',
    requires: <String>['onSurfaceVariant'],
    refuses: <String>['onSurface', 'primary'],
    because: '_LisTileDefaultsM3.iconColor is onSurfaceVariant.',
  ),
  RoleBinding(
    component: 'ListTile',
    slot: 'selectedColor',
    file: _listTile,
    scope: 'buildListTileTheme',
    requires: <String>['primary'],
    refuses: <String>['secondary', 'onSecondaryContainer'],
    because:
        '_LisTileDefaultsM3.selectedColor is primary; the secondary accent '
        'belongs to the card edge and the glyph (3:1 graphics), not to a row '
        'label that needs 4.5:1.',
  ),
];
