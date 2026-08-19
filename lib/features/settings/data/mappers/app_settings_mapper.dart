import '../../../../core/database/app_database.dart';
import '../../../study/domain/models/new_card_order_model.dart';
import '../../../study/domain/models/study_card_limit_model.dart';
import '../../domain/models/app_language_model.dart';
import '../../domain/models/app_settings_model.dart';
import '../../domain/models/app_theme_mode_model.dart';

/// The one place a Drift `AppSetting` row becomes a domain value (AD-01).
///
/// **Every column goes through its own tolerant reader.** A stored value out of
/// range is not a reason to refuse to open the app: `StudyCardLimit.fromStored`
/// clamps, and the two enum readers fall back to their default. The clamp is
/// visible the moment the settings screen opens, which is a better outcome than
/// a launch that throws on a row the user cannot reach to repair.
///
/// There is no reverse mapper. Writes go column by column through the DAO
/// (BR-216), so a whole-row companion would only exist to be filled from a
/// value the caller had to assemble first — which is the read-modify-write the
/// repository contract exists to avoid.
AppSettingsModel appSettingsFromRow(AppSetting row) => AppSettingsModel(
  cardLimit: StudyCardLimit.fromStored(row.cardLimit).value,
  newCardOrder: NewCardOrder.fromDbValue(row.newCardOrder),
  themeMode: AppThemeMode.fromDbValue(row.themeMode),
  language: AppLanguage.fromDbValue(row.language),
);
