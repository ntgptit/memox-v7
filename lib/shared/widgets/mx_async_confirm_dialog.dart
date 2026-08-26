import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/state/submit_state.dart';
import 'mx_confirm_dialog.dart';
import 'mx_dialog_tone.dart';

/// When a confirmation that submits in place should take itself off screen.
///
/// **Two policies because the app genuinely has two, and the difference is a
/// bug that already shipped.** `settings_reset_confirm_widget.dart` records it:
/// the first version closed only on success, `submitStateFromFailure` produces
/// a state carrying a `failure` and no `outcome`, and so a failed reset left
/// the dialog standing, unchanged and silent, over an error band it was hiding.
/// Four dialogs each wrote this condition by hand and one of them got it wrong;
/// naming the two policies is what stops the fifth from having to get it right.
enum MxConfirmCloseWhen {
  /// The write succeeded and said so with `SubmitOutcome.savedAndClose`.
  ///
  /// The failure stays *in* the dialog: the body swaps to the reason and the
  /// user decides whether to try again. The three deletes use this.
  saved,

  /// The operation stopped, either way — succeeded, or failed with a reason
  /// something behind the dialog is already showing.
  ///
  /// For the case where the failure belongs to the screen rather than to the
  /// question: settings reset renders its error in the reset group's own band
  /// with a `Try again`, and that band cannot be read until the scrim is gone
  /// (wireframe W4).
  settled,
}

/// A confirmation that stays mounted while the write it confirms runs.
///
/// **The other half of the confirmation story.** [showMxConfirm] answers a
/// yes/no question and pops immediately; this one keeps the dialog up so
/// `isSubmitting` can disable both actions and a failure can be read without
/// the question disappearing first. Confirming a delete twice sends two
/// deletes, and the second fails against data the first already removed —
/// which reaches the user as an error for an action that worked.
///
/// **It owns the transition, and nothing else.** Four call sites had each
/// written the same `ref.listen` — *fire when the state crosses into settled,
/// and only on the crossing* — and the widget below is that comparison, once.
/// What each caller says in [message], which counts it read first, and what it
/// does after closing all stay in the caller: the deck delete reads its impact
/// before asking, the tag delete appends the reason to the question while the
/// deck delete replaces it (a deliberate three-way divergence, D26), and two of
/// them hand a batch id to an Undo afterwards.
///
/// [P] is the caller's own problem enum, so a feature's `SubmitState` typedef
/// passes straight in.
class MxAsyncConfirmDialog<P extends Enum> extends StatefulWidget {
  const MxAsyncConfirmDialog({
    required this.state,
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.onConfirm,
    required this.onCancel,
    required this.onDone,
    this.variant = MxConfirmDialogVariant.normal,
    this.tone,
    this.closeWhen = MxConfirmCloseWhen.saved,
    this.isBlocked = false,
    super.key,
  });

  /// The write's status, watched by the caller and passed down.
  ///
  /// A value rather than a provider: a feature's write controllers are distinct
  /// generated types — several of them families — and no single parameter type
  /// unifies them. The same trade `MxFormHost` makes, for the same reason.
  final SubmitState<P> state;

  /// Already-localized, and complete. [message] is where a failure lands, and
  /// the caller decides whether it replaces the question or is appended to it.
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;

  /// Starts the write. Fired from a button press, never from a build.
  final VoidCallback onConfirm;

  /// The user backed out. Pops, and nothing has happened.
  final VoidCallback onCancel;

  /// The operation reached [closeWhen]. Pops, and something did happen — this
  /// is where a caller hands a batch id to an Undo, or navigates away from a
  /// deck that no longer exists.
  final VoidCallback onDone;

  final MxConfirmDialogVariant variant;
  final MxDialogTone? tone;
  final MxConfirmCloseWhen closeWhen;

  /// Disables **confirm only** for a reason that is not the write.
  ///
  /// One caller: the deck delete cannot ask *are you sure* until it knows what
  /// will be lost (BR-04), so it blocks while the impact read is in flight.
  ///
  /// **Cancel stays live throughout**, which is the correction this parameter
  /// carries. It first went through `isSubmitting`, which disables both — so a
  /// user who opened the dialog by accident was held in it until a database
  /// query returned. That was the pre-existing behaviour, faithfully copied
  /// when the four dialogs were merged into this one, and copying it is what
  /// gave it a single place to be wrong in and a single place to fix.
  final bool isBlocked;

  @override
  State<MxAsyncConfirmDialog<P>> createState() =>
      _MxAsyncConfirmDialogState<P>();
}

class _MxAsyncConfirmDialogState<P extends Enum>
    extends State<MxAsyncConfirmDialog<P>> {
  /// Whether [state] has reached the point [closeWhen] names.
  ///
  /// A pure function of the state, so the transition below is a comparison
  /// between two of them rather than a flag this widget has to maintain.
  static bool _hasArrived<P extends Enum>(
    SubmitState<P> state,
    MxConfirmCloseWhen when,
  ) => switch (when) {
    MxConfirmCloseWhen.saved => state.shouldClose,
    MxConfirmCloseWhen.settled =>
      state.outcome != null || state.failure != null,
  };

  @override
  void didUpdateWidget(MxAsyncConfirmDialog<P> oldWidget) {
    super.didUpdateWidget(oldWidget);

    // **The crossing, not the value.** Reading the outcome alone fires on every
    // rebuild that happens to see it and pops the route more than once.
    // The pair the settings dialog named `hasSettled` / `hasSettledAlready`,
    // kept in that shape: a bare `arrived` does not say which way true points.
    final bool hasArrived = _hasArrived(widget.state, widget.closeWhen);
    final bool hasArrivedAlready = _hasArrived(
      oldWidget.state,
      oldWidget.closeWhen,
    );
    if (!hasArrived || hasArrivedAlready) return;

    // **After the frame, not inside it, and this is not defensive.**
    // `didUpdateWidget` runs during build, and [onDone] pops a route — for two
    // callers it then navigates as well. Tearing down the tree that is
    // currently being built throws
    // `'_dependents.isEmpty': is not true` out of `InheritedElement`, an
    // assertion whose message names neither this widget nor the pop.
    //
    // The four hand-written versions never met it because each fired from
    // `ref.listen`, which Riverpod already invokes outside the build phase.
    // Taking the transition off the provider means taking that guarantee with
    // it, so it is restored here rather than left as a property callers have to
    // know about.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.onDone();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MxConfirmDialog(
      title: widget.title,
      message: widget.message,
      confirmLabel: widget.confirmLabel,
      cancelLabel: widget.cancelLabel,
      variant: widget.variant,
      tone: widget.tone,
      isSubmitting: widget.state.isSubmitting,
      isConfirmBlocked: widget.isBlocked,
      onConfirm: widget.onConfirm,
      onCancel: widget.onCancel,
    );
  }
}

/// Opens a confirmation whose controller is cleared first.
///
/// **[reset] runs from the tap that opens the dialog**, not from a widget
/// life-cycle — the discipline `showMxFormSheet` documents for every form, and
/// for the same reasons: Riverpod refuses a provider mutation during `build`,
/// `initState` or `dispose`, and an `autoDispose` provider with no listeners
/// left is already gone by the time a scheduled callback runs.
///
/// **Only one of the four dialogs used to do this**, and its comment says why
/// the other three were gambling: `autoDispose` will *usually* have collected
/// the notifier already, but a second dialog opened while the first is still
/// unmounting shares it — and what the user then reads is the previous
/// attempt's failure, presented as the current question's answer.
Future<void> showMxAsyncConfirm(
  BuildContext context, {
  required void Function(ProviderContainer) reset,
  required Widget Function(BuildContext, VoidCallback) builder,
}) {
  reset(ProviderScope.containerOf(context));

  return showDialog<void>(
    context: context,
    builder: (dialogContext) =>
        builder(dialogContext, () => Navigator.of(dialogContext).pop()),
  );
}
