import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The two vendored web assets, and the versions they were built for.
///
/// `sqlite3.wasm` and `drift_worker.js` are downloaded binaries. Nothing in the
/// build produces them and nothing in the build notices when they are stale: the
/// app compiles, loads, and then cannot open a database. Web is the E2E channel
/// (AD-04), so a stale worker means an E2E suite passing against an app with no
/// persistence — green, and covering nothing.
///
/// This is the only thing standing between a `drift` upgrade and that outcome.
void main() {
  /// Versions the files in `web/` were downloaded for. Update these in the same
  /// commit as the files themselves; the test reads both, so half an upgrade
  /// fails instead of shipping.
  const pinned = <String, String>{'sqlite3': '3.5.0', 'drift': '2.34.0'};

  String lockedVersion(String package) {
    // Normalised: the lockfile is CRLF on Windows, and `\n` in the pattern then
    // matches nothing at all — a silent null rather than a wrong answer.
    final lock = File(
      'pubspec.lock',
    ).readAsStringSync().replaceAll('\r\n', '\n');
    final match = RegExp(
      '^  $package:\\n(?:.*\\n)*?    version: "([^"]+)"',
      multiLine: true,
    ).firstMatch(lock);

    expect(match, isNotNull, reason: '$package is not in pubspec.lock');

    return match!.group(1)!;
  }

  test('both assets are present in web/', () {
    // Their absence is invisible until runtime, which is the whole problem.
    expect(File('web/sqlite3.wasm').existsSync(), isTrue);
    expect(File('web/drift_worker.js').existsSync(), isTrue);
  });

  test('sqlite3.wasm is a WebAssembly module, not an error page', () {
    // A failed download writes an HTML error body to the same filename with a
    // perfectly ordinary exit code.
    final header = File('web/sqlite3.wasm').openSync().readSync(4);

    expect(header, <int>[0x00, 0x61, 0x73, 0x6d]);
  });

  test('drift_worker.js is compiled Dart, not an error page', () {
    final head = File(
      'web/drift_worker.js',
    ).readAsStringSync().substring(0, 64);

    expect(head, contains('dartProgram'));
  });

  test('the vendored assets match the locked package versions', () {
    // The check that matters. Upgrading drift without re-downloading the worker
    // leaves a version mismatch that only shows up in a browser.
    pinned.forEach((package, version) {
      expect(
        lockedVersion(package),
        version,
        reason:
            'pubspec.lock has $package ${lockedVersion(package)} but web/ was '
            'built for $version. Re-download the asset and update both this '
            'test and web/WEB_ASSETS.md — see that file for the commands.',
      );
    });
  });
}
