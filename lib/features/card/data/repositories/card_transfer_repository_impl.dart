import '../../domain/models/card_transfer_document_model.dart';
import '../../domain/models/card_transfer_source_model.dart';
import '../../domain/repositories/card_transfer_repository.dart';
import '../datasources/card_transfer_resolver_data_source.dart';

/// The decode boundary (M99.19): hands the source to the resolver's
/// off-thread entry and nothing more. Which decoder runs is the registry's
/// decision — this class never mentions a format, and the database does not
/// exist from where it stands.
final class CardTransferRepositoryImpl implements CardTransferRepository {
  const CardTransferRepositoryImpl();

  @override
  Future<CardTransferDocument> parse(CardTransferSource source) =>
      decodeCardTransferSourceOffThread(source);
}
