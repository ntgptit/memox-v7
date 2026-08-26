import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import 'mx_action_button.dart';
import 'mx_button_pair.dart';

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
    this.isSubmitting = false,
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

  /// While true both actions are inert. Confirming a delete twice sends two
  /// deletes, and the second one fails against data the first already removed —
  /// which surfaces to the user as an error for an action that worked.
  final bool isSubmitting;

  bool get _isDestructive => variant == MxConfirmDialogVariant.destructive;

  /// Whether Cancel starts focused. True for both serious variants.
  bool get _shouldFocusCancel =>
      _isDestructive || variant == MxConfirmDialogVariant.cautious;

  /// How far a dialog sits in from each edge of the screen.
  ///
  /// **Stated rather than inherited**, so the two paddings that decide the
  /// footer's width are visible in one place rather than inherited silently
  /// from Material. They are no longer *arithmetic* anybody depends on:
  /// `MxButtonPair` measures the line it is handed instead of computing it, so
  /// changing these moves the dialog without anything else needing to be told.
  ///
  /// It is off `AppSpacing.scale` on purpose — the scale stops at 32 and this
  /// is a framework constant, not a design step. Naming it keeps that visible.
  static const double dialogInset = 40;

  /// The dialog's own padding around its action row — Material's default,
  /// stated here for the same reason as [dialogInset].
  static const double actionsInset = 24;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      // Stated rather than inherited, so the dialog's geometry is readable
      // here instead of being Material's default two indirections away.
      insetPadding: const EdgeInsets.symmetric(
        horizontal: dialogInset,
        vertical: AppSpacing.xl,
      ),
      actionsPadding: const EdgeInsets.fromLTRB(
        actionsInset,
        0,
        actionsInset,
        actionsInset,
      ),
      // Scrollable because the alternative is silent truncation, not an error.
      // At textScaler 3.0 on a 320-wide screen a translated message clips
      // mid-word inside the content box: no exception, no overflow stripe,
      // nothing a passing widget test would notice — and the user confirms a
      // delete having read half the sentence describing it.
      scrollable: true,
      title: Text(title),
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
            onPressed: isSubmitting ? null : onConfirm,
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
