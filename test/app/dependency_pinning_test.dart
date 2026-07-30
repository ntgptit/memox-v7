import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Every dependency states a version, and `any` needs a reason.
///
/// `flutter_riverpod`, `riverpod_annotation` and `riverpod_generator` were all
/// `any`, which is not a small imprecision when the whole state layer is codegen
/// against a version-specific contract: the generated `$Notifier` base,
/// `@Riverpod(retry:)`, `Notifier.listenSelf`, and `noAutomaticRetry` — which
/// exists only because Riverpod 3 retries a failed provider ten times with
/// backoff. A resolver free to take the next major would change runtime behaviour
/// with no code change and no review, on whichever machine hit a cold cache first.
///
/// `pubspec.lock` is committed, so in practice everyone gets the same versions
/// until somebody runs `pub upgrade`. This check is about that day.
void main() {
  /// `pubspec.yaml` with comments removed, so the prose above a constraint cannot
  /// be mistaken for one — the same reason the AST guard stopped reading text.
  final pubspec = File(
    'pubspec.yaml',
  ).readAsLinesSync().map((String line) => line.split('#').first).join('\n');

  /// Constraint for [package], or `null` when it is not declared.
  ///
  /// Matched at two-space indentation only, which is where a dependency sits;
  /// deeper indentation belongs to an `sdk:`/`path:` block.
  String? constraintFor(String package) => RegExp(
    '^  $package:(.*)\$',
    multiLine: true,
  ).firstMatch(pubspec)?.group(1)?.trim();

  /// The versions in `pubspec.lock`, so a constraint can be compared against what
  /// the resolver actually chose rather than against a number typed by hand.
  Map<String, String> lockedVersions() {
    final versions = <String, String>{};
    String? current;
    for (final String line in File('pubspec.lock').readAsLinesSync()) {
      final package = RegExp(r'^  ([a-z0-9_]+):$').firstMatch(line);
      if (package != null) {
        current = package.group(1);
        continue;
      }
      final version = RegExp(r'^    version: "(.+)"$').firstMatch(line);
      if (version == null || current == null) continue;
      versions[current] = version.group(1)!;
      current = null;
    }

    return versions;
  }

  const riverpodPackages = <String>[
    'flutter_riverpod',
    'riverpod_annotation',
    'riverpod_generator',
  ];

  test('every Riverpod package pins a major', () {
    final offenders = <String>[];

    for (final String package in riverpodPackages) {
      final constraint = constraintFor(package);
      expect(constraint, isNotNull, reason: '$package is not declared');
      if (constraint == 'any' || constraint!.isEmpty) {
        offenders.add('$package: $constraint');
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'The state layer is generated against a specific Riverpod major. An '
          'unpinned one lets the next major arrive as a resolution result '
          'rather than as a decision.\n${offenders.join('\n')}',
    );
  });

  test('each pin is a caret bound on the major actually resolved', () {
    // **Form, not exact version.** A constraint that names a version pub cannot
    // satisfy is caught by pub itself — version solving fails and nothing runs, so
    // a test for it would never get the chance. What resolves happily and is still
    // wrong is a range with no upper bound: `>=3.0.0` takes 4.x on the next
    // upgrade, which is the whole problem `any` had, written to look deliberate.
    //
    // Caret form also means the major is asserted against the lock rather than
    // against a number typed here, and a patch bump does not force a pubspec edit.
    final locked = lockedVersions();
    final mismatches = <String>[];

    for (final String package in riverpodPackages) {
      final constraint = constraintFor(package)!;
      final resolved = locked[package];
      expect(resolved, isNotNull, reason: '$package missing from pubspec.lock');

      final caret = RegExp(r'^\^(\d+)\.\d+\.\d').firstMatch(constraint);
      if (caret == null) {
        mismatches.add(
          '$package: "$constraint" is not a caret pin — it permits a major '
          'the code was never compiled against',
        );
        continue;
      }
      final lockedMajor = resolved!.split('.').first;
      if (caret.group(1) == lockedMajor) continue;
      mismatches.add(
        '$package: pubspec pins major ${caret.group(1)}, lock resolved $resolved',
      );
    }

    expect(
      mismatches,
      isEmpty,
      reason:
          'A pin is only meaningful if it bounds the major in use.\n'
          '${mismatches.join('\n')}',
    );
  });

  test('the two Riverpod majors are the pair that go together', () {
    // `riverpod_annotation` 4 is the annotation set for `flutter_riverpod` 3, which
    // looks like a mistake often enough to be worth stating. If either moves, both
    // and `riverpod_generator` move together.
    final locked = lockedVersions();

    expect(locked['flutter_riverpod'], startsWith('3.'));
    expect(locked['riverpod_annotation'], startsWith('4.'));
    expect(locked['riverpod_generator'], startsWith('4.'));
  });

  test('an unconstrained dependency says why in a comment', () {
    // `intl: any` is deliberate: `flutter_localizations` pins it to an exact
    // version and repeating that by hand is a recurring resolution conflict. That
    // is a reason, and it is written above the line. This check is that the
    // exception stays explained rather than spreading.
    final lines = File('pubspec.yaml').readAsLinesSync();
    final unexplained = <String>[];

    for (var i = 0; i < lines.length; i++) {
      final match = RegExp(r'^  ([a-z0-9_]+):\s*any\s*$').firstMatch(lines[i]);
      if (match == null) continue;
      // A reason is a comment block immediately above the line.
      final hasReason = i > 0 && lines[i - 1].trimLeft().startsWith('#');
      if (hasReason) continue;
      unexplained.add('line ${i + 1}: ${match.group(1)}');
    }

    expect(
      unexplained,
      isEmpty,
      reason:
          '`any` is sometimes right — but only with the reason next to it, or '
          'the next person reads it as an oversight and pins it wrongly.\n'
          '${unexplained.join('\n')}',
    );
  });

  test('this check read a real pubspec', () {
    // The zero-scope guard. Every assertion above is driven by a regex over a
    // file; a rename or a formatting change that stops the patterns matching would
    // make all four pass on nothing.
    expect(pubspec, contains('name: memox'));
    expect(lockedVersions(), isNotEmpty);
    expect(
      lockedVersions().length,
      greaterThan(50),
      reason: 'the lock parser found almost nothing — it has stopped matching',
    );
    for (final String package in riverpodPackages) {
      expect(
        constraintFor(package),
        isNotNull,
        reason: 'the constraint parser found no $package',
      );
    }
  });
}
