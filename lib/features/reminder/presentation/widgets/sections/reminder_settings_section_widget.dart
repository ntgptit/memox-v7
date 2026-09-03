import 'package:flutter/material.dart';

import '../../../../../core/theme/foundations/app_spacing.dart';
import '../../../../../core/theme/extensions/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_card.dart';
import '../../../../../shared/widgets/mx_icon.dart';
import '../../../domain/models/reminder_overview_model.dart';
import '../../../domain/models/reminder_time_model.dart';
import '../../../domain/failures/reminder_failure.dart';
import '../items/reminder_time_row_widget.dart';
import '../items/reminder_toggle_row_widget.dart';
import 'reminder_banner_section_widget.dart';

/// The whole body of the reminder screen (M6 W3…W6).
///
/// **One surface column.** The card and the banner share both edges, and the
/// supporting copy sits on the same gutter (M6 G1, G2) — which is what makes
/// the screen read as one decision rather than three stacked panels.
///
/// **Stateless, and every value comes in.** The stored choice arrives from the
/// database stream and the task status from the controller; nothing here
/// remembers a toggle position of its own, so a failed enable cannot leave the
/// switch showing something the database does not hold.
class ReminderSettingsSectionWidget extends StatelessWidget {
  const ReminderSettingsSectionWidget({
    required this.overview,
    required this.isBusy,
    required this.onEnabledChanged,
    required this.onTimePressed,
    required this.onRetry,
    this.rejection,
    super.key,
  });

  final ReminderOverviewModel overview;

  /// Whether any of the screen's three commands is in flight (UC-17 S3).
  final bool isBusy;

  /// Why the last command did not complete, if it did not (UC-17 E1…E4).
  final ReminderSetupRejection? rejection;

  final ValueChanged<bool> onEnabledChanged;
  final ValueChanged<ReminderTime> onTimePressed;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final settings = overview.settings;
    // Two different answers on purpose. The toggle stays operable on a
    // supported platform whenever no command is running; the time row also
    // needs the reminder to be on, because changing a time that schedules
    // nothing is a control with no effect (M6 R3, S2).
    // **An unsupported platform states itself, without waiting to be poked**
    // (M6 S7, BR-229). The rejection only ever arrives from a command, and on
    // this platform no command can run — the toggle is disabled — so deriving
    // the banner from the capability is the only way the state is reachable at
    // all. A live rejection still wins: it is the more recent thing to have
    // happened.
    final banner =
        rejection ??
        (overview.isChangeable
            ? null
            : ReminderSetupRejection.platformUnavailable);
    // **The banner decides the toggle, not just the capability snapshot.** The
    // capability is resolved once, when the screen opens; `EnableReminderUseCase`
    // reads it again at the moment of the tap, so a platform that stopped
    // answering in between refuses the command while the snapshot still says
    // supported. Without this the screen said "not available on this device"
    // beside a switch the user could still flip (M6 S7).
    final canToggle =
        overview.isChangeable &&
        !isBusy &&
        banner != ReminderSetupRejection.platformUnavailable;
    final canPickTime = canToggle && settings.isEnabled;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        MxCard.raised(
          // The rows own the horizontal gutter so their ink spans the card's
          // full width; only the vertical breath is this section's.
          padding: MxCardPadding.none,
          // `Material` inside the card, and it is not decoration: `MxCard`
          // paints its surface with a `DecoratedBox`, and `ListTile` paints its
          // background and ink onto the nearest `Material` ancestor — which
          // without this is the Scaffold, *behind* the card. Flutter asserts on
          // exactly that arrangement. Transparent, so the card's own colour is
          // still what shows.
          child: Material(
            type: MaterialType.transparency,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Column(
                children: <Widget>[
                  ReminderToggleRowWidget(
                    isEnabled: settings.isEnabled,
                    isChangeable: canToggle,
                    onChanged: onEnabledChanged,
                  ),
                  // The subtle divider Card Detail uses between an optional
                  // group and its content (M6 R2 restated in visual terms):
                  // the toggle and the time are one decision, so the seam
                  // between them reads as a hairline, not as two cards
                  // pretending to be one.
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    // The theme's divider — `outlineVariant`, which is what
                    // `borderSubtle` aliased; one spelling (M100.36 10H).
                    child: Divider(),
                  ),
                  ReminderTimeRowWidget(
                    time: settings.time,
                    isChangeable: canPickTime,
                    onTap: () => onTimePressed(settings.time),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (banner != null) ...<Widget>[
          const SizedBox(height: AppSpacing.lg),
          ReminderBannerSectionWidget(rejection: banner, onRetry: onRetry),
        ],
        const SizedBox(height: AppSpacing.lg),
        // **One quiet info panel, not two floating paragraphs** (M6 W6
        // restated in visual terms). Card Detail's own supporting-copy
        // grammar is `MxCard.muted` with a leading glyph; two sentences that
        // read as a contract belong inside one surface, and this panel keeps
        // the same edges as the schedule card and the banner above it
        // because it sits in the same stretch column, not because anything
        // measures it against them.
        MxCard.muted(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const MxIcon(Icons.info_outline, size: MxIconSize.sm),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      context.l10n.reminderDueOnlyNote,
                      style: context.texts.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      context.l10n.reminderPrivacyNote,
                      style: context.texts.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
