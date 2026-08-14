// `dart:ui` for the one symbol this needs. The caller with the strongest claim
// to this file is a background isolate with no widget tree, so the locale comes
// from the engine rather than from a `BuildContext`.
import 'dart:ui' show Locale, PlatformDispatcher;

import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/models/reminder_summary_model.dart';

/// The two strings a reminder notification is made of.
///
/// A pair rather than two loose arguments so the mapper below returns one thing
/// and the adapter cannot assemble a body from something else.
final class ReminderMessage {
  const ReminderMessage({required this.title, required this.body});

  final String title;
  final String body;
}

/// Builds the notification title and body from a summary (BR-186).
///
/// **This is the only place the summary becomes words, and it can only reach
/// three numbers and one deck name.** `ReminderSummaryModel` has no field for
/// card content, a tag or a history row, so BR-186's privacy line is a property
/// of the inputs rather than a rule someone has to remember while writing a
/// sentence.
///
/// **Two variants, split on whether other decks are owed.** A single sentence
/// with a `0 more decks` tail reads as broken; one deck and several decks are
/// different sentences in both shipped locales.
///
/// **The locale is resolved from the platform, not from a `BuildContext`.** The
/// caller with the strongest claim to this function is the background isolate,
/// which has no widget tree at all — so the lookup goes through
/// `lookupAppLocalizations`, and an unsupported device language falls back to
/// the template locale rather than throwing at 8 p.m. inside a worker.
abstract final class ReminderMessageMapper {
  static ReminderMessage toMessage(
    ReminderSummaryModel summary,
    AppLocalizations l10n,
  ) => ReminderMessage(
    title: l10n.reminderNotificationTitle,
    body: summary.otherDeckCount == 0
        ? l10n.reminderNotificationBodyOneDeck(
            summary.totalDueCount,
            summary.leadDeckName,
          )
        : l10n.reminderNotificationBodyManyDecks(
            summary.otherDeckCount,
            summary.totalDueCount,
            summary.leadDeckName,
          ),
  );

  /// The localizations for the device language, with the template as fallback.
  static AppLocalizations localizationsForDevice() {
    final device = PlatformDispatcher.instance.locale;
    final isSupported = AppLocalizations.supportedLocales.any(
      (locale) => locale.languageCode == device.languageCode,
    );

    return lookupAppLocalizations(
      isSupported ? Locale(device.languageCode) : const Locale('en'),
    );
  }
}
