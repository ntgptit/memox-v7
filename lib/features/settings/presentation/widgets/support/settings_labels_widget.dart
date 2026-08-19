import 'package:flutter/widgets.dart';

import '../../../../../core/error/failure.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_failure_labels_widget.dart';
import '../../../../study/domain/models/new_card_order_model.dart';
import '../../../../study/domain/models/study_card_limit_model.dart';
import '../../../domain/models/app_language_model.dart';
import '../../../domain/models/app_theme_mode_model.dart';

/// Every enum and failure this feature shows, as copy.
///
/// A `BuildContext` extension, like Deck's and Card's, and it keeps the
/// `_widget` suffix for the reason `deck_labels_widget.dart` records: the
/// suffix is what puts the file inside the widget scope the guards select on,
/// and renaming it to `_extension.dart` was tried once and reverted.
///
/// **Every switch is exhaustive with no `_` branch.** A fourth theme or a third
/// language must fail to compile here rather than render as a blank row.
extension SettingsLabels on BuildContext {
  String themeModeLabel(AppThemeMode mode) => switch (mode) {
    AppThemeMode.system => l10n.settingsThemeSystem,
    AppThemeMode.light => l10n.settingsThemeLight,
    AppThemeMode.dark => l10n.settingsThemeDark,
  };

  String languageLabel(AppLanguage language) => switch (language) {
    AppLanguage.system => l10n.settingsLanguageSystem,
    AppLanguage.english => l10n.settingsLanguageEnglish,
    AppLanguage.vietnamese => l10n.settingsLanguageVietnamese,
  };

  /// Reuses Study's copy, because it is the same choice on a second surface
  /// (BR-211). A second pair of strings would be two ways to say "shuffled",
  /// free to be translated differently.
  String newCardOrderLabel(NewCardOrder order) => switch (order) {
    NewCardOrder.created => l10n.studyOptionsOrderCreated,
    NewCardOrder.random => l10n.studyOptionsOrderRandom,
  };

  /// The card-limit field error, or null when the field is fine.
  ///
  /// The bounds come from Study's constants, so the message quotes the numbers
  /// the parser actually used rather than a pair retyped here.
  String? cardLimitError(StudyCardLimitProblem? problem) => switch (problem) {
    StudyCardLimitProblem.notANumber => l10n.studyOptionsCardLimitNotANumber,
    StudyCardLimitProblem.tooSmall || StudyCardLimitProblem.tooLarge =>
      l10n.studyOptionsCardLimitOutOfRange(kMinCardLimit, kMaxCardLimit),
    null => null,
  };

  /// The body of a failed save (BR-216).
  ///
  /// Delegates to the shared exhaustive switch. Neither branch this feature
  /// supplies can happen in practice — there is no row to be missing and no
  /// uniqueness to conflict with on a one-row table — but they are answered
  /// honestly rather than with a different sentence, because "please try again"
  /// is the truthful advice for both.
  String settingsWriteFailure(Failure failure) => mxWriteFailure(
    failure,
    onNotFound: (_) => l10n.writeErrorMessage,
    onConflict: (_) => l10n.writeErrorMessage,
  );
}
