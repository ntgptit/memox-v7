import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

/// The AST plumbing shared by `command_query_separation_test.dart`.
///
/// Extracted here so the test file stays under the 400-line source limit the
/// guard enforces (`common.no_large_source_file`) — the checks are the subject
/// of that file, the scanning is machinery, and the two read better apart.
///
/// **Parsed, not matched.** These walk a real Dart AST rather than source text:
/// comments and string literals are not nodes, classes are separate objects, and
/// a return type is a type rather than a line that starts a certain way. That is
/// what a `navigateTo` in a comment, or two notifiers in one file, taught the
/// regex version at the cost of real coverage.

/// Every `.dart` file under [path], excluding generated output.
List<File> dartFilesUnder(String path) {
  final directory = Directory(path);
  if (!directory.existsSync()) return <File>[];

  return directory
      .listSync(recursive: true)
      .whereType<File>()
      .where(
        (File file) =>
            file.path.endsWith('.dart') &&
            !file.path.endsWith('.g.dart') &&
            !file.path.endsWith('.freezed.dart'),
      )
      .toList();
}

/// [file]'s path from `lib/` on, with separators normalised — so a Windows
/// backslash path and a POSIX path both reduce to the same `lib/...` string.
String relativeLibPath(File file) =>
    file.path.replaceAll(r'\', '/').replaceFirst(RegExp('^.*?lib/'), 'lib/');

/// Every class declared in [file].
///
/// `throwIfDiagnostics: false` because this parses without resolution, so an
/// unresolved import is reported as a diagnostic and is not a problem here — the
/// syntax is all these checks read. A genuine syntax error still yields no
/// declarations, which the coverage check would notice.
List<ClassDeclaration> classesIn(File file) => parseString(
  content: file.readAsStringSync(),
  throwIfDiagnostics: false,
).unit.declarations.whereType<ClassDeclaration>().toList();

/// Public plain methods on [type] — not getters, setters or operators.
///
/// The count checks are about *interactions*, and a `build`/`submit`/etc. is the
/// shape an interaction takes. Getters, setters and operators are a different
/// shape and are handled by [forbiddenSurface], which bans them outright — so
/// excluding them here is not a loophole, it is a division of labour: this counts
/// the allowed methods, that rejects the disallowed members. Before
/// `forbiddenSurface` existed, excluding them here *was* the loophole:
/// `set value(String v) {}` on a use case passed every count check because a
/// setter is not a `MethodDeclaration` the count could see.
List<String> publicMethods(ClassDeclaration type) => type.body.members
    .whereType<MethodDeclaration>()
    .where(
      (MethodDeclaration m) =>
          !m.isGetter &&
          !m.isSetter &&
          !m.isOperator &&
          !m.name.lexeme.startsWith('_'),
    )
    .map((MethodDeclaration m) => m.name.lexeme)
    .toList();

/// Every public member that is not a plain method: getters, setters, operators
/// and mutable fields.
///
/// **The getter policy, stated once and enforced here.** A use case is one
/// interaction, a command controller is `build`/`submit`/`reset`, an input-state
/// notifier is one value and one mutator, a query controller is `build`. None of
/// them is a thing you read a derived property off — the value they hold is their
/// `state`, read through Riverpod, not through a bespoke getter. So a public
/// getter is a second surface, and it is forbidden rather than "not counted as an
/// interaction". That closes the "reading a value is not a command" escape a
/// getter would otherwise be: `int get operationCount` is state under a getter's
/// syntax.
///
/// A setter and an operator are interactions under another syntax — `set value`
/// is a command, `operator ==` is behaviour — and a public mutable field is
/// mutable state exposed directly. Each returns its kind and name so a failure
/// reads `public setter: value`, not just a count that moved.
List<({String kind, String name})> forbiddenSurface(ClassDeclaration type) {
  final found = <({String kind, String name})>[];
  for (final ClassMember member in type.body.members) {
    if (member is MethodDeclaration) {
      final name = member.name.lexeme;
      if (name.startsWith('_')) continue;
      if (member.isSetter) {
        found.add((kind: 'public setter', name: name));
      } else if (member.isOperator) {
        found.add((kind: 'public operator', name: name));
      } else if (member.isGetter) {
        found.add((kind: 'public getter', name: name));
      }
    } else if (member is FieldDeclaration && !member.isStatic) {
      final variables = member.fields;
      final isMutable = !variables.isFinal && !variables.isConst;
      if (!isMutable) continue;
      for (final VariableDeclaration v in variables.variables) {
        if (v.name.lexeme.startsWith('_')) continue;
        found.add((kind: 'public mutable field', name: v.name.lexeme));
      }
    }
  }

  return found;
}

/// Whether [type] is a generated-base Riverpod notifier (`extends _$Foo`).
bool isNotifier(ClassDeclaration type) =>
    type.extendsClause?.superclass.toSource().startsWith(r'_$') ?? false;

/// The declared return type of `build`, as written.
///
/// `null` when there is no `build` or it has no annotation. Read from the type
/// node, so `SubmitState<DeckValidationProblem>` and a line that merely begins
/// with the word are not the same thing — which is what the old regex compared.
String? buildReturnType(ClassDeclaration type) => type.body.members
    .whereType<MethodDeclaration>()
    .where((MethodDeclaration m) => m.name.lexeme == 'build')
    .map((MethodDeclaration m) => m.returnType?.toSource())
    .firstOrNull;

/// Classes in files whose path contains [fragment].
List<({String path, ClassDeclaration type})> classesUnder(
  String fragment, {
  String root = 'lib/features',
}) {
  final found = <({String path, ClassDeclaration type})>[];
  for (final File file in dartFilesUnder(root)) {
    final path = relativeLibPath(file);
    if (!path.contains(fragment)) continue;
    for (final ClassDeclaration type in classesIn(file)) {
      found.add((path: path, type: type));
    }
  }

  return found;
}

/// Collects every named type written inside a class.
///
/// Type annotations, type arguments and constructor names all arrive as
/// `NamedType`, which is exactly the set a "does this class mention type X"
/// question is about. Comments and string literals are not AST nodes, so neither
/// can produce a hit.
class NamedTypeCollector extends RecursiveAstVisitor<void> {
  final Set<String> types = <String>{};

  @override
  void visitNamedType(NamedType node) {
    // The bare name, so `BuildContext?` and a qualified `widgets.BuildContext`
    // both reduce to the identifier being looked for.
    types.add(node.name.lexeme);
    super.visitNamedType(node);
  }
}
