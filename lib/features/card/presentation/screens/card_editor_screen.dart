import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/state/submit_outcome.dart';
import '../../../../l10n/l10n_extension.dart';
import '../../../../shared/widgets/mx_content_shell.dart';
import '../../../../shared/widgets/mx_icon_button.dart';
import '../../domain/entities/card_entity.dart';
import '../controllers/card_create_controller.dart';
import '../controllers/card_editor_load_controller.dart';
import '../controllers/card_flag_controller.dart';
import '../controllers/card_write_controller.dart';
import '../controllers/deck_context_controller.dart';
import '../states/card_content_draft_state.dart';
import '../states/card_submit_state.dart';
import '../widgets/overlays/card_discard_confirm_widget.dart';
import '../widgets/sections/card_create_action_bar_widget.dart';
import '../widgets/sections/card_create_form_widget.dart';
import '../widgets/sections/card_editor_action_bar_widget.dart';
import '../widgets/sections/card_editor_form_widget.dart';
import '../widgets/sections/card_editor_save_shortcut_widget.dart';
import '../widgets/sections/card_flag_toggle_widget.dart';
import '../widgets/support/card_failure_labels_widget.dart';
import '../../../../shared/widgets/mx_loading_state.dart';
import '../../../../shared/widgets/mx_error_state.dart';

/// The card editor — create and edit (UC-04 W4, A1).
///
/// One screen, two modes, decided by [cardId]. It owns the shell, the five
/// content controllers and the submit state in both; what the body *contains*
/// is a mode's own — `CardEditorFormWidget` draws edit's, `CardCreateFormWidget`
/// draws create's, and neither reads the other. That split is what stops a
/// decision taken for edit landing on a screen nobody has reviewed, which is
/// what happened the last time the two shared one field builder.
///
/// Four facts, in the order they were got wrong:
///
/// - **Save owns five fields and nothing else.** Tags and the flag write the
///   moment they are touched (BR-92, BR-93); a Save lit by them would promise
///   what it does not carry. It is pinned in the footer, not in the scroll —
///   in **both** modes: create's pair sat at the end of the scroll on a screen
///   that autofocuses its first field, so the keyboard covered the primary
///   action from the first frame (SC-C1-02).
/// - **Two affordances, one command.** The app bar carries a compact `Save`;
///   it and the footer read the same dirty state and call the same `_save()`.
///   Only the footer spins — two spinners read as two operations.
/// - **Dirty is a comparison.** [CardContentDraft] holds the five values as a
///   save would store them, so typing a word and deleting it lands on pristine.
/// - **There is one way out.** The back arrow, Cancel, the system gesture *and
///   every breadcrumb crumb* reach `_handleExitRequest`. The crumbs were the
///   ones that did not, and they dropped drafts silently.
///
/// It navigates nothing itself: controllers report outcomes and this widget
/// reacts — a controller holding a `BuildContext` is the crash
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

  bool _isContentDirty = false;
  bool _hasTagDraft = false;

  /// One discard dialog at a time. Android's back gesture is easy to fire twice
  /// and `PopScope` reports both, so without this the user answers the same
  /// question to two stacked dialogs.
  bool _isDiscardOpen = false;

  bool get _hasUnsavedWork => _isContentDirty || _hasTagDraft;

  @override
  void initState() {
    super.initState();
    // Edit's alone. Create shares the controllers but has no baseline to
    // compare against — it saves whatever is typed and closes — so tracking
    // dirtiness there would be five listeners answering a question nobody asks.
    if (widget.cardId == null) return;
    for (final controller in _contentControllers) {
      controller.addListener(_recomputeDirty);
    }
  }

  /// **Unreachable today, and cheap enough to keep that way.** Nothing rebuilds
  /// this screen with a different card: `cardToEditProvider` is a one-shot
  /// future, and go_router keys the page by the matched path, which carries the
  /// resolved id. If that ever changes, the failure is silent and expensive:
  /// the form would keep card A's text and card A's baseline, and Save would
  /// write A's content onto B.
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
      controller
        ..removeListener(_recomputeDirty)
        ..dispose();
    }
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

  @override
  Widget build(BuildContext context) {
    final cardId = widget.cardId;
    if (cardId != null) return _buildEdit(context, cardId);

    return _buildCreate(context);
  }

  // ---- create ------------------------------------------------------------

  /// Create's shell: no breadcrumb, no tags, no discard guard — and the two
  /// dispositions pinned in [MxContentShell.footer] rather than sitting at the
  /// end of the scroll. The front field autofocuses, so the keyboard is up on
  /// the first frame and the body has already shrunk; a Save inside that scroll
  /// starts off screen, which is the failure the footer slot was added to fix
  /// (SC-C1-02).
  Widget _buildCreate(BuildContext context) {
    final provider = cardCreateProvider(widget.deckId);
    final state = ref.watch(provider);

    ref.listen<CardSubmitState>(provider, (previous, next) {
      if (next.shouldClose && !(previous?.shouldClose ?? false)) {
        _pop();

        return;
      }
      // Save-and-add-another: empty the form, return focus to the front, and
      // clear the outcome so the next save is a fresh attempt (UC-04 A4).
      if (next.shouldClearDraft && !(previous?.shouldClearDraft ?? false)) {
        for (final controller in _contentControllers) {
          controller.clear();
        }
        _frontFocus.requestFocus();
        ref.read(provider.notifier).reset();
      }
    });

    final busy = state.isSubmitting;
    void submit(SubmitDisposition disposition) => ref
        .read(provider.notifier)
        .submit(
          rawFront: _front.text,
          rawBack: _back.text,
          rawExample: _example.text,
          rawHint: _hint.text,
          rawPronunciation: _pronunciation.text,
          disposition: disposition,
        );

    return MxContentShell(
      title: context.l10n.cardEditorCreateTitle,
      leading: _closeButton(context, _pop),
      isScrollable: true,
      footer: CardCreateActionBarWidget(
        isSaving: busy,
        onSave: busy ? null : () => submit(SubmitDisposition.close),
        onSaveAndAdd: busy ? null : () => submit(SubmitDisposition.addAnother),
      ),
      body: CardCreateFormWidget(
        state: state,
        isBusy: busy,
        front: _front,
        back: _back,
        example: _example,
        hint: _hint,
        pronunciation: _pronunciation,
        frontFocus: _frontFocus,
      ),
    );
  }

  // ---- edit --------------------------------------------------------------

  Widget _buildEdit(BuildContext context, String cardId) {
    final loaded = ref.watch(cardToEditProvider(cardId));

    return loaded.when(
      loading: () => _shell(
        context,
        body: MxLoadingState(
          semanticsLabel: context.l10n.cardEditorLoadingLabel,
        ),
      ),
      error: (error, stackTrace) =>
          _recoveryFace(context, context.l10n.cardEditorLoadFailed),
      // **The one consistency check this screen owes.** A deep link can name a
      // deck the card no longer belongs to; rendering the route's breadcrumb
      // over another deck's card would be a confident lie about where the user
      // is. Both values are already in hand, so the check costs no query — and
      // the recovery names what to do rather than the ids.
      data: (card) => card.deckId == widget.deckId
          ? _buildEditForm(context, cardId, card)
          : _recoveryFace(context, context.l10n.cardEditorContextMismatch),
    );
  }

  /// A dead end with a way back. Both of the editor's are the same shape, so
  /// only the sentence differs.
  ///
  /// **`MxErrorState`, not `MxEmptyState`** (A20.1 P2-03): a card that could
  /// not be opened is a failure with a recovery, and `mx_empty_state.dart`'s
  /// own doc renounces standing in for one. The recovery here is the way
  /// back, which is what the action slot carries.
  Widget _recoveryFace(BuildContext context, String message) => _shell(
    context,
    body: MxErrorState(
      title: context.l10n.unexpectedErrorTitle,
      message: message,
      retryLabel: context.l10n.cardEditorLoadRetry,
      onRetry: _pop,
    ),
  );

  Widget _buildEditForm(BuildContext context, String cardId, CardEntity card) {
    _prefillOnce(card);

    final provider = cardEditProvider(cardId);
    final state = ref.watch(provider);
    final flagState = ref.watch(setCardFlagProvider(cardId));
    final controller = ref.read(provider.notifier);
    final deckContext = ref.watch(deckContextProvider(widget.deckId));

    ref.listen<CardSubmitState>(provider, (previous, next) {
      if (next.shouldClose && !(previous?.shouldClose ?? false)) {
        _leaveAfterSave();
      }
    });

    final busy = state.isSubmitting;
    final canSave = !busy && _isContentDirty;
    void save() => controller.submit(
      rawFront: _front.text,
      rawBack: _back.text,
      rawExample: _example.text,
      rawHint: _hint.text,
      rawPronunciation: _pronunciation.text,
    );

    // **`canPop` tracks the draft rather than sitting at `false`.** One handler
    // still decides everything — the system back gesture, the back arrow and
    // Cancel all arrive at `_handleExitRequest`. But a screen that claims the
    // gesture unconditionally suppresses Android's predictive-back preview even
    // when it is going to let the pop through anyway.
    return PopScope<Object?>(
      canPop: !_hasUnsavedWork,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        unawaited(_handleExitRequest(cardId));
      },
      child: _shell(
        context,
        onClose: () => unawaited(_handleExitRequest(cardId)),
        actions: <Widget>[
          CardFlagToggleWidget(
            cardId: cardId,
            onToggle: flagState.isSubmitting
                ? null
                : (isFlagged) => ref
                      .read(setCardFlagProvider(cardId).notifier)
                      .submit(isFlagged: !isFlagged),
          ),
          // The compact shortcut. Same command, same enabled rule, no spinner —
          // the footer owns saying that a save is running.
          CardEditorSaveShortcutWidget(onSave: canSave ? save : null),
        ],
        subheader: flagState.failure == null
            ? null
            : CardWriteFailureTextWidget(
                failure: flagState.failure!,
                message: context.l10n.cardEditorFlagFailed,
              ),
        footer: CardEditorActionBarWidget(
          isSaving: busy,
          onCancel: () => unawaited(_handleExitRequest(cardId)),
          onSave: canSave ? save : null,
        ),
        body: CardEditorFormWidget(
          deckId: widget.deckId,
          cardId: cardId,
          deckContext: deckContext,
          onLeave: (navigate) =>
              unawaited(_handleExitRequest(cardId, then: navigate)),
          state: state,
          isBusy: busy,
          front: _front,
          back: _back,
          example: _example,
          hint: _hint,
          pronunciation: _pronunciation,
          frontFocus: _frontFocus,
          isDetailsExpanded: _detailsExpanded,
          onToggleDetails: () =>
              setState(() => _detailsExpanded = !_detailsExpanded),
          onTagDraftChanged: _onTagDraftChanged,
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
    // build without a `setState` in it.
    _baseline = _draft;
    _prefilled = true;
  }

  /// The one way out of the edit form, whichever affordance asked.
  ///
  /// Async, and every early return is a case that must **not** pop: a save in
  /// flight, because the write would land on a screen that is gone, and a
  /// dialog already asking this question.
  /// [then] is what leaving *means* for the affordance that asked. The back
  /// arrow, Cancel and the system gesture pop; a breadcrumb crumb navigates
  /// somewhere else entirely. Passing the destination in as a thunk is what
  /// lets one coordinator own the question for all of them — the alternative
  /// was four `goNamed` calls that walked past the guard, which is exactly
  /// what they were doing.
  Future<void> _handleExitRequest(String cardId, {VoidCallback? then}) async {
    if (ref.read(cardEditProvider(cardId)).isSubmitting) return;
    if (_isDiscardOpen) return;
    if (!_hasUnsavedWork) {
      (then ?? _pop)();

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
    (then ?? _pop)();
  }

  /// Leaves after a successful write.
  ///
  /// The baseline moves to the saved text first, so anything that re-enters the
  /// exit path during the pop sees a pristine form rather than asking the user
  /// to discard the changes they just saved.
  void _leaveAfterSave() {
    // **Only the editor the user is looking at reacts.** `cardEditProvider` is
    // a family keyed by card id, so two editors mounted for one card share a
    // notifier and both see the same `shouldClose` transition — and
    // `Navigator.pop` pops the *top* route, not the caller's. Measured: one
    // Save popped two routes and left the user on a stale copy of the form
    // underneath. `isCurrent` is what makes the reaction belong to a route
    // rather than to a card.
    //
    // Two editors for one card is reachable today: this screen pushes Card
    // Detail for the history, and Card Detail's own Edit action pushes an
    // editor back. That cycle is a navigation question for Card Detail and the
    // router, both outside this task's scope — recorded in `docs/wbs.md`
    // M99.62. What this guard buys is that no save can strand anyone.
    if (!(ModalRoute.of(context)?.isCurrent ?? true)) return;
    _baseline = _draft;
    _isContentDirty = false;
    _pop();
  }

  /// **`pop`, not `maybePop`.** `PopScope` intercepts `maybePop` and the system
  /// gesture; a direct pop is the deliberate exit this screen has already
  /// authorised, so routing it back through the guard would ask the question a
  /// second time.
  void _pop() => Navigator.of(context).pop();

  Widget _shell(
    BuildContext context, {
    required Widget body,
    List<Widget>? actions,
    Widget? subheader,
    Widget? footer,
    VoidCallback? onClose,
  }) => MxContentShell(
    title: context.l10n.cardEditorEditTitle,
    leading: _closeButton(context, onClose ?? _pop),
    actions: actions,
    subheader: subheader,
    footer: footer,
    isScrollable: true,
    body: body,
  );

  /// **A back arrow in edit, an `×` in create, and the difference is real.**
  /// Edit is pushed onto the card list and returns to it; create is a form the
  /// user opened and can abandon. [onClose] is the same coordinator the system
  /// gesture reaches, which is the whole reason the discard question cannot be
  /// answered differently depending on how the user tried to leave.
  Widget _closeButton(BuildContext context, VoidCallback onClose) =>
      MxIconButton(
        icon: widget.cardId == null ? Icons.close : Icons.arrow_back,
        semanticLabel: widget.cardId == null
            ? context.l10n.cardEditorClose
            : context.l10n.cardEditorBackAction,
        onPressed: onClose,
      );
}
