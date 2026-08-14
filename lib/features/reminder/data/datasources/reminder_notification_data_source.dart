import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../domain/models/reminder_capability_model.dart';

/// The Android notification channel the daily reminder posts into.
///
/// A constant because it is user-visible in system settings and because
/// changing it strands the channel the user has already configured: Android
/// keeps per-channel importance and sound, and a renamed id arrives as a new
/// channel with defaults.
const String kReminderChannelId = 'memox.daily_reminder';

/// The one notification id the reminder ever uses (BR-185).
///
/// Fixed on purpose: posting today's summary with the same id replaces
/// yesterday's if it is still on the shade, which is exactly "at most one
/// summary per day" expressed in the only place the OS can enforce it.
const int kReminderNotificationId = 1;

/// What a tapped reminder asks the app to open (BR-189).
///
/// A payload constant rather than a route path: the app navigates by name, and
/// a path is a URL contract no feature has any business writing into a
/// notification.
const String kReminderTapPayload = 'daily-reminder';

/// The notification plugin, wrapped so nothing above `data/` sees it (AD-21).
///
/// **Constructed with the plugin's own singleton by default.** The plugin holds
/// process-wide state — the initialization settings and the tap callback — so a
/// second instance would be a second registration. The seam exists for host
/// tests, not for the composition root to choose between platforms.
final class ReminderNotificationDataSource {
  ReminderNotificationDataSource({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  /// Prepares the plugin and registers the tap handler.
  ///
  /// Safe to call more than once: the plugin replaces its settings rather than
  /// stacking them, which is what lets both the app isolate and the background
  /// isolate call it without coordinating.
  ///
  /// The icon is the launcher icon under its Android resource name — the app
  /// ships no dedicated notification asset, and naming one that does not exist
  /// makes Android drop the notification silently.
  Future<void> initialize({
    void Function(String? payload)? onTap,
  }) => _plugin.initialize(
    settings: const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    ),
    onDidReceiveNotificationResponse: (response) =>
        onTap?.call(response.payload),
  );

  /// Whether this device will answer the plugin at all (BR-193).
  ///
  /// **A probe, not a platform check.** It asks the Android implementation a
  /// question with no side effect; a `MissingPluginException` — no plugin
  /// registered, or a platform this build does not ship it for — is the honest
  /// definition of "reminders are not available here", and it needs no
  /// `Platform.isAndroid` in any layer.
  ///
  /// `on Object` because a platform channel can throw anything, and every one
  /// of them means the same thing to a caller who only wants to know whether to
  /// show a toggle.
  Future<ReminderCapability> readCapability() async {
    try {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (android == null) return ReminderCapability.unsupported;

      await android.areNotificationsEnabled();

      return ReminderCapability.supported;
    } on Object {
      return ReminderCapability.unsupported;
    }
  }

  /// Asks for the Android 13+ notification permission (BR-192).
  ///
  /// `null` from the plugin means the platform had no answer — an older Android
  /// that needs no runtime permission returns it, and so does a resolution
  /// failure. Treated as granted, because on those versions posting is allowed;
  /// a refusal is only ever an explicit `false`.
  Future<ReminderPermission> requestPermission() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android == null) return ReminderPermission.notRequested;

    final granted = await android.requestNotificationsPermission();

    return granted == false
        ? ReminderPermission.denied
        : ReminderPermission.granted;
  }

  /// Posts the summary (BR-185, BR-186).
  ///
  /// Takes the two finished strings: the copy is built where the locale lives,
  /// and this method has no access to a card, a tag or a history row to leak.
  Future<void> show({required String title, required String body}) =>
      _plugin.show(
        id: kReminderNotificationId,
        title: title,
        body: body,
        payload: kReminderTapPayload,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            kReminderChannelId,
            'Daily reminder',
            channelDescription: 'A once-a-day summary of the cards you owe.',
            // Importance and priority are left at the plugin defaults on
            // purpose: a study reminder is not urgent, and stating the default
            // trips `avoid_redundant_argument_values`, a lint this project
            // promoted to an error.
          ),
        ),
      );

  /// Removes the reminder from the shade, if it is there.
  Future<void> cancel() => _plugin.cancel(id: kReminderNotificationId);

  /// The payload of the notification that launched the app, if one did.
  ///
  /// `null` when the app was started any other way — which is every launch that
  /// is not BR-189's tap.
  Future<String?> readLaunchPayload() async {
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details == null || !details.didNotificationLaunchApp) return null;

    return details.notificationResponse?.payload;
  }
}
