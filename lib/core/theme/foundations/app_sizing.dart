/// The dimensions a control *is*, as opposed to the space around it.
///
/// **Not a scale, and deliberately not one.** [AppSpacing], [AppRadius] and
/// [AppIconSize] are ladders — pick a rung, and the neighbouring rung is the
/// answer when this one is wrong. These are floors and fixed extents: a
/// touch target is not "one step below" anything, and a generic `controlSm` /
/// `controlMd` / `controlLg` ladder would be decisions made without a screen to
/// check them against. What the control rungs below hold instead is the sizes
/// the v3 Button handoff fixes (48 / 40 / 36 / 32 / 28), each named for the
/// button size that paints it.
///
/// **Every value in the first group already existed** (M100.29). Two were on
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
  ///
  /// **Both sides.** A one-glyph pill paints 33 wide and occupies 48, centred:
  /// `MxPillButton` grows the box around the shape on the narrow axis as well
  /// as the short one (#434 P3-1 — the number used to arrive from
  /// `chip.dart:1493` and nothing here said so).
  static const double touchTarget = 48;

  /// A control that draws smaller than the target it keeps.
  ///
  /// The deck tile's Study verb is the case it encodes: a button living in a
  /// row of chips and gauges rather than in an action bar. It paints 40 and
  /// `MaterialTapTargetSize.padded` restores [touchTarget] around it, so the
  /// body comes down and the finger's floor does not.
  ///
  /// **A short ladder, not the usual 32 / 40 / 48 / 56 / 64 scale.** The
  /// rungs here are the ones the v3 handoff fixes ([controlChip], [controlDense],
  /// [controlSmall], this one and [touchTarget]) — each a size the button enum
  /// names. [controlSmall] and [controlChip] have no live caller yet; they are
  /// admitted because the handoff fixes their geometry, not because a screen
  /// needs them today.
  /// It was a private `_kCompactHeight` in `mx_action_button.dart` until
  /// M100.30 — the one control dimension the design system could not see.
  static const double controlCompact = 40;

  /// The v3 handoff's small button rung: between [controlCompact] and
  /// [controlDense], keeping [touchTarget] around it the same way.
  ///
  /// The handoff names four roles for it — a reminder-time control, a
  /// tag-management empty action and two deck-import file pickers. None is a
  /// built button yet (the reminder time is a list tile; the tag empty state
  /// has no action), so `MxActionButtonSize.small` is admitted ahead of its
  /// screens because the handoff fixes its geometry.
  static const double controlSmall = 36;

  /// The dense tier — a chip's content box, the compact breadcrumb line, the
  /// 32 dp icon well beside a metric or a catalog row.
  ///
  /// **One owner for a number that had five spellings** (A20.1 P2-12):
  /// `app_chip_theme._containerHeight`, `MxBreadcrumb.compactLineHeight`,
  /// `card_metric_widget._wellSize`, `tag_catalog_row_widget.wellSize` and
  /// `AppSpacing.xxl` used as a width, a height and an icon size. A spacing
  /// token is a *gap* on one axis; the moment it is the size of a box it is a
  /// dimension, and dimensions live here. `spacing_is_a_gap_test.dart` keeps
  /// the two apart.
  static const double controlDense = 32;

  /// The v3 handoff's chip-sized button: the shortest control body, keeping
  /// [touchTarget] around it through `MaterialTapTargetSize.padded`.
  ///
  /// The one rung whose look is not a tone: `MxActionButtonSize.chip` paints a
  /// fixed ghost-edged pill whatever `variant` says, because the handoff's
  /// `themeRoleUsage` table has no per-tone row for it.
  static const double controlChip = 28;

  /// The plain `IconButton`'s own painted ink circle — 36, not
  /// [controlCompact]'s 40.
  ///
  /// **A third component-owned value, not a third rung on [controlCompact]'s
  /// ladder.** [controlCompact] answers "a control living in a row of chips
  /// and gauges rather than an action bar" (the deck tile's Study verb); this
  /// answers one specific control's own kit dimension. The MemoX v3 IconButton
  /// component spec (Actions & controls, 2026-09-18) fixes the ink box at 36,
  /// independently of whatever the outlined variant draws — reusing
  /// [controlCompact] here would tie two unrelated components to one number
  /// that only coincidentally isn't 40, and the day either spec moves the two
  /// would drift apart silently.
  ///
  /// [touchTarget] still centres around it via
  /// `MaterialTapTargetSize.padded` — the same drawn-vs-hit technique
  /// `buildOutlinedIconButtonStyle` already uses for its own 40.
  static const double iconButtonInk = 36;

  /// The scrollbar's thumb — Material's own 4, stated (A20.1 P3-09).
  static const double scrollbarThickness = 4;

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
  /// not to size a FAB: [fab] states the FAB's own painted size now, so this
  /// constant's one remaining job is feeding the clearance arithmetic.
  static const double floatingAction = 56;

  /// The v3 Fab contract's own size — the actual painted box, fixed at 52×52
  /// (never [floatingAction], which backs `AppSpacing.fabScrollClearance`
  /// only). Two constants because they answer two different questions: this
  /// one is what the FAB *is*; [floatingAction] is what the scroll tail
  /// clears, and shrinking the FAB does not need to shrink the clearance.
  static const double fab = 52;

  /// The narrowest a button is allowed to be, label notwithstanding.
  ///
  /// Material's own minimum, restated here rather than left as the literal it
  /// was: a one-word button ("OK", "Xoá") would otherwise shrink to its text
  /// plus padding and read as a link beside its neighbour. Height comes from
  /// [touchTarget]; this is the other half of the same `Size`.
  static const double buttonMinWidth = 64;

  /// The bottom navigation bar's own painted height — v3's `size-bottom-bar`.
  ///
  /// Fixed regardless of the device's gesture inset: [MxNavigationBar] locks
  /// `NavigationBar.height` to this and hands the inset to its own wrapper
  /// padding instead, so the painted bar never grows taller on a device with
  /// more or less gesture-nav space. The spec's 80dp wrapper total is
  /// `AppSpacing.xs` (top) + this + `AppSpacing.md` (bottom) — not a symbol of
  /// its own, since nothing computes with it directly.
  static const double bottomBarHeight = 64;

  /// A painted mark that reports state and is not a control: the Library
  /// header's "something is ready to study" dot.
  ///
  /// **Here rather than borrowed from `AppSpacing`, and the repo had already
  /// decided that.** 8 is also `AppSpacing.sm`, and reaching for it would have
  /// worked and would have been wrong — `spacing_is_a_gap_test` bans a spacing
  /// token in a `width`/`height` pair precisely because a token that names a
  /// gap, used as a size, is a dimension wearing the wrong name. M100.76 tried
  /// the shortcut and that test caught it in CI.
  ///
  /// **It is not on the control ladder and must not join it.** A control has a
  /// 48dp floor; this thing is never touched, so a floor would be meaningless
  /// on it. It sits at the bottom of the file next to the other values no
  /// ladder asks for, and `app_sizing_test` holds it to the 4dp grid with the
  /// rest.
  static const double statusDot = 8;
}
