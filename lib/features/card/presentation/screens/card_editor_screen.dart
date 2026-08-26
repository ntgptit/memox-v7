import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/l10n_extension.dart';
import '../../../../shared/widgets/mx_content_shell.dart';
import '../../../../shared/widgets/mx_empty_state.dart';
import '../../../../shared/widgets/mx_icon_button.dart';
import '../../domain/entities/card_entity.dart';
import '../controllers/card_editor_load_controller.dart';
import '../controllers/card_flag_controller.dart';
import '../controllers/card_write_controller.dart';
import '../states/card_content_draft_state.dart';
import '../states/card_submit_state.dart';
import '../widgets/overlays/card_discard_confirm_widget.dart';
import '../widgets/sections/card_create_form_widget.dart';
import '../widgets/sections/card_delete_action_widget.dart';
import '../widgets/sections/card_details_section_widget.dart';
import '../widgets/sections/card_editor_action_bar_widget.dart';
import '../widgets/sections/card_flag_toggle_widget.dart';
import '../widgets/sections/card_sides_fields_widget.dart';
import '../widgets/support/card_failure_labels_widget.dart';
import '../widgets/sections/card_tag_section_widget.dart';

/// The card editor — create and edit (UC-04 W4, A1).
///
/// One screen, two modes, decided by [cardId]: null creates, set edits. The two
/// share the front/back fields and the inline validation; they differ in title,
/// in the save paths (create offers save-and-add-another, edit does not), and in
/// what sits below the fields (edit adds a BR-10 reassurance and a danger zone).
///
/// It navigates nothing itself: each controller reports a [SubmitOutcome] and
/// this widget reacts — pop on `savedAndClose`, clear the form on
/// `savedAndContinue` — because a controller holding a `BuildContext` is the
/// crash `command_query_separation_test.dart` exists to forbid.
class CardEditorScreen extends ConsumerStatefulWidget {
  const CardEditorScreen({required this.deckId, this.cardId, super.key});

  final String deckId;

  /// Null in create mode; the card being edited otherwise.
  final String? cardId;

  @override
  ConsumerState<CardEditorScreen> createState() => _CardEditorScreenState();
}

class _CardEditorScreenState extends ConsumerState<CardEditorScreen> {
  final TextEditingController _front = TextEditingController();
  final TextEditingController _back = TextEditingController();
  final TextEditingController _example = TextEditingController();
  final TextEditingController _hint = TextEditingController();
  final TextEditingController _pronunciation = TextEditingController();
  final FocusNode _frontFocus = FocusNode();

  /// Edit mode fills the fields once, when the card first arrives — re-filling
  /// on every rebuild would overwrite what the user is typing.
  bool _prefilled = false;

  /// The optional-detail fields start collapsed (W4); a card that already has a
  /// detail opens them expanded (W5).
  bool _detailsExpanded = false;

  /// The five content values as they stood when the card was loaded, already
  /// normalised the way a save would store them.
  ///
  /// **Null until the prefill runs, and that is what makes the prefill safe.**
  /// Assigning to a `TextEditingController` fires its listeners synchronously,
  /// and the prefill happens inside `build`; with no baseline yet the listener
  /// returns before it can reach `setState`, so the one thing that must never
  /// happen during a build cannot.
  CardContentDraft? _baseline;

  /// Whether the five content fields differ from [_baseline].
  ///
  /// **Only these five.** `Save changes` calls `CardEdit.submit` with front,
  /// back, example, hint and pronunciation and nothing else; tags and the flag
  /// are written the moment they are touched (BR-92, BR-93). A save button lit
  /// by a tag would be offering to save something it does not carry.
  bool _isContentDirty = false;

  /// A tag typed into the add field but not committed.
  ///
  /// It is work, so it arms the exit guard — and it is **not** the save
  /// button's, so it stays out of [_isContentDirty]. Those two sentences are
  /// the whole reason this is a second flag rather than folded into the first.
  bool _hasTagDraft = false;

  /// One discard dialog at a time. Android's back gesture is easy to fire twice
  /// and `PopScope` reports both, so without this the user answers the same
  /// question to two stacked dialogs.
  bool _isDiscardOpen = false;

  bool get _hasUnsavedWork => _isContentDirty || _hasTagDraft;

  @override
  void initState() {
    super.initState();
    for (final controller in _contentControllers) {
      controller.addListener(_recomputeDirty);
    }
  }

  @override
  void dispose() {
    for (final controller in _contentControllers) {
      controller.removeListener(_recomputeDirty);
    }
    _front.dispose();
    _back.dispose();
    _example.dispose();
    _hint.dispose();
    _pronunciation.dispose();
    _frontFocus.dispose();
    super.dispose();
  }

  List<TextEditingController> get _contentControllers =>
      <TextEditingController>[_front, _back, _example, _hint, _pronunciation];

  CardContentDraft get _draft => CardContentDraft(
    front: _front.text,
    back: _back.text,
    example: _example.text,
    hint: _hint.text,
    pronunciation: _pronunciation.text,
  );

  /// Recomputes [_isContentDirty] from the baseline, on every keystroke.
  ///
  /// Comparing snapshots rather than tracking "has been edited" is what makes
  /// typing a word and deleting it again land back on pristine — which is the
  /// state the user is actually in, and the state a "has been edited" boolean
  /// can never return to.
  void _recomputeDirty() {
    final baseline = _baseline;
    if (baseline == null) return;
    final isDirty = baseline != _draft;
    if (isDirty == _isContentDirty) return;
    setState(() => _isContentDirty = isDirty);
  }

  void _onTagDraftChanged(bool hasDraft) {
    if (hasDraft == _hasTagDraft) return;
    setState(() => _hasTagDraft = hasDraft);
  }

  Widget _detailsSection(CardSubmitState state, {required bool busy}) =>
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
      );

  @override
  Widget build(BuildContext context) {
    final cardId = widget.cardId;
    if (cardId != null) return _buildEdit(context, cardId);

    return MxContentShell(
      title: context.l10n.cardEditorCreateTitle,
      leading: _closeButton(context, _pop),
      isScrollable: true,
      body: CardCreateFormWidget(deckId: widget.deckId),
    );
  }

  // ---- edit --------------------------------------------------------------

  Widget _buildEdit(BuildContext context, String cardId) {
    final loaded = ref.watch(cardToEditProvider(cardId));

    return loaded.when(
      loading: () => _shell(
        context,
        title: context.l10n.cardEditorEditTitle,
        body: Center(
          child: Semantics(
            label: context.l10n.cardEditorLoadingLabel,
            child: const CircularProgressIndicator(),
          ),
        ),
      ),
      error: (error, stackTrace) => _shell(
        context,
        title: context.l10n.cardEditorEditTitle,
        body: MxEmptyState(
          icon: Icons.error_outline,
          title: context.l10n.cardEditorLoadFailed,
          actionLabel: context.l10n.cardEditorLoadRetry,
          onAction: () => Navigator.of(context).pop(),
        ),
      ),
      data: (card) => _buildEditForm(context, cardId, card),
    );
  }

  Widget _buildEditForm(BuildContext context, String cardId, CardEntity card) {
    _prefillOnce(card);

    final provider = cardEditProvider(cardId);
    final state = ref.watch(provider);
    final flagState = ref.watch(setCardFlagProvider(cardId));
    final controller = ref.read(provider.notifier);

    ref.listen<CardSubmitState>(provider, (previous, next) {
      if (next.shouldClose && !(previous?.shouldClose ?? false)) {
        _leaveAfterSave();
      }
    });

    final busy = state.isSubmitting;

    // `canPop: false` and one handler: the system back gesture and the bar's
    // close button both arrive here, so exactly one place decides whether
    // leaving costs the user anything.
    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        unawaited(_handleExitRequest(cardId));
      },
      child: _shell(
        context,
        title: context.l10n.cardEditorEditTitle,
        actions: <Widget>[
          CardFlagToggleWidget(
            cardId: cardId,
            onToggle: flagState.isSubmitting
                ? null
                : (isFlagged) => ref
                      .read(setCardFlagProvider(cardId).notifier)
                      .submit(isFlagged: !isFlagged),
          ),
        ],
        subheader: flagState.failure == null
            ? null
            : CardWriteFailureTextWidget(failure: flagState.failure!),
        onClose: () => unawaited(_handleExitRequest(cardId)),
        footer: CardEditorActionBarWidget(
          label: context.l10n.cardEditorSaveChanges,
          isLoading: busy,
          // Disabled on a pristine form: a Save that is always pressable says
          // nothing about whether there is anything to save, and pressing it
          // writes the card back over itself.
          onSave: busy || !_isContentDirty
              ? null
              : () => controller.submit(
                  rawFront: _front.text,
                  rawBack: _back.text,
                  rawExample: _example.text,
                  rawHint: _hint.text,
                  rawPronunciation: _pronunciation.text,
                ),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            CardSidesFieldsWidget(
              frontController: _front,
              backController: _back,
              frontFocusNode: _frontFocus,
              state: state,
              isBusy: busy,
              backHelperText: context.l10n.cardEditorProgressNote,
            ),
            const SizedBox(height: AppSpacing.md),
            _detailsSection(state, busy: busy),
            const SizedBox(height: AppSpacing.xl),
            CardTagSectionWidget(
              cardId: cardId,
              onDraftChanged: _onTagDraftChanged,
            ),
            const SizedBox(height: AppSpacing.xxl),
            CardDeleteActionWidget(
              deckId: widget.deckId,
              cardId: cardId,
              isDisabled: busy,
            ),
          ],
        ),
      ),
    );
  }

  void _prefillOnce(CardEntity card) {
    if (_prefilled) return;
    _front.text = card.front;
    _back.text = card.back;
    _example.text = card.example ?? '';
    _hint.text = card.hint ?? '';
    _pronunciation.text = card.pronunciation ?? '';
    // Open the details already if this card has any — so an existing detail is
    // visible without hunting for the toggle (W5). Presentation only: opening
    // the disclosure changes no value, so it does not make the form dirty.
    _detailsExpanded =
        card.example != null || card.hint != null || card.pronunciation != null;
    // **After the assignments, not before.** Each one fires the dirty listener;
    // with the baseline still null they all return early, so this runs during a
    // build without a `setState` in it. Taking the snapshot from the
    // controllers rather than from `card` also means the baseline is whatever
    // the fields actually hold.
    _baseline = _draft;
    _prefilled = true;
  }

  /// The one way out of the edit form, whichever affordance asked.
  ///
  /// Async, and every early return is a case that must **not** pop: a save in
  /// flight, because the write would land on a screen that is gone, and a
  /// dialog already asking this question.
  Future<void> _handleExitRequest(String cardId) async {
    if (ref.read(cardEditProvider(cardId)).isSubmitting) return;
    if (_isDiscardOpen) return;
    if (!_hasUnsavedWork) {
      _pop();

      return;
    }

    _isDiscardOpen = true;
    final shouldDiscard = await showCardEditorDiscardConfirm(context);
    if (!mounted) return;
    _isDiscardOpen = false;
    // `Keep editing` returns false and does nothing at all — no clearing, no
    // refocusing — which is what leaves the draft, the focus and the scroll
    // exactly where the user left them.
    if (!shouldDiscard) return;
    _pop();
  }

  /// Leaves after a successful write.
  ///
  /// The baseline moves to the saved text first, so anything that re-enters the
  /// exit path during the pop sees a pristine form rather than asking the user
  /// to discard the changes they just saved.
  void _leaveAfterSave() {
    _baseline = _draft;
    _isContentDirty = false;
    _pop();
  }

  /// **`pop`, not `maybePop`.** `PopScope` intercepts `maybePop` and the system
  /// gesture; a direct pop is the deliberate exit this screen has already
  /// authorised, so routing it back through the guard would ask the question a
  /// second time.
  void _pop() => Navigator.of(context).pop();

  // ---- shared ------------------------------------------------------------

  Widget _shell(
    BuildContext context, {
    required String title,
    required Widget body,
    List<Widget>? actions,
    Widget? subheader,
    Widget? footer,
    VoidCallback? onClose,
  }) => MxContentShell(
    title: title,
    leading: _closeButton(context, onClose ?? _pop),
    actions: actions,
    subheader: subheader,
    footer: footer,
    isScrollable: true,
    body: body,
  );

  /// **[onClose], not a bare pop.** In edit mode this is the same coordinator
  /// the system back gesture reaches, which is the whole reason the discard
  /// question cannot be answered differently depending on how the user tried to
  /// leave. Create mode and the load/error faces have no draft to protect and
  /// pass the plain pop.
  Widget _closeButton(BuildContext context, VoidCallback onClose) =>
      MxIconButton(
        icon: Icons.close,
        semanticLabel: context.l10n.cardEditorClose,
        onPressed: onClose,
      );
}
