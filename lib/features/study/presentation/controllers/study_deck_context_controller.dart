import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/state/retry_policy.dart';
import '../../di/study_repository_provider.dart';
import '../../domain/models/study_deck_context_model.dart';
import '../../domain/usecases/get_study_deck_context_use_case.dart';

part 'study_deck_context_controller.g.dart';

/// The deck a study surface is scoped to, watched.
///
/// **A stream, because the branch never unmounts.**
/// `StatefulShellRoute.indexedStack` keeps Study alive behind the other three
/// tabs, so a `Future` provider here ran once and then held a name the deck no
/// longer had — the screen papered over it with a manual `ref.invalidate` that
/// fired on exactly one path out of the many that can rename a deck.
///
/// **A function provider, not a class, and that is not only style.** The
/// convention this repo enforces is `@Riverpod(retry: noAutomaticRetry)` on
/// every async query, and until this change the guard could only see function
/// providers — which is how a class-shaped one came to be written without the
/// annotation at all. The guard reads both shapes now; this reads like the card
/// feature's `deckContext`, which is the pattern being followed.
///
/// **No automatic retry**: the read is a local SQLite watch. A failure here is a
/// schema or a disk problem, not a flaky network, and retrying it on a timer
/// hides it behind a spinner that never resolves.
@Riverpod(retry: noAutomaticRetry)
Stream<StudyDeckContextModel> studyDeckContext(Ref ref, String deckId) =>
    WatchStudyDeckContextUseCase(ref.watch(studyRepositoryProvider))(deckId);
