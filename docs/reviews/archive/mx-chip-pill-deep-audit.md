# Chip / Pill / Filter / selection-control deep audit

| | |
|---|---|
| **Status** | **IMPLEMENTED — superseded by M100.36** (Phase 5, commit `refactor(chip)`). Measurements below are history; every P1/P2 disposition is in `docs/wbs.md` M100.36. Current contract: `docs/design-system/tokyo-component-mapping.md` §2 selection/, §4 #4 and §5 |
| **Purpose** | Prepare the future implementation pass for the Chip/Pill/filter/selection-control stack: what exists, what Flutter 3.44.8 actually contracts, where the two disagree, and what an owner still has to decide |
| **Scope** | `lib/core/theme/components/selection/app_chip_theme.dart`, `lib/shared/widgets/mx_pill_button.dart`, `lib/shared/widgets/mx_focus_ring.dart`, every chip-like control in `lib/features/**`, and the tests / Widgetbook / goldens that cover them. **Out of scope:** ColorScheme role values (AD-14 owns those), the button family, TextField, ListTile, Card — all four are being changed in parallel worktrees |
| **Source of truth for** | Nothing yet. This is a discovery report; every finding must land in `docs/wbs.md` and the relevant component doc before it becomes a rule |
| **Depends on** | `document-conventions.md` · `architecture.md` (AD-14, AD-15) · `design-system/tokyo-component-mapping.md` · `design-system/theme-architecture.md` |
| **Updated by task** | — (audit only, no implementation) |
| **Last updated** | 2026-09-03 |

---

## Provenance

| | |
|---|---|
| Base commit | `4cfddd3d` (`main` at time of audit) |
| Flutter | 3.44.8 stable, framework `058e0af2c2`, Dart 3.12.2 — the pinned SDK at `D:/Setup/flutter` |
| Material source read | `choice_chip.dart`, `filter_chip.dart`, `action_chip.dart`, `input_chip.dart`, `chip.dart`, `chip_theme.dart`, `ink_well.dart`, `theme_data.dart` |
| Method | Every colour, size and state value below was **measured** by rendering the real widget under the real `buildLightTheme()` / `buildDarkTheme()` in throwaway `flutter test` probes, then reconciled against quoted SDK source. Probe files were deleted; nothing under `lib/`, `test/`, `widgetbook/` or `design_system/` was modified |
| Not verified | Android runtime rendering. No device profile was taken — see §24 |

**Nothing in this document is a change.** No production file, test, story or golden
was touched. The single file this branch adds is this one.

---

## 1. Executive verdict

The pill system is **structurally sound and factually mis-documented**. Three
separate design notes — `app_chip_theme.dart:47-54`, `mx_pill_button.dart:91-99`
and `docs/design-system/tokyo-component-mapping.md` §4 binding #4 — all assert
that `MxPillButton` builds `ChoiceChip.elevated` *in order to take
`surfaceContainerLow` from the canonical role instead of substituting a fill on a
flat chip*. **That is not what happens.** `ChipThemeData.color` short-circuits
`chipDefaults.color` entirely (`chip.dart:1529-1531`), so `_ChoiceChipDefaultsM3`
is never consulted for fill. Flat and elevated paint identically under this theme.
The variant's only surviving effect is the one the note says it was avoiding: it
swaps `shadowColor` from `Colors.transparent` to `colorScheme.shadow`, and
because `chipTheme` zeroes `elevation` but leaves `pressElevation` null, **every
unselected pill now casts a real Material elevation-1 drop shadow while pressed**
(measured: `Material.elevation` 0.0 → 1.0, `shadowColor` `#FF9FA2BF`). AD-14
admits one depth mechanism and it is `shadowsFor`; this is a second one, arrived
at by a rationale that does not hold.

Two other findings are larger than their component:

- **The focus ring does not fit the pill it marks.** `MxFocusRing` decorates the
  box it wraps, and the box it wraps is `RawChip`'s 48×48 tap-target box, not the
  34-tall painted pill. Measured on a one-character pill: ring `48.0 × 48.0`,
  painted pill `33.4 × 34.0` — the ring floats 7.3dp clear on each side and 7.0dp
  clear above and below, at a different corner curvature.
- **Selection rests on colour alone, and the project already knows.** With
  `showCheckmark: false` and `side` going transparent when selected, the entire
  non-text difference between a selected and an unselected pill is a fill delta of
  **1.35:1 in light, 1.43:1 in dark**. `docs/wbs.md:10121-10126` records this as a
  P1 against wireframe rule W6 — and closed it by moving *one screen* to radio
  rows. Four pill groups still ship the defect.

Against that, three things are genuinely right and should survive any rewrite:
the state-aware `ChipThemeData.color` ownership (§12), the focus ring's *colour*
architecture (§10 — it clears 3:1 on every ground, measured), and the
`showCheckmark: false` layout argument (§11 — the tick costs a measured 20.0dp of
reflow per toggle).

Severity roll-up: **0 × P0, 5 × P1, 7 × P2, 6 × P3.**

---

## 2. Semantic taxonomy

Classified from what the user is doing, not from what the control looks like.

| Class | Definition | Persistent? | Exclusive? | Immediate action? |
|---|---|---|---|---|
| **A** single-choice selection | one of N views of the same content | yes | yes | no |
| **B** multi-select filter | independent on/off predicates | yes | no | no |
| **C** action | a command; no resting state | no | n/a | yes |
| **D** dismissible / input token | a datum the user added and can remove | yes (it *is* data) | n/a | removal is immediate |
| **E** status / badge | pure readout | n/a | n/a | no |
| **F** navigation-like pill | moves the user somewhere | no | n/a | yes |
| **G** compact inline action | C, but repeated inside a row | no | n/a | yes |

Production population: **A** ×5 groups, **B** ×0 rendered as chips, **C/F hybrid**
×1, **D** ×1, **E** ×9, **F** ×0, **G** ×1.

The important shape of that distribution: MemoX has **no multi-select chip UI at
all** — its only multi-select surface (`card_tag_filter_sheet_widget.dart:129`)
uses `MxCheckboxRow`. So `FilterChip` semantics are not currently needed, which
changes the answer to §18 from "migrate" to "do not adopt yet".

---

## 3. Flutter 3.44.8 chip-family contract matrix

Read from the pinned SDK. Flat and elevated are kept apart, as required.

### 3.1 Fill (`color` WidgetStateProperty)

| state | ChoiceChip flat | ChoiceChip elevated | FilterChip flat | FilterChip elevated | ActionChip flat | ActionChip elevated | InputChip |
|---|---|---|---|---|---|---|---|
| disabled + selected | `onSurface@12%` | `onSurface@12%` | `onSurface@12%` | `onSurface@12%` | *(no branch)* | `onSurface@12%` | `onSurface@12%` |
| disabled | **`null`** | `onSurface@12%` | **`null`** | `onSurface@12%` | **`null`** | `onSurface@12%` | **`null`** |
| selected | `secondaryContainer` | `secondaryContainer` | `secondaryContainer` | `secondaryContainer` | **no selected branch** | **no selected branch** | `secondaryContainer` |
| unselected (default) | **`null`** | **`surfaceContainerLow`** | **`null`** | **`surfaceContainerLow`** | **`null`** | `surfaceContainerLow` | **`null`** |

Sources: `choice_chip.dart:307-328`, `filter_chip.dart:340-361`,
`action_chip.dart:295-306`, `input_chip.dart:298-311`.

`null` means *nothing is painted* — `Ink`'s `ShapeDecoration.color` is null
(`chip.dart:1432-1436`) and the ancestor Material shows through.

**PR #429's premise is confirmed exactly:** flat unselected → `null`, elevated
unselected → `surfaceContainerLow`, selected → `secondaryContainer` for both.

### 3.2 Everything else

| property | ChoiceChip flat | ChoiceChip elevated | FilterChip flat | FilterChip elev. | ActionChip | InputChip |
|---|---|---|---|---|---|---|
| label colour, enabled selected | `onSecondaryContainer` | same | `onSecondaryContainer` | same | *n/a* | `onSecondaryContainer` |
| label colour, enabled unselected | `onSurfaceVariant` | same | `onSurfaceVariant` | same | **`onSurface`** | `onSurfaceVariant` |
| label colour, disabled | `onSurface` | same | `onSurface` | same | `onSurface` | `onSurface` |
| label rung | `labelLarge` (14 / w500 / +0.1 / 1.43) | — | — | — | — | — |
| icon colour selected | `onSecondaryContainer` | same | `onSecondaryContainer` | same | *n/a* | **`primary`** |
| icon colour unselected | `primary` | same | `primary` | same | `primary` | **`onSurfaceVariant`** |
| icon size | 18.0 | 18.0 | 18.0 | 18.0 | 18.0 | 18.0 |
| `side` unselected enabled | `outlineVariant` | **transparent** | `outlineVariant` | **transparent** | `outlineVariant` / transparent | `outlineVariant` |
| `side` unselected disabled | `onSurface@12%` | **transparent** | `onSurface@12%` | **transparent** | `onSurface@12%` / transparent | `onSurface@12%` |
| `side` selected | **transparent** | transparent | transparent | transparent | *n/a* | transparent |
| `side` focused | **does not exist** | — | — | — | — | — |
| `elevation` | `0.0` | `isEnabled ? 1.0 : 0.0` | `0.0` | `isEnabled ? 1.0 : 0.0` | `0.0` / `1.0` | `0.0` |
| `pressElevation` | **`1.0`** | **`1.0`** | `1.0` | `1.0` | `1.0` | **`null` → 0** |
| `shadowColor` | **`Colors.transparent`** | **`colorScheme.shadow`** | transparent | `colorScheme.shadow` | transparent / shadow | transparent |
| `selectedShadowColor` | `null` (→ `ThemeData.shadowColor`) | same | same | same | same | same |
| `surfaceTintColor` | `Colors.transparent` | same | same | same | same | same |
| `shape` | `RoundedRectangleBorder(r=8)` | same | same | same | same | same |
| `showCheckmark` default | `true` | `true` | `true` | `true` | `true` (inert) | `true` |
| `checkmarkColor` selected | `onSecondaryContainer` | same | `onSecondaryContainer` | same | `null` | **`primary`** |
| `padding` | `EdgeInsets.all(8)` | same | same | same | same | same |
| `labelPadding` | `symmetric(h: 8)` @1.0×, lerping to `h: 4` @≥2.0× | same | same | same | same | same |
| `materialTapTargetSize` | from `ThemeData` → `padded` (48) on Android/iOS, `shrinkWrap` on desktop | — | — | — | — | — |
| overlay / state layer | **`RawChip` sets no `overlayColor`.** hover/focus/press come from `ThemeData.hoverColor` / `focusColor` / `splashColor` | — | — | — | — | — |

Border width is always the `BorderSide` default `1.0` — including the
*transparent* selected side — so the inset is identical across selection states
(`choice_chip.dart:352-357`).

### 3.3 The three SDK facts that matter most here

1. **`ChipThemeData.color` preempts the variant defaults completely.**
   `chip.dart:1529-1531`:
   ```dart
   Color? resolve(Set<WidgetState> states) {
     if (color != null) { return color!.resolve(states); }
   ```
   `chipDefaults.color` is reached only via the `?? defaultColor?.resolve(...)`
   tail at `chip.dart:1167`, which fires **only when the theme's resolver returns
   `null`**. MemoX's `_fillFor` never returns null. **Therefore
   `_ChoiceChipDefaultsM3.color` is dead code in this app.**

2. **`elevation` and fill are not coupled.** `ChipThemeData.elevation` is consumed
   at exactly one place, `chip.dart:1350`, and feeds only `Material(elevation:)`
   at `chip.dart:1405`. There is no path from `elevation` to `_getBackgroundColor`
   or to `_chipVariant`. `_chipVariant` is a `final` field set by *which
   constructor you called* (`choice_chip.dart:106` / `:149`). You cannot make an
   elevated chip flat through the theme, and `elevation: 0` does not change which
   `color` map is used.

3. **Supplying any `color` silently kills the hover state layer.**
   `chip.dart:1427`:
   ```dart
   hoverColor: (widget.color ?? chipTheme.color) == null ? null : Colors.transparent,
   ```
   Only *hover* is zeroed. `focusColor` and `splashColor` stay null on the
   `InkWell` and therefore fall through to `ThemeData.focusColor` /
   `ThemeData.splashColor` — see §12.

---

## 4. Current MemoX architecture

```
buildChipTheme(scheme, semantic, texts)            lib/core/theme/components/selection/app_chip_theme.dart
  ├─ color:        WidgetStateProperty  → _fillFor()        (disabled → pressed → focused → hovered → resting)
  ├─ side:         WidgetStateBorderSide → selected → disabled → outlineVariant
  ├─ labelStyle:   labelLarge @ w500, colour = WidgetStateColor
  ├─ iconTheme:    IconThemeData(size 16, onSurfaceVariant)   ← single-state fall-through
  ├─ shape:        RoundedRectangleBorder(AppRadius.pill = 999)
  ├─ padding:      EdgeInsets.symmetric(h: 12, v: 6)
  ├─ labelPadding: EdgeInsets.zero
  ├─ elevation:    AppElevation.none (0)
  └─ showCheckmark:false
        ↑ every value applies to all six Flutter chip variants app-wide

MxPillButton                                        lib/shared/widgets/mx_pill_button.dart
  └─ MxFocusRing(borderRadius: pill)                lib/shared/widgets/mx_focus_ring.dart
       └─ ChoiceChip.elevated(
            label: _Content(Row[Icon(sm, colour←DefaultTextStyle), gap xs, Flexible(Text)]),
            labelStyle: theme label re-metric'd to labelMedium,
            materialTapTargetSize: padded)
```

The layering is correct and matches AD-15 / `tokyo-component-mapping.md` §5: the
theme owns geometry and every colour state, the widget owns composition only (the
icon gap and the label rung). Two deliberate exceptions are documented in place
and both hold up: the icon colour is read back from `DefaultTextStyle` because
`ChipThemeData.iconTheme` has no `WidgetStateProperty` slot, and the icon rides in
the label rather than the `avatar` slot.

---

## 5. Production chip/pill inventory

### 5.1 Interactive pills — all five are class A or A-adjacent

| # | file:line | screen | class | exclusive | persists |
|---|---|---|---|---|---|
| 1 | [card_filter_bar_widget.dart:156](lib/features/card/presentation/widgets/sections/card_filter_bar_widget.dart:156) (helper; 4 pills at :76 / :88 / :100 / :114) | Card list — All / Due / New / Flagged | **A** | yes, 1-of-4 | `cardListFilterSelectionProvider` |
| 2 | [card_filter_bar_widget.dart:192](lib/features/card/presentation/widgets/sections/card_filter_bar_widget.dart:192) `_TagsPill` | Card list — Tags | **C/F hybrid with B state** | **no** | reflects `cardListTagFilterProvider` |
| 3 | [progress_range_selector_widget.dart:45](lib/features/progress/presentation/widgets/sections/progress_range_selector_widget.dart:45) | Progress — 7 / 30 day | **A** | yes | caller state |
| 4 | [study_options_section_widget.dart:97](lib/features/study/presentation/widgets/sections/study_options_section_widget.dart:97) | Study options sheet — new-card order | **A** | yes | draft, saved on submit |
| 5 | [trash_filter_bar_widget.dart:46](lib/features/trash/presentation/widgets/sections/trash_filter_bar_widget.dart:46) | Trash — All / Cards / Decks | **A** | yes | caller state |

### 5.2 Non-interactive rounded labels — class E, nine of them

All are `Container`/`DecoratedBox` + `BoxDecoration`. **None wraps an `InkWell` or
`GestureDetector`; none is focusable; none claims a tap target.** That is the
right call and it is consistent.

| file:line | what | fill | radius |
|---|---|---|---|
| [mx_session_top_bar.dart:222](lib/shared/widgets/mx_session_top_bar.dart:222) `_Chip` | study task name | `surfaceMuted` | `pill` |
| [card_detail_summary_widget.dart:149](lib/features/card/presentation/widgets/sections/card_detail_summary_widget.dart:149) `_SchedulerBadge` | `Box 3 / 8` | `surfaceMuted` | `pill` |
| [card_detail_summary_widget.dart:235](lib/features/card/presentation/widgets/sections/card_detail_summary_widget.dart:235) `_FlagChip` | flag readout | `dueContainer` | `pill` |
| [card_tile_widget.dart:279](lib/features/card/presentation/widgets/items/card_tile_widget.dart:279) `_DueBadge` | due date | `surfaceMuted` | `pill` |
| [card_history_event_widget.dart:158](lib/features/card/presentation/widgets/items/card_history_event_widget.dart:158) `_ActionBadge` | verdict word | none — outlined | `pill` |
| [card_tag_chip_widget.dart:20](lib/features/card/presentation/widgets/support/card_tag_chip_widget.dart:20) | read-only tag | `surfaceMuted` | `pill` |
| [card_import_preview_summary_widget.dart:163](lib/features/card/presentation/widgets/sections/card_import_preview_summary_widget.dart:163) `_StatusChip` | import counts | status containers | **`md`** |
| [deck_workload_line_widget.dart:125](lib/features/deck/presentation/widgets/items/deck_workload_line_widget.dart:125) `_WorkloadChip` | overdue / due / new | danger / due / muted | **`sm`** |
| [card_export_format_options_widget.dart:314](lib/features/card/presentation/widgets/sections/card_export_format_options_widget.dart:314) `_RecommendedBadge` | "Recommended" | `secondaryContainer` | **`sm`** |

**Finding P2-1 — one badge family, three radii.** Six use `pill`, one `md`, two
`sm`. `AppRadius.sm`'s own doc string names it "chips, badges, small indicators",
so the three that use it are following the token's stated intent and the six that
use `pill` are following the pill. Both readings are defensible; having both
shipped is not.

### 5.3 Deliberate non-pills (context — do not "fix" these)

`settings_choice_rows_widget.dart` (radio rows, explicitly rejects the pill —
see §11), `card_tag_filter_sheet_widget.dart:129` (`MxCheckboxRow` for
multi-select), `card_sort_control_widget.dart:29` (`MxMenuButton`),
`study_entry_section_widget.dart:42` (plain `Text` replaced a disabled pill),
`mx_session_top_bar.dart:219` (explicitly *not* `MxPillButton(onPressed: null)`).
`SegmentedButton` is themed at `app_segmented_button_theme.dart` and has **zero
call sites**.

---

## 6. Raw Chip-family inventory

Three raw uses in all of `lib/`. **No `FilterChip`, no `InputChip`, no `RawChip`,
no flat `ChoiceChip`, no Material `Badge`.**

| file:line | widget | classification |
|---|---|---|
| [mx_pill_button.dart:100](lib/shared/widgets/mx_pill_button.dart:100) | `ChoiceChip.elevated` | **A — the shared primitive itself**; see §8 |
| [card_tag_section_widget.dart:290](lib/features/card/presentation/widgets/sections/card_tag_section_widget.dart:290) | `Chip(onDeleted:)` | **A/legitimate special case** — this is class **D**, and `Chip` + `onDeleted` is the right primitive. `InputChip` is the closer M3 name but would add selection semantics the tag strip does not want. See §20 |
| [card_tag_section_widget.dart:299](lib/features/card/presentation/widgets/sections/card_tag_section_widget.dart:299) | `ActionChip` | **B — should use a shared primitive, or the boundary should be written down.** It is the app's only `ActionChip` and its only `avatar`-slot chip. See §14 and §19 |

---

## 7. `MxPillButton` semantic finding

**P1-1 — one shared widget serves two different semantics, and the API cannot
tell them apart.**

Four of the five call sites are honest class-A single-choice groups. The fifth,
`_TagsPill` ([card_filter_bar_widget.dart:192](lib/features/card/presentation/widgets/sections/card_filter_bar_widget.dart:192)),
is not: pressing it **opens a modal sheet** (`showCardTagFilterSheet`), and its
`isSelected` reflects whether a multi-tag predicate is active. Its own doc comment
says so plainly — *"It is the one pill that does not belong to the four-way
choice"*.

The consequence is measured, not theoretical. All five pills in that row emit an
identical semantics node shape:

```
SemanticsNode(flags: [isButton, hasEnabledState, isEnabled, isFocusable,
                      hasSelectedState, (isSelected)], actions: [focus, tap])
```

So a screen reader traversing the card filter bar meets five controls that are
indistinguishable in kind: four that are mutually exclusive and one that is an
independent toggle opening a dialog. Nothing announces which is which, and
nothing announces the exclusivity of the four. (Flutter's own `ChoiceChip` does
not set `inMutuallyExclusiveGroup` either — this is not a MemoX regression, but
it is a MemoX consequence, because MemoX chose `ChoiceChip` for a mixed row.)

`MxPillButton`'s API is `label / isSelected / onPressed / icon / semanticLabel`.
That is exactly the surface a class-A control needs and it exposes no visual
escape hatches (§26 — this is a strength). What it lacks is any way to say *which
kind of selection this is*, so the semantic drift is invisible at the call site
and un-assertable in a test.

---

## 8. `ChoiceChip.elevated` decision finding

**P1-2 — the recorded rationale is factually wrong, and the variant's only live
effect is the one the rationale claims to avoid.**

The five questions, answered with evidence.

**1. Is the semantic intent actually `ChoiceChip`?**
Yes, for four of five call sites — one-of-N with a persistent selected state is
precisely `ChoiceChip`. See §7 for the fifth.

**2. Is `.elevated` used for semantic fill behaviour, or only to obtain a
background?**
Neither, in practice. It obtains **nothing**. `chipTheme` declares
`color: WidgetStateProperty.resolveWith(...)`, which short-circuits
`_IndividualOverrides.resolve` at `chip.dart:1529-1531` before
`chipDefaults.color` is ever consulted. Measured under `buildLightTheme()`:

| | painted `Material.color` | elevation | `shadowColor` |
|---|---|---|---|
| `ChoiceChip` unselected | *(fill from `Ink`, identical)* | 0.0 | `#00000000` |
| `ChoiceChip.elevated` unselected | *(fill from `Ink`, identical)* | 0.0 | **`#FF9FA2BF`** |
| `ChoiceChip` selected | identical | 0.0 | `null` |
| `ChoiceChip.elevated` selected | identical | 0.0 | `null` |

The fill is byte-identical between variants. `_ChoiceChipDefaultsM3.color` is
unreachable code in this app.

**3. Does forcing `elevation: 0` make the variant semantically misleading?**
It makes it *inert* on the elevation axis — but only on `elevation`, not on
`pressElevation`. `chip.dart:1351-1352`:
```dart
final double pressElevation =
    widget.pressElevation ?? chipTheme.pressElevation ?? chipDefaults.pressElevation ?? 0;
```
`chipTheme.pressElevation` is **null** (measured). `_ChoiceChipDefaultsM3.pressElevation`
is `1.0` (`choice_chip.dart:295-296`). And `chip.dart:1405`:
```dart
Material(elevation: isTapping ? pressElevation : elevation, ...)
```

Measured on a real press of an unselected `MxPillButton`:

| frame | `Material.elevation` | `Material.shadowColor` |
|---|---|---|
| rest | `0.0` | `#FF9FA2BF` |
| **pressed** | **`1.0`** | `#FF9FA2BF` |

`#FF9FA2BF` is `AppColors.shadowLight` — the app's real shadow token, arriving
through `colorScheme.shadow` via `_ChoiceChipDefaultsM3.shadowColor`, which the
*flat* variant would have set to `Colors.transparent`. **So choosing `.elevated`
is precisely what makes the press shadow visible.** AD-14 admits one depth
mechanism and it is `shadowsFor`; this is a second, and it was introduced by the
change that was documented as removing one.

A second-order asymmetry falls out of the same chain: a **selected** pill's press
shadow uses `selectedShadowColor`, which no M3 defaults class overrides
(`chip.dart:1357-1360`), so it resolves to `null` and `Material` falls back to
`ThemeData.shadowColor` = **`#FF000000`** (measured — the app never sets it). One
control, two shadow colours, decided by selection state.

**4. Would a flat primitive + custom wrapper be worse?**
No — and that framing does not apply, because no wrapper is needed. Flat
`ChoiceChip` + the *existing* `chipTheme.color` produces the identical render
(measured above) and additionally restores `shadowColor: Colors.transparent`,
which neutralises the `pressElevation: 1.0` default for free. Nothing is
"bypassed": `ChipThemeData.color` **is** the canonical slot, and MemoX already
owns it deliberately and for good reason (§12).

**5. Is the current choice still the least-wrong architecture?**
No. The least-wrong architecture is the flat constructor plus the theme it
already has. The elevated variant buys nothing measurable and costs a shadow.

**Recording, not blame:** the reasoning behind M100.32 — *the pill is a paper pill
on the page, so it should take a canonical filled role rather than substitute one*
— is a good design argument and its **conclusion is correct** (`surfaceContainerLow`
is the right resting fill). Only the *mechanism* is wrong. The fix is not to
change what the pill looks like; it is to change which constructor produces it,
and to state `pressElevation: 0`.

**Three documents will need correcting together**, because they say the same wrong
thing three times: `app_chip_theme.dart:47-54` and `:169-175`,
`mx_pill_button.dart:91-99`, `docs/design-system/tokyo-component-mapping.md` §4
binding #4 and its table row at :68 / :179-184. Note that binding #4 is
**explicitly not in the pinned set** — that document says only five slots (FAB ×2,
Card, AppBar ×2) are guarded at source level, so nothing failed when the mechanism
diverged from the note.

---

## 9. Role / state matrix — current, measured

Resolved from the real `ChipThemeData` under both themes. Contrast ratios are
WCAG 2.x, computed from the measured hexes.

### 9.1 Light

| state | fill | vs page `#F2F5F9` | side | label | ext. focus ring | checkmark | elevation |
|---|---|---|---|---|---|---|---|
| rest | `#FFFFFF` (`surfaceContainerLow`) | 1.09:1 | `#E4E7EA` (`outlineVariant`) | `#596680` (`onSurfaceVariant`, 5.77:1 on fill) | — | none | 0 |
| selected | `#DADDEB` (`secondaryContainer`) | 1.24:1 | **transparent** | `#2E3141` (`onSecondaryContainer`, 9.51:1) | — | none | 0 |
| hover | `#F4F5FC` | — (1.09:1 vs rest) | `outlineVariant` | `onSurfaceVariant` | — | none | 0 |
| pressed | `#E9EAF9` | — | `outlineVariant` | `onSurfaceVariant` | — | none | **1 (+ shadow)** |
| focus | `#ECEEFA` | — (**1.16:1** vs rest) | `outlineVariant` | `onSurfaceVariant` | `#4454CC` @2dp, **5.67:1 on page** | none | 0 |
| disabled | `#E4E7EA` | 1.14:1 | `#E4E7EA` — **same as fill** | `#9AA3B1` composited, 2.06:1 | — | none | 0 |
| selected+hover | `#D1D5E9` | — | transparent | `onSecondaryContainer` | — | none | 0 |
| selected+pressed | `#C8CDE7` | — | transparent | `onSecondaryContainer` | — | none | **1 (+ shadow)** |
| selected+focus | `#CBCFE8` | — (**1.14:1** vs selected) | transparent | `onSecondaryContainer` | `#4454CC`, **4.58:1 on selected fill** | none | 0 |
| selected+disabled | `#C4C9D9` | 1.51:1 | transparent | `#9AA3B1` | — | none | 0 |

### 9.2 Dark

| state | fill | vs page `#070C27` | side | label |
|---|---|---|---|---|
| rest | `#111633` | 1.09:1 | `#272C48` | `#9395A2`, 5.95:1 |
| selected | `#2A3259` | 1.56:1 | transparent | `#DADCE7`, 9.05:1 |
| hover | `#1B203F` | — | `#272C48` | — |
| pressed | `#262B4B` | — | `#272C48` | — |
| focus | `#222747` | — | `#272C48` | ring `#BCC2FF`, **11.27:1 on page** |
| disabled | `#272C46` | 1.41:1 | `#272C46` — **same as fill** | `#65697B`, 2.51:1 |
| selected+hover | `#333B63` | — | transparent | — |
| selected+pressed | `#3C436D` | — | transparent | — |
| selected+focus | `#39406A` | — | transparent | ring `#BCC2FF`, **7.24:1 on selected fill** |
| selected+disabled | `#3D4468` | **2.04:1** | transparent | `#65697B` |

### 9.3 Canonical-role audit — no role substitution found

Every fill and label in the matrix resolves to a `ColorScheme` role or a
documented `AppSemanticColors` value. `primary` appears **only** as a state-layer
tint inside `_fillFor` and as the focus ring colour — never as a resting or
selected fill, and never in `side`. The M100.23 regression (focus resolving
`side` to `primary`) **is fixed and stays fixed**: `side` returns transparent for
`{selected}` and `{selected, focused}` alike, and `outlineVariant` for `{}` and
`{focused}` alike. This is pinned by
`test/core/theme/contracts/m3_combined_state_test.dart:65-110` and
`test/shared/widgets/mx_pill_button_theme_test.dart` (the negative check that
`side` never equals the focus-ring colour in any of four state sets). ✅

### 9.4 Findings from the matrix

**P1-3 — selection is carried by a 1.35:1 fill delta and nothing else.**
Selected removes the border *and* has no checkmark, so the total non-text signal
is `#FFFFFF` → `#DADDEB` (light, 1.35:1) / `#111633` → `#2A3259` (dark, 1.43:1).
`docs/wbs.md:10121-10126` already classified this as P1 against wireframe rule
W6 — and closed it by moving the Settings screen to `SettingsChoiceRowsWidget`
rather than by changing the pill. Four groups still ship it: card filter bar,
trash filter bar, study options, and the *unselected* half of the progress range
selector. Progress is the one that is already compliant, by adding
`icon: Icons.check` at the call site
([progress_range_selector_widget.dart:52](lib/features/progress/presentation/widgets/sections/progress_range_selector_widget.dart:52))
— a per-caller workaround for a component-level gap.

**P2-2 — a disabled unselected pill has no visible edge.** `side` disabled resolves
to `disabledSurfaceTint(scheme)` and `fill` disabled resolves to
`disabledSurfaceTint(scheme, over: surfaceContainerLow)` — which for the
unselected case is the *same call with the same ground*, so both are `#E4E7EA`
(light) / `#272C46` (dark). The border is invisible against its own fill. Not
wrong exactly — a disabled control legitimately recedes — but it is unintended:
`app_chip_theme.dart:201-203` writes a disabled border as if it were a distinct
signal.

**P2-3 — in dark, disabling a selected pill makes it *more* prominent.**
`selected` measures 1.56:1 against the page; `selected+disabled` measures
**2.04:1** — 31% more separation. `disabledSurfaceTint` blends `onSurface` (a
light ink in dark mode) at 12% over the resting fill, which lightens rather than
recedes. It is what M3 does too, so this is a *canonical* oddity rather than a
MemoX invention — but the app has both a `disabledSurface` token and a dark theme
that otherwise reads bottom-up, so the exception is worth an owner decision rather
than inheritance.

---

## 10. Focus architecture

The colour half is right. The geometry half is not.

**Colour — keep.** `MxFocusRing`'s premise is verified: MemoX's own focus wash
measures **1.16:1 in light and 1.22:1 in dark** against the resting fill (the doc
says 1.15 / 1.25 — close enough that the doc was measured, not guessed), which is
nowhere near the 3:1 WCAG 1.4.11 asks. The external ring at
`AppInteractionStates.focusIndicator` (2dp, `colorScheme.primary`) measures:

| ground | light | dark |
|---|---|---|
| page (`surface`) | 5.67:1 | 11.27:1 |
| paper (unselected fill) | 6.20:1 | 10.37:1 |
| selected fill (`secondaryContainer`) | **4.58:1** | **7.24:1** |

All six clear 3:1 with margin. Role identity is preserved: the ring never touches
a Material colour slot, so `side` keeps `outlineVariant`/transparent in every
combination. Selection survives focus — measured, `{selected, focused}` still
paints `secondaryContainer`-derived fill and a transparent side. Nothing moves on
focus: `MxFocusRing` adds only a `foregroundDecoration`, which paints without
participating in layout. It is not clipped — `Material.clipBehavior` is
`Clip.none` (measured) and the ring is drawn outside the chip's own shape anyway.

**P1-4 — geometry: the ring is drawn around the tap target, not around the pill.**

`MxFocusRing` wraps `ChoiceChip`, and `RawChip` with
`MaterialTapTargetSize.padded` wraps its painted body in
`_ChipRedirectingHitDetectionWidget(constraints: minWidth 48, minHeight 48)` +
`Center(widthFactor: 1, heightFactor: 1)` (`chip.dart:1487-1502`). So the box the
`DecoratedBox` decorates is the **48×48-floored** box.

Measured, light theme, 393dp, textScale 1.0:

| pill | painted `Material` rect | `MxFocusRing` `DecoratedBox` rect | gap |
|---|---|---|---|
| `'7'` (one glyph) | `(7.3, 7.0) → (40.7, 41.0)` = **33.4 × 34.0** | `(0,0) → (48.0, 48.0)` | **7.3dp** each side, **7.0dp** top/bottom |
| `'Due'` | `(0, 7.0) → (50.4, 41.0)` = 50.4 × 34.0 | `(0,0) → (50.4, 48.0)` | 0 horizontally, **7.0dp** top/bottom |

The ring's own radius is `AppRadius.pill` = 999, clamped by `BorderRadius` to half
the *ring* box's short side — 24 — while the pill clamps to 17. So the ring is
both larger and a different curve.

Consequences worth naming:
- On a short pill the ring reads as a ring around empty page, not around the
  control. The Progress range selector's `'7'` / `'30'` labels are the narrowest
  in the app and hit this hardest.
- The 7dp vertical bleed collides with anything within 7dp above or below. It does
  **not** collide horizontally with neighbours at the production gaps
  (`AppSpacing.sm` = 8 in card / trash bars, 8 in progress), because the 48-wide
  floor is inside the widget's own box — measured: pills at `0→76.6` and
  `84.6→226.6` in a `Wrap(spacing: 8)`, so 8dp of true clearance remains.
- `focus_ring_contrast_test.dart:102-109` deliberately removed the chip from its
  per-component list and delegated to `mx_pill_button_focus_test.dart`, which
  asserts the ring's **colour** after a real Tab press but never its **rect**.
  That is exactly why the geometry defect is unguarded.

**Do not move focus back into `ChipThemeData.side`.** The SDK gives no support:
`_ChoiceChipDefaultsM3.side` is a plain `BorderSide` computed from two booleans,
never a `WidgetStateBorderSide`, and no defaults class has a focused branch
(`choice_chip.dart:352-357`). Putting focus there is precisely the M100.23 bug.
The correct fix direction is to give the ring the pill's real rect, not to move
the ring.

---

## 11. Selected state and checkmark policy

**The layout argument for `showCheckmark: false` is correct and now measured.**
With `showCheckmark: true` and no avatar, `_layoutAvatar` (`chip.dart:1879-1891`)
gives the avatar slot a width of `contentSize` gated by `avatarDrawerAnimation`,
which is 0 when unselected and 1 when selected. Measured on a `FilterChip`
labelled `Flagged` under this theme:

| | width |
|---|---|
| `showCheckmark: true`, selected | **100.66** |
| `showCheckmark: false`, selected | **80.66** |
| `showCheckmark: false`, unselected | 80.66 |

**Exactly 20.0dp of growth on selection**, animated over 150ms
(`_kDrawerDuration`). In a 1-of-4 row that means every pill after the selected one
slides 20dp sideways on every change — the theme's stated reason
(`app_chip_theme.dart:176-179`) is right.

**But the accessibility argument is also right, and the project already agreed
with it.** Two production files refuse the pill *because of this setting*:

> `settings_choice_rows_widget.dart:14-21` — "W6 requires a selected state not to
> rest on colour alone. `MxPillButton` over `ChoiceChip` cannot satisfy that
> today."

and `settings_study_defaults_section_widget.dart:191-196` repeats it. `docs/wbs.md`
records it as a closed **P1**. So the current position is: the pill has a known W6
violation, it was fixed for one screen by not using the pill, and four screens
still use the pill.

**P1-3 (restated as a policy question, not a fix).** The report deliberately does
not recommend restoring the checkmark, because the 20dp reflow is real. The design
space the owner actually has:

| option | selection signal added | reflow cost | notes |
|---|---|---|---|
| restore `showCheckmark: true` | canonical tick | **20dp per toggle** | rejected once already, on measured grounds |
| keep a **selected-only leading glyph** at the component level | tick, composed in `_Content` | same 20dp — the icon is in the label | this is what Progress does per-caller today |
| keep a **persistent** glyph slot, swapping the glyph on selection | shape change, zero reflow | 0dp | rejected in `progress_range_selector_widget.dart:50-53`: "two different icons would read as two different kinds of thing" |
| add a **selected border** (`side` non-transparent when selected) | outline, zero reflow | 0dp | departs from `_ChoiceChipDefaultsM3.side`, which is transparent when selected — a *deliberate* canonical departure, which the project's own role-binding guard would have to admit |
| raise the fill delta | none — still colour-only | 0dp | does not satisfy W6 at all |
| accept per-caller opt-in (status quo) | caller's choice | 20dp when used | leaves four groups non-compliant |

Only the last row is free, and it is the one currently shipping. **This needs an
owner decision (§30 D1), not an implementer's judgement.**

Note for whoever implements: `_ChoiceChipDefaultsM3` also gives the checkmark a
colour that would *not* need overriding — `onSecondaryContainer` when selected
(`choice_chip.dart:338-343`), which is already the pill's selected label colour at
9.51:1.

---

## 12. Fill / surface findings and the state-layer audit

### 12.1 Fill and surface

After #429 the surface model is `surface` = page, `surfaceContainerLow` = paper.
The pill's resting fill is paper, which is right and consistent with `MxCard`,
sheets and menus. But **the pill's separation from the page is 1.09:1** — the
fill contributes almost nothing, and what actually draws the pill's boundary is
the `outlineVariant` hairline at **1.24:1 against the paper / 1.14:1 against the
page**.

**P2-4 — the resting pill boundary is below any non-text contrast floor.**
WCAG 1.4.11 asks 3:1 of "visual information required to identify user interface
components". A 1dp hairline at 1.14:1 against the ground it sits on does not
supply it. This is not a MemoX invention — it is `_ChoiceChipDefaultsM3`'s own
`outlineVariant` — but M3's own unselected chip is `null`-filled on a *card*,
where `outlineVariant` has more to work against. Here the pill is white on
near-white.

Contextual placements — **the paper-on-page assumption only holds on the page:**

| context | ground | pill resting fill | separation |
|---|---|---|---|
| on the page (card list, trash, progress) | `surface` `#F2F5F9` | `#FFFFFF` | 1.09:1 — the intended case ✅ |
| inside a `MxCard` | `surfaceContainerLow` `#FFFFFF` | `#FFFFFF` | **1.00:1 — the pill disappears into the card**, leaving only the hairline |
| inside a BottomSheet | sheet is `surfaceContainerLow` | `#FFFFFF` | **1.00:1** — this is Study options ([study_options_section_widget.dart:97](lib/features/study/presentation/widgets/sections/study_options_section_widget.dart:97)) |
| inside a Dialog | same as sheet | `#FFFFFF` | **1.00:1** |
| on a selected Card | selected-card surface | `#FFFFFF` | untested — no production case |

**P2-5 — a pill inside a sheet or card has zero fill separation from its ground.**
The one production instance is the Study options sheet's new-card-order pills. In
dark the same comparison is `#111633` on `#111633` — identically 1.00:1. The
control is still visible (hairline + label), but the "paper pill on the page"
model that justifies `surfaceContainerLow` is simply not true in that context, and
`ChipThemeData` has one fill for the whole app with no way to say otherwise. This
is a genuine constraint of a global component theme, not a bug — but it should be
a written constraint rather than an accident.

### 12.2 State layer

MemoX precomposes hover / focus / pressed / disabled into solid fills via
`_fillFor` + `Color.alphaBlend`, which is correct under MX-VIS-002 rule R7 (no
paint-time translucency) and is exactly what `design_audit/m3_token_architecture_3tier_vi.md:249`
records. Classification per the audit's own options:

- **(A) correctly owns the state** — yes for hover. `chip.dart:1427` forces
  `InkWell.hoverColor` to `Colors.transparent` the moment `ChipThemeData.color` is
  non-null, so MemoX's wash is the *only* hover feedback. Clean. ✅
- **(B) changes semantic role** — no. `primary` appears only as a tint over a
  canonical ground; the resting and selected roles are untouched. ✅
- **(C) creates duplicate feedback with the Material overlay** — **yes, for focus
  and press.** `chip.dart:1427` zeroes *only* `hoverColor`. Measured on the real
  `InkWell` inside `MxPillButton`:

  | `InkWell` slot | value | falls back to |
  |---|---|---|
  | `hoverColor` | `#00000000` | — (suppressed ✅) |
  | `focusColor` | `null` | `ThemeData.focusColor` = **`#1A4454CC`** = `primary` @ 10% |
  | `splashColor` | `null` | `ThemeData.splashColor` = **`#1F4454CC`** = `primary` @ 12% |
  | `highlightColor` | `null` | `ThemeData.highlightColor` = `#1F4454CC` |
  | `overlayColor` | `null` | — |

  MemoX's `_fillFor` **also** tints by `AppStateOpacity.focus` = 10% of `primary`
  on focus and `AppStateOpacity.pressed` = 12% of `primary` on press. So both fire:
  the rendered focus wash is roughly `primary` at ~19% effective, not the 10% the
  token declares, and the press adds an `_InkSparkleFactory` ripple in `primary`
  @12% on top of a fill that already moved 12% toward `primary`.

  **P2-6.** The numbers the theme documents (`1.15:1` for the focus wash) describe
  only MemoX's half. This does not break any role, and it is invisible in a
  `ChipThemeData` unit test — which is why no test caught it — but it means the
  state-layer opacity ladder in `AppStateOpacity` is not the ladder the pill
  renders.

- **(D) loses variant-specific behaviour** — yes, and this is the §8 finding: by
  owning `color`, MemoX makes the flat/elevated fill distinction unreachable. That
  is fine and intended; what is not fine is a comment claiming the opposite.

**Do not "fix" this by removing explicit state ownership.** The ownership is
correct and R7 requires it. The available fix is narrower: state the `InkWell`
slots the chip actually reads, which `ChipThemeData` cannot do — it has no
`overlayColor` field — so it would have to be an `InkWell`-level or
`ThemeData`-level decision. That is a design question, listed at §30 D3.

---

## 13. Disabled findings

Measured, both themes, all four disabled combinations.

| check | light | dark | verdict |
|---|---|---|---|
| disabled unselected ≠ enabled unselected | `#E4E7EA` vs `#FFFFFF` | `#272C46` vs `#111633` | ✅ |
| disabled selected ≠ enabled selected | `#C4C9D9` vs `#DADDEB` | `#3D4468` vs `#2A3259` | ✅ |
| **selected identity survives disabling** | `#C4C9D9` vs `#E4E7EA`, **1.33:1** | `#3D4468` vs `#272C46`, **1.45:1** | ✅ distinguishable, but only just — and by the same weak channel as §9.4 |
| disabled label | `#9AA3B1` composited, 2.06:1 on fill | `#65697B`, 2.51:1 | acceptable — WCAG 1.4.3 exempts disabled controls |
| disabled icon | rides the label via `DefaultTextStyle` | same | ✅ correct, and tested |
| disabled border | **identical to the fill** | **identical to the fill** | **P2-2** (§9.4) |
| tap semantics | measured `flags: [isButton, hasEnabledState, hasSelectedState]` — no `isEnabled`, no `isFocusable`, no tap action | same | ✅ correct; `chip.dart:1417` `canRequestFocus: widget.isEnabled` keeps a disabled pill out of traversal |
| never looks fully active | ✅ | ✅ | |
| never identical to disabled unselected | ✅ | ✅ | |

`disabledSurfaceTint(scheme, over: resting)` remains coherent after the surface
migration: because the ground is passed in per state, the selected pill's disabled
fill is derived from `secondaryContainer` rather than from the page, which is
exactly what keeps the selected identity. That mechanism is the right one and
should not change. The dark-mode prominence inversion (**P2-3**) is a palette
question, not a mechanism question.

One live production consideration: only one call site can currently produce a
disabled pill — `MxPillButton.onPressed: null` — and its own doc says it exists
"for the transient case … rather than for a permanent one". No production screen
renders a disabled pill today, which is why the state is untested visually (§16).

---

## 14. Icon / label composition findings

Measured, light theme, `MxPillButton(icon: Icons.schedule, label: 'Due')`:

| metric | MxPillButton (manual `Row`) | `ActionChip` (avatar slot), same theme | M3 default |
|---|---|---|---|
| left inset to glyph | **13.0** (= 1dp border + 12dp `padding`) | **15.0** | 8 + avatar centring |
| glyph size | 16.0 (`AppIconSize.sm`) | 16.0 (from `chipTheme.iconTheme`) | 18.0 |
| glyph → label gap | **4.0** (`AppSpacing.xs`) | **2.0** | 8 (`labelPadding`) |
| right inset from label | **13.0** — symmetric ✅ | 13.0 | 8 |
| painted height | 34.0 | 34.0 | label-driven |

**The manual composition still earns its place, and now there is a number for it.**
The avatar slot puts the glyph 2dp further from the edge and 2dp closer to its
word than the composed row does — the exact asymmetry
`mx_pill_button.dart:106-110` describes. Composed, the padding is symmetric at
13.0 on both sides. Keep it.

Colour sync is correct in every state: the glyph reads
`DefaultTextStyle.of(context).style.color`, which is what `RawChip` resolves
`labelStyle` into (`chip.dart:1375-1380`), so selected / disabled / resting all
arrive for free. This is asserted at
`test/shared/widgets/mx_pill_button_theme_test.dart` for three states. ✅

`Flexible(child: text)` is load-bearing and verified: at 320dp × textScale 2.0
with a Vietnamese label, three icon pills wrap across two runs with **no
exception and no overflow** (measured: `76.6`, `142.0`, `166.0` wide; second run
at y 56). ✅

**P2-7 — the app's one `ActionChip` uses the avatar slot and therefore does not
match any pill in the app.** [card_tag_section_widget.dart:299](lib/features/card/presentation/widgets/sections/card_tag_section_widget.dart:299)
renders `+ Add tag` at 15.0 / 2.0 where every `MxPillButton` renders 13.0 / 4.0.
It sits in a `Wrap` beside `Chip`s that have no leading glyph at all, so the
discrepancy is not currently visible side-by-side with a pill — but it is the one
chip in the app whose geometry nothing owns.

RTL: not audited. The app ships `en` and `vi`, neither RTL, and
`ChoiceChip`/`RawChip` handle direction via `EdgeInsets.resolve(textDirection)`
throughout. The composed `Row` in `_Content` inherits `Directionality` correctly.
No finding.

---

## 15. Geometry findings

All measured, light theme, `devicePixelRatio` 1.0.

| metric | value | source of the value |
|---|---|---|
| content box height | 32.0 | `padding.vertical` 12 + `label-lg` line box 20, stated at `app_chip_theme.dart:271-275` |
| **painted height** | **34.0** | content 32 + two 1dp hairlines **outside** it |
| **tap target height** | **48.0** | `kMinInteractiveDimension`, via `MaterialTapTargetSize.padded` |
| tap target min width | **48.0** | same constraint (`chip.dart:1493`) |
| horizontal padding to content | 12.0 (13.0 including the border) | `AppSpacing.md` |
| vertical padding | 6.0 | derived `(32 − 20) / 2` |
| icon gap | 4.0 | `AppSpacing.xs`, composed |
| radius | `AppRadius.pill` (999, clamped to 17 on a 34-tall pill) | |
| border width | 1.0 | `BorderSide` default — never stated by MemoX or by the SDK |

**The theme's own documentation of these numbers is accurate.** The claim that
"a ruler laid on the painted shape reads 34" and that the content box is 32
verified exactly.

Widths measured at three breakpoints and three text scales:

| label | 320 / 1.0 | 393 / 1.0 | 320 / 2.0 |
|---|---|---|---|
| `'7'` | 48.0 (floored by the tap target; painted 33.4) | 48.0 | — |
| `'Due'` | 50.4 | 50.4 | — |
| `'Due'` + icon | 70.4 | 70.4 | — |
| `'All'` + icon | — | — | 76.6, painted height **46.0** |
| `'Flagged'` + icon | — | — | 142.0 |
| `'Đã gắn cờ'` + icon | — | — | 166.0, wraps to run 2 |

At textScale 2.0 the painted height grows 34 → 46 and the outer box stays 48, so
the pill is still inside its own tap target and nothing clips. `padding` rather
than a fixed height is the right choice and the comment at
`app_chip_theme.dart:258-260` is vindicated.

**P3-1 — `RawChip`'s 48dp *width* floor is undeclared in MemoX tokens.** A
one-glyph pill paints 33.4 wide but occupies 48.0, centred. Nothing in
`app_chip_theme.dart` or `AppSizing` says so; the number arrives from
`chip.dart:1493`. It is *correct* (a 33dp-wide target is below the guideline) but
it is the geometry that produces the §10 focus-ring bleed, and it is not written
down anywhere a reader would look.

**P3-2 — border width is nobody's decision.** 1.0dp comes from Flutter's
`BorderSide` default. `AppStroke` exists and has a `focus = 2`; there is no
`hairline` constant feeding the chip.

Visual pill height (34) and touch target (48) are correctly kept separate — the
padded tap target grows around the shape rather than instead of it, exactly as
`AppSizing.touchTarget`'s doc says. No Tokyo desktop height leaked in: 34dp
painted / 32dp content is M3's own chip height, not a CSS value.

---

## 16. Pill-vs-Button boundary

Proposed boundary for the implementation pass:

> **Chip / Pill** — a control with a *resting selected state* that filters,
> chooses or tokenises content. Its press changes what is *shown*.
> **Button** — a command. Its press changes what *is*. No selected state.

Measured against production, **four of five pills are on the correct side.** The
one that is not:

**P1-1 (again) — `_TagsPill` is a command wearing a selection.** It opens a modal.
Under the boundary above it belongs to the Button family or to a named
"filter-entry" primitive — but note it *also* legitimately carries a persistent
on/off state (whether a tag predicate is applied), which no button in
`MxActionButton`'s ladder can express. So it is not a simple migration; it is a
missing primitive. Flagged, not resolved.

Nothing was found where `MxPillButton` was reached for *purely because the shape
is small and rounded* — the two places where that temptation appeared are both
documented refusals: `study_entry_section_widget.dart:42` (a readout that became
plain `Text`) and `mx_session_top_bar.dart:219` (a classification label that
became a private `_Chip`). That is a good sign about the codebase's discipline.

---

## 17. Pill-vs-Badge boundary

> **Badge** — a readout. No focus, no press, no selected semantics, no touch-target
> claim. Rounded because it is a label, not because it is a control.

**The project already respects this and should keep the two APIs apart.** All nine
class-E labels (§5.2) are plain `Container` + `BoxDecoration`; **not one** is
built from an interactive chip component. Nothing in `lib/` uses `Chip`,
`ActionChip` or `MxPillButton` for a pure badge.

Two observations, both minor:

**P3-3 — three radii for one family** (P2-1 in §5.2, restated as a boundary
question): the badge family has no shared primitive, so nine independent
`Container`s each decide their own radius. A shared `MxBadge` is *arguably*
warranted — nine call sites is well past the "repeated production composition"
bar — but that is a separate audit's territory and it must **not** be unified with
the chip API.

**P3-4 — `Chip` in the tag strip announces `hasSelectedState` and is never
selected.** Measured: `SemanticsNode(flags: [hasSelectedState], label: "grammar")`
— no `isButton`, no tap action, correctly, but the selected-state flag is
inherited noise from `RawChip`. Cosmetic; a screen reader reads the label
normally.

---

## 18. ChoiceChip vs FilterChip

Inventory of every filter surface in the app:

| surface | selection model | control today | correct primitive |
|---|---|---|---|
| Card list state filter (4) | **single**, 1-of-4 | `MxPillButton` → `ChoiceChip.elevated` | **`ChoiceChip` — correct** ✅ |
| Card list tag filter | **multi** (n tags) | a **sheet** of `MxCheckboxRow`, entered by `_TagsPill` | checkbox rows are correct for the sheet; the *entry* is the mismatch (§7) |
| Trash filter (3) | single, 1-of-3 | `MxPillButton` | correct ✅ |
| Progress range (2) | single, 1-of-2 | `MxPillButton` | correct ✅ |
| Study new-card order | single | `MxPillButton` | correct ✅ |
| Settings appearance / language / order | single | `SettingsChoiceRowsWidget` (radios) | correct — and chosen *over* the pill for W6 |

**Verdict: no `ChoiceChip` → `FilterChip` migration is warranted.** MemoX has no
multi-select chip bar. Adopting `FilterChip` now would add a variant, a defaults
class and a Widgetbook axis for zero call sites. **Do not adopt it until a
multi-select chip bar actually exists.**

Worth recording for whoever gets there: `_FilterChipDefaultsM3` is
behaviourally **identical** to `_ChoiceChipDefaultsM3` in every field
(`filter_chip.dart:305-423`). The difference is purely at the widget level —
`FilterChip` passes `labelStyle`/`selectedColor` through verbatim instead of via
`secondaryLabelStyle`/`secondarySelectedColor`, resolves `showCheckmark` through
the full theme chain rather than eagerly, and carries a delete icon
(`Icons.clear` @18). Since MemoX overrides `color`, `side`, `labelStyle`,
`showCheckmark` and `padding` anyway, **switching to `FilterChip` would change
nothing visually** — the choice is purely semantic, which is the right reason to
make it and the right reason not to make it yet.

---

## 19. ActionChip / InputChip findings

**`ActionChip` — do not expand its use; write the boundary down instead.**
The app has exactly one, at
[card_tag_section_widget.dart:299](lib/features/card/presentation/widgets/sections/card_tag_section_widget.dart:299).
It is a legitimate special case: `+ Add tag` sits inside a `Wrap` **of chips**, so
a `Button` there would be the outlier, not the chip. But it is also the only
place in the app where a command is a chip, and §16's boundary says commands are
buttons.

The honest answer to "would `ActionChip` fit MemoX's Button-vs-Chip architecture?"
is **no as a general primitive, yes as a documented exception for a chip that
joins a row of chips.** Two SDK facts support keeping it exceptional:
`_ActionChipDefaultsM3.labelStyle` uses **`onSurface`** where every other variant
uses `onSurfaceVariant` (`action_chip.dart:288-293`), and its `color` map has **no
selected branch at all** (`action_chip.dart:295-306`) — so an `ActionChip` cannot
express selection even if asked. Under MemoX's global `chipTheme`, both are
overridden, which means the app's `ActionChip` currently paints like a pill and
means something else. That is the whole risk of adopting it more widely.

No production candidate was found for converting a pill into an `ActionChip`. The
one near-candidate, `_TagsPill`, carries persistent state and therefore cannot be
an `ActionChip` (no selected branch).

**`InputChip` — not applicable, and it should stay that way.** MemoX's removable
tag token uses `Chip(onDeleted:)`, which is the right primitive: `InputChip` adds
`selected` / `onSelected` semantics that a tag on a card editor does not have.
Two SDK divergences make `InputChip` an active liability if adopted casually:
its `pressElevation` is **`null` → 0** where every other variant is 1.0
(`input_chip.dart:276-281`), and it **swaps `primary` and `onSurfaceVariant`**
relative to Choice/Filter for both `iconTheme.color` and `checkmarkColor`
(`input_chip.dart:319-348`). Under MemoX's global theme those are mostly
overridden — but `checkmarkColor` is not, and it would surface the day
`showCheckmark` changes.

---

## 20. Tag system review — the three tag roles are correctly separated

| role | control | file |
|---|---|---|
| tag as **data label** (read-only) | `CardTagChipWidget` — plain `Container`, class E | [card_tag_chip_widget.dart:20](lib/features/card/presentation/widgets/support/card_tag_chip_widget.dart:20) |
| tag as **filter** | `MxCheckboxRow` inside a sheet, entered by `_TagsPill` | [card_tag_filter_sheet_widget.dart:129](lib/features/card/presentation/widgets/overlays/card_tag_filter_sheet_widget.dart:129) |
| tag as **removable token** | `Chip(onDeleted:)` in the card editor | [card_tag_section_widget.dart:290](lib/features/card/presentation/widgets/sections/card_tag_section_widget.dart:290) |

Three roles, three controls, no forcing. ✅ **Do not unify these.**

**P3-5 — the removable token's delete affordance is 33 × 48, not 48 × 48, and the
guard cannot see it.** This is *already recorded and already decided* at
`card_tag_section_widget.dart:264-277`: no `deleteIconBoxConstraints` is set, so
the hit region is 48dp tall (from `MaterialTapTargetSize.padded` +
`_RenderChipRedirectingHitDetection`, which maps any hit in the 48dp band to the
slot under the x) but only ~33dp wide; `minWidth: 48` would cost 28px per chip and
push a ten-tag card to a third row at 320dp. The owner looked at both renders and
chose width (2026-08-26). The note also records the reason a test cannot catch it:
`meetsGuideline(androidTapTargetGuideline)` reads the semantics rect, and the
delete's node merges into the chip's, so the guideline is green either way.

Listed as P3 rather than higher **because it is a made decision, not a missed
one.** It appears here only so a future implementation pass does not "fix" it
without knowing it was chosen. My own first measurement read the `InkWell`'s
render box as 16×16 and was wrong — the redirecting hit detection is what makes
the real number 33 × 48, and the repo's note is more accurate than a naive probe.

---

## 21. Accessibility findings

Measured with `ensureSemantics()` on a real render.

| pill | emitted node |
|---|---|
| selected, enabled | `flags: [isSelected, isButton, hasEnabledState, isEnabled, isFocusable, hasSelectedState]`, `actions: [focus, tap]` |
| unselected, enabled | same minus `isSelected` |
| disabled | `flags: [isButton, hasEnabledState, hasSelectedState]`, **no actions, not focusable** |

What works:
- selected state is announced ✅
- `semanticLabel` correctly **replaces** the visible label rather than adding to
  it (`Text.semanticsLabel`, not a `Semantics` wrapper) ✅ — abbreviations like
  `A–Z` and the counts stripped from the visible filter labels
  (`cardFilterSemantics` → "Flagged, 3 cards") both ride this ✅
- disabled pills leave the traversal order ✅
- `ProgressRangeSelectorWidget` wraps its group in
  `Semantics(container: true, label: 'Reporting window')` so the group is
  introduced before its options ✅ — the only group that does

What does not:

**P1-5 — no group communicates exclusivity, and multi-select is indistinguishable
from single-select.** All five controls in the card filter bar emit the same node
shape; four are 1-of-4 and one is an independent toggle. Nothing sets
`inMutuallyExclusiveGroup`. Flutter's `ChoiceChip` does not set it either, so this
is inherited — but MemoX put a non-exclusive control into an exclusive row, which
is the part that is MemoX's.

**P2-8 — three of four pill groups have no group label.** Trash, card filter bar
and study options emit their pills as loose siblings; only Progress introduces the
group as a `Semantics` container. Study options does have a visible `Text` label
above its `Wrap`, which sighted users get and the accessibility tree does not
associate. A screen reader user hears "All, selected, button / Due, button / …" with
no statement of what is being chosen.

Icon labelling is correct: every glyph is decorative and unlabelled, the label is
what is announced, and no icon repeats its word — the `Icons.circle_outlined`
choice over `fiber_new` at `card_filter_bar_widget.dart:107-111` is exactly this
reasoning applied.

Touch targets: 48×48 minimum is met by every pill in every measured configuration
including 320dp × 2.0×, and is asserted by
`test/shared/widgets/mx_stress_test.dart` via `meetsGuideline`. ✅

---

## 22. Group composition findings

| group | layout | gap | overflow behaviour |
|---|---|---|---|
| Card filter bar | `SingleChildScrollView(horizontal)` + `Row`, with `_TagsPill` pinned outside the scroller | `SizedBox(width: AppSpacing.sm)` between pills | scrolls |
| Trash filter bar | `SingleChildScrollView(horizontal)` + `Row` | `Padding(right: AppSpacing.sm)` | scrolls |
| Progress range | plain `Row` | `SizedBox(width: AppSpacing.sm)` | none — two short pills, cannot overflow |
| Study options | `Wrap` | `Wrap(spacing: AppSpacing.sm)` | wraps; a visible `Text` label sits above it |
| Golden specimen | `Wrap` | — | wraps |

Measured at 320dp × textScale 2.0: three icon pills in a `Wrap(spacing: 8)`
produce runs of `76.6 + 8 + 142.0` and then `166.0` on run 2 — no exception, no
clipping. The scrolling bars do not wrap by design, and
`trash_filter_bar_widget.dart:33-37` records why (a wrapped second line moves the
list under the reader's thumb).

**P2-9 — four groups, three spacing idioms, and the gap value is repeated four
times.** `SizedBox(width: AppSpacing.sm)`, `Padding(right: AppSpacing.sm)` and
`Wrap(spacing: 8)` all express the same decision. None is wrong; the value is the
same token; but there is no single place that says "pills sit 8 apart", so the
fifth group will decide again.

**Is a shared group-layout primitive warranted?** Marginally yes — four production
groups is past the bar, and three of them additionally need the same group
`Semantics` wrapper that only Progress has today (**P2-8**). A primitive that
supplied gap + group label + scroll-vs-wrap policy would close both findings at
once. But note the two scrolling bars differ in a real way (`_TagsPill` is
deliberately pinned outside the card bar's scroller), so the primitive must not
assume a homogeneous list.

**Do not put group layout into `ChipThemeData`.** It has no slot for it, and the
gap between two chips is not a property of a chip.

---

## 23. Selected hierarchy

Selected pills use `secondaryContainer` `#DADDEB` / `#2A3259`, which is the same
pair `NavigationBar`'s indicator and `SegmentedButton` take — deliberately, per
`app_theme.dart:238-241`, so "this one is active" reads the same across tab,
segment and filter.

Competition check against everything that could out-shout it, measured against the
page:

| element | light contrast vs page | dark |
|---|---|---|
| selected pill (`secondaryContainer`) | **1.24:1** | **1.56:1** |
| primary CTA (`FilledButton`, `primary` `#4454CC`) | 5.67:1 | 11.27:1 |
| focus ring (`primary` @2dp) | 5.67:1 | 11.27:1 |
| status badges (`dueContainer`, `dangerContainer`, …) | varies, all above the pill |

The selected pill is by a wide margin the quietest of these. **It is not competing
with the primary CTA — it is arguably losing to the status badges beside it**, and
that is the same complaint the owner review of 2026-08-20 raised and M100.22
answered by moving the *tone* rather than the role. The role binding is correct
and should be left alone.

**Do not switch to `primaryContainer`.** That was tried between the 2026-08-20
review and M100.22 and reverted for exactly the right reason. If the hierarchy
still reads weak after the W6 decision (§11) lands, the lever is a palette/tone
review of `secondaryContainerLight` / `secondaryContainerDark`, per AD-14 — not a
component role substitution. Recorded as a *conditional*, not a finding: at
1.35:1 selected-vs-unselected the pill's problem is discriminability from its own
neighbours (§9.4), not from the CTA.

---

## 24. Tokyo — keep vs reject

Filtered through the standing rule that Tokyo is a **web** design system and MemoX
is a **mobile** app.

### Worth adapting

| trait | why it survives the filter | already present? |
|---|---|---|
| restrained inactive state | a resting pill that does not shout is right on a screen where the list is the content | yes — `outlineVariant` hairline, `onSurfaceVariant` label |
| confident, calm typography on the label | `label-lg` metrics at **w500** rather than the app's w600 | yes, and this is the app's only rung-level weight exception — `app_chip_theme.dart:123-143` argues it from a measured ink-coverage comparison (0.340 / 0.364 vs the search hint's 0.271), which is the right kind of evidence |
| clean selected state — one fill change, no ornament | matches M3's own `secondaryContainer` answer | yes |
| balanced padding | 12 horizontal, symmetric at 13 including the border | yes, measured ✅ |
| compact visual chrome | 34dp painted is compact without going under the M3 chip height | yes |

### Reject

| trait | why |
|---|---|
| hover-first interaction | the primary input is a finger; hover exists only on the web E2E channel. Note the app **still spends a token on it** (`AppStateOpacity.hoverControl`) and composites a hover fill that no Android user will ever see — harmless, but it is web thinking that survived |
| desktop click target | `MaterialTapTargetSize` defaults to `shrinkWrap` on desktop and `padded` on mobile (`theme_data.dart:400-409`). MemoX states `padded` explicitly at the widget, which is correct and must stay |
| exact CSS pill height | Tokyo's pill height is a CSS value; MemoX's 32/34 is M3's chip height, derived from the app's own `label-lg` line box. Do not import a number |
| pointer-driven affordances | nothing in the pill depends on hover to be discoverable ✅ |
| exact desktop border / shadow | already the §8 problem in a different costume: the elevated variant's shadow is a depth mechanism AD-14 does not admit |
| dense admin-toolbar assumptions | the card filter bar already gave up its visible counts to fit 390dp (`card_filter_bar_widget.dart:161-165`); a denser toolbar is the wrong direction |

**No recommendation in this document rests on "Tokyo does it".** Each row above
either has an M3 role, a measured number, or a repo rule behind it.

---

## 25. Performance — static findings only

Per-pill widget cost, read from `chip.dart`:

- `MxFocusRing` = 1 × `Focus` + 1 × `DecoratedBox`, `setState` scoped to itself.
  Focus changes rebuild the ring only, not the chip. ✅
- `RawChip` = 1 × `Material` + 1 × `InkWell` + 1 × `Ink` + 1 × `Semantics` +
  1 × `Center` + 1 × `_ChipRedirectingHitDetection` + **2 × `AnimatedSwitcher`**
  (avatar and delete icon, constructed unconditionally at `chip.dart:1452-1462`
  even when both are null) + **4 `AnimationController`s** (`select`, `avatarDrawer`,
  `deleteDrawer`, `enable`).
- No `Clip` — measured `Material.clipBehavior == Clip.none`. ✅
- No `BackdropFilter`, no explicit `saveLayer`, no per-chip custom shadow. ✅
- `InkWell.customBorder` is set to the resolved `RoundedRectangleBorder`
  (`chip.dart:1428`) — splash clipping goes through a path, which is the one
  non-trivial raster cost, and it is Flutter's, not MemoX's.
- **`Material(elevation: 1.0)` on press** (§8) is the one MemoX-caused raster cost:
  an elevation change triggers a shadow layer for the press duration.

Largest group in production is five pills (card filter bar). Nothing here is a
performance concern at that count. `RawChip`'s 4 controllers × 5 would matter in a
long scrolling list of chips; MemoX has none.

**Android runtime profiling → DEFERRED.** No device profile was taken.

---

## 26. API escape-hatch audit

`MxPillButton`'s full public surface:

| parameter | type | visual escape hatch? | callers |
|---|---|---|---|
| `label` | `String` | no | 5 |
| `isSelected` | `bool` | no | 5 |
| `onPressed` | `VoidCallback?` | no | 5 |
| `icon` | `IconData?` | no — size and colour are both derived | 3 (card filter bar ×2, progress) |
| `semanticLabel` | `String?` | no | 3 |

**Zero visual escape hatches. No `color`, `selectedColor`, `backgroundColor`,
`border`, `radius`, `padding`, `elevation`, `textStyle` or `iconColor` is
exposed.** This is the strongest part of the component and it should be defended
in any rewrite: a feature literally cannot drift the pill's appearance.

Two adjacent notes, neither a finding:

- The **three raw chips** (§6) are the real escape hatch — a feature that wants a
  differently-shaped chip today simply writes `Chip(...)` and inherits the global
  `chipTheme`. That is fine while there are three; it is the mechanism by which a
  fourth appears without review.
- `MxPillButton` itself reaches into `ChipTheme.of(context).labelStyle` and
  re-metrics it to `labelMedium` (`mx_pill_button.dart:65-75`). That is a *widget*
  overriding a *theme* geometry decision, which `tokyo-component-mapping.md` §5
  lists as MUST NOT ("một `Mx*` widget hoặc một feature nêu lại các giá trị này").
  **P3-6.** The comment at `mx_pill_button.dart:115-125` argues it well — the deck
  list's Study button is `label-md` and two same-height controls should not read
  at two sizes — but the effect is that **`chipTheme.labelStyle`'s size is dead
  for every pill in the app**, since all five call sites go through
  `MxPillButton`. The `label-lg` rung it sets is reached only by the tag strip's
  raw `Chip`/`ActionChip`. That is worth reconciling: one of the two is wrong.

---

## 27. Widgetbook gaps

`widgetbook/lib/components/control_components.dart:400-438` — one component, one
use-case, named `Playground`. Knobs: `label`, `isSelected`, `enabled`,
`with icon`, `semanticLabel`. Global addons supply theme, text scale, locale and
viewport (including a 320 `compactViewport`).

| presentation | status |
|---|---|
| choice semantics | ✅ (the only variant) |
| filter / action / badge comparison | ❌ none exist |
| resting / selected / disabled | ✅ via knobs |
| **focused**, **selected + focused** | ❌ — and `MxFocusRing` is an *explicit exclusion* in `test/app/widgetbook_coverage_test.dart:36-41` |
| label only / icon + label | ✅ (icon fixed to `Icons.schedule`) |
| long label | ⚠️ typeable, no preset |
| on page | ✅ indirectly, via five screen use-cases |
| **inside Card / inside sheet** | ❌ — and this is where §12.1's 1.00:1 finding lives |
| **horizontal group / wrapped group** | ❌ — the `PillGroupSpecimen` golden has no catalogue twin |
| 320dp / textScale 2.0 | ⚠️ available as addons, no dedicated case |

Highest-value additions, kept deliberately small to avoid combinatorial explosion:

1. **`Group`** — three pills, one selected, in a `Wrap`; the only way to see the
   1.35:1 selected/unselected delta in context, which is the audit's biggest
   finding.
2. **`On a card`** — the same group inside `MxCard`; makes §12.1 visible.
3. **`Focused`** — a pill with `autofocus`; makes §10's ring geometry visible.
   Requires relaxing the `MxFocusRing` exclusion, or hosting the focus in the
   pill's own use-case rather than the ring's.

Everything else is reachable through existing knobs and addons and does not earn
a story.

`test/app/widgetbook_coverage_test.dart` only enforces *presence of a component
name*, so the single-Playground shape is invisible to the guard. That is why the
gap persisted.

---

## 28. Golden and test gaps

### 28.1 Goldens

Two exist: `test/shared/widgets/goldens/mx_pill_group_{light,dark}.png`, written
by `mx_components_golden_test.dart:329` from `PillGroupSpecimen`
(`golden_specimens.dart:209-263` — a `Wrap` of two pills, one selected, both with
`Icons.filter_list`). **Resting frame only.** No golden anywhere captures a
focused, hovered, pressed or disabled pill.

Pills also appear inside `card_list_*`, `tag_catalog_*`, `tag_filter_sheet_*`,
`progress_overview_*`, `progress_deck_*` and `trash_*` screen goldens.

**Gap: Study options has pills and no golden at all.** `test/demo/` has no central
`SCREENS`-style registry, so a pill-bearing screen can ship with no picture and
nothing objects.

Minimum useful future component set — three files, not five:

| golden | why it earns a file |
|---|---|
| `chip_states_light` / `chip_states_dark` | one image per theme carrying rest / selected / disabled / **selected+disabled** side by side. This is the only artefact that would make P1-3 and P2-2 visible to a reviewer at a glance |
| `chip_focus_light` | the ring's rect against the pill's rect — the picture that would have caught P1-4 |

**Do not add** `chip_choice_*` as a separate file (it is the resting half of
`chip_states_*`), and do not snapshot `FilterChip` / `InputChip` / `ActionChip`
variants MemoX does not use — §18 and §19 say it has no callers for two of the
three.

### 28.2 Test quality

**Protected contracts (good, keep):**

- `m3_role_contract_test.dart:91-124` — pins `secondaryContainer`,
  `surfaceContainerLow`, `onSecondaryContainer`, `onSurfaceVariant`,
  `outlineVariant`, transparent-when-selected, **by role**, both themes. This is
  the right shape of assertion. ✅
- `m3_combined_state_test.dart:65-110` — pins that `side` stays transparent under
  `{selected, focused}` and `outlineVariant` under `{focused}`. This is the
  M100.23 regression guard and it works. ✅
- `mx_pill_button_theme_test.dart` — every state resolves **opaque** (R7), and
  `side` never equals the focus-ring colour in four state sets. A negative role
  assertion, which is unusual and valuable. ✅
- `mx_pill_button_test.dart` — `matchesSemantics(...)` with the full flag set; the
  strongest semantics assertion in the repo. ✅
- `mx_stress_test.dart` — 320×640 × 2.0× × both themes × Vietnamese, plus
  `meetsGuideline`. ✅

**Tests that pin implementation rather than contract:**

- `mx_pill_button_theme_test.dart`'s painted-`Ink` check asserts the tree's
  `ShapeDecoration.color` **equals the theme's own resolved value**. That is a
  tautology across a role change: move `secondaryContainer` and both sides move
  together. It catches a wiring break, not a role drift — the role tests do that
  separately, so this is defensible, but it should not be mistaken for coverage.
- `component_theme_typography_test.dart:120-125` pins `labelStyle` weight to the
  literal `500`. Fine, but note §26 P3-6: nothing pins the *size*, and
  `MxPillButton` overrides it.

**Missing:**

| gap | consequence |
|---|---|
| **flat vs elevated variant is asserted nowhere** — `grep 'ChoiceChip.elevated' test/` returns zero | swapping the constructor changes the press shadow and **no test fails**. This is why §8's defect went unnoticed |
| **`pressElevation` / `Material.elevation` is asserted nowhere** | ditto |
| **`selected + hover` appears in no list in the repo** | the one combination with no coverage at all |
| **`selected + pressed`** is only in the "resolves opaque" list — no differential vs `selected` or vs `pressed` | |
| **no test ever produces a real pointer frame** on a pill — hover and press are theme-map reads only | §12.2's double state layer is unobservable |
| **the focus ring's *rect*** is never asserted, only its colour | P1-4 |
| **no group-level semantics test** — exclusivity, group label | P1-5, P2-8 |
| **short-label width** at 1.0× is not asserted | P3-1 |

The single highest-leverage test to add is a **rendered state-matrix test** that
drives a real pointer and a real Tab and reads `Material.elevation`,
`ShapeDecoration.color` and the ring rect at each of the ten states. It closes six
of the eight rows above.

---

## 29. Findings by severity

### P0 — none

No finding in this audit makes the pill unusable, unreachable, or wrong to an
assistive technology in a way that blocks a task. The two accessibility findings
(P1-3, P1-5) degrade the experience rather than break it, and one of them
(P1-3) has a per-caller workaround already shipping on the screen where it
mattered most.

### P1 — systemic

| id | finding | where |
|---|---|---|
| **P1-1** | One shared widget serves two semantics; `_TagsPill` is a modal-opening command in an exclusive row, and emits an identical semantics node to its four exclusive neighbours | §7, §16 · `card_filter_bar_widget.dart:192` |
| **P1-2** | `ChoiceChip.elevated`'s documented rationale is not what happens — `ChipThemeData.color` preempts the variant defaults — and the variant's only live effect is a **measured elevation-1 press shadow** (`#FF9FA2BF` unselected, `#FF000000` selected), a second depth mechanism AD-14 does not admit | §8 · `mx_pill_button.dart:100`, `app_chip_theme.dart:169-179` |
| **P1-3** | Selection rests on colour alone: **1.35:1** light / **1.43:1** dark, no checkmark, border removed when selected. Already recorded as P1 against W6 in `docs/wbs.md:10121-10126` and closed for one screen only; four groups still ship it | §9.4, §11 |
| **P1-4** | The focus ring is drawn around `RawChip`'s **48×48 tap-target box**, not the **33.4×34.0** painted pill — 7.3dp horizontal and 7.0dp vertical bleed on a short pill, at a different corner radius | §10 · `mx_focus_ring.dart:63-74` + `chip.dart:1487-1502` |
| **P1-5** | No pill group communicates exclusivity, and a multi-select control is semantically indistinguishable from four single-select ones | §21 |

### P2 — localized

| id | finding | where |
|---|---|---|
| **P2-1** | Nine badge-family labels ship three different radii (`pill` ×6, `md` ×1, `sm` ×2) | §5.2 |
| **P2-2** | A disabled pill's border resolves to the same colour as its fill, in both themes | §9.4, §13 |
| **P2-3** | In dark, `selected+disabled` (2.04:1 vs page) is **more** prominent than `selected` (1.56:1) | §9.4 |
| **P2-4** | The resting pill's boundary is a 1dp hairline at 1.24:1 / 1.14:1 — below WCAG 1.4.11's 3:1 for component identification | §12.1 |
| **P2-5** | Inside a Card, sheet or Dialog the pill's fill equals its ground (1.00:1), so the "paper pill on the page" model does not hold — one live case, Study options | §12.1 |
| **P2-6** | Duplicate state layer: `chip.dart:1427` zeroes only `hoverColor`, so `ThemeData.focusColor` (primary @10%) and `ThemeData.splashColor` (primary @12%) still paint **on top of** MemoX's own composited focus and press washes | §12.2 |
| **P2-7** | The app's only `ActionChip` uses the `avatar` slot and therefore renders 15.0 / 2.0 where every pill renders 13.0 / 4.0 | §14 |
| **P2-8** | Three of four pill groups have no group `Semantics` label; only Progress introduces its choice | §21, §22 |
| **P2-9** | Four groups express the same 8dp gap three different ways, with no shared owner | §22 |

### P3 — polish / debt

| id | finding | where |
|---|---|---|
| **P3-1** | `RawChip`'s 48dp **width** floor is undeclared in MemoX tokens, and is what produces P1-4's horizontal bleed | §15 |
| **P3-2** | The 1.0dp border width is Flutter's `BorderSide` default; nothing in `AppStroke` owns it | §15 |
| **P3-3** | The badge family has nine call sites and no shared primitive (must **not** be unified with the chip API) | §17 |
| **P3-4** | The tag strip's `Chip` announces `hasSelectedState` and is never selected | §17 | **ACCEPTED at M100.37:** `RawChip.selected` is a non-nullable `bool` (`chip.dart:930`, 3.44.8) handed to `Semantics` as-is, so every `Chip` carries the flag; the only fix is leaving `Chip`, which the owner-pinned delete affordance (P3-5) forbids.
| **P3-5** | The tag delete affordance is 33 × 48 — **an owner decision of 2026-08-26**, listed only so it is not "fixed" unknowingly | §20 |
| **P3-6** | `MxPillButton` re-metrics `chipTheme.labelStyle` to `labelMedium`, so the theme's `label-lg` size is dead for every pill — contradicting `tokyo-component-mapping.md` §5's MUST NOT | §26 |

---

## 30. Recommended future implementation plan

Ordered so that each step is independently verifiable, and so the two steps that
need an owner decision come after the ones that do not.

**Phase 1 — correct the record and remove the shadow (no visual change except the
press frame).**
1. Switch `MxPillButton` to the flat `ChoiceChip` constructor and add
   `pressElevation: AppElevation.none` to `buildChipTheme`. Fill, border, label
   and geometry are unchanged — proven by measurement, and provable again by
   dumping `ThemeData` before and after.
2. Rewrite the three notes that state the elevated rationale
   (`app_chip_theme.dart`, `mx_pill_button.dart`,
   `tokyo-component-mapping.md` §4) to say what actually governs the fill:
   `ChipThemeData.color` short-circuits `chipDefaults.color` at
   `chip.dart:1529-1531`.
3. Add the missing assertions: `Material.elevation == 0` at rest **and while
   pressed**, and a source-level pin that the constructor is the flat one. Without
   3, step 1 can silently revert.

**Phase 2 — fix the focus ring's rect.**
4. Give `MxFocusRing` the painted pill's box rather than the tap-target box. The
   cleanest shape is for the pill to place the ring *inside* the tap-target
   padding rather than outside it — but note `RawChip` supplies no hook for that,
   so this likely means the ring moves to wrap a `SizedBox`/`Align` sized to the
   painted chip, or `MxPillButton` stops relying on `MaterialTapTargetSize.padded`
   and supplies its own 48dp target. **Both options change which widget owns the
   48dp floor**, so measure before and after with `getRect` on the `Material`.
5. Add a golden (`chip_focus_light`) and a rect assertion.

**Phase 3 — close the state-matrix test gap (blocks nothing, enables everything).**
6. One rendered state-matrix test driving a real pointer and a real Tab across all
   ten states, reading fill, label, side, elevation and ring rect.
7. `chip_states_{light,dark}` goldens.
8. Widgetbook: `Group`, `On a card`, `Focused`.

**Phase 4 — the W6 decision (needs D1 below).**
9. Implement whichever selection signal the owner picks, at the **component**
   level, and remove the per-caller `icon: Icons.check` workaround from
   `progress_range_selector_widget.dart` so there is one answer.

**Phase 5 — semantics (needs D2 below).**
10. Group labels on the three groups that lack them.
11. Whatever `_TagsPill` becomes.

**Explicitly deferred:** `FilterChip` adoption (§18 — no callers), `ActionChip`
generalisation (§19 — one legitimate exception), a shared `MxBadge` (§17 — a
different audit's scope), the badge radius reconciliation (P2-1 — same), and
`P3-5` (already decided).

---

## 31. Files a future implementation would need to modify

Listed per phase so the parallel-worktree hazard is visible. **Nothing in this
list is touched by this branch.**

| phase | file | change |
|---|---|---|
| 1 | `lib/shared/widgets/mx_pill_button.dart` | constructor + doc |
| 1 | `lib/core/theme/components/selection/app_chip_theme.dart` | `pressElevation` + doc |
| 1 | `docs/design-system/tokyo-component-mapping.md` | §4 binding #4, table row :68, prose :179-184 |
| 1 | `test/core/theme/contracts/m3_role_bindings.dart` | add the constructor/pressElevation pin |
| 1 | `test/shared/widgets/mx_pill_button_theme_test.dart` | elevation assertions |
| 2 | `lib/shared/widgets/mx_focus_ring.dart` **or** `lib/shared/widgets/mx_pill_button.dart` | ring geometry — `MxFocusRing` has **exactly one caller** (`mx_pill_button.dart:89`), so its contract can change freely |
| 2 | `test/shared/widgets/mx_pill_button_focus_test.dart` | rect assertion |
| 2 | `test/shared/widgets/goldens/` | `chip_focus_light.png` |
| 3 | `test/shared/widgets/` | new state-matrix test |
| 3 | `test/shared/widgets/golden_specimens.dart` + `mx_components_golden_test.dart` | `chip_states` specimen |
| 3 | `widgetbook/lib/components/control_components.dart` | three use-cases |
| 4 | `lib/core/theme/components/selection/app_chip_theme.dart` | `showCheckmark` / `side` per D1 |
| 4 | `lib/features/progress/presentation/widgets/sections/progress_range_selector_widget.dart` | remove the per-caller workaround |
| 4 | every screen golden containing a pill — `card_list_*`, `tag_catalog_*`, `tag_filter_sheet_*`, `progress_*`, `trash_*` | regenerate **on Linux/WSL only** |
| 5 | `card_filter_bar_widget.dart`, `trash_filter_bar_widget.dart`, `study_options_section_widget.dart` | group `Semantics` |
| 5 | `lib/l10n/app_{en,vi}.arb` | group labels |
| 1–5 | `docs/wbs.md` | one entry per phase, same commit as the code |

**Golden warning, restated because Phase 4 will trip it:** a Windows checkout
cannot regenerate goldens — `--update-goldens` there writes PNGs CI rejects, and
it does so silently. Use WSL or a cloud session, and republish
`build/screen_gallery.html` at the existing pinned URL.

**Parallel-worktree hazard:** `mx_focus_ring.dart` has exactly one caller today
(`mx_pill_button.dart:89`), so Phase 2 is self-contained — but the button,
TextField and ListTile audits running in parallel may each want to adopt the ring,
which would change that. Phase 4 regenerates screen goldens, which every one of
those audits will also want. Sequence Phase 1 (self-contained, two files) first
regardless of what else lands.

---

## 32. Owner decisions genuinely required

Four, and only the first two block the plan.

**D1 — What is the pill's non-colour selection signal?** (§11, P1-3)
The trade is measured: a checkmark or a selected-only glyph costs **20.0dp of
reflow per toggle**; a selected border costs nothing but departs from
`_ChoiceChipDefaultsM3.side`, which is transparent when selected; a persistent
swapping glyph costs nothing but was rejected once on the grounds that two glyphs
read as two kinds of thing. Doing nothing leaves four groups violating W6 — a rule
the project has already enforced against itself once, by removing the pill from
Settings rather than fixing it. **This is a design-language decision, not an
implementation choice, and it determines whether Settings could ever come back to
pills.**

**D2 — What is `_TagsPill`?** (§7, §16, P1-1)
It opens a sheet (a command) and carries a persistent predicate state (a filter).
No existing primitive expresses both. The options are: leave it as a pill and
document the exception; give it a distinct visual so its row-mate status is
honest; or add a "filter entry" primitive. This decides whether §16's Pill-vs-Button
boundary is a rule or a guideline.

**D3 — Should the pill suppress Material's own focus and splash layers?** (§12.2,
P2-6)
Today the rendered focus wash is roughly double the 10% the token declares,
because `chip.dart:1427` zeroes only `hoverColor`. Suppressing the rest is
possible but has no `ChipThemeData` slot, so it would be an `InkWell`- or
`ThemeData`-level intervention affecting more than chips. Alternatively:
accept it and correct `AppStateOpacity`'s documentation to say the chip's
effective values differ. **Either is defensible; the current state — a documented
number that the render does not produce — is not.**

**D4 — Does `chipTheme` own the pill's label size, or does `MxPillButton`?**
(§26, P3-6)
`chipTheme` sets `label-lg`; every pill overrides it to `label-md`; the `label-lg`
rung is reached only by the tag strip's raw `Chip`. `tokyo-component-mapping.md`
§5 says a widget MUST NOT restate a theme geometry value. One of the two is wrong
and it is cheap to settle either way.

---

## Appendix — what this audit could not verify

| claim | why not |
|---|---|
| Android runtime rendering and performance | no device profile taken (§25) |
| RTL behaviour | the app ships no RTL locale; nothing to observe (§14) |
| Whether the press shadow is *visible* to a user | measured in the widget tree (`Material.elevation` 0.0 → 1.0, opaque `shadowColor`); not confirmed against a rendered pixel, because goldens capture resting frames only and this checkout cannot author goldens (§28.1) |
| Hover appearance on a real pointer | hover exists only on the web E2E channel, which no golden covers |
