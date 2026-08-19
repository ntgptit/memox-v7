import 'package:flutter/widgets.dart';
import '../../../../../core/error/failure.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../domain/models/progress_activity_day_model.dart';
import '../../../domain/models/progress_overview_model.dart';
import '../../../domain/models/progress_path_segment_model.dart';
import '../../../domain/models/progress_range_model.dart';

/// Copy for the Progress screen, in one place.
///
/// **A `_widget` file with no widget in it, deliberately.** `support/` is the
/// bucket for presentation mapping used across the other three (AD-15), and the
/// suffix is what puts a file inside the guard's widget scope —
/// `deck_labels_widget.dart` keeps its name for exactly this reason, and
/// renaming it was tried and reverted.
///
/// **One extension, both halves of the screen.** The overview header and the
/// deck level arrived as separate features and phrase the same nouns — a card
/// count, a day, a range — so two extensions on `BuildContext` would put the
/// same sentence in two places and let them drift apart. That is the reason this
/// file exists at all: the places that phrase a card count phrase it the same
/// way, and the user sees several of them at once.
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

  /// The pill's visible word — short, because two pills share a row at 320dp.
  String progressRangeLabel(ProgressRange range) => switch (range) {
    ProgressRange.last7Days => l10n.progressRange7Label,
    ProgressRange.last30Days => l10n.progressRange30Label,
  };

  /// What a screen reader hears instead. `7 days` does not say the window ends
  /// today; `Last 7 days` does.
  String progressRangeSemanticLabel(ProgressRange range) => switch (range) {
    ProgressRange.last7Days => l10n.progressRange7SemanticLabel,
    ProgressRange.last30Days => l10n.progressRange30SemanticLabel,
  };

  /// The summary panel's heading, which states the window in words so a
  /// screenshot is unambiguous about which figures it holds.
  String progressSummaryTitle(ProgressRange range) => switch (range) {
    ProgressRange.last7Days => l10n.progressSummaryLast7DaysTitle,
    ProgressRange.last30Days => l10n.progressSummaryLast30DaysTitle,
  };

  /// A deck's path as one string — for the row's secondary line and for the
  /// sentence a screen reader reads before the metrics.
  ///
  /// Joined with the localized separator, whose value carries its own spaces so
  /// a long path wraps at the marks rather than mid-name.
  String progressPathLabel(List<ProgressPathSegment> path) => path
      .map((ProgressPathSegment segment) => segment.name)
      .join(l10n.progressPathSeparator);
}

/// The copy for a failed read.
///
/// **Two outcomes, not one** — a deck that is gone is not a failure, and
/// offering Retry for it would offer an action guaranteed to fail again. So
/// `NotFoundFailure` gets its own words and its own way back, and everything
/// else gets the generic read failure with a retry.
///
/// The failure's own `message` never reaches the screen: it is an unlocalized
/// diagnostic written for a log, and a screen that rendered it would show
/// English to a Vietnamese reader with no test failing anywhere.
@immutable
class ProgressErrorCopy {
  const ProgressErrorCopy({
    required this.title,
    required this.message,
    required this.isDeckMissing,
  });

  final String title;
  final String message;

  /// Whether the level's deck is gone, which decides whether the state offers
  /// Retry or the way back.
  final bool isDeckMissing;
}

/// Maps a read failure to what the user is told.
ProgressErrorCopy progressErrorCopyOf(BuildContext context, Object error) {
  if (error is NotFoundFailure) {
    return ProgressErrorCopy(
      title: context.l10n.progressDeckMissingTitle,
      message: context.l10n.progressDeckMissingMessage,
      isDeckMissing: true,
    );
  }

  return ProgressErrorCopy(
    title: context.l10n.progressErrorTitle,
    message: context.l10n.progressErrorMessage,
    isDeckMissing: false,
  );
}
