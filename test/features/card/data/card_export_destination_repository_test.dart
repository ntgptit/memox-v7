import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/card/data/repositories/card_export_destination_repository_impl.dart';
import 'package:memox/features/card/domain/failures/card_export_failure.dart';
import 'package:memox/features/card/domain/models/card_export_artifact_model.dart';
import 'package:memox/features/card/domain/models/card_export_result_model.dart';
import 'package:share_plus/share_plus.dart';
import 'package:share_plus_platform_interface/share_plus_platform_interface.dart';

/// The share seam (BR-181, UC-11 A3, E1, E2).
///
/// **`share_plus` is faked at its own boundary, not by faking the adapter.**
/// A double standing in for `CardExportDestinationRepository` would prove only
/// that a fake returns what it was told to; the four outcomes below are
/// decisions this file makes about what the plugin said, and a test that
/// skipped the plugin would skip the decisions.
void main() {
  final artifact = CardExportArtifact(
    fileName: 'Leaf 2026-08-13.csv',
    mimeType: 'text/csv',
    bytes: Uint8List.fromList(<int>[1, 2, 3]),
  );

  CardExportDestinationRepositoryImpl destination(
    _FakeSharePlatform platform,
  ) => CardExportDestinationRepositoryImpl(share: SharePlus.custom(platform));

  test('a chosen destination is a hand-over (UC-11 step 7)', () async {
    final platform = _FakeSharePlatform.returning(
      const ShareResult('com.example.mail', ShareResultStatus.success),
    );

    expect(
      await destination(platform).share(artifact),
      CardExportResult.shared,
    );
  });

  test('a closed sheet is a cancel, not a failure (UC-11 A3)', () async {
    final platform = _FakeSharePlatform.returning(
      const ShareResult('', ShareResultStatus.dismissed),
    );

    expect(
      await destination(platform).share(artifact),
      CardExportResult.dismissed,
    );
  });

  test('a platform that cannot report the choice still handed the file '
      'over', () async {
    // Android without result support, and every desktop and web
    // implementation. "Handed to the system" is the truthful claim; calling it
    // a dismissal would tell the user they cancelled something they did not.
    final platform = _FakeSharePlatform.returning(ShareResult.unavailable);

    expect(
      await destination(platform).share(artifact),
      CardExportResult.shared,
    );
  });

  test('a platform with no file sharing at all is its own reason '
      '(UC-11 E1)', () async {
    final platform = _FakeSharePlatform.throwing(
      UnimplementedError('sharing files is not available here'),
    );

    await expectLater(
      destination(platform).share(artifact),
      throwsA(
        isA<UnknownFailure>().having(
          (UnknownFailure failure) => failure.reason,
          'reason',
          CardExportProblem.shareUnavailable,
        ),
      ),
    );
  });

  test('a missing plugin registration reads as unavailable, not as a '
      'channel error', () async {
    final platform = _FakeSharePlatform.throwing(
      MissingPluginException('no implementation found'),
    );

    await expectLater(
      destination(platform).share(artifact),
      throwsA(
        isA<UnknownFailure>().having(
          (UnknownFailure failure) => failure.reason,
          'reason',
          CardExportProblem.shareUnavailable,
        ),
      ),
    );
  });

  test('a channel exception maps to a typed reason and leaks neither path '
      'nor file name (UC-11 E2)', () async {
    final platform = _FakeSharePlatform.throwing(
      PlatformException(
        code: 'error',
        message: 'could not open /data/user/0/com.example/cache/x/Leaf.csv',
      ),
    );

    await expectLater(
      destination(platform).share(artifact),
      throwsA(
        isA<UnknownFailure>()
            .having(
              (UnknownFailure failure) => failure.reason,
              'reason',
              CardExportProblem.sharePlatformError,
            )
            .having(
              (UnknownFailure failure) => failure.message,
              'message',
              allOf(
                isNot(contains('/data/')),
                isNot(contains('Leaf')),
                isNot(contains('.csv')),
              ),
            ),
      ),
    );
  });

  test('the artifact is handed over as data, with its name and type — never '
      'as a path this app wrote (BR-181)', () async {
    final platform = _FakeSharePlatform.returning(
      const ShareResult('com.example.mail', ShareResultStatus.success),
    );

    await destination(platform).share(artifact);

    final params = platform.received!;
    final file = params.files!.single;
    // An empty path is what tells the plugin to put the transient copy in the
    // app's own temporary area: nothing here names a directory, so nothing here
    // can name a shared one.
    expect(file.path, isEmpty);
    expect(file.mimeType, 'text/csv');
    expect(params.fileNameOverrides, <String>['Leaf 2026-08-13.csv']);
    expect(await file.readAsBytes(), <int>[1, 2, 3]);
    // A silent download or a mail compose window is a destination the user did
    // not pick.
    expect(params.downloadFallbackEnabled, isFalse);
    expect(params.mailToFallbackEnabled, isFalse);
  });
}

/// Stands in for the plugin's platform implementation — the lowest point the
/// adapter can be cut at without a device.
final class _FakeSharePlatform extends SharePlatform {
  _FakeSharePlatform.returning(this._result) : _error = null;

  _FakeSharePlatform.throwing(this._error) : _result = null;

  final ShareResult? _result;
  final Object? _error;

  ShareParams? received;

  @override
  Future<ShareResult> share(ShareParams params) async {
    received = params;
    final error = _error;
    // Rethrows verbatim whatever the test handed it, because reproducing what
    // the plugin actually throws is the point — `UnimplementedError` is an
    // `Error` and `PlatformException` is an `Exception`, and a wrapper that
    // made them one type would erase the distinction the adapter switches on.
    // ignore: only_throw_errors
    if (error != null) throw error;

    return _result!;
  }
}
