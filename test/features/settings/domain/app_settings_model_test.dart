import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/settings/domain/models/app_language_model.dart';
import 'package:memox/features/settings/domain/models/app_settings_model.dart';
import 'package:memox/features/settings/domain/models/app_theme_mode_model.dart';
import 'package:memox/features/study/domain/models/new_card_order_model.dart';
import 'package:memox/features/study/domain/models/study_card_limit_model.dart';

/// The two appearance choices and the value that carries them (BR-186, BR-187).
void main() {
  group('AppThemeMode', () {
    test('every value round-trips through its stored form', () {
      for (final mode in AppThemeMode.values) {
        expect(AppThemeMode.fromDbValue(mode.dbValue), mode);
      }
    });

    test('an unreadable stored value falls back to system', () {
      // Tolerant on purpose, like `NewCardOrder`: an unreadable appearance
      // preference is not a reason to refuse to open the app, and the fallback
      // is what every build before v8 did.
      expect(AppThemeMode.fromDbValue('sepia'), AppThemeMode.system);
      expect(AppThemeMode.fromDbValue(''), AppThemeMode.system);
    });

    test('the three stored values are exactly what the CHECK admits', () {
      // The negative half matters more than the positive one: a fourth enum
      // value added without widening the column's CHECK would fail on write,
      // in production, on the one user who picked it.
      expect(AppThemeMode.values.map((mode) => mode.dbValue), <String>[
        'system',
        'light',
        'dark',
      ]);
    });
  });

  group('AppLanguage', () {
    test('every value round-trips through its stored form', () {
      for (final language in AppLanguage.values) {
        expect(AppLanguage.fromDbValue(language.dbValue), language);
      }
    });

    test('an unreadable stored value falls back to system', () {
      expect(AppLanguage.fromDbValue('fr'), AppLanguage.system);
    });

    test('system carries no language code, the other two carry theirs', () {
      // Null is not "missing": `MaterialApp.locale` takes the absence to mean
      // "resolve from the platform", which is exactly BR-187's `system`.
      expect(AppLanguage.system.languageCode, isNull);
      expect(AppLanguage.english.languageCode, 'en');
      expect(AppLanguage.vietnamese.languageCode, 'vi');
    });

    test('the three stored values are exactly what the CHECK admits', () {
      expect(AppLanguage.values.map((language) => language.dbValue), <String>[
        'system',
        'en',
        'vi',
      ]);
    });
  });

  group('AppSettingsModel.defaults', () {
    test('the card limit is Study\'s constant, not a second copy', () {
      // BR-183: one copy of the number. If someone retypes 20 here and BR-24
      // later moves, this is the assertion that notices.
      expect(AppSettingsModel.defaults.cardLimit, kDefaultCardLimit);
      expect(
        AppSettingsModel.defaults.cardLimit,
        StudyCardLimit.standard.value,
      );
    });

    test('it matches every column default in the schema', () {
      expect(AppSettingsModel.defaults.newCardOrder, NewCardOrder.created);
      expect(AppSettingsModel.defaults.themeMode, AppThemeMode.system);
      expect(AppSettingsModel.defaults.language, AppLanguage.system);
    });

    test('a change to any field makes it stop equalling the defaults', () {
      // Value equality is what the reset path relies on to assert it landed —
      // `expect(current, AppSettingsModel.defaults)` in the repository and
      // controller suites is only a real assertion if a single changed field
      // breaks it.
      expect(
        AppSettingsModel.defaults.copyWith(themeMode: AppThemeMode.dark),
        isNot(AppSettingsModel.defaults),
      );
      expect(
        AppSettingsModel.defaults.copyWith(cardLimit: 21),
        isNot(AppSettingsModel.defaults),
      );
      expect(
        AppSettingsModel.defaults.copyWith(language: AppLanguage.english),
        isNot(AppSettingsModel.defaults),
      );
    });
  });
}
