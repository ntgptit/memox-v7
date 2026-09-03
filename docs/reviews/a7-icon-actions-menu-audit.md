# A7 — Icon actions / FAB / menu / dropdown deep audit

| | |
|---|---|
| **Status** | report only — no code, test, theme, Widgetbook or golden was changed |
| **Purpose** | Establish the Flutter 3.44.8 contract for `IconButton`, `FloatingActionButton`, `PopupMenuButton` and `DropdownButton`/`DropdownMenu`, compare it to what MemoX currently paints, and register what is worth fixing before the next pass touches this surface |
| **Scope** | `lib/core/theme/components/actions/app_icon_button_theme.dart` · `.../app_fab_theme.dart` · `lib/core/theme/components/overlays/app_popup_menu_theme.dart` · `lib/shared/widgets/mx_icon_button.dart` · `mx_fab.dart` · `mx_menu_button.dart` · `mx_dropdown.dart` · `mx_session_top_bar.dart` · `mx_content_shell.dart` · `mx_navigation_bar.dart` · `lib/app/shell/app_navigation_shell.dart` · `lib/core/theme/states/app_interaction_states.dart` · every production caller of the above under `lib/` · the tests and Widgetbook cases that cover them |
| **Audited against** | branch `claude/a7-icon-actions-audit-vnv9sz` @ `3207e7b7e0d3a2ecefa5e6a85fed48a65890ba6b` (**BASE_SHA**) · Flutter **3.44.8**, SDK source read at `packages/flutter/lib/src/material/{icon_button,icon_button_theme,button_style_button,floating_action_button,floating_action_button_theme,popup_menu,popup_menu_theme,dropdown,dropdown_menu,menu_anchor,app_bar,ink_well}.dart` fetched at the `3.44.8` tag |
| **Not in scope** | Token *values* below the ones cited · bottom-sheet theming (`app_bottom_sheet_theme.dart`) beyond the one structural fact it changes the verdict on · `MxActionSheet`'s own internal contract |
| **Last updated** | 2026-09-03 |

**Method note.** Composited colours are computed with the same model the
repository's own tests use — `Color.alphaBlend`/`Color.lerp` — from the palette
constants as they stand at `3207e7b7`. Contrast is WCAG relative luminance. No
Flutter binary is available in this environment (`flutter --version` fails, no
SDK checkout on disk), so nothing below was rendered — every visual claim is
either arithmetic on the composited pixel or a structural fact read directly
from source (a widget takes no such parameter, a class declares no such slot,
a file exists or does not). Where a claim would need a render to settle (does
this actually overlap on screen), it is written as a coverage gap to close,
not as a confirmed defect.

---

## 1. Executive verdict

The architecture is sound: one `IconButtonThemeData`, one `MxIconButton` with
no colour escape hatch (a `isFilled` param was added and removed **twice**,
per its own comment); one `FloatingActionButtonThemeData`, one `MxFab` with no
parameters beyond icon/label/callback; one `PopupMenuThemeData`, one
`MxMenuButton` used at all four of the app's overflow-menu sites; one
`MxDropdown` wrapping the one Material primitive it needs. The
`no_raw_widget` guard is doing its job — outside the four wrapper files
themselves, `lib/` contains exactly **one** raw `IconButton(` (a search
field's clear button, which correctly hand-replicates the accessibility
pattern) and **zero** raw `FloatingActionButton(`, `PopupMenuButton(`,
`showMenu(`, `MenuAnchor(`, `DropdownButton(` or `DropdownMenu(` calls.

**Correction record.** An earlier draft of this report registered two
additional P1s — an icon-button press/focus "accent leak" and a speculative
`MxDropdown` error-state gap. Both were checked against
`design_system/components/mx.css` (the actual design source of truth, not
read in the first pass) and against `CardTransferMapping`'s domain model,
after an automated PR review flagged both claims — neither holds up:
`.mx-iconbtn:active{background:color-mix(in srgb,var(--color-primary)
12%,transparent)}` (`mx.css:43`) is explicit — press is *supposed* to be
`primary` @ 12%, exactly what the code does, and the `iconOverlay` doc
comment I read that as contradicting only ever discusses hover. The
`MxDropdown` gap does not survive contact with `CardTransferMapping.assign`
(`card_transfer_mapping_model.dart:52–62`), which makes a duplicate
destination structurally unrepresentable, or with
`card_import_preview_step_widget.dart:288–292`, which already renders the
BR-169 aggregate error MemoX actually needs. Both are corrected in place
below (§4.1, §5.2, §7) rather than left as a stale first pass — see §7's
retracted-findings note for exactly what changed and why.

The one finding that does hold: a single miswired call site with an
outsized consequence. `tag_catalog_row_widget.dart`'s "Delete tag"
`MxMenuAction` does not set `isDestructive: true`. It is the one delete
action in the whole app — of four comparable sites — that renders in the
same ink as Rename. The widget exists specifically to make destructive rows
unmistakable (`_MenuRow`'s own logic: `isDestructive ? AppInk.error :
AppInk.stated`), and one caller does not use it.

Second, `MxDropdown`'s doc comment inaccurately describes a sibling widget:
it claims a field-anchored picker should use "Material's `DropdownMenu`,
which is themed" — `app_theme.dart`'s own comment and
`theme_coverage_test.dart`'s acknowledged blind spot both establish that
neither `DropdownButton` nor `DropdownMenu` has a customised theme slot in
this app. That claim is wrong regardless of whether an error slot is ever
needed (§7, P2-4).

**P0: none.** No contrast floor reachable by a user is broken, no control is
unreachable, nothing crashes. **P1: one** — the missing destructive flag,
systemic and cheap to close. The rest is coverage debt and one architectural
question (two overflow-menu surfaces, no documented rule for which to use)
worth an owner decision rather than a fix.

---

## 2. Inventory

Counts are exhaustive (`grep`/AST search over `lib/`, not a sample).

| Surface | Theme file | Widget file | Prod call sites | Raw-widget escapes |
|---|---|---|---|---|
| Icon button | `app_icon_button_theme.dart` (41 lines) | `mx_icon_button.dart` (124 lines) | 28 `MxIconButton(` | 1 — `mx_search_field.dart:206` |
| FAB | `app_fab_theme.dart` (67 lines) | `mx_fab.dart` (48 lines) | 1 `MxFab(` | 0 |
| Popup menu | `app_popup_menu_theme.dart` (69 lines) | `mx_menu_button.dart` (122 lines) | 4 `MxMenuButton(` | 0 |
| Dropdown | *none* (no `DropdownButtonThemeData`/`DropdownMenuThemeData` set) | `mx_dropdown.dart` (65 lines) | 2 `MxDropdown<` | 0 |
| AppBar / toolbar | — | `mx_content_shell.dart` (1 raw `AppBar(`) + `mx_session_top_bar.dart` (custom, non-`AppBar`) | every screen | 0 raw `AppBar(` outside the shell |

**Icon button call sites (28), by purpose:** overflow trigger (`more_vert`) ×4
(`deck_tile_widget.dart:149`, `deck_list_screen.dart:155,171`,
`trash_row_widget.dart:138` — note this last one is a raw `MxIconButton`
sitting beside a `MxMenuButton` on the same row, not one itself); close/cancel
×6 (`mx_session_top_bar.dart:164`, `trash_screen.dart:47`,
`card_import_screen.dart:226`, `card_editor_screen.dart:409` conditional,
`card_import_source_summary_widget.dart:94`, `card_tag_section_widget.dart:345`,
`card_selection_bar_widget.dart:136`); command (`search`, `tune`, `checklist`,
`select_all`, `check`, `add`, `edit_outlined`, `restore_outlined`,
`expand_less`/`more`) across the remainder. **Zero** destructive-tinted
`MxIconButton` — every delete/reset/destroy action routes through a menu, an
action sheet or `MxConfirmDialog`, never a standalone red icon button.

**FAB:** exactly one call site, `deck_list_screen.dart:208`, conditional on
`_mayCreate(parent)` (BR-59/64/66 — a `card`-typed deck holds no sub-decks and
gets no create FAB).

**Menu call sites (4), all `MxMenuButton`, matching the theme file's own
doc-comment claim of "four call sites":**

| Site | Actions | Destructive |
|---|---|---|
| `card_list_menu_widget.dart:37` (deck's card-list overflow) | Import (always) · Export (`if deckTotal > 0`) · Tag catalog (always) | none |
| `card_sort_control_widget.dart:38` (sort control) | one row per `CardListSort.values`, label-only | none |
| `tag_catalog_row_widget.dart:103` (per-tag row menu) | Rename · **Delete tag** | **missing** — see P1-1 |
| `card_selection_bar_widget.dart:189` (`_ActionMenu`, bulk overflow) | Move · Add tag · Flag · Unflag · Export · **Delete** | `isDestructive: true` ✓ |

**A second, separate overflow-menu mechanism exists and is not
`MxMenuButton` at all:** `showDeckActions` (`deck_actions_widget.dart:33`)
and `showLibraryMenu` (`library_menu_widget.dart:20`) open `MxActionSheet` via
`showModalBottomSheet`, themed by `app_bottom_sheet_theme.dart` — a
completely different surface (full-width sheet, not an anchored menu).
`showDeckActions` carries up to seven conditional rows including the app's
other destructive delete (`MxActionSheetActionVariant.destructive`). See
§7 finding P2-2.

**Dropdown call sites (2):** `card_import_preview_step_widget.dart:341`
(`MxDropdown<String>`) and `card_import_mapping_row_widget.dart:55`
(`MxDropdown<CardTransferField?>`, the nullable "Ignore this column" case) —
both inside the card-import wizard's column-mapping UI, the one place in the
app that asks a user to make several independent field choices in a row.

**AppBar / toolbar:** exactly one raw `AppBar(` construction in `lib/`
(`mx_content_shell.dart:217`), used by every screen shell. `leading`/`actions`
are pass-through slots; no feature builds `AppBar(` directly.
`mx_session_top_bar.dart` is a separate, non-`Scaffold.appBar` full-width bar
(the study session's top bar) carrying one `MxIconButton(isCompact: true)`
close action.

**Tests:** `MxIconButton` has the deepest coverage of the four — dedicated
assertions in `mx_form_components_test.dart`, `mx_accessibility_test.dart`,
goldens in `mx_components_golden_test.dart` (6 PNGs,
`test/shared/widgets/goldens/mx_icon_button_*`), a compact-scale golden and a
stress specimen. `MxMenuButton` has a dedicated `mx_menu_button_test.dart`
(4 tests) plus a `PopupMenu depth` theme-level group and a dedicated demo
golden (`card_overflow_menu_demo_test.dart`). **`MxFab` and `MxDropdown` have
no dedicated test file** — coverage for both exists only inline
(`mx_components_test.dart`'s `MxFab` group, `mx_stress_specimens.dart` /
`mx_stress_selection_specimens.dart`).

**Design doc:** `docs/design-system/tokyo-component-mapping.md` documents
IconButton's foreground role and both FAB slots (the latter pinned by
`m3_role_binding_guard_test.dart` as 2 of "five slots... FAB×2, Card,
AppBar×2"). **It contains no row for `PopupMenuThemeData` or for
`Dropdown`/`DropdownButton`/`MxDropdown` at all.**

---

## 3. Flutter 3.44.8 contract, read from SDK source

### 3.1 IconButton (`icon_button.dart`)

`_IconButtonDefaultsM3` (unfilled/standard variant, ` :1055–1159`):

| slot | rest | hover | pressed | focused | disabled |
|---|---|---|---|---|---|
| background | `transparent` | " | " | " | " |
| foreground | `onSurfaceVariant` | " | " | " | `onSurface` @ .38 |
| **overlay** | none | **`onSurfaceVariant` @ .08`** | **`onSurfaceVariant` @ .10`** | **`onSurfaceVariant` @ .10`** | none |
| shape | `StadiumBorder` | | | | |
| minimumSize | **40 × 40** | | | | |
| padding | `EdgeInsets.all(8)` | | | | |
| iconSize | 24 | | | | |
| side | `null` | | | | |

**M3's canonical role for a standard icon button's overlay is one colour for
all three interactive states — `onSurfaceVariant`.** There is no branch that
substitutes `primary` for a non-selected, non-toggleable icon button
anywhere in `_IconButtonDefaultsM3.overlayColor` (` :1085–1109`, read in
full — the only place `primary` appears is inside the `WidgetState.selected`
branch, for a *toggle* icon button, which MemoX's `MxIconButton` never uses:
it exposes no `isSelected`/toggle parameter at all).

**Painted body vs. touch target — the mechanism, not an assumption.**
`ButtonStyleButton.build` (`button_style_button.dart:578–614`) wraps the
`Material`+`InkWell` (sized to `minimumSize`, i.e. **40×40** by default) in
`_InputPadding`/`_RenderInputPadding`, which pads the **hit-test area only**
to `kMinInteractiveDimension` (48) when `tapTargetSize ==
MaterialTapTargetSize.padded` (the M3 default). The doc comment on
`_InputPadding` is explicit: *"increases the size of the button and the
button's tap target, but not its material or its ink splashes."* So a
default M3 `IconButton` paints a **40×40 ripple inside an invisible 48×48
hit zone** — the ripple does not fill the area a finger actually touches.

### 3.2 FilledIconButton / FilledTonalIconButton / OutlinedIconButton

Same 40×40/padding-8/icon-24 geometry; only the fill and its overlay ink
change. `FilledIconButtonDefaultsM3` (` :1172–1301`): background `primary`
(unselected+toggleable→`surfaceContainerHighest`), foreground `onPrimary`,
overlay `onPrimary` @ .08/.10/.10. `FilledTonalIconButtonDefaultsM3`
(` :1314+`): `secondaryContainer`/`onSecondaryContainer`, overlay
`onSecondaryContainer` @ .08/.10/.10. **MemoX constructs none of these three
variants anywhere** — confirmed, zero `IconButton.filled(`,
`.filledTonal(`, `.outlined(` in `lib/`.

### 3.3 FloatingActionButton (`floating_action_button.dart`, `_FABDefaultsM3` ` :775–833`)

| type | size | radius | icon |
|---|---|---|---|
| regular | 56 × 56 | **16** | 24 |
| small | 40 × 40 | 12 | 24 |
| large | 96 × 96 | 28 | 36 |
| extended | h 56 | 16 | 24 |

Colour pair: `foregroundColor: onPrimaryContainer`, `backgroundColor:
primaryContainer` (` :809–810`) — **not** `primary`/`onPrimary`; the FAB's
own canonical M3 pair is the container family, same as MemoX's binding (§4.2).
Elevation: `elevation: 6.0, focusElevation: 6.0, hoverElevation: 8.0,
highlightElevation: 6.0` (` :778–781`) — rest and focus equal, hover is the
odd one out at +2, press returns to rest. State washes: `splashColor:
onPrimaryContainer @ .1`, `focusColor: @ .1`, `hoverColor: @ .08` (` :811–813`)
— all keyed to the *container* foreground, consistent with the resting pair.

### 3.4 PopupMenuButton / PopupMenuItem (`popup_menu.dart`)

`_PopupMenuDefaultsM3` (` :1837–1879`): `elevation: 3.0`, `color:
surfaceContainer`, `shadowColor: scheme.shadow`, `surfaceTintColor:
transparent`, `shape: RoundedRectangleBorder(radius: 4)`, `menuPadding:
EdgeInsets.symmetric(vertical: 8)`, item padding `EdgeInsets.symmetric(horizontal: 12)`,
label `labelLarge` at `onSurface` / `onSurface @ .38` disabled.
`PopupMenuItem.height` defaults to `kMinInteractiveDimension` (48,
` :279`). A disabled item (`enabled: false`) additionally wraps its icon in
`IconTheme.merge(opacity: isDark ? 0.5 : 0.38)` (` :443–448`) — **this is a
real, themed disabled-item mechanism the framework provides**; nothing in
`MxMenuAction`/`MxMenuButton` exposes a path to it (§7, P2-1). The row's
`InkWell` (` :453–463`) sets no `overlayColor` of its own — it inherits the
ambient `ThemeData` fallback (`hoverColor`/`focusColor`/`highlightColor`/
`splashColor`), the same fallback ladder `app_theme.dart` seeds for every
untended control.

### 3.5 DropdownButton / DropdownButtonFormField / DropdownMenu (`dropdown.dart`, `dropdown_menu.dart`)

`DropdownButton` (M2-era, no `_DefaultsM3` class — it predates the M3
token-generation pass and is not migrated): `itemHeight` defaults to
`kMinInteractiveDimension` (48, `dropdown.dart:1011`); `isDense` (default
`false`) controls whether the closed row shrinks below that; no
`errorText`/error-border slot exists on `DropdownButton` itself.
`DropdownButtonFormField` (` :1800+`) is the M2 answer to a field-shaped
dropdown — it wraps a `DropdownButton` in a `FormField`/`InputDecorator`,
which is where `errorText`, a label and a bottom border would come from.
**MemoX uses neither** — `MxDropdown` wraps bare
`DropdownButtonHideUnderline(child: DropdownButton(...))`.

`DropdownMenu` (` dropdown_menu.dart`, the modern M3 combo widget) *does*
expose `errorText`, `label`, `hintText`, `helperText`, `enabled` directly
(` :198–237`) — it is a `TextField` + `MenuAnchor` composed as one field-and-menu
control, which is the primitive that would answer audit item 6's
"field-vs-menu" question if MemoX used it. **MemoX does not construct
`DropdownMenu` anywhere** (confirmed, zero matches).

---

## 4. Current MemoX contract

### 4.1 Icon button — `app_icon_button_theme.dart` + `mx_icon_button.dart`

| slot | value | vs M3 |
|---|---|---|
| background | none (ghost, unfilled) | = (matches standard `_IconButtonDefaultsM3`) |
| foreground (rest) | `onSurfaceVariant` | = |
| foreground (disabled) | `semantic.onDisabled` (named explicitly, not left to SDK's `onSurface @ .38`) | role = , value re-derived |
| **minimumSize** | `Size.square(48)` (`AppSizing.touchTarget`) | **M3 default is 40×40; MemoX states 48×48 as the painted `Material`/`InkWell` box itself** — the ripple fills the full 48dp target rather than sitting inside an invisible padded zone. This *exceeds* M3's own floor and is a deliberate, correct choice (comment: "so no screen can pass a smaller one — there is no parameter to pass") |
| shape | `RoundedRectangleBorder(12)` (`AppRadius.md`) | M3: `StadiumBorder` — tier translation, consistent with every other control |
| **overlay (hover)** | `onSurfaceVariant` @ **.08** (`AppInteractionStates.iconOverlay`) | = role, = alpha |
| **overlay (press)** | `primary` @ **.12** | M3's own role is `onSurfaceVariant` @ .10 — but MemoX's actual source of truth here is `design_system/components/mx.css:43`, `.mx-iconbtn:active{background:color-mix(in srgb,var(--color-primary) 12%,transparent)}`, which explicitly specifies the accent at this exact alpha. **Confirmed deliberate, not a defect** — a tier translation from M3's role, same status as the shape/radius rows above |
| **overlay (focus)** | `primary` @ **.10** | M3's role is `onSurfaceVariant` @ .10; `mx.css:44`'s per-component rule (`.mx-iconbtn:focus-visible`) specifies only the ring (`box-shadow`), not a background wash — so the per-component CSS neither confirms nor contradicts an accent wash on focus. `AppStateOpacity.focus`'s own comment attributes the 10% figure to "`mx.css`'s interaction-model header" (a cross-component convention, not this selector specifically), which is the same source `controlOverlay` (buttons) draws its focus wash from. **No finding** — nothing establishes this as wrong, and the app-wide convention is consistent |
| focus ring | `BorderSide(primary, AppStroke.focus)` only when focused | M3: no `side` at all — MemoX adds one because a wash-only focus cue measured 1.15:1 against the WCAG-1.4.11 3:1 floor (comment, ` :32–34`) — same justified pattern as `MxActionButton`'s filled family |

`isCompact` (`MxIconButton`): shrinks the **glyph** (`AppIconSize.mdCompact`
20 vs `AppIconSize.md` 24) via `constraints: BoxConstraints.tightFor(48, 48)`
+ `padding: EdgeInsets.zero`. The box stays 48×48 either way — confirmed by
the widget's own comment recording that a narrower box was tried and
reverted because Material's tap-target padding re-inflated it to 48 anyway.
**This directly answers audit item 1: MemoX's compact icon button never
drops under 48dp, in either the painted body or the hit target — it is one
box that never changes size, only its glyph does.**

### 4.2 FAB — `app_fab_theme.dart` + `mx_fab.dart`

| slot | value | vs M3 |
|---|---|---|
| background/foreground | `primaryContainer`/`onPrimaryContainer` | = M3 canonical exactly (both use the container pair, not `primary`/`onPrimary` — confirmed identical role, and pinned at source level by `m3_role_binding_guard_test.dart` per the design doc) |
| shape | `RoundedRectangleBorder(16)` (`AppRadius.lg`) | = M3's own regular-FAB radius (16), by coincidence of MemoX's corner scale rather than by copying the spec — `AppRadius.lg` is also the app's card/sheet radius, so the FAB happens to share a token with an unrelated surface (see P3-3) |
| elevation (rest/focus/hover/press) | flat `AppElevation.overlay` = **8** on all four | M3: 6/6/8/6 — MemoX is permanently at M3's *hover* level, and elevation never changes with state. Deliberately reasoned (comment: Android has no hover pointer to reach the M3 8; a single flat value "spends nothing on a state the release target cannot reach") |
| state washes | `onPrimaryContainer` @ .08/.10/.12 (hover/focus/press) | = role (container foreground), alphas re-derived from `AppStateOpacity` rather than M3's raw .08/.1/.1 — press is 2pp louder |
| icon size | unset → SDK default 24 | = |

`MxFab` takes exactly `icon`, `label` (doubles as tooltip + accessible name),
`onPressed` — no colour, shape or elevation parameter, matching
`MxActionButton`'s "no escape hatch" pattern.

**FAB placement / list clearance (audit item 4), verified structurally.**
`AppNavigationShell` owns one `Scaffold` with `bottomNavigationBar:
MxNavigationBar`; each screen's `MxContentShell` is a **second**, nested
`Scaffold` carrying the `floatingActionButton`. The outer `Scaffold`
subtracts `bottomNavigationBar`'s real height from the layout box it hands
its `body` (Flutter lays out `bottomNavigationBar` first and constrains
`body` to what remains, unless `extendBody: true` — which
`AppNavigationShell` does not set), so the inner `Scaffold`'s own bounds —
and therefore its own FAB's `endFloat` position — never overlaps the bottom
bar. This is correct and is exactly what the shell's own doc comment
describes for list content; the same mechanism happens to also clear the
FAB, though nothing states that explicitly. `DeckListSliverWidget` separately
reserves `_kListBottomInset = AppSpacing.fabScrollClearance` (`56 + 16 + 16 =
88`) plus the gesture-nav safe area at the bottom of the **populated** list
so the last row's own action is not covered by the floating button
(comment, ` :17–25`, citing the M4.10ag regression this fixes). **The empty
state does not get the same reservation** — see P2-3.

### 4.3 Popup menu — `app_popup_menu_theme.dart` + `mx_menu_button.dart`

| slot | value | vs M3 |
|---|---|---|
| color | `surfaceContainer` | M3: `surfaceContainer` — = (MemoX's own comment records this was the fix for an earlier `surface`/elevation-0 pass that lifted 0.00 L\* off the card underneath it) |
| elevation | `AppElevation.raised` = **3** | = M3's 3.0, numerically identical though arrived at independently (measured against AD-14's own depth floor, not copied from the spec) |
| shadowColor | `materialShadowColor(scheme)` — transparent in dark, `scheme.shadow` in light | M3: always `scheme.shadow` — MemoX's dark-mode suppression is the app-wide M100.35 pattern (§ elsewhere), consistent with `MxCard`/FAB |
| shape | `RoundedRectangleBorder(12, side: outlineVariant)` | M3: 4px radius, no border — deliberate tier translation + an added edge, consistent with the corner scale |
| label (rest/disabled) | `bodyMedium` at `onSurface` / `semantic.onDisabled` | = role, M3 uses `labelLarge` — a rung down, consistent with `MxListTile`'s row-not-control weighting per the theme's own comment |
| menuPadding | vertical `AppSpacing.sm` only | M3: vertical 8 (≈ same magnitude) |

`MxMenuAction`: `label`, `onSelected`, `icon?`, `isDestructive` (default
`false`), `isSelected` (default `false`). **No `isEnabled`/disabled field —
M3's own `PopupMenuItem.enabled` (with its themed 38%/50%-opacity dimming,
§3.4) has no path from this API at all.** See P2-1.

### 4.4 Dropdown — `mx_dropdown.dart`, no dedicated theme file

`MxDropdown<T>`: `value`, `options` (`List<MxDropdownOption<T>>`),
`onChanged` (`null` disables). Wraps `DropdownButtonHideUnderline(child:
DropdownButton<T>(isExpanded: true))`. No `isDense`, no `itemHeight`
override — closed row and open rows both default to `kMinInteractiveDimension`
(48). Items and the closed-value display share the exact same `Text(...,
maxLines: 1, overflow: ellipsis)` widget (no `selectedItemBuilder`
override), so long-text truncation is consistent between the trigger and the
open list — confirmed correct, no finding.

**No component theme exists for it.** `app_theme.dart`'s own comment (read
in full, ` :190–220`) states plainly: *"`DropdownButton` is a Material 2
survivor — `ThemeData` has no slot for it, only `dropdownMenuTheme` for the
unrelated `DropdownMenu`—so it resolves straight from these top-level
colours."* The top-level colours it falls back to are seeded from
`AppInteractionStates`/`AppStateOpacity` too (`hoverColor:
onSurfaceVariant @ hoverRow`, `focusColor`/`highlightColor`/`splashColor:
primary @ focus`/`pressed`), so a MemoX dropdown's interaction washes are
not literally unthemed — but two things are: **`canvasColor` (the open
menu's surface) and `disabledColor` are the two colours this fallback exists
to fix**, and neither has an error/validation slot of any kind.
`theme_coverage_test.dart` itself documents this as a known, accepted blind
spot in its own coverage mechanism (` :251–267`, quoted in full: *"A code
review found this while the guard reported full coverage, which is the
honest limit of the mechanism: it proves every widget that has a slot is
themed, and nothing about the ones that do not."*).

**`MxDropdown`'s own doc comment is inaccurate about its sibling.** Line 28-29
reads: *"A field-anchored picker with a text box is Material's `DropdownMenu`,
which is themed and needs no wrapper."* `dropdownMenuTheme` is a real
`ThemeData` slot, but `app_theme.dart` never sets it — so `DropdownMenu` is
exactly as unthemed as `DropdownButton`, not the themed alternative the
comment presents it as. See P2-4.

---

## 5. Findings by dimension

### 5.1 Caller-level (semantics/grammar)

- **P1-1** — one destructive menu action out of four comparable sites is not
  flagged destructive (`tag_catalog_row_widget.dart:113–118`).
- Back/close/command semantics (audit item 2): checked across every
  `leading:`/manual-close call site found in §2 — `card_editor_screen.dart`'s
  `_closeButton` correctly switches `arrow_back` (edit, real back navigation)
  vs `close` (create, dismiss a transient flow); `card_import_screen.dart`
  and `trash_screen.dart` correctly use `close` for "leave a modal-ish flow
  without committing," never for hierarchical back. **No inconsistency found**
  — this dimension is clean.
- Destructive icon-action grammar overall (item 3): consistently routed
  through `MxConfirmDialog`/`MxActionSheet` (destructive variant) or a
  flagged `MxMenuAction`, never a standalone red `MxIconButton` — because
  `MxIconButtonTone` has no destructive/error member at all (0 call sites
  need one today; see P3-2 for the gap this leaves if one ever does).

### 5.2 State-layer (accessibility)

- Icon-button press and focus overlay both resolve to `primary` rather than
  the neutral `onSurfaceVariant` hover uses. **Checked against the design
  source and confirmed deliberate, not a defect** — `mx.css:43`
  (`.mx-iconbtn:active{background:color-mix(in srgb,var(--color-primary)
  12%,transparent)}`) specifies the accent explicitly for press, and
  `AppStateOpacity.pressed`'s own comment already named `.mx-iconbtn:active`
  as an accent state before this report was written; the earlier draft of
  this audit missed that and over-read the `iconOverlay` doc comment's
  hover-only claim ("Hover is the neutral, not the accent") as covering all
  three interactive states. Composited for reference (`alphaBlend` over the
  page/AppBar ground, both modes) — no action implied, these are the correct
  pixels:

  | mode | hover (neutral) | press (accent, confirmed correct) | focus (accent, unresolved role but not contradicted) |
  |---|---|---|---|
  | light | `#E6EAEF` | `#DDE2F4` | `#E1E5F4` |
  | dark | `#121731` | `#1D2241` | `#191E3D` |

  `app_interaction_states_test.dart:103–118`'s own coverage
  (`overlay.resolve(pressed) isNotNull`) asserts non-null, never asserts
  *which* colour — so nothing pins the role either way, which is a coverage
  observation (§6) rather than a defect: the value the test would need to
  pin is the one `mx.css:43` already specifies, and the code already matches
  it.
- Disabled-item dimming exists in the M3 `PopupMenuItem` mechanism (icon
  opacity 0.38/0.5) but has no path from `MxMenuAction` — see P2-1.
- Focus ring on icon buttons: correct and measured (§4.1) — `AppStroke.focus`
  width `primary`, added specifically because the wash-only cue fails
  WCAG 1.4.11. No finding.
- Keyboard/focus traversal into a `PopupMenuButton`'s open menu and
  `DropdownButton`'s open list are both stock Material navigation
  (arrow-key highlight, `Escape` to dismiss) — MemoX overrides neither, so
  this is inherited correctly with no local risk. Not independently
  re-verified by render (no Flutter binary here); flagged as inherited-correct
  rather than confirmed-by-test.

### 5.3 Geometry (mobile)

- Icon button: 48×48 painted body = hit target, in every mode including
  `isCompact` — **exceeds** the M3 floor rather than merely meeting it
  (§4.1). No finding; recorded as the answer to audit item 1.
- FAB: 56×56 regular, radius 16 — matches M3 canonical exactly (§4.2).
- The automatic AppBar leading widget (`BackButton`/`CloseButton`, inserted
  by `AppBar._AppBarState.build` when `leading == null &&
  automaticallyImplyLeading`, `app_bar.dart:1010–1014`) is **not** a call
  site any `grep`/AST scan of `lib/` can see — it is constructed inside the
  framework. It **does** inherit `IconButtonThemeData` correctly (M3's
  `AppBar` routes its default leading through a plain `IconButton`, which
  resolves `IconButtonTheme.of(context)`), so the confirmed-correct 48dp
  floor and overlay behaviour (§5.2) both apply to it too — but it has
  **zero MemoX-specific test or golden coverage** despite being the single
  most-rendered icon button in the app (every screen without a manual
  `leading:` override uses it). See P2-6.
- FAB-vs-empty-state clearance: reserved for the populated list, not
  reserved for `MxEmptyState` (`Center` + `SingleChildScrollView`, no bottom
  padding token). See P2-3.

### 5.4 API surface (escape hatches, raw widgets)

- `MxIconButton`: no `Color`, no `ButtonStyle`, no `TextStyle` parameter.
  Clean.
- `MxFab`: no `Color`, `shape`, `elevation`. Clean.
- `MxMenuButton`/`MxMenuAction`: no colour escape; the one structural gap is
  the missing `isEnabled` on `MxMenuAction` (P2-1), not an escape hatch.
- `MxDropdown`: no colour escape. It also has no error/validation slot at
  all; investigated as a possible gap and found not needed for either
  current call site — the import wizard's `CardTransferMapping.assign`
  makes a duplicate mapping structurally unrepresentable and the wizard
  already renders the BR-169 aggregate error MemoX actually requires (§7
  retraction note, §10).
- Raw widgets outside the four wrappers: **exactly one**,
  `mx_search_field.dart:206`'s plain `IconButton(...)` for the clear (✕)
  action. It correctly sets `Icon(..., semanticLabel: ...)` by hand,
  replicating `MxIconButton`'s accessibility pattern — but it is invisible to
  `MxIconButton`'s own test suite and would silently diverge if that pattern
  ever changes centrally. See P3-1.

---

## 6. Coverage gaps (audit item 10)

| gap | detail |
|---|---|
| No `mx_fab_test.dart` | `MxFab` coverage is one inline group in `mx_components_test.dart` plus a stress specimen. No golden, no dedicated state assertions. |
| No `mx_dropdown_test.dart` | `MxDropdown` coverage is one stress specimen only. No golden, no disabled/error-state assertion (none of the latter two states exist to assert). This gap is already named by `theme_coverage_test.dart`'s own comment as an accepted mechanism limit — but that comment covers the *theming* blind spot, not the missing widget-level test file. |
| Automatic `AppBar` back/close button | No test constructs a bare `Scaffold(appBar: AppBar())` and asserts the auto-leading button's size/tooltip/overlay — the app's most common icon button has no direct regression coverage (§5.3). |
| `MxMenuAction` disabled state | Untestable because unimplemented (P2-1) — flagged as a gap in the audited dimension "menu item... disabled" (item 5), not a broken test. |
| FAB + empty state, 320dp × textScale 2.0 | No stress specimen or golden combines a visible `MxFab` with `MxEmptyState`'s centred content at the smallest width / largest scale the audit's own matrix (item 9) requires. |
| Widgetbook | `MxDropdown`'s catalogue entry (`form_components.dart:629–639`) has a fixed 3-option showcase and no knobs — cannot preview long-text truncation, disabled, or (if added) an error state interactively. `MxMenuButton`'s entry does cover `hasDestructive`; it cannot preview a disabled row because none exists to preview. |
| No PopupMenu Linux golden beyond the demo | `card_overflow_menu_demo_test.dart` is the only rendered popup-menu picture in the repo (added specifically because none of the four `PopupMenuButton` sites had ever been golden-rendered before, per its own comment) — it covers one of the four menus, not all four, and does not cover a disabled or long-label row. |

---

## 7. P0–P3 registry

### P0 — none

No contrast floor reachable by a user is broken; no control drops under
48dp; nothing is unreachable by keyboard or screen reader; nothing crashes.

### Retracted findings (verify-before-report, caught in review)

A first pass of this report registered two additional P1s. Both were
challenged by an automated PR review
([chatgpt-codex-connector](https://github.com/ntgptit/memox-v7/pull/436#discussion_r0))
with specific, checkable evidence; both challenges were verified directly
against source and hold. Recorded here rather than silently deleted, per
this audit's own evidentiary standard:

- **Icon-button press/focus overlay "accent leak."** The claim was that
  `AppInteractionStates._overlay`'s pressed/focused branches hardcoding
  `scheme.primary` violated a "hover is neutral" rule `iconOverlay`'s doc
  comment states. **Wrong** — `design_system/components/mx.css:43`,
  `.mx-iconbtn:active{background:color-mix(in srgb,var(--color-primary)
  12%,transparent)}`, explicitly specifies the accent for press at exactly
  this alpha, and `AppStateOpacity.pressed`'s own comment already named
  `.mx-iconbtn:active` as an accent state. The doc comment the first pass
  relied on ("Hover is the neutral, not the accent...") only ever discusses
  hover; reading it as a blanket "icon buttons are always neutral" rule was
  the error, not the code. Corrected in §4.1 and §5.2 — the current
  behaviour is deliberate and matches the design source exactly for press;
  nothing establishes focus as wrong either, so neither is a finding.
- **`MxDropdown` speculative error-state gap.** The claim was that the
  card-import mapping wizard "most plausibly" needs a per-row dropdown error
  state `MxDropdown` cannot provide. **Overreach** —
  `CardTransferMapping.assign` (`card_transfer_mapping_model.dart:52–62`)
  removes a field from any column that previously held it before assigning
  it to a new one, so two columns cannot ever both claim the same
  destination — the state a per-row error would flag is structurally
  unrepresentable. `card_import_preview_step_widget.dart:288–292` already
  renders the BR-169 aggregate error ("both required fields have a column")
  the wizard actually needs. No canonical document requires a row-level
  error, so this was a defect claim built on "plausible," not on a read
  business rule — exactly the failure mode this audit's own method note
  warns against for anything short of a structural fact. `MxDropdown`'s
  missing error slot remains a true structural fact (§4.4, §5.4); it is not
  a P1, and is not registered below at any priority — see §10 for the
  closed decision.

### P1 — systemic

**P1-1 · The one delete action out of four comparable menu sites is not
flagged destructive.**
`tag_catalog_row_widget.dart:108–119`'s `MxMenuAction(icon:
Icons.delete_outline, label: context.l10n.tagDeleteAction, onSelected:
onDelete)` omits `isDestructive: true`. `_MenuRow` (`mx_menu_button.dart:99,112`)
renders it in `AppInk.stated`/`AppInk.quiet` — identical ink to "Rename" one
row above it — where `card_selection_bar_widget.dart:120`'s bulk delete and
`deck_actions_widget.dart:130`'s sheet delete both correctly flag their
equivalent action. An irreversible action (deleting a tag catalog entry)
reads as no more consequential than a rename. **Recommendation:** add
`isDestructive: true` to the one call site. **Closure test:** a widget test
opening the tag row's menu and asserting the "Delete tag" row's `Text`/`Icon`
resolve to `AppInk.error`'s colour — the same assertion shape
`mx_menu_button_test.dart` already uses for its other three tests, extended
to a real production call site rather than only the widget's own API.

### P2 — local quality

**P2-1 · `MxMenuAction` has no disabled state; the framework mechanism it
would use is already themed and unreachable.**
`PopupMenuItem.enabled` dims the icon to 38%/50% opacity and swaps the label
to the theme's own disabled colour (§3.4) — `app_popup_menu_theme.dart:57–63`
already declares that disabled label colour. `MxMenuAction` has no
`isEnabled` field, so no call site can reach it; the app's only mechanism for
"sometimes unavailable" is conditional inclusion (`if (deckTotal > 0)` in
`card_list_menu_widget.dart`), which is also what the sibling
`MxActionSheet` surface does (`showDeckActions`'s conditional rows) — so this
is at least internally consistent, not a one-off oversight, and may be a
deliberate house style rather than a gap. **Recommendation:** an owner
decision on whether a "visible but disabled, with reason" row is ever wanted
here; if yes, add `isEnabled`/`disabledReason` to `MxMenuAction`. **Closure
test:** none until the decision is made; record the decision either way.

**P2-2 · Two structurally different overflow-menu surfaces coexist with no
documented selection rule.**
`MxMenuButton`/`PopupMenuButton` (anchored menu, 4 sites) and
`MxActionSheet`/`showModalBottomSheet` (full-width sheet, 2 sites —
`showDeckActions`, `showLibraryMenu`) both answer "give me a kebab of
actions, possibly with one destructive," themed by two unrelated files. Row
count does not predict which is used: the bulk-selection bar's 6-action menu
uses `MxMenuButton`; the single-deck actions' 7-action set (with more
conditional branches) uses `MxActionSheet`. Neither is wrong on its own —
this is a consistency finding (item 5/architecture priority), not an
accessibility one. **Recommendation:** an owner decision recording the rule
(e.g. "action sheet when an item can carry a second line of explanation or a
switch; anchored menu otherwise") so a sixth call site does not have to
re-derive it. **Closure test:** none — a documentation/decision outcome, not
a code change.

**P2-3 · FAB has no reserved clearance against `MxEmptyState`, unlike the
populated list.**
`DeckListSliverWidget` reserves `AppSpacing.fabScrollClearance` (88dp) plus
the gesture-nav safe area at the bottom of a populated list (`:17-25,72-80`)
specifically because an earlier milestone (M4.10ag) had the floating action
covering list content. `_emptyLevel`'s `MxEmptyState` (`Center` +
`SingleChildScrollView`, no bottom inset) gets no equivalent reservation, and
`_mayCreate(parent)` can be `true` while the empty state is showing (a root
level with zero decks). At 320×~600 + textScale 2.0 — the audit's own
required matrix (item 9) — the centred title/message/two-button column could
plausibly grow tall enough for its lower button to sit near or under the
floating `MxFab`'s 56dp+margin footprint. Not confirmed by render (no
Flutter binary in this environment); flagged as untested rather than broken.
**Recommendation:** a stress specimen combining the empty root-level state
with a visible FAB at 320dp/textScale 2.0, then a fix (bottom padding on
`MxEmptyState`'s scroll view, or a `bottomInset` parameter) only if the
specimen actually shows overlap. **Closure test:** the stress specimen
itself, added to `mx_stress_specimens.dart` or a screen-level golden.

**P2-4 · `MxDropdown`'s doc comment misdescribes `DropdownMenu` as themed.**
`mx_dropdown.dart:28–29` says a field-anchored picker should use "Material's
`DropdownMenu`, which is themed and needs no wrapper." `app_theme.dart`'s own
comment (§4.4) and `theme_coverage_test.dart`'s explicit acknowledgment both
establish that `dropdownMenuTheme` is never set — `DropdownMenu` is exactly
as unthemed as `DropdownButton` today. **Recommendation:** correct the
comment to state the actual fact (no theme exists for either; `DropdownMenu`
is the *better* primitive for a field-shaped picker because of its native
`errorText`/`label` slots, not because it is currently themed), or add
`dropdownMenuTheme` to `app_theme.dart` so the comment becomes true.
**Closure test:** none — documentation accuracy only.

**P2-5 · `MxFab` has no dedicated test file.**
Confirmed via `Glob` — no `mx_fab_test.dart` anywhere in `test/`. Coverage is
one inline group (`mx_components_test.dart`) plus a stress specimen.
Given `MxFab` has exactly one production call site but is the single most
visually prominent control on its screen (56dp, filled, elevated, centre of
the primary "create" journey), this is thinner coverage than its weight in
the app suggests. **Recommendation:** a small dedicated test file mirroring
`mx_menu_button_test.dart`'s shape (tooltip/semantics, disabled via
`onPressed: null`, geometry). **Closure test:** the file itself.

**P2-6 · The automatic AppBar back/close button has zero MemoX-specific
regression coverage.**
Established in §5.3: it inherits `IconButtonThemeData` correctly, but no
test in the repository constructs a bare `AppBar()` with implied leading
and asserts its size, tooltip, or overlay —
every existing icon-button test targets `MxIconButton` or the one raw
`IconButton` by name. **Recommendation:** one widget test pinning the
default `AppBar` leading button's tap target (≥48dp) and tooltip presence,
since it is the one icon button in the app no `grep`-based guard can ever
see. **Closure test:** the test itself.

### P3 — polish / debt

**P3-1 · The one raw `IconButton` escape hatch replicates `MxIconButton`'s
pattern by hand instead of using it.**
`mx_search_field.dart:206–214` builds `IconButton(tooltip: ...,
icon: Icon(Icons.close, size: AppIconSize.sm, semanticLabel: ...))` directly.
It gets the accessibility pattern right (label on the `Icon`, matching
`MxIconButton`'s own documented reasoning) and inherits the theme correctly,
so this is not a defect — but it is a second, hand-maintained copy of a
pattern `MxIconButton` exists to centralise, and it would not follow a
future change to that pattern automatically. **Recommendation:** low
priority; migrate to `MxIconButton` when the search field is next touched
for another reason, purely for the single-source-of-truth benefit.

**P3-2 · `MxIconButtonTone` has no destructive/error member.**
Zero current call sites need one (§5.1) — every destructive action already
routes elsewhere. Recorded so a future single-icon destructive action does
not reach for `IconButton(color: error)` directly, which is precisely the
pattern `mx_icon_button.dart:89–95`'s own comment says was tried and removed
twice for the (different) filled-variant case. **Recommendation:** none
now; note for the next `MxIconButton` API review.

**P3-3 · `app_fab_theme.dart`'s shape comment is inaccurate.**
` :25–28` describes `AppRadius.lg` as "the house corner... M3's default is
the 16dp large-component squircle this app does not use anywhere else" —
but `app_radius.dart` itself documents `lg` (16) as the radius for "Cards
and sheets," so the FAB is sharing a token with an unrelated, frequently-used
surface, not introducing a corner unique to itself. The *value* is right
(and happens to equal M3's own FAB radius); the *rationale comment* overstates
its uniqueness. **Recommendation:** trivial comment fix next time the file
is touched; not worth its own change.

---

## 8. Implementation order

1. **P1-1** (tag delete flag) — one-line fix, one new/extended test. No
   dependency on anything else.
2. **P2-6** (automatic back-button test) — cheap, standalone, closes the one
   real coverage gap on the app's most-rendered icon button.
3. **P2-5** (`mx_fab_test.dart`) — cheap, standalone.
4. **P2-3** (FAB/empty-state stress specimen) — write the specimen first;
   only touch layout code if it actually shows overlap once rendered.
5. **P2-1 / P2-2** (menu disabled state, two-surface consistency rule) —
   both are owner decisions before they are code changes; sequence after
   everything with a clear technical answer.
6. **P2-4 / P3-1 / P3-2 / P3-3** — opportunistic, bundle into whichever of
   the above changes happens to touch the same file.

---

## 9. Likely files

| change | file |
|---|---|
| P1-1 | `lib/features/card/presentation/widgets/items/tag_catalog_row_widget.dart`, a test near `mx_menu_button_test.dart` or a tag-catalog widget test |
| P2-1 | `lib/shared/widgets/mx_menu_button.dart` |
| P2-2 | `docs/architecture.md` or a new AD, no code change by itself |
| P2-3 | `test/shared/widgets/mx_stress_specimens.dart`, possibly `lib/shared/widgets/mx_empty_state.dart` |
| P2-4 | `lib/shared/widgets/mx_dropdown.dart` (comment only) |
| P2-5 | new `test/shared/widgets/mx_fab_test.dart` |
| P2-6 | a new or existing AppBar-level widget test under `test/shared/widgets/` |
| P3-1 | `lib/shared/widgets/mx_search_field.dart` |
| P3-2 | `lib/shared/widgets/mx_icon_button.dart` (comment/deferred note) |
| P3-3 | `lib/core/theme/components/actions/app_fab_theme.dart` (comment only) |

---

## 10. Owner decisions / deferred

- **Does the card-import mapping wizard need a per-row dropdown error
  state?** — investigated and resolved **no**, after an initial draft of
  this report speculatively raised it as a P1 without reading the domain
  model. `CardTransferMapping.assign` makes a duplicate mapping structurally
  unrepresentable and `card_import_preview_step_widget.dart:288–292` already
  renders the BR-169 aggregate error the wizard needs (retraction note,
  §7). `MxDropdown`'s missing error slot remains a true structural fact
  (§4.4) but is not a defect against any read requirement.
- **Is a visible-but-disabled menu row ever wanted, or is conditional
  inclusion the house style?** (P2-1) — both `MxMenuButton` and
  `MxActionSheet` currently agree on "hide, don't disable," so this may
  already be a settled (if undocumented) decision; worth a one-line
  confirmation in `docs/architecture.md` either way.
- **Two overflow-menu surfaces, no written rule for which to use.** (P2-2) —
  not a defect in either surface; a documentation gap that will keep costing
  a fresh judgement call per new call site until it is written down once.
- **`AppElevation.overlay`'s flat 8dp FAB elevation** (§4.2) is a deliberate,
  well-reasoned divergence from M3's 6/6/8/6 (Android has no hover to reach
  the M3 8dp step) — recorded here as verified-deliberate, not reopened.
- **`primaryContainer`/`onPrimaryContainer` FAB pair** (§4.2) is already
  pinned at source level (`m3_role_binding_guard_test.dart`) and canonical —
  no action.

---

*Generated by [Claude Code](https://claude.ai/code)*
