import 'package:flutter/material.dart';

/// The app's one way to say something transient.
///
/// **Exists so no feature builds a `SnackBar` again.** Seven call sites used
/// to assemble their own, and they disagreed about everything the user cannot
/// see: three announced themselves to screen readers, four did not; three
/// cleared the queue first, two hid only the current bar, two did neither.
/// The house pattern was already declared — `showMxUndoSnackBar` and the trash
/// screen both wrote *"the same liveRegion every other dynamically-appearing
/// message in the app carries"* — and this function is that declaration made
/// executable: **every message announces, every message clears the queue.**
///
/// Visuals come entirely from `SnackBarThemeData`; this file owns behaviour
/// only. There are deliberately no tone variants (success/error/info): the
/// design has not defined snack tone families, and the skill's own rule is
/// that a wrapper must not invent one ahead of it.
///
/// The undo flow keeps its own `showMxUndoSnackBar` — its 8-second duration
/// and async-refusal handling are a contract of their own, not a variant of
/// this one.
void showMxMessage(
  BuildContext context,
  String message, {
  String? actionLabel,
  VoidCallback? onAction,
}) => showMxMessageOn(
  ScaffoldMessenger.of(context),
  message,
  actionLabel: actionLabel,
  onAction: onAction,
);

/// [showMxMessage] for a messenger captured **before** an `await`.
///
/// The undo-failure paths need this: by the time an Undo is refused, the
/// context that started it may belong to a screen the user has already left,
/// and `ScaffoldMessenger.of` on a dead context is the crash this parameter
/// exists to prevent.
void showMxMessageOn(
  ScaffoldMessengerState messenger,
  String message, {
  String? actionLabel,
  VoidCallback? onAction,
}) {
  assert(
    (actionLabel == null) == (onAction == null),
    'an action needs both its label and its handler',
  );

  messenger
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        // Announced, not only drawn — the liveRegion every dynamically-
        // appearing message in the app carries.
        content: Semantics(liveRegion: true, child: Text(message)),
        action: actionLabel == null
            ? null
            : SnackBarAction(label: actionLabel, onPressed: onAction!),
      ),
    );
}
