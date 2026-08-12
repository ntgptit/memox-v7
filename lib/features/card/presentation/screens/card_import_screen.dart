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

  /// Close (app bar): out of the wizard, asking first when a draft would be
  /// lost (W5). A committed result is not a draft — leaving is free.
  Future<void> _close() async {
    final isDone = ref.read(commitCardImportProvider(widget.deckId)).isDone;
    if (isDone || !_isDirty) {
      _leave();
      return;
    }
    final discard = await showCardImportDiscardConfirm(context);
    if (!mounted || !discard) return;
    _leave();
  }

  /// Android Back: a step back first (W5); the Source step behaves as Close.
  Future<void> _handleSystemBack() async {
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
    await _close();
  }

  void _leave() {
    if (!mounted) return;
    context.goNamed(
      RouteNames.cardList,
      pathParameters: <String, String>{RoutePathParams.deckId: widget.deckId},
    );
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

    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        // Fire-and-forget by design: the pop was already blocked, and the
        // handler re-pops once it has decided.
        unawaited(_handleSystemBack());
      },
      child: Scaffold(
        appBar: AppBar(
          leading: MxIconButton(
            icon: Icons.close,
            semanticLabel: context.l10n.cardImportTitle,
            tooltip: context.l10n.commonCancelAction,
            onPressed: _close,
          ),
          title: Text(context.l10n.cardImportTitle),
        ),
        body: SafeArea(
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  AppSpacing.sm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    CardImportContextWidget(deckId: deckId),
                    const SizedBox(height: AppSpacing.sm),
                    CardImportStepperWidget(current: step),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.sm,
                    AppSpacing.lg,
                    AppSpacing.xl,
                  ),
                  child: switch (step) {
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
                step: step,
                submit: submit,
                pasteController: _pasteController,
                onLeave: _leave,
              ),
            ],
          ),
        ),
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
}
