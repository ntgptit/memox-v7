import 'dart:io';

import 'audited_screens.dart';

/// Finds the screens `lib/` actually contains, and compares them to the registry.
///
/// Kept as plain functions with explicit inputs so the rules can be tested on
/// data that does not exist on disk. A gate whose logic can only be exercised by
/// the one situation the repository happens to be in is a gate nobody can prove
/// works — and this one has to keep working on the day it first says no.

/// Folders a screen may live in.
///
/// A screen anywhere else belongs to no feature and no app shell — both are
/// decisions worth making on purpose rather than by where a file landed.
const List<String> screenFolders = <String>[
  'lib/features/', // .../<feature>/presentation/
  'lib/app/fallback/',
];

/// Screen files sitting outside [screenFolders].
///
/// Lives here rather than in the guard on purpose. The guard reads one file at
/// a time and would have to express this as "this set of files must be empty",
/// which it cannot tell apart from a rule whose scope has silently stopped
/// matching — it reports `rule_without_targets` forever, and silencing that
/// diagnostic is how three dead rules survived in this repository already.
List<String> misplacedScreenFiles(Directory libRoot) {
  return <String>[
    for (final path in _screenFilePaths(libRoot))
      if (!screenFolders.any(path.startsWith)) path,
  ];
}

List<String> _screenFilePaths(Directory libRoot) {
  const suffix = '_screen.dart';

  return <String>[
    for (final entity in libRoot.listSync(recursive: true))
      if (entity is File)
        // Windows hands back backslashes; every comparison below is written in
        // forward slashes, so normalise once at the boundary rather than
        // letting the separator leak into `screenFolders`.
        if (_posix(entity.path).endsWith(suffix)) _posix(entity.path),
  ];
}

String _posix(String path) => path.replaceAll(r'\', '/');

/// Every screen class `lib/` declares, derived from file names.
///
/// The name comes from the file rather than from parsing Dart: the project
/// already forces `*_screen.dart` under `presentation/` and forces snake_case,
/// so `route_not_found_screen.dart` can only be `RouteNotFoundScreen`. Parsing
/// would add a Dart grammar to a check whose whole value is being obvious.
List<String> discoverScreenClasses(Directory libRoot) {
  final names = <String>[
    for (final path in _screenFilePaths(libRoot))
      _classNameOf(path.split('/').last),
  ];
  names.sort();

  return names;
}

String _classNameOf(String fileName) {
  final base = fileName.substring(0, fileName.length - '.dart'.length);

  return base
      .split('_')
      .map(
        (part) =>
            part.isEmpty ? part : part[0].toUpperCase() + part.substring(1),
      )
      .join();
}

/// What is wrong with the registry, in the words the reader needs.
///
/// Empty means the registry describes `lib/` exactly.
List<String> screenCoverageFailures({
  required List<String> screensInLib,
  required List<String> auditedNames,
  required List<PendingAudit> pending,
}) {
  final failures = <String>[];
  final pendingNames = pending.map((entry) => entry.name).toSet();
  final audited = auditedNames.toSet();

  for (final screen in screensInLib) {
    if (audited.contains(screen)) continue;
    if (pendingNames.contains(screen)) continue;

    failures.add(
      '$screen has no entry in auditedScreens. Add one, or add a PendingAudit '
      'with a rationale and the WBS task that will close it.',
    );
  }

  for (final entry in pending) {
    if (screensInLib.contains(entry.name)) continue;

    failures.add(
      '${entry.name} is deferred by a PendingAudit but no longer exists in '
      'lib/. Remove the entry — a permission for a screen nobody can find '
      'reads as coverage.',
    );
  }

  for (final entry in pending) {
    if (!audited.contains(entry.name)) continue;

    failures.add(
      '${entry.name} is both audited and deferred. One of the two is a leftover, '
      'and whichever it is, the registry currently claims two different things.',
    );
  }

  return failures;
}
