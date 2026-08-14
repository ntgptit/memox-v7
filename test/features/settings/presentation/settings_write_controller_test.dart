import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/state/submit_outcome.dart';
import 'package:memox/features/settings/di/app_settings_repository_provider.dart';
import 'package:memox/features/settings/domain/models/app_language_model.dart';
import 'package:memox/features/settings/domain/models/app_settings_model.dart';
import 'package:memox/features/settings/domain/models/app_theme_mode_model.dart';
import 'package:memox/features/settings/presentation/controllers/settings_write_controller.dart';
import 'package:memox/features/settings/presentation/states/settings_submit_state.dart';
import 'package:memox/features/study/domain/models/new_card_order_model.dart';
import 'package:memox/features/study/domain/models/study_card_limit_model.dart';

import '../domain/support/fake_app_settings_repository.dart';

/// The four settings writes, as state transitions (BR-183, BR-186…BR-189).
void main() {
  ProviderContainer containerWith(FakeAppSettingsRepository repository) {
    final container = ProviderContainer(
      overrides: [appSettingsRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    return container;
  }

  group('study defaults', () {
    test(
      'a valid save reaches the repository and reports savedAndContinue',
      () async {
        // `savedAndContinue`, never `savedAndClose`: this screen is a tab with
        // nothing to pop, and `savedAndClose` latches `canSubmit` shut — which
        // would allow exactly one save per app launch.
        final repository = FakeAppSettingsRepository();
        final container = containerWith(repository);
        final notifier = container.read(
          settingsStudyDefaultsControllerProvider.notifier,
        );

        await notifier.submit(
          rawCardLimit: '35',
          newCardOrder: NewCardOrder.random,
        );

        expect(repository.current.cardLimit, 35);
        expect(repository.current.newCardOrder, NewCardOrder.random);
        expect(
          container.read(settingsStudyDefaultsControllerProvider).outcome,
          SubmitOutcome.savedAndContinue,
        );
        expect(
          container.read(settingsStudyDefaultsControllerProvider).canSubmit,
          isTrue,
        );
      },
    );

    test('an out-of-range limit reports the typed problem and writes '
        'nothing', () async {
      // The bounds are `StudyCardLimit`'s and are applied by the use case; the
      // controller only carries which one broke (BR-183, BR-188).
      final repository = FakeAppSettingsRepository();
      final container = containerWith(repository);

      await container
          .read(settingsStudyDefaultsControllerProvider.notifier)
          .submit(
            rawCardLimit: '${kMaxCardLimit + 1}',
            newCardOrder: NewCardOrder.created,
          );

      final state = container.read(settingsStudyDefaultsControllerProvider);
      expect(state.cardLimitProblem, StudyCardLimitProblem.tooLarge);
      expect(state.failure, isNull);
      expect(repository.writes, isEmpty);
    });

    test('text that is not a number reports notANumber', () async {
      final container = containerWith(FakeAppSettingsRepository());

      await container
          .read(settingsStudyDefaultsControllerProvider.notifier)
          .submit(rawCardLimit: 'twenty', newCardOrder: NewCardOrder.created);

      expect(
        container
            .read(settingsStudyDefaultsControllerProvider)
            .cardLimitProblem,
        StudyCardLimitProblem.notANumber,
      );
    });

    test(
      'a persistence failure arrives as a typed failure, not a problem',
      () async {
        // BR-188: the message the user sees is chosen from the failure *type*.
        // A `DatabaseFailure` landing in `problems` would be a validation error
        // pointing at a field that was fine.
        final container = containerWith(FailingAppSettingsRepository());

        await container
            .read(settingsStudyDefaultsControllerProvider.notifier)
            .submit(rawCardLimit: '20', newCardOrder: NewCardOrder.created);

        final state = container.read(settingsStudyDefaultsControllerProvider);
        expect(state.failure, isA<DatabaseFailure>());
        expect(state.problems, isEmpty);
        expect(state.isSubmitting, isFalse);
      },
    );

    test('reset clears a failure so a retry starts clean', () async {
      final container = containerWith(FailingAppSettingsRepository());
      final notifier = container.read(
        settingsStudyDefaultsControllerProvider.notifier,
      );
      await notifier.submit(
        rawCardLimit: '20',
        newCardOrder: NewCardOrder.created,
      );

      notifier.reset();

      expect(
        container.read(settingsStudyDefaultsControllerProvider),
        const SettingsSubmitState(),
      );
    });
  });

  group('theme and language', () {
    test('each write reaches the repository', () async {
      final repository = FakeAppSettingsRepository();
      final container = containerWith(repository);

      await container
          .read(settingsThemeControllerProvider.notifier)
          .submit(AppThemeMode.dark);
      await container
          .read(settingsLanguageControllerProvider.notifier)
          .submit(AppLanguage.vietnamese);

      expect(repository.current.themeMode, AppThemeMode.dark);
      expect(repository.current.language, AppLanguage.vietnamese);
    });

    test('a failing theme save leaves the language controller idle', () async {
      // BR-188, S7: three groups are three transactions and three statuses. A
      // shared status would put the theme's error on the language group.
      final container = containerWith(FailingAppSettingsRepository());

      await container
          .read(settingsThemeControllerProvider.notifier)
          .submit(AppThemeMode.dark);

      expect(
        container.read(settingsThemeControllerProvider).failure,
        isA<DatabaseFailure>(),
      );
      expect(
        container.read(settingsLanguageControllerProvider),
        const SettingsSubmitState(),
      );
    });

    test('a second submit while the first is in flight is ignored', () async {
      // BR-188's double-submit guard. `_SlowRepository` never completes its
      // first write, so the controller stays `isSubmitting` and the second
      // call must not reach the repository at all.
      final repository = _SlowAppSettingsRepository();
      final container = containerWith(repository);
      final notifier = container.read(settingsThemeControllerProvider.notifier);

      final first = notifier.submit(AppThemeMode.dark);
      await notifier.submit(AppThemeMode.light);

      expect(repository.attempts, 1);
      repository.release();
      await first;
      expect(repository.attempts, 1);
    });
  });

  group('reset', () {
    test('calls the repository once and reports savedAndContinue', () async {
      final repository = FakeAppSettingsRepository(
        initial: AppSettingsModel.defaults.copyWith(
          themeMode: AppThemeMode.dark,
        ),
      );
      final container = containerWith(repository);

      await container.read(settingsResetControllerProvider.notifier).submit();

      expect(repository.resetCount, 1);
      expect(repository.current, AppSettingsModel.defaults);
      expect(
        container.read(settingsResetControllerProvider).outcome,
        SubmitOutcome.savedAndContinue,
      );
    });

    test('a failure is reported and the settings are left alone', () async {
      final repository = FailingAppSettingsRepository(
        initial: AppSettingsModel.defaults.copyWith(
          themeMode: AppThemeMode.dark,
        ),
      );
      final container = containerWith(repository);

      await container.read(settingsResetControllerProvider.notifier).submit();

      expect(
        container.read(settingsResetControllerProvider).failure,
        isA<DatabaseFailure>(),
      );
      expect(repository.current.themeMode, AppThemeMode.dark);
    });
  });
}

/// A repository whose theme write hangs until released, for the double-submit
/// guard.
final class _SlowAppSettingsRepository extends FakeAppSettingsRepository {
  _SlowAppSettingsRepository();

  int attempts = 0;
  final Completer<void> _gate = Completer<void>();

  void release() => _gate.complete();

  @override
  Future<void> saveThemeMode(AppThemeMode themeMode) async {
    attempts++;
    await _gate.future;

    return super.saveThemeMode(themeMode);
  }
}
