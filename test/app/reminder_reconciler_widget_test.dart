import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/app/startup/reminder_reconciler_widget.dart';
import 'package:memox/core/time/clock_provider.dart';
import 'package:memox/core/time/time_zone_provider.dart';
import 'package:memox/features/reminder/di/reminder_platform_repository_provider.dart';
import 'package:memox/features/reminder/di/reminder_settings_repository_provider.dart';
import 'package:memox/features/reminder/domain/models/reminder_settings_model.dart';
import 'package:memox/features/reminder/domain/models/reminder_time_model.dart';

import '../features/reminder/support/fake_reminder_platform.dart';

/// The widget that wraps the whole app tree, and had no test at all.
///
/// **`lib/app/` is where two of the three seventy-PR breakages came from**, and
/// this is a startup widget that reads a provider on every launch and swallows
/// whatever it throws. The device half — real plugin registration, the worker's
/// second SQLite connection, Doze timing — genuinely needs an emulator and is
/// tracked as pending. The half asserted here does not: on a non-Android host
/// `initializeReminderPlatform` returns early, so the reconcile itself runs for
/// real against fake contracts, which is exactly the seam a host test can hold.
///
/// Two claims from the widget's own doc comment, neither of which was checked:
/// that it does not block the first frame, and that a failure is logged rather
/// than surfaced.
void main() {
  late FakeReminderSettings settings;
  late FakeReminderPlatform platform;

  setUp(() {
    settings = FakeReminderSettings(
      ReminderSettingsModel(
        isEnabled: true,
        time: ReminderTime.parse(20 * 60).time!,
      ),
    );
    platform = FakeReminderPlatform();
  });

  /// Runs [body] with the target platform reported as a host, and puts it back.
  Future<void> onHost(Future<void> Function() body) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    try {
      await body();
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  }

  Future<void> pump(WidgetTester tester) async {
    // **`flutter_test` reports Android by default**, so without this the widget
    // takes the real bootstrap path, reaches for two plugins that are not
    // registered, throws, and is swallowed by the very catch this file exists
    // to test — every assertion below would then pass on a widget that did
    // nothing. A host platform is what makes `initializeReminderPlatform`
    // return early, leaving the reconcile itself to run for real.
    //
    // Reset in a `finally` rather than through `setUp`/`addTearDown`: the
    // framework asserts every foundation debug variable is unset the moment a
    // test body returns, ahead of both, so the only reliable place is the body
    // itself.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          reminderSettingsRepositoryProvider.overrideWithValue(settings),
          reminderPlatformRepositoryProvider.overrideWithValue(platform),
          clockProvider.overrideWithValue(() => DateTime.utc(2026, 7, 29, 3)),
          utcOffsetProvider.overrideWithValue(() => const Duration(hours: 7)),
        ],
        child: ReminderReconcilerWidget(
          onOpenStudy: () {},
          child: const SizedBox.shrink(),
        ),
      ),
    );
  }

  testWidgets('the child renders, and the reconcile never gates it', (
    tester,
  ) async {
    await onHost(() async {
      // **Not "the schedule is still empty on the first frame".** That was the
      // first version of this test and it was wrong: the post-frame callback runs
      // at the end of the frame `pumpWidget` already produced, and a fake
      // platform answers on the same microtask, so the work is done before
      // anything can look. What is actually observable is that the child is up
      // and the tree is not held by a pending future — which is what the widget's
      // "does not block the first frame" claim means for anyone reading it.
      await pump(tester);

      expect(find.byType(SizedBox), findsOneWidget);
      expect(tester.binding.hasScheduledFrame, isFalse);
    });
  });

  testWidgets('an enabled reminder is re-armed once per launch (BR-227)', (
    tester,
  ) async {
    await onHost(() async {
      await pump(tester);
      await tester.pumpAndSettle();

      // One, not two: reconciling is idempotent, and a launch that stacked a
      // second pending run would double the notification the next evening.
      expect(platform.scheduled, hasLength(1));
      expect(platform.cancelCount, 0);
    });
  });

  testWidgets('a scheduler that refuses does not take down the launch', (
    tester,
  ) async {
    await onHost(() async {
      // The whole reason the catch is wide: a missing plugin, a refused scheduler
      // and a database that will not open all arrive here, and none of them may
      // stop the app the user opened to do something else.
      platform.shouldFailSchedule = true;

      await pump(tester);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(SizedBox), findsOneWidget);
    });
  });

  testWidgets('a reminder left off arms nothing at all (BR-218)', (
    tester,
  ) async {
    await onHost(() async {
      settings = FakeReminderSettings();

      await pump(tester);
      await tester.pumpAndSettle();

      expect(platform.scheduled, isEmpty);
      expect(
        platform.permissionRequests,
        0,
        reason:
            'a launch must not ask for a permission the user never opted into',
      );
      // The one observable that says the disabled branch *ran*, rather than
      // nothing having happened: both assertions above are equally true of a
      // reconcile that never fired.
      expect(platform.cancelCount, 1);
    });
  });
}
