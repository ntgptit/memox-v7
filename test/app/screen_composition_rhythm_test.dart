/// The composition grammar, held by a test rather than by prose.
///
/// `docs/design-system/v1-freeze.md` §2 leaves the composition of a business
/// screen deliberately unfrozen, and §4 says the answer to an empty cell in the
/// enforcement table is *a guard, not another report*. This file is that guard
/// for the two grammar rules the app-wide consistency review found broken in
/// more than one feature at once
/// (`docs/reviews/app-wide-screen-consistency.md`, clusters C1 and C2).
///
/// **The grammar.** `AppSpacing` is xs 4 · sm 8 · md 12 · lg 16 · xl 24 · xxl 32,
/// and `app_spacing.dart` defines `lg` as *"Standard screen padding **and the
/// gap between list items**"*. `md` means "inside a compact control"; a screen
/// that uses it as an item gap has borrowed a control's spacing for a page.
///
/// **Why an AST test and not a guard regex.** Both rules need to see structure
/// rather than lines. Rule 1 must know that a `SizedBox` is the thing a
/// `separatorBuilder` returns, not any `SizedBox` in the file. Rule 2 must know
/// that a `Padding` is the `body:` argument of an `MxContentShell` that passes
/// no `padding:` of its own — a file-level scan cannot tell that apart from the
/// two legitimate `AppSpacing.xs` gaps inside a private item widget three
/// classes further down, which is exactly the false positive a first draft of
/// this rule produced against `starter_library_screen.dart`. The precedent for
/// reaching for `package:analyzer` here is `shared_api_closure_test.dart`.
///
/// **The allowlists shrink, never grow.** Each entry is a live finding with an
/// `SC-` id in the review. A cluster PR removes entries; a feature PR that adds
/// one is adding a defect, and `the allowlists only shrink` below is the
/// mechanical half of saying so.
library;

import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:flutter_test/flutter_test.dart';

/// Files whose list separator is not yet `AppSpacing.lg`. Value is the finding.
const Map<String, String> kListItemGapAllowlist = <String, String>{
  'lib/features/card/presentation/widgets/sections/card_list_body_widget.dart':
      'SC-C2-08 — card rows at md (12); the deck list this tile is modelled on '
      'is at lg (16)',
  'lib/features/search/presentation/widgets/sections/library_search_body_widget.dart':
      'SC-C2-01 — search results at sm (8), one step below every other MxCard '
      'list in the app',
  'lib/features/progress/presentation/widgets/sections/progress_deck_list_widget.dart':
      'SC-C2-20 — progress deck rows at md (12). Found by this test, not by the '
      'review: no reviewer named it, which is the argument for the test',
};

/// Screens that pad their body a second time inside `MxContentShell`, which
/// already applies `mxScreenGutter`. Value is the finding.
const Map<String, String> kDoubleGutterAllowlist = <String, String>{
  'lib/features/study/presentation/screens/study_entry_screen.dart':
      'SC-C1-13 — content sits at a 32dp left edge instead of 16, and the '
      'compact step at 320dp becomes 28 instead of 12, inverting the rule',
  'lib/features/study/presentation/screens/study_options_screen.dart':
      'SC-C1-07 — the same second EdgeInsets.all(AppSpacing.lg)',
};

/// The one token a list separator may use.
const String kItemGap = 'lg';

class Finding {
  const Finding(this.path, this.line, this.detail);

  final String path;
  final int line;
  final String detail;

  @override
  String toString() => '$path:$line: $detail';
}

/// `AppSpacing.md` -> `md`; anything else -> the source, so a failure names it.
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

/// Unwraps the expression a one-line closure returns, so
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

/// A widget construction, whether or not the parser could tell it was one.
///
/// `parseString` does not resolve, so only an explicitly `const` or `new` call
/// arrives as an `InstanceCreationExpression`. A bare `MxContentShell(...)`,
/// `Padding(...)` or `ListView.separated(...)` is a `MethodInvocation` that
/// happens to start with a capital letter. Both shapes are the same thing to
/// these rules, and reading only the first is how the first draft of this file
/// passed every probe by finding nothing at all.
({String name, ArgumentList arguments})? _construction(Expression? node) {
  if (node is InstanceCreationExpression) {
    return (
      name: node.constructorName.type.name.lexeme,
      arguments: node.argumentList,
    );
  }
  if (node is MethodInvocation) {
    // `Padding(...)` has no target; `ListView.separated(...)` carries the type
    // as its target and the named constructor as the method.
    final Expression? target = node.target;
    return (
      name: target is SimpleIdentifier ? target.name : node.methodName.name,
      arguments: node.argumentList,
    );
  }
  return null;
}

/// Rule 1 — the gap a `separatorBuilder` returns must be [kItemGap].
class _SeparatorVisitor extends RecursiveAstVisitor<void> {
  _SeparatorVisitor(this.path, this.lineOf);

  final String path;
  final int Function(int offset) lineOf;
  final List<Finding> findings = <Finding>[];

  void _check(Expression node) {
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
    findings.add(
      Finding(
        path,
        lineOf(separator!.offset),
        'list separator is AppSpacing.$step; the item gap is '
        'AppSpacing.$kItemGap',
      ),
    );
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    _check(node);
    super.visitInstanceCreationExpression(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    _check(node);
    super.visitMethodInvocation(node);
  }
}

/// Rule 2 — `MxContentShell(body: Padding(padding: EdgeInsets.all(...)))` with
/// no `padding:` of its own pays the screen gutter twice.
class _DoubleGutterVisitor extends RecursiveAstVisitor<void> {
  _DoubleGutterVisitor(this.path, this.lineOf);

  final String path;
  final int Function(int offset) lineOf;
  final List<Finding> findings = <Finding>[];

  void _check(Expression node) {
    final call = _construction(node);
    if (call == null || call.name != 'MxContentShell') return;
    if (_namedArgument(call.arguments, 'padding') != null) return;

    final Expression? body = _namedArgument(call.arguments, 'body');
    final padded = _construction(body);
    if (padded == null || padded.name != 'Padding') return;

    final Expression? inset = _namedArgument(padded.arguments, 'padding');
    findings.add(
      Finding(
        path,
        lineOf(body!.offset),
        'body is wrapped in ${inset?.toSource() ?? 'a Padding'} while the '
        'shell already applies mxScreenGutter — pass '
        'padding: EdgeInsets.zero, or drop this Padding',
      ),
    );
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    _check(node);
    super.visitInstanceCreationExpression(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    _check(node);
    super.visitMethodInvocation(node);
  }
}

List<Finding> scanSeparators(String source, String path) {
  final parsed = parseString(content: source, throwIfDiagnostics: false);
  final visitor = _SeparatorVisitor(
    path,
    (int offset) => parsed.lineInfo.getLocation(offset).lineNumber,
  );
  parsed.unit.visitChildren(visitor);
  return visitor.findings;
}

List<Finding> scanDoubleGutter(String source, String path) {
  final parsed = parseString(content: source, throwIfDiagnostics: false);
  final visitor = _DoubleGutterVisitor(
    path,
    (int offset) => parsed.lineInfo.getLocation(offset).lineNumber,
  );
  parsed.unit.visitChildren(visitor);
  return visitor.findings;
}

/// Every `.dart` file under `lib/features/*/presentation/`, path-normalised so
/// the allowlist keys read the same on Windows and Linux.
Iterable<({String path, String source})> presentationFiles() sync* {
  final Directory features = Directory('lib/features');
  for (final FileSystemEntity feature in features.listSync()) {
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

void main() {
  group('the composition grammar', () {
    test('every list separator is the item gap, AppSpacing.$kItemGap', () {
      final unexpected = <Finding>[];
      final allowedButClean = <String>[];

      for (final file in presentationFiles()) {
        final List<Finding> findings = scanSeparators(file.source, file.path);
        final bool isAllowed = kListItemGapAllowlist.containsKey(file.path);
        if (findings.isEmpty && isAllowed) allowedButClean.add(file.path);
        if (!isAllowed) unexpected.addAll(findings);
      }

      expect(
        unexpected,
        isEmpty,
        reason:
            'a list separator off the composition grammar. Use '
            'AppSpacing.$kItemGap, or add the file to '
            'kListItemGapAllowlist with its SC- finding:\n'
            '${unexpected.join('\n')}',
      );
      expect(
        allowedButClean,
        isEmpty,
        reason:
            'these files are on kListItemGapAllowlist but no longer break the '
            'rule — the allowlist only shrinks, so delete the entries:\n'
            '${allowedButClean.join('\n')}',
      );
    });

    test('no screen pays the gutter twice', () {
      final unexpected = <Finding>[];
      final allowedButClean = <String>[];

      for (final file in presentationFiles()) {
        final List<Finding> findings = scanDoubleGutter(file.source, file.path);
        final bool isAllowed = kDoubleGutterAllowlist.containsKey(file.path);
        if (findings.isEmpty && isAllowed) allowedButClean.add(file.path);
        if (!isAllowed) unexpected.addAll(findings);
      }

      expect(
        unexpected,
        isEmpty,
        reason:
            'MxContentShell already applies mxScreenGutter. Drop the Padding, '
            'or pass padding: EdgeInsets.zero and let the scroll view own the '
            'gutter:\n${unexpected.join('\n')}',
      );
      expect(
        allowedButClean,
        isEmpty,
        reason:
            'these files are on kDoubleGutterAllowlist but no longer break the '
            'rule — the allowlist only shrinks, so delete the entries:\n'
            '${allowedButClean.join('\n')}',
      );
    });

    test('every allowlist entry names a real file', () {
      final missing = <String>[
        for (final String path in <String>[
          ...kListItemGapAllowlist.keys,
          ...kDoubleGutterAllowlist.keys,
        ])
          if (!File(path).existsSync()) path,
      ];
      expect(
        missing,
        isEmpty,
        reason:
            'an allowlist entry points at a file that no longer exists, so it '
            'is silently exempting nothing:\n${missing.join('\n')}',
      );
    });
  });

  // The rules are only worth having if they fire. A scan that returns nothing
  // looks identical to a scan that is broken, and this project has shipped a
  // guard that was green because its regex never matched.
  group('fault probes', () {
    test('a separator at md is a finding, one at lg is not', () {
      const bad = '''
Widget build(BuildContext context) => ListView.separated(
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) => const Text('x'),
      itemCount: 1,
    );
''';
      final List<Finding> found = scanSeparators(bad, 'probe.dart');
      expect(found, hasLength(1));
      expect(found.single.detail, contains('AppSpacing.md'));

      const good = '''
Widget build(BuildContext context) => ListView.separated(
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppSpacing.lg),
      itemBuilder: (context, index) => const Text('x'),
      itemCount: 1,
    );
''';
      expect(scanSeparators(good, 'probe.dart'), isEmpty);
    });

    test('a block-bodied separator is read too', () {
      const bad = '''
Widget build(BuildContext context) => ListView.separated(
      separatorBuilder: (BuildContext context, int index) {
        return const SizedBox(height: AppSpacing.sm);
      },
      itemBuilder: (context, index) => const Text('x'),
      itemCount: 1,
    );
''';
      expect(scanSeparators(bad, 'probe.dart'), hasLength(1));
    });

    test(
      'a SizedBox that is not a separator is none of this rule’s business',
      () {
        const fine = '''
Widget build(BuildContext context) => const Column(
      children: <Widget>[
        Text('title'),
        SizedBox(height: AppSpacing.xs),
        Text('subtitle'),
      ],
    );
''';
        expect(scanSeparators(fine, 'probe.dart'), isEmpty);
      },
    );

    test('a padded body under a shell that passes no padding is a finding', () {
      const bad = '''
Widget build(BuildContext context) => MxContentShell(
      title: 'x',
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Text('y'),
      ),
    );
''';
      final List<Finding> found = scanDoubleGutter(bad, 'probe.dart');
      expect(found, hasLength(1));
      expect(found.single.detail, contains('EdgeInsets.all(AppSpacing.lg)'));
    });

    test('the same body is fine once the shell hands the gutter over', () {
      const good = '''
Widget build(BuildContext context) => MxContentShell(
      title: 'x',
      padding: EdgeInsets.zero,
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Text('y'),
      ),
    );
''';
      expect(scanDoubleGutter(good, 'probe.dart'), isEmpty);
    });

    test('a Padding that is not the shell’s body is not a finding', () {
      const fine = '''
Widget build(BuildContext context) => MxContentShell(
      title: 'x',
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text('y'),
          ),
        ],
      ),
    );
''';
      expect(scanDoubleGutter(fine, 'probe.dart'), isEmpty);
    });
  });
}
