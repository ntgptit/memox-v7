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

  test('presentation/widgets holds only the four buckets, one level deep', () {
    // AD-15. A feature's widgets sit in exactly one of four buckets —
    // sections/, items/, overlays/, support/ — and nowhere else: not directly
    // under widgets/, not in a bucket someone invents, not nested deeper. The
    // point of fixing the list is that every feature answers "where does this
    // widget live" the same way, so a cloned feature inherits a map instead of
    // a habit.
    //
    // This test owns the full shape; the guard's two `file_name` rules are the
    // second net and deliberately cover less (fnmatch cannot see nesting depth
    // inside a valid bucket). Change the bucket list in AD-15 first, then here,
    // then in `memox-architecture-rules.yaml` — three sites, named there.
    const allowedBuckets = <String>{'sections', 'items', 'overlays', 'support'};
    final offenders = <String>[];

    for (final File file in dartFilesUnder('lib/features')) {
      final path = relative(file);
      final match = RegExp(r'/presentation/widgets/(.*)$').firstMatch(path);
      if (match == null) continue;

      final below = match.group(1)!.split('/');
      // [file.dart] — sitting directly in widgets/, where nothing may.
      if (below.length == 1) {
        offenders.add('$path — directly under widgets/, pick a bucket');
        continue;
      }
      // [bucket, file.dart] — the only legal shape, and only the four names.
      if (!allowedBuckets.contains(below.first)) {
        offenders.add(
          '$path — "${below.first}" is not a bucket '
          '(${allowedBuckets.join(', ')})',
        );
        continue;
      }
      if (below.length > 2) {
        offenders.add('$path — nested deeper than one bucket level');
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          "A feature's widgets sit in exactly one of four buckets, one level "
          'deep: sections/ (bands the screen composes), items/ (the repeated '
          'row and its parts), overlays/ (sheets, dialogs, forms), support/ '
          '(presentation mapping used across buckets). AD-15 is the contract; '
          'a fifth bucket is an AD change, not a new folder.\n'
          '${offenders.join('\n')}',
    );
  });

  test('domain/, data/ and presentation/ hold only their buckets', () {
    // AD-12, and the same shape as the widget rule above — for the same reason.
    //
    // **What this catches is a feature the other rules cannot see at all.**
    // `check_architecture.sh` selects files by path fragment: `/domain/entities/`,
    // `/data/datasources/`. A feature that never made those folders matches zero
    // of them, so every suffix rule passes without inspecting anything, and the
    // app-wide scope counters at the bottom of that script stay non-zero because
    // one correctly-laid-out feature satisfies them alone. The feature is not
    // compliant; it is invisible. That is the defect class the script's own
    // comment describes at its `check_suffix` block — six checks matching zero
    // files, reading as coverage — reintroduced through a different door.
    //
    // Bucket lists come from AD-12 and the folder table in `CLAUDE.md`. A fifth
    // name is an AD change, not a new folder.
    const buckets = <String, Set<String>>{
      'domain': <String>{
        'entities',
        'repositories',
        'models',
        'usecases',
        'failures',
      },
      'data': <String>{'repositories', 'mappers', 'datasources', 'models'},
      'presentation': <String>{
        'screens',
        'controllers',
        'states',
        'widgets',
        'providers',
      },
    };
    // `presentation/widgets/` is the one bucket that legally nests one level
    // further, because AD-15 divides it again. The depth inside it belongs to
    // the widget-bucket test above — checking it here too would report the same
    // file twice with two different explanations.
    const nestsFurther = <String>{'widgets'};
    final offenders = <String>[];

    for (final File file in dartFilesUnder('lib/features')) {
      final path = relative(file);
      for (final MapEntry<String, Set<String>> layer in buckets.entries) {
        final match = RegExp('/${layer.key}/(.*)').firstMatch(path);
        if (match == null) continue;

        final below = match.group(1)!.split('/');
        if (below.length == 1) {
          offenders.add(
            '$path — directly under ${layer.key}/, pick a bucket '
            '(${layer.value.join(', ')})',
          );
          continue;
        }
        if (!layer.value.contains(below.first)) {
          offenders.add(
            '$path — "${below.first}" is not a ${layer.key}/ bucket '
            '(${layer.value.join(', ')})',
          );
          continue;
        }
        if (below.length > 2 && !nestsFurther.contains(below.first)) {
          offenders.add('$path — nested deeper than one bucket level');
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'A feature lays domain/ and data/ out the same way or the next '
          'feature cannot be read by anyone who learned the last one — and, '
          'worse, the suffix rules select files by these exact paths, so an '
          'unbucketed file is not checked by anything at all.\n'
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
    // App-level, not per-feature: a feature with no widgets yet must not fail
    // the bucket rule, but the suite has to prove the rule saw at least one
    // bucketed file somewhere — otherwise a renamed widgets/ folder would turn
    // the whole check into a pass that inspected nothing.
    expect(
      dartFilesUnder(
        'lib/features',
      ).where((File f) => relative(f).contains('/presentation/widgets/')),
      isNotEmpty,
      reason: 'the bucket rule needs widget files to have any effect',
    );
    // The layer-bucket rule reports nothing when it matches nothing, which is
    // exactly how a feature laid out flat stayed invisible to every suffix rule
    // until M4.10ar. Prove each layer was seen — in more than one feature, so
    // one correctly-shaped feature cannot cover for the rest.
    for (final String layer in <String>['domain', 'data']) {
      final features = dartFilesUnder('lib/features')
          .map(relative)
          .where((String path) => path.contains('/$layer/'))
          .map((String path) => path.split('/')[2])
          .toSet();
      expect(
        features.length,
        greaterThan(1),
        reason:
            'the $layer/ bucket rule saw ${features.length} feature(s); it '
            'needs to be exercised by more than one or it degrades into a '
            'check on Deck alone',
      );
    }
  });
}
