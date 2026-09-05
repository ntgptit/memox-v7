/// The scanner behind `screen_composition_rhythm_test.dart`.
///
/// It lives beside the test rather than inside it for two reasons: the test
/// file was over the 400-line ceiling the code-verification guard enforces, and
/// the probes that prove the ratchet works need to drive [compareToAllowlist]
/// against synthetic sources rather than against `lib/`.
///
/// **Why an AST scan and not a guard regex.** Both rules need structure. The
/// item-gap rule must know a `SizedBox` is the thing a `separatorBuilder`
/// returns, not any `SizedBox` in the file. The gutter rule must know a
/// `Padding` is the `body:` of an `MxContentShell` that passes no `padding:` —
/// a file-level scan cannot tell that apart from the two legitimate
/// `AppSpacing.xs` gaps inside a private item widget further down the same
/// file, which is the false positive a first draft produced against
/// `starter_library_screen.dart`. Precedent: `shared_api_closure_test.dart`.
///
/// `parseString` does not resolve, so a bare `Padding(...)` arrives as a
/// `MethodInvocation` and only `const SizedBox(...)` as an
/// `InstanceCreationExpression`. Reading one shape is why an earlier draft
/// passed every probe by finding nothing at all; [_construction] reads both.
library;

import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

/// The one token a list separator may use.
const String kItemGap = 'lg';

const String kRuleItemGap = 'list-item-gap';
const String kRuleDoubleGutter = 'double-gutter';

/// One breach of the composition grammar, identified by what it is rather than
/// by where it sits.
class Violation {
  const Violation({
    required this.rule,
    required this.path,
    required this.context,
    required this.pattern,
    required this.line,
    required this.detail,
    this.ordinal = 0,
  });

  final String rule;
  final String path;

  /// The declaration chain around it — `CardListBodyWidget.build`.
  final String context;

  /// The offending source, e.g. `AppSpacing.md`.
  final String pattern;

  final int line;
  final String detail;

  /// Distinguishes two otherwise identical violations in one declaration,
  /// assigned in source order.
  final int ordinal;

  /// Deliberately without the line number: an edit above a violation must not
  /// invalidate its entry, or the ratchet becomes noise and gets loosened.
  String get signature => '$rule|$path|$context|$pattern|$ordinal';

  Violation withOrdinal(int n) => Violation(
    rule: rule,
    path: path,
    context: context,
    pattern: pattern,
    line: line,
    detail: detail,
    ordinal: n,
  );

  @override
  String toString() => '$path:$line: $detail\n    signature: $signature';
}

/// `AppSpacing.md` -> `md`; anything else -> null.
String? _spacingStep(Expression? expression) {
  if (expression is! PrefixedIdentifier) return null;
  if (expression.prefix.name != 'AppSpacing') return null;
  return expression.identifier.name;
}

Expression? _namedArgument(ArgumentList arguments, String name) {
  for (final Expression argument in arguments.arguments) {
    if (argument is NamedExpression && argument.name.label.name == name) {
      return argument.expression;
    }
  }
  return null;
}

/// Unwraps the expression a closure returns, so
/// `(context, index) => const SizedBox(...)` yields the `SizedBox`.
Expression? _closureResult(Expression? expression) {
  if (expression is! FunctionExpression) return null;
  final FunctionBody body = expression.body;
  if (body is ExpressionFunctionBody) return body.expression;
  if (body is BlockFunctionBody) {
    for (final Statement statement in body.block.statements) {
      if (statement is ReturnStatement) return statement.expression;
    }
  }
  return null;
}

/// A widget construction, whether or not the unresolved parser could tell.
({String name, ArgumentList arguments})? _construction(Expression? node) {
  if (node is InstanceCreationExpression) {
    return (
      name: node.constructorName.type.name.lexeme,
      arguments: node.argumentList,
    );
  }
  if (node is MethodInvocation) {
    final Expression? target = node.target;
    return (
      name: target is SimpleIdentifier ? target.name : node.methodName.name,
      arguments: node.argumentList,
    );
  }
  return null;
}

/// The declaration chain around [node], outermost first — `MyWidget.build`.
///
/// This is what makes a signature specific enough to name *one* violation
/// without naming a line: two separators in two different widgets in one file
/// are two signatures, and an edit between them moves neither.
String enclosingContext(AstNode node) {
  final parts = <String>[];
  for (AstNode? at = node; at != null; at = at.parent) {
    if (at is MethodDeclaration) {
      parts.add(at.name.lexeme);
    } else if (at is FunctionDeclaration) {
      parts.add(at.name.lexeme);
    } else if (at is ClassDeclaration) {
      // Analyzer 12 moved a class's name behind `namePart`, to make room for
      // primary constructors; the other declaration kinds still expose a bare
      // `name` token. `shared_api_closure_test.dart` reads enums the same way.
      parts.add(at.namePart.typeName.lexeme);
    } else if (at is MixinDeclaration) {
      parts.add(at.name.lexeme);
    } else if (at is ExtensionDeclaration && at.name != null) {
      parts.add(at.name!.lexeme);
    }
  }
  if (parts.isEmpty) return '<top-level>';
  return parts.reversed.join('.');
}

class _RhythmVisitor extends RecursiveAstVisitor<void> {
  _RhythmVisitor(this.path, this.lineOf);

  final String path;
  final int Function(int offset) lineOf;
  final List<Violation> found = <Violation>[];

  void _checkSeparator(Expression node) {
    final call = _construction(node);
    if (call == null) return;
    final Expression? builder = _namedArgument(
      call.arguments,
      'separatorBuilder',
    );
    final Expression? separator = _closureResult(builder);
    final made = _construction(separator);
    if (made == null || made.name != 'SizedBox') return;

    final Expression? height = _namedArgument(made.arguments, 'height');
    final String step = _spacingStep(height) ?? height?.toSource() ?? '(none)';
    if (step == kItemGap) return;
    found.add(
      Violation(
        rule: kRuleItemGap,
        path: path,
        context: enclosingContext(separator!),
        pattern: 'AppSpacing.$step',
        line: lineOf(separator.offset),
        detail:
            'list separator is AppSpacing.$step; the item gap is '
            'AppSpacing.$kItemGap',
      ),
    );
  }

  void _checkGutter(Expression node) {
    final call = _construction(node);
    if (call == null || call.name != 'MxContentShell') return;
    if (_namedArgument(call.arguments, 'padding') != null) return;

    final Expression? body = _namedArgument(call.arguments, 'body');
    final padded = _construction(body);
    if (padded == null || padded.name != 'Padding') return;

    final Expression? inset = _namedArgument(padded.arguments, 'padding');
    final String inner = inset == null
        ? 'Padding'
        : inset.toSource().replaceFirst('const ', '');
    found.add(
      Violation(
        rule: kRuleDoubleGutter,
        path: path,
        context: enclosingContext(body!),
        pattern: inner,
        line: lineOf(body.offset),
        detail:
            'body is wrapped in $inner while the shell already applies '
            'mxScreenGutter — pass padding: EdgeInsets.zero, or drop this '
            'Padding',
      ),
    );
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    _checkSeparator(node);
    _checkGutter(node);
    super.visitInstanceCreationExpression(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    _checkSeparator(node);
    _checkGutter(node);
    super.visitMethodInvocation(node);
  }
}

/// Assigns each violation its ordinal within its own signature group, in source
/// order, so two identical violations in one declaration stay distinguishable.
List<Violation> _numbered(List<Violation> raw) {
  final seen = <String, int>{};
  final out = <Violation>[];
  for (final Violation v in raw) {
    final String key = '${v.rule}|${v.path}|${v.context}|${v.pattern}';
    final int n = seen[key] ?? 0;
    seen[key] = n + 1;
    out.add(v.withOrdinal(n));
  }
  return out;
}

List<Violation> scanSource(String source, String path) {
  final parsed = parseString(content: source, throwIfDiagnostics: false);
  final visitor = _RhythmVisitor(
    path,
    (int offset) => parsed.lineInfo.getLocation(offset).lineNumber,
  );
  parsed.unit.visitChildren(visitor);
  visitor.found.sort((Violation a, Violation b) => a.line.compareTo(b.line));
  return _numbered(visitor.found);
}

/// Every `.dart` file under `lib/features/*/presentation/`, path-normalised so
/// a signature reads the same on Windows and Linux.
Iterable<({String path, String source})> presentationFiles() sync* {
  for (final FileSystemEntity feature in Directory('lib/features').listSync()) {
    final Directory presentation = Directory('${feature.path}/presentation');
    if (!presentation.existsSync()) continue;
    for (final FileSystemEntity entity in presentation.listSync(
      recursive: true,
    )) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      yield (
        path: entity.path.replaceAll(r'\', '/'),
        source: entity.readAsStringSync(),
      );
    }
  }
}

Map<String, Violation> scanRepository() {
  final out = <String, Violation>{};
  for (final file in presentationFiles()) {
    for (final Violation v in scanSource(file.source, file.path)) {
      out[v.signature] = v;
    }
  }
  return out;
}

/// The comparison the ratchet makes, isolated so the probes can drive it
/// against synthetic states instead of against `lib/`.
({List<String> unexpected, List<String> stale}) compareToAllowlist(
  Iterable<String> live,
  Set<String> allow,
) {
  final List<String> seen = live.toList();
  return (
    unexpected: seen.where((String s) => !allow.contains(s)).toList(),
    stale: allow.where((String s) => !seen.contains(s)).toList(),
  );
}
