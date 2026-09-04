import 'package:flutter/material.dart';

import '../../../../../core/theme/extensions/app_ink.dart';
import '../../../../../core/theme/foundations/app_spacing.dart';
import '../../../../../core/theme/extensions/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_content_shell.dart';
import '../../../../../shared/widgets/mx_empty_state.dart';
import '../../../domain/models/study_home_deck_model.dart';
import '../../../domain/models/study_home_model.dart';
import '../items/study_home_deck_item_widget.dart';
import 'study_home_resume_section_widget.dart';
import '../../../../../shared/widgets/mx_section_label.dart';
import '../../../../../shared/widgets/mx_reading_column.dart';

/// Study Home once its read has landed: the two empty states, or the list.
///
/// **Three loaded states, not one with holes in it** (BR-202). "No decks at
/// all", "decks but no cards" and "decks with cards" have different next steps —
/// ready-made content, the library, and a session — so each gets a screen that
/// names its own. Collapsing the first two into one message would send somebody
/// who already has four decks to a catalog they do not need.
///
/// **Nothing pending is not a fourth state.** A library where every deck is
/// caught up still shows the list: BR-29 makes a quiet schedule the product
/// working rather than a locked door, the decks are still openable (BR-201), and
/// hiding them would leave the tab looking broken on the day the user has done
/// everything.
class StudyHomeBodySectionWidget extends StatelessWidget {
  const StudyHomeBodySectionWidget({
    required this.home,
    required this.onResume,
    required this.onStudy,
    required this.onStarterLibrary,
    required this.onOpenLibrary,
    super.key,
  });

  final StudyHomeModel home;

  /// Continues the open session. Never null when [StudyHomeModel.resume] is
  /// present, and never called when it is absent.
  final VoidCallback onResume;

  final ValueChanged<StudyHomeDeckModel> onStudy;
  final VoidCallback onStarterLibrary;
  final VoidCallback onOpenLibrary;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    if (home.isLibraryEmpty) {
      return MxEmptyState(
        // Not the default check-mark: that glyph says "you have finished
        // everything", which is the opposite of what an empty library means.
        icon: Icons.folder_outlined,
        title: l10n.studyHomeEmptyLibraryTitle,
        message: l10n.studyHomeEmptyLibraryMessage,
        // **Ready-made content leads** (UC-01). Production seeds nothing, so
        // this is a real first-run screen and a person who installed a flashcard
        // app wants cards rather than an empty folder. The library stays one tap
        // away as the quieter second path.
        actionLabel: l10n.studyHomeStarterAction,
        onAction: onStarterLibrary,
        secondaryActionLabel: l10n.studyHomeOpenLibraryAction,
        onSecondaryAction: onOpenLibrary,
      );
    }

    if (home.hasNoCards) {
      return MxEmptyState(
        icon: Icons.style_outlined,
        title: l10n.studyHomeNoCardsTitle,
        message: l10n.studyHomeNoCardsMessage,
        // The library, not the catalog: the decks already exist, so what is
        // missing is cards inside them, and that is where cards are added.
        actionLabel: l10n.studyHomeOpenLibraryAction,
        onAction: onOpenLibrary,
      );
    }

    return _StudyHomeList(home: home, onResume: onResume, onStudy: onStudy);
  }
}

/// The scrolling body: the resume offer, then the ranked decks.
class _StudyHomeList extends StatelessWidget {
  const _StudyHomeList({
    required this.home,
    required this.onResume,
    required this.onStudy,
  });

  final StudyHomeModel home;
  final VoidCallback onResume;
  final ValueChanged<StudyHomeDeckModel> onStudy;

  @override
  Widget build(BuildContext context) {
    return ListView(
      // The gutter is applied here rather than by the shell so the scroll runs
      // edge to edge — content passes under the app-bar hairline instead of
      // stopping short of it — and so the last card keeps clearance above the
      // bottom bar at the *end* of the scroll.
      // Sides take the screen gutter; the step under the last row is `lg`
      // at every width, the same as the deck list and Progress (M99.26).
      padding: EdgeInsets.fromLTRB(
        mxScreenGutter(context),
        mxScreenGutter(context),
        mxScreenGutter(context),
        AppSpacing.lg,
      ),
      children: <Widget>[
        // **A working column, not a full-bleed one.** On a phone this binds
        // nothing — 600 is above every width the app ships against — but a
        // row of task cards stretched across a tablet is a line nobody can
        // track back to the start of. The same ceiling Card Detail caps its
        // reading column at, and a ceiling rather than a branch: below it the
        // layout is identical everywhere (AppBreakpoints.medium's own rule).
        Center(
          child: MxReadingColumn(
            child: _StudyHomeColumn(
              home: home,
              onResume: onResume,
              onStudy: onStudy,
            ),
          ),
        ),
      ],
    );
  }
}

/// The column the ceiling wraps: supporting copy, the resume offer, the
/// heading, then the ranked decks.
class _StudyHomeColumn extends StatelessWidget {
  const _StudyHomeColumn({
    required this.home,
    required this.onResume,
    required this.onStudy,
  });

  final StudyHomeModel home;
  final VoidCallback onResume;
  final ValueChanged<StudyHomeDeckModel> onStudy;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final decks = home.studiableDecks;
    final resume = home.resume;
    final hasWork = decks.any((deck) => deck.hasWorkload);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          // **Two lines, chosen by whether there is anything to carry on
          // from.** One line saying "pick a deck, or carry on where you
          // stopped" renders above a screen with no Resume card in the common
          // case — BR-200 needs four conditions at once, so no open session is
          // the ordinary state, not the exception.
          resume == null
              ? l10n.studyHomeSupportingCopyNoResume
              : l10n.studyHomeSupportingCopy,
          style: context.texts.bodyMedium!.inked(context, AppInk.quiet),
        ),
        if (resume != null) ...<Widget>[
          const SizedBox(height: AppSpacing.lg),
          StudyHomeResumeSectionWidget(resume: resume, onResume: onResume),
        ],
        // `xl` above the heading: this is a break between two sections — what
        // you were doing, and what you could do next — and a section break that
        // used the gap between two cards would make the heading read as a row.
        const SizedBox(height: AppSpacing.xl),
        // **A heading, declared.** The `xl` above it builds the section break
        // visually; without `header: true` that break is invisible to a screen
        // reader, which hears the Resume card run straight into the first deck
        // and cannot jump by heading at all.
        // **The app's one section-label treatment**, now the component
        // (A20.1 P2-02): caps at paint, the written sentence as the header's
        // name. Its own boundary — the heading used to inherit one from being
        // a `ListView` child, and merged into the resume card's text without
        // it now that the column is one child.
        Semantics(
          container: true,
          child: MxSectionLabel(label: l10n.studyHomeNextTitle),
        ),
        if (!hasWork) ...<Widget>[
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.studyHomeNothingDueMessage,
            style: context.texts.bodySmall!.inked(context, AppInk.quiet),
          ),
        ],
        // **The gap leads each row rather than trailing it**, so the list ends
        // on the last card and the clearance above the bottom bar is exactly the
        // list's own bottom padding. Trailing it added a step nothing in the
        // geometry contract accounted for, and made the clearance two numbers.
        for (final deck in decks) ...<Widget>[
          const SizedBox(height: AppSpacing.md),
          StudyHomeDeckItemWidget(deck: deck, onStudy: () => onStudy(deck)),
        ],
      ],
    );
  }
}
