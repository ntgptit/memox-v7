import '../../../../core/database/app_database.dart';
import '../../../../core/error/failure.dart';
import '../../domain/failures/card_export_failure.dart';
import '../../domain/failures/card_validation_failure.dart';
import '../../domain/models/card_export_scope_model.dart';
import '../../domain/models/card_text_model.dart';
import '../../domain/models/card_transfer_record_model.dart';
import '../../domain/models/tag_name_model.dart';
import '../../domain/repositories/card_export_repository.dart';
import '../datasources/card_export_dao.dart';

/// Drift-backed [CardExportRepository] — the read half of export (UC-11 step 4).
///
/// Builds its DAO from the one [AppDatabase] it is handed, for the reason
/// `CardImportRepositoryImpl` states: the deck name and the card rows must
/// share one transaction, and a ready-made adapter would let a composition
/// root hand it a second database whose snapshot is a different moment.
///
/// It speaks canonical records and rows; no format, no bytes, no file name and
/// no share sheet — those are the encoder's and the destination's business,
/// and keeping them out is what `card_transfer_boundary_test.dart` pins.
///
/// **Nothing here writes** (BR-178). The DAO exposes no write method, this
/// class builds no companion, and the transaction it opens contains only
/// `SELECT`s — so a successful export leaves content, timestamps, the deck's
/// `content_type`, study state, history, flags and tag relations exactly as
/// they were.
final class CardExportRepositoryImpl implements CardExportRepository {
  CardExportRepositoryImpl(AppDatabase database)
    : _dao = CardExportDao(database);

  final CardExportDao _dao;

  /// The ASCII unit separator the query concatenates tag names with
  /// (`char(31)`), which a trimmed printable `TagName` can never contain —
  /// the same delimiter and the same argument as the card list's join.
  static const String _tagSeparator = '\u{1F}';

  @override
  Future<CardExportSnapshot> readSnapshot({
    required String deckId,
    required CardExportScope scope,
  }) => _guard(
    () => _dao.runInTransaction(() async {
      // One snapshot, not two reads (BR-177): the name is read inside the same
      // transaction as the rows, so a rename cannot land between them.
      final deckName = await _dao.deckName(deckId);
      if (deckName == null) {
        throw const NotFoundFailure(
          message: 'That deck no longer exists.',
          reason: CardExportProblem.deckMissing,
        );
      }

      final rows = await switch (scope) {
        CardExportWholeDeckScope() => _dao.cardsInDeck(deckId),
        CardExportSelectionScope(:final cardIds) => _selectedRows(
          deckId: deckId,
          cardIds: cardIds,
        ),
      };
      // The deck emptied, or the selection resolved to nothing that survives.
      // A file holding six headers and no cards is not the export the user
      // asked for (BR-174, UC-11 E5).
      if (rows.isEmpty) {
        throw const ValidationFailure(
          message: 'The export scope holds no cards.',
          problems: <Enum>{CardExportProblem.emptyScope},
        );
      }

      rows.sort(_byCreatedAtThenId);

      return CardExportSnapshot(
        deckName: deckName,
        records: <CardTransferRecord>[for (final row in rows) _recordOf(row)],
      );
    }),
  );

  /// The selected scope's rows, plus BR-174's all-or-nothing check.
  ///
  /// **Which ids came back, not how many.** The scope normalized duplicates
  /// away on construction, so a short result and a stale id look identical to
  /// a count; subtracting the returned ids from the requested ones names the
  /// difference instead. A deleted card and a card that moved to another deck
  /// both simply fail to return, because the statement filters on the deck as
  /// well as on the id — so one subtraction covers both halves of UC-11 E6.
  ///
  /// The whole request fails on it. A file quietly missing the cards the user
  /// picked is worse than no file, because nothing about it says anything is
  /// missing.
  Future<List<ExportCardRow>> _selectedRows({
    required String deckId,
    required Set<String> cardIds,
  }) async {
    final rows = await _dao.cardsByIds(
      deckId: deckId,
      cardIds: cardIds.toList(growable: false),
    );
    final missing = cardIds.difference(<String>{
      for (final row in rows) row.cardId,
    });
    if (missing.isNotEmpty) {
      throw const ValidationFailure(
        message: 'Some selected cards are no longer in this deck.',
        problems: <Enum>{CardExportProblem.staleSelection},
      );
    }

    return rows;
  }

  /// BR-177's order, applied where BR-177 puts it.
  ///
  /// The statements already carry `ORDER BY created_at ASC, id ASC` so the
  /// composite index supplies the order without a temp B-tree — but the
  /// selected scope runs in chunks, and the concatenation of several sorted
  /// statements is not itself sorted. Sorting here makes one comparator the
  /// single definition of the order for both scopes, rather than a property
  /// that happens to hold whenever the selection fits in one chunk.
  ///
  /// Total, so `sort`'s instability cannot show: ids are unique per row.
  static int _byCreatedAtThenId(ExportCardRow a, ExportCardRow b) {
    final byCreatedAt = a.createdAt.compareTo(b.createdAt);
    if (byCreatedAt != 0) return byCreatedAt;

    return a.cardId.compareTo(b.cardId);
  }

  /// One row as one canonical record — through the same value objects a manual
  /// create and an import use (BR-169), so nothing downstream looks at the text
  /// again.
  ///
  /// **Restored, not re-validated** (BR-175). A write parses; a read of what
  /// was already written must not re-apply the write-time length caps, because
  /// BR-08 and BR-95 have already changed their numbers once and no migration
  /// truncated the rows that predate the change. Re-parsing made one such row
  /// fail the whole deck's export — the app's only data escape hatch — over a
  /// limit the user never chose and cannot now satisfy. `fromStored` keeps
  /// every structural guarantee and drops only the cap.
  ///
  /// The id and `created_at` the query carried stop here: the canonical record
  /// has no field for either, which is what keeps export a content transfer
  /// rather than a backup (BR-175).
  CardTransferRecord _recordOf(ExportCardRow row) {
    final front = CardText.fromStored(row.front, side: CardSide.front);
    final back = CardText.fromStored(row.back, side: CardSide.back);

    final frontText = front.text;
    final backText = back.text;
    if (frontText == null || backText == null) {
      // A side that is blank in the database. Not a length question — BR-169
      // makes such a row unimportable, so there is no honest cell to write and
      // the request fails whole rather than exporting half a card (BR-174).
      throw DatabaseFailure(
        message: 'A stored card could not be read for export.',
        reason: CardExportProblem.readFailed,
        cause: front.problem ?? back.problem,
      );
    }

    return CardTransferRecord(
      front: frontText,
      back: backText,
      example: CardDetailText.fromStored(row.example ?? ''),
      hint: CardDetailText.fromStored(row.hint ?? ''),
      pronunciation: CardDetailText.fromStored(row.pronunciation ?? ''),
      tags: _tagsOf(row.tagNames),
    );
  }

  /// The concatenated tag names, split apart and put in BR-177's order.
  ///
  /// **Sorted here, not by the query.** SQLite does not promise the input order
  /// of an aggregate, so the `ORDER BY` inside the `GROUP_CONCAT` subquery is a
  /// courtesy and not a guarantee. Folded name first — BR-93's identity — with
  /// the raw spelling as the tie-break, so two spellings of one folded name
  /// could still only order one way.
  List<TagName> _tagsOf(String? concatenated) {
    if (concatenated == null || concatenated.isEmpty) return const <TagName>[];

    final tags = <TagName>[];
    for (final raw in concatenated.split(_tagSeparator)) {
      final parsed = TagName.fromStored(raw);
      final name = parsed.name;
      if (name == null) {
        // Not a length refusal — `fromStored` relaxes that, for the reason it
        // states. What is left is a name that cannot be written to a cell at
        // all, and the request fails whole rather than exporting a card with a
        // tag silently missing.
        throw DatabaseFailure(
          message: 'A stored tag could not be read for export.',
          reason: CardExportProblem.readFailed,
          cause: parsed.problem,
        );
      }
      tags.add(name);
    }
    tags.sort(_byFoldedThenSpelling);

    return tags;
  }

  static int _byFoldedThenSpelling(TagName a, TagName b) {
    final byFolded = a.folded.compareTo(b.folded);
    if (byFolded != 0) return byFolded;

    return a.value.compareTo(b.value);
  }

  /// **Not `mapDatabaseError`.** Its three arms answer "which constraint did
  /// this write violate", and export writes nothing (BR-178) — so every
  /// failure that reaches here is a read that did not complete, which is
  /// exactly one reason (UC-11 E3). The original is kept on `cause` for the
  /// log; the message names no table, no column and no card.
  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on Failure {
      rethrow;
    } on Object catch (error) {
      throw DatabaseFailure(
        message: 'The cards could not be read for export.',
        reason: CardExportProblem.readFailed,
        cause: error,
      );
    }
  }
}
