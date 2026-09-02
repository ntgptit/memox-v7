@Tags(<String>['design-audit'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'audit_report.dart';
import 'audit_role_steps.dart';
import 'audit_scan_steps.dart';
import 'audit_theme_steps.dart';
import 'color_usage_scan.dart';

/// The colour-system audit, run end to end.
///
/// **One file on purpose.** `flutter test` runs test *files* concurrently in
/// separate isolates, so an audit split across four of them can render its
/// report from JSON another isolate is still writing — or from the previous
/// run's. Tests inside one file run in order, and that ordering is the only
/// thing making the last step correct. The steps themselves are libraries
/// (`audit_theme_steps.dart`, `audit_scan_steps.dart`, `audit_report.dart`) so
/// this file stays a schedule rather than an implementation.
///
/// It writes files and asserts almost nothing. An audit that failed would stop
/// before producing the report it exists to produce; the judgements live in
/// `design_audit/color_system_report.md`, where a human can disagree with them.
/// The assertions below guard the **harness** — a scan that found nothing, or a
/// token dump missing half the roles, would make every later step under-report
/// while looking clean.
void main() {
  late Map<String, Object?> tokens;
  late Map<String, Object?> perceptual;
  late Map<String, Object?> inventory;
  late Map<String, Object?> violations;
  late Map<String, Object?> roles;

  String encode(Object? value) =>
      const JsonEncoder.withIndent('  ').convert(value);

  void save(String name, Object? data) =>
      File('design_audit/$name').writeAsStringSync(encode(data));

  setUpAll(() => Directory('design_audit').createSync(recursive: true));

  test('step 1 — dumps every theme colour and its distance from the seed', () {
    tokens = buildTokenDump();
    save('tokens_current.json', tokens);

    expect(
      tokens['seedHypotheses'],
      isNotNull,
      reason: 'the dump is missing its seed analysis',
    );
    expect(
      (tokens['light']! as Map<String, Object?>),
      // 54 until M99.47, which added the twelve `*Fixed` roles to the theme
      // and therefore to the dump; 66 until M100.17, which retired the one
      // entry that was never a role; 65 until M100.19, which retired the ring
      // token once `primary` could carry the role itself; 64 until M100.21,
      // which gave the extension eight status-container fields; 72 until
      // M100.22 retired `secondaryAction`, the last token standing in for a
      // canonical role. The number is pinned rather than derived for exactly
      // the reason the message below states, so it moves only when someone
      // decided it should.
      hasLength(71),
      reason:
          'a role added to Material and not listed in auditTokensOf is '
          'invisible to every later step',
    );
  });

  test('step 2 — inventories every colour site in lib/', () {
    inventory = buildUsageInventory();
    save('usage_inventory.json', inventory);

    // Coverage, not conformance: a scan that found nothing would pass every
    // violation check and read as a clean bill of health.
    expect(inventory['totalSites'], greaterThan(100));
    expect(libDartFiles(), hasLength(greaterThan(100)));
  });

  test('step 3 — classifies scope and flags violations', () {
    violations = buildViolations();
    save('violations.json', violations);

    expect(violations['byCode'], isNotNull);
  });

  test('step 4 — computes the perceptual checks', () {
    perceptual = buildPerceptualChecks();
    save('perceptual_checks.json', perceptual);

    expect(perceptual['light'], isNotNull);
    expect(perceptual['dark'], isNotNull);
  });

  test('step 4b — checks every role for a generator-derived token set', () {
    roles = buildRoleFamilies();
    save('role_families.json', roles);

    expect(roles['roles'], isNotNull);
  });

  test('steps 5 and 6 — writes the migration map and the report', () {
    // Reads the maps the steps above returned, not the files they wrote. The
    // files are the deliverable; the data is the source.
    File('design_audit/color_system_report.md').writeAsStringSync(
      buildReportMarkdown(
        inventory: inventory,
        violations: violations,
        perceptual: perceptual,
        roles: roles,
      ),
    );
    File(
      'design_audit/migration_map.md',
    ).writeAsStringSync(buildMigrationMarkdown(violations: violations));

    expect(File('design_audit/color_system_report.md').existsSync(), isTrue);
    expect(File('design_audit/migration_map.md').existsSync(), isTrue);
  });
}
