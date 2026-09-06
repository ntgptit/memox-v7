import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/state/submit_outcome.dart';
import '../../../../l10n/l10n_extension.dart';
import '../../../../shared/widgets/mx_async_view.dart';
import '../../../../shared/widgets/mx_content_shell.dart';
import '../../../../shared/widgets/mx_error_state.dart';
import '../../domain/models/new_card_order_model.dart';
import '../../domain/models/study_options_model.dart';
import '../controllers/study_options_controller.dart';
import '../controllers/study_options_write_controller.dart';
import '../states/study_options_submit_state.dart';
import '../widgets/sections/study_options_section_widget.dart';

/// How much to study, and in what order (BR-147, BR-148).
///
/// **Whichever deck opened it, the values belong to the root.** A sub-deck
/// carries no options of its own, so editing here and editing from the root are
/// the same edit — the repository resolves through `root_deck_id` rather than
/// this screen deciding, which is what keeps invariant 20 true no matter which
/// level the user happened to be on.
class StudyOptionsScreen extends ConsumerWidget {
  const StudyOptionsScreen({required this.deckId, super.key});

  final String deckId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // A saved change closes the screen. Watching the transition rather than
    // acting inside `submit` is what keeps the controller free of a
    // `BuildContext` it must never hold.
    ref.listen(studyOptionsWriteControllerProvider(deckId), (_, next) {
      if (next.outcome != SubmitOutcome.savedAndClose) return;
      if (!context.mounted) return;

      Navigator.of(context).pop();
    });

    final submit = ref.watch(studyOptionsWriteControllerProvider(deckId));
    final clear = ref.watch(studyOptionsClearControllerProvider(deckId));
    // Watched here rather than inline in `value:` so the error branch can read
    // `isRefreshing` off the same snapshot — see `isRetrying` below.
    final options = ref.watch(studyOptionsProvider(deckId));

    return MxContentShell(
      title: context.l10n.studyOptionsTitle,
      // Every branch below owns its gutters — the form through the padding on
      // the `data:` branch, the error and loading faces through their own — so
      // the shell's default would pad each of them twice. It was costing this
      // screen 16dp a side, which also defeated the compact step-down: at 320dp
      // the form ended up inset *more* than at regular width.
      padding: EdgeInsets.zero,
      body: MxAsyncView<StudyOptionsModel>(
        value: options,
        loadingLabel: context.l10n.studyOptionsTitle,
        // **The read failed, so neither the screen name nor the save note is
        // the right sentence.** `studyOptionsTitle` under a red glyph reads as
        // a heading — and it is already the app-bar title one line up, so the
        // face printed it twice — while "Takes effect from your next session"
        // describes a save that succeeded, which denies that anything went
        // wrong. `settingsLoadErrorTitle` and `reminderLoadErrorTitle` are the
        // same situation on the two other screens that read this pair.
        error: (_, _) => MxErrorState(
          title: context.l10n.studyOptionsLoadErrorTitle,
          message: context.l10n.writeErrorMessage,
          retryLabel: context.l10n.retryAction,
          // Rebuilding the provider, not re-navigating: the read failed, and a
          // fresh subscription is the only thing that can change the answer.
          onRetry: () => ref.invalidate(studyOptionsProvider(deckId)),
          // Without this the tap repaints an identical face: `invalidate` is a
          // refresh, and `MxAsyncView` holds the previous value through one, so
          // nothing on screen would tell the user the app had noticed.
          isRetrying: options.isRefreshing,
        ),
        data: (options) => Padding(
          // The screen gutter, so the form's left edge lines up with the
          // app-bar title on every width.
          padding: EdgeInsets.all(mxScreenGutter(context)),
          child: StudyOptionsSectionWidget(
            // Keyed on the resolved values so the draft re-seeds after
            // `Use app defaults` swaps the override for the app defaults —
            // without it the fields would keep showing the numbers that were
            // just cleared.
            key: ValueKey<String>(
              '${options.cardLimit}-${options.newCardOrder.dbValue}-'
              '${options.isRootOverride}',
            ),
            initialCardLimit: options.cardLimit,
            initialNewCardOrder: options.newCardOrder,
            isSubmitting: submit.isSubmitting,
            cardLimitProblem: submit.cardLimitProblem,
            isRootOverride: options.isRootOverride,
            isClearing: clear.isSubmitting,
            onSave: (rawCardLimit, newCardOrder) =>
                _save(ref, rawCardLimit, newCardOrder),
            onUseAppDefaults: () => _useAppDefaults(ref),
          ),
        ),
      ),
    );
  }

  /// The notifier, read when the button is pressed rather than during a build.
  ///
  /// `ref.read` inside `build()` takes a value without subscribing, which is how
  /// a screen ends up showing state it will never be told has changed — the
  /// guard rule `no_ref_read_in_build` exists for exactly that, and it caught
  /// this.
  void _save(WidgetRef ref, String rawCardLimit, NewCardOrder newCardOrder) =>
      unawaited(
        ref
            .read(studyOptionsWriteControllerProvider(deckId).notifier)
            .submit(rawCardLimit: rawCardLimit, newCardOrder: newCardOrder),
      );

  /// Clears the root's override (BR-212). The screen stays open on the app
  /// defaults it has just adopted, which is the confirmation.
  void _useAppDefaults(WidgetRef ref) => unawaited(
    ref.read(studyOptionsClearControllerProvider(deckId).notifier).submit(),
  );
}
