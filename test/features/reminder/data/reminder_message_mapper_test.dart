import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/reminder/data/mappers/reminder_message_mapper.dart';
import 'package:memox/features/reminder/domain/models/reminder_summary_model.dart';
import 'package:memox/features/reminder/domain/models/reminder_workload_model.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';
import 'package:memox/l10n/generated/app_localizations_vi.dart';

/// The sentence a notification actually shows.
///
/// **Nothing pinned this, which is the odd part: it is the feature's whole
/// output.** The delivery use case is tested against a fake platform that never
/// calls the mapper, the platform adapter's test covers scheduling delay, and
/// the ARB templates were only ever read by eye. So every plural boundary and
/// every placeholder here was one edit away from silently reading wrong on a
/// device, at 8 p.m., with no way to see it from the host suite.
///
/// **BR-222 gets no test here on purpose.** "The notification carries nothing
/// but counts and one deck name" is enforced by `ReminderSummaryModel`'s field
/// set — there is no field a card, a tag or a history row could travel through,
/// so the mapper cannot reach one. A runtime assertion would have to guess at
/// strings that could never appear, and a test that cannot fail is worse than
/// the type that makes it unnecessary.
///
/// The two locales are asserted separately rather than through a shared
/// expectation, because they are genuinely different sentences: English splits
/// `=1` from `other` for the card count, and Vietnamese has no plural forms at
/// all, so its templates collapse to one branch. A test that asserted "the
/// count appears somewhere" would pass on both and prove neither.
void main() {
  ReminderWorkloadModel deck(
    String name, {
    int overdue = 0,
    int dueToday = 0,
  }) => ReminderWorkloadModel(
    deckId: name,
    deckName: name,
    overdueCount: overdue,
    dueTodayCount: dueToday,
    overdueDayCount: 0,
  );

  ReminderSummaryModel summaryOf(List<ReminderWorkloadModel> decks) {
    final summary = ReminderSummaryModel.build(decks);
    expect(summary, isNotNull, reason: 'the fixture owes something');

    return summary!;
  }

  group('English', () {
    final l10n = AppLocalizationsEn();

    test('one deck, one card — the singular branch', () {
      final message = ReminderMessageMapper.toMessage(
        summaryOf(<ReminderWorkloadModel>[deck('Korean verbs', overdue: 1)]),
        l10n,
      );

      expect(message.title, 'Time to study');
      expect(message.body, '1 card is due in Korean verbs');
    });

    test('one deck, several cards — the plural branch', () {
      final message = ReminderMessageMapper.toMessage(
        summaryOf(<ReminderWorkloadModel>[deck('Korean verbs', overdue: 7)]),
        l10n,
      );

      expect(message.body, '7 cards are due in Korean verbs');
    });

    test('exactly one other deck reads "1 more deck", not "1 more decks"', () {
      // The boundary the `others` plural exists for. Two decks, so the tail is
      // singular while the card count is not.
      final message = ReminderMessageMapper.toMessage(
        summaryOf(<ReminderWorkloadModel>[
          deck('Korean verbs', overdue: 5),
          deck('Hanja', overdue: 2),
        ]),
        l10n,
      );

      expect(message.body, '7 cards are due in Korean verbs and 1 more deck');
    });

    test(
      'several other decks read "N more decks", and N excludes the lead',
      () {
        // BR-224: the total counts every due card once, and `others` counts the
        // decks *besides* the lead — three decks owing, so two others.
        final message = ReminderMessageMapper.toMessage(
          summaryOf(<ReminderWorkloadModel>[
            deck('Korean verbs', overdue: 5),
            deck('Hanja', overdue: 2),
            deck('Idioms', dueToday: 1),
          ]),
          l10n,
        );

        expect(
          message.body,
          '8 cards are due in Korean verbs and 2 more decks',
        );
      },
    );
  });

  group('Vietnamese', () {
    final l10n = AppLocalizationsVi();

    test('one deck reads the same shape at one card and at many', () {
      // Vietnamese has no plural forms, so both counts take the one branch.
      // Asserted rather than assumed: an ARB edit that added `=1` to the
      // Vietnamese template would be wrong, and only this notices.
      final one = ReminderMessageMapper.toMessage(
        summaryOf(<ReminderWorkloadModel>[deck('Động từ', overdue: 1)]),
        l10n,
      );
      final many = ReminderMessageMapper.toMessage(
        summaryOf(<ReminderWorkloadModel>[deck('Động từ', overdue: 7)]),
        l10n,
      );

      expect(one.title, 'Đến giờ học rồi');
      expect(one.body, '1 thẻ đến hạn trong Động từ');
      expect(many.body, '7 thẻ đến hạn trong Động từ');
    });

    test('other decks are counted the same way as in English', () {
      final message = ReminderMessageMapper.toMessage(
        summaryOf(<ReminderWorkloadModel>[
          deck('Động từ', overdue: 5),
          deck('Hán tự', overdue: 2),
        ]),
        l10n,
      );

      expect(message.body, '7 thẻ đến hạn trong Động từ và 1 deck khác');
    });
  });
}
