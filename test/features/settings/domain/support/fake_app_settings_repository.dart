import 'dart:async';

import 'package:memox/core/error/failure.dart';
import 'package:memox/features/settings/domain/models/app_language_model.dart';
import 'package:memox/features/settings/domain/models/app_settings_model.dart';
import 'package:memox/features/settings/domain/models/app_theme_mode_model.dart';
import 'package:memox/features/settings/domain/repositories/app_settings_repository.dart';
import 'package:memox/features/study/domain/models/new_card_order_model.dart';
import 'package:memox/features/study/domain/models/study_card_limit_model.dart';

/// An `AppSettingsRepository` a widget or controller test drives by hand.
///
/// **It behaves like the real one in the way that matters: a write re-emits.**
/// BR-210 makes the stream the mechanism by which one save updates every open
/// surface, so a double that recorded calls without emitting would let a test
/// pass on a screen that never updates in production.
///
/// **What it does not do is validate.** Bounds live in `StudyCardLimit` and are
/// applied by the use case above this contract; a double that re-checked them
/// would be a third owner of the rule and could disagree with both.
///
/// Not `final`: tests subclass it to fail one write at a time, which is
/// cheaper than a constructor flag per method.
base class FakeAppSettingsRepository implements AppSettingsRepository {
  FakeAppSettingsRepository({AppSettingsModel? initial})
    : _current = initial ?? AppSettingsModel.defaults;

  AppSettingsModel _current;

  /// Broadcast, because the root widget and the settings screen subscribe at
  /// the same time — a single-subscription stream would throw on the second
  /// listener, which is precisely the arrangement production has.
  final StreamController<AppSettingsModel> _controller =
      StreamController<AppSettingsModel>.broadcast();

  /// Every write, in call order, so a test can assert what was sent rather than
  /// only what came back.
  final List<AppSettingsModel> writes = <AppSettingsModel>[];

  /// How many times [resetToDefaults] was called.
  int resetCount = 0;

  AppSettingsModel get current => _current;

  @override
  Stream<AppSettingsModel> watch() async* {
    yield _current;
    yield* _controller.stream;
  }

  @override
  Future<void> saveStudyDefaults({
    required StudyCardLimit cardLimit,
    required NewCardOrder newCardOrder,
  }) async => _emit(
    _current.copyWith(cardLimit: cardLimit.value, newCardOrder: newCardOrder),
  );

  @override
  Future<void> saveThemeMode(AppThemeMode themeMode) async =>
      _emit(_current.copyWith(themeMode: themeMode));

  @override
  Future<void> saveLanguage(AppLanguage language) async =>
      _emit(_current.copyWith(language: language));

  @override
  Future<void> resetToDefaults() async {
    resetCount++;

    return _emit(AppSettingsModel.defaults);
  }

  void _emit(AppSettingsModel next) {
    _current = next;
    writes.add(next);
    _controller.add(next);
  }

  /// Closes the stream. Tests that build one per pump do not need it; a test
  /// that keeps one across pumps should `addTearDown` it.
  Future<void> dispose() => _controller.close();
}

/// A double whose every write fails, for the persistence-error state
/// (UC-16 E2, BR-216).
///
/// Reads still work: the point of that state is a screen that keeps showing
/// the **persisted** values while reporting that the last write did not land.
base class FailingAppSettingsRepository extends FakeAppSettingsRepository {
  FailingAppSettingsRepository({super.initial});

  static const DatabaseFailure failure = DatabaseFailure(
    message: 'Could not save your settings.',
  );

  @override
  Future<void> saveStudyDefaults({
    required StudyCardLimit cardLimit,
    required NewCardOrder newCardOrder,
  }) async => throw failure;

  @override
  Future<void> saveThemeMode(AppThemeMode themeMode) async => throw failure;

  @override
  Future<void> saveLanguage(AppLanguage language) async => throw failure;

  @override
  Future<void> resetToDefaults() async => throw failure;
}

/// A double whose read stream fails, for the whole-screen error state
/// (UC-16 E3).
base class UnreadableAppSettingsRepository extends FakeAppSettingsRepository {
  UnreadableAppSettingsRepository();

  @override
  Stream<AppSettingsModel> watch() =>
      Stream<AppSettingsModel>.error(FailingAppSettingsRepository.failure);
}
