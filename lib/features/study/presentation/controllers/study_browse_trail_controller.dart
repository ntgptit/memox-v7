import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/models/study_mode.dart';
import '../states/study_session_state.dart';
import 'study_session_controller.dart';

part 'study_browse_trail_controller.g.dart';

/// How many cards back from the live turn `browse` is looking (BR-155).
///
/// **Its own owner, because looking is not answering.** The session's controller
/// writes: it records answers, moves the cursor, fetches turns. This offset does
/// none of that — the card it puts on screen is already `completed`, no row is
/// rewritten, and coming forward again re-records nothing. The two were one
/// class only because they are used on one screen, and that class then held
/// every command a session has and could not be split at all: Dart has no
/// partial classes, Riverpod's generated base is private, and an extension in a
/// `part` cannot touch `state` either.
///
/// **The offset moves, or the queue does — never both.** Stepping forward from
/// the live turn is an answer, so it goes to [StudySessionController.markBrowsed]
/// rather than being reimplemented here. Keeping that decision in one place is
/// what stops a card being marked browsed twice; a screen deciding it would be
/// deciding it in two gestures.
@riverpod
class StudyBrowseTrailController extends _$StudyBrowseTrailController {
  @override
  int build(String deckId) {
    // **A new card puts the trail back at its front.** The offset counts
    // backwards from the live turn, so one left over from the last card would
    // show a card already walked past in place of the one just arrived — and
    // nothing on screen would say so. It used to be cleared inside the session's
    // fetch; here it belongs to the value it resets.
    ref.listen(studySessionControllerProvider(deckId), (previous, next) {
      if (previous?.turn?.cardId == next.turn?.cardId) return;
      state = 0;
    });

    return 0;
  }

  /// Moves one card along the trail, either way.
  ///
  /// **One name, because from the user's side it is one thing** — the same swipe
  /// with the sign flipped. Two would put the "am I looking at history?" test in
  /// the screen, and the screen would then be what decides whether a card gets
  /// marked browsed, which is how one gets answered twice.
  Future<void> step(StudyBrowseStep direction) {
    final session = ref.read(studySessionControllerProvider(deckId));
    if (session.session?.currentMode != StudyMode.browse || session.isBusy) {
      return Future<void>.value();
    }

    if (direction == StudyBrowseStep.forward &&
        !session.isLookingBackAt(state)) {
      return ref
          .read(studySessionControllerProvider(deckId).notifier)
          .markBrowsed();
    }

    final next = direction == StudyBrowseStep.back ? state + 1 : state - 1;

    // Off either end is a step there is nowhere to take. Clamping silently would
    // read as accepted; returning leaves the card where it is, which is what
    // "refused" looks like.
    if (next < 0 || next > session.seenCardIds.length) {
      return Future<void>.value();
    }

    state = next;

    return Future<void>.value();
  }
}
