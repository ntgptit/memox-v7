import 'package:flutter/material.dart';

import '../../../../../l10n/l10n_extension.dart';
import '../../../../deck/domain/models/scheduler_type_model.dart';

/// Copy the Study tab's home screen needs and no other Study screen does.
///
/// **Its own extension rather than a third method on `StudyLabels`.** That one
/// is the vocabulary of a *session* — actions, modes, hints — and this is the
/// vocabulary of the screen that has not started one yet. Keeping them apart is
/// what stops a session label being reached for on a screen with no session.
///
/// **The scheduler copy is the shared ARB key, not the deck screen's helper.**
/// `context.schedulerShortLabel` lives in `features/deck/presentation/`, which a
/// feature may not import (`check_architecture.sh` rule 3). The ARB is shared,
/// so both read the same string and neither owns the other.
extension StudyHomeLabels on BuildContext {
  /// The algorithm a root deck is reviewed with (BR-06, BR-11).
  ///
  /// Null for [SchedulerType.unknown], and null is the point: a deck written by
  /// a newer build is still listed and still openable, but naming its algorithm
  /// would be a guess. The row drops the fact rather than inventing it.
  String? studyHomeSchedulerLabel(SchedulerType scheduler) =>
      switch (scheduler) {
        SchedulerType.eightBox => l10n.schedulerEightBoxShortLabel,
        SchedulerType.sm2 => l10n.schedulerSm2Label,
        SchedulerType.unknown => null,
      };
}
