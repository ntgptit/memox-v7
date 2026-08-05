import '../models/deck_template_model.dart';
import '../repositories/deck_template_repository.dart';

/// What one whole seed pass did, per template.
typedef DeckTemplateInstallReport =
    List<
      ({String templateId, int version, DeckTemplateInstallOutcome outcome})
    >;

/// Installs every published starter template, once each (UC-01, BR-37).
///
/// **One use case for the whole set, not one per template.** The caller —
/// startup — has a single question: "is the app's fixture content in place?".
/// Splitting it would make the caller loop, and a loop in a caller is where the
/// "already installed" case gets forgotten for one template and not another.
///
/// It reports rather than returning void: a seed that silently does nothing and
/// a seed that silently did everything look identical from the outside, and the
/// demo flow has to be able to say which happened.
final class InstallDeckTemplatesUseCase {
  const InstallDeckTemplatesUseCase(this._repository);

  final DeckTemplateRepository _repository;

  Future<DeckTemplateInstallReport> call(List<DeckTemplate> templates) async {
    final report =
        <
          ({String templateId, int version, DeckTemplateInstallOutcome outcome})
        >[];
    for (final template in templates) {
      // Sequential, not `Future.wait`: each install opens a transaction, and
      // running them concurrently on one connection serialises anyway while
      // making the failure of one harder to attribute.
      final outcome = await _repository.installTemplate(template);
      report.add((
        templateId: template.templateId,
        version: template.version,
        outcome: outcome,
      ));
    }

    return report;
  }
}
