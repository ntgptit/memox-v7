import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/settings/data/repositories/app_settings_repository_impl.dart';
import 'package:memox/features/settings/domain/models/app_language_model.dart';
import 'package:memox/features/settings/domain/models/app_settings_model.dart';
import 'package:memox/features/settings/domain/models/app_theme_mode_model.dart';
import 'package:memox/features/settings/domain/repositories/app_settings_repository.dart';
import 'package:memox/features/study/domain/models/new_card_order_model.dart';
import 'package:memox/features/study/domain/models/study_card_limit_model.dart';
import 'package:memox/core/database/app_database.dart';

import '../../../database/support/test_database.dart';

/// `AppSettingsRepositoryImpl` against a real SQLite database (BR-182…BR-189).
///
/// Real, not a mock: every claim here — the single row, the `CHECK` that keeps
/// it single, a stream that re-emits on write, a reset that writes the column
/// defaults — is behaviour of SQLite and of the schema, and a fake executor
/// would only assert that the code calls the API it was written to call.
void main() {
  final DateTime writeAt = DateTime.utc(2026, 8, 14, 9);

  ({AppSettingsRepository repository, AppDatabase db}) build() {
    final db = openTestDatabase();

    return (
      repository: AppSettingsRepositoryImpl(db, clock: () => writeAt),
      db: db,
    );
  }

  /// A root deck carrying a `study_config` override (BR-147).
  ///
  /// Raw SQL rather than the deck repository: this file is about the settings
  /// row, and pulling a second feature's write path in would make a failure
  /// here ambiguous about which half broke.
  Future<void> seedRootWithOverride(AppDatabase db) => db.customStatement(
    'INSERT INTO decks (id, name, root_deck_id, content_type, scheduler_type, '
    'scheduler_version, scheduler_generation, study_config, created_at, '
    'updated_at) '
    "VALUES ('root', 'Korean', 'root', 'deck', 'eight_box', 1, 1, "
    "'{\"card_limit\":30,\"new_card_order\":\"random\"}', 8, 8)",
  );

  /// One card that has finished the learning chain, so a reset that reached
  /// learning state would be visible as a lost `learned_at` (BR-189).
  Future<void> seedLearnedCard(AppDatabase db) async {
    await db.customStatement(
      'INSERT INTO decks (id, name, parent_deck_id, root_deck_id, '
      'content_type, created_at, updated_at) '
      "VALUES ('words', 'Words', 'root', 'root', 'card', 8, 8)",
    );
    await db.customStatement(
      'INSERT INTO cards (id, deck_id, front, back, front_folded, back_folded, '
      'created_at, updated_at) '
      "VALUES ('c1', 'words', '연구자', 'researcher', '연구자', 'researcher', "
      '8, 8)',
    );
    await db.customStatement(
      'INSERT INTO card_study_states (card_id, scheduler_type, '
      'scheduler_version, scheduler_generation, learned_at, due_at, '
      'answer_count, lapse_count, current_box) '
      "VALUES ('c1', 'eight_box', 1, 1, 8, 9, 1, 0, 2)",
    );
  }

  Future<String?> studyConfigOf(AppDatabase db, String deckId) async {
    final row = await db
        .customSelect("SELECT study_config FROM decks WHERE id = '$deckId'")
        .getSingle();

    return row.data['study_config'] as String?;
  }

  Future<int> countOf(AppDatabase db, String sql) async {
    final row = await db.customSelect(sql).getSingle();

    return row.data.values.first! as int;
  }

  Future<DateTime> settingsUpdatedAt(AppDatabase db) async {
    final row = await db
        .customSelect('SELECT updated_at FROM app_settings WHERE id = 1')
        .getSingle();

    return DateTime.fromMillisecondsSinceEpoch(
      (row.data['updated_at']! as int) * 1000,
      isUtc: true,
    );
  }

  group('watch', () {
    test('emits the seeded defaults on a fresh database', () async {
      // The row is seeded by `onCreate`, so this also proves a fresh install
      // has one — the case the v5 migration cannot cover.
      final fixture = build();

      expect(await fixture.repository.watch().first, AppSettingsModel.defaults);
    });

    test('re-emits after every write, which is how one save updates every '
        'open surface', () async {
      final fixture = build();
      final seen = <AppSettingsModel>[];
      final subscription = fixture.repository.watch().listen(seen.add);
      addTearDown(subscription.cancel);

      await pumpEventQueue();
      await fixture.repository.saveThemeMode(AppThemeMode.dark);
      await pumpEventQueue();
      await fixture.repository.saveLanguage(AppLanguage.vietnamese);
      await pumpEventQueue();

      expect(seen.first, AppSettingsModel.defaults);
      expect(seen.last.themeMode, AppThemeMode.dark);
      expect(seen.last.language, AppLanguage.vietnamese);
      // BR-182: the surfaces subscribe, they are not told to re-read. Three
      // emissions for one initial state and two writes.
      expect(seen, hasLength(3));
    });

    test('an error on the stream reaches the subscriber as a Failure', () async {
      // **The one path a try/catch cannot cover.** A `watchSingle` reports a
      // failure as an error *event*, not as a thrown exception, so the
      // `handleError` in the repository is the only thing standing between a
      // raw driver error and the UI — and without a test it is a claim in a doc
      // comment (AD-01).
      //
      // Deleting the row is a real way to produce one: the table notifies, the
      // query re-runs, and `watchSingle` errors on zero rows. That is also
      // exactly the state BR-182 calls a defect rather than a valid reading.
      final fixture = build();
      final errors = <Object>[];
      final subscription = fixture.repository.watch().listen(
        (_) {},
        onError: errors.add,
      );
      addTearDown(subscription.cancel);

      await pumpEventQueue();
      // The generated delete, not `customStatement`: a raw statement does not
      // tell drift which tables it touched, so nothing re-runs the query and
      // the stream simply stays quiet — a test that would pass on a repository
      // with no error handling at all.
      await fixture.db.delete(fixture.db.appSettings).go();
      await pumpEventQueue();

      expect(errors, isNotEmpty);
      expect(errors.first, isA<Failure>());
    });
  });

  group('saveStudyDefaults', () {
    test(
      'stores both values and leaves the appearance choices alone',
      () async {
        // BR-188: one group is one transaction. Saving the study defaults must
        // not carry a theme along with it.
        final fixture = build();
        await fixture.repository.saveThemeMode(AppThemeMode.light);

        await fixture.repository.saveStudyDefaults(
          cardLimit: StudyCardLimit.parse('35').limit!,
          newCardOrder: NewCardOrder.random,
        );

        final settings = await fixture.repository.watch().first;
        expect(settings.cardLimit, 35);
        expect(settings.newCardOrder, NewCardOrder.random);
        expect(settings.themeMode, AppThemeMode.light);
      },
    );

    test('writes no deck override', () async {
      // BR-183/BR-184: the app-wide defaults and a root deck's override are two
      // different rows in two different tables, and this write touches one.
      final fixture = build();
      await seedRootWithOverride(fixture.db);

      await fixture.repository.saveStudyDefaults(
        cardLimit: StudyCardLimit.parse('35').limit!,
        newCardOrder: NewCardOrder.random,
      );

      expect(await studyConfigOf(fixture.db, 'root'), isNotNull);
    });

    test('stamps updated_at from the injected clock', () async {
      // AD-16: nothing under `lib/features/` reads the wall clock, so the
      // stamp has to be the one the composition root passed in.
      final fixture = build();

      await fixture.repository.saveStudyDefaults(
        cardLimit: StudyCardLimit.standard,
        newCardOrder: NewCardOrder.created,
      );

      expect(await settingsUpdatedAt(fixture.db), writeAt);
    });
  });

  group('saveThemeMode and saveLanguage', () {
    test('each stores its own column and only its own', () async {
      final fixture = build();

      await fixture.repository.saveThemeMode(AppThemeMode.dark);
      var settings = await fixture.repository.watch().first;
      expect(settings.themeMode, AppThemeMode.dark);
      expect(settings.language, AppLanguage.system);
      expect(settings.cardLimit, AppSettingsModel.defaults.cardLimit);

      await fixture.repository.saveLanguage(AppLanguage.english);
      settings = await fixture.repository.watch().first;
      expect(settings.language, AppLanguage.english);
      expect(settings.themeMode, AppThemeMode.dark);
    });

    test('an explicit choice survives being read back, which is what '
        'restart means here', () async {
      // A restart is a new repository over the same database file. Two
      // repositories over one database is the closest a host test gets, and it
      // is the part that actually matters: the value is in SQLite, not in a
      // provider (BR-182, BR-186, BR-187).
      final db = openTestDatabase();
      final first = AppSettingsRepositoryImpl(db, clock: () => writeAt);
      await first.saveThemeMode(AppThemeMode.dark);
      await first.saveLanguage(AppLanguage.vietnamese);

      final second = AppSettingsRepositoryImpl(db, clock: () => writeAt);
      final settings = await second.watch().first;

      expect(settings.themeMode, AppThemeMode.dark);
      expect(settings.language, AppLanguage.vietnamese);
    });
  });

  group('resetToDefaults', () {
    test('puts all four values back', () async {
      final fixture = build();
      await fixture.repository.saveStudyDefaults(
        cardLimit: StudyCardLimit.parse('35').limit!,
        newCardOrder: NewCardOrder.random,
      );
      await fixture.repository.saveThemeMode(AppThemeMode.dark);
      await fixture.repository.saveLanguage(AppLanguage.vietnamese);

      await fixture.repository.resetToDefaults();

      expect(await fixture.repository.watch().first, AppSettingsModel.defaults);
    });

    test('touches no deck override, no card and no study state', () async {
      // BR-189, and the negative half of it is the point: this app has a second
      // action whose name starts with "Reset" and it clears every schedule.
      final fixture = build();
      await seedRootWithOverride(fixture.db);
      await seedLearnedCard(fixture.db);

      await fixture.repository.resetToDefaults();

      expect(await studyConfigOf(fixture.db, 'root'), isNotNull);
      expect(await countOf(fixture.db, 'SELECT COUNT(*) AS n FROM cards'), 1);
      expect(
        await countOf(
          fixture.db,
          'SELECT COUNT(*) AS n FROM card_study_states '
          'WHERE learned_at IS NOT NULL',
        ),
        1,
      );
    });
  });

  group('the single row', () {
    test('a second row cannot be inserted', () async {
      // The CHECK is what makes "the settings" one answer rather than
      // "whichever row was read first" (BR-182).
      final fixture = build();

      expect(
        fixture.db.customStatement(
          'INSERT INTO app_settings (id, card_limit, new_card_order, '
          "theme_mode, language, updated_at) VALUES (2, 20, 'created', "
          "'system', 'system', 8)",
        ),
        throwsA(isA<Object>()),
      );
    });

    test('the row still holds exactly one row after every write', () async {
      final fixture = build();
      await fixture.repository.saveThemeMode(AppThemeMode.dark);
      await fixture.repository.resetToDefaults();

      expect(
        await countOf(fixture.db, 'SELECT COUNT(*) AS n FROM app_settings'),
        1,
      );
    });
  });

  group('failures', () {
    test('a database error crossing the boundary arrives as a Failure', () async {
      // AD-01: the layer above this one speaks `Failure` and never sees a Drift
      // exception. Closing the database is the cheapest genuine failure.
      // A statement against a table the schema does not have: a genuine
      // SQLite error raised inside the repository's own `_guard`, rather than
      // a closed connection — closing the database resolves writes to null in
      // this driver and would assert nothing.
      final fixture = build();
      await fixture.db.customStatement('DROP TABLE app_settings');

      await expectLater(
        fixture.repository.saveThemeMode(AppThemeMode.dark),
        throwsA(isA<Failure>()),
      );
    });
  });
}
