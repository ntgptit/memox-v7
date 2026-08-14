import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/settings/domain/models/app_language_model.dart';
import 'package:memox/features/settings/domain/models/app_settings_model.dart';
import 'package:memox/features/settings/domain/models/app_theme_mode_model.dart';
import 'package:memox/features/settings/presentation/widgets/items/settings_error_band_widget.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';
import 'package:memox/l10n/generated/app_localizations_vi.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_loading_state.dart';
import 'package:memox/shared/widgets/mx_text_field.dart';
import 'package:memox/features/study/domain/models/new_card_order_model.dart';

import '../domain/support/fake_app_settings_repository.dart';
import 'support/settings_widget_harness.dart';

/// The seven states of the Settings screen (UC-12, wireframe W3).
void main() {
  final english = AppLocalizationsEn();
  final vietnamese = AppLocalizationsVi();

  /// The radio row for [label], which is what a user taps.
  ///
  /// `byWidgetPredicate` rather than `byType`: `RadioListTile` is generic and
  /// `find.byType(RadioListTile<Object>)` matches no `RadioListTile<AppThemeMode>`
  /// at all — it fails by finding nothing, which reads like the row is missing.
  Finder choiceRow(String label) => find.ancestor(
    of: find.text(label),
    matching: find.byWidgetPredicate((widget) => widget is RadioListTile),
  );

  /// Scrolls [label] into view, then taps it.
  ///
  /// `ensureVisible` first, because the Language group sits below the fold at
  /// every phone size — a bare `tap()` on an off-screen row warns about a
  /// missed hit test and then asserts on a write that never happened, which
  /// reads as a broken control rather than a test that never touched one.
  Future<void> tapChoice(WidgetTester tester, String label) async {
    await tester.ensureVisible(find.text(label));
    await tester.pumpAndSettle();
    await tester.tap(choiceRow(label));
    await tester.pumpAndSettle();
  }

  group('loaded', () {
    testWidgets('shows all three groups at their persisted values', (
      tester,
    ) async {
      await pumpSettings(
        tester,
        FakeAppSettingsRepository(
          initial: const AppSettingsModel(
            cardLimit: 35,
            newCardOrder: NewCardOrder.random,
            themeMode: AppThemeMode.dark,
            language: AppLanguage.vietnamese,
          ),
        ),
      );

      expect(find.text(english.settingsStudyDefaultsSection), findsOneWidget);
      expect(find.text(english.settingsAppearanceSection), findsOneWidget);
      expect(find.text(english.settingsLanguageSection), findsOneWidget);
      // The field opens on the stored number, not a placeholder: a placeholder
      // would be a value the user has to guess at (W3 state 3).
      expect(
        tester.widget<MxTextField>(find.byType(MxTextField)).controller.text,
        '35',
      );
    });

    testWidgets('the reset action and its scope sentence are on screen at '
        'rest', (tester) async {
      // BR-189: two actions in this app begin with "Reset", and the sentence
      // is what tells them apart. Hiding it inside the confirmation would make
      // the user open a dialog to find out which one they are looking at.
      await pumpSettings(tester, FakeAppSettingsRepository());

      expect(find.text(english.settingsResetAction), findsOneWidget);
      expect(find.text(english.settingsResetDescription), findsOneWidget);
    });

    testWidgets('the reset action stays available when nothing is off '
        'default', (tester) async {
      // W3 state 2: "already at defaults" is not a state the user should have
      // to infer from a missing control.
      await pumpSettings(tester, FakeAppSettingsRepository());

      final button = find.ancestor(
        of: find.text(english.settingsResetAction),
        matching: find.byType(TextButton),
      );

      expect(tester.widget<TextButton>(button).onPressed, isNotNull);
    });
  });

  group('loading and read failure', () {
    testWidgets('nothing renders a value before the first emission', (
      tester,
    ) async {
      // BR-182: a control showing `System` before the row has been read is a
      // value nobody stored.
      await pumpSettings(
        tester,
        _NeverEmittingRepository(),
        shouldSettle: false,
      );

      expect(find.byType(MxLoadingState), findsOneWidget);
      expect(find.text(english.settingsAppearanceSection), findsNothing);
    });

    testWidgets('a failed read is a whole-screen error with a retry', (
      tester,
    ) async {
      await pumpSettings(tester, UnreadableAppSettingsRepository());

      expect(find.byType(MxErrorState), findsOneWidget);
      expect(find.text(english.settingsLoadErrorTitle), findsOneWidget);
      expect(find.text(english.settingsAppearanceSection), findsNothing);
    });
  });

  group('writing', () {
    testWidgets('tapping a theme writes it and the marked row follows the '
        'persisted value', (tester) async {
      final repository = FakeAppSettingsRepository();
      await pumpSettings(tester, repository);

      await tapChoice(tester, english.settingsThemeDark);

      expect(repository.current.themeMode, AppThemeMode.dark);
    });

    testWidgets('tapping a language writes it', (tester) async {
      final repository = FakeAppSettingsRepository();
      await pumpSettings(tester, repository);

      await tapChoice(tester, english.settingsLanguageVietnamese);

      expect(repository.current.language, AppLanguage.vietnamese);
    });

    testWidgets('saving the study defaults sends both values together', (
      tester,
    ) async {
      // S3: they are one group in the data and one thought for the user, so a
      // save that carried only the number would save half of what changed.
      final repository = FakeAppSettingsRepository();
      await pumpSettings(tester, repository);

      await tester.enterText(find.byType(MxTextField), '35');
      await tester.tap(find.text(english.studyOptionsOrderRandom));
      await tester.pumpAndSettle();
      await tester.tap(find.text(english.studyOptionsSave));
      await tester.pumpAndSettle();

      expect(repository.current.cardLimit, 35);
      expect(repository.current.newCardOrder, NewCardOrder.random);
    });

    testWidgets('a theme write does not wipe a card limit being typed', (
      tester,
    ) async {
      // The stream re-emits on every write to the row, including a theme
      // change. Re-seeding the draft on every rebuild would delete a number
      // the user is halfway through (BR-188).
      final repository = FakeAppSettingsRepository();
      await pumpSettings(tester, repository);

      await tester.enterText(find.byType(MxTextField), '4');
      await tapChoice(tester, english.settingsThemeDark);

      expect(
        tester.widget<MxTextField>(find.byType(MxTextField)).controller.text,
        '4',
      );
    });
  });

  group('validation and persistence failure', () {
    testWidgets('an out-of-range limit shows its message under the field and '
        'writes nothing', (tester) async {
      final repository = FakeAppSettingsRepository();
      await pumpSettings(tester, repository);

      await tester.enterText(find.byType(MxTextField), '9999');
      await tester.tap(find.text(english.studyOptionsSave));
      await tester.pumpAndSettle();

      expect(find.textContaining('Between'), findsOneWidget);
      expect(repository.writes, isEmpty);
    });

    testWidgets('a failing theme save shows a band in that group and leaves '
        'the persisted value marked', (tester) async {
      // BR-188: the draft is kept and the other controls keep showing what is
      // actually stored.
      final repository = FailingAppSettingsRepository();
      await pumpSettings(tester, repository);

      await tapChoice(tester, english.settingsThemeDark);

      expect(find.byType(SettingsErrorBandWidget), findsOneWidget);
      expect(find.text(english.settingsSaveErrorTitle), findsOneWidget);
      expect(
        tester
            .widget<RadioGroup<AppThemeMode>>(
              find.byType(RadioGroup<AppThemeMode>),
            )
            .groupValue,
        AppThemeMode.system,
      );
      expect(repository.current.themeMode, AppThemeMode.system);
    });

    testWidgets('the failing group carries the band alone', (tester) async {
      // S7/S8: three groups are three transactions, so one band, in one group.
      await pumpSettings(tester, FailingAppSettingsRepository());

      await tapChoice(tester, english.settingsLanguageEnglish);

      expect(find.byType(SettingsErrorBandWidget), findsOneWidget);
    });

    testWidgets('Try again re-sends the value that failed, not the one on '
        'screen', (tester) async {
      // Retrying with the persisted value would report success for a change
      // that never happened.
      final repository = _FailOnceRepository();
      await pumpSettings(tester, repository);

      await tapChoice(tester, english.settingsThemeDark);
      await tester.ensureVisible(find.text(english.retryAction));
      await tester.pumpAndSettle();
      await tester.tap(find.text(english.retryAction));
      await tester.pumpAndSettle();

      expect(repository.current.themeMode, AppThemeMode.dark);
    });
  });

  group('locales', () {
    testWidgets('Vietnamese renders the Vietnamese headings', (tester) async {
      await pumpSettings(
        tester,
        FakeAppSettingsRepository(),
        locale: const Locale('vi'),
      );

      expect(
        find.text(vietnamese.settingsStudyDefaultsSection),
        findsOneWidget,
      );
      expect(find.text(vietnamese.settingsAppearanceSection), findsOneWidget);
    });

    testWidgets('the two language names stay endonyms in both locales', (
      tester,
    ) async {
      // Somebody stuck in a language they cannot read has to be able to find
      // the name of their own (W2).
      await pumpSettings(
        tester,
        FakeAppSettingsRepository(),
        locale: const Locale('vi'),
      );

      expect(find.text('English'), findsOneWidget);
      expect(find.text('Tiếng Việt'), findsOneWidget);
    });
  });

  group('dark and small screens', () {
    testWidgets('renders in dark without overflowing', (tester) async {
      await pumpSettings(
        tester,
        FakeAppSettingsRepository(),
        brightness: Brightness.dark,
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('320dp at textScaler 2.0 in Vietnamese does not overflow', (
      tester,
    ) async {
      // The tightest combination the wireframe names (W6): the longest
      // Vietnamese label, doubled, on the narrowest supported surface.
      await pumpSettings(
        tester,
        FakeAppSettingsRepository(),
        locale: const Locale('vi'),
        surface: const Size(320, 568),
        textScale: 2,
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('412dp renders without overflowing', (tester) async {
      await pumpSettings(
        tester,
        FakeAppSettingsRepository(),
        surface: const Size(412, 892),
      );

      expect(tester.takeException(), isNull);
    });
  });
}

/// A repository whose read never emits, for the loading state.
final class _NeverEmittingRepository extends FakeAppSettingsRepository {
  _NeverEmittingRepository();

  @override
  Stream<AppSettingsModel> watch() => const Stream<AppSettingsModel>.empty();
}

/// Fails the first theme write and accepts the second, for `Try again`.
final class _FailOnceRepository extends FakeAppSettingsRepository {
  _FailOnceRepository();

  bool _hasFailed = false;

  @override
  Future<void> saveThemeMode(AppThemeMode themeMode) async {
    if (!_hasFailed) {
      _hasFailed = true;
      throw FailingAppSettingsRepository.failure;
    }

    return super.saveThemeMode(themeMode);
  }
}
