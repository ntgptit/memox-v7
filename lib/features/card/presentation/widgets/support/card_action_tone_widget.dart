import 'package:flutter/material.dart';

import '../../../../../core/theme/app_ink.dart';

import '../../../../../core/theme/theme_context_extension.dart';
import '../../../../deck/domain/models/scheduler_type_model.dart';
import '../../../../study/domain/models/study_action_model.dart';
import '../../../../study/domain/models/eight_box_scheduler.dart';
import '../../../../../l10n/l10n_extension.dart';

/// How a recorded turn went, in three steps rather than six.
///
/// **The reader's question is "did this go well", and six actions answer it in
/// three ways.** `forgotten` and `again` cost the card ground; `hard` kept it at
/// the price of effort; the rest moved it forward. Mapping to a tone rather than
/// painting per action is what keeps the timeline scannable without turning it
/// into a six-colour legend.
enum CardActionTone {
  /// The card moved forward.
  success,

  /// Held, but the turn was hard work. `sm2` only — `eight_box` has no such
  /// action (AD-08).
  warning,

  /// Ground lost.
  danger,
}

/// Presentation mapping for the timeline's verdicts and the scheduler's
/// identity.
///
/// **Card's own file over Study's enums, deliberately** — the same arrangement
/// `card_history_labels_widget.dart` documents. The words come from the ARB keys
/// the session screen and the deck sheets already use, so one stored value is
/// never called two things; what is not shared is the mapping *file*, because a
/// feature may read another feature's `domain/` and never its `presentation/`.
extension CardActionTonePresentation on BuildContext {
  /// The tone of a turn, read off the **stored** action.
  ///
  /// Never inferred from a before/after schedule delta: BR-76 stores the action
  /// precisely because that comparison is wrong for a `scheduled` review of a
  /// box-8 card, and a colour recomputed here would put the bug back at the last
  /// possible moment.
  CardActionTone cardActionTone(StudyAction action) => switch (action) {
    StudyAction.forgotten || StudyAction.again => CardActionTone.danger,
    StudyAction.hard => CardActionTone.warning,
    StudyAction.remembered ||
    StudyAction.good ||
    StudyAction.easy => CardActionTone.success,
  };

  /// The ink a tone is drawn in.
  ///
  /// **Measured on `scheme.surface`, which is the event card's own ground:**
  /// success 5.20:1 light / 8.10:1 dark, danger 5.57 / 6.71, warning 4.58 /
  /// 11.24. All three clear the 4.5:1 text bar, which is why the badge is an
  /// outline on the card's surface rather than a fill — on `surfaceMuted`,
  /// warning falls to 4.00:1 in light.
  Color cardActionToneColor(CardActionTone tone) => switch (tone) {
    CardActionTone.success => semanticColors.success,
    CardActionTone.warning => semanticColors.warning,
    CardActionTone.danger => semanticColors.danger,
  };

  /// The tone as an [AppInk] — the text and glyph legs of the badge take it,
  /// and the border resolves the same ink so the three stay one colour by
  /// construction.
  AppInk cardActionToneInk(CardActionTone tone) => switch (tone) {
    CardActionTone.success => AppInk.success,
    CardActionTone.warning => AppInk.warning,
    CardActionTone.danger => AppInk.danger,
  };

  /// The glyph beside the word, so the verdict survives being read without
  /// colour.
  IconData cardActionToneIcon(CardActionTone tone) => switch (tone) {
    CardActionTone.success => Icons.check_rounded,
    CardActionTone.warning => Icons.trending_flat_rounded,
    CardActionTone.danger => Icons.replay_rounded,
  };

  /// The scheduler's identity, in the words the deck sheets use.
  ///
  /// `eight_box` has no entry: its identity on this screen is its position,
  /// `Box N / 8`, which the summary badge composes from
  /// [AppLocalizations.cardDetailBoxLabel] and the count. A scheduler this build
  /// does not recognise says so rather than borrowing another algorithm's words.
  String cardSchedulerIdentity(SchedulerType scheduler) => switch (scheduler) {
    SchedulerType.sm2 => l10n.schedulerSm2Label,
    SchedulerType.eightBox => l10n.schedulerEightBoxShortLabel,
    SchedulerType.unknown => l10n.schedulerUnknownShortLabel,
  };

  /// How many boxes `eight_box` has, from the scheduler that defines it.
  ///
  /// Read through here rather than written as an `8` at each call site: the
  /// number belongs to `EightBoxScheduler`, and a UI that hardcoded it would go
  /// on saying "/ 8" the day the algorithm changed.
  int get cardMaxBox => kMaxBox;
}
