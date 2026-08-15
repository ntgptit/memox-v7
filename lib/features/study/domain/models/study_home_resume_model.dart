import 'package:freezed_annotation/freezed_annotation.dart';

import 'study_mode.dart';
import 'study_session_kind_model.dart';

part 'study_home_resume_model.freezed.dart';

/// The session Study Home offers to continue, when there is one (BR-200).
///
/// **It describes a session that already exists; it never asks for one.** A
/// session is created only because the user asked (BR-101), so nothing on this
/// type is derived from "what is due right now" — [sessionId] names a row that
/// was written when somebody tapped Study, and [kind] and [currentMode] are that
/// row's own, carried so the screen can name the stage before the session screen
/// has finished loading it.
///
/// **Absence is the interesting half.** A session that ended, one an earlier
/// study day left open (BR-103), one whose root has since been reset (BR-84),
/// one whose deck or cards are gone — all of them resolve to no resume at all
/// rather than to a card that fails when tapped. The filtering is a read, in
/// `studyHomeResumeCandidate`; Home writes nothing to reach this state.
@freezed
abstract class StudyHomeResumeModel with _$StudyHomeResumeModel {
  const factory StudyHomeResumeModel({
    required String sessionId,

    /// The deck the session was opened on — a root, or a branch inside one.
    required String deckId,

    /// That deck's name, from the same statement as everything else (AD-13). A
    /// second read for one string is a second snapshot, and a rename landing
    /// between them shows one deck under two names on one screen.
    required String deckName,

    required StudySessionKind kind,

    /// The stage the session stopped in (BR-98). Stored on the session, never
    /// inferred: a resumed `reviewing` session holds one mode for its whole
    /// life, and guessing it would hand the user a different exercise from the
    /// one they left.
    required StudyMode currentMode,
  }) = _StudyHomeResumeModel;
}
