import 'package:flutter/widgets.dart';

import '../../../core/error/failure.dart';
import '../../../l10n/l10n_extension.dart';
import '../domain/deck_entity.dart';
import '../domain/deck_move_target_model.dart';
import '../domain/scheduler_type_model.dart';
import 'deck_submit_state.dart';

/// Where a domain value becomes something a person reads.
///
/// One place, on purpose. Every one of these mappings is a `switch` over a
/// closed set, and scattering them across screens is how one branch ends up
/// showing the enum name or, worse, a `Failure.message` written for a
/// developer. Keeping them together also makes the exhaustiveness check do real
/// work: add a scheduler or a rejection reason and every call site fails to
/// compile until it has copy.
///
/// It is an extension on the build context rather than a widget because it
/// returns strings. The file carries the `_widget` suffix that the naming rule
/// requires of everything under `presentation/`; there is no widget here and
/// inventing a wrapper one to satisfy the suffix would be worse than the
/// mismatch. It is named `_labels_` and not `_copy_`: "copy" reads as a backup
/// file to the repository's own file-name guard, which is a fair reading.
extension DeckLabels on BuildContext {
  /// The study mode's name (BR-30's sibling for deck screens: the label comes
  /// from the stored value, never from a hardcoded pair).
  String schedulerLabel(SchedulerType? scheduler) => switch (scheduler) {
    SchedulerType.eightBox => l10n.schedulerEightBoxLabel,
    SchedulerType.sm2 => l10n.schedulerSm2Label,
    // A deck written by a newer build. Naming it as unsupported beats showing
    // a blank, which reads as "no mode" — a state BR-11 forbids.
    SchedulerType.unknown => l10n.schedulerUnknownLabel,
    null => l10n.schedulerUnknownLabel,
  };

  String schedulerDescription(SchedulerType scheduler) => switch (scheduler) {
    SchedulerType.eightBox => l10n.schedulerEightBoxDescription,
    SchedulerType.sm2 => l10n.schedulerSm2Description,
    SchedulerType.unknown => l10n.schedulerUnknownLabel,
  };

  /// Why the form refused the last attempt, per field.
  ///
  /// One accessor for every [DeckFormProblem] rather than one per input: the
  /// problems now live in a single set, so the copy for them belongs in a single
  /// exhaustive switch. Adding a fourth way for a deck form to be wrong fails to
  /// compile here until it has text.
  String deckFormError(DeckFormProblem problem) => switch (problem) {
    DeckFormProblem.nameEmpty => l10n.deckNameEmptyError,
    DeckFormProblem.nameTooLong => l10n.deckNameTooLongError(
      DeckEntity.maxNameLength,
    ),
    DeckFormProblem.schedulerMissing => l10n.schedulerMissingError,
  };

  /// Why a move target cannot be chosen (UC-09 step 2).
  String deckMoveRejection(DeckMoveRejection rejection) => switch (rejection) {
    DeckMoveRejection.itself => l10n.deckMoveRejectItself,
    DeckMoveRejection.ownDescendant => l10n.deckMoveRejectDescendant,
    DeckMoveRejection.alreadyParent => l10n.deckMoveRejectAlreadyParent,
    DeckMoveRejection.holdsCards => l10n.deckMoveRejectHoldsCards,
    DeckMoveRejection.differentScheduler => l10n.deckMoveRejectScheduler,
    DeckMoveRejection.differentGeneration => l10n.deckMoveRejectGeneration,
    DeckMoveRejection.tooDeep => l10n.deckMoveRejectTooDeep,
  };

  /// A failure, as copy the user can act on.
  ///
  /// Maps the `Failure` *type*, never its message: `Failure.message` is written
  /// for whoever reads a log, and can name a table or an exception.
  ///
  /// **Every subtype is listed and there is no `_` branch**, which is the whole
  /// reason `Failure` is sealed. This switch used to end in `_ =>
  /// deckWriteErrorMessage`, and that catch-all defeated the type: a new failure
  /// subtype would have compiled straight into "something went wrong" with
  /// nothing failing anywhere — exactly what the doc on [Failure] warns about.
  ///
  /// Several cases share one message on purpose. Sharing a message is a decision;
  /// a `_` branch is the absence of one, and the difference only shows up the day
  /// a subtype is added.
  String deckWriteFailure(Failure failure) => switch (failure) {
    // Distinct copy, because the user's next action differs.
    NotFoundFailure() => l10n.deckGoneMessage,
    ConflictFailure() => l10n.deckConflictMessage,

    // Reachable, and there is nothing more useful to say: the write did not
    // land and retrying is the only move.
    DatabaseFailure() => l10n.deckWriteErrorMessage,
    UnknownFailure() => l10n.deckWriteErrorMessage,

    // A cancelled write is usually not worth a message at all, but the state is
    // rendered whenever `failure != null`, so silence here would be an empty
    // banner. Revisit if a flow ever cancels deliberately.
    CancelledFailure() => l10n.deckWriteErrorMessage,

    // Should never arrive: `deckSubmitFailure` peels `ValidationFailure` off into
    // the per-field problem before the state is built. Listed rather than
    // grouped so that if that ever changes, this line is where someone looks.
    ValidationFailure() => l10n.deckWriteErrorMessage,

    // Unreachable today — no network (AD-05) and no auth (AD-03), so nothing can
    // construct these. They are enumerated instead of swept under a `_` so that
    // M9 has to come here and decide, rather than inheriting a generic string it
    // never chose. A session that expired mid-write is not "an error occurred".
    NetworkFailure() => l10n.deckWriteErrorMessage,
    UnauthorizedFailure() => l10n.deckWriteErrorMessage,
    ForbiddenFailure() => l10n.deckWriteErrorMessage,
  };
}
