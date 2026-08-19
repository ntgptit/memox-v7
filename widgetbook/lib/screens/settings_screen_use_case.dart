import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/settings/di/app_settings_repository_provider.dart';
import 'package:memox/features/settings/domain/models/app_language_model.dart';
import 'package:memox/features/settings/domain/models/app_settings_model.dart';
import 'package:memox/features/settings/domain/models/app_theme_mode_model.dart';
import 'package:memox/features/settings/domain/repositories/app_settings_repository.dart';
import 'package:memox/features/settings/presentation/screens/settings_screen.dart';
import 'package:memox/features/study/domain/models/new_card_order_model.dart';
import 'package:memox/features/study/domain/models/study_card_limit_model.dart';
import 'package:widgetbook/widgetbook.dart';

/// The Settings screen, mounted whole against the catalog's own repository
/// (UC-16).
///
/// **Its own double, like Study's.** The app's test doubles live under `test/`
/// and a second package cannot import them, so the catalog carries a small one
/// — enough to show the four states the wireframe names and no more.
WidgetbookComponent settingsScreenComponent() => WidgetbookComponent(
  name: 'SettingsScreen',
  useCases: <WidgetbookUseCase>[
    WidgetbookUseCase(
      name: 'Playground',
      builder: (context) {
        final scenario = context.knobs.object.dropdown<_SettingsScenario>(
          label: 'scenario',
          options: _SettingsScenario.values,
          labelBuilder: (_SettingsScenario value) => value.label,
        );

        // Keyed by scenario so switching it rebuilds from scratch: the write
        // controllers latch an outcome, and a tree that survived the switch
        // would carry the previous scenario's.
        return ProviderScope(
          key: ValueKey<Object>(scenario),
          overrides: [
            appSettingsRepositoryProvider.overrideWithValue(
              _SettingsCatalogRepository(scenario),
            ),
          ],
          child: const SettingsScreen(),
        );
      },
    ),
  ],
);

/// The states worth looking at, which are the ones the wireframe pins.
enum _SettingsScenario {
  defaults('At defaults'),
  customised('Non-default values'),
  writeFails('Every save fails'),
  readFails('Read fails'),
  // The two faces the catalogue could not reach: the read never hung and no
  // save ever stayed in flight, so W3's loading and submitting states — the
  // ones S7 exists to protect — were unobservable here.
  loading('Read never lands'),
  submitting('Every save stays in flight');

  const _SettingsScenario(this.label);

  final String label;
}

/// A double that emits and never throws on read, except where the scenario says
/// so. It validates nothing — the bounds belong to `StudyCardLimit` and are
/// applied above this contract.
final class _SettingsCatalogRepository implements AppSettingsRepository {
  _SettingsCatalogRepository(this._scenario)
    : _current = switch (_scenario) {
        _SettingsScenario.customised => const AppSettingsModel(
          cardLimit: 35,
          newCardOrder: NewCardOrder.random,
          themeMode: AppThemeMode.dark,
          language: AppLanguage.vietnamese,
        ),
        _ => AppSettingsModel.defaults,
      };

  final _SettingsScenario _scenario;
  AppSettingsModel _current;

  final StreamController<AppSettingsModel> _controller =
      StreamController<AppSettingsModel>.broadcast();

  static const DatabaseFailure _failure = DatabaseFailure(
    message: 'Could not save your settings.',
  );

  @override
  Stream<AppSettingsModel> watch() async* {
    if (_scenario == _SettingsScenario.readFails) throw _failure;
    // A stream that never answers, so the spinner holds still. Not
    // `Stream.empty()`: an empty stream closes at once, and a closed stream
    // with no value is a state Riverpod may render differently.
    if (_scenario == _SettingsScenario.loading) {
      yield* StreamController<AppSettingsModel>().stream;
      return;
    }
    yield _current;
    yield* _controller.stream;
  }

  @override
  Future<void> saveStudyDefaults({
    required StudyCardLimit cardLimit,
    required NewCardOrder newCardOrder,
  }) async => _write(
    _current.copyWith(cardLimit: cardLimit.value, newCardOrder: newCardOrder),
  );

  @override
  Future<void> saveThemeMode(AppThemeMode themeMode) async =>
      _write(_current.copyWith(themeMode: themeMode));

  @override
  Future<void> saveLanguage(AppLanguage language) async =>
      _write(_current.copyWith(language: language));

  @override
  Future<void> resetToDefaults() => _write(AppSettingsModel.defaults);

  /// **Async, so a save can be caught mid-flight.** Every write used to
  /// resolve on the same microtask, which made the submitting face — the
  /// group locked, its label saying so, the other two groups still usable —
  /// impossible to see in the catalogue.
  Future<void> _write(AppSettingsModel next) async {
    if (_scenario == _SettingsScenario.writeFails) throw _failure;
    if (_scenario == _SettingsScenario.submitting) {
      await Completer<void>().future;
      return;
    }
    _current = next;
    _controller.add(next);
  }
}
