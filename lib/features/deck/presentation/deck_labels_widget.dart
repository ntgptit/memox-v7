import 'package:flutter/widgets.dart';

import '../../../core/error/failure.dart';
import '../../../l10n/l10n_extension.dart';
import '../domain/deck_entity.dart';
import '../domain/deck_move_target_model.dart';
import '../domain/scheduler_type_model.dart';

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

  /// Inline copy for a name that breaks BR-01.
  String deckNameError(DeckNameProblem problem) => switch (problem) {
    DeckNameProblem.empty => l10n.deckNameEmptyError,
    DeckNameProblem.tooLong => l10n.deckNameTooLongError(
      DeckEntity.maxNameLength,
    ),
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

  /// What to tell the user about a failed write.
  ///
  /// Maps the `Failure` *type*, never its message: `Failure.message` is written
  /// for whoever reads a log, and can name a table or an exception. A
  /// `ValidationFailure` is deliberately absent — those are rendered under the
  /// field that caused them and never reach here.
  String deckWriteFailure(Failure failure) => switch (failure) {
    NotFoundFailure() => l10n.deckGoneMessage,
    ConflictFailure() => l10n.deckConflictMessage,
    _ => l10n.deckWriteErrorMessage,
  };
}
