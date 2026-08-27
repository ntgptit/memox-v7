import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:flutter_test/flutter_test.dart';

/// The foundation surface/action APIs stay closed: no visual primitive may
/// re-enter `MxCard` or `MxActionButton` through a public constructor or
/// field.
///
/// **An allowlist, not a blocklist, and that is the point.** A blocklist of
/// `Color`, `EdgeInsets`, `double`… is evaded by one `typedef Fill = Color;`
/// in a neighbouring file — the parsed type name is `Fill` and no ban matches
/// it. The allowlist admits content and behaviour types plus the enums the
/// component itself declares; everything else fails, including the alias,
/// because an unknown name is a finding rather than a pass. Widening the list
/// is therefore an explicit edit here, reviewed as such.
///
/// Private implementation stays free: the scan reads public members only, so
/// `_MxCardSpec` holding `double elevation` and the build method holding
/// `BoxDecoration` are none of this test's business.
///
/// A structural Dart test rather than a guard regex, on the
/// `icon_ink_boundary_test.dart` precedent: a rule that needs to see
/// declarations rather than lines becomes a test the suite runs.

/// The files whose public widget APIs must stay closed. A new shared surface
/// or action component joins this list in the same change that creates it.
const List<String> kClosedApiFiles = <String>[
  'lib/shared/widgets/mx_card.dart',
  'lib/shared/widgets/mx_action_button.dart',
];

/// Types a closed component API may expose: content, behaviour, identity.
const Set<String> kAllowedTypeNames = <String>{
  'Widget',
  'VoidCallback',
  'String',
  'bool',
  'Key',
  'IconData',
};

/// One public declaration that stepped outside the allowlist.
class ApiFinding {
  const ApiFinding(this.location, this.typeName);

  final String location;
  final String typeName;

  @override
  String toString() => '$location exposes `$typeName`';
}

/// The last identifier of a (possibly prefixed) named type — `m.Color` and
/// `Color` are the same escape.
String _bareName(TypeAnnotation type) {
  if (type is NamedType) return type.name.lexeme;

  // A function type, record type or `dynamic` written structurally: report
  // its source so the failure names what it saw.
  return type.toSource();
}

/// Scans one compilation unit for public widget members whose type is not on
/// the allowlist. [label] names the unit in findings.
List<ApiFinding> scanUnit(CompilationUnit unit, String label) {
  final findings = <ApiFinding>[];

  // Enums the file itself declares are the component's own closed vocabulary
  // — `MxCardPadding`, `MxActionButtonVariant` — and are admitted by being
  // defined here rather than by name pattern, so a wrapper class smuggling a
  // primitive cannot pose as one.
  final localEnums = unit.declarations
      .whereType<EnumDeclaration>()
      .map((EnumDeclaration e) => e.namePart.typeName.lexeme)
      .toSet();

  bool isAllowed(String name) =>
      kAllowedTypeNames.contains(name) || localEnums.contains(name);

  void checkType(TypeAnnotation? type, String location) {
    if (type == null) return;
    final name = _bareName(type);
    if (isAllowed(name)) return;
    findings.add(ApiFinding(location, name));
  }

  for (final declaration in unit.declarations) {
    if (declaration is! ClassDeclaration) continue;
    final className = declaration.namePart.typeName.lexeme;
    if (className.startsWith('_')) continue;

    for (final member in declaration.body.members) {
      if (member is FieldDeclaration && !member.isStatic) {
        for (final field in member.fields.variables) {
          if (field.name.lexeme.startsWith('_')) continue;
          checkType(
            member.fields.type,
            '$label · $className.${field.name.lexeme}',
          );
        }
      }
      if (member is ConstructorDeclaration) {
        final constructorName = member.name?.lexeme ?? '(unnamed)';
        for (final parameter in member.parameters.parameters) {
          final formal = parameter is DefaultFormalParameter
              ? parameter.parameter
              : parameter;
          // `this.x` and `super.x` take their type from the field they
          // initialise, which the field pass above already judged.
          if (formal is! SimpleFormalParameter) continue;
          checkType(
            formal.type,
            '$label · $className.$constructorName(${formal.name?.lexeme})',
          );
        }
      }
    }
  }

  return findings;
}

List<ApiFinding> scanSource(String source, String label) => scanUnit(
  parseString(content: source, throwIfDiagnostics: false).unit,
  label,
);

void main() {
  test('the foundation component APIs expose no visual primitives', () {
    var scannedClasses = 0;
    final findings = <ApiFinding>[];

    for (final path in kClosedApiFiles) {
      final file = File(path);
      expect(
        file.existsSync(),
        isTrue,
        reason:
            '$path is on the closed-API list and does not exist — a '
            'renamed foundation file silently leaves the scan',
      );
      final unit = parseString(
        content: file.readAsStringSync(),
        throwIfDiagnostics: false,
      ).unit;
      scannedClasses += unit.declarations
          .whereType<ClassDeclaration>()
          .where(
            (ClassDeclaration c) => !c.namePart.typeName.lexeme.startsWith('_'),
          )
          .length;
      findings.addAll(scanUnit(unit, path));
    }

    // A scan of nothing proves nothing: zero public classes means the target
    // moved and the guard has been green on an empty set.
    expect(
      scannedClasses,
      greaterThan(0),
      reason: 'the closed-API scan found no public classes to judge',
    );
    expect(
      findings,
      isEmpty,
      reason:
          'A visual primitive re-entered a closed foundation API. Recipes '
          'own fill/edge/radius/depth/padding; a caller states meaning, not '
          'paint.\n${findings.join('\n')}',
    );
  });

  group('fault injection — the scanner fires both ways', () {
    test('a public Color field is a finding', () {
      final findings = scanSource('''
class MxProbe extends StatelessWidget {
  const MxProbe({this.color});
  final Color? color;
}
''', 'probe');
      expect(findings, hasLength(1));
      expect(findings.single.typeName, 'Color');
    });

    test('a public EdgeInsets constructor parameter is a finding', () {
      final findings = scanSource('''
class MxProbe extends StatelessWidget {
  const MxProbe({EdgeInsetsGeometry padding = EdgeInsets.zero})
      : _padding = padding;
  final EdgeInsetsGeometry _padding;
}
''', 'probe');
      expect(findings, hasLength(1));
      expect(findings.single.typeName, 'EdgeInsetsGeometry');
    });

    test('a raw double parameter is a finding', () {
      final findings = scanSource('''
class MxProbe extends StatelessWidget {
  const MxProbe({required this.elevation});
  final double elevation;
}
''', 'probe');
      expect(findings, hasLength(1));
      expect(findings.single.typeName, 'double');
    });

    test('a typedef alias does not slip past the allowlist', () {
      // The blocklist this test refuses to be: `Fill` matches no banned name,
      // and matches nothing on the allowlist either — so it fails.
      final findings = scanSource('''
typedef Fill = Color;

class MxProbe extends StatelessWidget {
  const MxProbe({this.fill});
  final Fill? fill;
}
''', 'probe');
      expect(findings, hasLength(1));
      expect(findings.single.typeName, 'Fill');
    });

    test('private implementation types pass', () {
      final findings = scanSource('''
class MxProbe extends StatelessWidget {
  const MxProbe({required this.label})
      : _style = null;
  final String label;
  final ButtonStyle? _style;

  Color get _resolved => Colors.red;
}

class _MxProbeSpec {
  const _MxProbeSpec(this.elevation, this.fill);
  final double elevation;
  final Color fill;
}
''', 'probe');
      expect(findings, isEmpty);
    });

    test('a file-local enum is admitted as the component-s own vocabulary', () {
      final findings = scanSource('''
enum MxProbeTone { danger }

class MxProbe extends StatelessWidget {
  const MxProbe({required this.tone});
  final MxProbeTone tone;
}
''', 'probe');
      expect(findings, isEmpty);
    });
  });
}
