# MxListTile / row system — deep audit

| | |
|---|---|
| **Status** | **IMPLEMENTED — superseded by M100.36** (Phase 4, commit `refactor(row)`). Measurements below are history; every P1/P2 disposition is in `docs/wbs.md` M100.36. Current contract: `docs/design-system/tokyo-component-mapping.md` §2 content/ and §7 |
| **Purpose** | Prepare the implementation pass for the row/list-item system: inventory what exists, measure what it renders, name what disagrees |
| **Scope** | `MxListTile`, `ListTileThemeData`, every row-like shared widget, every production list composition, their tests/goldens/Widgetbook entries. **Report only** — no fix is applied here |
| **Source of truth for** | — (an audit; the decisions still live in AD-15, AD-23, `tokyo-component-mapping.md`, `flutter-theme-design`) |
| **Depends on** | `docs/architecture.md` (AD-12, AD-13, AD-15, AD-23) · `docs/design-system/tokyo-component-mapping.md` · `design_system/components/mx.css` |
| **Flutter pinned at** | 3.44.8 (`058e0af2c2`, Dart 3.12.2) — every framework claim below is read from `/packages/flutter/lib/src/material/list_tile.dart` at that revision, not from published Material docs |
| **Updated by task** | (audit only — no WBS entry consumed) |
| **Last updated** | 2026-09-03 |

---

## 1. Executive verdict

**The row primitive is in good shape. The row *system* does not exist yet — what exists is four unrelated row grammars, and `MxListTile` is the smallest of them.**

Three findings carry the pass:

1. **`ListTileThemeData.textColor` silently flattens the subtitle.** The theme sets `textColor: scheme.onSurface` (`app_list_tile_theme.dart:23`). In Flutter 3.44.8 that value is assigned to the *title, the subtitle and the leading/trailing text style alike* (`list_tile.dart:876`, `:920`, `:934`). So every `MxListTile`, every `RadioListTile`, every `CheckboxListTile` and every `SwitchListTile` in the app renders its second line at the primary ink instead of `onSurfaceVariant`. Both written contracts say otherwise — `tokyo-component-mapping.md:102` records the binding as canonical-and-conformant, and `design_system/components/mx.css:272` spells `.mx-tile__subtitle{color:var(--color-text-secondary)}`. Nothing enforces either, so the drift is invisible: the row's text hierarchy is currently carried by 16px-vs-14px alone. **P1.**

2. **`MxListTile` is used seven times, and never in a scrolling list.** Every production list — decks, cards, search, progress, starter library — is a stack of `MxCard.raised` with an `onTap`. `MxListTile` lives only in sheets and two settings rows. The canonical row primitive is therefore not the app's row, and the app's actual row costs a `ClipRRect(antiAlias)` plus two blurred `BoxShadow`s per item (`mx_card.dart:634`, `:662`; `app_elevation.dart:152`) that a `ListTile` would not. This is not automatically wrong — a deck tile is genuinely richer than a `ListTile` — but nothing in the codebase states the boundary, so the choice is being made per screen. **P1.**

3. **A non-tappable row still takes keyboard focus and still draws the ring.** `ListTile` sets `canRequestFocus: enabled` (`list_tile.dart:988`), and `MxListTile` passes `enabled: isEnabled`, which defaults to `true` even when `onTap` is null. `study_mode_chooser_widget.dart:75` ships exactly that: an unavailable mode renders at full ink, is not announced as a button, is reachable by Tab, draws a 2dp `primary` ring, and does nothing on Enter. **P1 (accessibility).**

What is *right*, and should be protected rather than revisited:

- **`MxListTile`'s API is already closed** (AD-23) — `title / subtitle / leading / trailing / onTap / isEnabled / isSelected`, and not one visual escape hatch. `shared_api_closure_test.dart:176-185` enforces it. This is the least drift-prone shared widget in the repo.
- **Disabled resolves correctly**, and by a non-obvious route: the theme's `textColor` returns null in the disabled branch (`_IndividualOverrides.resolve`, `list_tile.dart:1222`), so the chain falls through to `defaults` which is the only link carrying `theme.disabledColor` — and `app_theme.dart:220` seeds that to `semantic.onDisabled`. Three separate decisions have to hold for this to work; none of them is tested together.
- **The overlay weights are one definition** (`AppInteractionStates.rowOverlay`), transcribed from the kit with the CSS selector named beside each value.
- **The two selection accents are measured, not accidental** — see §10.

Nothing here is a functional break for a sighted touch user today. The pass is about hierarchy, focus order, and deciding what a row *is*.

---

## 2. Row-system architecture map

```
Flutter 3.44.8
  ListTile ─── InkWell (hover/focus/splash slots only, no overlayColor)
     │      └─ Semantics(button:, selected:, enabled:)
     │      └─ SafeArea(minimum: contentPadding)     ← vertical padding lives HERE,
     │         └─ IconTheme.merge / IconButtonTheme     outside the height minimum
     │            └─ _ListTile (RenderBox: 56/72/88 minima)
     │
     ├── ListTileThemeData ......... lib/core/theme/components/content/app_list_tile_theme.dart
     │     └── compact override .... lib/core/theme/schemes/app_compact_scale.dart:73
     │
     ├── MxListTile ................ lib/shared/widgets/mx_list_tile.dart      (7 callers)
     ├── MxActionSheet._SheetRow ... lib/shared/widgets/mx_action_sheet.dart:149  (raw ListTile, 6 sheets)
     ├── MxRadioRows ............... RadioListTile   (settings ×2, study defaults, scheduler picker ×5)
     ├── MxCheckboxRow ............. CheckboxListTile (tag filter sheet)
     └── MxSwitchRow ............... SwitchListTile | hand-built Row (reminder toggle, import toggles)

Not ListTile at all — the app's actual list rows:
     ├── MxCard.raised + onTap ..... deck tile · card tile · progress deck row · search result
     │                               shell · starter template          (~12 sites)
     ├── MxCard.option / .flat ..... export format · import source     (radio-shaped)
     └── MxPressable ............... trash row · guess option · match tile · 2 disclosure rows
```

Two facts the map makes visible:

- **`MxCard` and `MxListTile` both claim the row role**, and only `MxCard` is used for lists that scroll.
- **The `Material(transparency)` shim is required at four different levels.** `MxRadioRows:98` and `MxSwitchRow:53` bake it in; `MxPressable:66` owns it structurally; but `MxListTile` does **not**, so `settings_reminder_entry_section_widget.dart:35` and `reminder_settings_section_widget.dart:92` hand-write it. That asymmetry is the only structural inconsistency inside the shared layer.

---

## 3. Flutter 3.44.8 `ListTile` — defaults, roles, and what MemoX overrides

`_LisTileDefaultsM3` (`list_tile.dart:1826-1857`), the M3 branch taken because `useMaterial3: true` is pinned (`app_theme.dart:144`).

### 3.1 Colour

| Property | Flutter 3.44.8 default | ColorScheme role | MemoX override | Reason / risk |
|---|---|---|---|---|
| `tileColor` | `Colors.transparent` | — | not set | Correct: the row inherits the ground it sits on. |
| `selectedTileColor` | **null**, and the fallback is `defaults.tileColor` = transparent (`list_tile.dart:824`) — M3 gives a selected row no fill at all | none | `semantic.surfaceMuted` (`#E9EBEE` / `#21274C`) | The theme comment argues this correctly: there is no M3 default to depart from. **Risk: it is a neutral grey while `MxCard`'s selected fill is `surfaceSelected` (`#E6E9FF`), an indigo tint. Two selection fills — see §10.** |
| `selectedColor` | `_colors.primary` | `primary` | `scheme.primary` (`=`) | Conformant. Pinned indirectly by `component_depth_and_state_test.dart:35-42` (≥4.5:1 against `selectedTileColor`). |
| `textColor` | **null** — the title colour arrives inside `titleTextStyle` (`onSurface`), the subtitle's inside `subtitleTextStyle` (`onSurfaceVariant`) | title `onSurface`, subtitle `onSurfaceVariant` | `scheme.onSurface` | **The finding.** A non-null `textColor` becomes `effectiveColor`, and `effectiveColor` is `copyWith`-ed onto the title (`:920`), the subtitle (`:934`) **and** `leadingAndTrailingTextStyle` (`:899`). Setting it to the title's colour therefore overwrites the subtitle's. See §1 and §17. |
| `iconColor` | `_colors.onSurfaceVariant` | `onSurfaceVariant` | `scheme.onSurfaceVariant` (`=`) | Conformant. |
| disabled text / icon | `theme.disabledColor`, supplied only by the *defaults* link of the resolve chain (`:874`, `:888`) | — | `app_theme.dart:220` seeds `disabledColor: semantic.onDisabled` | Works, but by three-step fall-through. Material's own fallback would have been a hardcoded `black38`/`white38` — the exact unseeded-default class `AppStateOpacity`'s header opens against. |
| `focusColor` | `ThemeData.focusColor` | — | `rowOverlay.resolve({focused})` = `primary @ 10%`, passed per-widget (`mx_list_tile.dart:123`) | `ListTileThemeData` has no slot; the unpack is documented. |
| `hoverColor` | `ThemeData.hoverColor` | — | `rowOverlay.resolve({hovered})` = `onSurfaceVariant @ 7%` (`:122`) | Matches `mx.css:266` exactly. |
| `splashColor` | `ThemeData.splashColor` | — | `rowOverlay.resolve({pressed})` = `primary @ 12%` (`:124`) | See risk below. |
| `highlightColor` (the *steady* press wash; `splashColor` is only the expanding ripple) | `ThemeData.highlightColor` | — | **not passed** — falls to `app_theme.dart:202`, seeded to the same `primary @ 12%` | Correct today by seeding, not by declaration. One edit to the global and every row's press changes with no row file touched. **P3.** |
| leading/trailing `IconButton` foreground | `IconButtonTheme` pushed by `ListTile` itself (`:891-897`), forced to `effectiveIconButtonColor` | — | inherited | A trailing `IconButton` inside a selected row turns `primary` whether or not the caller wants it. No production caller has one yet — latent. |

### 3.2 Geometry

| Property | Flutter 3.44.8 default | MemoX | Notes |
|---|---|---|---|
| `contentPadding` | `EdgeInsetsDirectional.only(start: 16, end: 24)` — **asymmetric** | `EdgeInsets.symmetric(horizontal: AppSpacing.lg /*16*/, vertical: AppSpacing.xs /*4*/)`; compact: horizontal `md` /*12*/ (`app_compact_scale.dart:73-79`) | Two departures: the end inset drops 24→16, and a vertical inset is introduced where M3 has none. Applied through `SafeArea(minimum:)` (`list_tile.dart:1010`, `safe_area.dart:121-127`), i.e. **outside** the height minimum — so it adds to the row height rather than being absorbed by it. |
| `minVerticalPadding` | `8` | `AppSpacing.sm` = `8` (`=`) | Restated, not changed. |
| `minTileHeight` | null → `_defaultTileHeight` = **56 / 72 / 88** (1-line / 2-line / three-line) at `visualDensity.standard` (`list_tile.dart:1503-1511`) | not set | **The design system does not own row height.** `tokyo-component-mapping.md:211` lists `buildListTileTheme` as owning "content padding, minVerticalPadding, shape" — height is absent, and `AppSizing` has no row token. The kit says 48 (`mx.css:264`, `--touch-target-min`); Flutter says 56. See §6. |
| `horizontalTitleGap` | `16` (hardcoded fallback, `list_tile.dart:1029`); effective gap adds `visualDensity.horizontal * 2` = 0 | not set | Matches `mx.css`'s `gap:var(--space-lg)` at a 24dp icon, and only at a 24dp icon — see §7. |
| `minLeadingWidth` | `24` | not set | With `AppIconSize.md` = 24 the two coincide; a 20dp (`mdCompact`) leading would be padded out to 24 and shift nothing, a 40dp (`lg`) one would push the title to 72. |
| title / subtitle alignment | `ListTileTitleAlignment.threeLine` → **`.center`** whenever `isThreeLine` is false (`list_tile.dart:138-146`) | inherited; `MxListTile` never sets `isThreeLine` | Leading and trailing are vertically **centred**, at every row height. At textScaler 2.0 a two-line/two-line row is ~201dp tall and the leading glyph floats in its middle rather than beside the first line. See §19. |
| `visualDensity` | `ThemeData.visualDensity` | `VisualDensity.standard`, pinned (`app_theme.dart:152`) | Deliberate — the web E2E channel must measure Android's geometry. |
| `dense` | `false` | not set, not exposed | There is no dense row in the app. |
| `isThreeLine` | `false` | never set | So the 88dp branch and `ListTileTitleAlignment.top` are dead code paths here. |
| `shape` | `RoundedRectangleBorder()` (square) | `RoundedRectangleBorder(AppRadius.md /*12*/)` | Governs the ink clip and the `selectedTileColor` fill. **Inside an `MxCard` (radius `AppRadius.lg` = 16) the row's ink rounds at 12 within a 16 corner** — visible on the settings reminder entry. |
| trailing reservation | `max(trailingWidth + gap, 32.0)` (`:1608`) | inherited | A trailing narrower than 16dp still reserves 32. |
| leading/trailing max height | `56` (`maxIconHeightConstraint`, `:1542-1549`) | inherited | A 48dp `MxIconButton` fits; anything taller is squeezed. |

---

## 4. `MxListTile` current contract

`lib/shared/widgets/mx_list_tile.dart:33-128`. Seven parameters, classified:

| Parameter | Class | Notes |
|---|---|---|
| `title` (`String`, required) | **semantic** | Already-localized. A `String`, not a `Widget` — this is what stops a caller styling it. |
| `subtitle` (`String?`) | **semantic** | Same. |
| `leading` (`Widget?`) | **composition** | The one open slot on the reading edge. |
| `trailing` (`Widget?`) | **composition** | Ditto. |
| `onTap` (`VoidCallback?`) | **behavioral** | Documented as "non-interactive without greying" — see the focus defect in §1/§11. |
| `isEnabled` (`bool`) | **behavioral + semantic state** | Greys and removes from focus order. |
| `isSelected` (`bool`) | **semantic state** | Non-nullable, unlike `MxCard.isSelected` which is tri-state. See §10. |

**Visual escape hatches: none.** No `padding`, `height`, `color`, `shape`, `border`, `iconSize`, `spacing` or `textStyle` parameter exists, and `shared_api_closure_test.dart` (`:220` colours, `:231` `EdgeInsets`, `:243` raw doubles, `:301` primitive getters) is what keeps it that way. This is the model the rest of the row family should be measured against, and three of them fall short of it:

- `MxRadioRows.contentPadding` is a public `EdgeInsetsGeometry` (`mx_radio_rows.dart:77`) — a real escape hatch, used by `settings_choice_section_widget.dart:110` to restate `AppSpacing.lg`, which is a value `tokyo-component-mapping.md:211` says the theme owns and a widget MUST NOT restate.
- `MxSwitchRow` hardcodes its title style to `bodyMedium` on one branch and `bodyLarge` on the other (`:59`, `:72`) — one widget, two type scales, decided by whether `announcedValue` is set.
- `MxActionSheet._SheetRow` re-derives the title style, the ink and the leading colour by hand (`:149-180`) rather than going through `MxListTile`.

**What the API cannot express**, and this is what pushes callers elsewhere: a rich trailing region, a multi-part body, per-row leading insets (the move sheet fakes tree depth with an outer `Padding`, `move_deck_sheet_widget.dart:167`), a `Widget` title, and a long-press.

---

## 5. Production row inventory

### 5.1 `MxListTile` — 7 call sites, all in overlays or settings

| Site | Args used | Bucket |
|---|---|---|
| `card_bulk_overlays_widget.dart:138` — bulk move target | leading·title·subtitle·onTap | C navigation |
| `move_deck_sheet_widget.dart:171` — move deck target | +`isEnabled` | C navigation, with refusal reason as subtitle |
| `reminder_time_row_widget.dart:45` — reminder time | title·subtitle·isEnabled·onTap | B control (opens a picker) |
| `settings_reminder_entry_section_widget.dart:37` — settings entry | +`trailing` chevron | C navigation |
| `study_direction_chooser_widget.dart:196` — direction | +`isSelected`, radio glyph as leading | D selectable |
| `study_mode_chooser_widget.dart:75` — mode | title·subtitle·onTap | C navigation |
| `trash_restore_target_sheet_widget.dart:181` — restore target | +`isSelected` | D selectable |

Coverage: `title` 7/7 · `onTap` 7/7 · `subtitle` 6/7 · `leading` 4/7 · `isSelected` 2/7 · `isEnabled` 2/7 · `trailing` **1/7**.

### 5.2 The app's actual list rows — `MxCard` + `onTap`

| Site | Recipe | Content |
|---|---|---|
| `deck_tile_widget.dart:72` | `.raised`, padding none | 4 stacked regions: head row (icon well · name · overflow `MxIconButton`), state region, action row (Study button + gauges), meta line |
| `card_tile_widget.dart:70` | `.raised`, `selectionTreatment: tint` | selection mark / state dot · front+back+tag chips · trailing due badge + flag |
| `progress_deck_row_widget.dart:51` | `.raised` | name + stats, trailing `ExcludeSemantics(MxIcon(chevron_right))` — a chevron re-created outside the row system |
| `search_result_shell_widget.dart:51` | `.raised`, padding none | leading icon · `Expanded(child)` · trailing north-east glyph |
| `starter_library_screen.dart:112` | `.raised` | template title + counts + add affordance |
| `study_home_deck_item_widget.dart:67` | `.raised`, **no onTap** | name + workload metrics + a nested Study button |
| `card_export_format_options_widget.dart:198` | `.option` | radio-shaped format choice |
| `card_import_source_step_widget.dart:196` | `.flat`, `isSelected` | radio-shaped source choice |
| `card_history_event_widget.dart:93` | `.tile`, not tappable | timeline event |

### 5.3 `MxPressable` rows — 5 sites

`trash_row_widget.dart:78` (selectable, full-bleed) · `guess_option_item_widget.dart:120` · `match_tile_widget.dart:140` · `card_details_section_widget.dart:61` and `card_editor_details_widget.dart:114` (two near-duplicate disclosure rows differing only in glyph and icon side — there is no `ExpansionTile` anywhere).

### 5.4 Rows that are neither

`tag_catalog_row_widget.dart:56` is a `Padding`→`Row` with **no tap at all**; only the trailing `MxMenuButton` is actionable, yet `tag_catalog_alignment_test.dart:204-223` asserts "whole row toggles" and a 48dp height — worth re-reading during the pass. `card_import_row_preview_widget.dart:60`, `card_import_mapping_row_widget.dart:41`, `progress_today_widget.dart:83`, `card_state_distribution_widget.dart:125` and `deck_summary_metrics_widget.dart:331` are read-only metadata rows.

### 5.5 Classification (§3 of the brief)

| Class | Members |
|---|---|
| **A · canonical list item** | `MxListTile` (7 sites) — but zero of them in a scrolling feature list |
| **B · control row** | `MxSwitchRow`, `MxCheckboxRow`, `reminder_time_row_widget` |
| **C · navigation row** | move/restore/bulk targets, settings reminder entry, study mode chooser, progress deck row, search result shell |
| **D · selectable row** | study direction chooser, trash restore target, `card_tile_widget` (multi-select), `trash_row_widget` (multi-select), `MxRadioRows`, `MxCard.option`, `MxCard.flat+isSelected`, `MxActionSheet` selected row |
| **E · dense metadata row** | tag catalog row, import preview/mapping rows, progress breakdown, distribution legend, deck meta line |
| **F · genuinely unlike ListTile** | `deck_tile_widget` (four regions, nested button, progress track on the base), `card_history_event_widget` (timeline with a continuous marker line), `match_tile_widget` (grid cell) |

**Class D is the problem class: eight implementations, four visual grammars.** Classes E and F are correctly not `MxListTile` and should stay that way.

---

## 6. Raw `ListTile` / `InkWell` inventory (§22)

| Site | Widget | Verdict |
|---|---|---|
| `mx_list_tile.dart:104` | `ListTile` | **A** — the sanctioned wrapper |
| `mx_action_sheet.dart:149` | `ListTile` | **B** — the only raw `ListTile` outside the wrapper. It re-derives `enabled`/`selected`/leading ink/title style by hand, and its title carries an explicit `bodyLarge` + colour, so it is already immune to the §1 subtitle bug and would *change appearance* if migrated. Migration is a real decision, not a cleanup |
| `mx_checkbox_row.dart:37` | `CheckboxListTile` | **C** — belongs to its own shared component |
| `mx_switch_row.dart:55` | `SwitchListTile` | **C** |
| `mx_radio_rows.dart:113` | `RadioListTile` | **C** |
| `mx_pressable.dart:68` | `InkWell` | **A** — the sanctioned ripple primitive |
| `mx_card.dart:727` | `InkWell` | **A** — the sanctioned surface primitive |
| `mx_breadcrumb.dart:189`, `:397`, `mx_breadcrumb_step.dart:135` | `InkWell` | **A** — not list rows (a breadcrumb line, an icon button, a text link) |
| `fill_answer_pieces_widget.dart:122` | `GestureDetector` | **A** — focus forwarding onto a card, no row semantics |
| `study_swipe_deck_widget.dart:184` | `GestureDetector` | **A** — horizontal drag only |

`ExpansionTile`, `AboutListTile`: **zero occurrences**. `InkWell` in `lib/features/`: **zero** — every feature-level ripple already goes through `MxPressable` or `MxCard`. `search_result_shell_widget.dart:16` records the last hand-rolled one being retired.

**No blanket ban is warranted.** The inventory is already clean; the one item genuinely worth a decision is `mx_action_sheet.dart:149`.

---

## 7. Vertical density findings

Derived from `_RenderListTile._computeSizes` (`list_tile.dart:1560-1694`) at `visualDensity.standard`, `dense: false`, `isThreeLine: false`, memox typography (title `bodyLarge` 16/24, subtitle `bodyMedium` 14/1.45 → 20.3), `minVerticalPadding` 8, `contentPadding.vertical` 4+4.

| Row shape | `_ListTile` box | + contentPadding | **Painted height** |
|---|---|---|---|
| title only, 1 line | `max(56, 24+16)` = 56 | +8 | **64 dp** |
| title only, wraps to 2 lines | `max(56, 48+16)` = 64 | +8 | **72 dp** |
| title + subtitle, 1 line each | 72 (not compact — ideal positions hold) | +8 | **80 dp** |
| title 2 lines + subtitle 2 lines | compact: `16+48+40.6` = 104.6 | +8 | **≈ 112.6 dp** |
| title 2 + subtitle 2, textScaler 2.0 | compact: `16+96+81.2` = 193.2 | +8 | **≈ 201.2 dp** |

Measured heights that exist in the suite and agree with the derivation: `settings_screen_geometry_test.dart:224-243` pins all 8 `RadioListTile`s ≥ `AppSizing.touchTarget`; `reminder_settings_layout_test.dart:150-168` pins both reminder rows ≥ 48; `progress_deck_row_geometry_test.dart:27-40` and `tag_catalog_alignment_test.dart:204-223` do the same for the card-based rows. **No test anywhere asserts an exact row height** — only floors.

Findings:

- **F7.1 · Nothing in the design system owns the row height.** 56/72/88 are Flutter's, unmentioned in `app_list_tile_theme.dart`, absent from `AppSizing`, and absent from the ownership table at `tokyo-component-mapping.md:211`. The kit disagrees outright: `mx.css:264` gives `.mx-tile` `min-height: var(--touch-target-min)` = 48 with `padding: var(--space-sm) var(--space-lg)` — a **48dp** floor with 8 vertical, against the app's **64dp** with 4 vertical. Neither is wrong; only one is written down. **P2.**
- **F7.2 · The vertical `contentPadding` of 4 is a structural dimension that reads as an optical one.** It is on the `AppSpacing` ladder, but it stacks *outside* a 56dp minimum that is not on any ladder, so the total (64) is not a token and cannot be reasoned about from either value. **P2.**
- **F7.3 · No arbitrary heights were found.** The brief asks for 46/50/52/54/60 — there are none. Every row-adjacent literal traces to a token: `AppSizing.touchTarget` 48, `AppSizing.controlCompact` 40, `MxBreadcrumb.compactLineHeight` 32, the deck due chip's 24. `deck_list_rhythm_golden_test.dart:160-167` already fails on any gap off `AppSpacing.scale`, with an empty allow-list.
- **F7.4 · Optical vs structural, for the pass:** the 56/72 minima are *structural* and should acquire a token; `_defaultTileHeight`'s 88 (three-line) is dead here; the compact-mode growth path is *font-dependent* and must stay derived — a fixed row height would truncate the 201dp case.

---

## 8. Horizontal alignment findings

`titleStart = leading == null ? 0 : max(minLeadingWidth, leadingWidth) + horizontalTitleGap` (`list_tile.dart:1607`).

| Row | Title x (standard / compact) |
|---|---|
| no leading | **16 / 12** |
| leading `AppIconSize.md` (24) | `16 + max(24,24) + 16` = **56 / 52** |
| leading `AppIconSize.mdCompact` (20) | `16 + max(24,20) + 16` = **56 / 52** (padded out — good) |
| leading `AppIconSize.lg` (40) | `16 + 40 + 16` = **72 / 68** |

- **F8.1 · A list mixing leading-icon and no-icon rows steps its text column by 40 dp.** Two live cases: `study_mode_chooser_widget.dart` (no leading) sits beside `study_direction_chooser_widget.dart` (radio glyph leading) in the same flow, and `trash_restore_target_sheet_widget.dart:181` renders "Top level" (no leading) among deck rows — but there the *whole list* is leading-less, so it does not jump. **Currently latent, structurally guaranteed.** The fix is either "a list decides once" or a reserved leading well, and the deck tile already chose the second (`deck_tile_geometry_test.dart:90-99` pins `workloadLeft - well.left = DeckIconArea.dimension + AppSpacing.md`). **P2.**
- **F8.2 · Trailing icons and trailing icon-buttons do not align with each other.** Trailing is positioned flush at the content-box right edge (`:1683`). A 24dp `MxIcon` therefore has its glyph 16 dp from the screen edge; a 48dp `MxIconButton` centres its 24dp glyph inside 48, putting it **28 dp** in. No `MxListTile` currently has an interactive trailing, so this is latent — but `progress_deck_row_widget.dart:122` and `search_result_shell_widget.dart` already place trailing glyphs on cards under a different rule. **P2.**
- **F8.3 · The horizontal gutter is *not* a mismatch.** `applyCompactScale` (`app_compact_scale.dart:73-79`) drops the row's `contentPadding.horizontal` to `AppSpacing.md` below `AppBreakpoints.compact`, which is exactly what `mxScreenGutter` (`mx_content_shell.dart:382-385`) returns. Rows and screen chrome share one left edge at 320 dp. **This is correct and should be protected by the pass** — `compact_scale_test.dart:70-84` already pins it.
- **F8.4 · `minLeadingWidth` and `horizontalTitleGap` are not represented in MemoX tokens.** 24 and 16 are Flutter's; 16 happens to be `AppSpacing.lg` and 24 happens to be `AppSpacing.xl`, but neither is stated, so a token move would not follow them. **P3.**
- **F8.5 · Selection does not shift anything.** Verified in both live patterns: `card_tile_widget.dart:100` swaps the mark in place with an identical footprint, and `trash_row_widget.dart:96-110` swaps glyphs inside a fixed `Padding`. `mx_list_tile_test.dart:197-202` pins that focus does not move the row. Good; keep.

---

## 9. Leading and trailing findings

### Leading

All four `MxListTile` leadings are icons. Two spellings, with **different state behaviour**:

| Spelling | Sites | Follows `selectedColor`? | Follows disabled? |
|---|---|---|---|
| bare `Icon(...)` | `card_bulk_overlays_widget.dart:139`, `move_deck_sheet_widget.dart:174`, `settings_reminder_entry_section_widget.dart:39` | **yes** — `ListTile` pushes an `IconTheme` (`list_tile.dart:889`) | **yes** |
| `MxIcon(..., ink:)` | `study_direction_chooser_widget.dart:200`; trailing at `settings_reminder_entry_section_widget.dart:44` | **no** — `MxIcon` always sets `Icon.color` explicitly (`mx_icon.dart:97-102`), overriding the ambient theme | **no** |

- **F9.1 · An `MxIcon` leading inside an `isEnabled: false` row will not grey.** No caller combines the two today, so this is a **latent trap, not a live bug** — and it is exactly what a migration pass would trip on. `AppInk.quiet` resolves to `onSurfaceVariant`, which *equals* the theme's `iconColor` at rest, so the divergence is invisible until a state changes. **P2.**
- **F9.2 · The study direction chooser reimplements `selectedColor` by hand** (`ink: isSelected ? AppInk.accent : AppInk.quiet`). Both mechanisms currently resolve to `primary`, so they agree by coincidence. The comment there argues the glyph is the *signal* and the tint reinforcement — a legitimate semantic reason, so this is **documented duplication, not drift**. **P3.**
- **F9.3 · Leading icons are all decorative-or-semantic; none is independently interactive.** A bare `Icon` self-excludes from semantics; `MxIcon` wraps in `ExcludeSemantics` unless a `semanticLabel` is given (`mx_icon.dart:104-106`). No leading anywhere takes a tap. Clean.
- **F9.4 · Baseline alignment:** leading is *centred*, not baseline-aligned (§3.2). At normal scale on a 64/80dp row this is imperceptible; at 2.0 it is not.

### Trailing

| Category | Where | Decorative? | Separately interactive? | Row also interactive? |
|---|---|---|---|---|
| chevron | `settings_reminder_entry_section_widget.dart:44` (`MxListTile`); `progress_deck_row_widget.dart:122` (`MxCard`) | yes, `ExcludeSemantics` | no | yes |
| overflow menu | `deck_tile_widget.dart:149`, `trash_row_widget.dart:139`, `tag_catalog_row_widget.dart` | no | **yes** | deck: yes · trash: only while selecting · tag: **no** |
| icon action | `trash_row_widget.dart:131` (Restore) | no | yes | only while selecting |
| text button | `deck_tile_widget.dart` Study verb, `study_home_deck_item_widget.dart` | no | yes | study home card: **no**, deliberately |
| count / badge / status | `card_tile_widget.dart` due badge + flag | yes | no | yes |
| switch | `MxSwitchRow` | control | yes | tile variant: yes · announced variant: **no**, deliberately |
| progress | deck tile gauges | yes | no | yes |

- **F9.5 · The gesture arena is already tested where it matters.** `deck_tile_target_test.dart:45-62` proves a tap in the card's dead space opens the deck; `:72-82` proves opening the row menu does *not* also open it. This is the pattern a future `MxListTile`-with-interactive-trailing must reproduce, and nothing pins it at the primitive level. **P2 (test gap).**
- **F9.6 · No `MxListTile` has an interactive trailing today.** So the "row + IconButton" and "row + Switch" competing-activation risks the brief asks about are **not present in production** — but `ListTile` would happily create them, and it also force-colours a nested `IconButton` (§3.1). The pass should decide whether `trailing` is allowed to be interactive at all before a caller discovers it can be.
- **F9.7 · A trailing `Text` would render at `labelSmall`** — 11 px, weight 500 (`_LisTileDefaultsM3.leadingAndTrailingTextStyle`), recoloured to `effectiveColor`. Below anything this app uses for readable text. No caller does it yet. **P2, latent.**

---

## 10. Selected-state matrix

| Pattern | Fill | Edge | Text / glyph | Semantics |
|---|---|---|---|---|
| `MxListTile.isSelected` | `semantic.surfaceMuted` — **neutral grey** | none | title **and subtitle and leading/trailing** → `primary` | `ListTile` → `Semantics(selected:)` |
| `MxActionSheet` selected row | same (raw `ListTile`) | none | title colour is explicit (`AppInk.stated`), so it does **not** turn primary; a trailing check `MxIcon` in `primary` carries it | `Semantics(selected:)`, argued at `:151-154` |
| `MxCard.option` / `.flat` (`edge`) | none | `secondary` | unchanged | `Semantics(selected:)` tri-state |
| `MxCard` (`tint`) — card list | `semantic.surfaceSelected` — **indigo tint** | `secondary` | mark glyph swaps to `check_circle` in `AppInk.secondary` | `Semantics(selected:)` + an extra `Semantics(label:)` at `card_tile_widget.dart:69` |
| `trash_row_widget` | none | none | glyph swaps to `check_box_outlined` in `AppInk.secondary` | `Semantics(container: true, selected:)` |
| `MxRadioRows` | Material's radio | — | radio dot | `isChecked`, pinned at `settings_accessibility_test.dart:102-130` |

- **F10.1 · Two selected *fills* exist for the same idea.** `surfaceMuted` `#E9EBEE`/`#21274C` on rows; `surfaceSelected` `#E6E9FF`/`#2A3159` on cards. Light is the visible split: one is neutral grey, the other indigo. **Accidental as far as any document goes** — `app_list_tile_theme.dart:22-34` argues *against* `secondaryContainer` and for a muted tile, and `mx_card.dart` argues separately for `surfaceSelected`; neither references the other. **P1.**
- **F10.2 · Two selected *accents* exist, and this one is deliberate.** `primary` for the row's *label* (needs 4.5:1, and `component_depth_and_state_test.dart:35-42` pins it against `selectedTileColor`); `secondary` for card edges and selection glyphs (needs 3:1 as a non-text control, and dark `primary` measured 2.90:1 on `surface` for a border and 3.29:1 as a glyph — recorded at `mx_card.dart:424-426` and `trash_row_widget.dart:96-98`). **Do not collapse these.** The pass should write the split down as a rule, not remove it.
- **F10.3 · `MxListTile` turns the *subtitle* primary too**, because `selectedColor` flows through the same `effectiveColor` as the title (§3.1). `mx.css:269` selects only `.mx-tile--selected .mx-tile__title`. **P2**, and it is the same root cause as F1.
- **F10.4 · The kit's selected row also bolds its title** (`mx.css:205`, `font-weight: semibold`). Flutter does not. Shape-plus-colour is the more accessible answer and the app already applies that principle to its glyphs. **P3 — worth a decision, not a defect.**
- **F10.5 · `isSelected` is non-nullable on `MxListTile` and tri-state on `MxCard`.** `MxCard`'s header argues the tri-state carefully: `false` announces "selectable but unpicked", `null` says nothing, and "a plain reading card must stay `null`, or every panel in the app turns into a poll" (`mx_card.dart:428-433`). `MxListTile` cannot express `null`, so **every** row announces a selection state, including the five that have no selection concept. **P2.**
- **F10.6 · Selection and navigation are conflated in exactly one place**, correctly: `trash_restore_target_sheet_widget.dart:181` selects on tap and confirms with a separate button. `study_direction_chooser` does the same. Nowhere does a tap both select and navigate.

---

## 11. Interaction / focus matrix

Resolved from `AppInteractionStates._overlay` (`app_interaction_states.dart:197-214`), ordered pressed → focused → hovered.

| State | `MxListTile` | `MxPressable` | `MxCard` |
|---|---|---|---|
| rest | none | none | none |
| hover | `onSurfaceVariant @ 7%` | `ThemeData.hoverColor` — same value, by seeding | `primary @ 4%` |
| pressed | `primary @ 12%` (splash) + `ThemeData.highlightColor` (same value) | `ThemeData.splashColor` / `highlightColor` — same value | `primary @ 10%` via `overlayColor` |
| keyboard focus | `primary @ 10%` wash **+ a 2 dp `primary` ring** | `ThemeData.focusColor` wash, **no ring** | `primary @ 10%` + ring, **gated to `FocusHighlightMode.traditional`** |
| selected | grey fill + primary ink | n/a (caller's) | edge and/or tint |
| selected + pressed | both paint; press wins the overlay | — | same |
| selected + focused | ring painted in *foreground* so `selectedTileColor` cannot cover it (`mx_list_tile.dart:29-32`) | — | ring drawn inside the state edge, both visible (`mx_card.dart:651-655`) |
| disabled | `onTap` nulled → no ink; text/icon → `semantic.onDisabled` | `onTap: null` → no ink, **no visual change at all** | n/a |

- **F11.1 · Three focus implementations, three answers.** `MxFocusRing` is the shared widget — and it has exactly **one** caller, `mx_pill_button.dart:89`. `MxCard` hand-rolls its own with a `FocusManager.instance.addHighlightModeListener` gate. `MxListTile` hand-rolls a third with **no gate**, so a row that receives focus from a pointer or a programmatic move on a touch screen draws a keyboard affordance. `MxCard`'s own comment names this as the M99.75 defect ("a keyboard affordance without a keyboard makes one control read as a different component"), and `mx.css:267` uses `:focus-visible`, not `:focus`. **P2.**
- **F11.2 · `MxPressable` has a focus wash and no ring.** ~1.15:1 against the surface, where WCAG 1.4.11 asks 3:1 — the exact measurement `AppStateOpacity.focus` documents. Five feature rows use it, including the trash row and the two disclosure rows. **P1 (accessibility).**
- **F11.3 · A non-interactive row is focusable** (§1, finding 3). `canRequestFocus: enabled`, and `isEnabled` defaults true. Live at `study_mode_chooser_widget.dart:75`. **P1.**
- **F11.4 · Pressed and hover are distinguishable** — different hue (`primary` vs `onSurfaceVariant`) and different alpha (12 vs 7). Ordering is asserted for `cardOverlay` at `app_interaction_states_test.dart:289-296`; **`rowOverlay` is never resolved with `{hovered, pressed}` anywhere**. **P2 (test gap).**
- **F11.5 · The kit has no `.mx-tile:active` rule at all.** The app's press state is an addition Flutter/Android requires and the desktop reference does not have. Correct call; record it so it is not "corrected" toward the kit later.
- **F11.6 · Only one state mechanism paints per channel.** No case was found of an ink overlay and a background change answering the same state. `MxCard` explicitly separates the state edge from the focus ring (`mx_card.dart:651-655`).

---

## 12. Divider / separator findings

| Site | Colour | `height` | Inset |
|---|---|---|---|
| `DividerThemeData` (`app_divider_theme.dart:17-19`) | `scheme.outlineVariant` | `AppStroke.hairline` (1) — `space == thickness`, adds no padding | none |
| `mx_radio_rows.dart:110` | **`semanticColors.borderDivider`** (`#F2F5F9`/`#252C55`) | 1 | edge to edge |
| `tag_catalog_screen.dart:194` | theme default | hairline | `indent: 56` (= `md + wellSize(32) + md`), `endIndent: 12` |
| `reminder_settings_section_widget.dart:112` | **`semanticColors.borderSubtle`** (`#E4E7EA`/`#272C48`) | hairline | wrapped in `Padding(horizontal: 16)` |
| `card_detail_summary_widget.dart:92` | `borderSubtle` | hairline | none |
| `card_import_preview_summary_widget.dart:125`, `:131` | `colors.outlineVariant` | **`AppSpacing.xs` (4)** | none |
| `card_import_confirm_step_widget.dart:81`, `card_import_preview_step_widget.dart:250` | `colors.outlineVariant` | **`AppSpacing.lg` (16)** | none |
| `card_editor_form_widget.dart:139` | theme default | **`AppSpacing.xl` (24)** | none |

- **F12.1 · Two genuinely different hairline colours are in play for row separators.** `borderSubtle` (= `outlineVariant`, per the M100.20 mapping) and `borderDivider`, which is a distinct, lighter value — and in light mode `borderDivider` `#F2F5F9` is *the page colour itself*. So `MxRadioRows`' list divider and the tag catalog's are not the same line. **P2.**
- **F12.2 · Three spellings of one colour.** Theme default, `context.colors.outlineVariant`, `context.semanticColors.borderSubtle`. The last two resolve identically today; only the first follows if the mapping moves. **P3.**
- **F12.3 · The divider theme's one decision is overridden at four of nine sites.** `space: hairline` exists so a divider "occupies exactly the line it draws"; four sites pass `height:` of 4, 16, 16 and 24 — using *spacing* tokens as vertical extents, which puts a gap decision inside a separator widget. **P2.**
- **F12.4 · No list stacks Card shadow + Card gap + divider + border.** Checked all 24 repeated-row containers. Every one picks exactly one strategy: `SizedBox` gaps between cards (deck `lg`, card `md`, progress `md`, search `sm`, starter `sm`, study home `md`), hairlines inside a single card (tag catalog, reminder, radio-rows `list`, import preview), or nothing (all 8 sheets). **This is the healthiest part of the row system.**
- **F12.5 · The gap value between cards is a per-feature decision** — `sm`/`md`/`lg` across six lists, all on the ladder, none stated as a rule. `MxRadioRowsShape` is the one place where the choice was turned into a named enum with the reasoning attached (`mx_radio_rows.dart:28-43`), and that is the model. **P2.**
- **F12.6 · Tokyo's restraint is already in effect.** `mx.css` gives `.mx-tile` no border and no divider whatsoever; separation is spacing plus the hover wash. The app is close to that and does not need to move further.

---

## 13. Card vs ListTile boundary

Stated as it should be, and as it currently is:

| | `MxCard` | `MxListTile` |
|---|---|---|
| **is** | a surface / container primitive | a content row primitive |
| owns | fill, radius, elevation, shadow, resting edge, internal padding | text roles, leading/trailing slots, row minima, ink |
| paints per instance | `ClipRRect(antiAlias)` + 2 `BoxShadow` (light) + 2 foreground `DecoratedBox` layers + `Material` + `InkWell` | nothing but the ink and (when selected) a fill |
| selection | edge `secondary` ± tint `surfaceSelected`, tri-state | fill `surfaceMuted` + primary ink, non-nullable |
| in production | ~12 tappable list rows | 7 sheet/settings rows |

- **F13.1 · Rows with their own fill/radius/border sitting inside a Card: one live case, and it is defensible.** `settings_reminder_entry_section_widget.dart:37` puts an `MxListTile` inside `MxCard.raised(padding: none)` with a `Material(transparency)` shim. There is no shadow-on-shadow (the row draws none) and no double border, but there **is a corner mismatch**: the row's ink and selected fill round at `AppRadius.md` (12) inside a card cornered at `AppRadius.lg` (16). Same arrangement at `reminder_settings_section_widget.dart:92`. **P2.**
- **F13.2 · Card-inside-card: none found.**
- **F13.3 · The reverse problem is the real one — Card recipes doing a row's job.** `progress_deck_row_widget.dart` is a name, a stat line and a chevron; `search_result_shell_widget.dart` is an icon, a body and a glyph. Both are `ListTile` shapes paying `ClipRRect` + 2 shadows per item to be cards. `deck_tile_widget` and `card_tile_widget` are **not** in this category — four regions and a nested progress track are genuinely beyond `ListTile`, and `CLAUDE.md`'s AD-17 warning about copying the wrong half applies.
- **F13.4 · The `Material(transparency)` asymmetry.** `MxRadioRows`, `MxSwitchRow` and `MxPressable` all own the shim; `MxListTile` does not, so two callers hand-write it. Whatever the pass decides, it should be the same answer for all four.

---

## 14. Settings-row findings

The Settings screen renders **four row grammars in one scroll**, each inside its own `MxCard.raised`:

| Section | Row | Grammar |
|---|---|---|
| Study defaults (`:166`) | `MxRadioRows` (`shape: block`, no dividers) + a text field + a Save button | `RadioListTile`, `contentPadding: zero` |
| Appearance (`:87`) | `MxRadioRows` (`shape: list`, dividers) | `RadioListTile`, `contentPadding: symmetric(horizontal: 16)` |
| Language (`:87`) | same | same |
| Reminders (`settings_reminder_entry_section_widget.dart:37`) | `MxListTile` + chevron, inside a `Material(transparency)` | `ListTile` with the theme's own padding |
| Reset (`settings_reset_section_widget.dart`) | a button, not a row | — |

- **F14.1 · The `block` / `list` split is a *decided* difference, not drift.** `MxRadioRowsShape` names both meanings and `settings_choice_section_widget.dart:98-104` records the owner review that settled it. Keep.
- **F14.2 · `contentPadding: symmetric(horizontal: AppSpacing.lg)` at `settings_choice_section_widget.dart:110` restates a value `tokyo-component-mapping.md:211` assigns to `buildListTileTheme`,** and it does so with a literal that will not follow `applyCompactScale` down to 12 at 320 dp — where every other row and the screen gutter do. **P2.** `settings_screen_geometry_test.dart:126-129` pins `rowLeft + AppSpacing.lg == labelLeft` at the default width, so the 320 dp case is unmeasured.
- **F14.3 · There is no navigation row grammar.** The reminders entry is the only one, and it needed a card, a shim and a hand-built chevron to exist. A second settings destination would copy all three.
- **F14.4 · Stale comment.** `settings_reminder_entry_section_widget.dart:31` says "Flat, like every other card in a scrolling body (D20). A raised card here would be the only shadow on the screen" — while the code is `MxCard.raised` and **all four sibling sections are also `.raised`**. The code is consistent; the comment is wrong and would mislead the pass. **P3.**
- **F14.5 · Should settings get a closed row composition?** The evidence says yes but not yet: four grammars, one navigation row, one hand-built chevron, and one padding escape hatch. But a `SettingsRow` built before §10 and §11 are settled would bake in today's selection and focus answers. **Sequence it after the primitive.**

---

## 15. Deck / library findings

`deck_tile_widget.dart` is four stacked regions inside one `MxCard.raised(padding: none)`:

| Region | Content | Row-system relevance |
|---|---|---|
| head (`:118`) | icon well · name + breadcrumb + labels `Column` · overflow `MxIconButton` | this **is** a `ListTile` shape — leading, two-line title, trailing action |
| state (`:169`) | status band or spacer | not a row |
| action (`:207`) | Study button (`AppSizing.controlCompact` 40, target padded to 48) + due/new gauges | not a row |
| meta (`:330`) | quiet metadata line | dense metadata row |

- **F15.1 · Do not force the deck tile into `MxListTile`.** Its geometry is pinned by `deck_tile_geometry_test.dart` (`:61-62` vertical rhythm, `:90-99` the well-derived text axis, `:134` the 24dp chip, `:139-140` the Study button) and its gesture arena by `deck_tile_target_test.dart`. This is class F and belongs to the feature — exactly what `mx_list_tile.dart:9-14` says ("`DeckTile` and `CardTile` are built **on** this… in their own features"), which is currently true only in spirit: neither is built on `MxListTile`.
- **F15.2 · The *head region* is the reusable part.** Icon well + two-line title + trailing menu is the shape `card_tile_widget`, `progress_deck_row_widget` and `search_result_shell_widget` all rebuild. If anything graduates into the shared layer, it is this — not the whole tile.
- **F15.3 · Multi-select is answered twice.** `card_tile_widget.dart:79` uses `MxCard(selectionTreatment: tint)` with an in-place mark swap; `trash_row_widget.dart:78` uses `MxPressable` with a glyph swap and no surface change at all. Both are argued in comments; neither cites the other. **P2.**
- **F15.4 · Naming does not track behaviour.** `progress_deck_row_widget` and `deck_tile_widget` are both tappable `MxCard.raised`; `study_home_deck_item_widget` is a non-tappable one. `_row` / `_tile` / `_item` are used interchangeably, and AD-15 constrains only the *bucket* (`items/`), not the suffix. **P3.**

---

## 16. Picker / option overlap findings

Six implementations of "pick one from a short list":

| Use case | Implementation |
|---|---|
| Theme / Language / new-card order | `MxRadioRows` → `RadioListTile` |
| Deck scheduler (5 sites) | `MxRadioRows` |
| Study direction | `MxListTile` + `isSelected` + a radio glyph as leading |
| Move / restore destination | `MxListTile` + `isSelected` (restore) or plain tap (move) |
| Export format | `MxCard.option` + `MergeSemantics` + `Semantics(inMutuallyExclusiveGroup:)` |
| Import source | `MxCard.flat` + `isSelected` + a check glyph |
| Action-sheet choice (sort, etc.) | raw `ListTile` + `selected` + a trailing check |

- **F16.1 · Three semantics answers for one interaction.** `RadioListTile` announces `isChecked` (pinned at `settings_accessibility_test.dart:102-130`); `MxListTile`/`MxCard`/`MxActionSheet` announce `selected`; only the export sheet adds `inMutuallyExclusiveGroup`. A screen reader user gets a different sentence per screen for the same job. **P1.**
- **F16.2 · Two of the seven do not look like the others.** Export uses `MxCard.option` with a `borderControl` resting edge — argued in an owner review (`mx_card.dart:371-374`: "an option *is* a control, and a control's edge says so before it is picked") — while import uses `MxCard.flat` with a hairline, argued in the same review as the deliberate counterpart. Both reasons are written down. **This is the one overlap that is genuinely settled; do not re-litigate it.**
- **F16.3 · Recommended future boundary** (for the owner to confirm, §28):
  - **Row-based option** when the choice is a *value in a settings-shaped list* — short label, no supporting visual, three-or-fewer lines. Today: theme, language, card order, scheduler, sort, direction.
  - **Card-based option** when the choice carries a *description, a badge or a recommendation the user must weigh*, or when the options render side by side. Today: export format, import source.
  - **Neither** for destinations. Move/restore targets are navigation, not selection, and `trash_restore_target_sheet_widget`'s two-step (select, then confirm) is the odd one out.
- **F16.4 · `MxCard.option` is being audited elsewhere.** Nothing here should be resolved without that pass; the boundary above is a recommendation, not a decision.

---

## 17. Typography findings

| Role | Resolved style | Source |
|---|---|---|
| `MxListTile` title | `bodyLarge` 16 / 24, w400 | `_LisTileDefaultsM3.titleTextStyle` |
| `MxListTile` subtitle | `bodyMedium` 14 / 1.45 — **recoloured to `onSurface`** | `defaults.subtitleTextStyle`, then `:934` |
| leading / trailing `Text` | **`labelSmall` 11 / 16, w500**, recoloured to `effectiveColor` | `defaults.leadingAndTrailingTextStyle` |
| `MxActionSheet` row title | `bodyLarge` + an explicit `AppInk` colour | `mx_action_sheet.dart:176` |
| `MxSwitchRow` label (tile variant) | **`bodyMedium`** | `:59` |
| `MxSwitchRow` label (announced) | **`bodyLarge`** | `:72` |
| `MxRadioRows` / `MxCheckboxRow` label | `bodyLarge` (inherited) | theme |
| card-based row titles | `bodyLarge` / `titleSmall` per feature | feature |

- **F17.1 · The subtitle is the same colour as the title.** Root cause and citations in §1 and §3.1. Consequence: `MxListTile`'s hierarchy is 16px-vs-14px alone, in a system whose kit, whose mapping table and whose `AppInk.quiet` all say the second line is the secondary ink. The suite would not notice — no test asserts a subtitle colour, and the three `mx_list_tile_*.png` goldens have it baked in. **P1.**
- **F17.2 · `MxSwitchRow` uses two type scales for one label.** `bodyMedium` on the tile branch, `bodyLarge` on the announced branch, and the difference is a *semantics* decision, not a visual one. **P2.**
- **F17.3 · A trailing `Text` would be 11 px.** Latent (§9). **P2.**
- **F17.4 · Weight count is healthy.** Rows use w400 (body) and w500/w600 (labels) and nothing else; `AppTypography` has one weight per role. No row was found where metadata items carry three different weights.
- **F17.5 · Truncation policy is stated and consistent.** `MxListTile` caps both lines at 2 with ellipsis (`:105`, `:112`), matching `mx.css:271-272`'s `-webkit-line-clamp: 2`, and the reason is written down (an unbounded subtitle pushes the trailing control off a 320dp screen at scale 2). Card-based rows each decide for themselves — `reminder_time_row_widget.dart:33-38` records having to move a value from `trailing` to `subtitle` because of it.

---

## 18. Stress and localization findings

Coverage that exists: `mx_stress_test.dart` renders every shared widget at **320 × 640, textScaler 2.0, Vietnamese-length copy, light and dark**, asserting no overflow (`:83-89`) and `meetsGuideline(androidTapTargetGuideline)` (`:104`). Screen-level equivalents exist for settings (`settings_screen_geometry_test.dart:246-286`), deck (`deck_tile_geometry_test.dart:148-189`), trash (`trash_geometry_test.dart:270-322`), tag catalog (`:225-237`), reminder (`reminder_settings_layout_test.dart:171-186`) and the direction chooser (`study_direction_chooser_layout_test.dart:140-205`).

Findings:

- **F18.1 · The stress specimen for `MxListTile` covers only the resting, enabled, unselected row** (`mx_stress_specimens.dart:289-299`). `MxPillButton` by contrast is stressed *selected* (`:258`). So there is **no 320 × 2.0 evidence for a selected or disabled row**, which are the two states whose extra ink and extra fill are most likely to fail contrast on a squeezed row. **P2.**
- **F18.2 · Row height at textScaler 2.0 reaches ~201 dp** for a two-line title with a two-line subtitle (§7) — roughly four rows on a 852 dp screen. `study_direction_chooser_layout_test.dart:140-205` already covers the equivalent case and passes because the subtitle ellipsises at 2 lines. **A fixed row height would break this**; the growth path must stay derived.
- **F18.3 · The leading glyph centres in a 201 dp row** (§3.2, `ListTileTitleAlignment.center`). Not overflow, so no test catches it, and no golden renders it.
- **F18.4 · Widths.** The suite tests 320 and the default 360/393. **375 and 412 are not tested anywhere**, and 375 is where `AppBreakpoints.isCompact` has just turned off — the first width running the roomy 16 dp gutter. Worth one probe. **P3.**
- **F18.5 · Vietnamese is covered; long localized labels beyond Vietnamese are not.** `mx_stress_test.dart` uses Vietnamese-length copy, which is the right proxy for the two shipped locales.
- **F18.6 · Touch target is preserved in every measured case** — every row test that measures height asserts ≥ 48, and `MxPressable` floors it structurally (`mx_pressable.dart:73`).

---

## 19. Accessibility findings

| Concern | Status |
|---|---|
| row `button` flag | `ListTile` sets it iff `onTap != null` (`:996`). Correct — but see F11.3 |
| `selected` flag | present on all six selection patterns (§10) |
| `enabled` flag | present |
| merged semantics | `ListTile` does **not** merge; nested trailing controls keep their own nodes. `card_tile_widget`, `trash_row_widget`, `search_result_shell_widget` add explicit `Semantics`/`ExcludeSemantics` per site |
| icon-only action labels | pinned by `trash_geometry_test.dart:324-341`; `MxIcon` self-excludes without a `semanticLabel` |
| focus order | **defect** — see below |
| touch target | pinned everywhere it is measured |

- **F19.1 · A dead row is in the focus order.** `study_mode_chooser_widget.dart:75` — full-strength ink, no `button` flag, Tab-reachable, ring-drawing, inert. `MxListTile`'s own doc (`:52-54`) argues that a null `onTap` means "not now" and should not grey; nothing argues it should still be focusable. **P1.**
- **F19.2 · `MxPressable` gives a keyboard user a ~1.15:1 wash and no ring** (F11.2). Five feature rows. **P1.**
- **F19.3 · Duplicate screen-reader actions: none found.** Every row with an interactive trailing either excludes the body (`trash_row_widget.dart:126-131`) or keeps the trailing outside a labelled wrapper (`deck_tile_widget.dart:149`). The one row where the label *replaces* children is `search_result_shell_widget.dart:51`, deliberately.
- **F19.4 · Three different sentences for one selection interaction** (F16.1). **P1.**
- **F19.5 · `MxSwitchRow`'s two variants are both correct and the reasoning is exemplary** (`:8-21`): the announced variant excludes the label and puts `Semantics(label, value)` on the switch so a reader hears the value in words, and the label is deliberately not a tap target because the row asks the OS for a permission. Pinned at `mx_switch_row_test.dart:31-56`.
- **F19.6 · `trash_row_widget`'s selection control is an `Icon`, not a `Checkbox`.** The row's `Semantics(selected:)` carries the state, so a reader is served — but there is no `isChecked`, unlike the radio rows. Consistent within itself, inconsistent across the app (F16.1).
- **F19.7 · No contrast defect was found in the row system.** Every row colour resolves through a role, and `settings_accessibility_test.dart:43-93` checks each one on the highest-density row screen.

---

## 20. Performance — static only

**No profiler was run. Android runtime profiling → DEFERRED.** The following are read from source.

- **F20.1 · Every card-based list row costs one `ClipRRect(Clip.antiAlias)` + two `BoxShadow`s.** `mx_card.dart:662` clips unconditionally (documented: the deck tile seats a progress track on the card's base); `mx_card.dart:634` → `shadowsFor` → `_lightShadows` returns two shadows, and `.raised` is `(floatY 9, blur 16, seatY 2, blur 2)` (`app_elevation.dart:148`). A 30-row deck list is 30 antialiased clips and 60 blurred shadows per frame in light mode. `MxListTile` costs none of this. **P2 — the number to take to a profiler first.**
- **F20.2 · `MxCard` adds two unconditional foreground `DecoratedBox` layers** whether or not they draw (`mx_card.dart:651-655`, argued as deliberate so focus never changes layout). Cheap, but ×N.
- **F20.3 · `Opacity(0.38)` per dimmed trash row** (`trash_row_widget.dart:75`). Flutter short-circuits at 1.0, so this allocates a `saveLayer` only for ineligible rows during selection mode — bounded, but it is a saveLayer per row in the worst case. **P3.**
- **F20.4 · `IntrinsicHeight` in repeated rows: two sites.** `card_history_event_widget.dart:80` (timeline, one per history event) and `match_board_grid_widget.dart:65` (one per grid row) — both are an extra layout pass per item. `card_export_format_options_widget.dart:149` and `card_import_source_step_widget.dart:154` also use it but over 2–4 fixed options. **P3.**
- **F20.5 · No `BackdropFilter`, no explicit `saveLayer`, no nested `Material` elevation, no `ShaderMask` in any row.**
- **F20.6 · Rebuild scope is narrow.** Row widgets are `StatelessWidget` except `MxListTile` and `MxCard`, both of which `setState` only on their own focus change. `MxCard` registers a `FocusManager` highlight listener **only when interactive** (`mx_card.dart:459-462`) — explicitly so "a list of fifty plain panels must not pay fifty listeners". `MxListTile` allocates a `FocusNode` per row unconditionally, interactive or not. **P3.**
- **F20.7 · `applyCompactScale` is memoised through an `Expando`** (`app_compact_scale.dart:46`) — without it, every `MemoxApp` rebuild on a narrow screen would re-notify every `Theme.of` dependent. Already correct.

---

## 21. Tokyo traits worth adapting

Each is justified by a *mobile* argument, not by Tokyo's authority.

| Trait | Where the kit says it | Why it is right here |
|---|---|---|
| **Restrained row chrome** — no border, no divider, no fill at rest | `mx.css:264` (`border:0;background:transparent`) | A list of 30 boxed rows is 30 competing edges on a 393 dp screen. The app is already close; F13.3 is where it drifts |
| **Low-noise separator language** — spacing and a hover wash instead of lines | no `.mx-tile` divider rule exists | Answers F12.1–F12.3 without inventing anything: one hairline value, used sparingly |
| **Secondary metadata is the secondary ink** | `mx.css:272` `.mx-tile__subtitle{color:var(--color-text-secondary)}` | This is F17.1's fix, and the kit already states it — the app is the one that departed |
| **Selected = the label takes the accent, on a muted ground** | `mx.css:268-269` | Cheap on a wide target: a full brand fill across a row reads as a button, which `app_list_tile_theme.dart:27-31` already argues |
| **`focus-visible`, not `focus`** | `mx.css:267` | Directly answers F11.1 — and `MxCard` already implements it |
| **A two-line clamp on both text slots** | `mx.css:271-272` | Already implemented, and the 320 × 2.0 reasoning is written down |

---

## 22. Tokyo web traits to reject

| Trait | Why not |
|---|---|
| **Desktop table density** | The app renders 4–8 rows per screen with a thumb, not 40 with a pointer |
| **`min-height: 48` as the row floor** (`mx.css:264`) | 48 is the *touch target* floor, not a comfortable reading row. The app renders 64/80, and shrinking to 48 would put a two-line row at the accessibility minimum with no margin. **Take the 8 dp vertical padding from the kit if anything; do not take its height** |
| **Hover-first feedback** | `mx.css` has a `:hover` rule and **no `:active` rule at all**. On Android press is the only state most users will ever see. Hover must stay correct for the Flutter Web E2E channel and must not drive the design |
| **Sidebar row geometry** (`.mx-sheet__row` variants) | A destination list in a fixed-width rail is not a scrolling mobile list |
| **32–40 px pointer targets** | Already rejected once, and recorded: `theme-architecture.md:242` — "Chiều cao nút 33/38/44 · Dưới sàn touch target 48. Tokyo là personality, a11y là hợp đồng — hợp đồng thắng" |
| **Exact CSS paddings** (`padding: var(--space-sm) var(--space-lg)`) | The intent transfers; the number must snap to `AppSpacing` and must survive `applyCompactScale`, which CSS has no equivalent of |
| **Multi-column row assumptions** | Every memox row is single-column below 600 dp, which is every shipped surface |
| **Large hover surfaces / scrollbar relationships** | No pointer, no scrollbar |
| **`.mx-tile--selected .mx-tile__title{font-weight:semibold}`** | Tempting, and listed at F10.4 as a *decision* rather than an adoption: a weight change on selection reflows the text box, which is the thing every other selection pattern in this app was carefully built not to do |

**No recommendation in this document is justified by "Tokyo does it".** Where the kit and the app disagree and the app is right (press states, row height, the compact gutter), that is recorded above rather than silently corrected toward the kit.

---

## 23. Widgetbook gaps

Global addons already supply **dark mode, text scale and a 320 × 568 viewport to every use case** (`widgetbook/lib/main.dart:73-125`), so no entry needs its own knob for those.

| Component | Present | Missing |
|---|---|---|
| `MxListTile` (`form_components.dart:358-410`) | title · subtitle · leading · trailing · enabled · selected, all knobs; `onTap` always set | a **long-text preset** (reachable only by typing); a named `selected + disabled` variant; `onTap: null` (the F11.3/F19.1 case is not reachable at all — `enabled` nulls the tap, `onTap` itself is not a knob) |
| `MxSwitchRow` (`:425-440`) | `on`, `announced variant` | disabled |
| `MxCheckboxRow` (`:441-454`) | `checked` | disabled; subtitle toggle |
| `MxRadioRows` (`:455-469`) | `enabled` | **`selected` is hardcoded to 1** — a reviewer cannot see the unselected group, or selected-while-disabled; no `shape` knob, so the `block`/`list` divider decision is invisible |
| `MxPressable` (`:274-300`) | `shape`, `enabled` | long content; nothing showing its missing focus ring |
| `MxActionSheet` (`overlay_components.dart:86-128`) | title, second-row enabled | **`isSelected`** — used in production and asserted in tests, absent from the catalogue |
| row-bearing screens | one scenario dropdown each | — (correct; screens should not grow knobs) |

Highest-value additions, kept small (the brief warns against combinatorial explosion):

1. `MxListTile` — an `onTap` knob separate from `enabled`, so the inert-but-focusable row is visible.
2. `MxListTile` — a long-title/long-subtitle preset.
3. `MxRadioRows` — make `selected` and `shape` knobs.
4. `MxActionSheet` — an `isSelected` knob.
5. Disabled knobs on `MxSwitchRow` and `MxCheckboxRow`.

The one thing that cannot be catalogued is **focus** — `widgetbook_coverage_test.dart:37-41` excludes `MxFocusRing` for exactly that reason, and the row primitives inherit the limitation. Focus belongs to tests and goldens, not to the catalogue.

---

## 24. Golden and test gaps

### Existing row goldens

`test/shared/widgets/goldens/` at 360 × 640, `TextScaler.noScaling`, locale `en`, both modes: `mx_list_tile_{light,dark}.png` (`mx_components_golden_test.dart:272-281`), `mx_list_tile_selected_*` (`:249-259`), `mx_list_tile_disabled_*` (`:260-271`). Compact: `compact_screen_*` at 320 × 568 with two resting rows. Plus `mx_action_sheet_*`. Screen-level: `settings_*`, `reminder_settings_*`, `trash_*`, `deck_list_*`, `card_list_*`, `card_list_selection_*`, `tag_catalog_*`, `library_search_*` at 393 × 852. One geometry golden with assertions: `deck_list_rhythm.png`.

### Recommended minimum future component set

Only if the pass changes what a row paints:

| Golden | Why it earns a slot |
|---|---|
| `list_tile_{light,dark}` | exists — keep |
| `list_tile_states_{light,dark}` | **new** — one image holding rest / selected / disabled / **selected+disabled**, so the intersection is visible in one comparison rather than across three files |
| `list_tile_stress` | **new** — 320 × 2.0, long title + long subtitle + leading + trailing, one mode. This is the only picture that would show F18.3 (the centred glyph in a 201 dp row) |

Do **not** add a focused golden: focus is arranged in a widget test, not a golden pump, and `mx_list_tile_test.dart:197-202` already asserts the ring's width and that it moves nothing. Feature-screen goldens stay responsible for whole-list composition.

**Regeneration constraint:** goldens are Linux-authored since M100.24 (`dart_test.yaml:13-21`); a Windows checkout cannot produce them, and `--update-goldens` there passes locally and fails CI silently.

### Test gaps, ranked

| Gap | Note |
|---|---|
| **`selected + focused` on `MxListTile`** | The rationale is written into the source (`mx_list_tile.dart:29-32`: the ring is drawn in the foreground *precisely because* `selectedTileColor` would cover a background one) and the assertion does not exist. `MxCard` has the twin test (`mx_card_interaction_test.dart:390`). **The single highest-value missing test.** |
| **`selected + pressed`, and press at all** | There is no press test on `MxListTile`. `app_interaction_states_test.dart:289-296` asserts press-beats-hover on `cardOverlay` only; `rowOverlay` is never resolved with `{hovered, pressed}` |
| **`disabled + selected`** | Two separate goldens, no intersection |
| **subtitle colour** | Nothing asserts it, which is why F17.1 is invisible. A source-level guard on the `textColor`/`subtitleTextStyle` binding would be better than a colour-value test — `tokyo-component-mapping.md:102` records the contract with no "guard AST" note beside it, unlike NavigationBar/TabBar/AppBar which have one |
| **`MxCheckboxRow` has no test file at all** | Tap, toggle, disabled, semantics, subtitle — all unasserted. Only a stress specimen and one Widgetbook knob |
| **focus on `MxPressable`, `MxSwitchRow`, `MxCheckboxRow`, `MxRadioRows`** | None sends a Tab |
| **dark mode for the three control rows** | `mx_switch_row_test.dart:11`, `mx_radio_rows_test.dart:10`, `mx_pressable_test.dart:12` pump light only; dark is reached only through the no-exception stress pass |
| **selected / disabled under stress** | `mx_stress_specimens.dart:289-299` stresses the resting row only |
| **`MxRadioRows` selected-while-disabled** | `mx_radio_rows_test.dart:60-83` asserts the lock but nothing about how the selected row looks or announces while locked |

### Tests that pin implementation rather than contract

- `component_depth_and_state_test.dart:49-55` — a tautology (`expect(scheme.primary, scheme.primary)`) documented as a guard. It asserts nothing executable.
- `component_depth_and_state_test.dart:39-41` — the failure message names `primaryAccent`, a token retired at M100.19. The assertion is right; the reason text is stale.
- Literal `48` instead of `AppSizing.touchTarget` at `tag_catalog_alignment_test.dart:169-170` and `reminder_settings_layout_test.dart:168`.
- `trash_geometry_test.dart:131-172` is an explicit known-violation pin, correctly labelled as one.

### Tests protecting good contracts — do not weaken in the pass

`shared_api_closure_test.dart` (the closed API, §4) · `architecture_boundary_test.dart:105-127` (shared/ knows no feature) · `theme_coverage_test.dart:95` (a rendered `ListTile` requires a `listTileTheme`) · `compact_scale_test.dart:70-84` (F8.3) · `mx_stress_test.dart:174-186` and `widgetbook_coverage_test.dart:31-54` (no row widget may be excluded from either gate) · `deck_tile_target_test.dart:72-82` (the nested control wins the arena).

---

## 25. Findings by severity

### P0 — none

No functional break, no architecture violation, no user-blocking accessibility failure was found.

### P1

| # | Finding | Where |
|---|---|---|
| P1-1 | `ListTileThemeData.textColor: onSurface` flattens the subtitle to the primary ink across `MxListTile`, `RadioListTile`, `CheckboxListTile`, `SwitchListTile` — contradicting `tokyo-component-mapping.md:102` and `mx.css:272`, unguarded and untested | `app_list_tile_theme.dart:23` |
| P1-2 | A non-tappable row is keyboard-focusable, draws the focus ring, is not announced as a button, and does nothing on Enter | `mx_list_tile.dart:115-118`; live at `study_mode_chooser_widget.dart:75` |
| P1-3 | `MxPressable` has a ~1.15:1 focus wash and no ring, against WCAG 1.4.11's 3:1 — five feature rows | `mx_pressable.dart:68` |
| P1-4 | Two selected *fills* for one meaning: `surfaceMuted` (neutral) on rows, `surfaceSelected` (indigo) on cards, with neither decision referencing the other | `app_list_tile_theme.dart:36` vs `mx_card.dart:542` |
| P1-5 | Three semantics answers for one pick-one interaction (`isChecked` / `selected` / `selected + inMutuallyExclusiveGroup`) | §16 |
| P1-6 | `MxListTile` is used 7 times and never in a scrolling list; the app's list row is `MxCard`, at a cost of one antialiased clip + two blurred shadows per item, with no rule stating the boundary | §5, §13 |

### P2

| # | Finding | Where |
|---|---|---|
| P2-1 | Row height (56/72/88) is owned by Flutter, absent from `AppSizing` and from the ownership table; the kit says 48 | `tokyo-component-mapping.md:211` |
| P2-2 | Focus is implemented three ways — `MxFocusRing` (1 caller), `MxCard` (gated), `MxListTile` (ungated) | §11 |
| P2-3 | `MxListTile.isSelected` is non-nullable, so all seven rows announce a selection state including the five with no selection concept | `mx_list_tile.dart:60` |
| P2-4 | `borderDivider` and `borderSubtle` are two different hairlines both used as row separators | `mx_radio_rows.dart:110` vs `tag_catalog_screen.dart:194` |
| P2-5 | The divider theme's `space == thickness` decision is overridden at 4 of 9 sites with spacing tokens used as heights | §12 |
| P2-6 | `settings_choice_section_widget.dart:110` restates `AppSpacing.lg` as a literal `contentPadding`, so it will not follow `applyCompactScale` down to 12 at 320 dp | `settings_choice_section_widget.dart:110` |
| P2-7 | An `MxIcon` leading will not grey in a disabled row (latent — no caller combines them yet) | `mx_icon.dart:97-102` |
| P2-8 | A trailing `Text` renders at `labelSmall` 11 px (latent) | `_LisTileDefaultsM3` |
| P2-9 | Trailing icons and trailing icon-buttons sit at different optical insets (16 vs 28) | `list_tile.dart:1683` |
| P2-10 | A mixed leading/no-leading list steps its text column by 40 dp | `list_tile.dart:1607` |
| P2-11 | An `MxListTile` inside an `MxCard` rounds its ink at 12 inside a 16 corner, and needs a hand-written `Material` shim `MxRadioRows`/`MxSwitchRow`/`MxPressable` all own internally | `settings_reminder_entry_section_widget.dart:35` |
| P2-12 | `MxSwitchRow` uses two type scales for one label | `mx_switch_row.dart:59` vs `:72` |
| P2-13 | Multi-select is answered twice (`MxCard` tint + mark swap vs `MxPressable` + glyph swap) | §15 |
| P2-14 | Selected row turns the **subtitle** primary too, where `mx.css:269` selects only the title | §10 |
| P2-15 | Test gaps: `selected+focused`, `selected+pressed`, `disabled+selected`, no `MxCheckboxRow` test file, no dark-mode test for three control rows, `rowOverlay` never resolved with `{hovered,pressed}` | §24 |
| P2-16 | Inter-card gap is a per-feature decision (`sm`/`md`/`lg` across six lists) with no rule | §12 |
| P2-17 | `MxRadioRows.contentPadding` is a public `EdgeInsetsGeometry` — the one visual escape hatch in the row family | `mx_radio_rows.dart:77` |

### P3

`MxListTile` does not declare `highlightColor` and relies on a global seed · `minLeadingWidth`/`horizontalTitleGap` are Flutter's numbers, not MemoX tokens · three spellings of one hairline colour · the study chooser reimplements `selectedColor` by hand (documented) · the kit's semibold-on-selected is unadopted (a decision, not a defect) · stale comment at `settings_reminder_entry_section_widget.dart:31` · stale token name in `component_depth_and_state_test.dart:39` · `_row`/`_tile`/`_item` suffixes used interchangeably · `MxListTile` allocates a `FocusNode` per row even when non-interactive · `Opacity(0.38)` saveLayer per dimmed trash row · `IntrinsicHeight` in two repeated-row builders · 375 and 412 dp are untested widths.

---

## 26. Recommended future implementation plan

Ordered by dependency, not by severity. Each step is independently shippable and independently verifiable.

**Step 1 — Fix the ink, then guard it.** Remove `textColor` from `ListTileThemeData` and let `titleTextStyle` / `subtitleTextStyle` carry their M3 roles (they already do, and both already name the right colour); keep `iconColor` and `selectedColor`. Then add the AST guard `tokyo-component-mapping.md` leaves off the two ListTile rows, matching the pattern NavigationBar/TabBar/AppBar already have. *This changes every row golden and every row-bearing screen golden* — regenerate on Linux. Closes P1-1, P2-14, F17.1.

**Step 2 — One focus answer.** Make `MxListTile` use `MxFocusRing` and gate on `FocusHighlightMode.traditional` like `MxCard`; give `MxPressable` the same ring. Add `canRequestFocus` tied to `onTap != null`, closing the inert-focusable row. Closes P1-2, P1-3, P2-2, F19.1, F19.2. **Do this before anything touches selection**, because the `selected + focused` test in Step 5 depends on it.

**Step 3 — Decide the selection grammar, then unify the fill.** This is an owner decision (§28) and must not be inferred. Once decided: one fill token for "picked", the measured `primary`-for-text / `secondary`-for-glyph-and-edge split preserved and written down as a rule, and `MxListTile.isSelected` widened to the tri-state `MxCard` already uses. Closes P1-4, P2-3.

**Step 4 — State the boundary in prose before moving any caller.** Write, in `flutter-theme-design` or as a new AD: when a list row is `MxListTile`, when it is `MxCard + onTap`, and when it is feature-owned. Then migrate only the rows the rule clearly reclassifies — `progress_deck_row_widget` and `search_result_shell_widget` are the two candidates. `deck_tile_widget`, `card_tile_widget`, `card_history_event_widget` and `match_tile_widget` stay where they are. Closes P1-6, F13.3.

**Step 5 — Close the test and catalogue gaps.** `selected + focused`, `selected + pressed`, `disabled + selected`, a `MxCheckboxRow` test file, dark-mode pumps for the three control rows, selected/disabled stress specimens, and the five Widgetbook knobs from §23. Add `list_tile_states_*` and `list_tile_stress` goldens.

**Step 6 — Row height and the separator language.** Introduce a row-height token, decide the 48-vs-56 question (§28), and settle on one hairline colour and one `space` policy. Fold the four `height:`-overriding dividers back onto the theme.

**Step 7 — Only then, the settings row composition.** A `SettingsRow` built before Steps 2 and 3 would bake in today's focus and selection answers.

**Explicitly not in scope for the pass:** the picker/option boundary (§16) belongs to whoever is auditing `MxCard.option`; `mx_action_sheet.dart:149`'s raw `ListTile` should be left alone until Step 1 lands, because it is currently immune to P1-1 by virtue of its explicit styling and migrating it would *change* its appearance rather than preserve it.

---

## 27. Files the implementation pass would touch

**Theme and shared (the primitive):**
`lib/core/theme/components/content/app_list_tile_theme.dart` · `lib/core/theme/components/content/app_divider_theme.dart` · `lib/core/theme/schemes/app_compact_scale.dart` · `lib/core/theme/foundations/app_sizing.dart` (a row-height token) · `lib/core/theme/states/app_interaction_states.dart` (only if Step 3 changes a selection role) · `lib/shared/widgets/mx_list_tile.dart` · `lib/shared/widgets/mx_pressable.dart` · `lib/shared/widgets/mx_focus_ring.dart` · `lib/shared/widgets/mx_radio_rows.dart` · `lib/shared/widgets/mx_switch_row.dart` · `lib/shared/widgets/mx_checkbox_row.dart` · `lib/shared/widgets/mx_action_sheet.dart` (Step 1 aftermath only)

**Feature callers (Steps 3–4 only):**
`lib/features/settings/presentation/widgets/sections/settings_choice_section_widget.dart` (P2-6) · `.../sections/settings_reminder_entry_section_widget.dart` (P2-11, P3 comment) · `lib/features/reminder/presentation/widgets/sections/reminder_settings_section_widget.dart` (P2-11) · `lib/features/study/presentation/widgets/overlays/study_mode_chooser_widget.dart` (P1-2) · `lib/features/progress/presentation/widgets/items/progress_deck_row_widget.dart` and `lib/features/search/presentation/widgets/items/search_result_shell_widget.dart` (Step 4 candidates) · `lib/features/card/presentation/screens/tag_catalog_screen.dart` and `lib/features/card/presentation/widgets/items/tag_catalog_row_widget.dart` (P2-4, and the "whole row toggles" claim in §5.4)

**Tests:**
`test/shared/widgets/mx_list_tile_test.dart` · `test/shared/widgets/mx_pressable_test.dart` · `test/shared/widgets/mx_radio_rows_test.dart` · `test/shared/widgets/mx_switch_row_test.dart` · **new** `test/shared/widgets/mx_checkbox_row_test.dart` · `test/shared/widgets/mx_stress_specimens.dart` and `mx_stress_selection_specimens.dart` · `test/shared/widgets/mx_components_golden_test.dart` · `test/core/theme/components/component_depth_and_state_test.dart` (stale token name) · `test/core/theme/states/app_interaction_states_test.dart` (`rowOverlay` press-beats-hover) · `test/core/theme/schemes/compact_scale_test.dart` · `test/features/settings/presentation/settings_screen_geometry_test.dart` (320 dp gutter after P2-6)

**Goldens (Linux only):**
`test/shared/widgets/goldens/mx_list_tile*.png` (3 pairs, +2 new) · `test/shared/widgets/goldens/compact_screen_*.png` · `test/shared/widgets/goldens/mx_action_sheet_*.png` · every `test/demo/goldens/` PNG showing a row: `settings_*`, `reminder_settings_*`, `trash_*`, `deck_list_*`, `card_list_*`, `card_list_selection_*`, `tag_catalog_*`, `library_search_*`, `deck_*_sheet_*`, `card_move_picker_*`, `progress_*`, `study_home_*` · `test/features/deck/presentation/goldens/deck_list_rhythm.png` · `test/design_preview/goldens/settings_*.png`

**Widgetbook:**
`widgetbook/lib/components/form_components.dart` · `widgetbook/lib/components/control_components.dart` · `widgetbook/lib/components/overlay_components.dart`

**Docs:**
`docs/design-system/tokyo-component-mapping.md` (§2 ListTile rows + the §5 geometry ownership table) · `docs/architecture.md` (a new AD only if Step 4's boundary is adopted as a decision) · `docs/wbs.md` · `docs/reviews/design-parity-checklist.md`

---

## 28. Owner decisions genuinely required

Five. None can be inferred from the code, and three of them gate the plan in §26.

**D1 · What does the app's row grammar actually look like — a card, or a line?**
Today the answer is "a card in every scrolling list, a line in every sheet". Both are defensible; only one can be the default. This gates Step 4, and it is the decision that determines whether `progress_deck_row_widget` and `search_result_shell_widget` move.

**D2 · One selected fill, or two?**
`surfaceMuted` (neutral grey, rows) and `surfaceSelected` (indigo tint, cards) currently both mean "picked". Collapsing them is a visible change to the card list and the sheets; keeping them needs a written reason, because the existing reasons do not reference each other. The measured `primary`-for-text / `secondary`-for-glyph split underneath is **not** in question — that one is settled and should stay.

**D3 · Is the row floor 48 or 56?**
The kit says 48 with 8 dp of vertical padding; Flutter gives 56 with the app's 4. Adopting 48 tightens every list by 16 dp per row and puts a two-line row at the accessibility minimum. This is a density judgement about a mobile reading list and it is the owner's, not an audit's.

**D4 · May an `MxListTile` trailing be interactive?**
Allowing it means owning the gesture arena, the doubled semantics, and `ListTile`'s habit of force-colouring a nested `IconButton` to the row's text colour. Forbidding it means the settings navigation row and any future switch row need a different component. No caller does it today, so the decision is free right now and expensive later.

**D5 · Does a selected row change weight as well as colour?**
`mx.css:205` bolds the selected title. It is the most legible non-colour selection cue available, and it reflows the text box — which every other selection pattern in this app was deliberately built not to do (`card_tile_widget.dart:73-78`, `trash_row_widget.dart:96-98`).

**Deferred, not decided here:** Android runtime profiling of the card-per-row cost (F20.1) — the static count is 30 antialiased clips and 60 blurred shadows for a 30-row deck list, and that number deserves a profiler before it justifies any migration.
