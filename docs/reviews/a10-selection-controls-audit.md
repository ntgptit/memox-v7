# A10 — Selection / toggle controls, deep audit

| | |
|---|---|
| Base commit (`BASE_SHA`) | `3207e7b7e0d3a2ecefa5e6a85fed48a65890ba6b` — *refactor(theme): the dark card stops glowing…* (M100.35, #435) |
| Branch | `claude/a10-selection-controls-audit-ff7q7o` |
| Pinned SDK | Flutter **3.44.8** stable · framework `058e0af2c2` · engine `0cd610717b` · Dart 3.12.2 |
| Scope | `CheckboxThemeData` · `RadioThemeData` · `SwitchThemeData` · `SegmentedButtonThemeData` · `SliderThemeData` · `MxCheckboxRow` · `MxRadioRows` · `MxSwitchRow` · the `ListTile` variants and every caller |
| Mode | **Report only.** No production, theme, test, Widgetbook, doc or design-system file was changed; no golden was regenerated. `git status` was verified clean before and after |
| Method | The pinned SDK was cloned at tag `3.44.8` and read directly (`checkbox.dart`, `radio.dart`, `raw_radio.dart`, `switch.dart`, `segmented_button.dart`, `slider.dart`, `slider_theme.dart`, `list_tile.dart` and the three `*_list_tile.dart`), plus a throwaway measurement suite run against the real `buildLightTheme()` / `buildDarkTheme()` |
| Out of scope | Chip / pill / filter — covered by `mx-chip-pill-deep-audit.md`. Referenced here only for the semantic comparison in §4.6 |

**Every number below was measured, not recalled.** The harness lived at
`test/zz_a10_audit_measure_tmp_test.dart` (+ three focused probes) for the
duration of the audit and was deleted; it resolved every `WidgetStateProperty`
in the built themes across ten state combinations, pumped the three `Mx` rows at
320 / 360 / 375 / 393 dp × `textScaler` 1.0 / 1.3 / 2.0 in EN and VI, and read
sizes, type rungs and merged semantics data off the tree. Contrast ratios come
from `test/support/color_math.dart` — the repository's own WCAG 2.x
implementation — so they are comparable with every ratio already quoted in
`app_toggle_themes.dart`.

---

## 1 · Verdict

**The three rendered controls are in good shape and stay on their Material
roles in every state a user can reach today. The two unrendered ones are not,
and one of the guards that is supposed to be watching them is asserting the
wrong canonical class — it passes, and it is wrong.**

There is **no P0 and no P1 that a user of the shipped app can reach.** That is
the honest reading and it is worth stating plainly rather than promoting
something to fill the slot: the tag filter's checkbox, the reminder and importer
switches, and the scheduler / appearance / language / order radios all resolve
`primary`, `onPrimary`, `outline`, `onSurfaceVariant`, `onSurface`,
`surfaceContainerHighest` and `secondaryContainer` exactly where
`_CheckboxDefaultsM3`, `_RadioDefaultsM3` and `_SwitchDefaultsM3` do, under
`{}`, `{selected}`, `{focused}`, `{selected, focused}`, `{hovered}` and
`{pressed}`. M100.18 → M100.23 did that work and it holds.

The one **P1** is a test defect, and it is a P1 because a guard that is wrong is
worse than a guard that is absent:

> `m3_role_contract_test.dart`'s `Slider` block pins the roles of
> `_SliderDefaultsM3` — the 2024 expressive slider — while `Slider` in this app
> resolves `_SliderDefaultsM3Year2023`. The guard is green today and would stay
> green through a first render that is off-canonical in five slots.

Everything else clusters around **one root cause**, which is the finding this
audit exists to produce:

> **`AppSemanticColors.disabledSurface` is used as a single disabled fill in
> four places where Material 3 deliberately uses two different opacities to keep
> a disabled control's *value* readable.** M3 pairs a 38 %-derived ink with a
> 12 %-derived ground precisely so that "disabled" and "disabled and *on*" stay
> different. Collapsing both onto one token makes them identical: measured
> **1.00 : 1** on the slider's active-vs-inactive track, **1.00 : 1** between a
> disabled-on and a disabled-off switch thumb, and **1.24 : 1** between a
> disabled ticked checkbox and the card behind it.

That single substitution is what forced the checkbox's disabled ring (P2-3), and
it is why P2-2 and P2-3 must be fixed in the same change rather than one at a
time.

| # | Finding | Sev |
|---|---|---|
| P1-1 | The Slider role guard pins `_SliderDefaultsM3` while the app renders `_SliderDefaultsM3Year2023` | **P1** |
| P2-2 | One `disabledSurface` where M3 uses two opacities — disabled state collapses on slider, switch and checkbox | **P2** |
| P2-3 | A disabled ticked checkbox draws a 2 dp ring `_CheckboxDefaultsM3.side` makes transparent — and it is load-bearing because of P2-2 | **P2** |
| P2-4 | `RadioThemeData.fillColor` has no `pressed`/`hovered`/`focused` branch; canonical darkens to `onSurface`, and the checkbox beside it does | **P2** |
| P2-5 | `MxSwitchRow` renders its label at **14.0** in the tile variant and **16.0** in the announced one — one widget, two type rungs | **P2** |
| P2-6 | `MxSwitchRow.announced` sets `Semantics.value` on a node that already carries `isToggled`; `Switch` sets only `toggled` | **P2** |
| P2-7 | Radio has **zero** rows in `m3_role_bindings.dart` and **no group** in `m3_combined_state_test.dart`; `MxCheckboxRow` has no dedicated test | **P2** |
| P3-8 | `SliderThemeData.year2023` unset → 2024 colours on 2023 shapes | P3 |
| P3-9 | Slider `overlayColor` is a flat `Color`, so hover, focus and drag are one wash at 12 % | P3 |
| P3-10 | No `WidgetState.error` branch on checkbox, radio or switch; `_CheckboxDefaultsM3` has four | P3 |
| P3-11 | `checkColor` at rest is `onPrimary` where canonical is transparent | P3 |
| P3-12 | Three undocumented `SegmentedButton` deviations: `StadiumBorder`, `minimumSize`, disabled-selected fill | P3 |
| P3-13 | Switch disabled `trackOutlineColor` is 38 % ink where canonical is 12 % | P3 |
| P3-14 | One house overlay for all three toggles; M3 flips hue between selected and unselected | P3 |
| P3-15 | `app_planned_themes.dart` does not exist; five live references point at it, one of them the justification for `sliderTheme` | P3 |
| P3-16 | Widgetbook: stale doc comment, no Radio in the state matrix, no Slider / SegmentedButton page | P3 |

**Protected and deliberately left alone.** Under the rule that existing
canonical role guards stand unless pinned source proves them wrong, the
following were examined and confirmed correct — nothing below should be
"tidied" by the pass that acts on this report:

- the three `Switch` bindings and the one `Checkbox` binding in
  `m3_role_bindings.dart`;
- `m3_combined_state_test.dart`'s `Switch`, `SegmentedButton` and `Checkbox`
  groups, including `a ticked box draws no edge, focused or not`;
- `AppStroke.selectionControl = 2.0` — `_CheckboxDefaultsM3.side` and
  `_SwitchDefaultsM3.trackOutlineWidth` are both `2.0`, so the fourth stroke
  constant is right;
- the resting checkbox edge on `onSurfaceVariant` and the resting switch thumb
  on `outline` — both are the canonical roles and both clear their floors;
- `MxRadioRows`' transparent `Material` and per-tile lock;
- `MxSwitchRow`'s `ExcludeSemantics` on the visible label in the announced
  variant. P2-6 is about the *added* `value`, not about this.

---

## 2 · Inventory

### 2.1 Theme slots

| Slot | File | Builder | Rendered? |
|---|---|---|---|
| `checkboxTheme` | `lib/core/theme/components/selection/app_toggle_themes.dart` | `buildCheckboxTheme` | **yes** — 1 site |
| `switchTheme` | same file | `buildSwitchTheme` | **yes** — 3 sites |
| `radioTheme` | `lib/core/theme/components/selection/app_radio_theme.dart` | `buildRadioTheme` | **yes** — 4 sites |
| `segmentedButtonTheme` | `lib/core/theme/components/selection/app_segmented_button_theme.dart` | `buildSegmentedButtonTheme` | **no** |
| `sliderTheme` | `lib/core/theme/components/selection/app_slider_theme.dart` | `buildSliderTheme` | **no** |
| `listTileTheme` | `lib/core/theme/components/content/app_list_tile_theme.dart` | `buildListTileTheme` | yes — every row |

All six are wired in `app_theme.dart` (lines 261, 275–277, 291–292).

### 2.2 Shared components

| Widget | File | Material widget it owns | Callers |
|---|---|---|---|
| `MxCheckboxRow` | `lib/shared/widgets/mx_checkbox_row.dart` | `CheckboxListTile` | 1 |
| `MxRadioRows<T>` | `lib/shared/widgets/mx_radio_rows.dart` | `RadioGroup<T>` + `RadioListTile<T>` | 2 (→ 4 groups) |
| `MxSwitchRow` | `lib/shared/widgets/mx_switch_row.dart` | `SwitchListTile` / bare `Switch` | 3 |

### 2.3 Every render site under `lib/`

| Site | Control | Kind of choice |
|---|---|---|
| `card/…/overlays/card_tag_filter_sheet_widget.dart:156` | `MxCheckboxRow` | independent, multi-select (tags) |
| `deck/…/items/deck_scheduler_picker_widget.dart:72` | `MxRadioRows<SchedulerType>` | exclusive (UC-02, BR-11) |
| `settings/…/items/settings_choice_rows_widget.dart:73` | `MxRadioRows<T>` | exclusive — Appearance, Language |
| `settings/…/sections/settings_study_defaults_section_widget.dart:199` | `MxRadioRows<NewCardOrder>` | exclusive — new-card order |
| `reminder/…/items/reminder_toggle_row_widget.dart:45` | `MxSwitchRow` (announced) | immediate boolean setting (M6 R7) |
| `card/…/sections/card_import_preview_step_widget.dart:262` | `MxSwitchRow` (tile) | immediate boolean setting |
| `card/…/sections/card_import_preview_summary_widget.dart:119` | `MxSwitchRow` (tile) | immediate boolean setting |

**There is not one raw `Checkbox`, `CheckboxListTile`, `Radio`, `RadioListTile`,
`Switch`, `SwitchListTile`, `SegmentedButton`, `Slider` or `ToggleButtons` under
`lib/features/`.** Every selection surface goes through an `Mx` wrapper. That is
a stronger position than the input system was in at its audit, and it is the
reason this report has no "raw usage" registry to speak of (§7).

`SegmentedButton` and `Slider` render **nowhere** — not in `lib/`, not in
`widgetbook/`. Both slots sit on `theme_coverage_test.dart`'s
`allowedUnrendered` map as *planned* (lines 145–146). That is a made decision,
not an oversight, and it sets the severity ceiling for every slider and
segmented finding below: latent, not live.

---

## 3 · Canonical matrices — pinned source vs the app

Read from the pinned SDK. `_CheckboxDefaultsM3` is `checkbox.dart` §the class of
that name; `_RadioDefaultsM3` `radio.dart`; `_SwitchDefaultsM3` `switch.dart`;
`_SegmentedButtonDefaultsM3` `segmented_button.dart`; the two slider default
classes `slider.dart`.

Legend: **✓** app matches canonical · **≈** deviates within a decision the repo
has written down · **✗** deviates, undocumented or wrong.

### 3.1 Checkbox

| State | Slot | Flutter 3.44.8 | memox | |
|---|---|---|---|---|
| rest | `fill` | `transparent` | `transparent` | ✓ |
| rest | `side` | `onSurfaceVariant` / 2.0 | `onSurfaceVariant` / 2.0 | ✓ |
| rest | `check` | `transparent` | `onPrimary` | ✗ P3-11 |
| selected | `fill` | `primary` | `primary` | ✓ |
| selected | `side` | `transparent` / **0.0** | `BorderSide.none` (w 0.0) | ✓ |
| selected | `check` | `onPrimary` | `onPrimary` | ✓ |
| hovered | `side` | `onSurface` | `onSurface` | ✓ |
| pressed | `side` | `onSurface` | `onSurface` | ✓ |
| focused | `side` | `onSurface` | `onSurface` | ✓ |
| **sel + focused** | `side` | `transparent` / 0.0 | w 0.0 | ✓ |
| disabled | `fill` | `transparent` | `transparent` | ✓ |
| disabled | `side` | `onSurface@38` / 2.0 | `onDisabled` / 2.0 | ✓ |
| disabled | `check` | `transparent` | `onDisabled` | ≈ (no tick painted) |
| **sel + disabled** | `fill` | `onSurface@38` | `disabledSurface` | ✗ **P2-2** |
| **sel + disabled** | `side` | **`transparent`** / 2.0 | **`onDisabled`** / 2.0 | ✗ **P2-3** |
| **sel + disabled** | `check` | `surface` | `onDisabled` | ≈ (see P2-2) |
| error | `side` | `error` / 2.0 | `onSurfaceVariant` | ✗ P3-10 |
| sel + error | `fill` / `check` | `error` / `onError` | `primary` / `onPrimary` | ✗ P3-10 |

`_CheckboxDefaultsM3.side` resolution order is **disabled → selected → error →
pressed → hovered → focused → rest**. The app's order is **disabled → selected →
(pressed ∨ hovered ∨ focused) → rest**: identical apart from the missing `error`
rung, and the collapsed trio is correct because all three canonical branches
return the same `onSurface`.

The one ordering divergence is inside the disabled branch. Canonical splits it
by `selected`; the app does not, so `{selected, disabled}` falls through to the
same opaque `onDisabled` edge as `{disabled}`.

### 3.2 Radio

| State | Flutter 3.44.8 `fillColor` | memox | |
|---|---|---|---|
| rest | `onSurfaceVariant` | `onSurfaceVariant` | ✓ |
| selected | `primary` | `primary` | ✓ |
| **hovered** | **`onSurface`** | `onSurfaceVariant` | ✗ **P2-4** |
| **pressed** | **`onSurface`** | `onSurfaceVariant` | ✗ **P2-4** |
| **focused** | **`onSurface`** | `onSurfaceVariant` | ✗ **P2-4** |
| sel + hovered / pressed / focused | `primary` | `primary` | ✓ |
| disabled | `onSurface@38` | `onDisabled` | ✓ |
| sel + disabled | `onSurface@38` | `onDisabled` | ✓ |

`_RadioDefaultsM3` also declares `backgroundColor = transparent`; the app leaves
it unset, and `Radio` falls through to the default, so the resolved value is
identical.

### 3.3 Switch

| State | Slot | Flutter 3.44.8 | memox | |
|---|---|---|---|---|
| rest | thumb / track / edge | `outline` / `surfaceContainerHighest` / `outline` | same | ✓ |
| selected | thumb / track / edge | `onPrimary` / `primary` / `transparent` | same | ✓ |
| **hovered** | thumb | **`onSurfaceVariant`** | `outline` | ✗ (see note) |
| **pressed** | thumb | **`onSurfaceVariant`** | `outline` | ✗ (see note) |
| **focused** | thumb | **`onSurfaceVariant`** | `outline` | ✗ (see note) |
| **sel + hovered / pressed / focused** | thumb | **`primaryContainer`** | `onPrimary` | ✗ (see note) |
| sel + focused | edge | `transparent` | `transparent` | ✓ |
| disabled | thumb | `onSurface@38` | `onDisabled` | ✓ |
| **sel + disabled** | thumb | **`surface`** (opaque) | `onDisabled` | ✗ **P2-2** |
| disabled | track | `surfaceContainerHighest@12` | `disabledSurface` | ≈ |
| sel + disabled | track | `onSurface@12` | `disabledSurface` | ≈ |
| **disabled** | edge | **`onSurface@12`** | `onDisabled` (38 %) | ✗ P3-13 |
| sel + disabled | edge | `transparent` | `transparent` | ✓ |
| `trackOutlineWidth` | — | 2.0 | `AppStroke.selectionControl` = 2.0 | ✓ |

**Note on the interaction rungs.** M3 moves the thumb's *colour* under hover,
press and focus; the app moves only the overlay. This is the same trade the
checkbox made in the other direction, and it is not called out as its own
finding because the switch's canonical hover thumb (`onSurfaceVariant`) and its
resting thumb (`outline`) are near-neighbours — the cue M3 gets from that swap
is small, and the app's overlay wash is drawn at 6–12 % of `primary` around a
40 dp thumb, which is the louder of the two. The radio's case (P2-4) is
different and is a finding, because there the app's *only* glyph-level cue is
the one it dropped.

### 3.4 SegmentedButton — unrendered

| State | Slot | Flutter 3.44.8 | memox | |
|---|---|---|---|---|
| rest | `background` / `foreground` | `null` / `onSurface` | `transparent` / `onSurface` | ✓ |
| selected | `background` / `foreground` | `secondaryContainer` / `onSecondaryContainer` | same | ✓ |
| sel + focused | both | unchanged | unchanged | ✓ |
| rest / focused / hovered / pressed | `side` | `outline` | `outline` | ✓ |
| disabled | `foreground` | `onSurface@38` | `onDisabled` | ✓ |
| disabled | `side` | `onSurface@12` | `disabledSurface` | ≈ |
| **sel + disabled** | `background` | **`null`** | `disabledSurface` | ✗ P3-12 |
| — | `shape` | **`StadiumBorder()`** | `RoundedRectangleBorder(12)` | ✗ P3-12 |
| — | `minimumSize` | `Size.fromHeight(40.0)` | `Size.fromHeight(48.0)` | ✗ P3-12 (deliberate) |
| — | `textStyle` / `iconSize` / `elevation` | `labelLarge` / 18 / 0 | unset → default | ✓ |

The colour half of this theme is exactly canonical, which is what M100.22 fixed
and what `m3_role_bindings.dart` pins in three rows. The three deviations are
all *geometry or disabled*, none of them is wrong on its own, and none of them
is written down in a file whose doc comment is otherwise a careful argument for
canonical fidelity. See P3-12.

### 3.5 Slider — unrendered, and the class matters

`slider.dart:834`:

```dart
final bool year2023 = widget.year2023 ?? sliderTheme.year2023 ?? true;
final SliderThemeData defaults = switch (theme.useMaterial3) {
  true => year2023 ? _SliderDefaultsM3Year2023(context) : _SliderDefaultsM3(context),
```

Measured: `buildLightTheme().sliderTheme.year2023 == null`, and the app passes
no `year2023` at any call site (there is no call site). **So the defaults class
in force is `_SliderDefaultsM3Year2023`,** and every slot the theme leaves unset
resolves to a 2023 value.

| Slot | `_SliderDefaultsM3Year2023` (in force) | `_SliderDefaultsM3` (2024) | memox | |
|---|---|---|---|---|
| `activeTrackColor` | `primary` | `primary` | `primary` | ✓ |
| `inactiveTrackColor` | **`surfaceContainerHighest`** | `secondaryContainer` | `secondaryContainer` | ✗ P3-8 |
| `thumbColor` | `primary` | `primary` | `primary` | ✓ |
| `activeTickMarkColor` | `onPrimary@38` | `onPrimary` | `onPrimary` | ✗ P3-8 |
| `inactiveTickMarkColor` | `onSurfaceVariant@38` | `onSecondaryContainer` | `onSecondaryContainer` | ✗ P3-8 |
| `valueIndicatorColor` | **`primary`** | `inverseSurface` | `inverseSurface` | ✗ P3-8 |
| `valueIndicatorTextStyle` | `labelMedium` / `onPrimary` | `labelLarge` / `onInverseSurface` | `labelMedium` / `onInverseSurface` | ✗ (neither) |
| `valueIndicatorShape` | `DropSliderValueIndicatorShape` | `RoundedRectSliderValueIndicatorShape` | unset → **Drop** | — |
| `thumbShape` | `RoundSliderThumbShape` | `HandleThumbShape` | unset → **Round** | — |
| `trackShape` | `RoundedRectSliderTrackShape` | `GappedSliderTrackShape` | unset → **RoundedRect** | — |
| `trackHeight` | **4.0** | 16.0 | unset → **4.0** | — |
| `disabledActiveTrackColor` | `onSurface@38` | `onSurface@38` | `disabledSurface` | ✗ **P2-2** |
| `disabledInactiveTrackColor` | `onSurface@12` | `onSurface@12` | `disabledSurface` | ✗ **P2-2** |
| `disabledThumbColor` | `alphaBlend(onSurface@38, surface)` | `onSurface@38` | `disabledSurface` | ✗ **P2-2** |
| `overlayColor` | state-resolved 0.1 / 0.08 / 0.1 | same | **flat** `primary@12` | ✗ P3-9 |

**The theme transcribes the 2024 colour recipe onto the 2023 renderer.** That is
the whole of P3-8, and it is why `app_slider_theme.dart`'s claim that
`primary` on `secondaryContainer` is "M3's own pairing, in both halves" is true
of a slider this app does not build.

The contrast argument that file makes does not survive the correction, and it
survives it *in the app's favour*:

| pairing | light | dark |
|---|---|---|
| `primary` on `secondaryContainer` (current) | 4.58 : 1 | 7.24 : 1 |
| `primary` on `surfaceContainerHighest` (Year2023 canonical) | **4.91 : 1** | **7.31 : 1** |

Both clear the 3 : 1 a slider's value needs, and the canonical role is the
*better* of the two in both modes. So there is no contrast reason to keep the
substitution, in either direction — the choice is simply which slider is being
built, and that has to be decided before the first render.

---

## 4 · Each control family

### 4.1 Checkbox — the disabled ticked box

`_CheckboxPainter._drawBox` (`checkbox.dart`) fills the shape's outer path and
then paints the `BorderSide` **over** it:

```dart
canvas.drawPath(shape.getOuterPath(outer), paint);
if (side != null) { shape.copyWith(side: side).paint(canvas, outer); }
```

An opaque side therefore overpaints the outer 2 dp of the fill on all four
sides. `_kEdgeSize` is `Checkbox.width` = 18.0, so a ticked box with an opaque
2 dp side shows a **14 dp** core of fill inside a 2 dp ring, where a box with a
transparent side shows 18 dp of fill. That is precisely the regression
`app_toggle_themes.dart` records the owner finding on 2026-08-26 and M100.21
removing — **and it is still present in the disabled state**, because the
disabled branch is read before `selected` and does not split on it.

Measured, on `surfaceContainerLow` (the card these rows sit on):

| | light | dark |
|---|---|---|
| disabled ticked **fill** vs card | **1.24 : 1** | **1.29 : 1** |
| disabled ticked **ring** vs card | 2.14 : 1 | 2.65 : 1 |
| ring vs its own fill | 2.06 : 1 | 2.51 : 1 |
| *enabled* ticked fill vs card | 6.20 : 1 | 10.37 : 1 |

**The ring is load-bearing.** At 1.24 : 1 the disabled ticked box is very nearly
invisible against the card; the only thing that makes it findable is the 2 dp
edge M3 says should not be there. So P2-3 cannot be fixed on its own — removing
the ring to match `_CheckboxDefaultsM3.side` would leave the control at 1.24 : 1.

The cause is one slot up. M3's disabled-selected fill is `onSurface@38 %`; the
app's `disabledSurface` is the 12 %-derived solid (`AppStateOpacity
.disabledSurfaceBlend`), which is roughly a third of the ink. Substituting the
lighter fill is what created the need for the ring.

**The fix restores both canonical slots at once and improves the measurement:**
set `fillColor` for `{selected, disabled}` to `semantic.onDisabled` — a token
that already exists and is already the disabled tick and the disabled radio mark
— and return `BorderSide.none` for `selected` regardless of `disabled`. The fill
then reads 2.14 : 1 / 2.65 : 1 against the card (the ring's current number,
because it is the same ink), the 18 dp geometry comes back, and the app's own
`a disabled ticked box still looks ticked` test keeps passing because the tick
is `onDisabled` on `onDisabled`… which it would not. **That last point is the
one thing the implementer must check:** moving the fill to `onDisabled` requires
the `checkColor` for `{selected, disabled}` to move to the canonical `surface`,
or the tick disappears into its own box. `_CheckboxDefaultsM3.checkColor`
already says `surface` — the two changes are one canonical pair, and taking one
without the other is worse than taking neither.

### 4.2 Radio — the missing interaction rung

`_RadioDefaultsM3.fillColor` reads `selected` first, then — for the unselected
half — `disabled → pressed → hovered → focused → rest`, and the middle three all
return `onSurface` where rest returns `onSurfaceVariant`. `buildRadioTheme` has
three branches total: `disabled → selected → rest`. There is no interaction rung
at all.

`buildCheckboxTheme`, in the same directory, **does** have it, with a comment
explaining why:

> M3 darkens the outline under a pointer *and* under keyboard focus, to the same
> `onSurface` … the edge is most of what an 18 dp box has to change, and the
> overlay wash alone is 1.15:1.

Every word of that applies to a 20 dp radio ring. The two files were written at
different times and only one of them carries the answer.

**How much this costs today, measured honestly.** A radio in this app is always
inside a `RadioListTile`, and `ListTile` passes its `focusColor` to an `InkWell`
which falls back to `ThemeData.focusColor` — set in `app_theme.dart:200` to
`primary@10 %`. So a focused radio row does draw a full-row wash. The row is
320 × 56 dp, which is far more findable than a 20 dp glyph, and that is why this
is P2 and not P1. What is missing is the glyph-level cue M3 specifies, and the
consistency with the checkbox one file over.

### 4.3 Switch — disabled loses the boolean

Measured discriminability between a disabled-**on** and a disabled-**off**
switch, composited thumb over composited track:

| | app | canonical |
|---|---|---|
| light | **1.00 : 1** | 2.37 : 1 |
| dark | **1.00 : 1** | 3.73 : 1 |

Both disabled states resolve `thumb = onDisabled` and `track = disabledSurface`,
so the two are byte-identical. The stored value survives only as **thumb
position**, and the reminder toggle is disabled for the whole of every in-flight
command (BR-229) — which is exactly when a user is most likely to be checking
what it currently says.

`app_toggle_themes_test.dart`'s `disabled still shows what it is` group is the
test that exists for this class of bug, and it does not catch it: it measures
the thumb against **its own track** in each state separately, never the two
states against each other. That is the closure test P2-2 needs (§9).

Canonical's answer is a *different token per state* — `surface` when selected,
`onSurface@38` when not — which is the same two-opacity pattern as the checkbox.

Separately, the disabled track outline is `onDisabled` (38 %) where canonical is
`onSurface@12 %`: measured 1.73 : 1 (light) / 2.05 : 1 (dark) against its track,
versus 1.00 : 1 for canonical. The app's disabled edge is *louder* than M3's.
It still reads quieter than the enabled one (3.81 : 1 / 3.03 : 1), so the app's
own "reads as disabled rather than as available" bound holds. P3-13, documentation
only.

### 4.4 SegmentedButton — correct where it was audited, undocumented where it was not

The three colour bindings pinned at M100.22 are right and the combined-state
group covers `{selected, focused}`. Nothing in the colour half needs touching.

What is not written down anywhere is that the component's **shape** left
canonical: `_SegmentedButtonDefaultsM3.shape` is `StadiumBorder()` and the app
draws `RoundedRectangleBorder(AppRadius.md)`. For a segmented control the shape
is a large part of its identity — it is how a user tells a segmented control
from a row of outlined buttons — so this is a bigger departure than any of the
colour rows the same file argues about at length. The same is true of
`minimumSize` (48 vs canonical 40, which is *right* under the ≥ 48 mobile rule
and should be stated as a rule rather than left as a number) and of the disabled
selected background (`disabledSurface` vs canonical `null`, which is again an
improvement — M3 leaves a disabled selected segment identified only by its check
icon — and again unstated).

None of these is wrong. All three are decisions that a reader of
`app_segmented_button_theme.dart` cannot find, in a file whose whole doc comment
is about not letting a deviation go unrecorded.

### 4.5 Slider — see §3.5

The colour work is careful and the reasoning in `app_slider_theme.dart` is
sound; it is aimed at the wrong renderer. Three things follow:

1. **`year2023` must be an explicit decision, not an omission.** Either set
   `year2023: false` in `buildSliderTheme` and keep the 2024 colours (the file's
   current intent), or move the colours back to `_SliderDefaultsM3Year2023`.
   Leaving it unset ships a mix of both and is the only option that is
   indefensible.
2. **The disabled trio is P2-2's third instance** and is the worst of the three:
   at 1.00 : 1 across active track, inactive track *and* thumb, a disabled
   slider communicates no value whatsoever. Canonical measures 1.70 : 1 (light)
   / 2.09 : 1 (dark) between the two track halves — not generous, but not zero.
3. **`overlayColor` is a bare `Color`,** not a `WidgetStateProperty`. `Slider`
   resolves it with `WidgetStateProperty.resolveAs`, so a plain colour resolves
   to itself in every state: the halo is the same 12 % wash whether the thumb is
   hovered, focused or being dragged. Canonical distinguishes 0.08 / 0.10 / 0.10.
   The halo is not painted at rest (the overlay *radius* animates from zero), so
   this costs state feedback rather than showing a permanent ring.

### 4.6 Semantic taxonomy — verified against every render site

The audit's taxonomy holds at all seven sites, and this is the one section where
the answer is "nothing to do":

| Control | Meaning it must carry | Site | Correct? |
|---|---|---|---|
| checkbox | independent / multi | tag filter — many tags at once | ✓ |
| radio | exclusive | scheduler (BR-11), appearance, language, order | ✓ |
| switch | immediate boolean **setting** | reminder on/off (BR-229) | ✓ |
| switch | immediate boolean setting | import "has header row", "include duplicates" | ✓ — verified |
| segmented | bounded choice | — | no site |
| slider | continuous value | — | no site |

The two importer switches were the ones worth checking, because a toggle inside
a multi-step wizard is often a *form field* — for which M3 wants a checkbox, not
a switch. They are not: `_updateHeaderChoice` and `_updateDuplicateChoice` write
straight to their providers, the preview re-parses and re-renders on the same
frame, and the later Import button commits rows rather than the toggle. The
effect is immediate within the step, so the switch is right.

The comparison the brief asks for against the chip/pill audit: `MxPillButton`
over `ChoiceChip` carries **bounded choice** and, per that audit and per
`settings_choice_rows_widget.dart`'s own doc, cannot satisfy W6 today because
`buildChipTheme` sets `showCheckmark: false` — a selected pill differs from an
unselected one in fill and label colour and in nothing else. That is why three
exclusive settings groups render as radios rather than as pills. The reasoning
is recorded at the call site and is correct; nothing in A10 changes it, and the
pill's own gap stays with `app_chip_theme.dart`.

---

## 5 · Wrapper semantics

Measured from `SemanticsNode.getSemanticsData()` — the merged data, not the
node's own flags, because `MergeSemantics` in all three `*ListTile`s moves the
control's flags onto the tile's node.

| Wrapper | label | value | toggled | checked | exclusive | enabled | node rect |
|---|---|---|---|---|---|---|---|
| `MxSwitchRow` tile, on | "Has header row" | "" | `isTrue` | none | false | `isTrue` | 800 × 56 |
| `MxSwitchRow` tile, off | "Has header row" | "" | `isFalse` | none | false | `isTrue` | 800 × 56 |
| `MxSwitchRow` tile, locked | "Locked" | "" | `isTrue` | none | false | **`isFalse`** | 800 × 56 |
| `MxSwitchRow` announced | "Reminders" | **"On"** | `isTrue` | none | false | `isTrue` | **60 × 48** |
| `MxCheckboxRow` checked | "grammar\n12 cards" | "" | none | **`isTrue`** | false | `isTrue` | 800 × 72 |
| `MxCheckboxRow` unchecked | "grammar" | "" | none | `isFalse` | false | `isTrue` | 800 × 56 |
| `MxRadioRows` selected row | "choice 0" | "" | none | `isTrue` | **true** | `isTrue` | 800 × 56 |
| `MxRadioRows` other row | "choice 1" | "" | none | `isFalse` | true | `isTrue` | 800 × 56 |
| `MxRadioRows` locked | "choice 0" | "" | none | `isTrue` | true | **`isFalse`** | 800 × 56 |

**No duplicate node, no lost state, no missing action anywhere.** Each row is
exactly one merged node; the disabled variants report `isEnabled: isFalse` and
`actions: 0`; the radios carry `isInMutuallyExclusiveGroup`; the subtitle merges
into the label as it should. `ExcludeSemantics` on the announced variant's
visible `Text` does its job — the node is 60 × 48, not 800 wide, so the label is
spoken once and reached only through the control.

The one finding is **P2-6**, and it is narrow. `switch.dart:1074` is:

```dart
return Semantics(
  toggled: widget.value,
  child: GestureDetector(...
```

`Switch` sets **only** `toggled`. It does not set `value`, and no Material
selection control in 3.44.8 does. `MxSwitchRow`'s announced variant adds
`value: announcedValue` on top of that flag, so the merged node carries both a
toggled state and a value string that restates it. Android maps a toggled node
onto a control class whose checked state TalkBack announces on its own, and a
non-empty `value` is spoken in addition — the likely result is "Reminders, On,
on".

**This is reasoned from pinned source, not measured on a screen reader**, and it
contradicts an owner-reviewed decision (M6 R7, M6 A3), so it should be verified
on a device before it is changed. The rest of the pattern is right and must not
be touched: moving the label onto the control and excluding the visible text is
what stops WCAG 4.1.2 being violated, and that half is doing real work.

Note also that the tile variant of the same widget sets no `value` at all. So
the two variants expose different semantics contracts — which is defensible if
the announced one is right, and is a second reason to settle it.

---

## 6 · Geometry, hit targets, responsiveness and a11y

### 6.1 Visual control vs hit target

`kMinInteractiveDimension` is 48.0 (`constants.dart:27`); `kRadialReactionRadius`
is 20.0. `app_theme.dart:153` sets `materialTapTargetSize:
MaterialTapTargetSize.padded` globally, and line 152 `VisualDensity.standard`.

| Control | Drawn | Laid out | Actual target | ≥ 48? |
|---|---|---|---|---|
| bare `Checkbox` | 18 dp box | 48 × 48 | 48 × 48 | ✓ |
| `Checkbox` in `CheckboxListTile` | 18 dp box | 40 × 40 (forced `shrinkWrap`) | **the tile** | ✓ |
| `Radio` in `RadioListTile` | 20 dp ring | 40 × 40 (forced `shrinkWrap`) | **the tile** | ✓ |
| `Switch` in `SwitchListTile` | 52 × 32 track | 60 × 40 (forced `shrinkWrap`) | **the tile** | ✓ |
| bare `Switch` (announced row) | 52 × 32 track | **60 × 48** | 60 × 48 | ✓ |
| `SegmentedButton` segment | — | `minimumSize` 48 h | 48 h | ✓ |

All three `*ListTile` wrappers pass `MaterialTapTargetSize.shrinkWrap` to the
inner control by design (`checkbox_list_tile.dart:~500`,
`radio_list_tile.dart:672`, `switch_list_tile.dart:586`) and wrap the row in
`ExcludeFocus`, so the tile owns both the target and the focus node. The M3
`ListTile` floor is 56 / 72 / 88 dp for one, two and three lines
(`list_tile.dart:745`). **Nothing in this family is under 48 dp.**

The announced switch row is the one to keep an eye on: it is 48 dp exactly, the
floor rather than a margin, and only 60 dp of a 320 dp row is tappable because
the label is deliberately inert. Both are documented decisions; neither is a
violation.

### 6.2 Label / control geometry

`contentPadding: EdgeInsets.zero` in all three wrappers, so the surrounding card
or sheet owns the gutter — consistent, and `MxRadioRows` exposes
`contentPadding` for the one caller (`settings_choice_section_widget.dart`) that
needs the ink to span a card padded vertically only.

The affinities are right: checkbox **leading** (a pick-many list is scanned down
the marks), radio leading (`RadioListTile` default), switch **trailing**
(`SwitchListTile` default — the setting is read first, its state last).

**P2-5 is here.** Measured effective `fontSize` of the label:

| Row | declared | effective |
|---|---|---|
| `MxSwitchRow` **tile** | 14.0 | **14.0** |
| `MxSwitchRow` **announced** | 16.0 | **16.0** |
| `MxCheckboxRow` | — | 16.0 |
| `MxRadioRows` | — | 16.0 |
| plain `ListTile` | — | 16.0 |

`mx_switch_row.dart:58` hardcodes `style: context.texts.bodyMedium` on the tile
variant's title. Nothing else in the selection family does, and
`_LisTileDefaultsM3.titleTextStyle` is `bodyLarge`. So the two importer rows
render their labels one type rung below the tag-filter rows and the settings
rows, and the same widget renders at two sizes depending on whether
`announcedValue` was passed — a variant flag that is supposed to be a *semantics*
decision silently moves the typography too.

### 6.3 320 / 360 / 375 / 393 dp × textScaler 1.0 / 1.3 / 2.0 × EN / VI

96 combinations pumped. Row heights, EN label `"Enable reminders"`, VI label
`"Bật nhắc nhở học tập hằng ngày"`:

| Row | 320 × 1.0 | 320 × 1.3 | 320 × 2.0 | 393 × 2.0 |
|---|---|---|---|---|
| switch tile EN | 56.0 | 56.0 | 57.0 | 57.0 |
| switch tile VI | 56.0 | 68.0 | 98.0 | 98.0 |
| switch announced EN | 48.0 | 48.0 | 96.0 | 48.0 |
| switch announced VI | 48.0 | 62.0 | 144.0 | 96.0 |
| checkbox (2-line) EN | 72.0 | 73.0 | 153.0 | 105.0 |
| checkbox (2-line) VI | 72.0 | 104.0 | 201.0 | 153.0 |

And the radio tile, with the real VI settings label
`"Theo hệ thống mặc định của máy"` at 320 dp: 64.0 (×1.0) → 78.0 (×1.3) →
160.0 (×2.0), radio glyph 40 × 40 throughout.

**No clipping, no overflow, no sub-48 row, in any of the 96.** Every row grows
by wrapping its label; the control keeps its size and the tile keeps its floor.
The VI labels are the ones that wrap first, which is the expected direction —
`settings_choice_rows_widget.dart` already argues from exactly that case
("`Theo hệ thống` at `textScaler` 2.0 on a 320 dp screen") for choosing radios
over a segmented control, and the measurement supports the argument: 160 dp of
wrapped label is fine in a row and would be a truncation inside a segment.

---

## 7 · API surface and escape hatches

| Widget | Visual escape hatches | Verdict |
|---|---|---|
| `MxCheckboxRow` | **none** — `label`, `subtitle`, `isChecked`, `onToggle` | clean |
| `MxSwitchRow` | **none** — but hardcodes `bodyMedium` internally (P2-5) | clean API, wrong internal |
| `MxRadioRows<T>` | `contentPadding` (`EdgeInsetsGeometry`), `shape` (enum) | acceptable |

`MxRadioRows.contentPadding` is the only raw geometry type on the family's API.
It is used by exactly one caller and always with token values, and the
alternative — a second enum rung — was considered and rejected in
`settings_choice_rows_widget.dart`'s doc. It is not a finding; it is noted
because it is the one place a literal `EdgeInsets` could enter without a guard
objecting.

No `Color`, no `BorderSide`, no `WidgetStateProperty`, no `ShapeBorder` and no
`InputDecoration` is exposed by any of the three. Colours come entirely from the
theme, which is the property the input audit found `MxSearchField` had lost.

**Raw usage registry: empty.** §2.3 already states it — there is no raw
selection control anywhere under `lib/features/`. The Widgetbook builds raw
`Switch` and `Checkbox` in `_ToggleRow`, which is correct: that page exists to
show the *theme*, and going through a wrapper would hide it.

---

## 8 · Coverage gaps

### 8.1 Role guards

`m3_role_bindings.dart` holds **24 rows across 11 components**:

| Component | rows |
|---|---|
| NavigationBar | 4 |
| ChoiceChip · SegmentedButton · Switch | 3 each |
| AppBar · FloatingActionButton · OutlinedButton · TabBar | 2 each |
| Card · Checkbox · TextButton | 1 each |
| **Radio** | **0** |
| **Slider** | **0** |

The single `Checkbox` row pins `side` only — `fillColor` and `checkColor` are
unpinned in the source guard (they are pinned by the runtime contract, which is
a weaker check: it compares resolved colours, so a token that happens to equal
`primary` passes, which is the exact hole M100.27's `primaryInk` note describes).

`m3_combined_state_test.dart` (317 lines) has groups for ChoiceChip, Switch,
SegmentedButton, Checkbox, OutlinedButton, NavigationBar and a shared
`disabled does not leak a live role`. **There is no Radio group** — and P2-4 is
precisely a combination bug in an ordered resolver, which is the class of defect
that file's own header says it exists to catch.

The file also declares `disabled` and `disabledSelected` at lines 35–38 and uses
them in **one** test at line 291, which checks only that a disabled control is
not an enabled accent. No group asserts a disabled *pair* — which is why P2-2
and P2-3 are invisible to it.

`m3_role_contract_test.dart` has `Radio` (2 pins) and `Slider` (6 pins). The
Radio pins cover `{}` and `{selected}` — the two states P2-4 is not in. The
Slider pins are **P1-1**: they assert `inactiveTrackColor == secondaryContainer`,
`activeTickMarkColor == onPrimary`, `inactiveTickMarkColor ==
onSecondaryContainer` and `valueIndicatorColor == inverseSurface`, all four of
which are `_SliderDefaultsM3` values, against a widget that resolves
`_SliderDefaultsM3Year2023`. The guard is green and is asserting the wrong
contract.

### 8.2 Component tests

| File | Covers |
|---|---|
| `app_toggle_themes_test.dart` | switch + checkbox pairs, incl. a disabled group |
| `mx_switch_row_test.dart` | both variants' semantics and targets |
| `mx_radio_rows_test.dart` | transparent `Material`, pick, lock |
| **missing** | **`mx_checkbox_row_test.dart`** |
| `mx_stress_selection_specimens.dart` | all three rows under long content |
| **missing** | any radio theme test — `app_radio_theme.dart` has no `_test` file |

`MxCheckboxRow` is the only one of the three shared rows with no dedicated test,
and it is the one whose control has the most divergent disabled matrix.

### 8.3 Widgetbook

`form_components.dart` has `selectionRowsComponent()` (MxSwitchRow with an
`announced` knob, MxCheckboxRow, MxRadioRows with an `enabled` knob, MxDropdown)
and `toggleComponent()` → `_ToggleMatrix`, which draws raw `Switch` and
`Checkbox` on/off × enabled/disabled.

Three gaps:

- **No `Radio` in the state matrix.** The one control whose interaction states
  are missing from the theme (P2-4) is the one control the matrix does not show.
- **No `Slider` and no `SegmentedButton` page at all**, so P3-8's shape/colour
  hybrid has no surface where a person could see it.
- `toggleComponent()`'s doc comment says *"There is no shared component here to
  catalogue — the reminder screen and the tag filter sheet build Material's own
  widgets"*. Both statements are stale: `MxSwitchRow` and `MxCheckboxRow` exist,
  both are catalogued fifty lines above, and neither screen builds a raw widget
  any more.

### 8.4 Goldens

152 PNGs in `test/demo/goldens`. The rendered controls appear in
`reminder_settings_{light,dark}`, `settings_{light,dark}`,
`settings_save_failed_{light,dark}` and `tag_filter_sheet_{light,dark}` — so
enabled checkbox, switch and radio rows are all pixel-covered in both modes.

Not covered by any golden: **a disabled ticked checkbox, a disabled switch in
either position, and a disabled radio group.** `settings_save_failed` is the
closest — it is the screen state where `isSubmitting` locks the radio rows —
which means P2-2's radio half would be visible there if it existed, and its
switch and checkbox halves have no picture anywhere.

---

## 9 · Severity registry, with closure tests

Closure tests are given for every P0/P1/P2, as the brief requires. Each is
written to fail on the current tree.

### P1-1 · The Slider role guard pins the wrong defaults class

- **Evidence.** `slider.dart:834-836`; measured
  `buildLightTheme().sliderTheme.year2023 == null`; four of the six pins in
  `m3_role_contract_test.dart`'s `Slider` block name `_SliderDefaultsM3` values.
- **Impact.** Latent but active: the guard reports canonical compliance for a
  class the app does not instantiate. The first `Slider` ships off-canonical
  with a green suite.
- **Closure test.** In `m3_role_contract_test.dart`, assert the defaults class
  before asserting its roles:
  ```dart
  test('the Slider pins match the defaults class actually in force', () {
    // slider.dart:834 — year2023 defaults to TRUE when the theme leaves it null.
    final bool inForce = theme.sliderTheme.year2023 ?? true;
    expect(inForce, isFalse,
      reason: 'these pins are _SliderDefaultsM3 (2024) values; with year2023 '
              'unset the widget resolves _SliderDefaultsM3Year2023');
  });
  ```
  Green only once `buildSliderTheme` states `year2023: false` — or once the pins
  are moved to the Year2023 roles and this test is inverted.

### P2-2 · One `disabledSurface` where M3 uses two opacities

- **Evidence.** Measured: slider disabled active/inactive/thumb all
  `disabledSurface` → **1.00 : 1**; switch disabled-on vs disabled-off thumb
  **1.00 : 1** (canonical 2.37 / 3.73); checkbox disabled ticked fill vs card
  **1.24 : 1** / **1.29 : 1** (canonical ink measures 2.14 / 2.65). Canonical
  slots: `_CheckboxDefaultsM3.fillColor` `onSurface@38`; `_SwitchDefaultsM3
  .thumbColor` `surface` when `{disabled, selected}`; `_SliderDefaultsM3Year2023`
  `onSurface@38` / `onSurface@12` / `alphaBlend(onSurface@38, surface)`.
- **Closure test** (add to `app_toggle_themes_test.dart`'s
  `disabled still shows what it is` group — the group that should have caught it):
  ```dart
  test('a disabled switch tells on from off', () {
    for (final entry in themes.entries) {
      final t = entry.value;
      const off = <WidgetState>{WidgetState.disabled};
      const on  = <WidgetState>{WidgetState.disabled, WidgetState.selected};
      final knobOff = Color.alphaBlend(thumb(t, off), track(t, off));
      final knobOn  = Color.alphaBlend(thumb(t, on),  track(t, on));
      expect(contrast(knobOff, knobOn), greaterThan(1.5),
        reason: '${entry.key}: a disabled switch looks the same on and off');
    }
  });
  ```
  Plus, for the slider, in whichever file owns it once it is rendered:
  ```dart
  expect(contrast(sliderTheme.disabledActiveTrackColor!,
                  sliderTheme.disabledInactiveTrackColor!),
         greaterThan(1.5),
         reason: 'a disabled slider shows no value');
  ```

### P2-3 · A disabled ticked checkbox draws a ring M3 makes transparent

- **Evidence.** `_CheckboxDefaultsM3.side` returns `BorderSide(width: 2.0, color:
  Colors.transparent)` for `{disabled, selected}`; measured app value
  `#61223354` / `#61CBCCD2` at width 2.0. `_CheckboxPainter._drawBox` paints the
  side over the fill, so 18 dp of fill becomes a 14 dp core inside a 2 dp ring —
  the same geometry M100.21 removed from the enabled state.
- **Must ship with P2-2.** The ring currently carries the control (fill is
  1.24 : 1 against the card). Fix order inside the change: `fillColor{selected,
  disabled}` → `semantic.onDisabled`, `checkColor{selected, disabled}` →
  `scheme.surface` (canonical), then `side` → `BorderSide.none` whenever
  `selected`.
- **Closure test** (extend the existing `a ticked box draws no edge, focused or
  not` in `m3_combined_state_test.dart` to the state it omits):
  ```dart
  for (final state in <Set<WidgetState>>[selected, selectedFocused, disabledSelected]) {
    expect(side(state)!.width, 0,
      reason: '$mode: a ticked box grew an edge under ${_name(state)}');
  }
  ```

### P2-4 · Radio has no interaction rung

- **Evidence.** `_RadioDefaultsM3.fillColor` returns `onSurface` for unselected
  `pressed`/`hovered`/`focused`; measured app value `onSurfaceVariant` in all
  three. `buildCheckboxTheme` has the branch and the argument for it.
- **Closure test** — a new `Radio` group in `m3_combined_state_test.dart`,
  mirroring the Checkbox one:
  ```dart
  group('$mode · Radio', () {
    Color? fill(Set<WidgetState> s) => theme.radioTheme.fillColor!.resolve(s);
    test('an unpicked radio darkens to onSurface under focus, as under hover', () {
      holds('fill', fill, <Set<WidgetState>>[focused, hovered, pressed], scheme.onSurface);
      holds('fill', fill, <Set<WidgetState>>[resting], scheme.onSurfaceVariant);
    });
    test('a picked radio keeps primary in every combination', () {
      holds('fill', fill, <Set<WidgetState>>[selected, selectedFocused], scheme.primary);
    });
  });
  ```
  Plus a `RoleBinding` row for `Radio` / `fillColor` requiring
  `['onSurfaceVariant', 'onSurface', 'primary']` and refusing `['outline']`.

### P2-5 · `MxSwitchRow` has two type rungs

- **Evidence.** Measured effective `fontSize` 14.0 (tile) vs 16.0 (announced) vs
  16.0 for `MxCheckboxRow`, `MxRadioRows` and a plain `ListTile`. Source:
  `mx_switch_row.dart:58`.
- **Closure test** (`test/shared/widgets/mx_switch_row_test.dart`):
  ```dart
  testWidgets('both variants title at the ListTile rung', (tester) async {
    for (final announced in <String?>[null, 'On']) {
      await tester.pumpWidget(host(MxSwitchRow(
        label: 'Label', isOn: true, announcedValue: announced, onChanged: (_) {})));
      final style = tester.widget<RichText>(find.descendant(
        of: find.text('Label'), matching: find.byType(RichText))).text.style!;
      expect(style.fontSize, buildLightTheme().textTheme.bodyLarge!.fontSize,
        reason: 'announced=$announced renders its label off the ListTile rung');
    }
  });
  ```

### P2-6 · `Semantics.value` on top of `isToggled`

- **Evidence.** `switch.dart:1074-1075` sets `toggled` and nothing else;
  measured merged node for the announced variant carries `value: "On"` **and**
  `isToggled: Tristate.isTrue`. The tile variant carries the flag alone.
- **Reasoned, not measured on a screen reader.** Verify before changing.
- **Closure test** — device first, then, if confirmed, in
  `mx_switch_row_test.dart`:
  ```dart
  testWidgets('the announced switch states its value once', (tester) async {
    // ... pump announced variant ...
    final d = tester.getSemantics(find.byType(Switch)).getSemanticsData();
    expect(d.flagsCollection.isToggled, Tristate.isTrue);
    expect(d.value, isEmpty,
      reason: 'the toggled flag already speaks the value; a value string '
              'restates it — Switch itself sets only `toggled`');
  });
  ```
  This test **contradicts the current one** (`expect(node.value, 'On')`), which
  is the point: one of the two has to be deleted, and the owner decides which.

### P2-7 · Guard and test coverage holes

- **Evidence.** §8.1–8.2. Radio: 0 role bindings, 0 combined-state group.
  Slider: 0 role bindings. `MxCheckboxRow`: no test file.
- **Closure test.** The Radio group and binding above, plus a
  `mx_checkbox_row_test.dart` asserting the merged `checked` state in both
  positions, the whole-row target, and that `onToggle: null` yields
  `actions == 0`.

### P3 items

| # | Evidence | Note |
|---|---|---|
| P3-8 | `slider.dart:834`; §3.5 table | resolved by the same edit as P1-1 |
| P3-9 | `sliderTheme.overlayColor` is a `Color`, not a `WidgetStateProperty`; canonical resolves 0.1 / 0.08 / 0.1 | |
| P3-10 | `_CheckboxDefaultsM3` has `error` branches in `side`, `fillColor`, `checkColor`, `overlayColor`; the app has none | no caller passes `isError` today |
| P3-11 | measured `checkColor(rest) == onPrimary`; canonical `transparent` | no tick is painted when unselected — cosmetic in the theme, not on screen |
| P3-12 | `StadiumBorder` vs `RoundedRectangleBorder(12)`; 40 vs 48; `null` vs `disabledSurface` | document, do not necessarily change |
| P3-13 | measured 1.73 / 2.05 vs canonical 1.00 | app is louder than M3; still quieter than enabled |
| P3-14 | measured app overlay `primary@6/12/10` in every state vs M3's selected/unselected hue flip | pinned by `both resolve the house control wash`; app-wide, out of A10 scope |
| P3-15 | `lib/**/app_planned_themes.dart` does not exist; referenced by `app_theme.dart:288`, `app_sizing.dart:9,40`, `theme_coverage_test.dart:143`, `docs/design-system/theme-architecture.md:181`, and `app_planned_themes_test.dart` still exists | the justification for `sliderTheme` on the unrendered allowlist points at a missing file |
| P3-16 | `form_components.dart:572-578` doc; no Radio in `_ToggleRow`; no Slider/Segmented page | |

---

## 10 · Implementation order, files, and the decisions the owner owns

Four changes, smallest blast radius first. **They are ordered by dependency, not
by severity** — P2-2 and P2-3 are one edit, and P1-1 is a decision before it is
a diff.

### Step 1 — decide the slider, then fix its guard (P1-1, P3-8, P3-9)

**Owner decision required, and it is the only one in this report that cannot be
made from the source:** is memox's slider the 2023 one or the 2024 one? The
2024 slider is a 16 dp gapped track with a handle thumb — a visibly different
component, not a repaint. Nothing renders one today, so the cost of either
answer is zero now and non-zero after the first screen.

- Recommended: **`year2023: false`**, which keeps every colour decision
  `app_slider_theme.dart` already argues for and makes the existing role pins
  correct as written.
- Files: `lib/core/theme/components/selection/app_slider_theme.dart` (add
  `year2023: false`; make `overlayColor` a `WidgetStateProperty` resolving
  dragged/hovered/focused; move `valueIndicatorTextStyle` to `labelLarge` to
  match `_SliderDefaultsM3`), `test/core/theme/contracts/m3_role_contract_test.dart`
  (add the defaults-class assertion above).

### Step 2 — the disabled family (P2-2, P2-3)

One change, three controls, because it is one substitution.

- `app_toggle_themes.dart` — `buildCheckboxTheme`: split the disabled branch on
  `selected` (`fill` → `onDisabled`, `check` → `scheme.surface`), and return
  `BorderSide.none` for `selected` before the disabled branch. `buildSwitchTheme`:
  split the disabled thumb on `selected` (canonical `scheme.surface` when on).
- `app_slider_theme.dart` — `disabledActive` → `onDisabled`,
  `disabledInactive` → a 12 %-derived value, `disabledThumb` → `onDisabled`.
- Tests: the two closure tests in §9, added to the groups that already exist for
  this class of bug.
- **Watch:** `app_toggle_themes_test.dart`'s `a disabled ticked box still looks
  ticked` must keep passing — it will only do so if the `checkColor` half of the
  pair moves with the `fillColor` half.
- Goldens: `settings_save_failed_{light,dark}` and `tag_filter_sheet_*` may move.
  Regenerate with `TZ=UTC flutter test --tags golden --update-goldens` on Linux
  and republish the gallery at the existing URL, per `CLAUDE.md`.

### Step 3 — the radio's missing rung and its guards (P2-4, P2-7)

- `app_radio_theme.dart` — add the `pressed ∨ hovered ∨ focused → onSurface`
  branch between `selected` and `rest`, with the comment `buildCheckboxTheme`
  already carries.
- `m3_role_bindings.dart` — one `Radio` / `fillColor` row.
- `m3_combined_state_test.dart` — the `Radio` group from §9.
- New: `test/shared/widgets/mx_checkbox_row_test.dart`.
- Widgetbook: add `Radio` to `_ToggleRow` so the change has a picture.

### Step 4 — wrapper and documentation cleanup (P2-5, P2-6, P3-12, P3-15, P3-16)

- `mx_switch_row.dart` — drop the hardcoded `bodyMedium` (P2-5). This is a
  visible change to the two importer rows; it is also the change that makes the
  widget's two variants agree.
- **Owner decision required (P2-6):** verify the announced row on TalkBack. If
  the value duplicates the toggled state, drop `value:` and delete the assertion
  in `mx_switch_row_test.dart` that pins it. If it does not, record the device
  result beside the `announcedValue` doc so the next audit does not re-open it.
- `app_segmented_button_theme.dart` — document the three deviations (P3-12). No
  code change proposed: the shape is a brand decision, the 48 dp floor is the
  mobile rule, and the disabled-selected fill is an improvement over canonical.
  All three need to be *stated*.
- P3-15 — either restore `app_planned_themes.dart` or repoint the five
  references, so that `theme_coverage_test.dart`'s allowlist reason resolves.
  Owner decision: the file was emptied at M100.31 and its remaining test still
  exists, so the intent is unclear from the tree.
- P3-16 — fix `toggleComponent()`'s stale doc comment.

### Explicitly not proposed

- **Any change to the overlay wash (P3-14).** It is app-wide, transcribed from
  `mx.css`, and pinned by a test whose whole purpose is to stop it drifting back
  to Material's. Changing it here would be a selection-controls change to a
  system-wide decision.
- **Any change to the resting checkbox edge, the resting switch thumb, or the
  four `Switch`/`Checkbox` role bindings.** All measured canonical; all protected.
- **A `SegmentedButton` or `Slider` render site.** Both are on the planned list
  on purpose.

---

## 11 · Reproducing this report

```bash
# pinned SDK
git clone --depth 1 --branch 3.44.8 https://github.com/flutter/flutter.git
#   framework 058e0af2c2 — matches .fvmrc

flutter pub get
dart run build_runner build --delete-conflicting-outputs

# the measurements: resolve every WidgetStateProperty across the ten state
# combinations, pump the three Mx rows at 320/360/375/393 dp x 1.0/1.3/2.0 in
# EN and VI, read merged SemanticsData and effective TextStyles off the tree.
```

The harness was deliberately not committed — it prints, it does not assert, and
a printing test in the suite is a test that can never fail. Everything it proved
is either quoted above with its number or restated in §9 as a closure test that
*does* assert.
