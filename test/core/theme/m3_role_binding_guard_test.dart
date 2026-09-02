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
      final Set<String> roles = _rolesIn(binding);

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

Set<String> _rolesIn(_Binding binding) {
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

  return visitor.roles;
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

/// Every `scheme.<role>` the subtree reads.
///
/// Both spellings are collected because the analyser models `a.b` as a
/// `PrefixedIdentifier` and `a.b.c` as a `PropertyAccess`, and a resolver that
/// grows a `?.` or a cast moves between them without changing what it means.
class _SchemeRoles extends RecursiveAstVisitor<void> {
  final Set<String> roles = <String>{};

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    if (node.prefix.name == 'scheme') roles.add(node.identifier.name);
    super.visitPrefixedIdentifier(node);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    final Expression? target = node.target;
    if (target is SimpleIdentifier && target.name == 'scheme') {
      roles.add(node.propertyName.name);
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

const String _nav = 'lib/core/theme/app_navigation_bar_theme.dart';
const String _chip = 'lib/core/theme/app_chip_theme.dart';
const String _planned = 'lib/core/theme/app_planned_themes.dart';
const String _buttons = 'lib/core/theme/app_button_themes.dart';
const String _toggles = 'lib/core/theme/app_toggle_themes.dart';

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
    file: _planned,
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
    file: _planned,
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
    file: _planned,
    scope: 'buildSegmentedButtonTheme',
    requires: <String>['outline'],
    refuses: <String>['primary', 'outlineVariant'],
    because:
        '_SegmentedButtonDefaultsM3.side has no focus branch. The keyboard '
        'cue is the overlay.',
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
        '`secondaryAction` token was a second name for it.',
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
