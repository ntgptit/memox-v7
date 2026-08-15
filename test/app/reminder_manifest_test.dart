import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// BR-226's negative half, asserted where it can actually be broken.
///
/// **A manifest test, because that is the only place the claim lives.** "The app
/// does not request an exact alarm" cannot be proved by a widget test or a use
/// case: the permission is granted by a line of XML, and it arrives just as
/// easily from a plugin's own manifest as from ours — Android merges them all.
/// `android_alarm_manager_plus` was rejected for exactly this reason (AD-21),
/// and this is what would catch it coming back in through a dependency.
///
/// It reads the manifests of the app **and** of every plugin the lockfile
/// resolves, because a permission the app never typed is still a permission the
/// user is asked about.
void main() {
  /// Permissions Android will not grant without a user-visible justification,
  /// and which a study reminder has no product requirement for.
  const forbidden = <String>[
    'android.permission.SCHEDULE_EXACT_ALARM',
    'android.permission.USE_EXACT_ALARM',
  ];

  List<File> appManifests() => Directory('android')
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('AndroidManifest.xml'))
      .toList();

  test('the app declares no exact-alarm permission in any flavor', () {
    final manifests = appManifests();
    // Zero manifests would make every assertion below pass without looking at
    // anything — the same failure mode `check_architecture` guards against.
    expect(manifests, isNotEmpty);

    for (final manifest in manifests) {
      final xml = manifest.readAsStringSync();
      for (final permission in forbidden) {
        expect(
          xml.contains(permission),
          isFalse,
          reason: '${manifest.path} declares $permission (BR-226)',
        );
      }
    }
  });

  test('no resolved plugin brings an exact-alarm permission with it', () {
    // The package cache is where a plugin's own manifest lives, and it is what
    // the merger actually reads. Resolved through `package_config.json` so the
    // test follows this machine's cache rather than a guessed path.
    final config = File('.dart_tool/package_config.json');
    expect(config.existsSync(), isTrue, reason: 'run `flutter pub get` first');

    final roots = RegExp(r'"rootUri":\s*"file:///([^"]+)"')
        .allMatches(config.readAsStringSync())
        .map((match) => Uri.decodeFull(match.group(1)!))
        .where((path) => path.contains('pub.dev'))
        .toList();
    expect(roots, isNotEmpty);

    final offenders = <String>[];
    for (final root in roots) {
      final androidDir = Directory('$root/android');
      if (!androidDir.existsSync()) continue;

      for (final entity in androidDir.listSync(recursive: true)) {
        if (entity is! File) continue;
        if (!entity.path.endsWith('AndroidManifest.xml')) continue;

        final xml = entity.readAsStringSync();
        for (final permission in forbidden) {
          if (!xml.contains(permission)) continue;

          offenders.add('${entity.path}: $permission');
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'A dependency would merge an exact-alarm permission into the app '
          'manifest, which BR-226 forbids.\n${offenders.join('\n')}',
    );
  });
}
