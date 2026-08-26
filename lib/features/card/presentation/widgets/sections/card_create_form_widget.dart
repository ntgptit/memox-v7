import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/state/submit_outcome.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_action_button.dart';
import '../../controllers/card_create_controller.dart';
import '../../states/card_submit_state.dart';
import 'card_details_section_widget.dart';
import 'card_sides_fields_widget.dart';

/// The editor's create mode: two sides, the optional details, and two ways to
/// save (UC-04 W4, A4).
///
/// **It owns its own controllers, and that is the change.** Both modes used to
/// share five `TextEditingController`s held by `CardEditorScreen`, together
/// with the prefill flag, the details toggle and — once edit gained one — the
/// dirty baseline that means nothing here. One instance is only ever one mode,
/// so nothing was actually shared at runtime; what was shared was the *risk*
/// that a change made for one mode would land in the other. The split is a
/// move, not a redesign: every behaviour below is the one create had before.
///
/// The screen still owns `MxContentShell`, so this is a band the screen
/// composes (AD-15) rather than a second screen.
class CardCreateFormWidget extends ConsumerStatefulWidget {
  const CardCreateFormWidget({required this.deckId, super.key});

  final String deckId;

  @override
  ConsumerState<CardCreateFormWidget> createState() =>
      _CardCreateFormWidgetState();
}

class _CardCreateFormWidgetState extends ConsumerState<CardCreateFormWidget> {
  final TextEditingController _front = TextEditingController();
  final TextEditingController _back = TextEditingController();
  final TextEditingController _example = TextEditingController();
  final TextEditingController _hint = TextEditingController();
  final TextEditingController _pronunciation = TextEditingController();
  final FocusNode _frontFocus = FocusNode();

  /// The optional-detail fields start collapsed (W4); nothing here can open
  /// them but a tap, because a new card has no detail to reveal.
  bool _detailsExpanded = false;

  @override
  void dispose() {
    _front.dispose();
    _back.dispose();
    _example.dispose();
    _hint.dispose();
    _pronunciation.dispose();
    _frontFocus.dispose();
    super.dispose();
  }

  void _submit({SubmitDisposition disposition = SubmitDisposition.close}) => ref
      .read(cardCreateProvider(widget.deckId).notifier)
      .submit(
        rawFront: _front.text,
        rawBack: _back.text,
        rawExample: _example.text,
        rawHint: _hint.text,
        rawPronunciation: _pronunciation.text,
        disposition: disposition,
      );

  @override
  Widget build(BuildContext context) {
    final provider = cardCreateProvider(widget.deckId);
    final state = ref.watch(provider);

    ref.listen<CardSubmitState>(provider, (previous, next) {
      if (next.shouldClose && !(previous?.shouldClose ?? false)) {
        Navigator.of(context).pop();

        return;
      }
      // Save-and-add-another: empty the form, return focus to the front, and
      // clear the outcome so the next save is a fresh attempt (UC-04 A4).
      if (next.shouldClearDraft && !(previous?.shouldClearDraft ?? false)) {
        _front.clear();
        _back.clear();
        _example.clear();
        _hint.clear();
        _pronunciation.clear();
        _frontFocus.requestFocus();
        ref.read(provider.notifier).reset();
      }
    });

    final busy = state.isSubmitting;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        CardSidesFieldsWidget(
          frontController: _front,
          backController: _back,
          frontFocusNode: _frontFocus,
          state: state,
          isBusy: busy,
          shouldAutofocus: true,
        ),
        const SizedBox(height: AppSpacing.md),
        CardDetailsSectionWidget(
          isExpanded: _detailsExpanded,
          onToggle: () => setState(() => _detailsExpanded = !_detailsExpanded),
          exampleController: _example,
          hintController: _hint,
          pronunciationController: _pronunciation,
          isBusy: busy,
          exampleProblem: state.exampleProblem,
          hintProblem: state.hintProblem,
          pronunciationProblem: state.pronunciationProblem,
        ),
        const SizedBox(height: AppSpacing.xl),
        MxActionButton(
          label: context.l10n.cardEditorSave,
          onPressed: busy ? null : _submit,
          isLoading: busy,
        ),
        const SizedBox(height: AppSpacing.md),
        MxActionButton(
          label: context.l10n.cardEditorSaveAndAdd,
          variant: MxActionButtonVariant.secondary,
          onPressed: busy
              ? null
              : () => _submit(disposition: SubmitDisposition.addAnother),
        ),
      ],
    );
  }
}
