import 'package:flutter/widgets.dart';

import '../../../../../core/error/failure.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../domain/models/progress_path_segment_model.dart';
import '../../../domain/models/progress_range_model.dart';

/// Presentation mapping shared by more than one bucket of this feature.
///
/// **`_widget` and not `_extension`, deliberately** — the same decision
/// `deck_labels_widget.dart` records. The guard selects widget-scope files by
/// that suffix, and renaming this one drops it out of the rules meant to cover
/// it; the file holds no widget and keeps the suffix anyway.
///
/// Everything here turns a domain value into already-localized copy. Nothing
/// above `presentation/` may do this: `domain/` cannot import Flutter and so
/// cannot reach the ARB bundle at all.
extension ProgressLabelsX on BuildContext {
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
