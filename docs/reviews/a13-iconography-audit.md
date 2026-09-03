# A13 — Iconography system deep audit

| | |
|---|---|
| Base commit | `3207e7b7` (`claude/a13-iconography-audit-bydn4s`, identical to `origin/main`) — *the dark card stops glowing, and elevation stops meaning two things* (M100.35) |
| Pinned SDK | Flutter **3.44.8** stable · Dart **3.12.2** (`environment.sdk: ^3.12.2`) |
| Scope | Every glyph the production app draws: `MxIcon`, `AppIconSize`, `IconTheme`/`iconTheme` slots, `MxIconButton`, every raw `Icon(` and every `Icons.*` reference under `lib/`, plus their Widgetbook stories, goldens and tests |
| Mode | **Report only.** No production, theme, test, Widgetbook, token, golden or design-system file was changed. This file is the entire diff |
| Method | **Static source audit.** Every call site was enumerated by a throwaway Python AST-ish scanner (balanced-paren argument extraction, comments stripped) run over `lib/`; contrast figures were computed from the palette constants with the WCAG 2.x relative-luminance formula and `Color.alphaBlend` semantics |

> **This container has no Flutter SDK.** `flutter`, `dart` and `~/.pub-cache` are
> all absent, so unlike the four sibling audits (`mx-list-tile`, `mx-action-button`,
> `mx-chip-pill`, `mx-text-field`) **no measurement harness was pumped and no
> widget tree was read.** Everything below is derived from source and from
> arithmetic over the committed palette. Where a claim needs a render or an SDK
> read to settle, it is not asserted — it is listed in the appendix as unverified,
> with the exact question and the call site that answers it.

---

## 1 · Executive verdict

**The icon system is sound at the token layer and inconsistent at the vocabulary
layer.** The two things a design system must own — *what colour may a glyph be*
and *what size may a glyph be* — are both closed sets, both enforced, and both
enforced by mechanisms that survive `dart format` (`AppInk` + `MxIconSize`, the
guard's `no_raw_icon_color` / `no_raw_style_escape`, and
`test/app/icon_ink_boundary_test.dart`, which walks balanced parentheses precisely
because the line-anchored rule had a blind spot). Of 232 `Icons.*` references
across 93 files, exactly **24** reach a raw `Icon(` widget, and of those only
**four** name a colour — every one of the four through `<AppInk>.resolve(context)`,
which is the one legal open spelling. That is a genuinely well-held boundary and
nothing in this audit asks for it to be tightened.

**What is not owned is meaning.** Nothing in the repo says which glyph means
*tag*, *flag*, *wrong*, *not selected*, *share* or *history*, and the result is
measurable: `Icons.circle_outlined` means two different things simultaneously on
the card list screen; the tag concept has two glyphs, one of them used once;
"Flag" and "Unflag" sit next to each other in one menu wearing two Material
codepoints that both draw an unfilled flag; the app's release target is Android
and its share affordance is the **iOS** share glyph; the "your answer was wrong"
mark is `Icons.close` in two study modes and `Icons.error_outline` in a third.
The colour of a glyph has an owner. The identity of a glyph has none.

**The one systemic accessibility finding is text scaling.** `applyTextScaling`
appears nowhere in `lib/` — not on `Icon`, not on `IconThemeData`, not in
`AppIconSize`'s doc as a rejected option. 36 of the 58 `MxIcon` call sites are
`MxIconSize.sm` (16 dp), and most sit inline beside a `bodySmall` (12 dp) or
`labelSmall` (11 dp) label. At `textScaler` 1.0 those glyphs are 1.33× their own
label; at 2.0 they are 0.67× it. This is not a token that needs a new value — it
is a decision the system has never made, in an app whose every other component
carries measured notes about `textScaler` 2.0 and 3.0.

**No P0.** No icon is unreachable, unlabelled where it must be labelled, or wrong
to an assistive technology in a way that blocks a task. `MxIconButton` makes
`semanticLabel` **required**, which is the single highest-value decision in this
system and the reason there is no P0 to write: 24 icon-only actions ship, and all
24 have an accessible name because the type system would not let them ship
without one.

Verdict: **healthy foundation, unowned vocabulary, one systemic a11y gap.**
Four P1, eleven P2, twelve P3.

---

## 2 · Provenance and what "current HEAD" means

```
BASE_SHA = 3207e7b7e0d3a2ecefa5e6a85fed48a65890ba6b
branch   = claude/a13-iconography-audit-bydn4s
```

`git status` was clean at audit start and the branch tip equals `origin/main`'s
tip. **No concurrent-branch synchronisation was performed**, per the brief: every
line number in this report resolves against `3207e7b7` and against nothing else.

---

## 3 · Icon inventory

### 3.1 · The whole population, counted

| measure | value |
|---|---|
| distinct `Icons.*` glyphs referenced | **100** |
| total `Icons.*` references | **232** |
| files referencing at least one | **93** |
| raw `Icon(` widget constructions | **24** |
| `MxIcon(` call sites | **58** |
| `MxIconButton(` call sites | **24** |
| non-Material icon sets in production | **0** |
| SVG / PNG / third-party glyph assets | **0** |
| emoji or unicode symbols used as icons | **0** (one argued text character — §8) |

The 208-reference gap between "232 references" and "24 raw widgets" is the
system working: almost every `Icons.*` in a feature is an `IconData` **value**
handed to a shared component (`MxIconButton.icon`, `MxEmptyState.icon`,
`MxMenuButton` actions, `MxPillButton.icon`, `MxListTile.leading`,
`MxActionButton.icon`), which is exactly the shape `MxIcon`'s doc argues for.

### 3.2 · Family split

| Material family | distinct glyphs | share |
|---|---|---|
| baseline / filled | 46 | 46% |
| outlined (`*_outlined`, `*_outline`, `outlined_*`) | 44 | 44% |
| **rounded** (`*_rounded`) | **10** | **10%** |

The rounded tenth is not distributed — it is concentrated in three files
(§7.3). Material's `_rounded` set is a **different drawing style** of the same
concepts, not a state variant, so a rounded glyph beside a baseline one in the
same list is a style mix, not a state signal.

### 3.3 · The most-used glyphs

| glyph | refs | meanings it carries |
|---|---|---|
| `error_outline` | 13 | error state · failure band · invalid import row · **wrong fill answer** |
| `folder_outlined` | 12 | deck-of-decks · move target · Library tab (rest) |
| `check` | 12 | selected option · save/confirm · step complete · **correct answer** |
| `style_outlined` | 11 | deck-of-cards · "all cards" filter · card count |
| `close` | 11 | dismiss/cancel/clear · **wrong answer** (guess, match) |
| `info_outline` | 7 | inline note · info dialog tone |
| `delete_outline` | 7 | delete action · trash |
| `sell_outlined` | 6 | tag (6 of 7 tag sites — see §7.1) |

`check`, `close` and `error_outline` are the three overloaded glyphs, and all
three overloads land inside one feature area (card list + study session).

### 3.4 · The two shared primitives

**`MxIcon`** (`lib/shared/widgets/mx_icon.dart`) — takes `IconData`, an `AppInk`,
an `MxIconSize` and an optional `semanticLabel`. Takes **no `Color` and no
`double`**, which is the whole design. `semanticLabel == null` wraps the glyph in
`ExcludeSemantics`; non-null passes it to `Icon.semanticLabel`.

**`MxIconButton`** (`lib/shared/widgets/mx_icon_button.dart`) — `semanticLabel`
is **required**, `tooltip` defaults to it, the glyph carries the label (not a
`Semantics` wrapper, so `button`/`enabled`/the tap action survive), the 48 dp
floor lives in `IconButtonThemeData` where no caller can undercut it, and
`isCompact` moves the glyph to 20 dp without touching the target.

Both are exemplary. Neither needs an API change from this audit.

---

## 4 · The size system

### 4.1 · The vocabulary is four steps, not three

`lib/core/theme/foundations/app_icon_size.dart`:

| token | dp | declared role |
|---|---|---|
| `sm` | **16** | inline with body text |
| `mdCompact` | **20** | an action sharing a row with something that needs the width |
| `md` | **24** | default for actions and list affordances |
| `lg` | **40** | illustrative icon in an empty or error state |

**Verified, not assumed.** The brief asked whether the vocabulary is 16/24/40; it
is **16/20/24/40**. The 20 dp step is real, is used (4 `MxIcon` sites plus
`MxIconButton.isCompact` plus `MxSessionTopBar`'s derived inset), and is the
step the token catalogue and the token test both forget (§10.1, §10.2).

### 4.2 · What the steps are actually spent on

| step | `MxIcon` sites | notes |
|---|---|---|
| `sm` (16) | **36** | the real default in practice, despite `md` being the API default |
| `md` (24) | 16 (all by omission) | not one call site names `MxIconSize.md` explicitly |
| `mdCompact` (20) | 4 | |
| `lg` (40) | 2 | `MxEmptyState`, `MxErrorState` |

The API default is `md`; the population default is `sm`. That is not a defect,
but it is worth knowing before anyone "simplifies" the default.

### 4.3 · Literal size drift — the complete list

Every raw `Icon(` in `lib/` was extracted with its `size:` argument. There are
**no numeric literals**: the guard's `no_raw_style_escape` pattern
(`Icon\s*\([^)]*\bsize\s*:\s*\d`) has held. What exists instead is **four
off-vocabulary sizes reached through non-literal spellings**, which the guard
cannot see:

| site | spelling | effective dp | verdict |
|---|---|---|---|
| `card_tile_widget.dart:247` | `size: _flagIconSize` (`const double _flagIconSize = 18`) | **18** | off-step, documented, argued |
| `card_import_result_widget.dart:170` | `size: AppSpacing.xxl` | **32** | off-step **and cross-vocabulary** — a spacing token used as a size (P3-9) |
| `match_tile_widget.dart:179` | `size: style?.fontSize` | text-derived | correct: the mark tracks its own label |
| `card_tile_widget.dart:113-121` | `MxIcon` (24) inside a 10×10 `SizedBox` + `FittedBox` | **10** | **the real drift** (P2-1) |

The last one does not name a size at all — it names the default (24) and then
*scales it down by a factor of 2.4 with a `FittedBox`*, which no guard, no test
and no reviewer reading the argument list would catch. It is the only size in the
app below `sm`, and it renders the multi-select mark.

A fifth spelling worth recording as **not** drift: `AppIconSize.sm` is used twice
as a `SizedBox.square(dimension:)` for a `CircularProgressIndicator`
(`card_history_section_widget.dart:305`, `search_page_footer_widget.dart:55`).
The spinner stands where an inline glyph would stand, so borrowing the glyph's
step is right.

### 4.4 · One role, three sizes — the leading list-row glyph

| screen | site | size |
|---|---|---|
| Library search results | `search_result_shell_widget.dart:71` | `sm` (**16**) |
| Trash rows | `trash_row_widget.dart:99,109` | default (**24**) |
| Move-deck picker | `move_deck_sheet_widget.dart:176` | `ListTile` slot (**24**) |
| Bulk-move picker | `card_bulk_overlays_widget.dart:139` | `ListTile` slot (**24**) |
| Settings reminder row | `settings_reminder_entry_section_widget.dart:39` | `ListTile` slot (**24**) |
| Deck rows | `deck_icon_area_widget.dart:63` | **24 centred in a 48 well** |

Same job — *what kind of thing is this row about* — at 16, 24 and 24-in-a-well.
The deck well is argued (it creates the column the whole tile aligns to). The
16-vs-24 split between search results and every other picker is not argued
anywhere (P2-8).

### 4.5 · One role, two sizes — the hero glyph

| site | size |
|---|---|
| `mx_empty_state.dart:70` | `MxIconSize.lg` (**40**) |
| `mx_error_state.dart:71` | `MxIconSize.lg` (**40**) |
| `card_import_result_widget.dart:170` | `AppSpacing.xxl` (**32**) in a 44 circle |

The import result is the outcome face of a whole flow — the same role
`MxErrorState` fills — drawn 8 dp smaller through a token from a different
scale (P2-7).

### 4.6 · Nothing scales with text — the P1

`applyTextScaling` has **zero occurrences** in `lib/`. Not on any `Icon`, not on
`ThemeData.iconTheme` (`app_theme.dart:226-229` sets `color` and `size` only),
not on `NavigationBarThemeData.iconTheme`, not on `ChipThemeData.iconTheme`, and
not as a rejected option in `AppIconSize`'s doc — which is the tell, because this
codebase documents its rejections.

Flutter's default is `false`, so every glyph in the app is a fixed dp box at every
text scale. The effect, computed from the rungs the call sites actually pair with:

| pairing | glyph | label at 1.0 | glyph ÷ label at 1.0 | label at 2.0 | glyph ÷ label at 2.0 |
|---|---|---|---|---|---|
| `MxIcon(sm)` + `labelSmall` | 16 | 11 | 1.45 | 22 | **0.73** |
| `MxIcon(sm)` + `bodySmall` | 16 | 12 | 1.33 | 24 | **0.67** |
| `MxIcon(sm)` + `bodyMedium` | 16 | 14 | 1.14 | 28 | **0.57** |
| `MxIcon(sm)` + `titleSmall` | 16 | 14 | 1.14 | 28 | **0.57** |

36 call sites are in the first four rows. This is P1-1.

**It is not a blanket "turn it on".** An icon-only button must *not* scale its
glyph past its 48 dp target, and `MxIconButton` is right to keep a fixed glyph;
`match_tile_widget.dart:179` already scales correctly by deriving from
`style?.fontSize`. The decision the system owes is **per role**, and §14 proposes
the shape.

---

## 5 · `IconTheme` and colour inheritance

### 5.1 · Where an icon's colour comes from

There are exactly four ambient sources, and all four are declared:

| source | value | who reads it |
|---|---|---|
| `ThemeData.iconTheme` (`app_theme.dart:226`) | `onSurfaceVariant` @ `AppIconSize.md` | any bare `Icon` outside a themed slot |
| `NavigationBarThemeData.iconTheme` (`app_navigation_bar_theme.dart:32`) | `WidgetStateProperty`: `onSecondaryContainer` selected / `onSurfaceVariant` rest | the 4 destinations |
| `ChipThemeData.iconTheme` (`app_chip_theme.dart:230`) | plain `IconThemeData` @ `AppIconSize.sm` | `MxPillButton` |
| `IconButtonThemeData` (`app_icon_button_theme.dart`) | `onSurfaceVariant`, **`disabledForegroundColor: semantic.onDisabled`** | `MxIconButton` and every `IconButton` |

`ThemeData.iconTheme`'s doc says exactly why it exists: Material's fallback is a
hardcoded `black87`/`white` with no seed in it, so an icon nobody styled degrades
on-brand. That is the right call and it is why the 14 colourless raw `Icon(`
calls in the app are safe rather than accidental.

### 5.2 · Direct overrides, enumerated

Only **four** of 24 raw `Icon(` calls pass a `color:`, and every one goes through
`AppInk`:

| site | spelling | why it is not `MxIcon` |
|---|---|---|
| `mx_icon.dart:97` | `ink.resolve(context)` | this *is* `MxIcon` |
| `mx_pill_button.dart:184` | `DefaultTextStyle.of(context).style.color` | the chip theme's `WidgetStateColor`, already resolved for this row's state — allowlisted in `icon_ink_boundary_test.dart` with a reason |
| `card_import_result_widget.dart:170` | `heroColor.resolve(context)` | size 32 has no `MxIconSize` step |
| `card_tile_widget.dart:247` | `AppInk.stated.resolve(context)` | size 18 has no `MxIconSize` step |

Both feature exceptions exist **only** because the size is off-step. Give the
system the missing steps and both collapse into `MxIcon` — which is the cleanest
argument in this report for treating §4.3 as a size problem rather than a colour
problem.

### 5.3 · Measured inks

Computed from the committed palette constants with the WCAG formula. Grounds:
`page` = `AppSurfaceColors.pageLight/Dark`, `paper` = `paperLight/Dark`, `muted`
= `surfaceMutedLight/Dark`.

| ink | role | page L | paper L | muted L | page D | paper D | muted D |
|---|---|---|---|---|---|---|---|
| `quiet` | `onSurfaceVariant` | 5.28 | 5.77 | 4.83 | 6.47 | 5.95 | 4.84 |
| `accent` | `primary` | 5.67 | 6.20 | 5.19 | 11.27 | 10.37 | 8.43 |
| `secondary` | `secondary` | 5.78 | 6.32 | — | 7.82 | 7.19 | — |
| `success` | `semantic.success` | 5.07 | 5.55 | 4.65 | 9.05 | 8.32 | 6.77 |
| `warning` | `semantic.warning` | **4.53** | 4.95 | **4.15** | 9.63 | 8.85 | 7.20 |
| `danger` | `semantic.danger` | 5.28 | 5.77 | 4.83 | 7.55 | 6.95 | 5.65 |
| `info` | `semantic.info` | 4.96 | 5.42 | 4.54 | 9.44 | 8.68 | 7.06 |

Every ink clears **3:1** (WCAG 1.4.11, non-text graphic) on every ground in both
themes, and every ink clears **4.5:1** on page and paper. The two figures that
sit under 4.5 are `warning` on `surfaceMuted` in light (4.15) and — marginally —
`success` on the same ground (4.65 clears). Since an icon is a graphic, not text,
3:1 is the applicable floor and neither is a violation; they are recorded because
`card_action_tone_widget.dart:55-59` already documents this exact ground for this
exact reason and reached 4.00 for warning by its own measurement.

The deck well, the one place a glyph sits on a tinted container:
`onPrimaryContainer` on `primaryContainer` = **11.44:1 light / 8.87:1 dark**.

### 5.4 · High contrast changes nothing about icon colour, correctly

`highContrastScheme` / `highContrastSemantics` (`app_high_contrast.dart:71-92`)
re-point exactly four tokens: `borderSubtle`, `borderControl`, `borderAccent`,
`onDisabled`, plus `ColorScheme.outline`/`outlineVariant`. **None of them is an
`AppInk` an enabled icon can resolve to.** So a high-contrast user sees byte-identical
enabled glyphs. Given §5.3 — every enabled ink already ≥ 4.15:1 — that is the
right answer, and the file says so explicitly ("High contrast is a legibility
setting, not a second design").

What *does* move is the **disabled** glyph, via `onDisabled` — which is the
correct half to move, and is the half `IconButtonThemeData` names.

---

## 6 · Disabled behaviour

### 6.1 · Icon-only buttons: named, and the resolution order works

`MxIconButton` passes `color:` only for `MxIconButtonTone.warning`, and its doc
claims a disabled toned button still greys to `semantic.onDisabled`. The claim is
**consistent with `ButtonStyleButton`'s documented resolution order**, which
falls back per *resolved value*, not per property: `IconButton.styleFrom`'s
foreground resolver returns `null` for the disabled state when
`disabledForegroundColor` is null, and the null then falls through to
`IconButtonThemeData`'s resolver, which names `semantic.onDisabled`. **Not
verified by a render** (appendix A1) — but the theme names the value, which is
the part the app controls.

Measured, `onDisabled` is `onSurface` at 38% (`0x61`), composited:

| ground | light | dark |
|---|---|---|
| page | `#A3ABBA` → **2.11:1** | `#515568` → **2.61:1** |
| paper | `#ABB1BE` → 2.15:1 | `#585B6F` → 2.65:1 |
| muted | `#9DA5B3` → 2.08:1 | `#62667F` → 2.55:1 |
| high contrast (62%), page | `#717D93` → **3.80:1** | `#818391` → **5.12:1** |

WCAG 1.4.11 **exempts inactive components**, so 2.11:1 is not a violation, and
the high-contrast swap does exactly what it was written to do. Recorded because a
disabled *icon-only* action has no greyed word beside it to corroborate the state
— the glyph is the whole signal — and 2.11:1 is at the edge of "is this here at
all".

### 6.2 · List rows: the theme names an enabled colour and no disabled one

`buildListTileTheme` sets `iconColor: scheme.onSurfaceVariant` as a **plain
`Color`**, with no disabled counterpart — in contrast to
`buildIconButtonTheme`, which names `disabledForegroundColor` explicitly and
documents *why* ("Named, not left to `defaultStyleOf` where no audit can see
it"). There are genuinely disabled rows in production:
`move_deck_sheet_widget.dart` renders rejected move targets with
`MxListTile(isEnabled: false)` and a bare `Icon(Icons.folder_outlined)` leading.

The app is probably saved by `ThemeData.disabledColor: semantic.onDisabled`
(`app_theme.dart:220`) — but that line's own comment says it is there for
`DropdownButton`, so nothing pins it for rows and nothing would notice if it
moved. P2-11; unverified as to the SDK's actual fallback path (appendix A2).

### 6.3 · Everything else

`MxMenuButton` and `MxActionSheet` ink a disabled action's glyph through
`AppInk` conditionals at the call site; `MxPillButton` inherits the chip theme's
resolved state colour. Both are correct.

---

## 7 · Semantic taxonomy and vocabulary conflicts

### 7.1 · Classification of every meaning-bearing usage

| class | definition | representative sites | count (approx.) |
|---|---|---|---|
| **decorative** | a glyph beside a label that already says the thing; silent to AT | 57 of 58 `MxIcon` sites; every `MxMenuButton`/`MxActionSheet` action glyph | ~150 |
| **meaning-bearing with text** | glyph + word, glyph reinforces | metric wells, badge pills, filter pills, feedback bands | ~40 |
| **icon-only action** | no visible label; the accessible name is the only name | all 24 `MxIconButton` sites + `MxSearchField`'s clear + `MxBreadcrumb`'s fold | 26 |
| **navigation** | moves the user | 4 nav destinations (×2 states), `chevron_right` ×3, `chevron_left`, `arrow_back`, `north_east`, `close` ×7 | ~20 |
| **selected-state cue** | the glyph *is* the state | `card_tile` check, `trash_row` checkbox, `study_direction` radio, `card_export_format` radio, `card_import_source` check, `progress_range` check, `mx_action_sheet` check | 7 groups |
| **status** | reports data, not interaction | workload metrics, progress metrics, import row verdicts, card-history tone badges, study answer verdicts | ~30 |
| **empty / error hero** | the face of a whole screen state | `MxEmptyState` (23 callers), `MxErrorState`, `MxFeedbackBand`, `card_import_result` | 27 |

**Only 1 of 58 `MxIcon` call sites passes a `semanticLabel`**
(`deck_icon_area_widget.dart:63`). That is the correct ratio, not a gap: every
other one sits beside its own words, and the widget's null-means-silent contract
makes "decorative" the default an author has to leave rather than a state they
fall into. Decorative semantics noise is **not** a problem in this codebase —
`ExcludeSemantics` is applied deliberately and its placement is argued in
`trash_row_widget.dart:114-121`, `search_result_shell_widget.dart:66`,
`card_detail_state_widget.dart` and `progress_metric_widget.dart`.

### 7.2 · Same meaning, different glyph — the conflict register

| # | meaning | glyphs in production | sites |
|---|---|---|---|
| **V1** | *tag* | `sell_outlined` ×6, **`label_outline` ×1** | `card_selection_bar_widget.dart:93` vs `card_filter_bar_widget.dart:198`, `tag_catalog_row_widget.dart:156`, `card_list_menu_widget.dart:75`, `library_menu_widget.dart:32`, `tag_catalog_screen.dart:267`, `card_tag_filter_sheet_widget.dart:225` |
| **V2** | *flag / unflag* | `flag` (set) · `flag_outlined` (unset **and** the Flag action) · **`outlined_flag`** (the Unflag action) | `card_flag_toggle_widget.dart:43`, `card_tile_widget.dart:248`, `card_detail_summary_widget.dart:257`, `card_filter_bar_widget.dart:128` vs `card_selection_bar_widget.dart:99,105` |
| **V3** | *not started / not selected* | `circle_outlined` for **both** | `card_filter_bar_widget.dart:111` (New filter) vs `card_tile_widget.dart:117` (unselected row) |
| **V4** | *your answer was wrong* | `close` (guess, match) · `error_outline` (fill) | `guess_option_item_widget.dart:87`, `match_tile_widget.dart:248` vs `fill_answer_pieces_widget.dart:298` |
| **V5** | *history* | `history` · `history_outlined` · `history_rounded` | `card_history_section_widget.dart:163`, `card_editor_context_widget.dart:170`, `card_detail_state_widget.dart:118` |
| **V6** | *due / when* | `schedule` · `schedule_rounded` | `card_filter_bar_widget.dart:97`, `deck_sort_sheet_widget.dart:40` vs `card_detail_state_widget.dart:108` |
| **V7** | *restore* | `restore` · `restore_outlined` | `deck_actions_widget.dart:123` vs `trash_row_widget.dart:133` |
| **V8** | *row selected (multi-select)* | `check_circle`/`circle_outlined` · `check_box_outlined`/`check_box_outline_blank` | `card_tile_widget.dart:117` vs `trash_row_widget.dart:101-102` |
| **V9** | *one option chosen (pick-one)* | `radio_button_checked`/`unchecked` ×2 · `check_circle` appearing/vanishing ×1 · bare `check` ×2 | `study_direction_chooser_widget.dart:201`, `card_export_format_options_widget.dart:291` vs `card_import_source_step_widget.dart:224` vs `mx_action_sheet.dart:184`, `progress_range_selector_widget.dart:52` |
| **V10** | *share* | **`ios_share`** ×2 (Android-only release target) | `card_list_menu_widget.dart:54`, `card_selection_bar_widget.dart:111` |
| **V11** | *folded / more* | `more_horiz` (scrolling strip) · `…` U+2026 (header line) | `mx_breadcrumb.dart:408` vs `mx_breadcrumb_step.dart:205` — **argued**, see §8 |

V1, V2 and V3 all land on the **same screen** (card list) and two of them are
visible at the same instant: `card_list_screen.dart:203` renders the selection
bar while `:281` keeps the filter strip in the shell header, so during
multi-select the header shows `circle_outlined` meaning *New* and every unselected
row shows `circle_outlined` meaning *not picked*, while the bar offers a
`sell`-less `label_outline` tag action next to two indistinguishable flag actions.

### 7.3 · The rounded family is three files, not a policy

| file | rounded glyphs |
|---|---|
| `card_detail_state_widget.dart` | `schedule_rounded`, `history_rounded`, `autorenew_rounded`, `replay_rounded`, `speed_rounded`, `event_repeat_rounded`, `repeat_one_rounded` |
| `card_action_tone_widget.dart` | `check_rounded`, `trending_flat_rounded`, `replay_rounded` |
| `card_detail_summary_widget.dart` | `bolt_rounded` |

The sharpest instance is `card_detail_state_widget.dart:105-150`, which builds one
metric list where six entries are `_rounded` and one — `Icons.school_outlined`,
the *Learned* metric at line 113 — is outlined. Seven glyphs in one grid, two
drawing styles, no note explaining the split. Everything on Card Detail is
therefore drawn in a family the other 21 screens do not use.

---

## 8 · Non-Material exceptions

**There are none in the icon sense, and that is worth stating plainly.**

- No `flutter_svg`, no `font_awesome`, no `lucide`, no icon package of any kind.
- No `Image.asset`, no `AssetImage`, no `.svg` or `.png` referenced from `lib/`.
- No emoji anywhere in `lib/` or in either ARB file. A scan of every non-comment
  source line for Unicode categories `So`/`Sm`/`Sk` above U+2000 returns exactly
  three characters: en dash (×1), em dash (×16) and horizontal ellipsis (×1).

**The one argued exception** is that ellipsis: `mx_breadcrumb_step.dart:205`
declares `const String _kFoldedSteps = '…'` and documents why a character beats
`Icons.more_horiz` there — it sits in a text line between two slashes, where an
icon would be off the baseline and the wrong size, and it is not a control. The
neighbouring scrolling breadcrumb *does* use `more_horiz`, as a real button with
`MaterialLocalizations.moreButtonTooltip` as its name. Both are right; they are
recorded in V11 only so the pair is not "fixed" by someone who finds one of them.

**One counter-example on the dependency side:** `cupertino_icons: ^1.0.8` is a
declared production dependency (`pubspec.yaml:36`) and `CupertinoIcons` is
referenced **zero** times in `lib/`, `test/`, `widgetbook/` or `integration_test/`.
Flutter tree-shakes unused icon fonts in release builds, so the shipped cost is
approximately nothing — this is hygiene, not weight, and it is listed as P3-4
only because AD-05 refuses `dio` on exactly this principle.

---

## 9 · Accessibility and raw usage

### 9.1 · Every icon-only action has a name, structurally

24 `MxIconButton` call sites, 24 accessible names, because the parameter is
`required`. `mx_accessibility_test.dart:95-119` pins that tooltip and
`Icon.semanticLabel` merge into **one** node rather than announcing twice. The
two icon-only controls outside `MxIconButton` are also named:
`mx_search_field.dart:206-213` (raw `IconButton` with `tooltip` +
`semanticLabel`, both from `clearSemanticLabel`) and `mx_breadcrumb.dart:390-395`
(`mx_breadcrumb.dart:389-394` — `Semantics(button: true, label: moreButtonTooltip, value: hiddenCount)`).

**No unnamed icon-only action exists in this codebase.** That is the finding, and
it is a good one.

### 9.2 · The pick-one groups disagree about exclusivity

`inMutuallyExclusiveGroup` appears **once** in the whole repo:
`card_export_format_options_widget.dart:197`, where the comment states the reason
precisely — *"What the card cannot know is that these options exclude each
other."*

The three other pick-one groups do not have it:

| group | how it draws selection | exclusivity announced? |
|---|---|---|
| `card_export_format_options_widget.dart` | radio glyph + `MxCard.isSelected` | **yes** |
| `study_direction_chooser_widget.dart:196-212` | radio glyph + `MxListTile.isSelected` | **no** |
| `card_import_source_step_widget.dart:213-232` | `check_circle` appears + `MxCard.isSelected` | **no** |
| `progress_range_selector_widget.dart:52` | `check` in a menu | **no** (a menu, arguably fine) |

The Study direction chooser is the sharp one: it *draws a radio button* — the
strongest possible visual promise of "one of these" — and emits `selected: true`,
the flag a checkbox emits. A screen-reader user hears "selected" where the sighted
user sees "1 of 3". `MxRadioRows` exists (`lib/shared/widgets/mx_radio_rows.dart`)
and its doc opens with *"Exists so no feature builds a `RadioListTile` again"* —
this is a feature building one again, by hand, minus the semantics. P1-3.

### 9.3 · Feature raw `Icons.*` usage — legitimate, with one seam

All 7 feature-level raw `Icon(` calls are legitimate under the documented rule:

| site | why legitimate |
|---|---|
| `move_deck_sheet_widget.dart:176` | colourless in `MxListTile.leading` → inherits `ListTileThemeData.iconColor` |
| `card_bulk_overlays_widget.dart:139` | same |
| `settings_reminder_entry_section_widget.dart:39` | same |
| `card_tag_section_widget.dart:300` | colourless in `ActionChip.avatar` → inherits `chipTheme.iconTheme` |
| `card_import_result_widget.dart:170` | off-step 32, `.resolve(` spelling |
| `card_tile_widget.dart:247` | off-step 18, `.resolve(` spelling |
| `match_tile_widget.dart:179` | text-derived size, `.resolve(` spelling |

The seam: `settings_reminder_entry_section_widget.dart` uses a **bare `Icon`** for
`leading` (line 39) and an **`MxIcon`** for `trailing` (line 45) **in the same
row**, with a comment defending the trailing one ("the `ListTile` defaults it
happens to agree with today are not a contract") that applies equally to the
leading one. Two spellings of the same decision, four lines apart (P2-10).

### 9.4 · Outlined-rest → filled-selected: where it is right and where it is not

**Correct — a genuine rest/active axis on the same object:**

| site | pair |
|---|---|
| `app_navigation_shell.dart:44-60` | `folder`/`school`/`insights`/`settings` outlined ↔ filled, driven by `NavigationDestination.selectedIcon` with `NavigationBarThemeData.iconTheme` resolving `WidgetState.selected` |
| `card_flag_toggle_widget.dart:43` | `flag_outlined` ↔ `flag`, a user-set reversible state, plus a tone change plus a changing accessible name — three signals, exactly as its doc claims |
| `deck_level_summary_widget.dart:135` | `expand_more` ↔ `expand_less` — a disclosure axis, correctly a *direction* change rather than a fill change |
| `card_details_section_widget.dart:68-83` | `add` ↔ `expand_less` — asymmetric, and legitimately so: the label changes with it (*Add details* → *Details*), so the glyph names the action rather than the axis |

**Not a rest/active axis at all — and therefore correctly *not* using the fill
delta:** `deck_status_icon_widget.dart:47-48`, `deck_result_tile_widget.dart:32`,
`trash_row_widget.dart:111-112` all pick `style_outlined` vs `folder_outlined` for
*what kind of thing this is*. Two different concepts, two different glyphs, both
outlined. Right.

**Semantically wrong — fill used for data magnitude:**

| site | pair | what fill means here |
|---|---|---|
| `study_home_workload_item_widget.dart:78-79` | `event_busy_outlined` ↔ `event_busy` | overdue count > 0 |
| `study_home_workload_item_widget.dart:94` | `event_outlined` ↔ `event` | due-today count > 0 |
| `study_home_workload_item_widget.dart:109-110` | `auto_awesome_outlined` ↔ `auto_awesome` | new count > 0 |
| `progress_metric_widget.dart:303` | `auto_awesome_outlined` ↔ `auto_awesome` | learning count > 0 |

The file itself names the rule it is following — *"Parity item E5 says outlined
at rest and filled when active"* — so this is a deliberate design decision, not
drift. Two things are nonetheless wrong with it as shipped:

1. **The fill delta now carries three unrelated meanings**, two of which are on
   screen together. On Study Home the bottom navigation bar says *filled =
   you are here* while the workload row two hundred pixels above says *filled =
   this number is not zero*. Material 3 uses the outlined/filled pair for
   selection and for on/off toggles; it does not use it for magnitude, and the
   app now has three readings of one visual change (P2-3).
2. **It is applied to one of four siblings.** In `progress_metric_widget.dart`,
   `_LearningMetric` (line 303) fills at non-zero and cites E5 by name;
   `_ActiveCardsMetric` (240, `style_outlined`), `_ActiveDaysMetric`
   (`calendar_month_outlined`) and `_ReviewingMetric` (333,
   `event_repeat_outlined`) never fill, at any count. They render in one row.
   A user sees one glyph in four change state with the data and cannot tell
   whether the other three are permanently zero (P2-2).

**One error state wearing the empty-state face.**
`card_bulk_overlays_widget.dart:99-105` renders the `error:` branch of an
`AsyncValue` as `MxEmptyState(icon: Icons.error_outline, …)` with no retry.
`MxEmptyState` paints its icon `AppInk.accent` unconditionally
(`mx_empty_state.dart:70`), so the app's error glyph appears in **brand blue**,
and the widget's own doc opens by renouncing exactly this conflation:
*"Deliberately distinct from `MxErrorState`: … rendering it in error styling
tells the user something is broken when nothing is."* Read in reverse, this site
tells the user nothing is broken when something is.
`card_editor_screen.dart:211` is the same shape with a better excuse — its
"recovery face" is a dead end with a way back and does carry an action — but it
too paints `error_outline` in accent (P2-6).

---

## 10 · Coverage — tests, Widgetbook, goldens

### 10.1 · Widgetbook

| surface | state |
|---|---|
| `MxIcon` story (`control_components.dart:164-193`) | **present** — knobs for every `AppInk`, every `MxIconSize`, and the semantic-label toggle. Good. |
| `MxIconButton` story | present |
| Icon-size token section (`scale_sections.dart:76-97`) | **incomplete** — renders `sm`, `md`, `lg`. **`mdCompact` is missing**, so the catalogue tells a designer the vocabulary is three steps when it is four (P3-1) |

### 10.2 · Tests

| what | where | state |
|---|---|---|
| every `Icon(color:)` resolves through `AppInk`, kit **and** features | `test/app/icon_ink_boundary_test.dart` | **strong** — balanced-paren parsing, allowlist with per-entry reasons, and a staleness test that fails a spent exemption |
| icon-only button emits one labelled node, keeps 48×48 through hover/focus | `mx_accessibility_test.dart:95-150` | strong |
| icon-size token ordering | `design_tokens_test.dart:51-52` | asserts `sm < md < lg` only — **`mdCompact` is never asserted** (P3-2) |
| icon sizes match the CSS design kit | `css_scale_parity_test.dart:49-55` | complete, all four steps |
| **`MxIcon` itself** | — | **no unit test exists.** The central contract — `semanticLabel == null` ⇒ `ExcludeSemantics`, non-null ⇒ a labelled node — is asserted nowhere (P3-3) |
| high-contrast icon rendering | — | palette-level unit tests only (`app_high_contrast_test.dart`); **no rendered surface** |

### 10.3 · Goldens

152 committed PNGs under `test/demo/goldens/`. Icon-bearing states are well
covered: `card_list_selection_light/dark.png` capture the 10 dp selection mark,
`guess_correct/wrong`, `study_fill_correct/incorrect` and the four
`study_match_progress_*` pairs capture every verdict glyph, and both nav-bar
states appear on every screen shot.

Two gaps:

- **Zero goldens at high contrast.** No PNG renders `buildHighContrastLightTheme()`
  or `buildHighContrastDarkTheme()`. Per §5.4 the enabled icons are provably
  identical, so this is a *thin* gap for iconography specifically — but the
  disabled glyph does move, and nothing pictures it (P3-10).
- **6 of 152 goldens exercise a doubled text scale**, none of which is an
  icon-dense surface at `sm`. §4.6's finding is therefore invisible to the golden
  suite by construction.

---

## 11 · Severity registry

### P0 — none

No icon in this app is unreachable, unlabelled where a label is required, or
misreported to an assistive technology in a way that blocks a task. `MxIconButton`
making `semanticLabel` required is why.

### P1 — systemic

| id | finding | where | closure test |
|---|---|---|---|
| **P1-1** | **No glyph in the app scales with text size.** `applyTextScaling` has zero occurrences in `lib/`; 36 of 58 `MxIcon` sites are 16 dp beside 11–14 dp labels, so at `textScaler` 2.0 the glyph drops from 1.14–1.45× its label to 0.57–0.73× | `mx_icon.dart:95-106`, `app_theme.dart:226-229`, §4.6 | A widget test that pumps one `MxIcon(size: sm)` at `textScaler` 1.0 and 2.0 and asserts the rendered glyph box grows for the roles that opt in — **or** an `AppIconSize` doc block recording the rejection with the per-role table, plus a test asserting `MxIconButton`'s glyph does **not** grow |
| **P1-2** | **`Icons.circle_outlined` carries two meanings on one screen at one moment.** The card-list header shows it as the *New* filter while every unselected row shows it as *not picked* | `card_filter_bar_widget.dart:111` + `card_tile_widget.dart:117`, both live via `card_list_screen.dart:203,281` | A widget test that pumps the card list in selection mode with the New filter available and asserts the filter pill's `IconData` differs from the unselected row mark's |
| **P1-3** | **A pick-one group draws radio buttons and announces a checkbox.** The Study direction chooser has no `inMutuallyExclusiveGroup`, while its structural twin one feature over has it and documents why | `study_direction_chooser_widget.dart:196-212` vs `card_export_format_options_widget.dart:197` | A semantics test asserting each direction tile's node carries `isInMutuallyExclusiveGroup` and `hasCheckedState` |
| **P1-4** | **"Flag" and "Unflag" are adjacent menu items wearing two different codepoints that both draw an unfilled flag**, in an app whose established pair is `flag` = set / `flag_outlined` = unset | `card_selection_bar_widget.dart:99` (`flag_outlined`) and `:105` (`outlined_flag`); contrast `card_flag_toggle_widget.dart:43` | A widget test over the bulk-action list asserting no two actions share a visually equivalent glyph, and that the *Flag* action carries the same `IconData` the flagged state carries |

### P2 — localized

| id | finding | where |
|---|---|---|
| **P2-1** | The multi-select mark is drawn at **10 dp** — a 24 dp `MxIcon` compressed by a `FittedBox` into a `SizedBox(10,10)`, below every step in `AppIconSize`, fixed under text scale. The code's own comment claims "shape carries the state as much as colour does" | `card_tile_widget.dart:113-121`; the same meaning is 24 dp at `trash_row_widget.dart:99-104` |
| **P2-2** | Parity rule E5 (*outlined at rest, filled when active*) is applied to **one of four** metrics rendered in a single row | `progress_metric_widget.dart:303` vs `:240`, `:333` and `_ActiveDaysMetric` |
| **P2-3** | The outlined→filled delta now carries **three** meanings — navigation selection, toggle state, and count > 0 — two of them visible together on Study Home | `app_navigation_shell.dart:44-60` vs `study_home_workload_item_widget.dart:78-110` |
| **P2-4** | Material's `_rounded` family is mixed with baseline and outlined glyphs inside one metric grid: six `_rounded` and one `school_outlined` | `card_detail_state_widget.dart:105-150`; also `card_action_tone_widget.dart:78-80`, `card_detail_summary_widget.dart:186` |
| **P2-5** | "Your answer was wrong" is `close` in two study modes and `error_outline` — the app's *failure* glyph, 13 other uses — in the third | `guess_option_item_widget.dart:87`, `match_tile_widget.dart:248` vs `fill_answer_pieces_widget.dart:298` |
| **P2-6** | An `AsyncValue.error` branch renders as `MxEmptyState`, so the error glyph paints `AppInk.accent` (brand) with no retry — the exact conflation `MxEmptyState`'s doc renounces | `card_bulk_overlays_widget.dart:99-105`; milder at `card_editor_screen.dart:211` |
| **P2-7** | The hero glyph of a completed flow is **32 dp** (via `AppSpacing.xxl`) where the same role is 40 dp (`MxIconSize.lg`) everywhere else | `card_import_result_widget.dart:170` vs `mx_empty_state.dart:70`, `mx_error_state.dart:71` |
| **P2-8** | The leading list-row glyph is 16 dp in search results and 24 dp in every other picker and row, with no note either way | `search_result_shell_widget.dart:71` vs `trash_row_widget.dart:109`, `move_deck_sheet_widget.dart:176`, `card_bulk_overlays_widget.dart:139` |
| **P2-9** | *Tag* is `sell_outlined` at six sites and `label_outline` at the seventh — and both appear on the card list screen | `card_selection_bar_widget.dart:93` vs `card_filter_bar_widget.dart:198` |
| **P2-10** | `Icons.ios_share` — the Apple share affordance — is the app's share glyph, on a project whose release target is Android and whose iOS support is deferred | `card_list_menu_widget.dart:54`, `card_selection_bar_widget.dart:111` |
| **P2-11** | `ListTileThemeData` names an enabled `iconColor` and **no** disabled one, unlike `IconButtonThemeData` which names `disabledForegroundColor` and documents why. Production has genuinely disabled rows with bare leading `Icon`s | `app_list_tile_theme.dart:20` vs `app_icon_button_theme.dart:23`; live at `move_deck_sheet_widget.dart:176` |

### P3 — polish / debt

| id | finding | where |
|---|---|---|
| **P3-1** | The Widgetbook token catalogue shows 3 of the 4 icon sizes; `mdCompact` is absent | `widgetbook/lib/tokens/scale_sections.dart:88-92` |
| **P3-2** | `design_tokens_test.dart` asserts `sm < md < lg` and never mentions `mdCompact`, so the 20 dp step has no ordering guard | `design_tokens_test.dart:51-52` |
| **P3-3** | `MxIcon` has no unit test. Its null-label ⇒ `ExcludeSemantics` contract — the reason the widget exists — is asserted nowhere | no `test/shared/widgets/mx_icon_test.dart` |
| **P3-4** | `cupertino_icons` is a declared production dependency with zero `CupertinoIcons` references anywhere in the repo (tree-shaken, so cost ≈ 0; hygiene only) | `pubspec.yaml:36` |
| **P3-5** | Stale doc **inside the icon contract itself**: `mx_icon.dart` says "`MxMetricWell` takes a `Color` parameter, which is its own defect". It takes `AppInk tint`; its `Color? wellColor` is the well, not the glyph | `mx_icon.dart:67-69` vs `mx_metric_well.dart:39,54` |
| **P3-6** | Stale cross-reference: a comment cites `event_busy` as "what `deck_status_icon_widget.dart` uses for the same backlog". That file no longer draws a schedule glyph at all — it draws `style_outlined`/`folder_outlined` | `study_home_workload_item_widget.dart:75-76` vs `deck_status_icon_widget.dart:45-49` |
| **P3-7** | `app_high_contrast.dart`'s doc table records `onDisabled` at 2.37 / 3.20 normal and 4.88 / 6.33 high-contrast. Recomputing with the same method the file's own test uses (`Color.alphaBlend(onDisabled, surface)`) gives **2.11 / 2.61** and **3.80 / 5.12**, and no ground in the app's ladder produces the recorded pair | `app_high_contrast.dart:24-28` vs `app_high_contrast_test.dart:83-103`; §6.1 |
| **P3-8** | `AppIconSize`'s doc opens "Three steps covered everything UC-05 draws" and then declares four, with `mdCompact` written *after* `md` — the file reads as three-plus-an-afterthought where `MxIconSize` orders it correctly | `app_icon_size.dart:1-19` |
| **P3-9** | `AppSpacing.xxl` used as an icon size — a spacing token spent on the size scale. The guard cannot see it because it is not a literal | `card_import_result_widget.dart:170` |
| **P3-10** | No golden renders any surface under the high-contrast themes; the raised disabled glyph is pictured nowhere | `test/demo/goldens/` (152 PNGs, 0 high-contrast) |
| **P3-11** | The trash checkbox pairs `check_box_outlined` (outline theme) with `check_box_outline_blank` (baseline) rather than the M3 pair `check_box` / `check_box_outline_blank` | `trash_row_widget.dart:101-102` |
| **P3-12** | *Restore* is `restore` in one place and `restore_outlined` in another; *history* has three spellings; *due* has two | `deck_actions_widget.dart:123`, `trash_row_widget.dart:133`; §7.2 V5–V7 |

---

## 12 · What is already right, and must not be "fixed"

Recorded so a later sweep does not undo work that was argued once:

1. **A bare `Icon` is legal and correct inside a themed slot.** Six kit widgets
   and three feature list rows pass no colour so the glyph takes the button's or
   the tile's `IconTheme`, which resolves per state. Wrapping them in `MxIcon`
   would freeze one colour and leave the glyph lit while the control goes
   disabled. `icon_ink_boundary_test.dart:102-104` skips colourless calls for
   this reason.
2. **`MxPillButton`'s open colour is not a defect.** It reads
   `DefaultTextStyle.of(context).style.color`, which is the chip theme's
   `WidgetStateColor` already resolved for this row. There is no `AppInk` member
   for "whatever the chip decided", and naming one would drop the selected and
   disabled states.
3. **The four `MxDialogTone` glyphs are four distinct silhouettes on purpose**
   (`mx_dialog_tone.dart:71-76`), because roughly one man in twelve cannot
   separate the warning amber from the danger red. Do not collapse them to one
   tinted glyph.
4. **The breadcrumb's `…`-vs-`more_horiz` split is argued** and both halves are
   correct in their own context (§8).
5. **`Icons.circle_outlined` for the *New* filter is the better of two bad
   options** — `fiber_new` draws the word NEW directly beside the word New
   (`card_filter_bar_widget.dart:107-110`). If P1-2 is resolved, resolve it on
   the *selection mark* side.
6. **The deck well's 24-in-48 is not a size inconsistency** — the square is what
   creates the column the whole tile aligns to (`deck_icon_area_widget.dart:16-35`).
7. **`MxIcon`'s default ink is `quiet`, not `stated`**, and that is the design
   system's rule, not laziness: an icon at full text strength competes with the
   words it decorates.

---

## 13 · Owner decisions genuinely required

Three, and only the first two block anything.

**D1 — Does an inline glyph scale with text?** (§4.6, P1-1)
The trade is real in both directions. Scaling keeps a 16 dp glyph legible beside
a 28 dp word at `textScaler` 2.0; not scaling keeps 320 dp layouts from
overflowing, and this project has measured overflow at 2.0 on the search field,
the pill row, the selection bar and the export options. The honest answer is
almost certainly *per role* — inline and status glyphs scale, icon-only actions
and the navigation bar do not — which means `MxIconSize` grows a boolean or the
enum grows a scaling flag. **This is a design-language decision, not an
implementation choice, and until it is made the app has an unstated policy of
"never".**

**D2 — Who owns glyph identity?** (§7.2)
Colour has `AppInk`. Size has `MxIconSize`. Identity has nothing, and eleven
conflicts are the consequence. The options are: (a) an `AppIcons` const class
mapping *concepts* to glyphs (`AppIcons.tag`, `AppIcons.flag`, `AppIcons.wrong`),
which closes the set the way `AppInk` closed colour; (b) a doc table in
`docs/` plus a lint that fails on a `Icons.*` not on the list; (c) leave it open
and fix the eleven by hand. **(a) is the consistent answer and it is also the one
this audit is most reluctant to recommend** — the brief says not to force
abstraction merely to eliminate raw `Icon`, and an `AppIcons` class touches 93
files. (b) buys most of the value at a fraction of the blast radius. The decision
is which.

**D3 — Is `Icons.ios_share` deliberate?** (P2-10)
It may be an owner preference for the glyph's shape. If it is, it needs one line
somewhere saying so, because the next reader of an Android-only project will
change it.

---

## 14 · Recommended implementation order

Ordered so each step is independently verifiable and so the two steps needing D1
or D2 come last.

**Phase 1 — no design decision needed, no visual change (P3 doc debt).**
`mx_icon.dart:67-69` (the `MxMetricWell` sentence), `study_home_workload_item_widget.dart:75-76`
(the `event_busy` cross-reference), `app_icon_size.dart:1-19` (four steps, in
order), `app_high_contrast.dart:24-28` (reconcile or recompute the `onDisabled`
row). Four comment edits, zero risk.
*Files:* `lib/shared/widgets/mx_icon.dart`,
`lib/features/study/presentation/widgets/items/study_home_workload_item_widget.dart`,
`lib/core/theme/foundations/app_icon_size.dart`,
`lib/core/theme/schemes/app_high_contrast.dart`.

**Phase 2 — close the coverage holes (P3-1, P3-2, P3-3).**
Add `mdCompact` to the Widgetbook token section and to `design_tokens_test`; write
`test/shared/widgets/mx_icon_test.dart` asserting the label/no-label semantics
contract and that each `MxIconSize` renders its `dp`. No production code moves.
*Files:* `widgetbook/lib/tokens/scale_sections.dart`,
`test/core/theme/foundations/design_tokens_test.dart`, new
`test/shared/widgets/mx_icon_test.dart`.

**Phase 3 — the accessibility fix (P1-3).**
Add `inMutuallyExclusiveGroup: true` to the Study direction tiles, or move them
onto `MxRadioRows`. The second is more correct and larger; the first is one line
and closes the announcement gap. Ship with the semantics test from P1-3's closure
column.
*Files:* `lib/features/study/presentation/widgets/overlays/study_direction_chooser_widget.dart`,
`test/features/study/presentation/study_accessibility_test.dart`.

**Phase 4 — the same-screen collisions (P1-2, P1-4, P2-9).**
Three glyph swaps on the card list: give the unselected row mark a glyph that is
not `circle_outlined`; give the *Flag* bulk action `Icons.flag`; give *Add tag*
`Icons.sell_outlined`. All three are one-word changes and all three move
goldens — `card_list_selection_light/dark.png` and `card_overflow_menu_*.png` at
minimum, so **regenerate goldens on Linux and republish the gallery in the same
turn** per CLAUDE.md.
*Files:* `lib/features/card/presentation/widgets/items/card_tile_widget.dart`,
`lib/features/card/presentation/widgets/sections/card_selection_bar_widget.dart`,
plus `test/demo/goldens/`.

**Phase 5 — size normalisation (P2-1, P2-7, P2-8, P3-9).**
Give `AppIconSize` the steps the off-step sites need (18 and 32 are the two real
ones), then convert `card_tile_widget.dart:247`, `card_import_result_widget.dart:170`
and the `FittedBox` selection mark onto `MxIcon` — which removes the last two
feature `Icon(color:)` exceptions as a side effect (§5.2). Decide the leading-row
size (16 or 24) once and apply it.
*Files:* `lib/core/theme/foundations/app_icon_size.dart`,
`lib/shared/widgets/mx_icon.dart`, four feature widgets, `spacing.css` parity,
`test/design_audit/css_scale_parity_test.dart`, goldens.

**Phase 6 — needs D2.** The vocabulary register (§7.2 V4–V8, V10, P2-4, P2-5,
P2-11's sibling `restore`/`history`/`schedule` splits). Do not start this before
D2 is answered; fixing eleven conflicts by hand without an owner for identity
buys a clean snapshot and no guarantee.

**Phase 7 — needs D1.** Text scaling. Whatever D1 decides, the deliverable is the
same: an explicit per-role policy written into `AppIconSize`, an
`applyTextScaling` flag threaded to the roles that opt in, and a golden or widget
test at `textScaler` 2.0 on one icon-dense surface.

**Deliberately not planned:** P2-2, P2-3 and P2-6 are design questions dressed as
defects. P2-2/P2-3 ask whether E5 should exist at all now that fill means three
things; P2-6 asks whether an error branch may borrow the empty face. All three
belong to a design review, not to an implementation queue.

---

## Appendix A — what this audit could not verify

| id | claim | why not |
|---|---|---|
| **A1** | That a disabled `MxIconButtonTone.warning` button actually paints `semantic.onDisabled` rather than falling through to the ambient `IconTheme` | The reasoning depends on `ButtonStyleButton` resolving per *value* rather than per *property*. No Flutter SDK is installed in this container, so the source could not be read and no widget tree was pumped. The theme names the value; the SDK path is assumed |
| **A2** | What a disabled `MxListTile`'s bare leading `Icon` actually resolves to | Same reason. `ListTileThemeData.iconColor` is a plain `Color` here, so the disabled path is entirely Flutter's; `ThemeData.disabledColor` is set to `semantic.onDisabled` but for a documented reason unrelated to rows |
| **A3** | Rendered appearance at 320 dp and at `textScaler` 2.0/3.0 | No renderer. §4.6's ratios are arithmetic over the declared dp values and the `TextTheme` rungs in `app_typography.dart`, not pixels |
| **A4** | Whether `flag_outlined` and `outlined_flag` are pixel-identical | They are two distinct Material codepoints that both draw an unfilled flag; the finding stands on "indistinguishable in a menu row", not on "identical". A rendered comparison would settle the degree |
| **A5** | High-contrast rendered output | Derived from the token diff (§5.4), which shows no enabled icon ink moves. Nothing pictures it — see P3-10 |
| **A6** | Contrast figures against `surfaceContainer*` roles | Only `page`, `paper` and `surfaceMuted` were computed; the M3 container ladder was not enumerated. All three computed grounds clear 3:1 with margin, and the ladder sits between them |
| **A7** | Whether any icon regressed a golden | No goldens were regenerated and none could be — this checkout has no SDK, and per CLAUDE.md goldens have exactly one authoring platform |
