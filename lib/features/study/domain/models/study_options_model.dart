import 'package:freezed_annotation/freezed_annotation.dart';

import 'new_card_order_model.dart';

part 'study_options_model.freezed.dart';

/// The study options actually in force for one root deck (BR-147).
///
/// **Two tiers, resolved into one value.** The app-wide defaults live in
/// `app_settings`; a root deck MAY override them, a sub-deck MUST NOT — the same
/// rule the scheduler columns have followed since BR-06, resolved through
/// `root_deck_id` rather than by walking parents.
///
/// Resolving to a single value here, rather than handing the caller both tiers,
/// is what stops "which one wins" being re-decided at every call site.
@freezed
abstract class StudyOptionsModel with _$StudyOptionsModel {
  const factory StudyOptionsModel({
    /// The ceiling on distinct cards **per session** — not per day (BR-24).
    ///
    /// The number of sessions in a day is deliberately unlimited: the app
    /// creates the environment, and how much to study is the user's call.
    required int cardLimit,

    /// How new cards are ordered in a `learning` session (BR-148).
    required NewCardOrder newCardOrder,
  }) = _StudyOptionsModel;
}
