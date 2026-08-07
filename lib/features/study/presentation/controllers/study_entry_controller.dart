import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/time/clock_provider.dart';
import '../../di/study_repository_provider.dart';
import '../../domain/models/study_entry_summary_model.dart';
import '../../domain/usecases/watch_study_entry_use_case.dart';

part 'study_entry_controller.g.dart';

/// The counts the study entry point shows (BR-150, BR-154).
///
/// A **query** controller: it reports what the data layer says and holds no
/// command. Opening a session is a write, and a write behind the same state as a
/// read means a failed open would leave the counts showing an error.
@riverpod
class StudyEntry extends _$StudyEntry {
  @override
  Stream<StudyEntrySummaryModel> build(String deckId) => WatchStudyEntryUseCase(
    ref.watch(studyRepositoryProvider),
  ).call(deckId, now: ref.watch(clockProvider)());
}
