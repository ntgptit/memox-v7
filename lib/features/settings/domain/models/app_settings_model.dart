import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../study/domain/models/new_card_order_model.dart';
import '../../../study/domain/models/study_card_limit_model.dart';
import 'app_language_model.dart';
import 'app_theme_mode_model.dart';

part 'app_settings_model.freezed.dart';

/// The single row of `app_settings`, as the app's one set of global options
/// (BR-210).
///
/// **One value, four fields, one stream.** Splitting it into "study defaults"
/// and "appearance" read models would put two subscriptions on one row: the two
/// would be two snapshots, and a screen showing both could render one field
/// from before a write and the other from after it (AD-13). Which fields a
/// given surface uses is that surface's business — `MaterialApp` reads two of
/// them and ignores the rest.
///
/// **`cardLimit` is an `int` here, not a `StudyCardLimit`.** The value object
/// is the *input* type — it exists so `saveStudyDefaults` can state in its
/// signature that the bounds have been applied (BR-211). A value read back out
/// of the database has already been through `StudyCardLimit.fromStored`, so
/// re-wrapping it would claim a second validation that never ran.
///
/// **`NewCardOrder` is reused, not redeclared** (BR-211). A second enum with
/// the same two names is a second list somebody has to remember to extend.
@freezed
abstract class AppSettingsModel with _$AppSettingsModel {
  const factory AppSettingsModel({
    /// The app-wide ceiling on distinct cards per session (BR-24), already
    /// clamped to its bounds by the mapper.
    required int cardLimit,

    /// How new cards are ordered in a `learning` session (BR-148).
    required NewCardOrder newCardOrder,

    /// The theme the user picked, not the brightness it resolves to (BR-214).
    required AppThemeMode themeMode,

    /// The language the user picked, not the locale it resolves to (BR-215).
    required AppLanguage language,
  }) = _AppSettingsModel;

  /// The state a fresh install and a completed reset both land in (BR-217).
  ///
  /// Named here rather than assembled at each call site because "what are the
  /// defaults" is asked by the schema, the reset statement and the screen that
  /// has to say whether anything is off-default — three answers that must not
  /// be free to disagree.
  ///
  /// The ceiling is `kDefaultCardLimit` from Study's own model, not a `20`
  /// retyped here: BR-211 requires exactly one copy of the number, and this is
  /// the second place that would have grown one.
  static const AppSettingsModel defaults = AppSettingsModel(
    cardLimit: kDefaultCardLimit,
    newCardOrder: NewCardOrder.created,
    themeMode: AppThemeMode.fallback,
    language: AppLanguage.fallback,
  );

  // **There is deliberately no `isAtDefaults`.** One was written and removed:
  // nothing could consume it, because wireframe W3 state 2 requires the reset
  // action to be offered whether or not anything is off-default — "already at
  // defaults" is not a state a user should have to infer from a missing
  // button. A getter that describes a UI nuance the UI does not have is worse
  // than no getter: the next reader assumes some surface branches on it.
}
