import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/command_query_scan.dart';

/// `presentation/` may hold a repository; it may not call one.
///
/// **The rule existed and nothing checked it.** `CLAUDE.md` says a controller
/// calls a use case and does not read a repository, and four such calls lived in
/// `StudySessionController` through four merged pull requests. Both existing
/// guards inspect **imports**, and `presentation/` is allowed to import
/// `domain/repositories/` — the contract is a legitimate type to name. What
/// nobody checked was the call.
///
/// **Passing the repository into a use case is the point, not the violation.**
/// `SomeUseCase(ref.watch(repoProvider)).call(...)` is exactly right: the
/// provider is read and handed straight on. What this test forbids is a method
/// invoked *on* that value — the moment presentation starts asking the data
/// layer questions itself, the use case layer stops being where interactions
/// are defined and becomes optional decoration.
void main() {
  test('no presentation file calls a method on a repository', () {
    final offenders = <String>[];

    for (final file in dartFilesUnder('lib/features')) {
      final path = file.path.replaceAll(r'\', '/');
      if (!path.contains('/presentation/')) continue;
      if (path.endsWith('.g.dart') || path.endsWith('.freezed.dart')) continue;

      final unit = parseString(content: file.readAsStringSync()).unit;
      final visitor = _RepositoryCallVisitor();
      unit.visitChildren(visitor);

      for (final call in visitor.calls) {
        offenders.add('${path.split('lib/').last}: $call');
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'A controller calls a use case; it does not read a repository. Wrap '
          'the call in a use case under domain/usecases/ and call that '
          'instead.\n${offenders.join('\n')}',
    );
  });
}

/// Finds a method invoked on something that came out of a repository provider.
///
/// Two shapes, because both have appeared: the chained
/// `ref.read(fooRepositoryProvider).bar()`, and the two-step where the provider
/// is stored in a local first and the call comes later. The second is the one
/// that hid for four pull requests, so catching only the chain would leave the
/// check looking green while the habit continued.
final class _RepositoryCallVisitor extends RecursiveAstVisitor<void> {
  final List<String> calls = <String>[];

  /// Locals holding a repository, by name.
  final Set<String> _holders = <String>{};

  /// Whether [expression] *is* a read of a repository provider.
  ///
  /// **Shape, not substring.** A first draft asked whether the source text
  /// contained `.read(` and `RepositoryProvider`, and flagged every
  /// `SomeUseCase(ref.read(repoProvider)).call()` — the pattern that is
  /// correct. What matters is whether the thing being called on *is* the read,
  /// or merely contains one somewhere inside it.
  static bool _isRepositoryProviderRead(Expression? expression) {
    if (expression is! MethodInvocation) return false;

    final name = expression.methodName.name;
    if (name != 'read' && name != 'watch') return false;

    return expression.argumentList.arguments.any(
      (argument) => argument.toSource().contains('RepositoryProvider'),
    );
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    if (_isRepositoryProviderRead(node.initializer)) {
      _holders.add(node.name.lexeme);
    }
    super.visitVariableDeclaration(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final target = node.target;

    // `ref.read(fooRepositoryProvider).bar()` — the chained form. `read` and
    // `watch` themselves are not the violation, only what is called on them.
    if (_isRepositoryProviderRead(target) &&
        node.methodName.name != 'read' &&
        node.methodName.name != 'watch') {
      calls.add('${target!.toSource()}.${node.methodName.name}(…)');
    }

    // `final r = ref.read(fooRepositoryProvider); … r.bar()` — the two-step.
    if (target is SimpleIdentifier && _holders.contains(target.name)) {
      calls.add('${target.name}.${node.methodName.name}(…)');
    }

    super.visitMethodInvocation(node);
  }
}
