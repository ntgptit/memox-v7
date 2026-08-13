import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/card/domain/failures/card_export_failure.dart';
import 'package:memox/features/card/domain/models/card_export_artifact_model.dart';
import 'package:memox/features/card/domain/models/card_export_request_model.dart';
import 'package:memox/features/card/domain/models/card_export_result_model.dart';
import 'package:memox/features/card/domain/models/card_export_scope_model.dart';
import 'package:memox/features/card/domain/models/card_text_model.dart';
import 'package:memox/features/card/domain/models/card_transfer_encoder_model.dart';
import 'package:memox/features/card/domain/models/card_transfer_format_model.dart';
import 'package:memox/features/card/domain/models/card_transfer_record_model.dart';
import 'package:memox/features/card/domain/repositories/card_export_destination_repository.dart';
import 'package:memox/features/card/domain/models/tag_name_model.dart';
import 'package:memox/features/card/domain/repositories/card_export_repository.dart';
import 'package:memox/features/card/domain/usecases/export_cards_use_case.dart';

/// UC-11 steps 4–7, with only the two boundaries faked: the snapshot read and
/// the platform destination. The file name, the MIME type and the encode step
/// are production code.
void main() {
  DateTime clock() => DateTime.utc(2026, 8, 13);

  CardTransferRecord recordOf(String front, String back) {
    final sides = parseCardSides(rawFront: front, rawBack: back);

    return CardTransferRecord(
      front: sides.front,
      back: sides.back,
      tags: const <TagName>[],
    );
  }

  ExportCardsUseCase useCaseFor({
    required _FakeExportRepository repository,
    required _FakeDestination destination,
    CardTransferEncoderResolver? encoderFor,
  }) => ExportCardsUseCase(
    repository: repository,
    encoderFor: encoderFor ?? (_) => const _StubEncoder(),
    destination: destination,
    clock: clock,
  );

  const request = CardExportRequest(
    deckId: 'deck-1',
    scope: CardExportWholeDeckScope(),
    format: CardTransferFormat.csv,
  );

  test('reads, encodes, names and hands over — in that order', () async {
    final repository = _FakeExportRepository(
      snapshot: CardExportSnapshot(
        deckName: 'Korean Verbs',
        records: <CardTransferRecord>[recordOf('사과', 'apple')],
      ),
    );
    final destination = _FakeDestination(CardExportResult.shared);

    final result = await useCaseFor(
      repository: repository,
      destination: destination,
    ).call(request, isCancelled: () => false);

    expect(result, CardExportResult.shared);
    expect(repository.readDeckIds, <String>['deck-1']);
    expect(destination.shared!.fileName, 'Korean Verbs_2026-08-13.csv');
    expect(destination.shared!.mimeType, CardTransferFormat.csv.mimeType);
    expect(destination.shared!.bytes, isNotEmpty);
  });

  group('cancelled while it runs (UC-11 A5, M4.13 W4)', () {
    _FakeExportRepository repositoryOfOne() => _FakeExportRepository(
      snapshot: CardExportSnapshot(
        deckName: 'Deck',
        records: <CardTransferRecord>[recordOf('사과', 'apple')],
      ),
    );

    test('nothing is handed to the OS once the user has left', () async {
      // W4's promise, in the only place it can still be kept: the artifact is
      // built but has never left this process, so dropping it is exactly "the
      // sheet closed without creating a file". Before this check the share
      // sheet appeared *after* the user cancelled, for a file the app then
      // never confirmed either way.
      final destination = _FakeDestination(CardExportResult.shared);

      final result = await useCaseFor(
        repository: repositoryOfOne(),
        destination: destination,
      ).call(request, isCancelled: () => true);

      expect(result, CardExportResult.dismissed);
      expect(destination.shared, isNull, reason: 'nothing may be handed over');
    });

    test('a cancel that lands during the read skips the encode too', () async {
      var encoded = false;
      final destination = _FakeDestination(CardExportResult.shared);

      final result = await useCaseFor(
        repository: repositoryOfOne(),
        destination: destination,
        encoderFor: (_) {
          encoded = true;

          return const _StubEncoder();
        },
      ).call(request, isCancelled: () => true);

      expect(result, CardExportResult.dismissed);
      expect(encoded, isFalse, reason: 'no deck is encoded for nobody');
      expect(destination.shared, isNull);
    });

    test('a cancel that never comes changes nothing', () async {
      final destination = _FakeDestination(CardExportResult.shared);

      final result = await useCaseFor(
        repository: repositoryOfOne(),
        destination: destination,
      ).call(request, isCancelled: () => false);

      expect(result, CardExportResult.shared);
      expect(destination.shared, isNotNull);
    });
  });

  test('a dismissed share comes back as a value, not a failure (A3)', () async {
    final destination = _FakeDestination(CardExportResult.dismissed);

    final result = await useCaseFor(
      repository: _FakeExportRepository(
        snapshot: CardExportSnapshot(
          deckName: 'Deck',
          records: <CardTransferRecord>[recordOf('사과', 'apple')],
        ),
      ),
      destination: destination,
    ).call(request, isCancelled: () => false);

    expect(result, CardExportResult.dismissed);
  });

  test(
    'an empty snapshot is refused and nothing is handed over (E5)',
    () async {
      final destination = _FakeDestination(CardExportResult.shared);

      await expectLater(
        useCaseFor(
          repository: _FakeExportRepository(
            snapshot: const CardExportSnapshot(
              deckName: 'Deck',
              records: <CardTransferRecord>[],
            ),
          ),
          destination: destination,
        ).call(request, isCancelled: () => false),
        throwsA(
          isA<ValidationFailure>().having(
            (ValidationFailure failure) => failure.problems,
            'problems',
            contains(CardExportProblem.emptyScope),
          ),
        ),
      );
      expect(destination.shared, isNull);
    },
  );

  test(
    'a read failure propagates untouched and nothing is shared (E3)',
    () async {
      final destination = _FakeDestination(CardExportResult.shared);

      await expectLater(
        useCaseFor(
          repository: _FakeExportRepository(
            failure: const DatabaseFailure(
              message: 'read failed',
              reason: CardExportProblem.readFailed,
            ),
          ),
          destination: destination,
        ).call(request, isCancelled: () => false),
        throwsA(
          isA<DatabaseFailure>().having(
            (DatabaseFailure failure) => failure.reason,
            'reason',
            CardExportProblem.readFailed,
          ),
        ),
      );
      expect(destination.shared, isNull);
    },
  );

  test(
    'an encoder throw becomes its own reason, distinct from a read (E4)',
    () async {
      final destination = _FakeDestination(CardExportResult.shared);

      await expectLater(
        useCaseFor(
          repository: _FakeExportRepository(
            snapshot: CardExportSnapshot(
              deckName: 'Deck',
              records: <CardTransferRecord>[recordOf('사과', 'apple')],
            ),
          ),
          destination: destination,
          encoderFor: (_) => const _ThrowingEncoder(),
        ).call(request, isCancelled: () => false),
        throwsA(
          isA<ValidationFailure>().having(
            (ValidationFailure failure) => failure.problems,
            'problems',
            contains(CardExportProblem.encodeFailed),
          ),
        ),
      );
      expect(destination.shared, isNull);
    },
  );
}

/// The snapshot half of UC-11 step 4 — the only database this test has.
final class _FakeExportRepository implements CardExportRepository {
  _FakeExportRepository({this.snapshot, this.failure});

  final CardExportSnapshot? snapshot;
  final Failure? failure;
  final List<String> readDeckIds = <String>[];

  @override
  Future<CardExportSnapshot> readSnapshot({
    required String deckId,
    required CardExportScope scope,
  }) async {
    readDeckIds.add(deckId);
    final thrown = failure;
    if (thrown != null) throw thrown;

    return snapshot!;
  }
}

/// The platform half — records what it was handed, so "nothing partial was
/// shared" is an assertion and not a hope.
final class _FakeDestination implements CardExportDestinationRepository {
  _FakeDestination(this.result);

  final CardExportResult result;
  CardExportArtifact? shared;

  @override
  Future<CardExportResult> share(CardExportArtifact artifact) async {
    shared = artifact;

    return result;
  }
}

final class _StubEncoder implements CardTransferEncoder {
  const _StubEncoder();

  @override
  Uint8List encode(List<CardTransferRecord> records) =>
      Uint8List.fromList(<int>[1, 2, 3]);
}

final class _ThrowingEncoder implements CardTransferEncoder {
  const _ThrowingEncoder();

  @override
  Uint8List encode(List<CardTransferRecord> records) =>
      throw StateError('encoder blew up');
}
