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

  /// A control that draws smaller than the target it keeps.
  ///
  /// The deck tile's Study verb is the case it encodes: a button living in a
  /// row of chips and gauges rather than in an action bar. It paints 40 and
  /// `MaterialTapTargetSize.padded` restores [touchTarget] around it, so the
  /// body comes down and the finger's floor does not.
  ///
  /// **Two heights, not a five-rung ladder.** 32 / 40 / 48 / 56 / 64 is the
  /// usual control scale and this app renders two of them; the other three
  /// would be sizes with no screen to check them against, which is the rule
  /// `app_planned_themes.dart` already follows for component themes. It was a
  /// private `_kCompactHeight` in `mx_action_button.dart` until M100.30 — the
  /// one control dimension the design system could not see.
  static const double controlCompact = 40;

  /// The one-line reading or control row — `ListTile`'s own 56, stated.
  ///
  /// **A row is not a button** (M100.36 4J). [touchTarget] is the floor a
  /// finger needs; a list the eye reads down wants more than the floor, and
  /// Material's `_defaultTileHeight` gives it 56 for one line, 72 for two.
  /// The number was Flutter's and nobody's here (#431 P2-1) — the kit says 48
  /// for a desktop tile, and the app had been rendering 56 + 4 + 4 without a
  /// token to say so. A *minimum*: a two-line row grows past it, and text is
  /// never clipped to hold it. Compact mode keeps it; 48 is reserved for
  /// controls that are only a target.
  static const double rowMinHeight = 56;

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
