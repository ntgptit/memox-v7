import '../models/deck_template_model.dart';
import '../models/scheduler_type_model.dart';
import '../repositories/deck_template_repository.dart';

/// Copies **one** chosen starter template into the library (UC-01, BR-33).
///
/// The plural [InstallDeckTemplatesUseCase] belongs to startup, whose question
/// is "is the fixture content in place?" and whose answer covers the whole set.
/// This one belongs to a person on the starter screen who picked a deck and a
/// schedule — one interaction, one use case (AD-12).
///
/// Thin on purpose: the scheduler choice is already typed, the template is
/// already validated by construction, and every rule that needs the database as
/// it stands — the BR-37 idempotency check above all — runs inside the
/// repository's transaction, where hoisting it would put it outside (AD-13).
final class InstallDeckTemplateUseCase {
  const InstallDeckTemplateUseCase(this._repository);

  final DeckTemplateRepository _repository;

  Future<DeckTemplateInstallOutcome> call(
    DeckTemplate template, {
    SchedulerType? schedulerType,
    bool allowDuplicate = false,
  }) => _repository.installTemplate(
    template,
    schedulerType: schedulerType,
    allowDuplicate: allowDuplicate,
  );
}
