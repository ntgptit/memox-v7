import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/time/clock_provider.dart';
import '../../../../core/time/time_zone_provider.dart';
import '../../di/study_repository_provider.dart';
import '../../domain/entities/study_session_entity.dart';
import '../../domain/usecases/resume_study_day_use_case.dart';

part 'study_resume_controller.g.dart';

/// Today's still-open session, if there is one (BR-103).
///
/// Reading it also closes any session left by an **earlier** study day, as
/// `abandoned`/`interrupted` — that is one call on purpose, because the second
/// question has to be asked after the first write. Split, a caller can run them
/// backwards and offer to resume a session it just closed.
@riverpod
class StudyResume extends _$StudyResume {
  @override
  Future<StudySessionEntity?> build(String deckId) =>
      ResumeStudyDayUseCase(ref.watch(studyRepositoryProvider)).call(
        deckId: deckId,
        now: ref.watch(clockProvider)(),
        utcOffset: ref.watch(utcOffsetProvider)(),
      );
}
