import 'package:flutter/material.dart';

import '../../core/theme/foundations/app_spacing.dart';
import '../../core/theme/extensions/theme_context_extension.dart';
import 'mx_action_button.dart';
import 'mx_button_pair.dart';
import 'mx_dialog_metrics.dart';
import 'mx_dialog_tone.dart';
import 'mx_text_field.dart';
import '../../core/theme/extensions/app_ink.dart';

/// A form the user fills in without leaving the screen behind.
///
/// **The third overlay shape, and until now the only one with no shared
/// widget.** `showMxFormSheet` owns forms that come up from the bottom —
/// several fields, a keyboard, room to scroll — and `MxConfirmDialog` owns
/// questions with no input at all. Between them sat one hand-built
/// `AlertDialog` with a text field and two bare `TextButton`s, which is where
/// the bulk tag prompt lived: no `MxButtonPair`, so Cancel was a small button
/// beside a large one; no submitting state; and no way to say that what was
/// typed was refused.
///
/// **Dialog, not sheet, and the rule is the number of fields.** One field with
/// one decision is a question, and a sheet that slides up for it takes the
/// whole bottom of the screen to ask something a line can hold. Two or more
/// fields, or anything that needs room to scroll, is `showMxFormSheet` — that
/// one already carries the keyboard inset and the system-bar clearance a tall
/// form needs, and this one deliberately does not try to.
///
/// **It does not close itself**, for the same reason `MxConfirmDialog` does
/// not: the caller pops in its callback, once the work either succeeded or
/// failed. A dialog that dismissed on tap would unmount [isSubmitting] before
/// it could ever be seen.
class MxFormDialog extends StatelessWidget {
  const MxFormDialog({
    required this.title,
    required this.child,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.onConfirm,
    required this.onCancel,
    this.tone,
    this.errorMessage,
    this.isSubmitting = false,
    super.key,
  });

  /// Already-localized. The feature owns the copy; this never reads ARB.
  final String title;
  final String confirmLabel;
  final String cancelLabel;

  /// The fields. One `MxTextField` in the only caller today, but the parameter
  /// is a widget so a second field does not need a second dialog class.
  final Widget child;

  final MxDialogTone? tone;

  /// What went wrong with the form as a whole, already localized.
  ///
  /// **Form-level, not field-level.** A problem that belongs to one input
  /// belongs in that input's own `errorText`, where a screen reader announces
  /// it together with the field it is about. This slot is for the rest: the
  /// write was refused, the name is taken, the value could not be parsed at
  /// all.
  ///
  /// Null renders nothing — not an empty box that shifts the layout when a
  /// failure arrives.
  final String? errorMessage;

  /// While true both actions are inert and confirm shows a spinner. Submitting
  /// a form twice is the same double-write `MxConfirmDialog` guards against.
  final bool isSubmitting;

  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final errorMessage = this.errorMessage;

    return AlertDialog(
      // **The same two insets `MxConfirmDialog` states, and for the same
      // reason** (#348): a dialog's footer is not one page gutter in from the
      // screen, and a button pair left to assume that lays out a row 96px wider
      // than the line it actually has. Both labels then wrap, nothing
      // overflows, and no gate says a word.
      insetPadding: MxDialogMetrics.insetPadding,
      actionsPadding: MxDialogMetrics.actionsPadding,
      // Scrollable for the reason the confirm dialog is: at textScaler 3.0 on a
      // narrow screen the alternative is silent truncation, not an error.
      scrollable: true,
      title: MxDialogHeader(title: title, tone: tone),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          child,
          if (errorMessage != null) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            _FormError(message: errorMessage),
          ],
        ],
      ),
      actions: <Widget>[
        MxButtonPair(
          // No width passed: the pair measures the constraint it is handed, which
          // is this dialog's footer.
          secondary: MxActionButton(
            label: cancelLabel,
            onPressed: isSubmitting ? null : onCancel,
            variant: MxActionButtonVariant.secondary,
          ),
          primary: MxActionButton(
            label: confirmLabel,
            onPressed: isSubmitting ? null : onConfirm,
            isLoading: isSubmitting,
          ),
        ),
      ],
    );
  }
}

/// The form-level failure line.
///
/// **A live region, because it is the whole of the feedback.** The dialog stays
/// open, focus does not move and the title does not change, so without this a
/// screen-reader user presses the confirm button and is told nothing at all —
/// which is exactly what the bulk tag prompt did before this existed, for
/// everyone: it returned early on an unparseable tag and nothing happened.
class _FormError extends StatelessWidget {
  const _FormError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Text(
        message,
        style: context.texts.bodySmall!.inked(context, AppInk.error),
      ),
    );
  }
}

/// What a prompt's field turned into: the parsed value, or the reason it was
/// refused, already localized.
///
/// A record rather than two callbacks so the two cannot disagree — a validator
/// that passes beside a parser that returns null is a button that does nothing,
/// which is the exact defect [showMxPromptDialog] exists to prevent.
typedef MxPromptParse<T extends Object> =
    ({T? value, String? error}) Function(String raw);

/// Asks for one value, parses it, and returns it — or null if the user backed
/// out.
///
/// **The single-field case, which is the only form dialog this app has.** It
/// owns the three things its one caller was doing by hand, and getting one of
/// them wrong:
///
/// * the `TextEditingController` and its disposal;
/// * the parse, run once, on confirm;
/// * **and what happens when the parse refuses.** The bulk tag prompt read
///   `if (name == null) return;` inside its confirm button — so a tag that the
///   value object rejected produced a button press with no dialog change, no
///   message and no way to tell a refusal from a dropped tap. That is the bug
///   this function exists to make unwriteable: a refusal always says so.
///
/// **[parse] returns the value or the reason, and the reason is already
/// localized.** That split is the app's own: the domain says *which* rule
/// failed and the screen picks the ARB copy, so a field with four ways to be
/// wrong — a tag name is one — names the one that actually failed instead of
/// falling back to a single "invalid". No rule is re-derived here; the value
/// object stays the only place that decides.
///
/// Anything other than a successful parse returns null: the barrier, the back
/// gesture and Cancel all mean the same thing.
Future<T?> showMxPromptDialog<T extends Object>(
  BuildContext context, {
  required String title,
  required String fieldLabel,
  required String confirmLabel,
  required String cancelLabel,
  required MxPromptParse<T> parse,
  String? hintText,
  int? maxLength,
  MxDialogTone? tone,
}) => showDialog<T>(
  context: context,
  builder: (dialogContext) => _PromptDialog<T>(
    title: title,
    fieldLabel: fieldLabel,
    confirmLabel: confirmLabel,
    cancelLabel: cancelLabel,
    parse: parse,
    hintText: hintText,
    maxLength: maxLength,
    tone: tone,
  ),
);

class _PromptDialog<T extends Object> extends StatefulWidget {
  const _PromptDialog({
    required this.title,
    required this.fieldLabel,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.parse,
    required this.hintText,
    required this.maxLength,
    required this.tone,
  });

  final String title;
  final String fieldLabel;
  final String confirmLabel;
  final String cancelLabel;
  final MxPromptParse<T> parse;
  final String? hintText;
  final int? maxLength;
  final MxDialogTone? tone;

  @override
  State<_PromptDialog<T>> createState() => _PromptDialogState<T>();
}

class _PromptDialogState<T extends Object> extends State<_PromptDialog<T>> {
  final TextEditingController _controller = TextEditingController();

  /// The refusal, held only until the next keystroke.
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MxFormDialog(
      title: widget.title,
      tone: widget.tone,
      errorMessage: _error,
      confirmLabel: widget.confirmLabel,
      cancelLabel: widget.cancelLabel,
      onConfirm: _submit,
      onCancel: () => Navigator.of(context).pop(),
      child: MxTextField(
        controller: _controller,
        label: widget.fieldLabel,
        hintText: widget.hintText,
        maxLength: widget.maxLength,
        shouldAutofocus: true,
        textInputAction: TextInputAction.done,
        // Enter submits: the field is the whole form, so making the user reach
        // for a button after typing one word is a step with nothing in it.
        onSubmitted: (_) => _submit(),
        // **Clearing on the next keystroke, not on the next submit.** A refusal
        // that survives the edit that fixes it is a message describing text
        // that is no longer on screen.
        onChanged: _clearError,
      ),
    );
  }

  void _clearError(String _) {
    if (_error == null) return;
    setState(() => _error = null);
  }

  void _submit() {
    final ({T? value, String? error}) parsed = widget.parse(_controller.text);
    final T? value = parsed.value;
    if (value == null) {
      // **Never silently.** A parse that refused and said nothing is what the
      // bulk tag prompt used to do. If the caller somehow has no copy for this
      // refusal, the field still has to change — so the empty case is not a
      // branch that returns early here.
      setState(() => _error = parsed.error);

      return;
    }

    Navigator.of(context).pop(value);
  }
}
