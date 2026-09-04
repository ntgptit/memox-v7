import 'package:flutter/material.dart';

import '../../../../../l10n/l10n_extension.dart';
import '../../../domain/failures/reminder_failure.dart';
import '../../../domain/models/reminder_time_model.dart';
import '../../../../../shared/widgets/mx_feedback_band.dart';

/// The banner copy for one rejection: a heading, a body, and whether it can be
/// retried at all.
///
/// The third field is the one worth having as data. `platformUnavailable` has
/// no recovery (M6 R5, S7), and a screen that decided that by re-matching the
/// enum would be a second owner of the rule — free to grow a retry button for a
/// state that can never change.
final class ReminderBanner {
  const ReminderBanner({
    required this.title,
    required this.message,
    required this.isRetryable,
    this.tone = MxFeedbackTone.danger,
  });

  final String title;
  final String message;
  final bool isRetryable;

  /// Which band carries it. Mapped **per value** (A20.1 P1-13): a refused OS
  /// permission is not a failure of the app, it is a condition the user can
  /// change in settings, and painting it as an error said something untrue.
  final MxFeedbackTone tone;
}

/// Where a reminder domain value becomes something a person reads.
///
/// One place, for the reason `DeckLabels` states: every mapping here is a
/// `switch` over a closed set, so adding a rejection fails to compile until it
/// has copy. It carries the `_widget` suffix the naming rule requires of
/// everything under `presentation/` even though it holds no widget — the same
/// deliberate mismatch, and inventing a wrapper widget to satisfy the suffix
/// would be worse.
extension ReminderLabels on BuildContext {
  /// The time, formatted by the platform's own conventions.
  ///
  /// **`MaterialLocalizations`, not an ARB entry and not `intl` directly.** A
  /// 24-hour locale and a device with the 24-hour setting on are different
  /// questions, and only this knows both — a hand-rolled `HH:mm` would print
  /// `20:00` to a user whose phone says `8:00 PM` everywhere else.
  ///
  /// **The device's 12/24-hour setting travels with it** (A20.1 P2-16).
  /// `formatTimeOfDay` defaults `alwaysUse24HourFormat` to false, while the
  /// picker the row opens reads `MediaQuery.alwaysUse24HourFormat` — so a
  /// 24-hour phone showed `8:00 PM` on the row and `20:00` in the picker.
  String reminderTimeText(ReminderTime time) =>
      MaterialLocalizations.of(this).formatTimeOfDay(
        TimeOfDay(hour: time.hour, minute: time.minute),
        alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(this),
      );

  /// The accessibility value of the toggle (M6 R7).
  ///
  /// Exists so the state is spoken as a word rather than inferred from the
  /// switch's colour, which is the one signal a colour-blind or screen-reader
  /// user does not get.
  String reminderToggleValue({required bool isEnabled}) =>
      isEnabled ? l10n.reminderStatusOn : l10n.reminderStatusOff;

  /// The banner for a rejection (UC-17 E1…E4, E6).
  ReminderBanner reminderBanner(ReminderSetupRejection rejection) =>
      switch (rejection) {
        ReminderSetupRejection.platformUnavailable => ReminderBanner(
          title: l10n.reminderUnavailableTitle,
          message: l10n.reminderUnavailableMessage,
          isRetryable: false,
        ),
        ReminderSetupRejection.permissionDenied => ReminderBanner(
          title: l10n.reminderPermissionDeniedTitle,
          message: l10n.reminderPermissionDeniedMessage,
          isRetryable: true,
          tone: MxFeedbackTone.warning,
        ),
        ReminderSetupRejection.scheduleFailed => ReminderBanner(
          title: l10n.reminderScheduleErrorTitle,
          message: l10n.reminderScheduleErrorMessage,
          isRetryable: true,
        ),
        ReminderSetupRejection.cancelFailed => ReminderBanner(
          title: l10n.reminderCancelErrorTitle,
          message: l10n.reminderCancelErrorMessage,
          isRetryable: true,
        ),
        ReminderSetupRejection.settingsWriteFailed => ReminderBanner(
          title: l10n.reminderSaveErrorTitle,
          message: l10n.reminderSaveErrorMessage,
          isRetryable: true,
        ),
      };
}
