import '../../../../core/database/app_database.dart';
import '../../../../core/error/drift_error_mapper.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/time/local_day_model.dart';
import '../../domain/models/deck_activity_snapshot_model.dart';
import '../../domain/models/progress_overview_model.dart';
import '../../domain/models/progress_range_model.dart';
import '../../domain/repositories/progress_repository.dart';
import '../datasources/progress_dao.dart';
import '../mappers/progress_mapper.dart';

/// The Progress reads, against Drift (AD-01).
///
/// **Translation and failure mapping, and nothing else.** Every rule — the
/// seven-day window, the zero-fill, the streak walk, the ordering and the
/// two ranges — lives in `domain/`, where it is tested without a database.
/// What is left here is what only this layer knows: that rows arrive from
/// Drift, and that a `DriftException` must not reach a screen (BR-52).
///
/// Both reads are wrapped by [_guardStream], so a failure surfaces as a domain
/// `Failure` on the stream rather than as an infrastructure exception the UI
/// would have to know the shape of.
final class ProgressRepositoryImpl implements ProgressRepository {
  ProgressRepositoryImpl(this._dao);

  final ProgressDao _dao;

  @override
  Stream<ProgressOverview> watchProgressOverview({
    required DateTime now,
    required Duration utcOffset,
  }) {
    // Built once, outside the `map`, so every emission of this subscription is
    // measured against the same instant (BR-194). Constructing it per emission
    // would make a live refresh silently re-anchor the window to a newer clock
    // reading, and the screen would then roll over at an arbitrary answer rather
    // than at midnight — which is a rollover nobody scheduled and no test would
    // reproduce twice.
    final day = LocalDayModel(now: now, utcOffset: utcOffset);

    return _guardStream(
      _dao.watchActivityDays(utcOffset: utcOffset),
    ).map((rows) => overviewFromRows(rows, day: day));
  }

  @override
  Stream<DeckActivitySnapshot> watchDeckActivity({
    required String? deckId,
    required DateTime now,
    required Duration utcOffset,
  }) {
    final day = LocalDayModel(now: now, utcOffset: utcOffset);

    // Whole local days, today included (BR-184). `startOfDayAfter` takes a
    // signed offset, so the 30-day window begins 29 boundaries back and the
    // 7-day window 6 — `daysBeforeToday` owns that arithmetic so the off-by-one
    // lives in one place.
    final windowFrom = day.startOfDayAfter(
      -ProgressRange.last30Days.daysBeforeToday,
    );
    final recentFrom = day.startOfDayAfter(
      -ProgressRange.last7Days.daysBeforeToday,
    );
    // The next local midnight, not `now`: an answer graded a second ago must be
    // inside today's bucket, and an upper bound at `now` would also make the
    // read's result depend on the second it ran, which no test could pin.
    final windowUntil = day.startOfTomorrow;

    if (deckId == null) {
      return _guardStream(
        _dao.watchRootDeckActivity(
          windowFrom: windowFrom,
          recentFrom: recentFrom,
          windowUntil: windowUntil,
        ),
      ).map(
        (List<RootDeckActivityResult> rows) =>
            rootActivityFromRows(rows, day: day),
      );
    }

    return _guardStream(
      _dao.watchChildDeckActivity(
        parentDeckId: deckId,
        windowFrom: windowFrom,
        recentFrom: recentFrom,
        windowUntil: windowUntil,
      ),
    ).map(_requireLevel(day));
  }

  /// Turns "no rows" into the failure it means.
  ///
  /// The statement `LEFT JOIN`s the children onto the deck, so a deck with no
  /// sub-decks still produces one row. Zero rows can therefore only mean the
  /// deck itself is not there — deleted while the screen was open, or a link to
  /// a deck that never existed — and a level that rendered empty instead would
  /// tell the user their deck is simply quiet.
  DeckActivitySnapshot Function(List<ChildDeckActivityResult>) _requireLevel(
    LocalDayModel day,
  ) => (List<ChildDeckActivityResult> rows) {
    if (rows.isEmpty) {
      throw const NotFoundFailure(message: 'That deck no longer exists.');
    }

    return childActivityFromRows(rows, day: day);
  };

  /// Re-throws stream errors through the domain boundary, so nothing above this
  /// class ever sees a Drift exception.

  Stream<T> _guardStream<T>(Stream<T> source) =>
      source.handleError(_rethrowMapped);

  Never _rethrowMapped(Object error) {
    if (error is Failure) throw error;
    throw mapDatabaseError(error);
  }
}
