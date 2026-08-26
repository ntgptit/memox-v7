import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/state/submit_outcome.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_action_button.dart';
import '../../controllers/card_create_controller.dart';
import '../../states/card_submit_state.dart';
import 'card_details_section_widget.dart';
import 'card_editor_fields_widget.dart';

/// The editor's create body: the two sides, the optional details, and the two
/// save paths (UC-04 W4, A4).
///
/// **Split from `card_editor_screen.dart` at the 400-line guard, and the seam
/// is the one the modes already had.** Create and edit share the fields
/// —`CardEditorFieldsWidget` — and nothing else: create has two save paths and
/// no card id, edit has one save path pinned to the bottom of the screen, a
/// dirty check, a delete and a tag section that only exists once a card has an
/// id to hang tags on. Keeping create's draft here means the screen's own
/// controllers belong to edit alone, so neither mode has to ask which one it is
/// before touching them.
///
/// **Its actions stay in the body rather than moving to the shell's pinned
/// bar**, which is where edit's went in the same review. The reason is what the
/// review actually objected to: edit's button sat *above* a tag section that
/// saves on its own, so the order lied about what the button covered. Create's
/// form ends in its two actions with nothing after them, and the second action
/// — save-and-add-another — is a choice between paths rather than a single
/// commit, which a one-button bar cannot express.
///
/// It navigates nothing itself: the controller reports a [SubmitOutcome] and
/// this widget reacts, because a controller holding a `BuildContext` is what
/// `command_query_separation_test.dart` exists to forbid.
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

  /// The optional-detail fields start collapsed (W4); expanding reveals them
  /// (W5).
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

  /// **The notifier is read here, in the callback, and never in `build`.** An
  /// unsubscribed read inside `build` is indistinguishable from a subscription
  /// the widget forgot to make, which is why the guard forbids the shape rather
  /// than the intent.
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

  /// Empties the form and returns focus to the front, for
  /// save-and-add-another (UC-04 A4).
  void _clearDraft() {
    _front.clear();
    _back.clear();
    _example.clear();
    _hint.clear();
    _pronunciation.clear();
    _frontFocus.requestFocus();
    ref.read(cardCreateProvider(widget.deckId).notifier).reset();
  }

  @override
  Widget build(BuildContext context) {
    final provider = cardCreateProvider(widget.deckId);
    final state = ref.watch(provider);

    ref.listen<CardSubmitState>(provider, (previous, next) {
      if (next.shouldClose && !(previous?.shouldClose ?? false)) {
        Navigator.of(context).pop();
        return;
      }
      // Save-and-add-another: the form empties and the outcome clears, so the
      // next save is a fresh attempt (UC-04 A4).
      if (next.shouldClearDraft && !(previous?.shouldClearDraft ?? false)) {
        _clearDraft();
      }
    });

    final busy = state.isSubmitting;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        CardEditorFieldsWidget(
          state: state,
          frontController: _front,
          backController: _back,
          frontFocus: _frontFocus,
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
