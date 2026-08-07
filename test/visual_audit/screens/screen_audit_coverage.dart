import 'dart:io';

/// MX-VIS-001, the half that spans two trees.
///
/// A production screen must have a companion strict visual audit at the mirrored
/// path, and that companion must actually audit that screen. Both halves matter:
/// the file existing is trivially satisfiable, and a file full of the right
/// calls is worthless if nothing points it at the screen.
///
/// The content checks also exist as guard rules, which read one file at a time.
/// This is the part the guard cannot express — "for each screen, somewhere else,
/// there is a file" is a question about two trees at once.

/// Folders a production screen may live in.
const List<String> productionScreenRoots = <String>[
  'lib/features/',
  'lib/app/fallback/',
];

/// Where companions live.
const String auditRoot = 'test/visual_audit/screens/';

/// One screen and the companion it is required to have.
class ScreenAuditPair {
  const ScreenAuditPair({required this.screenPath, required this.auditPath});

  final String screenPath;
  final String auditPath;

  /// `StudyPlaceholderScreen`, derived from the file name.
  String get screenClass {
    final base = screenPath.split('/').last.replaceAll('.dart', '');

    return base
        .split('_')
        .map((p) => p.isEmpty ? p : p[0].toUpperCase() + p.substring(1))
        .join();
  }
}

String _posix(String path) => path.replaceAll(r'\', '/');

/// Every production screen file, with the companion path it requires.
///
/// `lib/features/study/presentation/screens/study_placeholder_screen.dart`
/// →  `test/visual_audit/screens/features/study/screens/
///     study_placeholder_screen_visual_audit_test.dart`
List<ScreenAuditPair> discoverScreenPairs(Directory libRoot) {
  final pairs = <ScreenAuditPair>[];

  for (final entity in libRoot.listSync(recursive: true)) {
    if (entity is! File) continue;

    final path = _posix(entity.path);
    if (!path.endsWith('_screen.dart')) continue;
    if (!productionScreenRoots.any(path.startsWith)) continue;

    // Mirror the path minus `lib/`, and minus the `presentation/` segment: the
    // layer is a lib-side concern and repeating it in the test tree buys
    // nothing but depth.
    final segments = path.substring('lib/'.length).split('/')
      ..removeWhere((segment) => segment == 'presentation');
    final file = segments.removeLast().replaceAll(
      '.dart',
      '_visual_audit_test.dart',
    );

    pairs.add(
      ScreenAuditPair(
        screenPath: path,
        auditPath: '$auditRoot${segments.join('/')}/$file',
      ),
    );
  }
  pairs.sort((a, b) => a.screenPath.compareTo(b.screenPath));

  return pairs;
}

/// Companion files that audit a screen which no longer exists.
///
/// Same rule as an unused allowance: a test left behind after its subject is
/// gone reads as coverage to whoever counts the files.
List<String> orphanedAuditFiles(
  Directory auditDir,
  List<ScreenAuditPair> pairs,
) {
  if (!auditDir.existsSync()) return const <String>[];

  final expected = pairs.map((pair) => pair.auditPath).toSet();

  return <String>[
    for (final entity in auditDir.listSync(recursive: true))
      if (entity is File)
        if (_posix(entity.path).endsWith('_visual_audit_test.dart'))
          if (!expected.contains(_posix(entity.path))) _posix(entity.path),
  ];
}

/// Everything wrong with the pairing, phrased for the person who has to fix it.
List<String> screenAuditFailures(List<ScreenAuditPair> pairs) {
  final failures = <String>[];

  for (final pair in pairs) {
    final companion = File(pair.auditPath);

    if (!companion.existsSync()) {
      failures.add(
        '${pair.screenPath} has no strict visual audit. Create '
        '${pair.auditPath} calling memoxProductionScreenAuditTest with '
        '${pair.screenClass}.',
      );

      continue;
    }

    final source = companion.readAsStringSync();

    // Points at the right screen. Without this a companion can sit at the
    // correct path and audit something else entirely.
    if (!source.contains(pair.screenClass)) {
      failures.add(
        '${pair.auditPath} never mentions ${pair.screenClass}, so it is not '
        'auditing the screen it is named after.',
      );
    }

    // Strict, not exploratory. `memoxAuditTest` alone permits
    // PASS_WITH_UNRESOLVED, which is the exploratory bar.
    if (!source.contains('memoxProductionScreenAuditTest')) {
      failures.add(
        '${pair.auditPath} does not call memoxProductionScreenAuditTest. A '
        'production screen is held to AuditExpectation.complete.',
      );
    }

    if (RegExp(r'\bskip\s*:').hasMatch(source)) {
      failures.add(
        '${pair.auditPath} is skipped. A skipped audit still counts as a '
        'passing suite, so the lost coverage is invisible.',
      );
    }
  }

  return failures;
}
