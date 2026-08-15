import 'package:flutter/material.dart';

import '../../../../../core/error/failure.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_action_button.dart';
import '../../../../../shared/widgets/mx_list_tile.dart';
import '../../../domain/failures/study_refusal_failure.dart';
import '../../../domain/models/study_direction_model.dart';
import '../support/study_labels_widget.dart';

/// Picks the way a self-assess review will ask (BR-203).
///
/// **It confirms, it does not act on tap.** A three-option list that started the
/// session on the first touch would give a mis-tap no way back, and the choice
/// is locked for the whole session (BR-207) — the one place in Study where a
/// stray finger costs the learner a session's worth of the wrong exercise. So the
/// options select and a single primary action starts.
///
/// **Selected state is never colour alone.** The leading glyph switches between
/// an empty and a filled radio, which is what a monochrome display and a
/// colour-blind reader both get; `MxListTile`'s `isSelected` tint is the
/// reinforcement, not the signal.
///
/// The three states are the sheet's own: [_StudyDirectionChooserState._isBusy]
/// while the caller's [onSubmit] is in flight — which is also the double-tap
/// guard BR-25 asks of every write path — and a failure line that **keeps the
/// selection**, because losing it would punish the user for an error that was
/// not theirs.
class StudyDirectionChooserWidget extends StatefulWidget {
  const StudyDirectionChooserWidget({
    required this.onSubmit,
    this.initialDirection = kStudyRecommendedDirection,
    super.key,
  });

  /// Starts the review, and resolves to null on success or to the failure that
  /// stopped it.
  ///
  /// **A returned failure rather than a thrown one.** The sheet has to keep
  /// rendering after a refusal, so the caller's error has to arrive as a value it
  /// can hold; an exception crossing a `setState` boundary is how a sheet ends up
  /// half-updated over a screen it no longer matches.
  final Future<Object?> Function(StudySessionDirection) onSubmit;

  /// Which option is selected when the sheet opens.
  ///
  /// Korean→Meaning, because that is what every review did before BR-203 — a
  /// learner who does not engage with the question gets the behaviour they
  /// already have, which is also the one marked Recommended.
  final StudySessionDirection initialDirection;

  @override
  State<StudyDirectionChooserWidget> createState() =>
      _StudyDirectionChooserState();
}

/// The three options, in the order the sheet lists them.
///
/// A constant rather than `StudySessionDirection.values`: that list carries
/// `unknown`, which is a value this build cannot name and must never offer.
const List<StudySessionDirection> kStudyDirectionOptions =
    <StudySessionDirection>[
      StudySessionDirection.koreanToMeaning,
      StudySessionDirection.meaningToKorean,
      StudySessionDirection.mixed,
    ];

class _StudyDirectionChooserState extends State<StudyDirectionChooserWidget> {
  late StudySessionDirection _selected = widget.initialDirection;

  /// True while [StudyDirectionChooserWidget.onSubmit] is open.
  ///
  /// **Local, because nothing above can be quick enough.** Starting a session
  /// pushes a route, and a second tap fits comfortably inside the frame before
  /// that route is on screen (BR-25).
  bool _isBusy = false;

  /// Set when a start was refused; cleared the moment another is attempted.
  Object? _failure;

  Future<void> _submit() async {
    if (_isBusy) return;

    setState(() {
      _isBusy = true;
      _failure = null;
    });

    final failure = await widget.onSubmit(_selected);

    // The sheet is usually gone by now — a successful start pops it — so this is
    // the ordinary path rather than a defensive one.
    if (!mounted) return;

    setState(() {
      _isBusy = false;
      _failure = failure;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final failure = _failure;

    // **Scrollable, and the bottom inset is the sheet's own.** A modal sheet is
    // capped at a fraction of the screen, so three options with two lines each
    // overflow it on a short screen long before a large text scale is involved —
    // and an overflowing sheet hides the Start button, which is the one control
    // the choice needs. `SafeArea` keeps that button clear of the gesture bar.
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(l10n.studyDirectionTitle, style: context.texts.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.studyDirectionBody,
              style: context.texts.bodyMedium?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            for (final option in kStudyDirectionOptions) _tile(context, option),
            if (failure != null) ...<Widget>[
              const SizedBox(height: AppSpacing.md),
              // **A live region, because nothing else says it happened.** The
              // sheet does not move, the focus does not move, and the button
              // simply becomes pressable again — to a screen reader that is
              // indistinguishable from a tap that did nothing.
              Semantics(
                liveRegion: true,
                child: Text(
                  _messageFor(context, failure),
                  style: context.texts.bodyMedium?.copyWith(
                    color: context.colors.error,
                  ),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            MxActionButton(
              label: l10n.studyDirectionStart,
              isLoading: _isBusy,
              shouldKeepLabelWhileLoading: true,
              // **Dead once there is nothing due.** That refusal is not a
              // transient failure: the copy above deliberately does not say
              // "try again", because re-reading finds the same empty queue. A
              // primary button that stays live under a message telling the user
              // to stop says the opposite of the message.
              onPressed: _isNothingDue(context) ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }

  /// What a refusal says, which is not one sentence for both of them.
  ///
  /// **"Try again" is advice, and it has to be advice that can work.** Two
  /// refusals reach this sheet (UC-15 E1 and E2) and only one of them is worth
  /// retrying: a deck whose algorithm changed will not change back by itself,
  /// but the user can leave and come back to a screen that now makes sense —
  /// while a deck with nothing due will not come due by tapping. Telling
  /// somebody to retry the second is telling them to do something that cannot
  /// succeed.
  ///
  /// Anything else keeps the generic line: an unrecognised failure is one this
  /// screen cannot describe, and inventing a cause for it would be worse than
  /// saying only that it did not work.
  /// Whether the last attempt failed because the queue is empty.
  ///
  /// A different question from "did it fail": every other refusal is worth a
  /// second press, and this one never is.
  bool _isNothingDue(BuildContext context) {
    final failure = _failure;

    return failure is Failure &&
        failure.reason == StudyRefusalReason.nothingDueToReview;
  }

  String _messageFor(BuildContext context, Object failure) =>
      failure is Failure &&
          failure.reason == StudyRefusalReason.nothingDueToReview
      ? context.l10n.studyDirectionNothingDue
      : context.l10n.studyDirectionFailed;

  Widget _tile(BuildContext context, StudySessionDirection option) {
    final isSelected = option == _selected;

    return MxListTile(
      title: context.studyDirection(option),
      subtitle: context.studyDirectionDescription(option),
      // The glyph carries the state; the tint only reinforces it.
      leading: Icon(
        isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
        // `primaryAccent`, not `primary`. The glyph is the selection *signal*
        // here — the tile tint is only reinforcement — and `primary` on the
        // selected tile measures **2.45:1** in dark, under the 3:1 WCAG 1.4.11
        // asks of a non-text control. `primaryAccent` reaches 4.66:1. The same
        // decision is already recorded three times: `app_radio_theme.dart`
        // (2.90:1), `match_tile_widget.dart`, `card_details_section_widget.dart`
        // (3.29:1) — this is the fourth call site to reach it.
        color: isSelected ? context.semanticColors.primaryAccent : null,
      ),
      isSelected: isSelected,
      // Locked while a start is in flight, so the choice cannot change under a
      // request already carrying the previous one.
      onTap: _isBusy ? null : () => setState(() => _selected = option),
    );
  }
}
