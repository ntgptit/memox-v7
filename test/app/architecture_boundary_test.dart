import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The dependency direction between `lib/features/`, `lib/app/` and `lib/core/`,
/// asserted from source.
///
/// **Why here as well as in `check_architecture.sh`.** The shell guard owns the
/// same rule and is the richer of the two, but it is not what runs on a developer's
/// machine when they type `flutter test`. A boundary that only CI notices is a
/// boundary that gets crossed locally and discovered in review, so the cheapest
/// version of it lives in the suite.
///
/// Import lines only, and deliberately so: this is a claim about the module graph,
/// which import lines are the whole of. Nothing here inspects behaviour.
void main() {
  /// Every non-generated Dart file under [folder], as repo-relative paths with
  /// forward slashes.
  List<File> dartFilesUnder(String folder) => Directory(folder)
      .listSync(recursive: true)
      .whereType<File>()
      .where((File file) {
        final path = file.path.replaceAll(r'\', '/');

        return path.endsWith('.dart') &&
            !path.endsWith('.g.dart') &&
            !path.endsWith('.freezed.dart');
      })
      .toList();

  String relative(File file) => file.path.replaceAll(r'\', '/');

  /// Import targets in [source], comments stripped first.
  ///
  /// Stripped because prose mentions paths constantly — this file's own doc
  /// comment names `lib/app/` — and a check that reads comments is a check that
  /// fails on documentation.
  List<String> importsIn(String source) {
    final withoutComments = source
        .replaceAll(RegExp(r'/\*.*?\*/', dotAll: true), '')
        .replaceAll(RegExp('//.*'), '');

    return RegExp(r"""^\s*import\s+'([^']+)'""", multiLine: true)
        .allMatches(withoutComments)
        .map((RegExpMatch match) => match.group(1)!)
        .toList();
  }

  test('no feature imports app/', () {
    // `app/` is the composition root: it may name a feature's provider and its
    // implementation, because choosing one is its job. The reverse makes a feature
    // depend on the shell it is mounted in — so it cannot be lifted out, and
    // cloning it means editing `app/` as well.
    //
    // Both halves of this were live before M4.10b. The deck feature's use-case
    // providers imported `app/di/deck_repository_provider.dart`, and two screens
    // imported `app/router/route_names.dart`. The first became a feature-owned
    // `di/` declaration bound at the root; the second moved to `core/navigation/`.
    final offenders = <String>[];

    for (final File file in dartFilesUnder('lib/features')) {
      for (final String target in importsIn(file.readAsStringSync())) {
        if (!RegExp(r'(^|/)app/').hasMatch(target)) continue;
        offenders.add('${relative(file)} -> $target');
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'A feature must not import app/. A provider the feature needs is '
          'declared in its own di/ as the domain contract and bound at the '
          'composition root; a constant both the router and a screen speak '
          'belongs in core/.\n${offenders.join('\n')}',
    );
  });

  test('no feature declares a repository implementation outside data/', () {
    // The other half of the seam. `di/` declares the *contract* and must not name
    // an implementation — the moment it does, `presentation/` can reach Drift
    // through it and AD-01 is gone without any import looking wrong.
    final offenders = <String>[];

    for (final File file in dartFilesUnder('lib/features')) {
      final path = relative(file);
      if (!path.contains('/di/')) continue;
      for (final String target in importsIn(file.readAsStringSync())) {
        if (!target.contains('/data/') && !target.contains('data/')) continue;
        offenders.add('$path -> $target');
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          "A feature's di/ declares what it needs, typed as the domain "
          'contract. What satisfies it is chosen in app/di/, which is the only '
          'place an implementation is named outside its own layer.\n'
          '${offenders.join('\n')}',
    );
  });

  test('core/ and shared/ import no feature', () {
    // Restated here because the two rules are one idea: `core/` is the base of the
    // graph and `app/` is the top. Everything in between may only look downwards.
    final offenders = <String>[];

    for (final String folder in <String>['lib/core', 'lib/shared']) {
      for (final File file in dartFilesUnder(folder)) {
        for (final String target in importsIn(file.readAsStringSync())) {
          if (!target.contains('features/')) continue;
          offenders.add('${relative(file)} -> $target');
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'core/ and shared/ are what every feature builds on. An edge back up '
          'to one makes them unusable by any other feature.\n'
          '${offenders.join('\n')}',
    );
  });

  test('the checks above actually looked at files', () {
    // The failure mode these guards are most likely to develop: a path that stops
    // matching, after which the rule passes because it inspected nothing. Six
    // suffix checks in `check_architecture.sh` did exactly that until M4.10.
    expect(dartFilesUnder('lib/features'), isNotEmpty);
    expect(dartFilesUnder('lib/core'), isNotEmpty);
    expect(
      dartFilesUnder(
        'lib/features',
      ).where((File f) => relative(f).contains('/di/')),
      isNotEmpty,
      reason: 'the di/ rule needs a di/ folder to have any effect',
    );
  });
}
