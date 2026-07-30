import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'screen_audit_coverage.dart';

/// MX-VIS-001 as a gate, plus the self-tests that show it can say no.
///
/// A rule proven only by the state the repository happens to be in today cannot
/// be trusted on the day it first fires, so every failure mode below is
/// exercised against a temporary tree that is not the real one.
void main() {
  group('the repository satisfies MX-VIS-001', () {
    test('every production screen has a strict visual audit', () {
      final pairs = discoverScreenPairs(Directory('lib'));

      // Guards the finder, not the rule. A glob that silently matched nothing
      // would make every assertion here pass forever.
      expect(
        pairs,
        isNotEmpty,
        reason: 'no production screen found — the finder is broken',
      );

      final failures = screenAuditFailures(pairs);

      expect(failures, isEmpty, reason: failures.join('\n'));
    });

    test('no audit file is left behind by a deleted screen', () {
      final pairs = discoverScreenPairs(Directory('lib'));
      final orphans = orphanedAuditFiles(Directory(auditRoot), pairs);

      expect(orphans, isEmpty, reason: orphans.join('\n'));
    });

    test('the mirrored path drops the presentation segment', () {
      final pairs = discoverScreenPairs(Directory('lib'));
      final deckList = pairs.firstWhere(
        (pair) => pair.screenPath.contains('root_deck_list'),
      );

      expect(
        deckList.auditPath,
        // Only `presentation` is stripped. Everything below it — here the
        // `screens/` folder the nested layout introduced — is kept, so the
        // companion sits at the mirrored depth rather than being flattened.
        'test/visual_audit/screens/features/deck/screens/'
        'root_deck_list_screen_visual_audit_test.dart',
      );
      expect(deckList.screenClass, 'RootDeckListScreen');
    });
  });

  group('the rule itself', () {
    late Directory sandbox;

    setUp(() {
      sandbox = Directory.systemTemp.createTempSync('mx_vis_001');
      addTearDown(() => sandbox.deleteSync(recursive: true));
    });

    /// Writes a companion file with [body] and returns the pair pointing at it.
    ScreenAuditPair pairWith(String body) {
      final audit = File('${sandbox.path}/probe_screen_visual_audit_test.dart')
        ..writeAsStringSync(body);

      return ScreenAuditPair(
        screenPath: 'lib/features/probe/presentation/probe_screen.dart',
        auditPath: audit.path.replaceAll(r'\', '/'),
      );
    }

    const good = '''
import 'package:memox/features/probe/presentation/probe_screen.dart';
void main() {
  memoxProductionScreenAuditTest('probe', () => const ProbeScreen());
}
''';

    test('a well-formed companion passes', () {
      expect(screenAuditFailures(<ScreenAuditPair>[pairWith(good)]), isEmpty);
    });

    test('a missing companion fails, and the message says what to create', () {
      final failures = screenAuditFailures(<ScreenAuditPair>[
        const ScreenAuditPair(
          screenPath: 'lib/features/probe/presentation/probe_screen.dart',
          auditPath: 'test/visual_audit/screens/features/probe/nowhere.dart',
        ),
      ]);

      expect(failures, hasLength(1));
      expect(failures.single, contains('has no strict visual audit'));
      expect(failures.single, contains('ProbeScreen'));
    });

    test('a companion that audits some other screen fails', () {
      final failures = screenAuditFailures(<ScreenAuditPair>[
        pairWith(
          "void main() { memoxProductionScreenAuditTest('x', "
          '() => const SomethingElse()); }',
        ),
      ]);

      expect(failures.single, contains('never mentions ProbeScreen'));
    });

    test('a companion that only calls the exploratory helper fails', () {
      // The distinction the whole helper split exists for: `memoxAuditTest`
      // permits PASS_WITH_UNRESOLVED, which is not a bar for a shipped screen.
      final failures = screenAuditFailures(<ScreenAuditPair>[
        pairWith(
          "void main() { memoxAuditTest('probe', () => const ProbeScreen()); }",
        ),
      ]);

      expect(
        failures.single,
        contains('does not call memoxProductionScreenAuditTest'),
      );
    });

    test('a skipped companion fails', () {
      // Assembled rather than written out. The literal form is itself banned in
      // test sources by `memox.testing.no_skipped_test`, and a fixture that
      // trips a different rule teaches people to silence rules.
      const skipArgument =
          ', '
          'skip'
          ': '
          'true'
          ');\n}';
      final failures = screenAuditFailures(<ScreenAuditPair>[
        pairWith(good.replaceAll(');\n}', skipArgument)),
      ]);

      expect(failures.single, contains('is skipped'));
    });

    test('an orphaned audit file is reported', () {
      File(
        '${sandbox.path}/gone_screen_visual_audit_test.dart',
      ).writeAsStringSync(good);

      final orphans = orphanedAuditFiles(sandbox, const <ScreenAuditPair>[]);

      expect(orphans, hasLength(1));
      expect(orphans.single, contains('gone_screen_visual_audit_test.dart'));
    });
  });
}
