import '../../domain/models/study_day_model.dart';
import '../../domain/models/study_home_model.dart';
import '../../domain/repositories/study_home_repository.dart';
import '../datasources/study_home_dao.dart';
import '../mappers/study_home_mapper.dart';

/// Study Home's read, wired to SQLite (BR-182).
///
/// **A signal, then one transactional read — not two zipped streams.** The
/// Resume card and the deck list have to describe the same instant (AD-13):
/// zipped, each carries its own snapshot, and a session that ends between them
/// leaves a Resume card offering something the list below it has already counted
/// as finished. One change signal driving one transaction cannot produce that
/// pair.
///
/// **Nothing here writes, including on the repair paths.** A session an earlier
/// study day left open is *excluded* by the query rather than closed by it
/// (BR-103): closing it belongs to `abandonStaleSessions`, which runs when the
/// user actually enters the flow. A Home screen that repaired sessions would
/// write to the database for being scrolled past, and would do it again on every
/// rebuild.
final class StudyHomeRepositoryImpl implements StudyHomeRepository {
  const StudyHomeRepositoryImpl(this._dao);

  final StudyHomeDao _dao;

  @override
  Stream<StudyHomeModel> watchStudyHome(StudyDayModel day) =>
      _dao.watchChanges().asyncMap((_) => _read(day));

  Future<StudyHomeModel> _read(StudyDayModel day) async {
    final snapshot = await _dao.readSnapshot(
      now: day.now,
      startOfToday: day.startOfToday,
      // The same instant, under the name each rule gives it: BR-162 splits the
      // due set at the start of today, and BR-103 calls a session started before
      // it one an earlier study day left open. One boundary, so the two can
      // never be computed from different clock readings.
      dayStart: day.startOfToday,
    );

    return studyHomeFromRows(
      rows: snapshot.decks,
      resume: snapshot.resume,
      day: day,
    );
  }
}
