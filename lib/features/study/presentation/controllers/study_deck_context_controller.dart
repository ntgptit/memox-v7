import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../di/study_repository_provider.dart';
import '../../domain/models/study_deck_context_model.dart';
import '../../domain/usecases/get_study_deck_context_use_case.dart';

part 'study_deck_context_controller.g.dart';

/// The deck a study surface is scoped to.
///
/// A **query** controller, the same shape as `StudyReviewOptions`: it exists so
/// a screen can name its deck without reading a repository, which
/// `widget_no_repository_access` forbids and has caught here before.
@riverpod
class StudyDeckContext extends _$StudyDeckContext {
  @override
  Future<StudyDeckContextModel> build(String deckId) =>
      GetStudyDeckContextUseCase(ref.watch(studyRepositoryProvider))(deckId);
}
