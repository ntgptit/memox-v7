import 'package:flutter/material.dart';

import 'mx_action_button.dart';
import 'mx_button_pair.dart';
import 'mx_dialog_metrics.dart';
import 'mx_dialog_tone.dart';

/// Whether the confirmed action destroys something.
///
/// An enum rather than an `isDestructive` flag beside a colour: a flag and a
/// colour can be passed independently, and a caller that sets one without the
/// other produces a dialog that looks safe and is not.
enum MxConfirmDialogVariant {
  /// Reversible, or harmless.
  normal,

  /// Deletes or discards. Styled as destructive, and — more importantly — not
  /// the initially focused control.
  destructive,

  /// Serious but reversible: it moves something out of sight rather than
  /// destroying it, and the user has a stated window to change their mind.
  ///
  /// **The two halves of `destructive` pulled apart** (BR-266). A soft delete
  /// must not wear the destructive colour — the colour has to keep meaning
  /// something at the one dialog that really is permanent — but it still wants
  /// the safe default focus, because a stray Enter should not move a deck the
  /// user was only reading about. Folding this into `normal` would have taken
  /// the focus rule with it, silently.
  ///
  /// **The rule generalised, after a second case turned up that the paragraph
  /// above does not describe.** What this variant encodes is *a stray Enter
  /// must not do this, and the destructive colour would overstate it*. Soft
  /// delete is one instance; adding a duplicate starter deck
  /// (`showStarterAddAgainConfirm`, BR-38) is another — nothing is hidden and
  /// there is no window to change your mind, but there is still a deck to go
  /// find and delete afterwards. Read "out of sight" as the case that named
  /// the variant, not as its boundary.
  cautious,
}

/// Asks the user to confirm one action.
///
/// **It counts nothing.** M4.10 deletes a deck and knows it is taking four
/// sub-decks and eleven cards with it; that sentence is built there, already
/// localized and already pluralised, and arrives here as [message]. A shared
/// dialog that knew about decks could not be used for anything else, and a
/// shared dialog that did its own pluralisation would do it in one language.
///
/// **It does not close itself.** The caller pops the route in its callback,
/// after the work either succeeded or failed. A dialog that dismissed on tap
/// would unmount [isSubmitting] before it could ever be shown, and the user
/// would see the screen behind it while the delete was still running.
class MxConfirmDialog extends StatelessWidget {
  const MxConfirmDialog({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.onConfirm,
    required this.onCancel,
    this.variant = MxConfirmDialogVariant.normal,
    this.tone,
    this.isSubmitting = false,
    this.isConfirmBlocked = false,
    super.key,
  });

  /// Already-localized, and complete. See the class doc.
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;

  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  final MxConfirmDialogVariant variant;

  /// How serious the situation is — the severity axis, independent of [variant].
  ///
  /// Null renders the header exactly as it did before tones existed: no icon,
  /// title alone. That is the default on purpose, so a dialog gains an icon
  /// only where someone decided it earns one, rather than every dialog in the
  /// app growing decoration in one commit.
  ///
  /// See [MxDialogTone] for why this is not folded into [variant].
  final MxDialogTone? tone;

  /// While true both actions are inert. Confirming a delete twice sends two
  /// deletes, and the second one fails against data the first already removed —
  /// which surfaces to the user as an error for an action that worked.
  final bool isSubmitting;

  /// While true the confirm button is inert **and Cancel is not**.
  ///
  /// **A second flag rather than more of [isSubmitting], because Cancel is not
  /// the same question.** The deck delete cannot ask *are you sure* until it
  /// knows what will be lost (BR-04), so confirm has to wait for the impact
  /// read — but backing out is safe at every instant, and a user who opened
  /// this dialog by accident should not be held in it until a database query
  /// returns. Folding the two into one flag is what made Cancel dead during
  /// that read; the code did it, the WBS entry claimed the opposite, and only
  /// the review caught that they disagreed.
  final bool isConfirmBlocked;

  bool get _isDestructive => variant == MxConfirmDialogVariant.destructive;

  /// Whether Cancel starts focused. True for both serious variants.
  bool get _shouldFocusCancel =>
      _isDestructive || variant == MxConfirmDialogVariant.cautious;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      // Stated, so the dialog Material draws is the dialog this file describes.
      // actually is.
      insetPadding: MxDialogMetrics.insetPadding,
      actionsPadding: MxDialogMetrics.actionsPadding,
      // Scrollable because the alternative is silent truncation, not an error.
      // At textScaler 3.0 on a 320-wide screen a translated message clips
      // mid-word inside the content box: no exception, no overflow stripe,
      // nothing a passing widget test would notice — and the user confirms a
      // delete having read half the sentence describing it.
      scrollable: true,
      title: MxDialogHeader(title: title, tone: tone),
      // **A live region, because the message is where a failure lands.** Both
      // callers that can fail leave the dialog open and change only this text —
      // the tag delete appends the reason to the question, the deck delete
      // replaces the question with it (a deliberate three-way divergence, D26).
      // Either way focus never moves and the title never changes, so without
      // this a screen-reader user is told nothing at all.
      //
      // The difference in *what* is announced is D26's business and stays; what
      // this fixes is that neither was announced. The banded failures elsewhere
      // mark themselves the same way (D24, D25).
      content: Semantics(liveRegion: true, child: Text(message)),
      // **One child, and it is `MxButtonPair` rather than the two buttons
      // Material would put in an `OverflowBar`.** The bar sizes each action to
      // its own label, so `Cancel` beside `Delete deck` is a small button next
      // to a large one — two options drawn at two weights when the dialog's
      // whole job is to present them as a choice. The pair splits the footer
      // evenly and matches their heights, and keeps the reason the bar was
      // here: it stacks when a 320-wide screen at textScaler 2.0 leaves no room
      // for a row.
      actions: <Widget>[
        MxButtonPair(
          // No width passed: the pair is a render object now and measures the
          // constraint it is given, which is this dialog's footer. Handing it a
          // computed number was the workaround for a widget that could not see
          // one.
          secondary: MxActionButton(
            label: cancelLabel,
            // Not `isConfirmBlocked` — see its doc. The way out stays open.
            onPressed: isSubmitting ? null : onCancel,
            variant: MxActionButtonVariant.secondary,
            // Focus starts on cancel for anything serious — destructive *or*
            // cautious — so a stray Enter neither deletes nor hides anything.
            // On a normal dialog neither action is autofocused: pre-selecting
            // "confirm" makes the keyboard path skip the question the dialog
            // exists to ask.
            shouldAutofocus: _shouldFocusCancel,
          ),
          primary: MxActionButton(
            label: confirmLabel,
            onPressed: isSubmitting || isConfirmBlocked ? null : onConfirm,
            variant: _isDestructive
                ? MxActionButtonVariant.destructive
                : MxActionButtonVariant.primary,
            isLoading: isSubmitting,
          ),
        ),
      ],
    );
  }
}

/// Asks a yes/no question and returns the answer.
///
/// **The one-shot half of the confirmation story**, for the callers that do not
/// keep the dialog open while a write runs — see `MxAsyncConfirmDialog` for
/// those. Five call sites had each written this same `showDialog` themselves,
/// and the fifth had drifted: it built a bare `AlertDialog` with two
/// `TextButton`s, so it had neither the destructive colour nor the focus rule,
/// while its own doc comment said a mistaken tap "must land on Cancel".
///
/// **Anything other than the confirm button is a no.** The barrier, the Android
/// back gesture and Escape all pop with null, and every caller was already
/// writing `?? false` to say so. Returning `bool` rather than `bool?` puts that
/// decision here once instead of trusting five call sites to keep repeating it.
Future<bool> showMxConfirm(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  required String cancelLabel,
  MxConfirmDialogVariant variant = MxConfirmDialogVariant.normal,
  MxDialogTone? tone,
}) async {
  final bool? confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => MxConfirmDialog(
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      variant: variant,
      tone: tone,
      onConfirm: () => Navigator.of(dialogContext).pop(true),
      onCancel: () => Navigator.of(dialogContext).pop(false),
    ),
  );

  return confirmed ?? false;
}
