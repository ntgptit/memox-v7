import 'card_import_repository.dart' show CardImportRepository;
import 'card_import_source_repository.dart' show CardImportSourceRepository;
import '../models/card_transfer_document_model.dart';
import '../models/card_transfer_source_model.dart';

/// The decode half of card transfer (M99.19): a source in, the raw document
/// out. Import is its only caller today; a future export adds the encoding
/// mirror beside it without touching this contract.
///
/// One of three deliberately narrow contracts — [CardImportSourceRepository]
/// picks, this one decodes, [CardImportRepository] commits — so a widget
/// test fakes only the half it exercises, and the commit implementation can
/// prove it never sees a byte of CSV.
///
/// Reads nothing and writes nothing to the database: decoding is a pure
/// transformation of bytes the user handed over, in app memory (BR-173).
abstract interface class CardTransferRepository {
  /// Decodes [source] into sheets of string rows, off the UI thread. Typed
  /// failures for what cannot be decoded (UC-10 E1): wrong encoding,
  /// corrupt bytes, no data at all.
  Future<CardTransferDocument> parse(CardTransferSource source);
}
