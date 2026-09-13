/// The dimensions a control *is*, as opposed to the space around it.
///
/// **Not a scale, and deliberately not one.** [AppSpacing], [AppRadius] and
/// [AppIconSize] are ladders — pick a rung, and the neighbouring rung is the
/// answer when this one is wrong. These three are floors and fixed extents: a
/// touch target is not "one step below" anything, and inventing `controlSm` /
/// `controlMd` / `controlLg` rungs nothing renders would be three decisions
/// made without a screen to check them against, which is the rule the
/// unrendered component themes in `app_theme.dart` already follow.
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
  ///
  /// **Both sides.** A one-glyph pill paints 33 wide and occupies 48, centred:
  /// `MxPillButton` grows the box around the shape on the narrow axis as well
  /// as the short one (#434 P3-1 — the number used to arrive from
  /// `chip.dart:1493` and nothing here said so).
  static const double touchTarget = 48;

  /// The handoff's compact button (`size-button-sm`): paints 36, and
  /// `MaterialTapTargetSize.padded` restores [touchTarget] around it.
  ///
  /// The deck tile's Study verb is the case it encoded first: a button living
  /// in a row of chips and gauges rather than in an action bar, so the body
  /// comes down and the finger's floor does not. It painted 40 as
  /// `controlCompact` (owner review, 2026-08-20) until M100.90 moved it to the
  /// handoff's value.
  ///
  /// **Two heights, not a five-rung ladder.** 32 / 40 / 48 / 56 / 64 is the
  /// usual control scale and this app renders two of them; the other three
  /// would be sizes with no screen to check them against, which is the rule
  /// the unrendered component themes in `app_theme.dart` already follow. It was a
  /// private `_kCompactHeight` in `mx_action_button.dart` until M100.30 — the
  /// one control dimension the design system could not see.
  static const double buttonCompact = 36;

  /// The handoff icon button's painted circle (`size-icon-btn`). The target
  /// around it is still [touchTarget]: expand the hit area, never the ink.
  static const double iconButtonInk = 36;

  /// The dense tier — a chip's content box, the compact breadcrumb line, the
  /// 32 dp icon well beside a metric. The catalog row led with one too until
  /// it took the handoff's `MxIconTile` (M100.91).
  ///
  /// **One owner for a number that had five spellings** (A20.1 P2-12):
  /// `app_chip_theme._containerHeight`, `MxBreadcrumb.compactLineHeight`,
  /// `card_metric_widget._wellSize`, `tag_catalog_row_widget.wellSize` and
  /// `AppSpacing.xxl` used as a width, a height and an icon size. A spacing
  /// token is a *gap* on one axis; the moment it is the size of a box it is a
  /// dimension, and dimensions live here. `spacing_is_a_gap_test.dart` keeps
  /// the two apart.
  static const double controlDense = 32;

  /// The scrollbar's thumb — Material's own 4, stated (A20.1 P3-09).
  static const double scrollbarThickness = 4;

  /// The handoff's list row: 48 MINIMUM, grows with content. Text is never
  /// clipped to hold it.
  ///
  /// **It was 56 until M100.91** — Material's `_defaultTileHeight`, stated at
  /// M100.36 4J on the argument that a list the eye reads down wants more than
  /// a finger's floor. The Tokyo handoff's ListRow and SettingsTile set the
  /// row at the touch floor and let content grow it, and the redesign follows
  /// the kit. A two-line row still grows past it.
  static const double rowMinHeight = 48;

  /// Where a row divider starts when the rows lead with a tile (handoff
  /// Divider `indent 0 / 56`): past the leading column, under the text. It is
  /// under the text only because `lg` + [iconTileSm] + `md` add up to it —
  /// the sum `app_sizing_test` pins (UI audit P2, M100.91).
  static const double listDividerIndent = 56;

  /// Handoff MasteryRing extent (`40×3px`). A painted mark, not a control: the
  /// row it sits in carries the target, so no 48 floor applies.
  static const double masteryRing = 40;

  /// The handoff text and search field height (`size-input`): a MINIMUM —
  /// large text grows it (M100.92).
  static const double input = 52;

  /// A multi-line field's minimum (handoff TextField, multiline state): the
  /// shell drops to 40 and its text wraps instead of truncating.
  static const double inputMultilineMin = 40;

  /// Handoff Switch geometry (FIXED): a 44 × 26 track and a 20 thumb, 3 in
  /// from the track's edge. A painted mark: the row around it carries the 48
  /// target (`MxSwitchRow`).
  static const double switchTrackWidth = 44;
  static const double switchTrackHeight = 26;
  static const double switchThumb = 20;
  static const double switchThumbInset = 3;

  /// The handoff's extended FAB height (`size-fab`). Width is content-driven.
  ///
  /// It was Material's 56 circle as `floatingAction` until M100.90; the kit has
  /// no circular variant. The FAB theme sizes the button from it, and
  /// `AppSpacing.fabScrollClearance` derives the list's tail from it.
  static const double fab = 52;

  /// The narrowest a button is allowed to be, label notwithstanding.
  ///
  /// Material's own minimum, restated here rather than left as the literal it
  /// was: a one-word button ("OK", "Xoá") would otherwise shrink to its text
  /// plus padding and read as a link beside its neighbour. Height comes from
  /// [touchTarget]; this is the other half of the same `Size`.
  static const double buttonMinWidth = 64;

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

  /// Handoff IconTile extents — a row's tinted leading square. Painted marks,
  /// not controls: the row carries the target, so no 48 floor applies.
  static const double iconTileSm = 28;
  static const double iconTileMd = 36;
  static const double iconTileLg = 44;
}
