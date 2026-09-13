import 'm3_role_binding_guard_test.dart' show RoleBinding;
import 'm3_role_bindings_inputs.dart';

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
    requires: <String>['surfaceContainerLowest'],
    refuses: <String>['surface', 'surfaceContainerLow', 'surfaceContainer'],
    because:
        'The Tokyo handoff draws its card on surfaceContainerLowest — white '
        'above a tinted page. `Low` sits below the page in light, so a card on '
        'it reads as a hole rather than a surface (M100.87, the kit outranks '
        '_CardDefaultsM3 by owner decision).',
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
    slot: 'iconTheme',
    file: _appBar,
    scope: 'buildAppBarTheme',
    requires: <String>['onSurface'],
    refuses: <String>['onSurfaceVariant'],
    because:
        '_AppBarDefaultsM3.iconTheme is onSurface. Left unset, app_bar.dart '
        'hands the leading to iconButtonTheme (onSurfaceVariant), one ink '
        'step quieter than canonical (A20.1 P2-05).',
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
    requires: <String>['primaryContainer', 'surfaceContainerLow'],
    refuses: <String>['secondaryContainer'],
    because:
        'M100.86: the owner\'s Chip design spec names primaryContainer for '
        'the selected fill, a stated departure from '
        '_ChoiceChipDefaultsM3.color\'s own secondaryContainer — '
        'design-system/chip-spec.md.',
  ),
  RoleBinding(
    component: 'ChoiceChip',
    slot: '_labelColorFor',
    file: _chip,
    scope: '_labelColorFor',
    requires: <String>['onPrimaryContainer', 'onSurfaceVariant'],
    refuses: <String>['onSecondaryContainer'],
    because:
        'M100.86: the label follows the fill to primaryContainer\'s own ink, '
        'onPrimaryContainer — design-system/chip-spec.md.',
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
  // **The three brand *labels* read the brand's ink, and refuse the fill**
  // (M100.87). M100.28 ruled that a text slot must read `primary` and the
  // palette move when it failed; the owner reversed that for the Tokyo
  // handoff — its hex stays verbatim, and text takes an ink solved from it.
  // So these rows now require `semantic.accentInk` and refuse `scheme.primary`:
  // a slot drifting back to the fill is back at 3.95:1. `accent` is the
  // argument the text-link resolver takes its resting, hovered and pressed
  // colour from, so it is the slot.
  RoleBinding(
    component: 'TextButton',
    slot: 'accent',
    file: _buttons,
    scope: 'buildTextButtonTheme',
    requires: <String>[],
    requiresSemantic: <String>['accentInk'],
    refuses: <String>['primary', 'secondary', 'tertiary', 'onSurfaceVariant'],
    because:
        'A text link is bare text on a surface, and the handoff\'s light '
        'primary reads 3.95:1 there — the label is the brand\'s ink.',
  ),
  RoleBinding(
    component: 'TabBar',
    slot: 'labelColor',
    file: _tabs,
    scope: 'buildTabBarTheme',
    requires: <String>[],
    requiresSemantic: <String>['accentInk'],
    refuses: <String>[
      'primary',
      'secondary',
      'tertiary',
      'onSurfaceVariant',
      'onSecondaryContainer',
    ],
    because:
        'The selected label sits on the page, not on a container, so it is '
        'the brand as text — its ink, not its fill.',
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
    requires: <String>[],
    requiresSemantic: <String>['accentInk'],
    refuses: <String>['primary', 'secondary', 'onSurfaceVariant'],
    because:
        'The label is text on a page or a card — the brand\'s ink (M100.87). '
        'The retired `secondaryAction` token is still refused by name.',
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

  ...inputRoleBindings,
];
