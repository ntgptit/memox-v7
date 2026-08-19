import 'package:flutter/material.dart';

/// How long an Undo offer stays reachable.
///
/// **Not a motion token.** `AppDurations` is the 120/200/320 animation scale;
/// this is a reading budget, and the two must not be tied together — shortening
/// an animation must never shorten the window in which data can be rescued.
///
/// Twice Material's four-second default, because four seconds is not enough to
/// read a sentence, notice the mistake and reach the button — least of all at a
/// large text scale, where the message wraps (R6).
const Duration kMxUndoDuration = Duration(seconds: 8);

/// A result message with one reversing action beside it.
///
/// **Pure UI, and it knows nothing about Trash.** The message, the label and
/// what "undo" does all arrive as arguments, so the widget layer that owns the
/// deletion owns its own wiring — a feature must not reach into another
/// feature's `presentation/` to find a snackbar.
///
/// [onUndo] returns whatever went wrong, or null on success, matching the shape
/// every controller command in this app uses. It is called at most once: the
/// snackbar is dismissed before the work starts, so a second tap is impossible
/// rather than merely unlikely.
///
/// The window is [kMxUndoDuration]; see there for why it is not a motion token.
void showMxUndoSnackBar(
  BuildContext context, {
  required String message,
  required String undoLabel,
  required Future<Object?> Function() onUndo,
  required void Function(Object error) onUndoFailed,
}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        // Announced, not only drawn — the undo window is short, and a screen
        // reader user who is not told it opened cannot use it at all.
        content: Semantics(liveRegion: true, child: Text(message)),
        duration: kMxUndoDuration,
        action: SnackBarAction(
          label: undoLabel,
          onPressed: () async {
            messenger.hideCurrentSnackBar();
            final error = await onUndo();
            if (error == null) return;
            onUndoFailed(error);
          },
        ),
      ),
    );
}
