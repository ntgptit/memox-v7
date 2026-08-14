@Tags(<String>['golden', 'screen-audit'])
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/time/clock_provider.dart';
import 'package:memox/core/time/time_zone_provider.dart';
import 'package:memox/features/reminder/di/reminder_platform_repository_provider.dart';
import 'package:memox/features/reminder/di/reminder_settings_repository_provider.dart';
import 'package:memox/features/reminder/di/reminder_workload_repository_provider.dart';
import 'package:memox/features/reminder/domain/models/reminder_settings_model.dart';
import 'package:memox/features/reminder/domain/models/reminder_time_model.dart';
import 'package:memox/features/reminder/presentation/screens/reminder_settings_screen.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_content_shell.dart';

import '../../../../audit_allowance.dart';
import '../../../../audit_model.dart';
import '../../../../audit_rules.dart';
import '../../../../memox_audit.dart';
import '../../../../screen_auditor.dart';
import '../../../../../features/reminder/support/fake_reminder_platform.dart';

/// Strict visual audit for `ReminderSettingsScreen`.
///
/// Companion of the screen at the mirrored path; MX-VIS-001 checks this file
/// exists, imports the screen, and calls the strict helper.
///
/// **The on state is what is audited.** Both rows, both disclosure paragraphs
/// and the time value are on screen, and every one of them paints a palette
/// token. The off state is deliberately not the subject: its time row is
/// disabled, and `ListTile` greys a disabled row with Material's own
/// `onSurface` at 38% rather than with a token — a framework default this
/// screen does not choose and the strict palette closure cannot resolve. That
/// state is covered by `reminder_settings_screen_test.dart`, which asserts what
/// it must: the row is present, readable and not operable.
///
/// The error banner adds one card whose edges are asserted against this one in
/// the same widget test (M6 G1).
void main() {
  memoxProductionScreenAuditTest(
    'reminder_settings_screen',
    () => ProviderScope(
      overrides: [
        reminderSettingsRepositoryProvider.overrideWithValue(
          FakeReminderSettings(
            const ReminderSettingsModel(
              isEnabled: true,
              time: ReminderTime.suggested,
            ),
          ),
        ),
        reminderPlatformRepositoryProvider.overrideWithValue(
          FakeReminderPlatform(),
        ),
        reminderWorkloadRepositoryProvider.overrideWithValue(
          FakeReminderWorkload(),
        ),
        clockProvider.overrideWithValue(() => DateTime.utc(2026, 7, 29, 3)),
        utcOffsetProvider.overrideWithValue(() => const Duration(hours: 7)),
      ],
      child: const ReminderSettingsScreen(),
    ),
    // This screen declares one surface column (M99.19a, M6 G1): the settings
    // card and the error banner span it, or stack. Opted in explicitly,
    // because a layout rule is a screen's own declaration.
    surfaceFinder: find.byType(MxCard),
    additionalRules: const <AuditRule>[SurfaceColumnRule()],
    anchors: <AuditAnchor>[AuditAnchor.type('shell', MxContentShell)],
    drive: (tester) => tester.pumpAndSettle(),
    allowances: const <AuditSkipAllowance>[
      AuditSkipAllowance(
        itemId: 'shell',
        reason: SkipReason.rasterOnly,
        detailContains: '_RenderInkFeatures',
        expectedMatches: 3,
        rationale:
            'The Material ink layers of the Scaffold, the AppBar and the '
            'transparent Material inside the settings card. Splash and '
            'highlight paint into these; the overlay colours are asserted in '
            'app_theme_test.dart.',
      ),
      AuditSkipAllowance(
        itemId: 'shell',
        reason: SkipReason.customPainter,
        detailContains: '_SwitchPainter',
        rationale:
            'The toggle draws its track and thumb through a CustomPainter; its '
            'colours come from SwitchThemeData and are pinned by the '
            'mx_components goldens.',
      ),
      AuditSkipAllowance(
        itemId: 'shell',
        reason: SkipReason.customPainter,
        detailContains: 'no painter',
        rationale:
            'A clip with no painter of its own, behind the time row.',
      ),
      AuditSkipAllowance(
        itemId: 'screen',
        reason: SkipReason.rasterOnly,
        detailContains: '_RenderColoredBox',
        rationale:
            'The route backdrop MaterialApp paints around an opaque page. It '
            'renders Colors.transparent at rest and ColorScheme.surface only '
            'mid-transition; the surface value is asserted in '
            'app_theme_test.dart.',
      ),
    ],
  );
}
