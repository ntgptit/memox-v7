import 'm3_role_binding_guard_test.dart' show RoleBinding;

/// The M100.36 slots — the FilledButton state layer, TextField and
/// ListTile — split from `m3_role_bindings.dart` at the 400-line guard. Same contract, same guard; the list is
/// spread into `roleBindings` so the scan sees one ledger.
const String _buttons =
    'lib/core/theme/components/actions/app_button_themes.dart';
const String _inputs = 'lib/core/theme/components/inputs/app_input_theme.dart';
const String _listTile =
    'lib/core/theme/components/content/app_list_tile_theme.dart';

const List<RoleBinding> inputRoleBindings = <RoleBinding>[
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
    slot: 'titleTextStyle',
    file: _listTile,
    scope: 'buildListTileTheme',
    requires: <String>['onSurface'],
    refuses: <String>['onSurfaceVariant', 'primary'],
    because: '_LisTileDefaultsM3.titleTextStyle is bodyLarge in onSurface.',
  ),
  RoleBinding(
    component: 'ListTile',
    slot: 'subtitleTextStyle',
    file: _listTile,
    scope: 'buildListTileTheme',
    requires: <String>['onSurfaceVariant'],
    refuses: <String>['onSurface', 'primary'],
    because:
        '_LisTileDefaultsM3.subtitleTextStyle is bodyMedium in '
        'onSurfaceVariant. A theme-level `textColor` flattened it onto the '
        'title ink for every ListTile in the app until M100.36 (#431 P1-1).',
  ),
  RoleBinding(
    component: 'ListTile',
    slot: 'leadingAndTrailingTextStyle',
    file: _listTile,
    scope: 'buildListTileTheme',
    requires: <String>['onSurfaceVariant'],
    refuses: <String>['onSurface', 'primary'],
    because: 'Trailing text is the secondary ink, at a readable rung.',
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
