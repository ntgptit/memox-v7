import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/route_names.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/l10n_extension.dart';
import '../../../../shared/widgets/mx_icon_button.dart';
import '../controllers/card_import_commit_controller.dart';
import '../controllers/card_import_draft_controller.dart';
import '../controllers/card_import_query_controller.dart';
import '../controllers/deck_context_controller.dart';
import '../widgets/overlays/card_import_overlays_widget.dart';
import '../widgets/sections/card_import_action_bar_widget.dart';
import '../widgets/sections/card_import_confirm_step_widget.dart';
import '../widgets/sections/card_import_context_widget.dart';
import '../widgets/sections/card_import_preview_step_widget.dart';
import '../widgets/sections/card_import_result_widget.dart';
import '../widgets/sections/card_import_source_step_widget.dart';
import '../widgets/sections/card_import_stepper_widget.dart';
import '../states/card_import_state.dart';

/// The import wizard (UC-10, wireframe M4.12): one full-screen route, three
/// steps switched in place, so the draft has one lifetime — the route's.
///
/// The paste box's [TextEditingController] lives on this state object rather
/// than in the Source section, which unmounts between steps: pasted rows must
/// survive the round trip to Preview and back, and a parse failure must never
/// cost the paste (I4).
class CardImportScreen extends ConsumerStatefulWidget {
  const CardImportScreen({required this.deckId, super.key});

  final String deckId;

  @override
  ConsumerState<CardImportScreen> createState() => _CardImportScreenState();
}

class _CardImportScreenState extends ConsumerState<CardImportScreen> {
  late final TextEditingController _pasteController;

  @override
  void initState() {
    super.initState();
    _pasteController = TextEditingController(
      text: ref.read(cardImportPastedTextProvider(widget.deckId)),
    )..addListener(_onPasteChanged);
  }

  // Enables the primary action as text appears. No parsing happens here —
  // the text reaches its provider only on the Preview press (I4).
  void _onPasteChanged() => setState(() {});

  @override
  void dispose() {
    _pasteController.dispose();
    super.dispose();
  }

  bool get _isDirty =>
      ref.read(cardImportFilePickChoiceProvider(widget.deckId)).file != null ||
      _pasteController.text.trim().isNotEmpty;

  /// Cancel (Close, and system Back from the Source step): back to wherever
  /// the wizard was opened from, by popping — a card list stays a card list,
  /// an unset deck stays its own detail (W5). A deep link has no history to
  /// pop to; the deck's detail route is the canonical fallback, and its own
  /// redirect forwards card-type decks on to their list.
  ///
  /// Never mid-commit: the transaction is atomic and cannot honestly be
  /// cancelled, so leaving is locked until it resolves either way (F).
  Future<void> _cancel() async {
    if (ref.read(commitCardImportProvider(widget.deckId)).isSubmitting) {
      return;
    }
    final isDone = ref.read(commitCardImportProvider(widget.deckId)).isDone;
    if (!isDone && _isDirty) {
      final discard = await showCardImportDiscardConfirm(context);
      if (!mounted || !discard) return;
    }
    _popOrFallback();
  }

  /// Android Back: a step back first (W5); the Source step behaves as
  /// Cancel. Inert while the commit is in flight (F).
  Future<void> _handleSystemBack() async {
    if (ref.read(commitCardImportProvider(widget.deckId)).isSubmitting) {
      return;
    }
    final step = ref.read(cardImportStepChoiceProvider(widget.deckId));
    final isDone = ref.read(commitCardImportProvider(widget.deckId)).isDone;
    if (!isDone && step != CardImportStep.source) {
      goToCardImportStep(
        ref,
        widget.deckId,
        CardImportStep.values[step.index - 1],
      );
      return;
    }
    await _cancel();
  }

  void _popOrFallback() {
    if (!mounted) return;
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.goNamed(
      RouteNames.deckDetail,
      pathParameters: <String, String>{RoutePathParams.deckId: widget.deckId},
    );
  }

  /// View cards, after a successful commit only: the target deck's list,
  /// whose Drift stream already shows what was imported — declarative `go`,
  /// no reload and no per-card re-read.
  void _viewCards() {
    if (!mounted) return;
    context.goNamed(
      RouteNames.cardList,
      pathParameters: <String, String>{RoutePathParams.deckId: widget.deckId},
    );
  }

  /// `Import another file` (G): the providers reset through the bar's free
  /// function; the paste controller is this state object's and only this
  /// method can clear it — leaving it out kept the old text alive under an
  /// empty provider.
  void _resetDraft() {
    _pasteController.clear();
    resetCardImportDraft(ref, widget.deckId);
  }

  @override
  Widget build(BuildContext context) {
    final deckId = widget.deckId;
    final step = ref.watch(cardImportStepChoiceProvider(deckId));
    final submit = ref.watch(commitCardImportProvider(deckId));
    // Pin the whole draft for the wizard's lifetime. These are autodispose
    // families, and a value nobody is listening to is a value Riverpod is
    // free to drop between steps — the pasted text was lost exactly there,
    // written on the Source step and read only once Preview mounted.
    ref
      ..watch(cardImportSourceChoiceProvider(deckId))
      ..watch(cardImportFilePickChoiceProvider(deckId))
      ..watch(cardImportPastedTextProvider(deckId))
      ..watch(cardImportSheetChoiceProvider(deckId))
      ..watch(cardImportHeaderChoiceProvider(deckId))
      ..watch(cardImportDuplicateChoiceProvider(deckId));

    // The presentation phase (M4.12): one derived answer to "what face is
    // on screen", computed here and passed down so the stepper, the body and
    // the bar can never disagree. The parse and preview are watched only
    // once the wizard has left Source — watching them earlier would start
    // the decode before the user pressed Preview (I4).
    final isPastSource = step != CardImportStep.source;
    final isParsing =
        step == CardImportStep.preview &&
        ref.watch(cardImportDocumentProvider(deckId)).isLoading;
    final preview = isPastSource
        ? ref.watch(cardImportPreviewProvider(deckId)).value
        : null;
    final phase = deriveCardImportPhase(
      step: step,
      isParsing: isParsing,
      submit: submit,
      invalidCount: preview?.invalidCount ?? 0,
    );

    // Which steps have *earned* their check (stepper contract): Source once
    // a source exists, Preview once the rows are classified, mapped and at
    // least one is importable.
    final mapping = isPastSource
        ? ref.watch(cardImportMappingDraftProvider(deckId))
        : null;
    final shouldIncludeDuplicates = ref.watch(
      cardImportDuplicateChoiceProvider(deckId),
    );
    final completed = <CardImportStep>{
      if (_isDirty) CardImportStep.source,
      if (preview != null &&
          (mapping?.isComplete ?? false) &&
          preview.importableCount(
                shouldIncludeDuplicates: shouldIncludeDuplicates,
              ) >
              0)
        CardImportStep.preview,
    };

    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        // Fire-and-forget by design: the pop was already blocked, and the
        // handler re-pops once it has decided.
        unawaited(_handleSystemBack());
      },
      child: Scaffold(
        appBar: _appBar(phase, isSubmitting: submit.isSubmitting),
        body: SafeArea(
          child: Column(
            children: <Widget>[
              // The breadcrumb, context chip and stepper leave with the
              // wizard: on an outcome the hero is the focal point (state 6).
              if (!phase.isOutcome) _wizardHeader(step, completed),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.sm,
                    AppSpacing.lg,
                    AppSpacing.xl,
                  ),
                  child: phase.isOutcome
                      ? _outcomeBody(deckId, phase)
                      : switch (step) {
                          CardImportStep.source => CardImportSourceStepWidget(
                            deckId: deckId,
                            pasteController: _pasteController,
                          ),
                          CardImportStep.preview => CardImportPreviewStepWidget(
                            deckId: deckId,
                          ),
                          CardImportStep.confirm => _confirmBody(deckId),
                        },
                ),
              ),
              CardImportActionBarWidget(
                deckId: deckId,
                phase: phase,
                submit: submit,
                pasteController: _pasteController,
                onReset: _resetDraft,
                onViewCards: _viewCards,
              ),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _appBar(
    CardImportPhase phase, {
    required bool isSubmitting,
  }) {
    return AppBar(
      leading: MxIconButton(
        icon: Icons.close,
        semanticLabel: context.l10n.cardImportTitle,
        tooltip: context.l10n.commonCancelAction,
        // Locked while the one commit runs (F): it cannot honestly be
        // cancelled, so the exit does not pretend otherwise.
        onPressed: isSubmitting ? null : _cancel,
      ),
      // An outcome retitles the bar (state 6): the wizard's name is for
      // work in progress, the result's for what it did.
      title: Text(
        phase.isOutcome
            ? context.l10n.cardImportResultsTitle
            : context.l10n.cardImportTitle,
      ),
    );
  }

  Widget _wizardHeader(CardImportStep step, Set<CardImportStep> completed) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          CardImportContextWidget(deckId: widget.deckId),
          const SizedBox(height: AppSpacing.sm),
          CardImportStepperWidget(current: step, completed: completed),
        ],
      ),
    );
  }

  Widget _confirmBody(String deckId) {
    final preview = ref.watch(cardImportPreviewProvider(deckId)).value;
    final shouldIncludeDuplicates = ref.watch(
      cardImportDuplicateChoiceProvider(deckId),
    );
    final deckName =
        ref.watch(deckContextProvider(deckId)).value?.deckName ?? '';
    // Continue is gated on the preview being loaded, so a missing preview
    // here is a transient rebuild; the step renders nothing for one frame
    // rather than a spinner that suggests new work.
    if (preview == null) return const SizedBox.shrink();

    return CardImportConfirmStepWidget(
      deckId: deckId,
      deckName: deckName,
      preview: preview,
      shouldIncludeDuplicates: shouldIncludeDuplicates,
    );
  }

  Widget _outcomeBody(String deckId, CardImportPhase phase) {
    final submit = ref.watch(commitCardImportProvider(deckId));
    final preview = ref.watch(cardImportPreviewProvider(deckId)).value;
    final deckName =
        ref.watch(deckContextProvider(deckId)).value?.deckName ?? '';

    return CardImportResultWidget(
      phase: phase,
      deckName: deckName,
      result: submit.result,
      invalidCount: preview?.invalidCount ?? 0,
      blankCount: preview?.blankCount ?? 0,
      failure: submit.failure,
    );
  }
}
