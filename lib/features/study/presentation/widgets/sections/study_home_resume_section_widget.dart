import 'package:flutter/material.dart';

import '../../../../../core/theme/app_ink.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_action_button.dart';
import '../../../../../shared/widgets/mx_card.dart';
import '../../../domain/models/study_home_resume_model.dart';
import '../support/study_labels_widget.dart';

/// The session already open, offered back — and nothing else (BR-200, BR-103).
///
/// **First on the screen, because it is the only row that is about something the
/// user has already started.** A list of decks under it offers new work; this
/// offers work in progress, and burying it would ask somebody to find their own
/// half-finished session among things they have not begun.
///
/// **It never appears speculatively.** The widget is built only when the read
/// found a session that is still `in_progress`, belongs to today's study day,
/// sits on a root whose generation has not moved, and still has a queue — every
/// one of those checked in SQL, so a Resume on screen is a Resume that works.
/// Nothing here creates or repairs a session (BR-101).
///
/// **The kind and the stage are the session's own** (BR-76, BR-98). Both are
/// stored columns, never inferred: a resumed `reviewing` session holds one mode
/// for its whole life, and guessing it would hand the learner a different
/// exercise from the one they walked away from.
class StudyHomeResumeSectionWidget extends StatelessWidget {
  const StudyHomeResumeSectionWidget({
    required this.resume,
    required this.onResume,
    super.key,
  });

  final StudyHomeResumeModel resume;
  final VoidCallback onResume;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return MxCard.tonal(
      // The one surface on this screen that steps away from `surface`: it is a
      // different kind of offer from the rows under it, and the pair only reads
      // as a pair if one of them is distinguishable at a glance.
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            l10n.studyHomeResumeTitle,
            // Through the wght axis — a bare `fontWeight:` paints the rung's
            // old weight.
            style: context.texts.labelMedium!.inked(
              context,
              AppInk.onSecondaryContainer,
              isEmphasized: true,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            resume.deckName,
            style: context.texts.titleMedium!.inked(
              context,
              AppInk.onSecondaryContainer,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.studyHomeResumeSubtitle(
              context.studySessionKind(resume.kind),
              context.studyMode(resume.currentMode),
            ),
            style: context.texts.bodySmall!.inked(
              context,
              AppInk.onSecondaryContainer,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.md),
          Align(
            alignment: AlignmentDirectional.centerStart,
            // Named after the deck for the reason the row buttons are: a screen
            // reader hearing "Resume" alone cannot tell which session it means.
            child: MxActionButton(
              label: l10n.studyHomeResumeAction,
              semanticLabel: l10n.studyHomeResumeSemanticLabel(resume.deckName),
              icon: Icons.play_arrow,
              onPressed: onResume,
            ),
          ),
        ],
      ),
    );
  }
}
