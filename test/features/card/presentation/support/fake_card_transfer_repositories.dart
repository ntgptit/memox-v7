import 'dart:async';

import 'package:memox/core/error/failure.dart';
import 'package:memox/features/card/data/datasources/card_transfer_resolver_data_source.dart';
import 'package:memox/features/card/domain/models/card_import_preview_model.dart';
import 'package:memox/features/card/domain/models/card_import_result_model.dart';
import 'package:memox/features/card/domain/models/card_transfer_document_model.dart';
import 'package:memox/features/card/domain/models/card_transfer_source_model.dart';
import 'package:memox/features/card/domain/repositories/card_import_repository.dart';
import 'package:memox/features/card/domain/repositories/card_import_source_repository.dart';
import 'package:memox/features/card/domain/repositories/card_transfer_repository.dart';

/// The decode contract, running the real resolver **synchronously**: widget
/// tests live under fake async, where a real isolate hop never completes.
/// The decoding itself is the production code path.
final class FakeCardTransferRepository implements CardTransferRepository {
  Failure? nextParseFailure;

  /// When set, parse answers with this instead of decoding — the way a test
  /// stages a multi-sheet workbook without building XLSX bytes.
  CardTransferDocument? documentToReturn;

  @override
  Future<CardTransferDocument> parse(CardTransferSource source) async {
    final failure = nextParseFailure;
    if (failure != null) throw failure;

    return documentToReturn ?? decodeCardTransferSource(source);
  }
}

/// The pick contract: hands back whatever the test staged. Null is the
/// cancel path (UC-10 A5).
final class FakeCardImportSourceRepository
    implements CardImportSourceRepository {
  CardTransferFileSource? fileToPick;
  Failure? nextPickFailure;
  int pickCalls = 0;

  @override
  Future<CardTransferFileSource?> pickFile() async {
    pickCalls += 1;
    final failure = nextPickFailure;
    if (failure != null) throw failure;

    return fileToPick;
  }
}

/// The commit contract: records every plan, applies the staged keys the way
/// the real recheck would, and fails on demand (UC-10 E5).
final class FakeCardImportCommitRepository implements CardImportRepository {
  Set<CardImportDuplicateKey> existingKeys = <CardImportDuplicateKey>{};
  Failure? nextCommitFailure;
  final List<CardImportPlan> commits = <CardImportPlan>[];

  @override
  Future<Set<CardImportDuplicateKey>> readExistingDuplicateKeys(
    String deckId,
  ) async => existingKeys;

  /// When set, the commit parks on this until the test completes it — how
  /// the submitting lock is observed mid-flight (F).
  Completer<void>? commitGate;

  @override
  Future<CardImportResult> commitImport({
    required String deckId,
    required CardImportPlan plan,
  }) async {
    commits.add(plan);
    final gate = commitGate;
    if (gate != null) await gate.future;
    final failure = nextCommitFailure;
    if (failure != null) throw failure;

    var imported = 0, skipped = 0;
    final seen = <CardImportDuplicateKey>{};
    for (final record in plan.records) {
      final key = record.duplicateKey;
      final isDuplicate = existingKeys.contains(key) || seen.contains(key);
      seen.add(key);
      if (isDuplicate && !plan.shouldIncludeDuplicates) {
        skipped += 1;
        continue;
      }
      imported += 1;
    }

    return CardImportResult(imported: imported, duplicatesSkipped: skipped);
  }
}
