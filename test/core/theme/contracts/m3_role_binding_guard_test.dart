import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:flutter_test/flutter_test.dart';

import 'm3_role_bindings.dart';

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
  for (final RoleBinding binding in roleBindings) {
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
class RoleBinding {
  const RoleBinding({
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

  /// The declaration the slot lives in — a top-level function name, or
  /// `Type.method` for a method on an enum or class. The slot is then found
  /// inside it: as a named argument, as the whole body when [slot] and [scope]
  /// name the same thing, or — when neither exists — as the arm of a switch
  /// expression whose pattern ends in `.slot` (M100.36).
  ///
  /// **The third form exists for `MxFilledPair`.** M100.31 closed the filled
  /// button's builder to an enum so a caller could not hand it two loose
  /// colours; the price was that the role is no longer named beside a
  /// `backgroundColor:` label but inside `fillOf`'s switch. A guard that could
  /// only read named arguments therefore covered no `FilledButton` slot at all
  /// (#432 §5), which is how a `primary`-based overlay sat on the error pair.
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

_SchemeRoles _readsIn(RoleBinding binding) {
  final File file = File(binding.file);
  expect(file.existsSync(), isTrue, reason: 'missing ${binding.file}');

  final CompilationUnit unit = parseString(
    content: file.readAsStringSync(),
    throwIfDiagnostics: false,
  ).unit;

  final AstNode? declaration = _declarationNamed(unit, binding.scope);
  expect(
    declaration,
    isNotNull,
    reason: '${binding.scope} is gone from ${binding.file}',
  );

  final AstNode? target = binding.slot == binding.scope
      ? declaration
      : _namedArgument(declaration!, binding.slot) ??
            _switchArm(declaration, binding.slot);
  expect(
    target,
    isNotNull,
    reason:
        '${binding.scope} declares no `${binding.slot}:` argument and no '
        '`.${binding.slot}` switch arm',
  );

  final _SchemeRoles visitor = _SchemeRoles();
  target!.accept(visitor);

  return visitor;
}

/// A top-level function, or `Type.method` on an enum or class declaration.
AstNode? _declarationNamed(CompilationUnit unit, String scope) {
  final List<String> parts = scope.split('.');
  if (parts.length == 1) return _functionNamed(unit, scope);

  final String typeName = parts.first;
  final String methodName = parts.last;
  for (final CompilationUnitMember member in unit.declarations) {
    final NodeList<ClassMember>? members = switch (member) {
      EnumDeclaration(:final body)
          when member.namePart.typeName.lexeme == typeName =>
        body.members,
      ClassDeclaration(:final body)
          when member.namePart.typeName.lexeme == typeName =>
        body.members,
      _ => null,
    };
    if (members == null) continue;

    for (final ClassMember m in members) {
      if (m is MethodDeclaration && m.name.lexeme == methodName) return m;
    }
  }

  return null;
}

AstNode? _functionNamed(CompilationUnit unit, String name) {
  for (final CompilationUnitMember member in unit.declarations) {
    if (member is FunctionDeclaration && member.name.lexeme == name) {
      return member;
    }
  }

  return null;
}

/// The arm of a switch expression whose pattern names `.slot` — the body of
/// `MxFilledPair.brand => scheme.primary`. Only the arm's expression is
/// returned, so a role read in a sibling arm cannot satisfy this one.
AstNode? _switchArm(AstNode declaration, String slot) {
  final _SwitchArm visitor = _SwitchArm(slot);
  declaration.accept(visitor);

  return visitor.found;
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

class _SwitchArm extends RecursiveAstVisitor<void> {
  _SwitchArm(this.slot);

  final String slot;
  Expression? found;

  @override
  void visitSwitchExpressionCase(SwitchExpressionCase node) {
    if (found == null &&
        node.guardedPattern.pattern.toSource().endsWith('.$slot')) {
      found = node.expression;
    }
    super.visitSwitchExpressionCase(node);
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
