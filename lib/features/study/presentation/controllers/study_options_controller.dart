import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/state/retry_policy.dart';
import '../../di/study_repository_provider.dart';
import '../../domain/models/study_options_model.dart';
import '../../domain/usecases/get_study_options_use_case.dart';

part 'study_options_controller.g.dart';

/// The options in force for a deck, already resolved across both tiers.
///
/// The settings screen and the session opener read the same value through the
/// same use case. Two paths that each merged the tiers themselves would be two
/// answers to "what is my card limit", and the screen would be the one that
/// looked right.
@Riverpod(retry: noAutomaticRetry)
Future<StudyOptionsModel> studyOptions(Ref ref, String deckId) =>
    GetStudyOptionsUseCase(ref.watch(studyRepositoryProvider)).call(deckId);
