import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

/// The AST machinery behind `usage_scan_test.dart`.
///
/// **Parsed, not grepped.** A regex over `lib/` finds `Colors.transparent` inside
/// a doc comment explaining why `Colors.*` is banned, and misses
/// `foo(color: someCondition ? a : b)` entirely. The project already learned this
/// once — `command_query_separation_test.dart` was rewritten onto the analyzer
/// for the same reason — so the audit starts where that ended up.
///
/// Parsing is unresolved (`parseString`, no element model). That is a real limit
/// and the report states it: an identifier's *declaration* is not available, so a
/// reference is classified by its written form and resolved against the theme
/// dump by name. A local variable that shadows a token name would be
/// misclassified. None exists today; the check that would catch one is the
/// coverage assertion, not this comment.

/// One colour-bearing expression, located and classified.
class ColorSite {
  const ColorSite({
    required this.file,
    required this.line,
    required this.widgetContext,
    required this.elementKind,
    required this.sourceKind,
    required this.expression,
    required this.tokenName,
  });

  /// `lib/...`, forward slashes on every platform.
  final String file;
  final int line;

  /// The enclosing class, or `<top-level>`.
  final String widgetContext;

  /// border · background · text · icon · shadow · other
  final String elementKind;

  /// theme-token · shared-constant · hardcoded-literal · Colors-material ·
  /// opacity-modified-token
  final String sourceKind;

  /// The source text, trimmed to one line so a report row stays readable.
  final String expression;

  /// The dotted token this site refers to, in the theme dump's naming, or null
  /// when the value is a literal or cannot be named.
  final String? tokenName;

  Map<String, Object?> toJson() => <String, Object?>{
    'file': file,
    'line': line,
    'widget_context': widgetContext,
    'element_kind': elementKind,
    'source_kind': sourceKind,
    'expression': expression,
    'token': tokenName,
  };
}

/// Every hand-written `.dart` file under `lib/`.
List<File> libDartFiles() => Directory('lib')
    .listSync(recursive: true)
    .whereType<File>()
    .where(
      (File file) =>
          file.path.endsWith('.dart') &&
          !file.path.endsWith('.g.dart') &&
          !file.path.endsWith('.freezed.dart') &&
          !file.path.replaceAll(r'\', '/').contains('/l10n/generated/'),
    )
    .toList();

String _relative(File file) =>
    file.path.replaceAll(r'\', '/').replaceFirst(RegExp('^.*?lib/'), 'lib/');

/// The named argument or field a colour expression sits in, mapped to the
/// model's element kinds.
///
/// Keyed on the *slot*, not on the value: `color:` inside a `BorderSide` is a
/// border and `color:` inside a `BoxDecoration` is a background, and only the
/// enclosing construct tells them apart. That is why this walks upward.
String _elementKindFor(AstNode node) {
  // `current`, re-bound each iteration, rather than testing the loop variable
  // directly: Dart does not promote a local that is assigned inside the loop, so
  // `cursor is InstanceCreationExpression` would compile to a check that grants
  // no access to the subtype's members.
  for (AstNode? cursor = node; cursor != null; cursor = cursor.parent) {
    final AstNode current = cursor;
    if (current is InstanceCreationExpression) {
      final type = current.constructorName.type.name.lexeme;
      if (type == 'BorderSide' ||
          type == 'Border' ||
          type == 'OutlineInputBorder' ||
          type == 'UnderlineInputBorder' ||
          type == 'TableBorder' ||
          type == 'Divider' ||
          type == 'VerticalDivider') {
        return 'border';
      }
      if (type == 'BoxShadow') return 'shadow';
      if (type == 'Icon') return 'icon';
      if (type == 'TextStyle' || type == 'Text') return 'text';
      if (type == 'BoxDecoration' ||
          type == 'DecoratedBox' ||
          type == 'Container' ||
          type == 'ColoredBox' ||
          type == 'Material') {
        return 'background';
      }
    }
    if (current is MethodInvocation) {
      final name = current.methodName.name;
      if (name == 'all' || name == 'symmetric' || name == 'fromBorderSide') {
        final target = current.target;
        if (target is SimpleIdentifier && target.name == 'Border') {
          return 'border';
        }
      }
    }
    if (current is NamedExpression) {
      final label = current.name.label.name;
      const borderSlots = <String>{
        'side',
        'borderSide',
        'border',
        'enabledBorder',
        'focusedBorder',
        'disabledBorder',
        'errorBorder',
        'focusedErrorBorder',
        'outlineVariant',
        'outline',
        'dividerColor',
      };
      const backgroundSlots = <String>{
        'backgroundColor',
        'fillColor',
        'indicatorColor',
        'surfaceTintColor',
        'scaffoldBackgroundColor',
        'barrierColor',
      };
      const textSlots = <String>{
        'labelStyle',
        'textStyle',
        'foregroundColor',
        'selectedLabelStyle',
      };
      if (borderSlots.contains(label)) return 'border';
      if (backgroundSlots.contains(label)) return 'background';
      if (textSlots.contains(label)) return 'text';
      if (label == 'shadowColor' || label == 'boxShadow') return 'shadow';
      if (label == 'iconColor' || label == 'iconTheme') return 'icon';
    }
  }

  return 'other';
}

/// The enclosing class name, or `<top-level>`.
String _contextFor(AstNode node) {
  for (AstNode? cursor = node; cursor != null; cursor = cursor.parent) {
    final AstNode current = cursor;
    // `namePart.typeName`, not `name`: analyzer 12 replaced the flat token with
    // a part that also carries type parameters.
    if (current is ClassDeclaration) return current.namePart.typeName.lexeme;
    if (current is ExtensionDeclaration) {
      return current.name?.lexeme ?? '<extension>';
    }
  }

  return '<top-level>';
}

String _oneLine(AstNode node) {
  final text = node.toSource().replaceAll(RegExp(r'\s+'), ' ').trim();

  return text.length <= 90 ? text : '${text.substring(0, 87)}...';
}

/// Finds every expression that produces a colour.
class _ColorVisitor extends RecursiveAstVisitor<void> {
  _ColorVisitor(this.file, this.lineOf);

  final String file;
  final int Function(int offset) lineOf;
  final List<ColorSite> sites = <ColorSite>[];

  void _record(AstNode node, String sourceKind, String? token) {
    sites.add(
      ColorSite(
        file: file,
        line: lineOf(node.offset),
        widgetContext: _contextFor(node),
        elementKind: _elementKindFor(node),
        sourceKind: sourceKind,
        expression: _oneLine(node),
        tokenName: token,
      ),
    );
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final type = node.constructorName.type.name.lexeme;
    if (type == 'Color') {
      _record(node, 'hardcoded-literal', null);
    }
    super.visitInstanceCreationExpression(node);
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    final prefix = node.prefix.name;
    final name = node.identifier.name;

    if (prefix == 'Colors') {
      _record(node, 'Colors-material', 'Colors.$name');
    } else if (prefix == 'AppColors') {
      _record(node, 'shared-constant', 'AppColors.$name');
    }
    super.visitPrefixedIdentifier(node);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    final token = _tokenPathOf(node);
    if (token != null) _record(node, 'theme-token', token);
    super.visitPropertyAccess(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final name = node.methodName.name;
    if (name == 'withValues' || name == 'withOpacity') {
      final target = node.target;
      _record(
        node,
        'opacity-modified-token',
        target == null ? null : _tokenPathOf(target),
      );
    }
    if (name == 'fromRGBO' || name == 'fromARGB') {
      final target = node.target;
      if (target is SimpleIdentifier && target.name == 'Color') {
        _record(node, 'hardcoded-literal', null);
      }
    }
    super.visitMethodInvocation(node);
  }
}

/// `context.colors.primary` → `colorScheme.primary`, and the same for the
/// semantic extension — the names the theme dump uses, so a site can be resolved
/// to a hex without a second naming scheme to keep in sync.
String? _tokenPathOf(AstNode node) {
  final text = node.toSource().replaceAll(RegExp(r'\s+'), '');

  const map = <String, String>{
    'colors.': 'colorScheme.',
    'colorScheme.': 'colorScheme.',
    'semanticColors.': 'semantic.',
    'scheme.': 'colorScheme.',
    'semantic.': 'semantic.',
  };

  for (final entry in map.entries) {
    final index = text.lastIndexOf(entry.key);
    if (index < 0) continue;
    final leaf = text.substring(index + entry.key.length);
    if (leaf.isEmpty || !RegExp(r'^[a-zA-Z]+$').hasMatch(leaf)) continue;

    return '${entry.value}$leaf';
  }

  return null;
}

/// Every colour site in `lib/`, in file then line order.
List<ColorSite> scanLib() {
  final sites = <ColorSite>[];

  for (final file in libDartFiles()) {
    final content = file.readAsStringSync();
    final parsed = parseString(content: content, throwIfDiagnostics: false);
    final lineInfo = parsed.lineInfo;
    final visitor = _ColorVisitor(
      _relative(file),
      (int offset) => lineInfo.getLocation(offset).lineNumber,
    );
    parsed.unit.accept(visitor);
    sites.addAll(visitor.sites);
  }

  sites.sort((a, b) {
    final byFile = a.file.compareTo(b.file);

    return byFile != 0 ? byFile : a.line.compareTo(b.line);
  });

  return sites;
}
