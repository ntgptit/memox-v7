import '../../../../core/error/failure.dart';
import '../../../../core/state/submit_state.dart';
import '../../domain/failures/tag_catalog_failure.dart';
import '../../domain/failures/tag_validation_failure.dart';

/// The status of **one** catalog write — a rename or a delete.
///
/// A typedef over the shared [SubmitState], like `CardTagSubmitState`. What is
/// this form's own is only which problems exist, and they are BR-93's — the
/// rename field is the same field the add-tag field is, validated by the same
/// `TagName.parse`, so a second enum here would be a second definition of what
/// a tag name is.
typedef TagCatalogSubmitState = SubmitState<TagValidationProblem>;

/// The rename field's reading of the problem set.
///
/// All of BR-93's problems belong to the one input, so there is a single
/// accessor rather than a per-field split — the shape `CardTagProblems` uses.
extension TagCatalogProblems on TagCatalogSubmitState {
  TagValidationProblem? get problem =>
      firstProblemOf(TagValidationProblem.values.toSet());
}

/// Maps a repository or use-case failure onto the rename field.
///
/// The problems are **read out of** the failure, never re-derived: the use case
/// put them there, and a screen that inspected the raw text again to decide
/// which error to show would become a second owner of BR-93. Anything that is
/// not a field problem — a vanished tag, a database error — stays on the
/// operation, where the sheet renders it as a band rather than under the input.
TagCatalogSubmitState tagCatalogFailure(Failure failure) {
  if (failure is! ValidationFailure) {
    return TagCatalogSubmitState(failure: failure);
  }

  final problems = failure.problems.whereType<TagValidationProblem>().toSet();

  return TagCatalogSubmitState(
    problems: problems,
    failure: problems.isEmpty ? failure : null,
  );
}

/// A rename attempt: its submit status, plus **which of the two things it did**
/// once it succeeded (BR-233, BR-234).
///
/// **The outcome is state, not a getter on the notifier.** It has to arrive on
/// the same transition the sheet reacts to, or the confirmation is chosen from
/// a value written after the widget last rebuilt — and a non-reactive field on
/// a Notifier is exactly what
/// `memox.state_management.notifier_no_public_mutable_field` exists to stop.
///
/// **And it is a wrapper rather than a fifth field on [SubmitState].**
/// `SubmitState` is shared by every form in the app and lives in `core/`;
/// "renamed or merged" is a tag concept, and putting it there would give one
/// feature's vocabulary to all of them.
final class TagRenameSubmitState {
  const TagRenameSubmitState({
    this.submit = const TagCatalogSubmitState(),
    this.outcome,
  });

  /// The shared four fields — spinner, field problems, failure, success.
  final TagCatalogSubmitState submit;

  /// What the write turned out to be. Null until it has succeeded; **read from
  /// the domain, never re-derived from the typed name**, because the collision
  /// is decided inside the BR-234 transaction, at the moment of the write.
  final TagRenameOutcome? outcome;

  @override
  bool operator ==(Object other) =>
      other is TagRenameSubmitState &&
      other.submit == submit &&
      other.outcome == outcome;

  @override
  int get hashCode => Object.hash(submit, outcome);
}
