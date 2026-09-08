# A11 — date / time picker deep audit

| | |
|---|---|
| BASE_SHA | `3207e7b7e0d3a2ecefa5e6a85fed48a65890ba6b` — *refactor(theme): the dark card stops glowing* (M100.35, #435) |
| Branch | `claude/a11-pickers-audit-kivdrw` |
| Pinned SDK | Flutter **3.44.8** stable (`.fvmrc`) · Dart 3.12.2 |
| Scope | `DatePickerThemeData`, `TimePickerThemeData`, every `showDatePicker` / `showTimePicker` call site, calendar + input modes, dial + input modes, and how both dialogs sit inside this app's dialog system |
| Mode | **Report only.** This file is the sole change. No theme, widget, test, Widgetbook or golden file was touched, and no golden was regenerated |
| Method | Flutter 3.44.8 source read at the pinned tag (`time_picker.dart`, `date_picker.dart`, `date_picker_theme.dart`, `calendar_date_picker.dart`, `input_date_picker_form_field.dart`, `dialog.dart`, `button_style_button.dart`, `material_localizations.dart`, `generated_material_localizations.dart`); repository read at BASE_SHA; contrast and geometry computed from the palette constants and the SDK's own layout constants |

## 0 · What was measured, and what was not

**Every number in the geometry and contrast tables is derived, not recalled** —
either read directly out of a Flutter 3.44.8 constant or computed from one with
the palette constants at BASE_SHA. Contrast is WCAG 2.x relative luminance,
with translucent inks composited over their stated ground first.

**No render was performed, and that is a real limit of this audit.** This
container has no Flutter SDK provisioned (`flutter` is not on `PATH`, and there
is no toolchain under `/opt`), so unlike the four audits before it this one
could not stand up a throwaway measurement harness against `buildLightTheme()`
and read sizes off a live tree. Nothing here is guessed to cover that: where an
outcome depends on glyph metrics or on a layout pass, it is marked
**`unverified — needs a render`** and excluded from the severity registry's
evidence column. Everything in the registry is source-derived.

The practical consequence: the *inputs* to every layout decision below (dialog
sizes, inset paddings, minimum sizes, grid delegates, text-scaler clamps,
`_InputPadding` tap-target expansion) are exact, because they are constants;
the *pixel* results of a text layout are not.

---

## 1 · Executive verdict

**The time picker is themed carefully and is the only picker anyone can open.
The date picker is a complete, well-argued theme for a dialog that does not
exist, and it carries two combined-state defects that the guard suite cannot
see because neither picker is in the guard suite.** Separately, the one
production picker disagrees with the row that opens it about whether the app
is on a 12- or 24-hour clock.

What is right, and should not be disturbed:

- `buildTimePickerTheme` correctly identifies that `TimePickerDialog` builds
  its own `Dialog` from `_TimePickerDefaultsM3` and never reads `dialogTheme`.
  The file's claim is verified: elevation 6 → `AppElevation.none`, radius 28 →
  `AppRadius.lg` + `outlineVariant` hairline, and the barrier still comes from
  `dialogTheme.barrierColor` because `showDialog` falls through to it
  (`dialog.dart:1655-1658`).
- `padding: EdgeInsets.all(AppSpacing.xl)` is **24**, byte-identical to
  `_TimePickerDefaultsM3.padding`. Stating it costs nothing and pins it.
- The AM/PM `tertiaryContainer` decision is canonical M3, and the file already
  records the measurement that makes it weak here (1.10:1 light / 1.29:1 dark
  against `primaryContainer`) instead of hiding it. Both figures reproduce
  exactly.
- The `inputDecorationTheme: null` decision on the **time** picker is correct
  and for the stated reason — `time_picker.dart:2203` falls back to
  `defaultTheme.inputDecorationTheme`, *not* to the ambient
  `buildInputDecorationTheme`. The comment is accurate.
- `semantic.onDisabled` is `Color(0x61223354)` = `onSurface` at 38%, which is
  bit-for-bit what `_DatePickerDefaultsM3` writes as
  `onSurface.withOpacity(0.38)`. That is a rename, not a role substitution.
- The picker's OK / Cancel touch targets are **48 × 48**, not the ~20 dp their
  labels suggest: `materialTapTargetSize: padded` +
  `VisualDensity.standard` puts `_InputPadding(minSize: 48×48)` around every
  `ButtonStyleButton` (`button_style_button.dart:578-597`), and that render
  object sizes to `max(child, minSize)`. The zero padding in
  `textButtonTheme` costs emphasis, not reach.

What the next pass has to deal with:

| # | Finding | Sev | Reach |
|---|---|---|---|
| F1 | Date: `dayForegroundColor` resolves **`disabled` before `selected`** while `dayBackgroundColor` ignores `disabled` → a disabled-and-selected day is `onDisabled` ink on a `primary` fill: **1.32:1 light, 1.02:1 dark** | **P1** | latent |
| F2 | Time: the reminder row and the picker it opens **disagree about 12 vs 24 hour** on a 12-hour locale with the device's 24-hour setting on — and the row's own doc comment claims it handles exactly that case | **P1** | **production** |
| F3 | Date: `todayForegroundColor` and `yearForegroundColor` have **no `disabled` branch** — a disabled today and a disabled year render identically to enabled ones | P2 | latent |
| F4 | Date: `dayOverlayColor` is `controlOverlay`, which never reads `selected`, so the state layer on a selected day is `primary` over `primary`. The overlay is the cell's **only** focus indicator | P2 | latent |
| F5 | Time: `hourMinuteTextStyle` is `displaySmall` (36) for **both** modes where canonical is `displayLarge` (57) / `displayMedium` (45) — and the control renders at `TextScaler.noScaling`, so no user setting recovers the size | P2 | production |
| F6 | Time: `hourMinuteShape` is retuned to radius **12** but `inputDecorationTheme` is left to Material at radius **8** — one control, two corners across its two modes | P2 | production |
| F7 | Modal action hierarchy: the picker footer is two bare `TextButton`s at **equal emphasis**, under a theme written for inline links (`padding: zero`, `overlayColor: transparent`, `NoSplash`), while every `Mx*` dialog uses `MxButtonPair`. `cancelButtonStyle` / `confirmButtonStyle` are unset | P2 | production |
| F8 | Time: `TimePickerDialog` hardcodes `insetPadding: horizontal 16`; every other dialog uses `MxDialogMetrics.inset` = **40**. No theme slot can change it | P2 | production |
| F9 | Date: `weekdayStyle` drops two type rungs **and substitutes the role** (`onSurface` → `onSurfaceVariant`, 10.53 → 4.83 light); `dayStyle` drops one rung while `yearStyle` stays canonical, so day 14 and year 16 in the same dialog | P2 | latent |
| F10 | Date: at 320 / 360 / 375 dp the day cell is **37.7 / 43.4 / 45.6 dp** wide. Only 393 dp yields exactly 48 | P2 | latent (framework) |
| F11 | Time: `entryModeIconColor` **substitutes** `onSurfaceVariant` for canonical `onSurface` (4.83 vs 10.53 light) on the one control that reaches the accessible input mode | P3 | production |
| F12 | Time: the dial face (`surfaceContainerHighest`) measures **1.06:1 light / 1.15:1 dark** against the dialog it sits on — the file's stated intent, "reads as a panel within the sheet", is not achieved | P3 | production |
| F13 | Doc: the contrast figures at `app_time_picker_theme.dart:58` (7.51 light / 5.88 dark) **do not reproduce** — recomputed 6.20 / 7.73, and `docs/wbs.md:17574` independently records 7.73 for the dark side | P3 | production |
| F14 | Five live references to **`app_planned_themes.dart`, a file that does not exist**, including the one `theme_coverage_test.dart` points its `allowedUnrendered` justifications at | P3 | production |
| F15 | Time: three different text-scaling rules inside one dialog — the box clamps at ×1.1, AM/PM clamps at ×2.0, the hour/minute does not scale at all | P3 | production (framework) |

And the coverage that let most of them exist unseen:

| # | Gap | Sev |
|---|---|---|
| G1 | **Nothing in the repository renders either picker.** No widget test, no golden, no a11y test, no `integration_test/` scenario, no Widgetbook use case. Coverage is `ThemeData`-object assertions only | **P1** |
| G2 | Neither picker appears in `m3_role_bindings.dart` or in `m3_combined_state_test.dart` — the file that exists for exactly F1's bug class | **P1** |
| G3 | `m3_role_contract_test.dart` pins 5 time slots and 6 date slots; `todayBorder`, `dayOverlayColor`, `dayPeriodColor`, `entryModeIconColor`, `weekdayStyle`, `dayStyle` are unpinned | P2 |
| G4 | `app_time_picker_theme_test.dart:144` measures `dayPeriodBorderSide` against `colorScheme.surface`; the AM/PM box is drawn on `surfaceContainerHigh`. Passes either way (4.02 / 3.50), but on the wrong ground | P3 |
| G5 | `app_planned_themes_test.dart:71` measures `todayBorder` against `colorScheme.surface`, same wrong ground (5.19 / 8.43 on the real one) | P3 |
| G6 | No test covers the AM/PM selected pair, any disabled state, the year grid, or the range fill | P3 |

**Severity here means impact when reached, and `Reach` says whether anything
reaches it today.** The date picker has zero production callers, so nothing in
its column is user-visible at BASE_SHA. That is why the implementation order in
§13 does not follow the severity column.

---

## 2 · Production inventory

### 2.1 · Every picker surface under `lib/`

| Surface | Call sites | File |
|---|---|---|
| `showTimePicker` | **1** | `lib/features/reminder/presentation/widgets/overlays/reminder_time_picker_widget.dart:24` |
| `showDatePicker` | **0** | — |
| `showDateRangePicker` | **0** | — |
| `CalendarDatePicker` | **0** | — |
| `DatePickerDialog` / `TimePickerDialog` direct | **0** | — |
| `InputDatePickerFormField` | **0** | — |
| `YearPicker` | **0** | — |

The single chain is:

```
ReminderSettingsScreen._pickTime                       reminder_settings_screen.dart:133
  └ showReminderTimePicker(context, current)           reminder_time_picker_widget.dart:20
      └ showTimePicker(initialTime:, helpText:)        reminder_time_picker_widget.dart:24
          └ ReminderTime.fromHourMinute(...).time      BR-219 re-validation
```

`showReminderTimePicker` passes exactly three arguments: `context`,
`initialTime` and `helpText`. Everything else — entry mode, orientation,
barrier, action labels, the entry-mode icons — is Material's default.
`initialEntryMode` is therefore `TimePickerEntryMode.dial`, which means **both
modes are reachable**: the keyboard-entry toggle renders
(`time_picker.dart:2604-2621`) and the user can switch.

The row that opens it is `ReminderTimeRowWidget` → `MxListTile`, which is a
correct 48-dp-floor list row with merged semantics; nothing about the entry
point is at fault except F2 below.

### 2.2 · The two themes

| Slot | Builder | Registered | Rendered by |
|---|---|---|---|
| `timePickerTheme` | `buildTimePickerTheme(scheme, texts)` — `app_time_picker_theme.dart:30` | `app_theme.dart:282` | the reminder screen |
| `datePickerTheme` | `buildDatePickerTheme(scheme, semantic, texts)` — `app_date_picker_theme.dart:18` | `app_theme.dart:290` | **nothing** |

**`datePickerTheme` has zero production callers, and that is recorded, not
discovered here.** `theme_coverage_test.dart:144` lists it in
`allowedUnrendered` with the justification `'planned — reminder date, deferred
history range'`, and `app_theme.dart:285-289` groups it with three other
declared-ahead-of-a-renderer themes. The guard is doing its job; §12 covers
what the guard cannot check about it.

---

## 3 · Canonical Time contract — Flutter 3.44.8

Read from `_TimePickerDefaultsM3` (`time_picker.dart:3631+`) and the widgets
that consume each slot.

### 3.1 · Slot table

| Slot | Canonical M3 value | Consumed by |
|---|---|---|
| `backgroundColor` | `surfaceContainerHigh` | `Dialog.backgroundColor` |
| `elevation` | `6.0` | `Dialog.elevation` |
| `shape` | `RoundedRectangleBorder(28)` | `Dialog.shape` |
| `padding` | `EdgeInsets.all(24)` | `Padding` inside the `Dialog` |
| `helpTextStyle` | `WidgetStateTextStyle` → `labelMedium` / `onSurfaceVariant` | both headers |
| `dialBackgroundColor` | `surfaceContainerHighest` | `_Dial` face |
| `dialHandColor` | `primary` | `_Dial` hand |
| `dialTextColor` | `selected → onPrimary`, else `onSurface` | dial numerals |
| `dialTextStyle` | `bodyLarge` | dial numerals |
| `hourMinuteColor` | `selected → primaryContainer` (+ pressed / hovered / focused blends), else `surfaceContainerHighest` (+ blends) | dial control (selected only) **and** input-mode fill (focused ⇒ selected) |
| `hourMinuteTextColor` | `selected → onPrimaryContainer`, else `onSurface` | both modes |
| `hourMinuteTextStyle` | **`displayLarge` in dial, `displayMedium` in input** | both modes |
| `hourMinuteShape` | `RoundedRectangleBorder(8)` | **dial mode only** |
| `dayPeriodColor` | `selected → tertiaryContainer`, else `transparent` | AM/PM |
| `dayPeriodTextColor` | `selected → onTertiaryContainer`, else `onSurfaceVariant` | AM/PM |
| `dayPeriodTextStyle` | `titleMedium` | AM/PM |
| `dayPeriodBorderSide` / `dayPeriodShape` | `outline` / `RoundedRectangleBorder(8)` + that side | AM/PM, split into two half-shapes |
| `entryModeIconColor` | **`onSurface`** | the keyboard / clock toggle |
| `inputDecorationTheme` | a full M3 recipe: `filled`, `fillColor: hourMinuteColor`, transparent enabled border at radius **8**, `focusedBorder: primary` width 2, `errorStyle: fontSize 0` | **input mode only** |
| `cancelButtonStyle` / `confirmButtonStyle` | `TextButton.styleFrom()` (all-null) | the footer |

### 3.2 · Canonical geometry

| Constant | Value | Note |
|---|---|---|
| `dialSize` | `256 × 256` | inside `ExcludeSemantics` |
| `dotRadius` / `centerRadius` / `handWidth` | `24` / `4` / `2` | |
| `hourMinuteSize` | `96 × 80` (12 h) · `114 × 80` (24 h) | **height only** is honoured in the dial header; width comes from `Expanded` |
| `hourMinuteInputSize` | `96 × 72` · `114 × 72` | wrapped in `Expanded` in input mode too |
| `dayPeriodPortraitSize` | `52 × 80`, expanded to `52 × 96` so each half clears `kMinInteractiveDimension` | |
| `dayPeriodLandscapeSize` / `dayPeriodInputSize` | `216 × 38` / `52 × 72` | |
| Dialog portrait dial | `310 × 468`, min `238 × 326` | height × clamped scale |
| Dialog input | `280 × 252` (12 h) · `248 × 252` (24 h), min height `196`, hard floor `216` | |
| `insetPadding` | `horizontal 16`, `vertical 24` (dial) / `0` (input) | **not themeable** |
| Text-scale clamp on the box | `maxScaleFactor: 1.1`; portrait scales **height only** | `time_picker.dart:2535-2585` |

### 3.3 · Two behaviours that decide half the findings

**Dial mode never passes an interaction state to `hourMinuteColor`.**
`_DialTimeSelectorControl` builds `states = {selected?}` and paints
`Material(color: resolveAs(backgroundColor, states))` with an `InkWell` on top
(`time_picker.dart:368-382`). The M3 default's hover / press / focus blends are
therefore dead in dial mode, and the app's flat two-state resolver is
*equivalent* there. They matter only in input mode, where
`_HourTextField` synthesises `{focused, selected}` from the focus node
(`time_picker.dart:2237-2243`) — and there the app returns flat
`primaryContainer` where M3 blends 10 % `onPrimaryContainer` on top. That
difference is invisible next to the `focusedBorder: primary width 2` the same
code path takes from `defaultTheme.inputDecorationTheme`, so **input-mode focus
is visible** and there is no finding.

**Nothing about the dial is exposed to assistive technology.** The whole
`_Dial` is wrapped in `ExcludeSemantics` (`time_picker.dart:3035`), and it is a
`GestureDetector` with angle arithmetic — no `Focus`, no keyboard handling. The
accessible and keyboard-operable paths are the two `Semantics` adjustables on
the hour and minute controls (`increasedValue` / `decreasedValue` / `onIncrease`
/ `onDecrease`, lines 440-460 and 549-570) and the entry-mode toggle into the
text fields. That is Flutter's design, not a defect — but it is why F11 is a
finding at all rather than a colour nit.

---

## 4 · Canonical Date contract — Flutter 3.44.8

Read from `_DatePickerDefaultsM3` (`date_picker_theme.dart:1254+`) and
`calendar_date_picker.dart`.

| Slot | Canonical M3 | Consumed by |
|---|---|---|
| `backgroundColor` / `elevation` / `shape` | `surfaceContainerHigh` / `6.0` / radius 28 | `Dialog` |
| `shadowColor` / `surfaceTintColor` / `headerBackgroundColor` | `transparent` ×3 | |
| `headerForegroundColor` | `onSurfaceVariant` | header title + help |
| `headerHeadlineStyle` / `headerHelpStyle` | `headlineLarge` / `labelLarge` | 120-dp portrait header |
| `subHeaderForegroundColor` / `toggleButtonTextStyle` | `onSurface@60 %` / `titleSmall` | the month/year toggle row |
| `weekdayStyle` | **`bodyLarge` · `onSurface`** | the S M T W T F S strip |
| `dayStyle` | **`bodyLarge`** | day numerals |
| `dayForegroundColor` | **`selected → onPrimary`**, then `disabled → onSurface@38 %`, else `onSurface` | day ink |
| `dayBackgroundColor` | `selected → primary`, else `null` | day fill |
| `dayOverlayColor` | `selected → onPrimary` 10/8/10 %; else `onSurfaceVariant` 10/8/10 % | `InkResponse.overlayColor` — the **only** focus cue a cell has |
| `dayShape` | `CircleBorder()` | |
| `todayForegroundColor` | `selected → onPrimary`, `disabled → primary@38 %`, else `primary` | |
| `todayBackgroundColor` | `= dayBackgroundColor` | |
| `todayBorder` | `BorderSide(primary)` — width **1.0** | ring, not fill |
| `yearStyle` / `yearForegroundColor` / `yearBackgroundColor` / `yearOverlayColor` / `yearShape` | `bodyLarge` / same three-branch resolver as day but on `onSurfaceVariant` / `primary` when selected / same overlay recipe / `StadiumBorder()` | |
| `rangeSelectionBackgroundColor` / `rangeSelectionOverlayColor` | `secondaryContainer` / `onPrimaryContainer` washes | |
| `rangePickerHeader*` | `transparent` / `onSurfaceVariant` / `titleLarge` / `titleSmall` | |
| `dividerColor` | **not defaulted** → falls through to `DividerTheme` | `Divider(height: 0)` under the header |
| `inputDecorationTheme` | **not defaulted** → `InputDecorationTheme.of(context).merge(datePickerTheme.inputDecorationTheme)` | `InputDatePickerFormField` |
| `cancelButtonStyle` / `confirmButtonStyle` | `TextButton.styleFrom()` | footer |

Geometry:

| Constant | Value |
|---|---|
| Calendar portrait dialog | `360 × 568` (M3) |
| Input portrait dialog | `328 × 270` |
| Landscape | `496 × 346` calendar |
| `insetPadding` | `horizontal 16, vertical 24` — a `DatePickerDialog` **parameter**, defaulted, and `showDatePicker` does not forward it |
| Day row height | `48` portrait M3; `+ (scale − 1) × 30` above scale 1.3 |
| Month grid horizontal padding | `12` portrait M3 |
| Day cell inner padding | `4` on every side (portrait M3) → a 40-dp circle in a 48-dp cell |
| Tile width | **`crossAxisExtent / 7`** — it flexes; it is not pinned to 48 |
| Text-scale clamp | `3.0` portrait, `1.6` landscape |

**One asymmetry worth stating plainly, because it contradicts the intuition the
time-picker file leaves you with:** the date picker's input mode **does** read
`buildInputDecorationTheme` (`input_date_picker_form_field.dart:261-278`),
while the time picker's does not. Two pickers, two different answers to the
same question, both correct for their own widget.

---

## 5 · MemoX current behaviour, slot by slot

Legend — **retune**: the canonical role is kept, its token or geometry moved.
**substitution**: a different `ColorScheme` role. **restatement**: the app
writes exactly what M3 would have defaulted to.

### 5.1 · `buildTimePickerTheme`

| Slot | Canonical | MemoX | Class | Verdict |
|---|---|---|---|---|
| `backgroundColor` | `surfaceContainerHigh` | same | restatement | ✅ |
| `elevation` | `6.0` | `AppElevation.none` | retune | ✅ AD-14 |
| `shape` | radius 28, no side | `AppRadius.lg` (16) + `outlineVariant` | retune | ✅ matches `dialogTheme` |
| `padding` | `24` | `AppSpacing.xl` = **24** | restatement | ✅ |
| `helpTextStyle` | `labelMedium` (12/w500) | `labelLarge` (14/w600) · `onSurfaceVariant` | retune | ✅ larger, role kept |
| `dialBackgroundColor` | `surfaceContainerHighest` | same | restatement | ⚠️ **F12** — 1.06:1 / 1.15:1 on the dialog |
| `dialHandColor` | `primary` | same | restatement | ✅ |
| `dialTextColor` | `selected → onPrimary`, else `onSurface` | identical | restatement | ✅ 6.20 / 7.73 and 9.97 / 7.79 |
| `dialTextStyle` | `bodyLarge` | `bodyLarge` | restatement | ✅ |
| `hourMinuteColor` | 2 roles + 3 blends | 2 roles, no blends | retune | ✅ blends are dead in dial mode; input mode carries a 2 px `primary` border instead |
| `hourMinuteTextColor` | same two roles | identical | restatement | ✅ 11.44 / 8.87 selected, 9.97 / 7.79 resting |
| `hourMinuteTextStyle` | `displayLarge` / `displayMedium` | **`displaySmall`** for both | retune | ❌ **F5** |
| `hourMinuteShape` | radius 8 | `AppRadius.md` = 12 | retune | ⚠️ **F6** — input mode stays at 8 |
| `dayPeriodColor` | `selected → tertiaryContainer` | identical | restatement | ✅ |
| `dayPeriodTextColor` | `selected → onTertiaryContainer` | identical | restatement | ✅ 9.84 / 7.27 |
| `dayPeriodTextStyle` | `titleMedium` | `titleMedium` | restatement | ✅ |
| `dayPeriodBorderSide` | `outline` | `outline` | restatement | ✅ 4.02 / 3.50 on the dialog |
| `dayPeriodShape` | radius 8 + side | `AppRadius.md` (12) + side | retune | ✅ the half-shape split still works — `hasRoundedBorder` is satisfied by `BorderRadius.circular` |
| `entryModeIconColor` | **`onSurface`** | **`onSurfaceVariant`** | **substitution** | ❌ **F11** |
| `inputDecorationTheme` | full recipe | `null` → Material's | deliberate | ✅ comment verified; drives F6 |
| `cancelButtonStyle` / `confirmButtonStyle` | `TextButton.styleFrom()` | `null` → same | unset | ⚠️ **F7** — the only lever for action emphasis, unused |

Not set and worth knowing: `dayPeriodTextColor` and `hourMinuteTextColor` are
`WidgetStateColor`, which is required — every `TimePickerThemeData` colour slot
is typed `Color?`, so a `WidgetStateProperty<Color>` does not compile. The file
already says this; it is correct.

### 5.2 · `buildDatePickerTheme`

| Slot | Canonical | MemoX | Class | Verdict |
|---|---|---|---|---|
| `backgroundColor` / `elevation` / `shape` | `surfaceContainerHigh` / 6 / 28 | same / `none` / `lg` + hairline | retune | ✅ agrees with `dialogTheme` |
| `headerForegroundColor` | `onSurfaceVariant` | same | restatement | ✅ 4.83 / 4.84 |
| `weekdayStyle` | `bodyLarge` (16) · `onSurface` | `labelMedium` (12) · **`onSurfaceVariant`** | **substitution + 2 rungs** | ❌ **F9** — 10.53 → 4.83 light |
| `dayStyle` | `bodyLarge` (16) | `bodyMedium` (14) | retune | ⚠️ **F9** — `yearStyle` is left at 16 |
| `dayForegroundColor` | `selected` → `disabled` → base | **`disabled` → `selected`** → base | **precedence inversion** | ❌ **F1** |
| `dayBackgroundColor` | `selected → primary` | same, **no `disabled` branch** | | ❌ **F1** (the other half) |
| `dayOverlayColor` | selected-aware, `onPrimary` / `onSurfaceVariant` | `AppInteractionStates.controlOverlay` — always `primary`, never reads `selected` | **substitution** | ❌ **F4** |
| `todayBorder` | `primary`, width 1 | `primary`, `AppStroke.selectionControl` = 2 | retune | ✅ role kept; see §6 |
| `todayForegroundColor` | selected / **disabled** / base | selected / base | **missing branch** | ❌ **F3** |
| `todayBackgroundColor` | `= dayBackgroundColor` | **unset** → M3's own `dayBackgroundColor` | unset | ✅ same value; see §6 |
| `yearForegroundColor` | selected / **disabled** / base | selected / base | **missing branch** | ❌ **F3** |
| `yearBackgroundColor` | `selected → primary` | same | restatement | ✅ |
| `yearOverlayColor` | selected-aware | **unset** → canonical | unset | ⚠️ so day and year overlays disagree — see F4 |
| `yearStyle` | `bodyLarge` | unset → `bodyLarge` | unset | ⚠️ **F9** — day is 14, year is 16 |
| `rangeSelectionBackgroundColor` | `secondaryContainer` | same | restatement | ✅ day ink 9.30 / 7.71 over it |
| `rangePickerHeaderForegroundColor` | `onSurfaceVariant` | same | restatement | ✅ |
| `dividerColor` | undefaulted → `DividerTheme` | `outlineVariant` | restatement | ✅ same value `dividerTheme` is pinned to |
| `dayShape` / `yearShape` / `headerHeadlineStyle` / `headerHelpStyle` / `subHeaderForegroundColor` / `toggleButtonTextStyle` / `rangeSelectionOverlayColor` / `inputDecorationTheme` / `cancelButtonStyle` / `confirmButtonStyle` | as §4 | **unset** | unset | left to Material — see §12 |

---

## 6 · Today vs selected

The distinction is drawn twice, and the file's argument for it is right:
today is a **ring**, selected is a **fill**, so a filled circle means selected
and nothing else. That survives.

What the audit adds is what happens where the two meet, and it turns on one
line of `calendar_date_picker.dart`:

```dart
final bool hasCustomBorderColor =
    datePickerTheme.todayBorder != null && datePickerTheme.todayBorder!.color.opacity != 0.0;
final BorderSide todayBorderSide = hasCustomBorderColor
    ? datePickerTheme.todayBorder!                                   // ← MemoX takes this
    : (…).copyWith(color: dayForegroundColor);                       // ← M3 default takes this
```

Because MemoX supplies an opaque `primary`, `hasCustomBorderColor` is **true**
and the ring is a fixed 2 px `primary` in every state. M3's own default —
opacity 0 — takes the other branch and makes the ring track `dayForegroundColor`,
so it turns `onPrimary` when today is selected and fades to 38 % when today is
disabled.

| State | MemoX renders | M3 renders |
|---|---|---|
| today, not selected | 2 px `primary` ring, `primary` numeral, no fill — **5.19 / 8.43** | 1 px ring tracking `primary` |
| today **and** selected | `primary` fill (from M3's `dayBackgroundColor`, because MemoX leaves `todayBackgroundColor` unset), `onPrimary` numeral, plus a `primary` ring **on a `primary` fill** — invisible but harmless | ring turns `onPrimary`, so the ring is still legible on the fill |
| today **and** disabled | full-strength `primary` ring **and** full-strength `primary` numeral — **identical to enabled** | ring and numeral both drop to `primary@38 %` |

The middle row is cosmetic. The last row is **F3**: for a `showDatePicker`
whose `selectableDayPredicate` or `firstDate`/`lastDate` excludes today — the
obvious case for a reminder-date picker, where past days are not selectable —
today looks tappable and is not.

Leaving `todayBackgroundColor` unset is harmless *today* because M3's
`dayBackgroundColor` and MemoX's resolve to the same `primary`. It stops being
harmless the moment `dayBackgroundColor` is retuned, because today would keep
the old fill. Pinning it is one line and belongs with the F1 fix.

---

## 7 · Disabled state

**Time picker: there is no disabled state to audit.** No slot in
`TimePickerThemeData` resolves `WidgetState.disabled`, `showTimePicker` takes no
predicate, and every control in the dialog is always enabled. Correctly absent.

**Date picker: three defects, all in the same shape — a resolver that does not
model the state it will be handed.** `_Day` builds
`states = {if (isDisabled) disabled, if (isSelectedDay) selected}` and passes
that *same set* to the foreground and background resolvers
(`calendar_date_picker.dart:1233-1249`), so both states can arrive together.

| Case | MemoX ink | MemoX fill | Contrast | M3 |
|---|---|---|---|---|
| disabled day | `semantic.onDisabled` | none → dialog | 2.07 / 2.54 | `onSurface@38 %` — the **same colour**, 2.07 / 2.54 |
| **disabled + selected day** | `semantic.onDisabled` | **`primary`** | **1.32 / 1.02** | `onPrimary` on `primary` — 6.20 / 7.73 |
| disabled today | `primary` | none | 5.19 / 8.43 — *indistinguishable from enabled* | `primary@38 %` |
| disabled year | `onSurfaceVariant` | none | 4.83 / 4.84 — *indistinguishable from enabled* | `onSurfaceVariant@38 %` |

The first row is fine and shows the app's token is exactly M3's value under a
different name. The second row is **F1**: the resolver checks `disabled` first
and returns a disabled ink, while the background resolver does not check
`disabled` at all and returns the selected fill. Neither half is wrong on its
own; together they paint 1.02:1 in dark, which is one colour.

**A disabled-and-selected day is reachable, not theoretical.** `showDatePicker`
asserts only that `initialDate` lies within `firstDate`…`lastDate`; a
`selectableDayPredicate` that excludes it is a documented, supported
configuration, and `_DatePickerDialogState` renders it as selected-but-disabled
until the user picks something else.

---

## 8 · Modal action hierarchy, relative to this app's dialog system

The app has an explicit, enforced answer for dialog actions, written down in
`MxConfirmDialog` and `MxDialogMetrics`:

| Question | The app's answer | Where |
|---|---|---|
| Emphasis | confirm = `MxActionButtonVariant.primary` (filled) or `destructive`; cancel = `secondary` (outlined) | `mx_confirm_dialog.dart:153-172` |
| Layout | `MxButtonPair` — equal widths, matched heights, **stacks** when a 320-dp screen at scale 2.0 leaves no room for a row | `mx_confirm_dialog.dart:139-146` |
| Why not `OverflowBar` | stated: it "sizes each action to its own label, so `Cancel` beside `Delete deck` is a small button next to a large one" | same |
| Inset from screen | `MxDialogMetrics.inset` = **40** horizontal, 24 vertical | `mx_dialog_metrics.dart:28-41` |
| Inset from the dialog's own edge | `actionsInset` = `AppSpacing.xl` = 24 | `mx_dialog_metrics.dart:35` |
| Focus | cancel autofocused for `destructive` and `cautious`; neither for `normal` | `mx_confirm_dialog.dart:109-111` |

The time picker answers every one of them differently, and only one of the
differences is fixable through a theme:

| Question | Time picker | Fixable via theme? |
|---|---|---|
| Emphasis | two bare `TextButton`s, **identical weight** — Cancel and OK are the same control | **Yes** — `cancelButtonStyle` / `confirmButtonStyle` accept a `ButtonStyle` and are currently `null` |
| Layout | `OverflowBar(spacing: 8, overflowAlignment: end)` — the exact widget `MxConfirmDialog` documents rejecting | No |
| Inset from screen | **16**, hardcoded in `TimePickerDialog.build` (`time_picker.dart:2669`) | **No** |
| Actions padding | the theme's `padding` (24) is the dialog's whole inner padding; there is no separate actions inset | n/a |
| Focus | nothing autofocused; focus is visible because the app's `textButtonTheme` underlines the label at `AppStroke.focus` on focus | — ✅ this part works |

Two consequences.

**F7 — the footer has no hierarchy, and no press affordance.** The app's
`textButtonTheme` (`app_button_themes.dart:318-354`) was written for
`MxTextButton`, an inline text link: `padding: EdgeInsets.zero`,
`minimumSize: Size(0, 48)`, `alignment: centerStart`,
`overlayColor: transparent`, `splashFactory: NoSplash`. `TextButton.styleFrom()`
with no arguments is an all-null `ButtonStyle`, so the theme wins every slot,
and the picker's OK / Cancel inherit all of it. The **touch target is still
48 × 48** — `_InputPadding` guarantees that independently — but the visible
button is the label alone with no fill, no border, no ripple and no hover wash,
in a dialog whose siblings all show a filled primary action. Focus is the one
state that still reads, via the underline.

**F8 — the picker is 24 dp wider per side than every other dialog.** At 393 dp
the time picker spans 361 dp of the screen; `MxConfirmDialog` spans 313. Two
modals opened from adjacent rows of the same settings screen are visibly
different widths, and **no theme slot can close the gap** —
`insetPadding` is a literal in `TimePickerDialog.build`. The `builder:`
parameter of `showTimePicker` could wrap the returned dialog, but that is a
wrapper this audit is not proposing; §13 hands it to the owner as a decision.

For completeness: the barrier **is** shared. `showDialog` resolves
`barrierColor` through `DialogTheme.of(context)` then
`Theme.of(context).dialogTheme.barrierColor` (`dialog.dart:1655-1658`), so the
picker darkens the page with `modalBarrierColor(scheme)` like everything else.

---

## 9 · Touch targets

All source-derived; none required a render.

| Control | Size | Floor | Verdict |
|---|---|---|---|
| Time · hour / minute (dial) | height 80 fixed; width from `Expanded` — 76 / 96 / 103.5 / 111 dp at 320 / 360 / 375 / 393 | 48 | ✅ |
| Time · hour / minute (input) | 96 × 72 (12 h) or 114 × 72 (24 h), inside `Expanded` | 48 | ✅ |
| Time · AM / PM, portrait | box is 52 × 80, expanded to 52 × **96** so each half is 52 × 48, plus `_DayPeriodInputPadding` which hit-tests **outside** the painted bounds | 48 | ✅ |
| Time · AM / PM, landscape | 216 × 38 expanded to 216 × 48 | 48 | ✅ |
| Time · entry-mode toggle | `IconButton` under `buildIconButtonTheme` → `minimumSize: Size.square(48)` | 48 | ✅ |
| Time · OK / Cancel | label width, then `_InputPadding(minSize: 48 × 48)` under `materialTapTargetSize: padded` + `VisualDensity.standard` | 48 | ✅ |
| Time · the dial itself | one `GestureDetector` over a 256-dp face with angle arithmetic; there is no per-numeral target to measure | n/a | n/a |
| Date · day cell | 48 tall; **`crossAxisExtent / 7` wide** | 48 | ❌ **F10**, see §10 |
| Date · year cell | `_yearPickerGridDelegate`, 3 columns of the dialog width | 48 | ✅ at every width in scope |
| Reminder row that opens it | `MxListTile` | 48 | ✅ |

**The only touch-target defect in either picker is the date grid's width**, and
it comes from the dialog being wider than the phone, not from the cell.

---

## 10 · 320 / 360 / 375 / 393 dp

### 10.1 · Time picker

`insetPadding` 16 per side, then the theme's `padding` 24 per side, so the
content viewport is `screen − 80`. `_dialogSize` proposes a width, the
`LayoutBuilder` constrains it, and `_minDialogSize` then raises it back if the
constrained value is smaller — which is what puts content into the outer
`SingleChildScrollView(scrollDirection: horizontal)`.

| Screen | Viewport | Dial: want 310 / min 238 → got | EN input: want 280 / min 280 | VI input: want 248 / min 248 |
|---|---|---|---|---|
| 320 | 240 | **240** — fits, 2 dp above the floor | **280** → **40 dp of horizontal scroll** |**248** → **8 dp of horizontal scroll** |
| 360 | 280 | 280 | 280 — exact fit | 248 |
| 375 | 295 | 295 | 280 | 248 |
| 393 | 313 | 310 | 280 | 248 |

Dial mode never overflows, because the hour/minute controls are `Expanded` in
the header row and simply narrow:

| Screen | hour / minute box, EN 12 h | VI 24 h |
|---|---|---|
| 320 | **76.0** | 108.0 |
| 360 | 96.0 | 128.0 |
| 375 | 103.5 | 135.5 |
| 393 | 111.0 | 143.0 |

At 393 the EN box lands at 111 dp against M3's designed 96 — comfortable. At
320 it is 76, and whether `displaySmall`'s two digits still centre cleanly in
76 dp is **unverified — needs a render** (they certainly fit; canonical
`displayLarge` at 57 px would be tighter).

**Input mode at 320 dp scrolls horizontally**, in both languages, because
`_minDialogSize` floors the width at 280 (EN) / 248 (VI) against a 240-dp
viewport. That is a framework behaviour, reachable from the reminder screen via
the keyboard toggle, and no theme value changes it.

### 10.2 · Date picker

The calendar dialog wants a fixed **360** and gets `min(360, screen − 32)`. The
month grid subtracts 12 dp of padding per side and divides by 7.

| Screen | Dialog width | Grid | **Day tile width** | ≥ 48? |
|---|---|---|---|---|
| 320 | 288 | 264 | **37.71** | ❌ |
| 360 | 328 | 304 | **43.43** | ❌ |
| 375 | 343 | 319 | **45.57** | ❌ |
| 393 | 360 | 336 | **48.00** | ✅ exactly |

**F10.** The M3 date picker is dimensioned for a 392-dp-or-wider phone and
degrades silently below it: no overflow, no exception, just tap targets that
shrink to 37.7 dp at 320. The app's own `test/demo` surface is 393 × 852, which
is precisely the one width where this is invisible — so a golden of a date
picker, if one is ever added, would show the only passing case.

Height is never the binding constraint in portrait: 568 against 852 − 48 = 804.

---

## 11 · textScale 1.0 / 1.3 / 2.0

Three different rules inside the time picker, all in the SDK (**F15**):

| Element | Rule | 1.0 | 1.3 | 2.0 |
|---|---|---|---|---|
| Dialog box | `clamp(maxScaleFactor: 1.1)`, applied to **height only** in portrait | 310 × 468 | 310 × 514.8 | 310 × 514.8 |
| Hour / minute numerals | `TextScaler.noScaling` (dial) and `MediaQuery.withNoTextScaling` (input) | 36 px | **36 px** | **36 px** |
| `:` separator | `TextScaler.noScaling` | 36 px | 36 px | 36 px |
| AM / PM label | `clamp(maxScaleFactor: 2.0)` | 16 px | 20.8 | 32 |
| Help text, Hour/Minute captions, OK / Cancel | unclamped | 14 / 12 / 14 | ×1.3 | ×2.0 |

Two things follow.

**F5 has an accessibility edge the type-rung comparison alone does not show.**
The number the user is reading is the one element in the dialog that *cannot*
be enlarged by any setting. M3 sizes it at 57 px in dial mode precisely because
it is fixed; MemoX pins it at 36 for both modes. A user at scale 2.0 gets every
label in the dialog doubled and the digits unchanged at 63 % of canonical.

**The AM/PM box does not grow with its label.** `dayPeriodPortraitSize.width` is
a hard 52 dp while the label scales to ×2.0. In EN — `AM` / `PM`, two glyphs at
`titleMedium` — that is comfortable. In VI it is not; see §12.

Date picker, for the record: the box scales by a factor clamped at **3.0**
(portrait) and the day row height grows by `(scale − 1) × 30` above 1.3, but
`tileHeight` is then `min(scaledRowHeight, viewport / 7)`, so at scale 2.0 the
dialog wants 720 × 1136 against an 804-dp-tall viewport and the rows compress.
Latent; not chased further.

---

## 12 · EN / VI

The delegates are wired correctly — `GlobalMaterialLocalizations`,
`GlobalWidgetsLocalizations` and `GlobalCupertinoLocalizations` are all
registered (`app.dart:72-77`) — so every string inside both pickers is
translated. Verified against
`flutter_localizations/…/generated_material_localizations.dart` at 3.44.8:
`MaterialLocalizationVi` supplies `cancelButtonLabel: 'Huỷ'`,
`okButtonLabel: 'OK'`, `inputTimeModeButtonLabel`, `dialModeButtonLabel`, the
hour/minute mode announcements, and `anteMeridiemAbbreviation: 'SÁNG'` /
`postMeridiemAbbreviation: 'CHIỀU'`.

`helpText` is the app's own `reminderTimeLabel` — `"Reminder time"` / `"Giờ
nhắc"` — present in both ARBs. No hardcoded string reaches either picker.

### 12.1 · The clock format disagrees between the row and the dialog — F2

Two different sources of truth for the same question:

| | Source | EN, 24-h device setting **on** | VI |
|---|---|---|---|
| `ReminderTimeRowWidget` | `MaterialLocalizations.formatTimeOfDay(t)` with the **default** `alwaysUse24HourFormat: false` → the **locale's** `timeOfDayFormatRaw` | `h_colon_mm_space_a` → **"8:00 PM"** | `HH_colon_mm` → "20:00" |
| `showTimePicker` | `timeOfDayFormat(alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context))` — the **platform flag** (`time_picker.dart:3132`) | `HH_colon_mm` → **24-hour dial, "20:00", no AM/PM** | `HH_colon_mm` → same |

On a `vi` device the two agree, because `vi`'s raw format is already 24-hour.
On an `en` device with Android's *Use 24-hour format* switched on — a common
setting — **the row says `8:00 PM` and the dialog it opens is a 24-hour dial
reading `20:00` with the AM/PM control absent.** Tapping the row changes the
apparent format of the value being edited.

The finding is sharpened by the code's own comment. `reminder_labels_widget.dart:37-40`
says:

> **`MaterialLocalizations`, not an ARB entry and not `intl` directly.** A
> 24-hour locale and a device with the 24-hour setting on are different
> questions, and only this knows both — a hand-rolled `HH:mm` would print
> `20:00` to a user whose phone says `8:00 PM` everywhere else.

The reasoning is right and the call does not implement it: the device setting
is only consulted when it is passed, and line 41-43 passes nothing. The
one-argument fix is in §13.

### 12.2 · The AM/PM box and Vietnamese

`SÁNG` and `CHIỀU` are 4 and 5 glyphs against EN's 2, at `titleMedium`
16 px / w600, in a **fixed 52-dp-wide** box whose label scales to ×2.0. On the
face of it that is an overflow waiting to happen.

**It is not reachable today.** The control renders only when
`hourDialType == twelveHour`, which follows from `timeOfDayFormat`, which for
`vi` is `HH_colon_mm` in every configuration — the MediaQuery flag can force a
locale *to* 24-hour, never away from it. So a Vietnamese user never sees AM/PM,
and the app's `tertiaryContainer` decision for it is EN-only in practice.

Recorded rather than filed as a finding, because it becomes one the moment a
12-hour locale with long day-period abbreviations is added to
`supportedLocales`.

---

## 13 · Dead and speculative themes

**`datePickerTheme` is declared with zero production callers.** That is
deliberate, recorded in `theme_coverage_test.dart:144` as `'planned — reminder
date, deferred history range'`, and `app_theme.dart:285-289` explains the
admission rule. This audit does not argue with the decision — the theme's own
header makes the case, and every colour in it was already decided elsewhere.

Three things about it that are not currently recorded anywhere:

1. **Two of its resolvers are wrong, and being unrendered is why nobody
   noticed** (F1, F3, F4). A theme admitted on the grounds that "every colour it
   uses was already decided and already measured" still has to model the state
   set the widget will hand it. `dayForegroundColor`'s precedence and
   `dayOverlayColor`'s missing `selected` branch are not colour choices; they
   are resolver shape, and the admission test as written does not look at shape.

2. **`app_planned_themes.dart` does not exist** (F14). It was split at M100.31
   — `m3_role_bindings.dart:14` says so — but five live references still point
   at it as the place the admission test and the justifications live:

   | File | Line | Claim |
   |---|---|---|
   | `lib/core/theme/app_theme.dart` | 288 | "the admission test, and the ones it turned away, are in `app_planned_themes.dart`" |
   | `lib/core/theme/foundations/app_sizing.dart` | 9, 40 | cites it as the convention to follow |
   | `test/core/theme/contracts/theme_coverage_test.dart` | 143 | "Every entry here is justified in `app_planned_themes.dart`" |
   | `test/core/theme/components/app_planned_themes_test.dart` | 12 | "the admission test in `app_planned_themes.dart` turns on" |
   | `test/core/theme/contracts/theme_coverage_test.dart` | 274 | names it in the comment-stripping rationale |

   The `allowedUnrendered` list is the guard that stops the waiting room
   growing, and its justification points at nothing. The test file is still
   named after the deleted file too, while the theme it actually tests now
   lives in `app_date_picker_theme.dart`.

3. **`buildDatePickerTheme` sets `rangeSelectionBackgroundColor` and
   `rangePickerHeaderForegroundColor`** — range-picker slots, for
   `showDateRangePicker`, which is not merely unrendered but not in either
   stated plan ("reminder date, deferred history range" — a history *range* is
   a query filter, not necessarily a `DateRangePicker`). Both restate M3's own
   value, so they cost nothing; they are noted so a future pass can decide
   whether the waiting room should be smaller.

Nothing else in either theme is dead. Every `timePickerTheme` slot is read by
the reminder flow in one mode or the other.

---

## 14 · Tests, guards and goldens

### 14.1 · What exists

| File | Covers | Assertions |
|---|---|---|
| `test/core/theme/components/app_time_picker_theme_test.dart` | `timePickerTheme` | agreement with `dialogTheme` (background, elevation, shape); radius = `AppRadius.lg`; 4 contrast pairs |
| `test/core/theme/components/app_planned_themes_test.dart` | `datePickerTheme` (+ 3 others) | agreement with `dialogTheme`; selected-day contrast; today-ring contrast |
| `test/core/theme/contracts/m3_role_contract_test.dart` | both | 5 time slots pinned, 6 date slots pinned |
| `test/core/theme/contracts/theme_coverage_test.dart` | both | `showTimePicker` → slot declared; `datePickerTheme` allow-listed as unrendered |

### 14.2 · What does not exist

- **No test in the repository renders either picker.** `showTimePicker`,
  `TimePicker` and `showReminderTimePicker` appear **zero** times under
  `test/`, `integration_test/` and `widgetbook/`. `reminder_settings_screen_test.dart`,
  `reminder_settings_layout_test.dart` and `reminder_settings_a11y_test.dart`
  all stop at the row. (**G1**)
- **No golden.** `test/demo/goldens/` holds 152 PNGs; `reminder_settings_light.png`
  and `reminder_settings_dark.png` are the screen behind the dialog. The three
  files matching `*picker*` are `card_move_picker_*` and `deck_move_picker_*`,
  which are the app's own deck-tree pickers, not Material's.
- **No Widgetbook use case.** `widgetbook/lib/components/overlay_components.dart`
  catalogues `MxConfirmDialog`, `MxActionSheet`, `MxFormDialog` and
  `MxAlertDialog`. Neither picker is a shared component, so the DoD's
  registration rule does not strictly bite — but the consequence is that no
  surface anywhere renders them for review.
- **Neither picker is in `m3_role_bindings.dart`** (11 components: AppBar, Card,
  Checkbox, ChoiceChip, FloatingActionButton, NavigationBar, OutlinedButton,
  SegmentedButton, Switch, TabBar, TextButton) **or in
  `m3_combined_state_test.dart`** (ChoiceChip, Switch, SegmentedButton,
  Checkbox, OutlinedButton, NavigationBar, plus the disabled-leak sweep).
  (**G2**) That last file's closing group is *"a disabled control never resolves
  to an enabled accent"* — F3 is exactly that, and F1 is exactly the combined
  state the rest of the file exists for.

### 14.3 · Two assertions measured against the wrong ground

Both currently pass, and both would keep passing after a change that broke what
they mean:

| Test | Measures against | Should be | Real value |
|---|---|---|---|
| `app_time_picker_theme_test.dart:144` | `colorScheme.surface` | `surfaceContainerHigh` — the AM/PM box is drawn on the dialog | 4.02 / 3.50 ✅ |
| `app_planned_themes_test.dart:71` | `colorScheme.surface` | `surfaceContainerHigh` | 5.19 / 8.43 ✅ |

---

## 15 · Severity registry

`Reach` = whether anything in the app can display it at BASE_SHA.
`Sev` = impact when reached.

### P1

**F1 · A disabled-and-selected day is one colour** — *latent*

- Evidence: `app_date_picker_theme.dart:33-43` checks `disabled` before
  `selected` in `dayForegroundColor` and omits `disabled` from
  `dayBackgroundColor`; `_DatePickerDefaultsM3.dayForegroundColor`
  (`date_picker_theme.dart:1318-1326`) checks `selected` first;
  `calendar_date_picker.dart:1233-1249` passes both states in one set.
  Composited: `#61223354` over `#4454CC` = **1.32:1**; `#61CBCCD2` over
  `#BCC2FF` = **1.02:1**.
- Closure test: in `m3_combined_state_test.dart`, resolve
  `dayForegroundColor` and `dayBackgroundColor` with
  `{disabled, selected}` and assert ≥ 4.5:1 in both brightnesses. It fails at
  BASE_SHA.

**F2 · The reminder row and its picker disagree about 12 vs 24 hour** — *production*

- Evidence: `reminder_labels_widget.dart:41-43` calls `formatTimeOfDay(t)` and
  takes the default `alwaysUse24HourFormat: false`
  (`material_localizations.dart:266`), which resolves to the locale's
  `timeOfDayFormatRaw` — `h_colon_mm_space_a` for `en`. `time_picker.dart:3132`
  passes `MediaQuery.alwaysUse24HourFormatOf(context)`. The two differ exactly
  when the platform flag is on in a 12-hour locale.
- Closure test: a widget test pumping `ReminderTimeRowWidget` and
  `showTimePicker` under `MediaQuery(alwaysUse24HourFormat: true)` with
  `locale: en`, asserting the row's text and
  `MaterialLocalizations.timeOfDayFormat` agree.
- Fix, for the record: `formatTimeOfDay(t, alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(this))`.

**G1 · Nothing renders either picker** · **G2 · Neither picker is in the state guards** — *see §14*

- Closure: one widget test that opens `showTimePicker` from the reminder
  harness and asserts the dialog's background, corner, elevation and the
  resolved hour/minute pair; plus `RoleBinding` rows and a combined-state group
  for both pickers.

### P2

| # | Evidence | Closure test |
|---|---|---|
| **F3** | `app_date_picker_theme.dart:51-55` and `:66-70` have no `disabled` branch; canonical has one at `date_picker_theme.dart:1365-1371` / `1385-1391` | resolve `todayForegroundColor` / `yearForegroundColor` with `{disabled}` and assert the result differs from `{}` |
| **F4** | `app_date_picker_theme.dart:44` → `AppInteractionStates.controlOverlay` → `_overlay` (`app_interaction_states.dart:197-214`) never reads `selected` and always washes with `scheme.primary`; `calendar_date_picker.dart:1305-1313` makes that overlay the cell's only focus cue. The app's own `AppStateOpacity.filledHoverBlend` doc names this exact failure for filled buttons | resolve `dayOverlayColor` with `{selected, focused}` and assert ≥ 3:1 against `dayBackgroundColor.resolve({selected})` |
| **F5** | `app_time_picker_theme.dart:80` = `texts.displaySmall` (36); `_TimePickerDefaultsM3.hourMinuteTextStyle` switches `displayLarge` (57) / `displayMedium` (45) by entry mode; `time_picker.dart:380` and `:2257` both refuse text scaling | assert `hourMinuteTextStyle.fontSize` against the rung the owner chooses, per mode |
| **F6** | `app_time_picker_theme.dart:81-83` sets radius `AppRadius.md` = 12; `inputDecorationTheme` is null so input mode takes `selectorRadius` = 8 from `_TimePickerDefaultsM3.inputDecorationTheme` | assert `hourMinuteShape`'s radius equals the radius the input-mode borders resolve to |
| **F7** | `time_picker.dart:2631-2647` builds two `TextButton`s with `TextButton.styleFrom()` (all-null); `app_button_themes.dart:318-354` then supplies `padding: zero`, `overlayColor: transparent`, `NoSplash`; `cancelButtonStyle` / `confirmButtonStyle` are unset in `buildTimePickerTheme` | assert `timePickerTheme.confirmButtonStyle` is non-null and its `backgroundColor` differs from `cancelButtonStyle`'s |
| **F8** | `time_picker.dart:2669` — `insetPadding: EdgeInsets.symmetric(horizontal: 16, …)`, a literal; `MxDialogMetrics.inset` = 40 | not theme-testable; §16 |
| **F9** | `app_date_picker_theme.dart:31-32` — `labelMedium` (12) + `onSurfaceVariant` vs canonical `bodyLarge` (16) + `onSurface`; `dayStyle` `bodyMedium` (14) vs `bodyLarge` (16); `yearStyle` unset = 16. Weekday ink 10.53 → **4.83** light, 8.98 → **4.84** dark | pin `weekdayStyle.color` to `onSurface` in `m3_role_bindings.dart`; assert `dayStyle.fontSize == yearStyle.fontSize` |
| **F10** | `_calendarPortraitDialogSizeM3 = 360`; `insetPadding` 16; `_monthPickerHorizontalPaddingPortraitM3 = 12`; `_DayPickerGridDelegate` → `crossAxisExtent / 7`. 37.71 / 43.43 / 45.57 / 48.00 dp at 320 / 360 / 375 / 393 | a layout test at 320 dp asserting the day cell's width ≥ 48 — it fails, which is the point; the fix is §16 |
| **G3** | `m3_role_contract_test.dart:267-317` | add the six unpinned slots |

### P3

| # | Evidence | Note |
|---|---|---|
| **F11** | `app_time_picker_theme.dart:136` = `onSurfaceVariant`; `_TimePickerDefaultsM3.entryModeIconColor` = `onSurface`. 4.83 / 4.84 vs 10.53 / 8.98. Both clear the 3:1 graphic floor | a role substitution on the one control that reaches the accessible entry mode; restoring `onSurface` is one token |
| **F12** | `surfaceContainerHighest` on `surfaceContainerHigh` = **1.06:1 light / 1.15:1 dark** | the file says the dial face should "read as a panel within the sheet"; at 1.06:1 it does not. Both roles are canonical, so this is a **palette** question (the app's surface ladder is compressed), not a role one |
| **F13** | `app_time_picker_theme.dart:58` claims 7.51 light / 5.88 dark for `onPrimary` on `dialHandColor`; recomputed **6.20 / 7.73**. `docs/wbs.md:17574` independently records **7,73** for dark `onPrimary` on dark `primary` | the light/dark figures look transposed and pre-M100.18. Every other number in both picker files reproduces to ±0.09 |
| **F14** | five references to a deleted file — table in §13 | |
| **F15** | §11's three-rule table | framework behaviour; recorded so a future scale audit does not re-derive it |
| **G4 / G5 / G6** | §14.2, §14.3 | |

---

## 16 · Implementation order, files, owner decisions

Ordered by *reach first, then severity* — a defect nobody can see does not
outrank one every reminder user meets.

### Step 1 — the two production defects, one file each

| Action | File |
|---|---|
| **F2** — pass `alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(this)` to `formatTimeOfDay`, so the row asks the same question the picker asks | `lib/features/reminder/presentation/widgets/support/reminder_labels_widget.dart` |
| **F11** — `entryModeIconColor: scheme.onSurface`, restoring the canonical role | `lib/core/theme/components/pickers/app_time_picker_theme.dart` |
| **F13** — correct the contrast figures in the comment | same |

### Step 2 — the coverage that would have caught both

| Action | File |
|---|---|
| **G1** — one widget test that actually opens `showTimePicker` from the reminder harness and reads the dialog's surface, corner, elevation and resolved pairs | new, under `test/features/reminder/presentation/` |
| **G2** — `RoleBinding` rows for `TimePicker` and `DatePicker`; a combined-state group for both | `test/core/theme/contracts/m3_role_bindings.dart`, `m3_combined_state_test.dart` |
| **G3** — pin `todayBorder`, `dayOverlayColor`, `dayPeriodColor`, `entryModeIconColor`, `weekdayStyle`, `dayStyle` | `test/core/theme/contracts/m3_role_contract_test.dart` |
| **G4 / G5** — measure the AM/PM edge and the today ring against `surfaceContainerHigh` | `app_time_picker_theme_test.dart`, `app_planned_themes_test.dart` |

### Step 3 — the date picker's resolvers, before anything renders it

All four in `lib/core/theme/components/pickers/app_date_picker_theme.dart`:

- **F1** — check `selected` before `disabled` in `dayForegroundColor`, and give
  `dayBackgroundColor` a `disabled` branch. Pin `todayBackgroundColor`
  explicitly at the same time (§6).
- **F3** — add the `disabled` branch to `todayForegroundColor` and
  `yearForegroundColor`.
- **F4** — replace `controlOverlay` with a selected-aware resolver, or extend
  `AppInteractionStates` with one. This is the same defect
  `AppStateOpacity.filledHoverBlend` was created to fix for filled buttons, so
  the app already owns the pattern.
- **F9** — restore `weekdayStyle`'s `onSurface`, and settle `dayStyle` /
  `yearStyle` on one rung.

### Step 4 — F14, and rename the test file after what it tests

`app_theme.dart`, `app_sizing.dart`, `theme_coverage_test.dart` and
`app_planned_themes_test.dart` all name a file that does not exist. Point them
at the four `pickers/` and `selection/` files that replaced it, and consider
`app_date_picker_theme_test.dart` for the test.

### Owner decisions this audit will not make

1. **F5 — how big is the hour/minute readout?** Canonical is `displayLarge`
   (57) in dial mode and `displayMedium` (45) in input; MemoX is `displaySmall`
   (36) for both. 57 px is what makes the readout legible for a control that
   refuses text scaling, and it fits the 96 × 80 box M3 designed around it — but
   at 320 dp the box narrows to 76 dp and this app has no render of the result.
   Three options: adopt canonical per-mode (a `WidgetStateTextStyle` switching
   on entry mode, which is what M3 does); adopt a single intermediate rung;
   or keep 36 and record the accessibility trade in the file. **Recommendation:
   per-mode canonical**, verified with a 320-dp golden before it lands.
2. **F6 — where does the corner live?** Either drop `hourMinuteShape` back to 8
   so both modes agree with Material, or supply a `TimePickerThemeData.inputDecorationTheme`
   whose borders use `AppRadius.md`. The second is more code and re-opens the
   question the file deliberately closed ("it becomes worth deciding the day a
   mock shows that mode"). **Recommendation: 8**, unless a mock says otherwise.
3. **F7 — does the picker footer get the app's action hierarchy?**
   `cancelButtonStyle` and `confirmButtonStyle` accept a `ButtonStyle` applied
   to a `TextButton`, so a *filled* confirm is reachable
   (`backgroundColor` + `foregroundColor` + `shape` + a real `padding`) without
   substituting the widget. What is **not** reachable through the theme is
   `MxButtonPair`'s equal widths and its stacking rule. So the choice is:
   retune the two styles toward the app's emphasis and accept `OverflowBar`
   layout, or leave the picker as Material's and accept that one dialog in the
   app has a flat footer. **Recommendation: retune the two styles** — it is a
   theme change, it is exactly the "retune rather than substitute" rule this
   audit was given, and it costs nothing structural.
4. **F8 / F10 — the two geometry defects are not themeable.** The time picker's
   16-dp inset and the date picker's 360-dp fixed width are literals inside
   `TimePickerDialog.build` and `_dialogSize`. Closing either means wrapping the
   dialog through `showTimePicker(builder:)` / passing
   `DatePickerDialog.insetPadding`, and **this audit does not propose a
   wrapper** — the brief forbids inventing one and the report-only scope
   forbids writing one. They are recorded so the decision is made deliberately
   if a date picker is ever built: the honest reading of F10 is that
   `showDatePicker` is a poor fit below 393 dp, and a reminder-date flow may be
   better served by the app's own surfaces than by Material's dialog.
5. **F12 — is the dial face supposed to be visible?** Both roles are canonical;
   the 1.06:1 is a property of this palette's compressed surface ladder. Either
   accept it and correct the file's claim, or raise `surfaceContainerHighest`,
   which is a palette change reaching well beyond the pickers.

### What is deliberately left alone

`headerHeadlineStyle` (unset → `headlineLarge`, 32 px, against `dialogTheme`'s
`titleMedium` 16), `dayShape`, `yearShape`, `subHeaderForegroundColor`,
`toggleButtonTextStyle`, `rangeSelectionOverlayColor`, `yearOverlayColor` and
both pickers' `inputDecorationTheme`. Every one is canonical M3 by omission, and
setting any of them is a decision that needs a screen to check it against —
which is the rule `app_time_picker_theme.dart:130-135` already states for
itself, and it is the right rule.
