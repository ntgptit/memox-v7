import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/extensions/app_ink.dart';
import '../../../../../core/theme/foundations/app_spacing.dart';
import '../../../../../core/theme/extensions/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../domain/failures/card_validation_failure.dart';
import '../../../domain/models/deck_context_model.dart';
import '../../states/card_submit_state.dart';
import 'card_editor_context_widget.dart';
import 'card_editor_details_widget.dart';
import 'card_editor_field_widget.dart';
import 'card_tag_section_widget.dart';
import 'card_trash_action_widget.dart';

/// Everything the edit form scrolls: context, the two sides, the optional
/// details, the tags and the Trash card.
///
/// **Split out of `CardEditorScreen` at the 400-line guard, and the seam is a
/// real one.** The screen owns the shell, the controllers and every decision
/// about state — what is dirty, whether leaving costs anything, which command a
/// Save runs. This owns the order things appear in and nothing else: hand it
/// the same values twice and it draws the same column twice.
///
/// It takes the controllers rather than their text because the fields need to
/// *be* controlled, and it takes callbacks rather than a `Notifier` because a
/// widget that reached for the screen's state would be the second place that
/// state lives.
class CardEditorFormWidget extends StatelessWidget {
  const CardEditorFormWidget({
    required this.deckId,
    required this.cardId,
    required this.deckContext,
    required this.onLeave,
    required this.state,
    required this.isBusy,
    required this.front,
    required this.back,
    required this.example,
    required this.hint,
    required this.pronunciation,
    required this.frontFocus,
    required this.isDetailsExpanded,
    required this.onToggleDetails,
    required this.onTagDraftChanged,
    super.key,
  });

  final String deckId;
  final String cardId;
  final AsyncValue<DeckContextModel> deckContext;
  final void Function(VoidCallback navigate) onLeave;
  final CardSubmitState state;
  final bool isBusy;
  final TextEditingController front;
  final TextEditingController back;
  final TextEditingController example;
  final TextEditingController hint;
  final TextEditingController pronunciation;
  final FocusNode frontFocus;
  final bool isDetailsExpanded;
  final VoidCallback onToggleDetails;
  final ValueChanged<bool> onTagDraftChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        CardEditorContextWidget(
          deckId: deckId,
          cardId: cardId,
          deckContext: deckContext,
          onLeave: onLeave,
        ),
        const SizedBox(height: AppSpacing.xl),
        CardEditorFieldWidget(
          label: context.l10n.cardEditorFrontFieldLabel,
          controller: front,
          focusNode: frontFocus,
          maxLength: kCardFrontMaxLength,
          isRequired: true,
          isEnabled: !isBusy,
          maxLines: 3,
          minLines: 1,
          errorText: _frontError(context, state.frontProblem),
          textInputAction: TextInputAction.next,
          // The front is the prompt a learner is shown and the back is the
          // answer, so the two are not equals. The value only: label, counter,
          // error and border stay on the theme, so the two fields still line up
          // on every edge.
          textStyle: context.texts.titleLarge,
        ),
        const SizedBox(height: AppSpacing.lg),
        CardEditorFieldWidget(
          label: context.l10n.cardEditorBackFieldLabel,
          controller: back,
          maxLength: kCardBackMaxLength,
          isRequired: true,
          isEnabled: !isBusy,
          maxLines: 6,
          minLines: 2,
          errorText: _backError(context, state.backProblem),
          // BR-10's reassurance is *about* this field, and as a floating `Text`
          // below it belonged to neither — it read as a heading for whatever
          // came next.
          helperText: context.l10n.cardEditorProgressNote,
        ),
        if (state.failure != null) ...<Widget>[
          const SizedBox(height: AppSpacing.lg),
          // Live, like every other failure on this screen. It is the one
          // furthest from the control that causes it — the button is pinned at
          // the bottom and this paints beside the fields — so a screen-reader
          // user pressed Save and was told nothing at all.
          Semantics(
            liveRegion: true,
            child: Text(
              context.l10n.cardEditorSaveFailed,
              style: context.texts.bodyMedium!.inked(context, AppInk.error),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
        CardEditorDetailsWidget(
          isExpanded: isDetailsExpanded,
          onToggle: onToggleDetails,
          exampleController: example,
          hintController: hint,
          pronunciationController: pronunciation,
          isBusy: isBusy,
          exampleProblem: state.exampleProblem,
          hintProblem: state.hintProblem,
          pronunciationProblem: state.pronunciationProblem,
        ),
        const SizedBox(height: AppSpacing.xl),
        CardTagSectionWidget(cardId: cardId, onDraftChanged: onTagDraftChanged),
        const SizedBox(height: AppSpacing.xl),
        const Divider(height: AppSpacing.xl),
        CardTrashActionWidget(
          deckId: deckId,
          cardId: cardId,
          isDisabled: isBusy,
        ),
      ],
    );
  }

  String? _frontError(BuildContext context, CardValidationProblem? problem) =>
      switch (problem) {
        CardValidationProblem.frontEmpty => context.l10n.cardFrontEmptyError,
        CardValidationProblem.frontTooLong =>
          context.l10n.cardFrontTooLongError,
        _ => null,
      };

  String? _backError(BuildContext context, CardValidationProblem? problem) =>
      switch (problem) {
        CardValidationProblem.backEmpty => context.l10n.cardBackEmptyError,
        CardValidationProblem.backTooLong => context.l10n.cardBackTooLongError,
        _ => null,
      };
}
