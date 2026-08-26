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
import '../widgets/sections/card_details_section_widget.dart';
import '../widgets/sections/card_editor_action_bar_widget.dart';
import '../widgets/sections/card_flag_toggle_widget.dart';
import '../widgets/sections/card_sides_fields_widget.dart';
import '../widgets/sections/card_tag_section_widget.dart';
import '../widgets/support/card_failure_labels_widget.dart';

/// The card editor — create and edit (UC-04 W4, A1).
///
/// One screen, two modes, decided by [cardId]: null creates, set edits. What
/// they share is `CardSidesFieldsWidget` and the shell; everything else differs,
/// and this file holds **only edit**. Create lives in `CardCreateFormWidget`
/// with its own controllers, because the two modes used to share five
/// `TextEditingController`s that no single instance ever used twice — the
/// sharing bought nothing at runtime and cost a place for an edit-mode change to
/// land in create.
///
/// Edit's own three facts, in the order they were got wrong:
///
/// - **`Save changes` owns five fields and nothing else.** Tags and the flag
///   write the moment they are touched (BR-92, BR-93), so a Save that lit up for
///   them would promise something it does not carry. It is pinned in the shell's
///   footer rather than in the scroll, where it used to disappear exactly when
///   the user was editing the tags below it.
/// - **Dirty is a comparison, not a flag.** [CardContentDraft] holds the five
///   values as a save would store them; typing a word and deleting it again
///   lands back on pristine, and Save goes dark again with it.
/// - **There is one way out.** The bar's close button and the system back
///   gesture both reach `_handleExitRequest`, so the discard question cannot be
///   answered differently depending on how the user tried to leave.
///
/// **It offers no delete, and that is a decision rather than an omission**
/// (owner review, 2026-08-26). D10 gave a card two ways to be deleted: the
/// list's multi-select, and a block in the editor. The block was a heading and
/// a filled red button at exactly `Save changes`' weight; demoting it to an
/// outline fixed the shouting and left the question of why a full-width
/// destructive action shares a screen whose entire purpose is editing text.
/// UC-04 A2 asks for a delete with a confirmation, not for a delete *here* —
/// A6's multi-select still provides it — so the frozen use case is intact and
/// the editor is a form again.
///
/// It navigates nothing itself: each controller reports an outcome and this
/// widget reacts — because a controller holding a `BuildContext` is the crash
/// `command_query_separation_test.dart` exists to forbid.
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
    // Edit's alone. Create has its own controllers in `CardCreateFormWidget`
    // and no baseline to compare against, so tracking dirtiness there would be
    // five listeners answering a question nobody asks.
    if (widget.cardId == null) return;
    for (final controller in _contentControllers) {
      controller.addListener(_recomputeDirty);
    }
  }

  /// **Unreachable today, and cheap enough to keep that way.** Nothing rebuilds
  /// this screen with a different card: `cardToEditProvider` is a one-shot
  /// future, and go_router keys the page by the matched path, which carries the
  /// resolved id — so card-1 to card-2 is a new element. If that ever changes,
  /// the failure is silent and expensive: the form would keep card A's text and
  /// card A's baseline, and Save would write A's content onto B.
  @override
  void didUpdateWidget(CardEditorScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cardId == widget.cardId) return;
    _prefilled = false;
    _baseline = null;
    _isContentDirty = false;
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

    // **`canPop` tracks the draft rather than sitting at `false`.** One handler
    // still decides everything — the system back gesture and the bar's close
    // button both arrive at `_handleExitRequest`. But a screen that claims the
    // gesture unconditionally suppresses Android's predictive-back preview even
    // when it is going to let the pop through anyway, so a pristine form paid an
    // animation for a question it was never going to ask.
    return PopScope<Object?>(
      canPop: !_hasUnsavedWork,
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
            : CardWriteFailureTextWidget(
                failure: flagState.failure!,
                message: context.l10n.cardEditorFlagFailed,
              ),
        onClose: () => unawaited(_handleExitRequest(cardId)),
        footer: CardEditorActionBarWidget(
          label: context.l10n.cardEditorSaveChanges,
          isSaving: busy,
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
