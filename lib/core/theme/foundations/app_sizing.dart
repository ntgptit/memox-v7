/// The dimensions a control *is*, as opposed to the space around it.
///
/// **Not a scale, and deliberately not one.** [AppSpacing], [AppRadius] and
/// [AppIconSize] are ladders — pick a rung, and the neighbouring rung is the
/// answer when this one is wrong. These three are floors and fixed extents: a
/// touch target is not "one step below" anything, and inventing `controlSm` /
/// `controlMd` / `controlLg` rungs nothing renders would be three decisions
/// made without a screen to check them against, which is the rule
/// `app_planned_themes.dart` already follows for component themes.
///
/// **Every value here already existed; none is new** (M100.29). Two were on
/// `AppSpacing`, whose own header says it holds "every gap, pad and inset" —
/// and then immediately had to disclaim [touchTarget] as "a floor, not a step".
/// A class that has to argue a member is not what the class is for is a member
/// in the wrong class. The third was a bare `64` inside
/// `buildSharedButtonStyle`, the exact shape of magic value this directory
/// exists to hold.
abstract final class AppSizing {
  /// Smallest side of anything a finger has to hit.
  ///
  /// A control below this is reachable on a desk and missed on a bus, and the
  /// miss looks like the app ignoring the tap rather than the user hitting
  /// beside it.
  ///
  /// It is enforced where it cannot be passed around: `iconButtonTheme` states
  /// it as `minimumSize` so no screen can build a smaller icon button, and
  /// `buildSharedButtonStyle` states it for every button family at once.
  static const double touchTarget = 48;

  /// Material's floating action button, which declares no public constant for
  /// its own size.
  ///
  /// Read only to derive clearances — `AppSpacing.fabScrollClearance` — and
  /// never to size a FAB: `FloatingActionButton` sizes itself, and a widget
  /// that restated this number would be a second answer able to drift from the
  /// SDK's.
  static const double floatingAction = 56;

  /// The narrowest a button is allowed to be, label notwithstanding.
  ///
  /// Material's own minimum, restated here rather than left as the literal it
  /// was: a one-word button ("OK", "Xoá") would otherwise shrink to its text
  /// plus padding and read as a link beside its neighbour. Height comes from
  /// [touchTarget]; this is the other half of the same `Size`.
  static const double buttonMinWidth = 64;
}
