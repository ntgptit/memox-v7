import 'package:flutter/material.dart';

import '../../../../../core/theme/extensions/app_ink.dart';
import '../../../../../core/theme/foundations/app_spacing.dart';
import '../../../../../core/theme/extensions/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_text_field.dart';
import '../../../domain/failures/card_validation_failure.dart';
import '../../states/card_submit_state.dart';
import 'card_editor_details_widget.dart';
import 'card_editor_field_widget.dart';

/// The editor's create mode: two sides and the optional details (UC-04 W4, A4).
///
/// **Its own file, and still the point — but no longer its own field grammar.**
/// The two modes compose differently on purpose: create has no breadcrumb, no
/// tag strip, no delete, no discard guard and no BR-10 note, so
/// `CardEditorFormWidget` is edit's column and this is create's. What create
/// also had, and should not have, was a second way of drawing the same five
/// card values — Material floating labels against edit's external upper-case
/// label row, the app-wide counter that only speaks near the limit against
/// edit's always-on one, no `Required` marker, and a 16sp front against edit's
/// 22. One semantic field was two sizes depending on which mode you were in
/// (SC-C6-02).
///
/// That split was deliberate while it lasted: edit had been redesigned twice
/// and create had not been reviewed, so letting edit's decisions reach it
/// through a shared builder would have changed a screen nobody had looked at.
/// The app-wide screen-consistency pass is that review, so the fields below now
/// come from `CardEditorFieldWidget` and `CardEditorDetailsWidget` like edit's.
/// What stays create's own is content: a placeholder for each of the five
/// fields, because this form opens empty, and the autofocus on the front.
///
/// **What it does not own is the save.** The two dispositions live in
/// `CardCreateActionBarWidget`, pinned in `MxContentShell.footer` — the pair
/// used to be the last child of this column, inside the scroll, on a screen
/// that autofocuses its first field and so meets the user with the keyboard
/// already up (SC-C1-02). The screen owns the controllers, the submit state and
/// the outcome, exactly as it does for edit; this widget is handed them.
class CardCreateFormWidget extends StatefulWidget {
  const CardCreateFormWidget({
    required this.state,
    required this.isBusy,
    required this.front,
    required this.back,
    required this.example,
    required this.hint,
    required this.pronunciation,
    required this.frontFocus,
    super.key,
  });

  final CardSubmitState state;
  final bool isBusy;
  final TextEditingController front;
  final TextEditingController back;
  final TextEditingController example;
  final TextEditingController hint;
  final TextEditingController pronunciation;
  final FocusNode frontFocus;

  @override
  State<CardCreateFormWidget> createState() => _CardCreateFormWidgetState();
}

class _CardCreateFormWidgetState extends State<CardCreateFormWidget> {
  /// The optional-detail fields start collapsed (W4); nothing here can open
  /// them but a tap, because a new card has no detail to reveal. Opening is
  /// one-way, as it is in edit: `CardEditorDetailsWidget` replaces the
  /// disclosure with the section heading once the three fields are on screen,
  /// so a form the user has begun filling cannot fold itself over their typing.
  bool _detailsExpanded = false;

  String? _frontError(CardValidationProblem? problem) => switch (problem) {
    CardValidationProblem.frontEmpty => context.l10n.cardFrontEmptyError,
    CardValidationProblem.frontTooLong => context.l10n.cardFrontTooLongError,
    _ => null,
  };

  String? _backError(CardValidationProblem? problem) => switch (problem) {
    CardValidationProblem.backEmpty => context.l10n.cardBackEmptyError,
    CardValidationProblem.backTooLong => context.l10n.cardBackTooLongError,
    _ => null,
  };

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final busy = widget.isBusy;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        CardEditorFieldWidget(
          label: context.l10n.cardEditorFrontFieldLabel,
          controller: widget.front,
          focusNode: widget.frontFocus,
          hintText: context.l10n.cardFrontHint,
          maxLength: kCardFrontMaxLength,
          isRequired: true,
          isEnabled: !busy,
          shouldAutofocus: true,
          maxLines: 3,
          minLines: 1,
          errorText: _frontError(state.frontProblem),
          textInputAction: TextInputAction.next,
          // Edit's argument, and it was never edit's alone: the front is the
          // prompt a learner is shown and the back is the answer, so the two
          // are not equals. Stated here rather than left to the default,
          // because inheriting `body` would put the same field at 16 on this
          // mode and 22 on the other — the size split SC-C6-02 measured.
          emphasis: MxTextFieldEmphasis.prominent,
        ),
        const SizedBox(height: AppSpacing.lg),
        CardEditorFieldWidget(
          label: context.l10n.cardEditorBackFieldLabel,
          controller: widget.back,
          hintText: context.l10n.cardBackHint,
          maxLength: kCardBackMaxLength,
          isRequired: true,
          isEnabled: !busy,
          maxLines: 6,
          minLines: 2,
          errorText: _backError(state.backProblem),
          // No BR-10 helper: that sentence reassures an editor that changing
          // the text leaves the card's progress alone, and a card being created
          // has none.
        ),
        if (state.failure != null) ...<Widget>[
          const SizedBox(height: AppSpacing.lg),
          // Live, exactly as edit spells it (`card_editor_form_widget.dart`).
          // The accessibility sweep only ever mounted edit, so the fix that
          // found this — a screen-reader user pressed Save and was told
          // nothing at all — was applied to one mode of one screen and create
          // was never looked at. It is the same sentence, after the same
          // command, at the same distance from the pinned footer that caused
          // it (SC-C3-03).
          Semantics(
            liveRegion: true,
            child: Text(
              context.l10n.cardEditorSaveFailed,
              style: context.texts.bodyMedium!.inked(context, AppInk.error),
            ),
          ),
        ],
        // The two sides end and the optional details begin: a section
        // boundary, so `xl`. It was `md`, which the scale reserves for the
        // inside of a compact control — and edit spells this same seam `xl`
        // (`card_editor_form_widget.dart`), so the two modes were 12 and 24
        // apart at the boundary they share (SC-C2-03).
        const SizedBox(height: AppSpacing.xl),
        CardEditorDetailsWidget(
          isExpanded: _detailsExpanded,
          onToggle: () => setState(() => _detailsExpanded = !_detailsExpanded),
          exampleController: widget.example,
          hintController: widget.hint,
          pronunciationController: widget.pronunciation,
          isBusy: busy,
          exampleProblem: state.exampleProblem,
          hintProblem: state.hintProblem,
          pronunciationProblem: state.pronunciationProblem,
          // The three placeholders create had and edit does not: this form
          // opens empty, so the fields have room to say what they are for.
          examplePlaceholder: context.l10n.cardExampleHint,
          hintPlaceholder: context.l10n.cardHintHint,
          pronunciationPlaceholder: context.l10n.cardPronunciationHint,
          // The last field of create's form (M100.36 9K).
          pronunciationTextInputAction: TextInputAction.done,
        ),
      ],
    );
  }
}
