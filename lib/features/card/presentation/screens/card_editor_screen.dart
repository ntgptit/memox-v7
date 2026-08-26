import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_context_extension.dart';
import '../../../../l10n/l10n_extension.dart';
import '../../../../shared/widgets/mx_action_button.dart';
import '../../../../shared/widgets/mx_content_shell.dart';
import '../../../../shared/widgets/mx_empty_state.dart';
import '../../../../shared/widgets/mx_failure_labels_widget.dart';
import '../../domain/entities/card_entity.dart';
import '../controllers/card_editor_load_controller.dart';
import '../controllers/card_flag_controller.dart';
import '../controllers/card_write_controller.dart';
import '../states/card_submit_state.dart';
import '../widgets/overlays/card_editor_discard_widget.dart';
import '../widgets/sections/card_create_form_widget.dart';
import '../widgets/sections/card_danger_zone_widget.dart';
import '../widgets/sections/card_details_section_widget.dart';
import '../widgets/sections/card_editor_fields_widget.dart';
import '../widgets/sections/card_flag_toggle_widget.dart';
import '../widgets/sections/card_tag_section_widget.dart';

/// The card editor — create and edit (UC-04 W4, A1).
///
/// One route, two modes, decided by [cardId]: null creates, set edits. Both are
/// framed by the same shell and share the front/back fields; everything else
/// differs, so create's draft and its two save paths live in
/// `CardCreateFormWidget` and this state object holds edit's alone.
///
/// It navigates nothing itself: the write controller reports a
/// `SubmitOutcome` and this widget reacts, because a controller holding a
/// `BuildContext` is the crash `command_query_separation_test.dart` exists to
/// forbid.
///
/// **Edit pins its save to the bottom of the screen and create does not.** Edit
/// is the mode the owner review was about: its form runs past a phone screen,
/// and the button sat mid-scroll with the tag section below it — so the one
/// control that commits the form was invisible from the place the user most
/// often finished, and the tags underneath read as being inside a transaction
/// they are not part of (2026-08-26). Create's form is short, ends in its two
/// actions, and has nothing after them to be misread.
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

  /// A card that already has a detail opens the optional fields expanded (W5).
  bool _detailsExpanded = false;

  /// What the card held when it was loaded, in the order [_editableControllers]
  /// declares.
  ///
  /// **The baseline the dirty check compares against, and it has to be a
  /// snapshot.** Comparing the fields against the *provider's* current card
  /// would answer a different question after a successful save — the stream
  /// re-emits with the new text, and every field would look clean again while
  /// the user is still typing the next change.
  List<String> _loadedValues = const <String>[];

  bool get _isEditing => widget.cardId != null;

  List<TextEditingController> get _editableControllers =>
      <TextEditingController>[_front, _back, _example, _hint, _pronunciation];

  /// Whether the form holds an edit that is not on disk.
  ///
  /// **Tags are deliberately not part of this.** A tag is written the moment it
  /// is added or removed (BR-93), so it is never unsaved — counting one would
  /// put a discard dialog in front of a user who has changed nothing that can
  /// be lost, and would light the save button for a change it does not save.
  bool get _isDirty {
    if (_loadedValues.isEmpty) return false;
    final controllers = _editableControllers;

    for (var i = 0; i < controllers.length; i++) {
      if (controllers[i].text != _loadedValues[i]) return true;
    }

    return false;
  }

  @override
  void initState() {
    super.initState();
    // The save button's enabled state is derived from the text, so the screen
    // has to rebuild as it changes. Edit only: create's draft is not here.
    if (!_isEditing) return;
    for (final controller in _editableControllers) {
      controller.addListener(_onFormChanged);
    }
  }

  void _onFormChanged() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    for (final controller in _editableControllers) {
      controller
        ..removeListener(_onFormChanged)
        ..dispose();
    }
    _frontFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      _isEditing ? _buildEdit(context, widget.cardId!) : _buildCreate(context);

  Widget _buildCreate(BuildContext context) => _shell(
    context,
    title: context.l10n.cardEditorCreateTitle,
    body: CardCreateFormWidget(deckId: widget.deckId),
  );

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

  void _prefill(CardEntity card) {
    _loadedValues = <String>[
      card.front,
      card.back,
      card.example ?? '',
      card.hint ?? '',
      card.pronunciation ?? '',
    ];
    for (var i = 0; i < _editableControllers.length; i++) {
      _editableControllers[i].text = _loadedValues[i];
    }
    // Open the details already if this card has any — so an existing detail is
    // visible without hunting for the toggle (W5).
    _detailsExpanded =
        card.example != null || card.hint != null || card.pronunciation != null;
    _prefilled = true;
  }

  Widget _buildEditForm(BuildContext context, String cardId, CardEntity card) {
    if (!_prefilled) _prefill(card);

    final provider = cardEditProvider(cardId);
    final state = ref.watch(provider);
    final flagState = ref.watch(setCardFlagProvider(cardId));
    final controller = ref.read(provider.notifier);

    ref.listen<CardSubmitState>(provider, (previous, next) {
      if (next.shouldClose && !(previous?.shouldClose ?? false)) {
        Navigator.of(context).pop();
      }
    });

    final busy = state.isSubmitting;

    return PopScope<Object?>(
      // Always blocked, then re-popped by the handler once it knows whether
      // there is anything to lose. `canPop: !_isDirty` was the first version
      // and is subtly wrong under Android's predictive back: the system
      // commits to the transition on the frame the gesture starts, so the
      // dialog would be decided a frame before the user finished typing.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        // Fire-and-forget by design: the pop was already blocked, and the
        // handler re-pops once the user has answered.
        unawaited(_leaveEditor());
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
            : _writeFailure(flagState.failure!),
        // Pinned, so the control that commits the form is reachable from every
        // scroll position — and disabled until there is something to commit, so
        // an untouched card does not offer a live primary that would write
        // nothing (owner review, 2026-08-26).
        bottomBar: MxActionButton(
          label: context.l10n.cardEditorSaveChanges,
          onPressed: busy || !_isDirty ? null : () => _submitEdit(controller),
          isLoading: busy,
          // The bar decides this button's width, so the label can stay painted
          // beside the spinner instead of hiding behind it.
          shouldKeepLabelWhileLoading: true,
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            CardEditorFieldsWidget(
              state: state,
              frontController: _front,
              backController: _back,
              frontFocus: _frontFocus,
              isBusy: busy,
              shouldAutofocus: false,
              backHelperText: context.l10n.cardEditorProgressNote,
            ),
            const SizedBox(height: AppSpacing.md),
            CardDetailsSectionWidget(
              isExpanded: _detailsExpanded,
              onToggle: () =>
                  setState(() => _detailsExpanded = !_detailsExpanded),
              exampleController: _example,
              hintController: _hint,
              pronunciationController: _pronunciation,
              isBusy: busy,
              exampleProblem: state.exampleProblem,
              hintProblem: state.hintProblem,
              pronunciationProblem: state.pronunciationProblem,
            ),
            const SizedBox(height: AppSpacing.xl),
            CardTagSectionWidget(cardId: cardId),
            const SizedBox(height: AppSpacing.xl),
            CardDangerZoneWidget(
              deckId: widget.deckId,
              cardId: cardId,
              isDisabled: busy,
            ),
          ],
        ),
      ),
    );
  }

  void _submitEdit(CardEdit controller) => controller.submit(
    rawFront: _front.text,
    rawBack: _back.text,
    rawExample: _example.text,
    rawHint: _hint.text,
    rawPronunciation: _pronunciation.text,
  );

  /// Close, and Android's back gesture: the same exit, asking the same
  /// question (UC-04 A1).
  ///
  /// Never mid-save — the write is already in flight, and leaving would strand
  /// the outcome the listener above is waiting for.
  Future<void> _leaveEditor() async {
    if (ref.read(cardEditProvider(widget.cardId!)).isSubmitting) return;
    if (_isDirty) {
      final shouldDiscard = await showCardEditorDiscardConfirm(context);
      if (!mounted || !shouldDiscard) return;
    }
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  // ---- shared ------------------------------------------------------------

  Widget _shell(
    BuildContext context, {
    required String title,
    required Widget body,
    List<Widget>? actions,
    Widget? subheader,
    Widget? bottomBar,
  }) => MxContentShell(
    title: title,
    leading: _closeButton(context),
    actions: actions,
    subheader: subheader,
    bottomBar: bottomBar,
    isScrollable: true,
    body: body,
  );

  Widget _writeFailure(Failure failure) => Semantics(
    liveRegion: true,
    child: Text(
      context.mxWriteFailure(
        failure,
        onNotFound: (_) => context.l10n.writeErrorMessage,
        onConflict: (_) => context.l10n.writeErrorMessage,
      ),
      style: context.texts.bodySmall?.copyWith(color: context.colors.error),
    ),
  );

  /// Create leaves straight away; edit routes through the same guard the back
  /// gesture does, so the `×` cannot be the one exit that loses work.
  Widget _closeButton(BuildContext context) => IconButton(
    icon: const Icon(Icons.close),
    onPressed: _isEditing
        ? () => unawaited(_leaveEditor())
        : () => Navigator.of(context).pop(),
    tooltip: context.l10n.cardEditorClose,
  );
}
