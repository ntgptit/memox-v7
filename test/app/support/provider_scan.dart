/// Finds Riverpod providers by **shape**, for `provider_convention_test.dart`.
///
/// **The regex it replaces could only see half of them.** It matched
/// `@riverpod` or `@Riverpod(...)` immediately followed by a line beginning
/// `Stream<` or `Future<` — which is the *function* provider shape. A class
/// provider's next line is always `class Foo extends _$Foo {`, and its async
/// `build()` deeper inside carries only `@override`, so neither the class nor
/// the method was ever a match target. Class-shaped async providers were not
/// failing the rule; they were outside its sample space entirely.
///
/// That was not an edge case. Nine of the repo's async providers are
/// class-shaped, and four of them had been written with no retry policy at all
/// while the test stayed green — including the one the final corrective pass
/// was opened to fix.
///
/// **So the discovery is structural.** `parseString` does not resolve, but it
/// does not need to: an annotation's name, a function's return type and a
/// method named `build` are all syntax. [scanProviders] is exported separately
/// from the test so the fault-injection probes can run it over synthetic
/// sources rather than only over `lib/`.
library;

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';

/// One provider declaration, as the convention cares about it.
class ProviderDeclaration {
  const ProviderDeclaration({
    required this.name,
    required this.path,
    required this.annotation,
    required this.isAsync,
    required this.isClassShaped,
  });

  final String name;
  final String path;

  /// The annotation source, e.g. `@riverpod` or
  /// `@Riverpod(retry: noAutomaticRetry)`.
  final String annotation;

  /// Whether the provider's own value is a `Future` or a `Stream` — for a
  /// class, whether its `build` returns one.
  final bool isAsync;

  /// `@riverpod class Foo extends _$Foo` rather than `@riverpod Foo foo(Ref)`.
  final bool isClassShaped;

  bool get disablesRetry => annotation.contains('noAutomaticRetry');

  @override
  String toString() =>
      '$path: $annotation ${isClassShaped ? 'class' : 'fn'} '
      '$name';
}

/// Every Riverpod provider declared in [source].
///
/// [path] is carried through only so a failure can name the file.
List<ProviderDeclaration> scanProviders(String source, {required String path}) {
  final CompilationUnit unit = parseString(
    content: source,
    throwIfDiagnostics: false,
  ).unit;
  final found = <ProviderDeclaration>[];

  for (final declaration in unit.declarations) {
    final String? annotation = _riverpodAnnotation(declaration);
    if (annotation == null) continue;

    if (declaration is FunctionDeclaration) {
      found.add(
        ProviderDeclaration(
          name: declaration.name.lexeme,
          path: path,
          annotation: annotation,
          isAsync: _isAsyncType(declaration.returnType),
          isClassShaped: false,
        ),
      );
      continue;
    }

    if (declaration is ClassDeclaration) {
      found.add(
        ProviderDeclaration(
          // `namePart.typeName` rather than `name`: analyzer 12 moved it to
          // make room for primary constructors. Reading the old shape is a
          // compile error rather than a silent miss, which is the good failure.
          name: declaration.namePart.typeName.lexeme,
          path: path,
          annotation: annotation,
          isAsync: _isAsyncType(_buildReturnType(declaration)),
          isClassShaped: true,
        ),
      );
    }
  }

  return found;
}

/// The `@riverpod` / `@Riverpod(...)` on [declaration], as source.
String? _riverpodAnnotation(CompilationUnitMember declaration) {
  for (final Annotation annotation in declaration.metadata) {
    final String name = annotation.name.name;
    if (name != 'riverpod' && name != 'Riverpod') continue;

    return annotation.toSource();
  }

  return null;
}

/// The return type of a class provider's `build`, or null when it has none.
///
/// A generated provider always has one; a class without it is not a provider
/// this convention can classify, and saying so by returning null keeps it out
/// of the async bucket rather than guessing.
TypeAnnotation? _buildReturnType(ClassDeclaration declaration) {
  // `body.members`, not `members`: a class's body is its own node in
  // analyzer 12.
  for (final ClassMember member in declaration.body.members) {
    if (member is! MethodDeclaration) continue;
    if (member.name.lexeme != 'build') continue;

    return member.returnType;
  }

  return null;
}

/// Whether [type] is a `Future<...>` or `Stream<...>`.
bool _isAsyncType(TypeAnnotation? type) {
  if (type is! NamedType) return false;
  final String name = type.name.lexeme;

  return name == 'Future' || name == 'Stream';
}
