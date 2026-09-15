import 'package:flutter/material.dart';

import '../../../../../core/theme/extensions/app_ink.dart';
import '../../../../../core/theme/foundations/app_spacing.dart';
import '../../../../../core/theme/extensions/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_card.dart';
import '../../../../../shared/widgets/mx_section_label.dart';
import '../../../domain/models/study_home_resume_model.dart';
import '../support/study_labels_widget.dart';
import '../../../../../shared/widgets/mx_hero_card.dart';

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
    // **S17 is a rule about the card, and `MxHeroCard` is where that gets
    // measured.** This widget is where the trap was found: the first version
    // put the `LayoutBuilder` inside the card's padding, saw the content width
    // — 393 handing it 329, under the 360 tier — and ran the full-width branch
    // on every phone. Both reviews caught it from the arithmetic; the golden
    // had quietly stamped the wrong branch. The shared widget carries that
    // history so the third caller cannot repeat it.
    return MxHeroCard(
      builder: (BuildContext context, bool isCramped) =>
          _ResumeCard(resume: resume, onResume: onResume, isCramped: isCramped),
    );
  }
}

class _ResumeCard extends StatelessWidget {
  const _ResumeCard({
    required this.resume,
    required this.onResume,
    required this.isCramped,
  });

  final StudyHomeResumeModel resume;
  final VoidCallback onResume;

  /// Whether the card is narrower than the compact tier — the width the
  /// stretched primary is for.
  final bool isCramped;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return MxCard.raised(
      // **The same surface as the rows, distinguished by what is on it**
      // (owner brief, 2026-09-08: modern, legible, not colourful).
      //
      // It was `MxCard.tonal`, whose argument was sound and whose execution
      // spent two devices on it at once: a `surfaceEmphasis` fill *and*
      // `AppElevation.none`, so the panel was both the only tinted area and
      // the only unlifted card on a screen of lifted neutral ones. At 353×355
      // it is the largest single area of colour in the app, holding four short
      // lines — which is what made Study Home read heavier than Library while
      // offering less.
      //
      // What tells it apart now is what should have been telling it apart:
      // the `CARRY ON` eyebrow the rows do not have, first position, and the
      // screen's only *filled* button against the rows' outlined `Study`.
      // That is the M3 reading of a primary action, and it survives a
      // greyscale print, which a tint does not. See
      // `docs/reviews/hero-panel-audit.md` §H2.
      //
      // **Its own semantics boundary, stated rather than inherited.** The body
      // used to get one from being a `ListView` child; inside the centred
      // working column that accident is gone, and without `container: true`
      // the card's three lines merge into whatever text stands above it.
      child: Semantics(
        container: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // **The app's one face-label treatment** (D18), not a hand-set
            // `labelMedium`. `MxSectionLabelRung.small` exists for exactly
            // this position — a label on the face of a card — and five other
            // sites already take it, the study prompt's own `QUESTION` among
            // them. Drawn here by hand it was 12sp semibold at `stated`: the
            // same ink and nearly the same weight as the deck name directly
            // under it, so the card opened with two dark bold lines and the
            // eyebrow competed with the thing it was introducing. Quiet caps
            // subordinate it, which is what an eyebrow is for, and the node
            // becomes a `header` a screen reader can jump to — the card had
            // none.
            MxSectionLabel(
              label: l10n.studyHomeResumeTitle,
              rung: MxSectionLabelRung.small,
            ),
            const SizedBox(height: AppSpacing.xs),
            // **`stated`, and now it is trivially right** (SC-C9-04). The pair
            // of lines below took `onSecondaryContainer` once — an ink
            // `app_ink.dart` scopes to "text on a tinted container, never on
            // the page" — while the fill underneath was `MxCard.tonal`'s
            // `semantic.surfaceEmphasis`, ΔE 9.21 away from the ground that
            // ink is measured against. The visible cost was this deck name and
            // the deck name in the rows one section down: the same rung, ΔE
            // 11.82 apart. `stated` closed that to zero on the tint, and the
            // card now paints the rows' own fill, so the two names sit on
            // identical ground as well as in identical ink. `quiet` stays
            // rejected — 4.20:1 in dark, under the floor its own test pins.
            Text(
              resume.deckName,
              style: context.texts.titleMedium!.inked(context, AppInk.stated),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.studyHomeResumeSubtitle(
                context.studySessionKind(resume.kind),
                context.studyMode(resume.currentMode),
              ),
              style: context.texts.bodySmall!.inked(context, AppInk.stated),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.md),
            _ResumeAction(
              resume: resume,
              onResume: onResume,
              isCramped: isCramped,
            ),
          ],
        ),
      ),
    );
  }
}

/// The one primary on the screen, sized by the card it sits in.
///
/// **Full-width on a cramped card, intrinsic on a roomy one** (S17). Below the
/// compact tier the stretched primary is the easier target and the calmer
/// line; at 393/412 an intrinsic button keeps the focal card from reading as a
/// wall of fill.
class _ResumeAction extends StatelessWidget {
  const _ResumeAction({
    required this.resume,
    required this.onResume,
    required this.isCramped,
  });

  final StudyHomeResumeModel resume;
  final VoidCallback onResume;
  final bool isCramped;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return MxHeroPrimary(
      label: l10n.studyHomeResumeAction,
      // Named after the deck for the reason the row buttons are: a screen
      // reader hearing "Resume" alone cannot tell which session it means.
      semanticLabel: l10n.studyHomeResumeSemanticLabel(resume.deckName),
      icon: Icons.play_arrow,
      onPressed: onResume,
      isCramped: isCramped,
    );
  }
}
