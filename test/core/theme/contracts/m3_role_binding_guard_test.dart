import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:flutter_test/flutter_test.dart';

/// **Which role does the source *name* in this slot?** — read off the AST, not
/// off the rendered colour.
///
/// `m3_role_contract_test.dart` resolves the theme and compares values, and that
/// is necessary but it is not sufficient: two roles can carry the same hex. In
/// this palette several do — `outlineVariant` and the retired `borderSubtle`
/// were byte-identical, `surfaceContainerHighest` and `secondaryContainer` are
/// the same value in dark, and `dangerContainer` is `errorContainer` by
/// construction. Against any of those a value comparison passes while the source
/// says the wrong thing, and the next person to change one of the two tones
/// discovers the binding was wrong all along.
///
/// So this file asks the other half of the question. It parses the theme
/// builders and collects, per slot, the set of `scheme.<role>` reads the source
/// actually performs — then requires the canonical ones and refuses the ones a
/// component has drifted onto before.
///
/// **Parsed rather than matched**, on the seam `command_query_scan.dart`
/// already established here: a role name inside a doc comment or a string is not
/// an AST node, and every one of these files carries paragraphs naming the roles
/// they used to read.
void main() {
  for (final _Binding binding in _bindings) {
    test('${binding.component} · ${binding.slot}', () {
      final _SchemeRoles reads = _readsIn(binding);
      final Set<String> roles = reads.roles;

      // **A slot that names an app token instead of a scheme role is the
      // substitute this file exists to refuse (M100.28).** `primaryInk` passed
      // every runtime pin while it stood in for `primary`, because the two
      // resolved to one value; only the source said which one the slot read.
      final Set<String> substitutes = reads.semanticReads.difference(
        _allowedSemanticReads,
      );
      expect(
        substitutes,
        isEmpty,
        reason:
            '${binding.component}.${binding.slot} reads '
            '`semantic.${substitutes.join('`, `semantic.')}` — an app token '
            'standing in for a canonical role. If the role fails a ratio, '
            'retune the palette; never route the slot around it.',
      );

      for (final String required in binding.requires) {
        expect(
          roles,
          contains(required),
          reason:
              '${binding.component}.${binding.slot} no longer reads '
              '`scheme.$required`. ${binding.because}',
        );
      }

      for (final String forbidden in binding.refuses) {
        expect(
          roles,
          isNot(contains(forbidden)),
          reason:
              '${binding.component}.${binding.slot} reads `scheme.$forbidden`. '
              '${binding.because}',
        );
      }
    });
  }
}

/// One slot's binding contract.
class _Binding {
  const _Binding({
    required this.component,
    required this.slot,
    required this.file,
    required this.scope,
    required this.requires,
    required this.refuses,
    required this.because,
  });

  final String component;
  final String slot;
  final String file;

  /// The declaration the slot lives in — a top-level function name. The slot is
  /// then found inside it, either as a named argument or as the whole body when
  /// [slot] and [scope] name the same thing.
  final String scope;

  final List<String> requires;
  final List<String> refuses;
  final String because;
}

/// The `semantic.<token>` reads a role slot may carry: the disabled pair, which
/// every role slot needs and which M3 itself spells as `onSurface @ 12% / 38%`
/// before AD-14 R7 flattens it into a token. Anything else is a substitute.
const Set<String> _allowedSemanticReads = <String>{
  'onDisabled',
  'disabledSurface',
};

_SchemeRoles _readsIn(_Binding binding) {
  final File file = File(binding.file);
  expect(file.existsSync(), isTrue, reason: 'missing ${binding.file}');

  final CompilationUnit unit = parseString(
    content: file.readAsStringSync(),
    throwIfDiagnostics: false,
  ).unit;

  final AstNode? declaration = _functionNamed(unit, binding.scope);
  expect(
    declaration,
    isNotNull,
    reason: '${binding.scope} is gone from ${binding.file}',
  );

  final AstNode? target = binding.slot == binding.scope
      ? declaration
      : _namedArgument(declaration!, binding.slot);
  expect(
    target,
    isNotNull,
    reason: '${binding.scope} declares no `${binding.slot}:` argument',
  );

  final _SchemeRoles visitor = _SchemeRoles();
  target!.accept(visitor);

  return visitor;
}

AstNode? _functionNamed(CompilationUnit unit, String name) {
  for (final CompilationUnitMember member in unit.declarations) {
    if (member is FunctionDeclaration && member.name.lexeme == name) {
      return member;
    }
  }

  return null;
}

AstNode? _namedArgument(AstNode declaration, String label) {
  final _NamedArgument visitor = _NamedArgument(label);
  declaration.accept(visitor);

  return visitor.found;
}

/// Every `scheme.<role>` the subtree reads — and every `semantic.<token>`, so
/// a slot that swapped a role for an app token is caught by name.
///
/// Both spellings are collected because the analyser models `a.b` as a
/// `PrefixedIdentifier` and `a.b.c` as a `PropertyAccess`, and a resolver that
/// grows a `?.` or a cast moves between them without changing what it means.
class _SchemeRoles extends RecursiveAstVisitor<void> {
  final Set<String> roles = <String>{};
  final Set<String> semanticReads = <String>{};

  void _record(String prefix, String member) {
    if (prefix == 'scheme') roles.add(member);
    if (prefix == 'semantic') semanticReads.add(member);
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    _record(node.prefix.name, node.identifier.name);
    super.visitPrefixedIdentifier(node);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    final Expression? target = node.target;
    if (target is SimpleIdentifier) {
      _record(target.name, node.propertyName.name);
    }
    super.visitPropertyAccess(node);
  }
}

class _NamedArgument extends RecursiveAstVisitor<void> {
  _NamedArgument(this.label);

  final String label;
  Expression? found;

  @override
  void visitNamedExpression(NamedExpression node) {
    if (found == null && node.name.label.name == label) {
      found = node.expression;
    }
    super.visitNamedExpression(node);
  }
}

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
const String _toggles =
    'lib/core/theme/components/selection/app_toggle_themes.dart';

const List<_Binding> _bindings = <_Binding>[
  _Binding(
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
  _Binding(
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
  _Binding(
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
  _Binding(
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
  _Binding(
    component: 'ChoiceChip',
    slot: '_restingFill',
    file: _chip,
    scope: '_restingFill',
    requires: <String>['secondaryContainer', 'surface'],
    refuses: <String>['primaryContainer'],
    because:
        '_ChoiceChipDefaultsM3.color fills a selected chip with '
        'secondaryContainer.',
  ),
  _Binding(
    component: 'ChoiceChip',
    slot: '_labelColorFor',
    file: _chip,
    scope: '_labelColorFor',
    requires: <String>['onSecondaryContainer', 'onSurfaceVariant'],
    refuses: <String>['onPrimaryContainer'],
    because:
        '_ChoiceChipDefaultsM3.labelStyle pairs the fill with its own ink.',
  ),
  _Binding(
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
  _Binding(
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
  _Binding(
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
  _Binding(
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
  _Binding(
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
  _Binding(
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
  _Binding(
    component: 'TabBar',
    slot: 'indicatorColor',
    file: _tabs,
    scope: 'buildTabBarTheme',
    requires: <String>['primary'],
    refuses: <String>['secondary', 'tertiary', 'secondaryContainer'],
    because: '_TabBarDefaultsM3.indicatorColor is primary.',
  ),
  _Binding(
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
  _Binding(
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
  _Binding(
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
  _Binding(
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
  _Binding(
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
  _Binding(
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
];
