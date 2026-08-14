import 'package:flutter/widgets.dart';

import '../../../../../l10n/l10n_extension.dart';
import '../../../domain/models/progress_activity_day_model.dart';
import '../../../domain/models/progress_overview_model.dart';

/// Copy for the Progress screen, in one place.
///
/// **A `_widget` file with no widget in it, deliberately.** `support/` is the
/// bucket for presentation mapping used across the other three (AD-15), and the
/// suffix is what puts a file inside the guard's widget scope — `deck_labels_widget.dart`
/// keeps its name for exactly this reason, and renaming it was tried and
/// reverted.
///
/// The mapping lives here rather than inside each section so that the three
/// places that phrase a card count phrase it the same way. Two of them are the
/// hero's supporting line and the Today total, and they are the pair a user sees
/// side by side.
extension ProgressLabelsX on BuildContext {
  /// The hero's supporting line, which has three shapes (W2).
  ///
  /// The held-from-yesterday sentence is not "0 cards today" with extra words:
  /// a headline of "7 days" above a bare zero reads as a contradiction, and the
  /// user's next move is to distrust the streak rather than the copy.
  String progressStreakSupportLine(ProgressOverview overview) {
    if (overview.currentStreakDays == 0) return l10n.progressStreakZeroLine;
    if (overview.isStreakHeldFromYesterday) {
      return l10n.progressStreakHeldLine;
    }

    return l10n.progressStreakTodayLine(overview.today.totalCards);
  }

  /// The row label of one chart day (W4.2).
  ///
  /// Today is named rather than dated. The last row is the one a reader looks
  /// for first, and making them work out which weekday today is costs more than
  /// the weekday name is worth.
  String progressDayLabel(ProgressActivityDay day, {required bool isToday}) =>
      isToday
      ? l10n.progressWeekTodayLabel
      : l10n.progressWeekdayShortLabel('${day.localDate.weekday}');
}
