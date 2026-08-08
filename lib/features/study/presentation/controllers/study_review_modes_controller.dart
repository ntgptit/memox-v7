import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../di/study_repository_provider.dart';
import '../../domain/models/study_mode.dart';
import '../../domain/usecases/get_review_modes_use_case.dart';

part 'study_review_modes_controller.g.dart';

/// The modes a deck offers for review (BR-146).
///
/// A **query** controller, and it exists so the screen stops reading a
/// repository to answer the same question. The guard rule
/// `widget_no_repository_access` catches that, and it caught it here.
@riverpod
class StudyReviewModes extends _$StudyReviewModes {
  @override
  Future<List<StudyMode>> build(String deckId) =>
      GetReviewModesUseCase(ref.watch(studyRepositoryProvider)).call(deckId);
}
