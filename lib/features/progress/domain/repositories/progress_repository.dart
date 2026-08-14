import '../models/progress_overview_model.dart';

/// Reading the learner's own activity back out of history (UC-12).
///
/// **Read-only, and there is nothing to add.** BR-190 makes Progress a screen
/// that cannot mutate anything, and a contract with one `Stream` getter is how
/// that is enforced structurally rather than by everyone remembering: there is
/// no write method to call by accident, and adding one would be a visible
/// decision in this file rather than a line inside an implementation.
///
/// Both time inputs are parameters (AD-16, BR-184). Nothing under
/// `lib/features/` reads the wall clock, and a repository that did could not be
/// tested at a local-midnight boundary — which is the boundary every number
/// here is defined against.
abstract interface class ProgressRepository {
  /// One consistent snapshot per emission, re-emitted whenever the history it
  /// summarises changes (BR-189).
  ///
  /// [now] and [utcOffset] are one snapshot of `clockProvider` and
  /// `utcOffsetProvider`, taken by the caller. Crossing local midnight is a new
  /// [now], not an event the repository detects: the stream measures what it is
  /// asked to measure, and the controller decides when to ask again.
  Stream<ProgressOverview> watchProgressOverview({
    required DateTime now,
    required Duration utcOffset,
  });
}
