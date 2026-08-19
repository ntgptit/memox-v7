import 'dart:async';

import 'package:memox/features/deck/domain/models/scheduler_type_model.dart';
import 'package:memox/features/study/domain/models/study_day_model.dart';
import 'package:memox/features/study/domain/models/study_home_deck_model.dart';
import 'package:memox/features/study/domain/models/study_home_model.dart';
import 'package:memox/features/study/domain/models/study_home_resume_model.dart';
import 'package:memox/features/study/domain/models/study_mode.dart';
import 'package:memox/features/study/domain/models/study_session_kind_model.dart';
import 'package:memox/features/study/domain/repositories/study_home_repository.dart';

/// A `StudyHomeRepository` a controller or widget test drives by hand.
///
/// **It does not simulate SQL.** The workload predicates, the resume filters and
/// the ordering are held to a real SQLite database in
/// `test/features/study/data/study_home_test.dart`; asserting them against a
/// double would be asserting the double. What this exists for is the layer above
/// — which state the screen renders, which action it fires, and whether it
/// re-reads when it should.
///
/// It records every [StudyDayModel] it is asked for, so a test can prove the
/// screen re-read at the instant it claimed to.
final class FakeStudyHomeRepository implements StudyHomeRepository {
  FakeStudyHomeRepository({
    StudyHomeModel? initial,
    this.failure,
    this.isPending = false,
  }) : _controller = StreamController<StudyHomeModel>.broadcast() {
    _latest = initial ?? fakeStudyHome();
  }

  /// Makes the stream fail the way a database error does, so the error state
  /// and its retry can be exercised.
  final Object? failure;

  /// Makes the read never land, which is the only way to hold the loading state
  /// still long enough to assert on it.
  ///
  /// A controller that is never fed, not `Stream.empty()`: an empty stream
  /// closes at once, and a closed stream with no value is a state Riverpod is
  /// entitled to treat differently from one still in flight.
  final bool isPending;

  final StreamController<StudyHomeModel> _controller;
  late StudyHomeModel _latest;

  /// Every day the repository was read for, oldest first.
  final List<StudyDayModel> readDays = <StudyDayModel>[];

  /// How many times a stream was opened — the count a "does not re-read on
  /// scroll" assertion is made against.
  int get subscriptions => readDays.length;

  @override
  Stream<StudyHomeModel> watchStudyHome(StudyDayModel day) {
    readDays.add(day);
    if (isPending) return StreamController<StudyHomeModel>().stream;
    if (failure != null) return Stream<StudyHomeModel>.error(failure!);

    return _controller.stream.startWithLatest(_latest);
  }

  /// Pushes a new snapshot, the way a write elsewhere in the app would.
  void emit(StudyHomeModel model) {
    _latest = model;
    _controller.add(model);
  }

  /// Fails the stream **after** it has already delivered a snapshot.
  ///
  /// Different from [failure], which fails at subscribe: this is the update bus
  /// going wrong under a screen that is already showing data, which the DAO now
  /// forwards rather than swallowing. Whether that turns into an error state or
  /// leaves stale counts on screen is a decision worth pinning.
  void emitError(Object error) => _controller.addError(error);

  Future<void> dispose() => _controller.close();
}

extension on Stream<StudyHomeModel> {
  /// `startWith` without pulling in rxdart, which is not a dependency here.
  Stream<StudyHomeModel> startWithLatest(StudyHomeModel first) async* {
    yield first;
    yield* this;
  }
}

/// A snapshot with sensible defaults, so a test states only what it is about.
StudyHomeModel fakeStudyHome({
  StudyHomeResumeModel? resume,
  List<StudyHomeDeckModel>? decks,
  DateTime? nextDueAt,
  DateTime? nextOverdueTickAt,
}) => StudyHomeModel(
  resume: resume,
  decks:
      decks ??
      <StudyHomeDeckModel>[
        fakeStudyHomeDeck(
          deckId: 'root-a',
          deckName: 'Everyday Korean',
          overdueCount: 2,
          dueTodayCount: 5,
          newCount: 12,
        ),
        fakeStudyHomeDeck(
          deckId: 'root-b',
          deckName: 'Kanji basics',
          schedulerType: SchedulerType.sm2,
          newCount: 3,
        ),
      ],
  nextDueAt: nextDueAt,
  nextOverdueTickAt: nextOverdueTickAt,
);

StudyHomeDeckModel fakeStudyHomeDeck({
  required String deckId,
  required String deckName,
  SchedulerType schedulerType = SchedulerType.eightBox,
  int? totalCardCount,
  int overdueCount = 0,
  int dueTodayCount = 0,
  int newCount = 0,
}) => StudyHomeDeckModel(
  deckId: deckId,
  deckName: deckName,
  schedulerType: schedulerType,
  // Defaults to a deck big enough to hold its own workload, so a test that
  // states counts never accidentally produces the "no cards" state — which is a
  // different screen (BR-202).
  totalCardCount:
      totalCardCount ?? (overdueCount + dueTodayCount + newCount + 10),
  overdueCount: overdueCount,
  dueTodayCount: dueTodayCount,
  newCount: newCount,
);

StudyHomeResumeModel fakeStudyHomeResume({
  String sessionId = 'session-1',
  String deckId = 'root-a',
  String deckName = 'Everyday Korean',
  StudySessionKind kind = StudySessionKind.reviewing,
  StudyMode currentMode = StudyMode.selfAssess,
}) => StudyHomeResumeModel(
  sessionId: sessionId,
  deckId: deckId,
  deckName: deckName,
  kind: kind,
  currentMode: currentMode,
);
