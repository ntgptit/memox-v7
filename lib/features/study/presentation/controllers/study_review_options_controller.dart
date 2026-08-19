import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../di/study_repository_provider.dart';
import '../../domain/models/study_review_options_model.dart';
import '../../domain/usecases/get_review_options_use_case.dart';

part 'study_review_options_controller.g.dart';

/// The modes a deck offers for review, and the algorithm they came from
/// (BR-146, BR-203).
///
/// A **query** controller, and it exists so the screen stops reading a
/// repository to answer the same question. The guard rule
/// `widget_no_repository_access` catches that, and it caught it here.
@riverpod
class StudyReviewOptions extends _$StudyReviewOptions {
  @override
  Future<StudyReviewOptionsModel> build(String deckId) =>
      GetReviewOptionsUseCase(ref.watch(studyRepositoryProvider)).call(deckId);
}
