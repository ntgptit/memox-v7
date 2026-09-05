# A20.1 — Final design-system reconciliation after A20

| | |
|---|---|
| **Status** | **historical closure evidence — not an active backlog.** Design System V1 was frozen at `b4599c35` (M100.40); the freeze record, the frozen contracts and the reopen triggers live in `docs/design-system/v1-freeze.md`. This file stays as the registry of what was found and what closed it. Do **not** open an A21 |
| **Closure** | **`fix/design-system-v1-closure`** (2026-09-04) — every finding in §16–§19 carries a disposition in **§27**. **Final scores at the V1 freeze (M100.40, 2026-09-05): §23 = 30 / 30, §24 = 22 / 22.** The device suite, the one criterion still NOT RUN at closure, was run: 8 of 8 on `emulator-5554`. Registry rows below are left as found at CURRENT_SHA; §27 is the record of what closed them |
| **Purpose** | Refresh and correct A20 against current `main`, and become the single authoritative finding registry and implementation plan for the design system V1 MASTER FIX |
| **CURRENT_SHA** | **`b7f45dc4b9a702c6812fd0b1490eafbebb8ddebf`** — *refactor(row): the row is the M3 rectangle; close the three P3 debts of M100.36* (#452) |
| **A20_BASE_SHA** | **`b2d134b748c214c4130966358249d33fad5c4dea`** |
| **Pinned SDK** | Flutter **3.44.8** stable · framework `058e0af2c2` · Dart 3.12.2 — installed locally and read directly for every Material claim |
| **Supported product surface** | **Android only** (AD-04). Web builds and is the E2E/visual-regression channel; it is **not** a released surface. iOS deferred |
| **Last updated** | 2026-09-04 — **correction pass** (A20.1 is corrected in place; no A20.2): raw-Material arithmetic (22 + 17 = 39), the width finding reconciled against the current stress matrix, the loading-indicator guard narrowed so the determinate ring stays allowed, `Scaffold` reclassified, the P0 closure test made implementation-neutral, and the two scores recomputed with verification criteria removed from the architectural set |

---

## 1 · Executive verdict

Two verdicts, reported independently, because A20 conflated them.

> **A · DESIGN SYSTEM V1 — ARCHITECTURALLY CLOSED: NO.**
> Four systemic gaps remain: one component family has no route owner
> (sheets), one has no semantic owner (loading/progress), the restyle
> vocabulary is unenforced in three spellings, and the enforcement layer has no
> ratchet for the names the architecture actually forbids. **Score 13/30**
> (§23 — ownership, role correctness, closed APIs, enforceability and
> component-level accessibility contracts; coverage properties live in §24).
>
> **B · DESIGN SYSTEM V1 — FULLY VERIFIED / RELEASE READY: NO.**
> High contrast is rendered nowhere, and eight screens sit in features with no
> accessibility sweep at all. **Score 11/22.**

**51 active findings — 1 P0 · 15 P1 · 21 P2 · 14 P3.**

**One P0**, and it is the only finding that blocks a user on the supported
surface: the `browse` study mode can be advanced only by a 70 dp horizontal
drag, with no single-pointer alternative (WCAG 2.5.7). A20 registered five P0s;
per §6's calibration four of them were not P0 — a false-green guard, a
self-referential parity gate and a missing focus ring are architecture and
accessibility defects, not user-blocking ones, and the async-confirm dialog's
lost Undo is recoverable from Trash (BR-264).

**Two corrections this pass makes to its own earlier text**, both because a
scanner claim was checked against the source rather than carried forward:
component goldens **are** shot at 360 dp (`golden_pump.dart:16`,
`kGoldenSurface = Size(360, 640)`), so "no picture at 360" was wrong and the
375 residual retires with it (§19); and a blanket ban on `BoxDecoration` would
have gone red on **30 correct token-fed sites**, so P2-08 closes by contract
instead (§18).

**M100.36 was substantial and closed real ground.** The token layer stayed
closed and got smaller; two API escape hatches are gone; the focus grammar was
unified across row, pressable, pill and card; nine `Divider` call sites moved
onto the theme. What it did **not** touch is the enforcement layer (guard config
is byte-identical to A20) and the kit (elevation.css unchanged).

**The single most useful correction in this pass** is §8: A20's "40 raw-Material
violations" is not 40 violations. Classified against the architecture, **17 of
the 39 current sites are legitimate** — theme-owned separators, framework paint
hosts, and compositions with written reasons. **22** represent a real ownership
gap, and they are two families: 16 raw sheet routes and 6 raw loading spinners.
A guard built from A20's list would have banned correct code and produced
exactly the wrapper spam §20 warns against.

---

## 2 · CURRENT_SHA and A20_BASE_SHA

```
A20_BASE_SHA  b2d134b748c214c4130966358249d33fad5c4dea   docs(audit): correct A18's R3 and R7 (#449)
CURRENT_SHA   b7f45dc4b9a702c6812fd0b1490eafbebb8ddebf   refactor(row): the row is the M3 rectangle (#452)
```

Both read from `origin/main`. The working tree at CURRENT_SHA analyzes clean and
the full non-golden host suite passes (§22).

---

## 3 · Post-A20 change inventory

`git log --oneline b2d134b7..b7f45dc4` — four commits, two of them code:

| commit | what |
|---|---|
| `4ab2846f` + `0742671b` | A20 itself (docs only) |
| **`1c917344`** | **M100.36** — Button, TextField/Search, Row, Chip/Pill close their contracts (#451) |
| **`b7f45dc4`** | **row is the M3 rectangle**; closes three P3 debts of M100.36 (#452) |

`git diff --stat` = **224 files, +7056 / −1357**. In `lib/`: **51 files,
+1363 / −753**, one file added (`mx_badge.dart`), none deleted.

### 3.1 · What changed, by layer

| layer | change |
|---|---|
| **Foundations** | `app_border_colors.dart` −57 (**`borderDivider` retired** — in light it was the page colour); `app_semantic_colors.dart` −10 (27 → **26** stored fields); `app_sizing.dart` +17 (`rowMinHeight` = 56) |
| **Accessor extension** | `theme_context_extension.dart` **+13 — a fifth accessor, `inputHintStyle`** |
| **States** | `app_interaction_states.dart` +42/−… — `stateLayer*` alphas from `_FilledButtonDefaultsM3`; two blend tokens retired |
| **Component themes** | `app_button_themes` (canonical filled state layer), `app_input_theme` (`focusedErrorBorder` at `AppStroke.focus`, per-state `hintStyle`, `WidgetStateColor suffixIconColor`), `app_list_tile_theme` (**drops `textColor` and `shape`**, `minTileHeight`), `app_chip_theme` (flat, elevation 0 both states), `app_toggle_themes` |
| **Shared widgets** | `mx_pill_button` +319 (flat ChoiceChip, stable 16 dp tick slot, ring traces the painted shape), `mx_list_tile` +196 (tri-state `isSelected`, `ExcludeFocus` for inert rows), `mx_text_field` +135 (**`textStyle`/`textAlign`/`isReadOnly` removed**, three closed enums added), `mx_search_field` +113 (required `semanticLabel`, `ConstrainedBox` floor), `mx_action_button` +114, `mx_focus_ring` +37 (`FocusHighlightMode.traditional` gate), `mx_radio_rows` (**`contentPadding` removed**), **`mx_badge.dart` new** |
| **Features** | 9 `Divider` sites moved onto the theme; tag-filter entry left `MxPillButton`; study grading one-primary |
| **Guard** | **nothing — `code-verification-guard-v2/` diff is empty** |
| **Kit** | `mx.css` −/+34, `colors.css` ±6. **`elevation.css` untouched** |
| **Tests / goldens** | +14 goldens (237 → **251**); 477 test files; new contract suites for list tile, text field, pill construction, composite button state; **`mx_stress_test.dart` gained a width × scale matrix — every shared specimen at 360 / 375 / 393 dp × 1.3 / 2.0, inputs at 2.5 / 3.0 × 320, on top of the 320 × 2.0 floor** |

### 3.2 · Two facts that decide many rows below

1. **The guard configuration is byte-identical to A20.** Every enforcement
   finding therefore reproduces unchanged, and every count A20 took of what the
   guard cannot see is still the guard's blind spot.
2. **`elevation.css` and `css_scale_parity_test.dart` are untouched**, so the
   kit↔Dart divergence A20 measured stands exactly.

---

## 4 · A20 finding reconciliation matrix

All **46** A20 findings (5 P0 · 13 P1 · 16 P2 · 12 P3). `Repro?` = reproduced
against CURRENT_SHA by re-running A20's own scanners plus targeted reads.

| OLD_ID | OLD_SEV | OLD_SUMMARY (abbrev) | Post-A20 change? | Repro? | ACTION | NEW_ID | NEW_SEV |
|---|---|---|---|---|---|---|---|
| A20-P0-01 | P0 | Guard raw-widget hole, "40 live violations", green | guard untouched; sites 40→39 | partly | **SPLIT + DOWNGRADE** | P1-01, P1-02, P1-03, P2-01 | P1/P2 |
| A20-P0-02 | P0 | `browse` no accessible operation (keyboard + non-drag) | no | **yes** | **UPDATE** (reframe to non-drag; keyboard split out) | **P0-01**, P3-01 | **P0** |
| A20-P0-03 | P0 | Breadcrumb fold: no focus indication | file untouched | **yes** | **DOWNGRADE** | P1-04 | P1 |
| A20-P0-04 | P0 | Async confirm mid-write dismissal loses Undo | no | **yes** | **DOWNGRADE** (soft delete, BR-264 recoverable) | P1-05 | P1 |
| A20-P0-05 | P0 | Elevation parity gate self-referential; kit/Dart diverged | no | **yes** | **DOWNGRADE** (§6: false-green ≠ P0) | P1-06 | P1 |
| A20-P1-01 | P1 | No `MxSheet`: 16 routes, 5 insets, 1/17 headers | no | **yes** | **KEEP** | P1-01 | P1 |
| A20-P1-02 | P1 | `textStyles.copyWith` outside the rule; rule stops at features | no | **yes** — recounted canonically: **9 feature + 15 shared = 24 migration sites** | **UPDATE** (canonical count; 4 sub-defects named) | P1-07 | P1 |
| A20-P1-03 | P1 | No glyph scales with text | no | yes (0 `applyTextScaling`) | **DOWNGRADE** (§12: no concrete defect) | P3-02 | P3 |
| A20-P1-04 | P1 | High contrast rendered nowhere | goldens 237→251, still 0 | **yes** | **KEEP** (counts updated) | P1-08 | P1 |
| A20-P1-05 | P1 | Accessor extension audited by nobody | **+1 accessor** | **yes, worse** | **UPDATE** (evidence strengthened) | P1-09 | P1 |
| A20-P1-06 | P1 | w700 registry is prose; test title now false | no | **yes** | **KEEP** | P1-10 | P1 |
| A20-P1-07 | P1 | boldText no-op **+** 19/21 all-caps unnamed | no | **yes**, but two root causes | **SPLIT** | P1-11, P2-02 | P1 / P2 |
| A20-P1-08 | P1 | FAB + SnackBar elevation, no `materialShadowColor` | no | **yes** | **KEEP** | P1-12 | P1 |
| A20-P1-09 | P1 | No warning tone **+** error/empty misuse **+** silent spinner | no | **yes**, three root causes | **SPLIT** | P1-13, P2-03, P1-02 | P1 / P2 |
| A20-P1-10 | P1 | 360 / 375 dp rendered nowhere | **yes — `mx_stress_test.dart:102` pumps 360 / 375 / 393 × 1.3 / 2.0 for every shared specimen (M100.36)** | **no** | **RESOLVED_BY_LATER_CHANGE** — and its one-time residual (P3-15) was itself retired once 360 was confirmed as the component-golden surface (§19), so nothing carries forward | — | — |
| A20-P1-11 | P1 | `MxActionSheet` rows raw `ListTile`, no focus ring | focus grammar unified elsewhere | **yes** | **UPDATE** (now the hold-out) | P2-04 | P2 |
| A20-P1-12 | P1 | Nav chrome: no bar on loading/error **+** two up-grammars **+** "ink is the inverse of M3" | no | 2 of 3 | **SPLIT + CORRECT** | P1-15, P1-16, P2-05 | P1/P1/P2 |
| A20-P1-13 | P1 | Slider guard pins the wrong defaults class | no | **yes**, refined | **DOWNGRADE + UPDATE** | P2-06 | P2 |
| A20-P2-01 | P2 | `MxMetricWell.wellColor` open beside closed `AppInk` | no | **yes** | **KEEP** | P2-07 | P2 |
| A20-P2-02 | P2 | `BoxDecoration`/`Border.all` outside the style rule | 29→27 | **yes, but not a defect** — all 30 sites token-fed, and every decision inside them is already closed by an existing rule (§9) | **ACCEPTED_BY_CONTRACT** — token-fed composition is allowed; banning the constructor would go red on 30 correct sites | — | — |
| A20-P2-03 | P2 | No stroke guard; 5 literals; 20 implicit `1.0` borders | **5 → 2 literals** | partly | **UPDATE** | P2-09 | P2 |
| A20-P2-04 | P2 | Spacing guard blind to `const double` declarations | no | **yes** | **KEEP** | P2-10 | P2 |
| A20-P2-05 | P2 | High-contrast `onDisabled` row wrong in all four figures | inputs unchanged | **yes** | **KEEP** | P2-11 | P2 |
| A20-P2-06 | P2 | 32 dp tier five spellings; `AppSpacing.xxl` as a dimension | no | **yes** (5 / 7) | **KEEP** | P2-12 | P2 |
| A20-P2-07 | P2 | Four heading policies; row announces state twice; switch stacks channels | list tile reworked | partly | **SPLIT** | P2-02, P2-13 | P2 |
| A20-P2-08 | P2 | `borderOption` 2.67:1; single-choice menu unannounced | token unchanged | **yes** | **KEEP** | P2-14 | P2 |
| A20-P2-09 | P2 | Disabled selection controls lose their boolean | toggle theme touched | **yes** | **KEEP** | P2-15 | P2 |
| A20-P2-10 | P2 | Pickers: disabled+selected one colour; 12/24h disagreement | no | **yes** | **KEEP** | P2-16 | P2 |
| A20-P2-11 | P2 | 10/17 screens no sweep; silent failure faces; no HC screen | no | **yes** (measured 8 screens in 4 unswept features) | **UPDATE** | P2-17 | P2 |
| A20-P2-12 | P2 | Shell geometry: hairline, max width, FAB clearance, scaler | no | **yes** | **KEEP** | P2-18 | P2 |
| A20-P2-13 | P2 | Icon vocabulary conflicts | no | **yes** | **KEEP** | P2-19 | P2 |
| A20-P2-14 | P2 | Snackbar 4 s vs undo 8 s | no | **yes** | **KEEP** | P2-20 | P2 |
| A20-P2-15 | P2 | Pickers unrendered; `MxDropdown` undocumented states | no | **yes** | **KEEP** | P2-21 | P2 |
| A20-P2-16 | P2 | `lib/app/` in no typography scope | no | **yes** | **KEEP** | P2-22 | P2 |
| A20-P3-01 | P3 | `MxProgressBarShape.flush` zero callers | no | **yes** | **KEEP** | P3-03 | P3 |
| A20-P3-02 | P3 | Four refs to two deleted files | no | **yes** | **KEEP** | P3-04 | P3 |
| A20-P3-03 | P3 | Stale cross-references in the design system | some corrected by #451 | partly | **UPDATE** | P3-05 | P3 |
| A20-P3-04 | P3 | Four dead rulesets vendored | no | **yes** (5 dirs) | **KEEP** | P3-06 | P3 |
| A20-P3-05 | P3 | `cupertino_icons` unused; `Icons.ios_share` on Android | no | **yes** | **KEEP** | P3-07 | P3 |
| A20-P3-06 | P3 | `mdCompact` / `AppRadius.xl` uncovered | no | **yes** | **KEEP** | P3-08 | P3 |
| A20-P3-07 | P3 | Four `elevation: 0` literals; raw `4`; radius guard warning | no | **yes** | **KEEP** | P3-09 | P3 |
| A20-P3-08 | P3 | Route naming and announcement | no | **yes** | **KEEP** | P3-10 | P3 |
| A20-P3-09 | P3 | `MxFormDialog.isSubmitting`, `MxActionSheetAction.isEnabled` dead | no | **yes** | **KEEP** | P3-11 | P3 |
| A20-P3-10 | P3 | `MxIcon` has no unit test | no | **yes** | **KEEP** | P3-12 | P3 |
| A20-P3-11 | P3 | `MxBreadcrumb.lineHeight: 32` below the touch floor | no | **yes** | **KEEP** | P3-13 | P3 |
| A20-P3-12 | P3 | `AppStroke.input` misnamed; `MxSearchField` implicit 1.0 | **search edge now `AppStroke.input`** | half | **UPDATE** | P3-14 | P3 |

**Tally.** 46 in (5 P0 · 13 P1 · 16 P2 · 12 P3), by final action:

| ACTION | n |
|---|---|
| KEEP | 26 |
| UPDATE | 8 |
| SPLIT | 5 |
| DOWNGRADE | 5 |
| RESOLVED_BY_LATER_CHANGE | 1 |
| ACCEPTED_BY_CONTRACT | 1 |
| **total** | **46** |

26 + 8 + 5 + 5 + 1 + 1 = 46. Counting severity movement rather than primary
action, **7** rows were lowered (the 5 `DOWNGRADE`s plus 2 inside a split) and
**0** raised.

Out: **1 P0 · 15 P1 · 21 P2 · 14 P3 = 51**.

**Three rows carry no forward obligation** and their `NEW_ID` is therefore `—`,
not a finding id:

- **A20-P1-10 → RESOLVED_BY_LATER_CHANGE.** M100.36's stress matrix pumps
  360 / 375 / 393 (`mx_stress_test.dart:102`). Its one-time golden residual was
  filed as P3-15 and then **retired** once 360 was confirmed as the
  component-golden surface (§19), so nothing carries forward.
- **A20-P2-02 → ACCEPTED_BY_CONTRACT.** Token-fed composition is allowed; every
  decision inside a `BoxDecoration` is already closed by an existing rule (§9).
  It was briefly filed as P2-08, which is now closed by the same contract (§18).
- P1-14 was retired earlier into P3-15, which is why P1 has a gap at 14.

**~~P2-08~~ and ~~P3-15~~ are historical only.** Neither is an active finding,
neither appears in any implementation phase, and neither is counted in the 51.

M100.36 targeted the four component audits (#431–#434), not A20's registry;
one A20 row was nevertheless closed by its Phase 6 stress matrix, and it closed
real ground inside several other rows, which §5 records.

---

## 5 · Findings resolved since A20

One A20 row was resolved outright, and **what M100.36 closed inside other
rows is narrower than the registry and worth recording**, because it is evidence
about the direction of travel and it removes work from the DAG:

| closed | evidence |
|---|---|
| **A20-P1-10 — "360 / 375 dp rendered nowhere"** (was A20.1-P1-14, now retired) | `test/shared/widgets/mx_stress_test.dart:102-103` pumps **360 / 375 / 393 × 1.3 / 2.0** for every shared specimen (`MxHeroCard` included) and **2.5 / 3.0 × 320** for the inputs, on top of the 320 × 2.0 floor; each pump asserts no layout overflow. The layout-tier width matrix A20 asked for exists, so this closes outright. It briefly carried a golden residual (~~P3-15~~), and that was retired too: 360 dp **is** the component-golden surface (`golden_pump.dart:16`, `kGoldenSurface = Size(360, 640)`) and 375 shares every branch with the already-pictured 393 — §19 |
| `MxTextField.textStyle` — an open `TextStyle?` on the shared surface | gone; replaced by `emphasis` / `content` / `supportingLine`, three closed enums with a caller behind every member |
| `MxTextField.textAlign`, `MxTextField.isReadOnly` | removed, zero callers |
| `MxRadioRows.contentPadding` — an open `EdgeInsetsGeometry` | removed; the gutter follows the shape |
| **Visual escape-hatch census 9 → 7** | §6.1 of A20, re-run at CURRENT_SHA |
| `MxSearchField` had no accessible name | `semanticLabel` and `clearSemanticLabel` now required |
| Focus grammar split across row / pressable / pill | one answer: `MxFocusRing` + `FocusHighlightMode.traditional`, adopted by `MxPressable` and `MxListTile` |
| Nine `Divider` sites carrying their own colour/height | **7 of 10 are now bare `Divider()`** — the theme owns the line, layout owns the gap |
| `borderDivider` — a second hairline that in light was the page colour | retired from extension, palette, kit and parity map |
| Two hand-written muted-badge recipes | one `MxBadge` primitive, catalogued and stress-tested |
| `MxActionButtonVariant.tonal` — zero callers | removed end to end |
| Raw stroke literals 5 → 2 | both remaining are `strokeWidth: 2` inside `mx_action_button.dart` |

---

## 6 · Findings retained or changed — the four that changed most

**A20-P0-01 → four findings.** A20 counted 40 raw-Material sites and treated
the count as the defect. §8 below classifies all 39 current sites; 17 are
legitimate and 22 need a shared owner. What survives is two ownership gaps
(sheet route, loading semantics), one pure ratchet (screen chrome, zero current
violations) and one enforcement gap.

**A20-P1-12's third claim is wrong and is corrected.** A20 wrote that
"`app_app_bar_theme.dart:15` gives leading `onSurfaceVariant` and
`app_icon_button_theme.dart:21` gives actions `onSurface` — the exact inverse of
M3". Both files are untouched since A20 and the citations are **swapped**:
`app_app_bar_theme.dart:17` sets `foregroundColor: scheme.onSurface` and
`app_icon_button_theme.dart:21` sets `foregroundColor: scheme.onSurfaceVariant`.
Read against `_AppBarDefaultsM3` (§11.3) the actions are **canonical** and only
the leading is one ink step quiet. Not an inversion — a single-slot deviation,
P2.

**A20-P1-07 splits.** `boldText` and all-caps share a file and nothing else:
different root cause, different fix, different test. And the all-caps half is
materially overstated — §13 below.

**A20-P1-13 sharpens.** The Slider theme declares eleven colour slots from the
2024 palette and leaves `year2023` unset, so `slider.dart:834` resolves
`_SliderDefaultsM3Year2023` for everything it does *not* declare — geometry
included. The defect is not "the guard pins the wrong class"; it is that **the
theme is split across two Material generations** and the guard cannot see it
because it only asserts what the theme itself declares. Latent (no renderer) ⇒
P2.

---

## 7 · Severity recalibration

Applying §6 strictly.

| A20 | finding | why it is not P0 |
|---|---|---|
| P0-01 | guard hole | §6 names this exactly: *"Do not classify something P0 merely because a guard is incomplete."* No user is blocked. → P1/P2 |
| P0-03 | breadcrumb fold focus | The control is labelled (`Semantics(button, label, value)`), reachable and operable by TalkBack and by touch. The defect is that a sighted keyboard/Switch-Access user cannot see *where* focus is. Real (WCAG 2.4.7 AA) and narrow. → P1 |
| P0-04 | async-confirm Undo | Deck/card delete is **soft**: BR-264 gives 30-day retention and Trash restores it. What is lost is the immediate Undo and any success message — a broken feedback contract on a destructive path, not data loss. → P1 |
| P0-05 | parity gate | §6 again: *"a parity test is false-green"* is explicitly not P0. → P1 |

**What stays P0.** `browse` cannot be advanced without a 70 dp drag. Android is
the only released surface; the mode is first in every `eight_box` new-learning
sequence (BR-110); and there is **no `onTap` at all** on the gesture layer. A
touch user with a tremor, using one hand, or with a stylus, who does not run an
assistive technology, has no way forward. That is WCAG 2.5.7 (AA) on a core
path — user-blocking on the supported surface.

---

## 8 · Raw Material ownership taxonomy

**39 raw high-level Material sites** in `lib/features/*/presentation/` at
CURRENT_SHA (A20 measured 40; one `Material(` went with M100.36). Measured with
the guard's own scope and its own comment-exempt line idiom, with a control
group of the 44 names the guard *does* ban returning **0**.

The invariant is **zero unjustified raw high-level Material usage**, not zero
raw Material usage.

| API | n | locations | classification | shared owner | guard? |
|---|---|---|---|---|---|
| `showModalBottomSheet` | **16** | 13 files across card/deck/study/trash | **SHARED_REQUIRED** | none exists — `showMxFormSheet` covers one shape | **yes, after the owner lands** |
| `Divider` (bare) | **7** | card ×5, reminder ×1, study ×0 | **THEMED_RAW_ALLOWED** | `dividerTheme` — one hairline, `outlineVariant` | **no** |
| `Divider` (per-site args) | **3** | `tag_catalog_screen:194` (list inset), `card_import_stepper:87` (colour = step state), `study_card_face_section:321` (face rule) | **FEATURE_SPECIAL_CASE_ALLOWED** — each carries a written reason | — | **no** |
| `CircularProgressIndicator` — full-area | **2** | `card_editor_screen:190`, `card_bulk_overlays:97` | **SHARED_REQUIRED** | `MxLoadingState` exists and is bypassed | **yes, after the owner lands** (`no_raw_loading_indicator`, §9) |
| `CircularProgressIndicator` — in-column | **2** | `card_import_preview_step:194`, `card_import_submit_progress:33` | **SHARED_REQUIRED** | same recipe twice; needs a no-padding variant | **yes, after the owner lands** |
| `CircularProgressIndicator` — inline 16 dp | **2** | `card_history_section:306`, `search_page_footer:56` | **SHARED_REQUIRED** | none — the same recipe written twice in two features | **yes, after the owner lands** |
| `CircularProgressIndicator` — determinate ring | **1** | `card_progress_panel:178` (`value: fraction`, `Positioned.fill`) | **FEATURE_SPECIAL_CASE_ALLOWED** | a mastery ring is not a loading spinner | **no — named on the rule's `exclude:` list with this reason** (§9) |
| `Material` | **2** | `reminder_settings_section:91` (transparent **ink host** — Flutter asserts without it), `trash_selection_bar:42` (**surface host**, colour from a role) | **FRAMEWORK_PRIMITIVE_ALLOWED** | — | **no** |
| `Chip` + `ActionChip` | **2** | `card_tag_section:290,299` — a deletable tag chip and an add-tag command | **FEATURE_SPECIAL_CASE_ALLOWED** — owner-accepted in #452 ("the only fix would replace the delete affordance the owner pinned"); `MxPillButton` is a pick-one `ChoiceChip`, a different semantic | `chipTheme` owns the paint | **`ChoiceChip` only** |
| `TextField` | **1** | `fill_answer_pieces:187` — chrome-less editable that **is** the card (`expands: true`, every border state off, name supplied by `Semantics`) | **FEATURE_SPECIAL_CASE_ALLOWED** | `MxTextField` is a decorated field; it cannot express this | **no** |
| `showTimePicker` | **1** | `reminder_time_picker:24` | **THEMED_RAW_ALLOWED** | `timePickerTheme` owns it; one caller | **no** |

**Totals: 22 SHARED_REQUIRED · 8 THEMED_RAW_ALLOWED · 2 FRAMEWORK_PRIMITIVE ·
7 FEATURE_SPECIAL_CASE · 0 UNRESOLVED.** Arithmetic from the table:
SHARED_REQUIRED = 16 sheets + (2 + 2 + 2) spinners = **22**; THEMED_RAW =
7 bare `Divider` + 1 `showTimePicker` = 8; FRAMEWORK_PRIMITIVE = 2 `Material`;
FEATURE_SPECIAL_CASE = 3 argued `Divider` + 1 determinate ring + 2 chips +
1 chrome-less `TextField` = 7. 22 + 8 + 2 + 7 = **39**, and the allowed set is
8 + 2 + 7 = **17** = 39 − 22.

### 8.1 · What this changes

A20's headline "40 live violations" becomes **22** — and those 22 are two
families with two owners to build (16 sheet routes, 6 loading spinners), not
twenty-two decisions. The other **17** are code doing the right thing:

- A bare `Divider()` **is** the design system working — the theme owns the line
  and the layout owns the gap. That was M100.36's explicit decision (10H), and
  an `MxDivider` would be the wrapper spam §20 forbids.
- `Material(type: transparency)` is an ink host that Flutter *requires*; the
  file says the framework asserts without it.
- The tag `Chip` was examined and accepted by the owner eight days ago.

---

## 9 · Corrected guard strategy

A guard must represent an architectural decision, not create one.

> **Two counts, kept apart deliberately, because conflating them is how §9 and
> the DAG drifted apart before:**
>
> - **`GUARD_RULE_COUNT` = 5** — the design-system guard *rules* that follow
>   from §8's taxonomy: `no_raw_sheet_route`, `no_raw_loading_indicator`,
>   `no_raw_screen_chrome`, `no_raw_choice_chip`, `no_text_restyle`.
> - **`ENFORCEMENT_ACTION_COUNT` = 8** — those 5 rules **plus** 3 enforcement
>   actions that do not come from §8's taxonomy and are not design-system
>   rules: the stroke-width guard (P2-09), the geometry `const double` scan
>   (P2-10), and adding `lib/app/**` to the typography scope (P2-22).
>
> Phase 0 lands **2 guard rules**; Phase 6 lands the remaining **3 guard rules
> + 3 enforcement actions = 6 Phase-6 actions**. "Six" is never a count of
> rules.

The five rules follow from §8; the rest of A20's 71-name list does not.

**The admission test for every rule below is the same, and it is a
sequencing rule, not a style preference:**

```
live-tree scan == 0   →  the rule may ratchet immediately (Phase 0)
live-tree scan  > 0   →  fix the violations, verify zero, THEN enable the rule
```

A rule enabled over live violations is either a red gate nobody can merge
past, or a rule quietly landed at `warning` and never raised — and the second
is how a guard becomes decoration. The `blocked by` column below is that scan,
not an opinion.

| proposed rule | names | scope | why | blocked by |
|---|---|---|---|---|
| `no_raw_sheet_route` | `showModalBottomSheet`, `showBottomSheet` | `presentation_files` | the app must open a sheet through one owner; five inset mechanisms are the proof it currently does not | **P1-01** — guarding first would ban the only mechanism that exists |
| `no_raw_loading_indicator` | `CircularProgressIndicator`, `LinearProgressIndicator` — **with an explicit `exclude:` for the determinate-progress callers** (today exactly one: `lib/features/card/presentation/widgets/sections/card_progress_panel_widget.dart`, `value: fraction`, a mastery ring), each entry carrying its reason in the rule file | `presentation_files` | the *accessible name of a loading state* must have one owner; the silent spinner is the proof. A determinate ring is not a loading state — §8 classifies it FEATURE_SPECIAL_CASE_ALLOWED, and the rule must agree with the taxonomy it enforces. `exclude:` is the guard's existing per-rule mechanism (used by `memox-architecture-rules.yaml`), so this needs no new capability; the alternative — matching only constructions with no `value:` argument — is more precise but needs a balanced-paren file walk for one site, and was rejected as machinery for a scanner. A new determinate caller is added to `exclude:` **with its reason** in the same change; an entry without a `value:` at the site is a violation of the rule's own contract and the live-tree scan must say so. **No `MxProgressRing` wrapper is created to satisfy the scanner** | **P1-02** — the six SHARED_REQUIRED spinner sites become guardable only once the loading family owns their shapes |
| `no_raw_screen_chrome` | `AppBar`, `SliverAppBar` — **`Scaffold` is not in this rule** | `presentation_files` | `MxContentShell` owns the *chrome* (bar, subheader, back affordance); **zero current violations**, so this is a pure ratchet. `Scaffold` is classified **FRAMEWORK_PRIMITIVE_ALLOWED**: it is the framework's layout host, not a design-system component; no architecture decision (AD-01…AD-19) forbids a feature from owning one, and `mx_content_shell.dart:99` ("owning the `Scaffold` is what makes this the shell's job") documents why the *shell* builds its own — it is not a prohibition on features. Zero raw `Scaffold` in `lib/features/` today, so nothing is lost by not ratcheting it; banning a framework host on the strength of a wrapper's existence is the reasoning §20 forbids. No `MxScaffold` is proposed | nothing — land immediately |
| `no_raw_choice_chip` | `ChoiceChip` | `presentation_files` | `MxPillButton` owns pick-one. `Chip`/`ActionChip`/`InputChip` deliberately **not** included | nothing |
| `no_text_restyle` (extend) | add `textStyles.<role>.copyWith(`; widen scope to `ui_surfaces`; `mode: file`; **plus an alias-tracking regression probe** (below) | `ui_surfaces` | four spellings of one decision escape today, and a fifth launders through a local | **P1-07 — 24 migration sites** (`FEATURE_UNIQUE` 9 + `SHARED_UNIQUE` 15). Cleanup first; the rule lands in Phase 6 |

**Explicitly not guarded**, and the reason recorded so the next audit does not
re-propose them: `Scaffold` (framework host, above), `Divider`,
`VerticalDivider`, `Material`, `Ink`, `SafeArea`, `Chip`, `ActionChip`,
`InputChip`, `TextField`, `showTimePicker`, `showDatePicker`, `Tooltip`,
`Drawer`, `DataTable`, `Stepper`, and — by `exclude:` rather than by name — the
determinate progress ring.

**Composition primitives are not guarded either, and this is the architecture
rule rather than an omission** (see P2-08). `BoxDecoration`, `DecoratedBox` and
`Border` are framework *composition*; feature code may compose them **provided
every visual decision inside is already design-system owned**. Every such
decision is already closed by an existing `memox-v7` rule:

| decision reachable inside a `BoxDecoration` | already closed by | scope |
|---|---|---|
| `color:` raw hex / `Colors.x` / `Color.fromARGB` | `memox.design_token.no_raw_color` | `ui_surfaces` |
| `borderRadius: BorderRadius.circular(<literal>)` | `memox.design_token.no_raw_border_radius` | `ui_surfaces` |
| `boxShadow: BoxShadow(` · `border: BorderSide(` · `ShapeDecoration(` · `RoundedRectangleBorder(` | `memox_v7.design_system.no_raw_style_escape` | `presentation_files` |
| `TextStyle(` | `memox.design_token.no_raw_text_style` | `ui_surfaces` |
| spacing literals | `memox.design_token.no_raw_spacing_literal` | `ui_surfaces` |

The **one** decision still open inside them is the border *width* — and that is
P2-09's rule, aimed at the open decision rather than at the constructor. No
`MxDecoration`, `MxBox` or equivalent wrapper is proposed; §20 forbids exactly
that, and the guard is green on all five rules above today.

**The determinate-progress `exclude:` needs a companion assertion, and the
MASTER FIX must add it.** A file-level `exclude:` says "this file may build a
progress indicator"; it does not say "and only a determinate one". Without a
companion check, a later indeterminate spinner added to
`card_progress_panel_widget.dart` inherits the exemption silently. The closure
contract for `no_raw_loading_indicator` is therefore four assertions, not one:

1. the rule catches a raw loading indicator in feature code (positive probe);
2. the rule does not catch the same name inside a comment (false-positive probe);
3. the `exclude:` list contains **only** named determinate sites, each with its
   reason in the rule file;
4. a companion test walks **every construction inside every excluded file** and
   asserts each names a non-null `value:` — so adding
   `CircularProgressIndicator()` with no `value:` to an excluded file **fails**.

Assertion 4 is the one that makes the exemption safe; it is specified here and
implemented in the MASTER FIX, not in this docs-only pass.

**`no_text_restyle` needs a companion of its own, for the same class of reason:
a regex cannot follow a local binding.** `mx_search_field.dart:139` writes

```dart
final TextStyle text = context.texts.bodyMedium!;
final TextStyle hint = text.copyWith(color: colors.onSurfaceVariant);
```

The receiver at the `.copyWith` is a bare identifier, so **no** receiver
pattern — not `texts.`, not `textStyles.`, not `textTheme.`, not
`withWeight(…)` — can reach it. Widening the scope does not help; `mode: file`
does not help. It is a real restyle and a real migration site (it is one of
P1-07's 24), and the rule will be green over it forever unless something else
looks.

**The alias regression probe.** A test, not a guard pattern, because binding a
name is beyond regex. Over `lib/features/**` + `lib/shared/widgets/**`, comments
stripped, in two passes:

1. bind every local whose initialiser is a text style —
   `final TextStyle? <name> = <expr>;` where `<expr>` mentions `texts.`,
   `textStyles.` or `textTheme.`;
2. flag every `<name>.copyWith(` on a bound name.

Expected result **1 today** (`mx_search_field.dart:139`) and **0** after
P1-07's migration; the probe then stays as the ratchet that stops the next one.
It must be fault-injected like every other rule — add a synthetic alias, watch
it go red, remove it.

**Why this is a probe and not a rule:** the guard is a regex engine over single
files, and this needs two passes with state carried between them. Filing it as
a test keeps the guard honest about what it can and cannot see, which is the
same discipline the determinate-progress companion assertion follows.

Every proposed rule must ship with a **positive synthetic probe**, a **comment
false-positive probe** and a **live-tree scan**, and must be fault-injected —
demonstrated red before it is trusted green. This report proposes the contract
only; it changes no rule.

---

## 10 · ThemeData closure by sub-layer

A20 said "the ThemeData layer is CLOSED". That is true of exactly one sub-layer.

| sub-layer | status | evidence |
|---|---|---|
| **Slot coverage** | **CLOSED** | `theme_coverage_test.dart` — 56 widget→slot mappings, `rendered ⇒ themed` **and** `themed ∧ ¬rendered ⇒ named reason` **and** the allowlist-went-stale converse, plus a named blind spot (`DropdownButton` has no slot, closed via `canvasColor`/`disabledColor`) and a self-test. Green |
| **Ownership** | **CLOSED** | component builders take `ColorScheme` / `TextTheme` / `AppSemanticColors` / closed enums; they may not import the four palette files. 113 colour literals, all in `theme/foundations/`; 14 `Colors.*`, all `transparent`, all inside `core/theme/` |
| **Canonical role correctness** | **OPEN** | app-bar leading resolves `onSurfaceVariant` where `_AppBarDefaultsM3.iconTheme` says `onSurface` (P2-05); Slider declares 2024 colours on 2023 geometry (P2-06); date picker checks `disabled` before `selected` where the SDK checks `selected` first (P2-16) |
| **Combined-state correctness** | **PARTLY CLOSED** | M100.36 added combined-state groups for TextField and ListTile. Still open: one `disabledSurface` where M3 uses two opacities; disabled ticked checkbox draws a ring M3 makes transparent; radio has no interaction rung (P2-15) |
| **Accessibility correctness** | **OPEN** | the high-contrast palette's own figures are wrong in all four cells and the 62% decision rests on a number 28% optimistic (P2-11); `borderOption` at 2.67:1 on a component that *is* its edge (P2-14) |
| **Visual / depth correctness** | **OPEN** | FAB and SnackBar state `elevation: overlay` and never wire `materialShadowColor`, so both paint `scheme.shadow` in dark where the model says transparent (P1-12); kit and Dart disagree on the dark rim's colour, blur and spread (P1-06) |

**Verdict: ThemeData coverage CLOSED, ThemeData semantic correctness OPEN.**

---

## 11 · Accessibility and platform reconciliation

### 11.1 · The contract, established from the repo

**AD-04** (`docs/architecture.md:135`) is explicit: *Android is the release
target; the web build is kept alive as the E2E/visual-regression channel and is
not published; iOS is deferred.* It adds: *"Do not trade Android design so that
web looks better."*

So, in §11's terms: **A** = Android, the supported product surface. **B** = web,
a test channel. **C** = none. **B does not imply C**, and no keyboard finding may
be justified by the web build.

### 11.2 · What that does and does not downgrade

| input path | on Android | consequence |
|---|---|---|
| Touch | primary | a touch-only defect is full severity |
| **Single pointer without dragging** | **primary** — tremor, one hand, stylus, head pointer | **WCAG 2.5.7 applies at full weight.** This is P0-01 |
| TalkBack | first-class | `customSemanticsActions` serves it; the swipe deck is fine here |
| Switch Access | first-class, **focus-driven** | custom actions are exposed, so `browse` is operable; but a missing **focus indicator** is a real defect for this population (P1-04) |
| Physical keyboard | supported, secondary | not a reason to raise severity; not a reason to dismiss focus-visible either |

Two rules followed from §11: a real mobile accessibility defect is **not**
downgraded because keyboard is secondary (so P1-04 stays a finding), and
"zero keyboard primitives in `lib/`" is **not** itself a finding — it is a
consequence, recorded as a contract note at P3-01.

### 11.3 · The app-bar ink question, settled against the SDK

`_AppBarDefaultsM3` at 3.44.8: `backgroundColor` = `surface`, `foregroundColor`
= `onSurface`, `iconTheme` (leading) = **`onSurface`**, `actionsIconTheme` =
**`onSurfaceVariant`**.

The app sets `backgroundColor: surface` and `foregroundColor: onSurface` —
both canonical — and sets neither icon theme. `app_bar.dart:958-970` then
resolves `overallIconTheme = defaults.iconTheme!.copyWith(color: foregroundColor)`,
which for this app is **equal to `defaults.iconTheme`**; so the branch at
`:1025` is taken and the leading is handed the app's `iconButtonTheme` —
`foregroundColor: onSurfaceVariant`.

**Result: actions canonical, leading one step quiet.** Both inks are the app's
own secondary text colour and clear their contrast floors, so this is a
canonical-role deviation, not an accessibility defect → **P2-05**.

---

## 12 · Icon text scaling, re-evaluated per §12

`applyTextScaling` has **zero** occurrences in `lib/`. Per-role analysis:

| role | example | should scale? | why |
|---|---|---|---|
| **Control glyph** | `MxIconButton`, FAB, nav destination | **no** | the 48 dp target is the control; growing the glyph at 2.0× breaks the target grid and the toolbar rhythm. Fixed is correct |
| **Label-adjacent informative** | metric row glyph, list-row leading | **yes, capped** | it is read *with* the label; at 2.0× a 16 dp glyph beside a 28 dp label reads as decoration |
| **Decorative** | empty-state hero, section ornament | **no** | carries no information the label does not |
| **Status glyph** | card state chip, due/overdue marks | **yes, capped** | it is a second channel for a state the colour also carries; if the label grows and it does not, the pairing degrades |
| **Navigation glyph** | breadcrumb chevron, back | **no** | chrome geometry is fixed by the bar |

**No WCAG requirement is missed** — 1.4.4 Resize Text governs text, and every
icon in the app that carries meaning has a text label or an accessible name
beside it. The defect is a usability/consistency one, and it is **not** what A20
called it ("no glyph scales" framed as systemic).

**Action: DOWNGRADE A20-P1-03 → P3-02**, recorded as a per-role policy with a
test in both directions (the roles that opt in grow; `MxIconButton` does not).

---

## 13 · All-caps and accessible names, re-evaluated per §13

**21** `toUpperCase()` paint sites in `lib/`. Classified by what they uppercase
and what `Semantics` actually exposes:

| class | n | verdict |
|---|---|---|
| **Format identifier** — `file.format.name`, `option.format.fileExtension` (CSV / JSON / TSV) | **3** | **Correct as uppercase, and a TTS engine spelling them out is *desired*.** A "21/21 custom label" rule would be actively wrong here |
| **Localized heading with an accessible name** | **1** | `settings_section_widget.dart:53-56` — `Semantics(label: label, excludeSemantics: true)`, with the reason written: *"Some TTS engines spell an all-caps run out letter by letter, and these headings are what tell three rows all labelled 'System' apart."* This is the documented correct pattern |
| **Localized heading with no accessible name** | **16** | the finding |
| **Composed string** | **1** | `study_session_frame_section:188` |

And a **third** policy exists: `search_group_header_widget.dart` deliberately
does **not** uppercase, with an l10n argument — *"`toUpperCase()` on a localized
string is the translator's decision to make, not the widget's — it is wrong for
locales with no case"* — plus `Semantics(header: true)`.

**So the real finding is not "19 of 21 lack labels".** It is that **one
decision has three policies**, one of them documented as correct, one documented
as better still, and no shared component enforcing either. The app ships EN and
VI, both cased, so the l10n half is currently theoretical.

**Action: A20-P1-07 splits; the all-caps half becomes P2-02** — a consistency
finding whose fix is the shared `MxSectionLabel` (which also closes A19-07's
four heading policies), with the three format identifiers **excluded by
contract**.

---

## 14 · `surfaceTint`, correctly scoped

A20 stated `surfaceTint` is "architecturally unreachable". Re-verified at
CURRENT_SHA and re-scoped as §14 requires:

> **Under Flutter 3.44.8 and at `b7f45dc4`, `ColorScheme.surfaceTint` is
> unconsumed.** It is not passed to either scheme, never read in `lib/`, and the
> only SDK default that resolves `colorScheme.surfaceTint` is
> `_BottomAppBarDefaultsM3` (`bottom_app_bar.dart:301`), whose widget the app
> does not build. Five component themes additionally pin
> `surfaceTintColor: Colors.transparent`.

This is **not** a timeless invariant. `ColorScheme.surfaceTint`'s getter is
`_surfaceTint ?? primary`, so the moment a `BottomAppBar` is added — or an SDK
release routes another component through the role — elevated surfaces gain an
indigo tint with no code change here. **Re-check on every SDK bump**; recorded
as a contract, not a closure.

---

## 15 · Cross-report conflicts newly resolved

**15.1 · A20 vs the code on app-bar ink.** A20 (inheriting A8-P1-03) said the
inks are "the exact inverse of M3". Settled in §11.3 against
`_AppBarDefaultsM3` and `app_bar.dart:958-1031`: actions canonical, leading one
step quiet. A20's citations were swapped.

**15.2 · A13-P3-7 vs the palette file, re-confirmed.** A20 adjudicated in
A13's favour; the palette inputs are unchanged at CURRENT_SHA, so the figures
stand: normal **2.11 / 2.62**, high contrast **3.80 / 5.11**, against the file's
2.37 / 3.20 → 4.88 / 6.33, and `onSurface` is **11.50 / 12.01** where the same
block says 14.81. Unchanged conclusion, re-measured rather than carried
forward.

**15.3 · A9-16 vs A16-G-15 on the dark rim.** Compatible, and the resolution is
directional: **the kit follows Dart, never the reverse.** Adopting the kit's
`#6A7199` 2 px-blur stepping rim in Dart is precisely the action A9-16 measured
(1.14:1, ΔL\* 6.58) and rejected as re-introducing #435's halo.

**15.4 · "Ban raw Material" vs M100.36's own decision.** A20's raw-widget list
and M100.36 10H point opposite ways on `Divider`: 10H deliberately moved nine
sites *onto* the theme so that a bare `Divider()` is the correct spelling.
**M100.36 wins** — it is newer, it is code, and §7 of this task states the
invariant is zero *unjustified* raw usage. A20's list would have reverted a
deliberate decision made after it.

**15.5 · A20-P3-09 vs the tree on `isEnabled`.** A20 grouped
`MxActionSheetAction.isEnabled` with dead API. Verified: its only caller is
`test/shared/widgets/golden_hosts.dart:78`. Still dead — but note the
similarly-named `DeckSchedulerPickerWidget.isEnabled` **is** live
(`deck_scheduler_change_widget.dart:101`) and is a different API; a scan on the
bare name would merge them.

---

## 16 · Canonical A20.1 P0 registry

---

### A20.1-P0-01 · A11Y · `browse` cannot be advanced by a single pointer without dragging

- **Sources.** A19-01 → A20-P0-02, reframed per §11.
- **Current evidence (CURRENT_SHA).**
  `study_swipe_deck_widget.dart:184-189` is a `GestureDetector` carrying
  `onHorizontalDragUpdate` / `End` / `Cancel` and **no `onTap`**; the threshold
  is `kStudySwipeThreshold = 70` (`:18`, applied `:121`).
  `study_mode_view_widget.dart:166` passes `actions: const <StudyAction>[]` and
  `study_card_face_section_widget.dart:375` early-returns
  `if (widget.actions.isEmpty) return const <Widget>[]`, so the mode draws no
  controls. `customSemanticsActions` (`:170`) offers Continue / Previous — which
  serves TalkBack and Switch Access, and nobody else.
- **Root cause.** The mode has one input mechanism, and it is a drag.
- **Violated contract.** WCAG 2.5.7 Dragging Movements (AA). BR-110 puts
  `browse` first in every `eight_box` new-learning sequence, so this is a normal
  state on the only released surface.
- **Who is blocked.** A sighted touch user who cannot complete a 70 dp
  horizontal drag and does not run an assistive technology.
- **Resolution.** Give the card a single-pointer path. Any of these satisfies
  the contract: a visible tap affordance on the card itself, a compact
  Continue / Previous pair for `browse` only, or another visible single-pointer
  non-drag action. `MxActionButton` and `AppMotionPolicy` already exist;
  nothing new is needed in the design system. Swipe stays.
- **Dependencies.** None. Independent of every other finding.
- **Files.** `lib/features/study/presentation/widgets/support/study_swipe_deck_widget.dart`,
  `.../support/study_mode_view_widget.dart`,
  `.../sections/study_card_face_section_widget.dart`, ARB pair.
- **Closure test — implementation-neutral, it validates the accessibility
  contract and does not prescribe the UI.** Widget test:
  1. pump `browse` mode with a deck of ≥ 2 cards;
  2. assert a **visible, enabled, non-drag single-pointer Continue affordance
     exists** — found by its semantic label / `button` flag, not by widget
     type, so a card-region tap target and a button both pass;
  3. activate it with **one tap** (`tester.tap`, no drag gesture);
  4. assert the study advanced (the next card is shown / the controller's
     index moved);
  5. where `canGoBack`, assert the equivalent **Previous** affordance exists
     and one tap goes back;
  6. assert the existing swipe (`kStudySwipeThreshold` drag) still advances —
     the tap path is an addition, not a replacement.
  Must fail today at step 2.
- **Owner decision.** None — accessibility selects the outcome; whether the
  affordance is a button or a card-region tap is a design detail the test
  deliberately does not fix.

---

## 17 · P1 registry

| ID | Axis | Summary | Source | Current evidence | Root cause | Resolution | Deps | Closure test |
|---|---|---|---|---|---|---|---|---|
| **P1-01** | CMP | **No sheet route owner.** 16 raw `showModalBottomSheet` in 13 files; bottom inset in **5** mechanisms (`SafeArea` ×7, `useSafeArea:` ×2, `MxSheetInsets` ×2, `mxSheetBottomObstruction` ×1, raw `viewInsets` ×1, none ×5); `Semantics(header: true)` on **1** of 17 sheets. Dialogs: 4 helpers, **0** raw | A9-01/02/05/06, A20-P1-01 | one decision, five owners | one `showMxSheet` + `MxSheetHeader` owning navigator, safe area, inset, handle, header semantics, traversal | — | route test per sheet: one inset value, one top gutter, `isHeader: true`, barrier covers `tester.view`; scan: `showModalBottomSheet` only in `lib/shared/` |
| **P1-02** | CMP/A11Y | **No loading semantic owner.** 6 of 7 raw `CircularProgressIndicator` sites are *loading* states reimplementing three shapes; `card_bulk_overlays:97` has **no accessible name at all**; `card_history_section:306` and `search_page_footer:56` are the same inline recipe written twice in two features. The 7th (`card_progress_panel:178`) is a determinate mastery ring and is **not** part of this finding (§8) | A12-#2/#7/#9, A20-P0-01 split | `MxLoadingState` covers one shape of three | keep `MxLoadingState`; add a no-padding variant and an inline 16 dp spinner; migrate the 6 sites. Then `no_raw_loading_indicator` (§9) can land with the determinate ring on its `exclude:` list | — | semantics test: every *indeterminate* progress indicator in `lib/` has a name; scan: the inline recipe exists once; the guard's live-tree scan reports 0 with exactly one excluded file |
| **P1-03** | ENF | **The guard has no ratchet for the names architecture forbids.** Config byte-identical to A20; guard prints *"No violations found"*; control group of 44 banned names = 0; **none of §9's 5 guard rules exists** (`GUARD_RULE_COUNT` = 5), nor the 3 further enforcement actions (`ENFORCEMENT_ACTION_COUNT` = 8) | A20-P0-01, A8-P2-16 | enforcement was never rebuilt after the taxonomy was decided | land the 5 guard rules + 3 enforcement actions, warning → fix → error, each fault-injected. 2 rules ratchet in Phase 0; the other 3 rules and all 3 actions land in Phase 6 | P1-01 and P1-02 gate 2 of the 5 rules; P2-09/P2-10/P2-22 gate the 3 actions | two-way probe per rule + live-tree scan |
| **P1-04** | A11Y | **`_MxBreadcrumbFold` is the last control outside the focus grammar.** `mx_breadcrumb.dart:397` `InkWell` with `overlayColor: _noOverlay` (a `WidgetStatePropertyAll` of `primary.withAlpha(0)`), `splashFactory: NoSplash`, no `onFocusChange`, no `MxFocusRing`. SDK-verified: `ink_well.dart` resolves `focus` as `overlayColor?.resolve(focused) ?? focusColor ?? theme.focusColor`, so both fallbacks are short-circuited. M100.36 unified focus for row/pressable/pill/card; this file was untouched | A17-P0-1, A20-P0-03 | one widget opts out of the app's focus system wholesale | drop the blanket `overlayColor`, or adopt `MxFocusRing` + `onFocusChange` as `mx_breadcrumb_step.dart:139` already does | after P1-04's grammar is the only one | `mx_breadcrumb_focus_test.dart`: tab to the fold, assert a border at `AppStroke.focus` in `focusIndicator(scheme).color`; absent at rest and under `alwaysTouch` |
| **P1-05** | CMP | **Async confirm dismisses mid-write and drops the Undo.** `mx_async_confirm_dialog.dart:203` `showDialog<void>` with `barrierDismissible` defaulted and no `PopScope`; `deck_confirm_widget.dart:113` wires `onDone: _finish`, and `_finish` is the only path to `onDeleted(_batchId)` — the Undo. Popping the barrier unmounts the listener, the write commits, no message appears | A9-03, A20-P0-04 | the dialog disables its buttons but not its exits | `PopScope(canPop: !isSubmitting)` + `barrierDismissible: !isSubmitting`, in the shared widget so all four callers inherit it | — | route test: submit, tap the barrier while submitting, drive to `savedAndClose`, assert `onDone` fired exactly once |
| **P1-06** | PAR | **Kit↔Dart elevation parity gate is self-referential and the two have diverged.** `css_scale_parity_test.dart:314-337` asserts the kit holds three string literals **copied from the kit**. Kit dark rim: `#6A7199`, blur 2 px, spread stepping 1/2/3. Dart `_darkDepth`: `scheme.outlineVariant` (= `#272C48` dark), blur **0**, spread constant `AppStroke.hairline` — and its doc says *"The ring never thickens"* | A16-G-15, A20-P0-05 | a gate comparing a file to a copy of itself | owner decision 1 first; then compare kit-derived values to the built `ThemeData` at every level in both brightnesses, and update the kit to Dart | owner decision 1 | the rewritten parity test, which must fail today |
| **P1-07** | ENF | **The restyle vocabulary escapes in four ways.** Canonical count, one `.copyWith(` call on a text style = one site, deduplicated by source offset, comments stripped: **`FEATURE_UNIQUE` = 9 · `SHARED_UNIQUE` = 15 · `TOTAL_MIGRATION_SITES` = 24**. Of the 24, **23 are pattern-matchable** — by receiver form `textStyles.` 9 · `texts.` 9 · `withWeight(…)` 4 · `textTheme.` 1, no site matching two forms — and **1 is a local alias** (below). (a) `textStyles.<role>.copyWith(` is unwatched — the 9 feature sites, all in `lib/features/card/`, 8 setting `onSurfaceVariant` and 1 `onSurface`, i.e. exactly `AppInk.quiet` / `AppInk.stated`, a provably zero-pixel migration; (b) the rule is scoped to `presentation_files`, so the 15 in `lib/shared/widgets/` are out of scope entirely; (c) 4 `withWeight(…).copyWith(` launderings, **3 of them multi-line**, escape a line-scoped pattern even after the scope widens; (d) **`mx_search_field.dart:139` launders through a local** — `final TextStyle text = context.texts.bodyMedium!;` then `text.copyWith(color: colors.onSurfaceVariant)`. It is a migration site like the other 23 and is counted as one; what it is *not* is regex-reachable, because the receiver at the `.copyWith` is a bare identifier. An alias-tracking scan finds **exactly 1** such site in `lib/features/**` + `lib/shared/widgets/**` today. Control group: the three watched spellings = **0** | A15-F4/F5, A20-P1-02 | the rule lists three of the accessor surface's four spellings, and no regex can follow a local binding | add the fourth pattern; widen this rule to `ui_surfaces`; `mode: file` with a balanced-paren walk; **add the alias regression probe**; migrate all 24 | P1-09 (know the accessor surface first), P2-02 (`MxSectionLabel` is the better destination for the 9) | two-way probe red on today's **23** pattern-matchable sites **and** the alias probe red on the 1, green after all 24 migrate |
| **P1-08** | COV | **High contrast is rendered nowhere.** Both themes wired at `app.dart:93-94`; **0 of 251** goldens; Widgetbook offers Light and Dark only (`main.dart:78-79`); 5 test files exercise them, all at token or single-component level. The palette re-points `outline`, `outlineVariant` and four semantic tokens — every hairline and disabled control in the app | A19-15, A13-P3-10, A20-P1-04 | a whole theme pair with no picture | two `WidgetbookTheme` entries; ≥2 screen goldens under HC (densest border surface + one with disabled controls) | **P2-11** — the palette's own numbers are wrong, so a golden taken now pictures a decision made on a wrong figure | Widgetbook coverage test asserts 4 modes; golden job renders ≥2 HC screens |
| **P1-09** | COV | **The accessor extension is audited by nobody and now has a fifth member.** `theme_context_extension.dart` — **367** call sites, named by 0 of 22 reports, no test. A20 predicted *"that test is what stops the fifth accessor repeating P1-02"*; M100.36 added `inputHintStyle` (+13 lines) and no test | A20-P1-05 | the file the guard's patterns are written against is unowned | a test asserting every public getter on `ThemeContextX` appears in a guard pattern or is explicitly exempted | — | that test, plus the accessor↔pattern list in both directions |
| **P1-10** | CMP | **The w700 registry is prose.** `buttonLabelWeight = FontWeight.w700` (`app_button_themes.dart:438`, used at `:69`, `:349`, `mx_action_button.dart:284`) makes a button label the app's most repeated w700, while `app_typography.dart:126-127` still argues the hero exception is safe because *"the theme spends w700 only on the two display rungs"*. `app_typography_test.dart:271` is titled *"the hero numeral is the one weight a feature adds"* and passes | A15-F3/F21, A20-P1-06 | the registry is a comment, and the test asserts one member of it | enumerate every weight reachable from the built theme; assert the set is exactly `{400,500,600,700}` and each w700 site is on a named allowlist | — | that enumeration; a sixth weight or an unnamed w700 fails |
| **P1-11** | A11Y | **The OS Bold-text setting is a complete no-op.** SDK-verified: `widgets/text.dart:722-723` honours `boldText` by merging `TextStyle(fontWeight: FontWeight.bold)`. Every rung in this app carries `fontVariations: _wght(...)` (`app_typography.dart:200,217`), and the app's own doc (`:163-169`) records that the renderer consults the axis *instead of* `fontWeight`. **Zero** `boldText` references in `lib/ test/ widgetbook/` | A15-F1, A20-P1-07 split | a variable-font axis silently overrides the flag Flutter uses | one `boldText`-aware wrapper at the composition root or in `AppTypography`, which must state what boldText means for `heroNumeral`'s derived cap-trim | — | pump `Text` at three rungs under `MediaQuery(boldText: true)`; assert the resolved `fontVariations` `wght` moves, not just `fontWeight` |
| **P1-12** | CMP | **Elevation without a shadow colour, on the two components that float.** `app_fab_theme.dart:62` and `app_snackbar_theme.dart:26` state `elevation: AppElevation.overlay`; only `app_popup_menu_theme.dart:52` and `app_card_theme.dart:41` call `materialShadowColor(scheme)`. In dark the model returns transparent; these two paint `scheme.shadow` instead. `component_depth_and_state_test.dart:203` tests the invariant for `PopupMenu` alone | A16-G-14, A20-P1-08 | the invariant is tested for one component and stated for none | wire both; then loop the level-equal + dark-transparent assertions over every theme with non-zero elevation | **none — independent of owner decision 1** (the runtime contract is Dart's `materialShadowColor`, already wired on two other themes; it does not wait on the kit's status, §20) | the generalised loop, red today on two slots |
| **P1-13** | CMP | **Feedback has no warning tone and a caller needs one.** `mx_feedback_band.dart:88` offers `MxCardFeedbackTone.danger` only; `reminder_labels_widget.dart` forces `permissionDenied` — one of five `ReminderSetupRejection` values — into danger, although `AppSemanticColors.warningContainer`/`onWarningContainer` exist | A12-#3, A20-P1-09 split | a four-tone palette and a one-tone band | add the warning tone; map the rejection **per value** in `reminderBanner()`, not with a blanket switch | — | widget test: `permissionDenied` renders the warning tone |
| **P1-15** | CMP | **The shell drops its bar while loading and on error.** `mx_content_shell.dart:213` returns early when `title == null && subheader == null && subline == null`; `deck_list_screen.dart` and `deck_level_error_widget.dart` render exactly that state — no title, no back affordance, a 56 dp jump | A8-P1-01, A20-P1-12 split | the bar is conditional on content it does not need | keep the bar (and its `leading`) whenever the shell has a back affordance to draw | — | widget test: the shell renders a bar with a back affordance in loading and error states |
| **P1-16** | CMP | **Two incompatible up-navigation grammars one tap apart.** `deck_path_widget.dart` and `card_breadcrumb_widget.dart` disagree about what the trail does | A8-P1-02, A20-P1-12 split | two features solved the same navigation question independently | pick one grammar; `MxBreadcrumb` already supports both forms, so this is a caller decision | — | a test asserting both screens' trails answer the same gesture the same way |

---

## 18 · P2 registry

| ID | Axis | Summary and current evidence | Source | Resolution / closure |
|---|---|---|---|---|
| **P2-01** | ENF | Latent guard gaps with **zero** current violations: `AppBar`, `SliverAppBar`, `ChoiceChip` and the other names §9 ratchets are unguarded. `Scaffold` is **not** among them — FRAMEWORK_PRIMITIVE_ALLOWED (§9). A pure ratchet | A8-P2-16 | land `no_raw_screen_chrome` (`AppBar`, `SliverAppBar`) + `no_raw_choice_chip` (§9); scan stays 0 |
| **P2-02** | A11Y/CMP | **All-caps has three policies.** 16 localized headings uppercase with no accessible name; 1 does it correctly (`settings_section_widget.dart:53`); 1 screen refuses to uppercase at all with an l10n argument; **3 are format acronyms that must be excluded** (§13) | A15-F2, A19-07, A20-P1-07/P2-07 split | one `MxSectionLabel` carrying label + `header: true` + the tracking; the 3 acronyms exempt by contract. Test: every heading built by the component exposes the written sentence |
| **P2-03** | CMP | `AsyncValue.error` rendered through `MxEmptyState` (`card_bulk_overlays:100-106`, `card_editor_screen:194-217`) — the conflation `mx_empty_state.dart`'s own doc renounces | A12-#1, A20-P1-09 split | route errors to `MxErrorState`; widget test per site |
| **P2-04** | A11Y | `MxActionSheet` rows are raw `ListTile` (`mx_action_sheet.dart:149`) — the only non-family raw `ListTile(` in `lib/shared/` — so they inherit no row overlay and **no focus ring**, on a keyboard-focusable row. M100.36 unified focus for row/pressable/pill and did not reach this file | A14-F1, A20-P1-11 | route through `MxListTile`, or adopt the ring. Lands with P1-01 |
| **P2-05** | CMP | **App-bar leading is one ink step quiet.** Actions resolve `onSurfaceVariant` (canonical); the leading also resolves `onSurfaceVariant` via `iconButtonTheme`, where `_AppBarDefaultsM3.iconTheme` says `onSurface` (§11.3). **Corrects A20's "inverse of M3"** | A8-P1-03, A20-P1-12 split | set the app bar's `iconTheme` explicitly to `onSurface`; role test pinning both slots |
| **P2-06** | ENF | **The Slider theme is split across two Material generations.** It declares 11 colour slots from the 2024 palette and leaves `year2023` unset; `slider.dart:834` then resolves `_SliderDefaultsM3Year2023` for everything undeclared — geometry included. 4 of the 6 role pins name values that differ between the classes (`inactiveTrack`, both tick marks, `valueIndicator`). Latent: no renderer | A10-P1-1, A20-P1-13 | state `year2023: false`, or move the pins; assert the class **before** asserting its roles |
| **P2-07** | API | `MxMetricWell.wellColor` is an open `Color?` beside a closed `AppInk tint` in the same constructor; all 8 callers feed semantic tokens | A20-P2-01 | **owner decision 2**; if structural, a closed `AppWellFill` mirroring `AppInk` |
| ~~**P2-08**~~ | ENF | **RESOLVED — ACCEPTED_BY_CONTRACT.** `BoxDecoration(` (27), `Border.all(` (3), `DecoratedBox(` (10) are framework *composition*, not a design decision, and all 30 are token-fed. Every visual decision reachable inside them is already closed by an existing `memox-v7` rule — colour, radius, shadow, `BorderSide`, `TextStyle`, spacing (table in §9) — and the guard is green on all of them. The one residual open decision is the border **width**, which is P2-09's. Banning the constructor would have gone red on 30 correct sites and invited the `MxDecoration` wrapper §20 forbids. **Not counted as an active finding** | A20-P2-02 | none — the architecture rule is written in §9: token-fed composition is allowed |
| **P2-09** | ENF | Stroke widths: **2** raw literals left (both `strokeWidth: 2` in `mx_action_button.dart:367,476`, down from 5), and borders that name no width at all — measured at HEAD: **3** `Border.all(` with no `width:` (`card_history_event_widget.dart:178`, `mx_card.dart:696`, `mx_search_field.dart:159`) taking Flutter's implicit `1.0` instead of `AppStroke.hairline`. **Live violations: 5** | A16-G-11/12, A20-P2-03 | **cleanup first (Phase 2), guard second (Phase 6)**: token the 5 sites, verify zero, then enable `no_raw_stroke_width` on `ui_and_theme_surfaces` plus an AST scan that every `BorderSide`/`Border.all` names a width |
| **P2-10** | ENF | The spacing guard sees inline literals only; feature geometry `const double` declarations sit in its blind spot — **16 measured at HEAD** in `lib/features/*/presentation/`, of which some are genuine geometry (`_minCardWidth = 164`, `minRowHeight = 112`) and some are not geometry at all (`dimmedOpacity = 0.7`, `clearedOutlineAlpha = 0.45`), so the rule must classify before it bans. **Live violations: > 0** | A16-G-19, A20-P2-04 | **cleanup first (Phase 5), guard second (Phase 6)**: classify all 16, token or justify each, verify zero, then land the scan test against the 4 dp grid |
| **P2-11** | DOC/A11Y | **The high-contrast palette's own figures are wrong in all four cells**, re-measured at CURRENT_SHA (inputs unchanged): normal **2.11 / 2.62**, HC **3.80 / 5.11** vs the recorded 2.37/3.20 → 4.88/6.33; and `onSurface` is 11.50/12.01 where the block says 14.81. The 62% decision was taken on a figure 28% optimistic. **No WCAG requirement is missed** — SC 1.4.3 exempts inactive components | A13-P3-7, A19-05, A20-P2-05 | correct the table; owner re-confirms 62% knowing 3.80:1. Blocks **P1-08** |
| **P2-12** | CMP | The 32 dp control tier has **5** spellings (`app_chip_theme._containerHeight`, `AppSpacing.xxl`, `MxBreadcrumb.compactLineHeight`, `card_metric_widget._wellSize`, `tag_catalog_row_widget.wellSize`) and no owner; and **7** `AppSpacing.xxl` sites are dimensions, not gaps | A16-G-1/G-5, A20-P2-06 | one owner for the tier; scan: `AppSpacing.*` may not appear as `width:`/`height:`/`size:` |
| **P2-13** | A11Y | The card row announces its state twice; `MxSwitchRow` stacks two state channels | A19-11/19, A20-P2-07 split | semantics tests per row |
| **P2-14** | A11Y | `borderOption` at 2.67:1 on a component that **is** its edge; a single-choice menu with no perceivable and no announced state | A19-02/03, A20-P2-08 | retune `borderOption` **within its own family** (§3 of the brief); announce the menu's selection |
| **P2-15** | CMP | Disabled selection controls lose their boolean: one `disabledSurface` where M3 uses two opacities; a disabled ticked checkbox draws a ring M3 makes transparent; radio has no interaction rung | A10-P2-2/3/4, A20-P2-09 | per-control fixes with composited-contrast tests (blend over the ground, never raw) |
| **P2-16** | CMP | Pickers: `app_date_picker_theme.dart:33-43` checks `disabled` before `selected` where `_DatePickerDefaultsM3` checks `selected` first → 1.32:1 / 1.02:1; the reminder row and its picker disagree about 12 vs 24 hour | A11-F1/F2, A20-P2-10 | reorder the resolver; pass `alwaysUse24HourFormatOf` to the row |
| **P2-17** | COV | **8 screens sit in features with no `meetsGuideline` sweep at all** — every `card` screen (5), `search`, `reminder`, `trash`. 13 test files and 23 call sites cover deck / progress / settings / study | A19-14, A20-P2-11 | one sweep per screen; the shared failure and empty faces get names |
| **P2-18** | CMP | Shell geometry: scroll hairline drawn between bar and subheader; shell owns no max content width (4 screens re-derive it); FAB clearance per-caller; the two-line bar over-reserves above scale 1.34 | A8-P2-04/11/12/13, A20-P2-12 | shell owns all four; layout tests |
| **P2-19** | CMP | Icon vocabulary conflicts: one glyph two meanings on one screen; a pick-one group announcing a checkbox; Flag/Unflag both unfilled; `_rounded` mixed with outlined in one grid | A13-P1-2/3/4, P2-4, A20-P2-13 | a glyph register; tests per conflict |
| **P2-20** | CMP | Actionable non-undo snackbars keep the 4 s default while undo got 8 s for the identical "reach a button" reason | A12-#5, A20-P2-14 | one duration policy in `MxMessenger` |
| **P2-21** | COV | Neither picker is rendered or in the state guards; `MxDropdown` has no documented disabled/error decision | A11-G1/G2, A14-F5, A20-P2-15 | one widget test per picker; a recorded `MxDropdown` decision |
| **P2-22** | ENF | `lib/app/` is in no typography scope (`ui_and_theme_surfaces` covers features, shared and theme only), and `error_screen_widget.dart` renders in the platform font — the only screen that does. **Widening the scope exposes a live defect: 3 violations** at `error_screen_widget.dart:92` (`TextStyle(`), `:94` (`fontSize: 20`) and `:102` (`fontSize: 14`) | A15-F6, A20-P2-16 | **cleanup first (Phase 5), scope second (Phase 6)**: move the error screen onto `AppTypography` families, verify zero, then add `lib/app/**` to the typography scope. The colour exemption for `MobileFrameWidget` stays — this widens typography only |

---

## 19 · P3 registry

| ID | Axis | Summary | Source |
|---|---|---|---|
| **P3-01** | A11Y | **Contract note, not a defect:** `lib/` contains zero keyboard primitives (`Shortcuts`, `CallbackShortcuts`, `LogicalKeyboardKey`, `SingleActivator`, `KeyboardListener`, `onKeyEvent`). Correct for an Android-only product (AD-04); record it so the absence is a decision. Revisit if a desktop or web surface is ever released | A19-01 tail, §11 |
| **P3-02** | A11Y | **Icon text-scaling policy** — per-role, written down, tested both directions (label-adjacent and status glyphs scale, control/decorative/navigation do not). No WCAG requirement is missed today | A13-P1-1, A20-P1-03 **downgraded** |
| **P3-03** | API | `MxProgressBarShape.flush` — zero callers in `lib/`, `test/` or Widgetbook by name; its doc names `deck_tile_widget.dart:233`, which passes no `shape:` | A20-P3-01 |
| **P3-04** | DOC | Four present-tense references to two deleted files: `app_theme.dart:266,288` and `app_sizing.dart:9,45` → `app_modal_themes.dart` / `app_planned_themes.dart`; plus a test file named after one | A20-P3-02 |
| **P3-05** | DOC | Stale cross-references: `mx_icon.dart` cites an `MxMetricWell` defect fixed at M100.5; `app_bottom_sheet_theme.dart:24-30` argues for `borderControl` and returns `onSurfaceVariant`; `app_dialog_theme.dart:26-28` says a shadow is hand-painted and nothing paints one | A13-P3-5, A14-F3, A9-09/10, A20-P3-03 |
| **P3-06** | ENF | Five rulesets vendored (`memox`, `memox-v4`, `memox-v5`, `memox-design-jsx`, `memox-v7`); only `memox-v7` runs, and `memox` — the name a reader would guess — has 75 rules bound to scopes matching nothing | A20-P3-04 |
| **P3-07** | API | `cupertino_icons` declared with zero `CupertinoIcons` references; `Icons.ios_share` is the share glyph on an Android-target app | A13-P3-4, P2-10, A20-P3-05 |
| **P3-08** | COV | `AppIconSize.mdCompact` absent from the Widgetbook token catalogue **and** from `design_tokens_test.dart`'s ordering assertion; `AppRadius.xl` likewise | A13-P3-1/2, A16-G-8, A20-P3-06 |
| **P3-09** | ENF | Four `elevation: 0` literals where `AppElevation.none` exists (`app_app_bar_theme:21`, `app_navigation_bar_theme:67`, `app_bottom_sheet_theme:14`, `app_dialog_theme:30`); a raw `4` scrollbar thickness; the radius guard is `warning` where the spacing guard beside it is `error` | A16-G-18/21/9, A20-P3-07 |
| **P3-10** | DOC | Every dialog announces "Alert" and every sheet "Dialog"; session and 404 screens carry no `namesRoute`; `deckPathAncestorsHint` orphaned in both ARBs | A9-13, A8-P3-19, P2-08, A20-P3-08 |
| **P3-11** | API | `MxFormDialog.isSubmitting` and `MxActionSheetAction.isEnabled` have no production caller (the latter's only use is `test/shared/widgets/golden_hosts.dart:78`). **Note:** `DeckSchedulerPickerWidget.isEnabled` is a different, live API | A9-14, A20-P3-09 |
| **P3-12** | COV | `MxIcon` has no unit test; its null-label ⇒ `ExcludeSemantics` contract — the reason the widget exists — is asserted nowhere | A13-P3-3, A20-P3-10 |
| **P3-13** | DOC | `MxBreadcrumb` accepts `lineHeight: 32` with tappable steps, below `AppSizing.touchTarget`; only convention prevents it | A16-G-7, A8-P3-17, A20-P3-11 |
| **P3-14** | DOC | `AppStroke.input` names a component and 3 of its 5 call sites are not inputs. **Half resolved:** `MxSearchField`'s edge is now `outline` at `AppStroke.input` (M100.36 4E), so only the naming survives | A16-G-10/13, A20-P3-12 |
| ~~**P3-15**~~ | COV | **RETIRED — the premise was false and the residual closes no branch.** Two facts, both read from source this pass. (1) **360 dp is the canonical component-golden surface**: `golden_pump.dart:16` declares `const Size kGoldenSurface = Size(360, 640)` and it is `pumpGolden`'s default, so the whole full-width component golden set is *already* a picture at 360; the compact suite adds 320 (`mx_components_compact_golden_test.dart:27`, `Size(320, 568)`). "No golden at 360" was simply wrong. (2) **375 has no unique visual branch.** The app has two named width thresholds — `AppBreakpoints.compact` = 360 and `medium` = 600 — and 360, 375 and 393 all sit between them, so no device-level branch separates them. The one content-level threshold that could (`card_import_source_step_widget.dart:142`, two source cards side-by-side at ≥ 336 dp of content) puts **375 on the same side as 393**, and 393 is pictured (`card_import_source_light.png`). A 375 golden would therefore re-photograph a branch combination already committed at 393, while 375 itself is asserted for overflow at 1.3× and 2.0× across all 31 shared specimens (`mx_stress_test.dart:102`). **Not counted as an active finding** | A18 §7.3, A8-P3-21, A20-P1-10 residual |

---

## 20 · Owner decisions

A20 listed five. Three are settled here by evidence; **two remain**.

### Settled, no longer owner decisions

| A20 decision | settled how |
|---|---|
| *"`useSafeArea: true` for the seven sheets, and does the scrim cover the nav bar?"* | Both are consequences of P1-01, not independent choices. `showModalBottomSheet` defaults `useRootNavigator = false` (`bottom_sheet.dart:1301`) against `showDialog`'s `true`; one owner decides once. Engineering decision: **the sheet route helper uses the root navigator and `useSafeArea: true`**, matching the dialog family |
| *"What form does the browse keyboard path take?"* | Reframed by §11: the **P0 is the non-drag single-pointer path** (WCAG 2.5.7), and accessibility selects it. The keyboard question is P3-01, a contract note on an Android-only product |
| *"Do glyphs scale with text?"* | §12 selects a per-role policy on usability grounds; no WCAG requirement forces a different answer. Recorded as P3-02 |

### Retained

**Owner decision 1 — Is the `design_system/` kit still normative?**
*Blocks **P1-06 only**.*

**It does not block P1-12**, and the earlier text saying so was wrong. P1-12 is
a *runtime* contract that already exists in Dart and is independent of the
kit's status: `materialShadowColor(scheme)` returns `Colors.transparent` in dark
and `scheme.shadow` in light, and `app_popup_menu_theme.dart:52` and
`app_card_theme.dart:41` already wire it. Wiring the same function into the FAB
and SnackBar themes uses only Dart truth, changes nothing the kit describes, and
would be correct under every one of the three options below. Whether the kit is
normative decides how the *parity gate* is written; it does not decide whether a
component with non-zero elevation names its shadow colour.

**Neither answer restores the dark glow.** #435 removed it and A9-16 measured
why it must stay removed; `materialShadowColor` returning transparent in dark is
precisely the mechanism that keeps it removed, so P1-12 *strengthens* that
invariant rather than risking it.

- **Options.** (a) Kit is normative → update it to Dart's quiet rim and rewrite
  the gate to compare kit ↔ `ThemeData`. (b) Kit is a mirror → same update, gate
  advisory. (c) Kit is retired for elevation → drop those rows and say so.
- **Trade-off.** (a) keeps one cross-checkable source of truth at the cost of
  maintaining a second artefact; (c) is cheapest and loses the cross-check.
- **Not an option.** Leaving a gate that reads as agreement.
- **Recommended default: (b).** The kit follows Dart. §15.3 shows why the
  reverse is the one action A9-16 measured and rejected.

**Owner decision 2 — Does V1 closure require *structural* API closure?**
*Decides P2-07.* (P2-08 no longer depends on it — it closed by contract, §18.)

- **Options.** (a) Empirical closure + guard: every hatch is token-fed and a
  scan keeps it that way. (b) Structural closure: closed enums, smaller API.
- **Trade-off.** (b) is unbreakable but costs an enum per hatch and some
  expressiveness; (a) is cheap and depends on the guard staying honest.
- **Recommended default: (a) for V1, with one exception** —
  `MxMetricWell.wellColor` sits beside a closed `AppInk tint` in the *same
  constructor*, so closing it is an internal-consistency fix rather than a
  policy change.

---

## 21 · Implementation DAG

Rebuilt from current dependencies. Nine phases, not A20's twelve: the guard
phase splits because 2 of the 5 guard rules (`GUARD_RULE_COUNT`, §9) are gated
on primitives that do not exist yet, and A20's separate "responsive/motion" phase collapses (motion is
closed and the width matrix landed with M100.36; only a P3 golden residual
remains).

```
Phase 0  PURE ZERO-VIOLATION RATCHETS                    P2-01
   │  2 of the 5 guard rules (§9). ONLY rules whose live-tree scan is 0 today:
   │      no_raw_screen_chrome (AppBar, SliverAppBar)  -> 0
   │      no_raw_choice_chip   (ChoiceChip)            -> 0
   │  No production change. Pixels: none. Cannot regress, so it may land first.
   │  NOTHING ELSE BELONGS HERE. ~~P2-08~~ closed by contract and is no longer
   │  a finding (§18); P2-09, P2-10, P2-22 and P1-07's rule all have live
   │  violations today and are sequenced cleanup-first below.
   ▼
Phase 1  THE P0                                          P0-01
   │  Shares no file with any other finding. Ship first. Pixels: yes.
   ▼
Phase 2  FOUNDATIONS + PARITY REFERENCE                  P1-06 P2-09(cleanup) P2-11 P2-12 P3-09 P3-14
   │  owner decision 1 gates P1-06 only. P2-09 tokens its 5 stroke sites here
   │  so its guard can ratchet in Phase 6. P2-11 must precede any HC picture.
   │  Pixels: none except P2-12's tier and the stroke widths.
   ▼
Phase 3  ThemeData CORRECTNESS                           P1-12 P2-05 P2-06 P2-15 P2-16
   │  P1-12 does NOT wait on Phase 2 — it is Dart runtime truth (§20). The rest
   │  is role and combined-state correctness. Pixels: yes.
   ▼
Phase 4  SHARED PRIMITIVES / SEMANTIC OWNERS             P1-01 P1-02 P2-02 P1-05 P1-04 P2-04
   │  MxSheet · loading family · MxSectionLabel · PopScope · focus ring.
   │  MxSectionLabel MUST precede Phase 5 or P1-07's 9 sites migrate twice.
   │  Pixels: yes.
   ▼
Phase 5  CALLER MIGRATIONS                               22 SHARED_REQUIRED sites · P1-07 · P1-13
   │                                                       P2-03 P2-10(cleanup) P2-22(cleanup)
   │  16 sheets -> showMxSheet; 6 spinners -> the loading family; 24 restyles
   │  -> .inked / MxSectionLabel; 16 geometry consts classified; the error
   │  screen onto AppTypography. Every family Phase 6 guards becomes clean HERE.
   │  Pixels: minimal (the restyles are zero-pixel).
   ▼
Phase 6  GUARDS FOR FAMILIES THAT ARE NOW CLEAN          P1-03
   │  6 actions = 3 of the 5 guard rules + 3 enforcement actions (§9).
   │  Every one is enabled only after its Phase 2/5 cleanup verified 0:
   │      no_raw_sheet_route          <- Phase 4 owner + Phase 5 migration
   │      no_raw_loading_indicator    <- Phase 4 owner + Phase 5 migration
   │                                     (+ the determinate companion assertion, §9)
   │      no_text_restyle  (extended) <- Phase 5 (24 sites: 23 + 1 alias)
   │      no_raw_stroke_width         <- Phase 2 (5 sites)
   │      geometry const-double scan  <- Phase 5 (16 sites)
   │      typography scope + lib/app  <- Phase 5 (3 sites)
   │  warning -> verify 0 -> error. Pixels: none.
   ▼
Phase 7  ACCESSIBILITY / CHROME / REMAINING BEHAVIOUR    P1-11 P1-15 P1-16 P2-13 P2-14 P2-17 P2-19 P2-20
   │  boldText, shell bar, one up-grammar, sweeps. Pixels: yes.
   ▼
Phase 8  COVERAGE / DOCS / API DEBT                      P1-08 P1-09 P1-10 P2-07 P2-18 P2-21
   │                                                       P3-01…P3-08 P3-10…P3-14
   │  high-contrast modes and goldens, accessor test, weight registry,
   │  MxMetricWell.wellColor (owner decision 2), dead API, stale docs.
   │  Pixels: none in the app.
   ▼
Phase 9  FULL VERIFICATION                               goldens on Linux · gallery · CI
```

**Why each edge exists.**

| edge | reason |
|---|---|
| 0 → all | the two Phase-0 rules scan 0 today, so they cannot regress and they make every later phase measurable. A rule with live violations in Phase 0 would be a red gate on day one — which is why P2-09, P2-10 and P2-22 are not there |
| 1 standalone | the P0 shares no file with any other finding; delaying it behind refactors would be indefensible |
| **2 → 3 is NOT an edge for P1-12** | P1-12 wires `materialShadowColor`, which is Dart runtime truth and independent of the kit decision (§20). The 2 → 3 edge applies to P1-06's parity gate only |
| 2 → 6 (P2-09) | the stroke guard can ratchet only once its 5 live sites are tokened |
| 2 → 8 | a high-contrast golden taken before P2-11 pictures a decision made on a wrong number |
| 4 → 5 | callers cannot migrate to owners that do not exist |
| 4(MxSectionLabel) → 5(P1-07) | otherwise the nine sites are touched twice |
| **5 → 6 (all six Phase-6 actions: 3 guard rules + 3 enforcement actions)** | this is the load-bearing edge of the whole plan: `no_raw_sheet_route` before `showMxSheet` bans the only mechanism there is; `no_text_restyle` before the migration is red on 24 sites; the geometry and typography rules are red on 16 and 3. Every Phase-6 rule is enabled against a scan that Phase 2 or Phase 5 has already driven to zero |

**Pixel-moving phases: 1, 2 (partly), 3, 4, 5 (minimal), 7.** Each ends with
goldens regenerated **on Linux** and the gallery republished at the pinned URL —
a Windows checkout cannot regenerate them and have CI agree.

---

## 22 · Exact files grouped by implementation phase

**Phase 0** (two zero-violation rules only) — `code-verification-guard-v2/registries/projects/memox-v7/rules/memox-design-system-rules.yaml`

**Phase 1** — `lib/features/study/presentation/widgets/support/study_swipe_deck_widget.dart`, `.../support/study_mode_view_widget.dart`, `.../sections/study_card_face_section_widget.dart`, `lib/l10n/app_{en,vi}.arb`

**Phase 2** — `design_system/tokens/elevation.css`, `test/design_audit/css_scale_parity_test.dart`, `lib/core/theme/schemes/app_high_contrast.dart`, `lib/core/theme/foundations/app_spacing.dart`, `lib/core/theme/components/{navigation/app_app_bar_theme,navigation/app_navigation_bar_theme,surfaces/app_bottom_sheet_theme,surfaces/app_dialog_theme,content/app_scrollbar_theme}.dart`, `lib/core/theme/foundations/app_stroke.dart`, `docs/design-system/tokyo-component-mapping.md`
· **P2-09 cleanup (5 sites):** `lib/shared/widgets/mx_action_button.dart:367,476`, `lib/features/card/presentation/widgets/items/card_history_event_widget.dart:178`, `lib/shared/widgets/mx_card.dart:696`, `lib/shared/widgets/mx_search_field.dart:159`

**Phase 3** — `lib/core/theme/components/actions/app_fab_theme.dart`, `.../feedback/app_snackbar_theme.dart`, `.../navigation/app_app_bar_theme.dart`, `.../selection/app_slider_theme.dart`, `.../selection/app_toggle_themes.dart`, `.../selection/app_radio_theme.dart`, `.../pickers/app_date_picker_theme.dart`, `lib/features/reminder/presentation/widgets/support/reminder_labels_widget.dart`, `test/core/theme/contracts/m3_role_contract_test.dart`, `test/core/theme/components/component_depth_and_state_test.dart`

**Phase 4** — new `lib/shared/widgets/mx_sheet.dart`, new `lib/shared/widgets/mx_section_label.dart`, `lib/shared/widgets/{mx_sheet_insets,mx_form_sheet,mx_action_sheet,mx_loading_state,mx_async_confirm_dialog,mx_breadcrumb,mx_feedback_band}.dart`

**Phase 5** — the 22 SHARED_REQUIRED sites: 16 `showModalBottomSheet` calls in 13 overlay files under `lib/features/{card,deck,study,trash}/presentation/widgets/overlays/` and `study_entry_screen.dart`, and the 6 loading-spinner sites; plus **P1-07's 24 restyle sites**: the 9 `textStyles.copyWith` in `lib/features/card/presentation/` and the 15 in `lib/shared/widgets/` (`mx_action_sheet.dart:118,173`, `mx_breadcrumb.dart:184`, `mx_breadcrumb_step.dart:97,122,187`, `mx_empty_state.dart:82`, `mx_error_state.dart:86`, `mx_form_dialog.dart:142`, `mx_progress_bar.dart:172,184`, **`mx_search_field.dart:139` (local alias)**, `mx_search_field.dart:230`, `mx_session_top_bar.dart:247`, `mx_text_field.dart:359`)
· **P2-10 cleanup (16 declarations):** `card_import_row_preview_widget.dart:28`, `tag_catalog_row_widget.dart:48`, `card_export_format_options_widget.dart:96`, `card_import_source_step_widget.dart:119`, `progress_metric_widget.dart:67`, `guess_option_item_widget.dart:216`, `match_tile_widget.dart:333,361`, and the 8 remaining under `lib/features/*/presentation/`
· **P2-22 cleanup (3 sites):** `lib/app/error_screen_widget.dart:92,94,102`

**Phase 6** — `code-verification-guard-v2/registries/projects/memox-v7/rules/memox-design-system-rules.yaml` (`no_raw_sheet_route`; `no_raw_loading_indicator` with its `exclude:` entry for `card_progress_panel_widget.dart` **and the companion determinate assertion**; the extended `no_text_restyle`), `.../memox-design-token-rules.yaml` (`no_raw_stroke_width`, the geometry const-double scan), `.../config/scopes.yaml` (`lib/app/**` added to the typography scope). Each rule: warning → verify 0 → error

**Phase 7** — `lib/core/theme/typography/app_typography.dart`, `lib/app/app.dart`, `lib/shared/widgets/mx_content_shell.dart`, `lib/features/deck/presentation/widgets/sections/deck_path_widget.dart`, `lib/features/card/presentation/widgets/support/card_breadcrumb_widget.dart`, `lib/core/theme/foundations/app_border_colors.dart`, `lib/shared/widgets/mx_messenger.dart`, ~21 heading sites

**Phase 8** — `widgetbook/lib/main.dart`, `test/demo/**`, `test/visual_audit/**`, new `test/core/theme/extensions/theme_context_extension_test.dart`, `test/core/theme/typography/app_typography_test.dart`, `lib/shared/widgets/mx_metric_well.dart` (P2-07), `lib/core/theme/app_theme.dart`, `lib/core/theme/foundations/app_sizing.dart`, `pubspec.yaml`, `code-verification-guard-v2/registries/projects/{memox,memox-v4,memox-v5,memox-design-jsx}/`. **No golden-surface work:** ~~P3-15~~ is retired — 360 is already the component-golden surface and 375 closes no branch (§19)

---

## 23 · Architectural closure criteria and score

Mechanically checkable. These answer *ownership* questions — who owns the
semantic contract, are `ThemeData` roles correct, are shared APIs closed or
explicitly constrained, is prohibited drift enforceable, are component-level
accessibility contracts present, are unjustified raw usages eliminated.
Coverage properties (catalogue, stress specimens, width matrices, goldens,
sweeps) are **not** here; they are §24. **Score: 13 / 30** at CURRENT_SHA — 13 met, 17 unmet. **Re-scored at `fix/design-system-v1-closure`: 30 / 30** (§27), and re-verified mechanically at the V1 freeze (M100.40, §28).

| # | Criterion | State |
|---|---|---|
| 1 | Exactly 45 M3 colour roles + `brightness`, both directions allowlisted | ✅ |
| 2 | Zero colour hex outside `lib/core/theme/foundations/` | ✅ 113/113 |
| 3 | Zero `Colors.<name>` outside `lib/core/theme/`; only `transparent` within | ✅ 14/14 |
| 4 | Zero dead tokens, or each survivor carrying a written reason | ✅ |
| 5 | Zero local `Theme(`/`IconTheme(`/`DefaultTextStyle(` overrides outside the composition root | ✅ |
| 6 | Zero literal `Duration(` as a `duration:`; every animation through `AppMotionPolicy` | ✅ |
| 7 | `theme_coverage_test` green in both directions with current allowlist reasons | ✅ 56 mappings |
| 8 | Every rendered Material component has its `ThemeData` slot filled | ✅ |
| 9 | Component themes read only `ColorScheme`/`TextTheme`/`AppSemanticColors`/closed enums | ✅ |
| 10 | Zero raw `showDialog` in features | ✅ |
| 11 | Focus grammar: one answer for row, pressable, pill, card | ✅ since M100.36 |
| 12 | Visual escape hatches on the shared surface ≤ 7, each token-fed at every call site | ✅ 7/7 |
| 13 | No feature invents a colour: every `BoxDecoration` token-fed | ✅ 27/27 |
| 14 | Raw high-level Material in features is **classified**, with every SHARED_REQUIRED site owned | ✅ 22 of 22 owned — 16 `showMxSheet`, 6 `MxLoadingState` (§27) |
| 15 | Every modal route opens through a shared helper | ✅ `showMxSheet`; `no_raw_sheet_route` keeps it so |
| 16 | One bottom-inset mechanism for sheets | ✅ one each: route inset by `showMxSheet` (`useSafeArea`), content inset by `MxSheetInsets` |
| 17 | Sheet headers announce as headers | ✅ 17 of 17 — `MxSheetHeader` in the two shared sheets, `Semantics(header:)` on every feature title |
| 18 | Loading semantics have one owner (determinate progress excluded by contract) | ✅ `MxLoadingState` family; the determinate ring is excluded by contract and named (`raw_progress_exclusions_test`) |
| 19 | Text restyle has one spelling, enforced across features **and** shared, **including aliases** | ✅ 0 sites; `no_text_restyle` in file mode, five patterns including the local alias and `inputHintStyle`; `text_restyle_alias_test` |
| 20 | Every accessor on `ThemeContextX` is covered by a guard pattern or exempted | ✅ 5 of 5 (`theme_context_extension_test`, both directions) |
| 21 | The guard bans every name the architecture forbids, and nothing else (`Scaffold`, the determinate ring **and token-fed composition primitives** are *not* forbidden) | ✅ 5 of 5 rules, 8 of 8 enforcement actions |
| 22 | Every guard rule has a positive probe, a comment probe and a live scan | ✅ positive + comment probe per rule (`test_memox_v7_*_guard_rules.py`), live scan green |
| 23 | Weight registry enumerated and asserted | ✅ `app_typography_test` — every reachable weight, every w700 source named |
| 24 | Elevation: every theme with non-zero elevation wires `materialShadowColor` | ✅ FAB wires `materialShadowColor`; SnackBar has no shadow slot in the SDK (documented in its theme) |
| 25 | Kit↔Dart parity compares the two systems, not a file to itself | ✅ `css_scale_parity_test` compares the kit's layers to `shadowsFor` |
| 26 | Canonical role correctness: no theme slot deviates from its `*DefaultsM3` without a written reason | ✅ slider (`year2023: false`), checkbox/radio disabled states, date picker order — each against `*DefaultsM3` |
| 27 | Every keyboard-focusable control has a visible focus indicator | ✅ the breadcrumb fold sits in `MxFocusRing` |
| 28 | Every core task completable by a single pointer without dragging | ✅ `browse` has a pointer row (P0-01) |
| 29 | OS `boldText` moves the resolved `fontVariations` `wght` | ✅ `applyBoldText` re-weights through `wght` |
| 30 | Feedback tone taxonomy complete for every caller that needs one | ✅ `warning` tone on band and card |

Moved to §24 in the correction pass: "every shared widget has a Widgetbook
entry" and "every shared widget has a stress specimen" — both are coverage
properties and were already counted there.

---

## 24 · Full-verification criteria and score

**Score: 11 / 22** at CURRENT_SHA — 11 met, 11 unmet (⚠️ NOT RUN / unknown counts as unmet). **Re-scored at `fix/design-system-v1-closure`: 21 / 22** — the device suite was the one NOT RUN (§27). **Final: 22 / 22 at the V1 freeze** (M100.40, §28).
These are *additional* to §23 and do not gate architectural closure.

The former criterion 23 ("≥ 1 component golden at 360 and 375 dp") is **removed,
not merely marked met**: 360 is the canonical component-golden surface already
(`golden_pump.dart:16`) and 375 closes no visual branch (§19). Keeping it as a
✅ would have inflated both numerator and denominator with a requirement the
architecture never had; the denominator drops from 23 to 22 accordingly.

| # | Criterion | State |
|---|---|---|
| 1 | `flutter analyze` zero issues repo-wide | ✅ |
| 2 | Full non-golden host suite green | ✅ 4740 |
| 3 | Active guard green | ✅ 84 rules |
| 4 | `check_docs.py` green | ✅ |
| 5 | Codegen fresh | ✅ |
| 6 | Golden suite green on Linux | ✅ 325 / 325 on Linux (WSL Ubuntu 24.04, Flutter 3.44.8) after regeneration — 321 at START_SHA plus the 4 HC screens — 107 pictures changed: 103 regenerated, 4 new high-contrast screens; compare → regenerate → compare again |
| 7 | Widgetbook smoke green | ✅ `widgetbook/`: analyze clean, smoke test green |
| 8 | `integration_test/` 8 of 8 on a device | ✅ **8 / 8** on `emulator-5554`, `--flavor development`, exit 0 (M100.40) — the last NOT RUN criterion, and the one that moved §24 to 22 / 22 |
| 9 | Every shared component in the catalogue | ✅ |
| 10 | Every shared component has a stress specimen | ✅ |
| 11 | Goldens authored on Linux only | ✅ policy in `dart_test.yaml` |
| 12 | Screen gallery published at the pinned URL from current goldens | ✅ rebuilt from this branch's committed goldens by `build_screen_gallery.py` and republished at the pinned URL, with the four high-contrast rows |
| 13 | Widgetbook offers 4 theme modes | ✅ 4 — `widgetbook_coverage_test` asserts all four builders |
| 14 | ≥2 screen goldens under each high-contrast theme | ✅ 2 screens × 2 themes — `deck_list_root_hc_*`, `reminder_settings_hc_*` |
| 15 | Layout tier pumps 320 / 360 / 375 / 393 | ✅ `mx_stress_test.dart`: 320 × 2.0, 360 / 375 / 393 × 1.3 / 2.0, inputs 2.5 / 3.0 × 320 |
| 16 | Gallery stays 393×852 only | ✅ enforced by `build_screen_gallery.py` |
| 17 | `meetsGuideline` sweep on every screen | ✅ card (5), search, reminder, trash — tap targets and labelled targets; contrast measured from the tokens |
| 18 | Both pickers rendered in a test | ✅ `mx_picker_render_test` — date and time pickers under both themes |
| 19 | Every progress indicator has an accessible name | ✅ the card progress ring is named (`cardProgressTitle`) with the percent as its value |
| 20 | Token scales fully catalogued and ordered (`mdCompact`, `AppRadius.xl`) | ✅ `mdCompact` and `AppRadius.xl` catalogued and ordered |
| 21 | `MxIcon` has a unit test | ✅ `mx_icon_test` |
| 22 | `docs/wbs.md` current with the code | ✅ M100.38 |

---

## 25 · Verification performed

Per §15, each claim with its command, scope and result.

| # | Command | Scope | Result |
|---|---|---|---|
| 1 | `flutter analyze` | repo-wide | **No issues found** (72.9 s) |
| 2 | `python code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v7` | active ruleset, 79 rules | **passed, no violations** |
| 3 | `TZ=UTC flutter test --exclude-tags golden` | **full non-golden host suite** | **+4622, All tests passed** (exit 0) |
| 4 | `flutter gen-l10n` + `dart run build_runner build --delete-conflicting-outputs` | codegen | 1601 outputs; required before (3) |
| 5 | A20's own scanners re-run | `lib/`, `test/`, `widgetbook/` | counts in §8, §13, §17 |
| 6 | Flutter 3.44.8 source reads | `app_bar.dart`, `ink_well.dart`, `slider.dart`, `widgets/text.dart`, `bottom_sheet.dart`, `color_scheme.dart` | §11.3, §12, §14, P1-04, P1-11, P2-06 |
| 7 | **Correction pass** — §8 table re-summed by hand and by script | the 11 rows of §8 | 16+7+3+2+2+2+1+2+2+1+1 = **39**; SHARED_REQUIRED **22**; allowed **17** |
| 8 | **Correction pass** — `test/shared/widgets/mx_stress_test.dart` read | `:33`, `:102-103`, `:140` | 320 × 2.0; **360 / 375 / 393 × 1.3 / 2.0**; inputs 2.5 / 3.0 |
| 9 | **Correction pass** — guard registry read for `exclude:` and `mode: file` support | `memox-architecture-rules.yaml:131,191`, `memox-design-token-rules.yaml:227` | both exist; `no_raw_loading_indicator`'s allowlist needs no new capability |
| 10 | **Correction pass** — `grep -rn "Scaffold(" lib/features` (excluding `ScaffoldMessenger`) and `docs/architecture.md` for an ownership contract | features, AD-01…AD-19 | **0** raw sites; no AD forbids feature-owned `Scaffold` |

**NOT RUN, and stated as such:** the golden suite (a Windows checkout cannot
author goldens and have CI agree — `dart_test.yaml` pins Linux), the Widgetbook
smoke test, and `integration_test/` on a device. No golden was regenerated and
no golden was updated for this report. *All three were run later:* the goldens
and the Widgetbook smoke at `fix/design-system-v1-closure` (§24 rows 6 and 7),
and the device suite at the V1 freeze (§28).

**Scanner discipline.** Every count came from a scanner run with a **control
group** — the raw-widget scan carries the 44 names the guard *does* ban and they
return 0; the restyle scan carries the three spellings the rule *does* watch and
they return 0. Two of this pass's own scanner results were discarded for method
errors and are recorded rather than deleted: an unstripped comment produced a
phantom 11th `Divider(` (the guard's comment-exempt pattern is right, my scan
was wrong), and a bare-name grep merged `MxActionSheetAction.isEnabled` with the
live `DeckSchedulerPickerWidget.isEnabled`.

### 25.1 · Final correction pass (docs-only)

Run at `9acaaa4a`, the merge of the first correction PR. No production, test,
guard, kit or generated file was touched; no golden was run or regenerated.

| # | What was checked | Command / read | Result |
|---|---|---|---|
| 1 | Docs guard | `python .claude/skills/flutter-workflow/scripts/check_docs.py` | **✓ specification is internally consistent** |
| 2 | Golden surface | read `test/shared/widgets/golden_pump.dart` | `kGoldenSurface = Size(360, 640)` at `:16`, the default of `pumpGolden` — **360 is the component-golden surface**; the compact suite is `Size(320, 568)` (`mx_components_compact_golden_test.dart:27`) |
| 3 | 375 runtime matrix | read `test/shared/widgets/mx_stress_test.dart` | `:102` `const widths = <double>[360, 375, 393]` × {1.3, 2.0} over 31 specimens, overflow-asserted; 320 in its own group |
| 4 | 375 visual branch | read `app_breakpoints.dart`, `mx_hero_card.dart`, every width comparison in `lib/` | two named thresholds (360, 600); 360/375/393 all between them. The one content threshold that could separate them (`card_import_source_step_widget.dart:142`, ≥ 336 dp) puts **375 on 393's side**, and 393 is pictured — so 375 closes no branch |
| 5 | P2-08 composition sites | balanced-paren walk over every `BoxDecoration(` in `lib/features/*/presentation/` | **30 sites, 0 with a raw colour**; all 3 `Border.all(` widths are variables or omitted — none is a literal |
| 6 | Existing token rules | read `memox-design-token-rules.yaml` | `no_raw_color`, `no_raw_border_radius`, `no_raw_text_style`, `no_raw_spacing_literal` all scoped `ui_surfaces`; with `no_raw_style_escape` they close every decision inside a `BoxDecoration` except border width |
| 7 | **Phase-0 admission test** | live-tree scan per candidate rule, guard's own scopes and comment-exempt idiom | `AppBar`/`SliverAppBar` **0** · `ChoiceChip` **0** → may ratchet. `strokeWidth` literal **2** + `Border.all` with no width **3** · feature geometry `const double` **16** · `lib/app` raw text style **3** · `textStyles.copyWith` **9** + `texts.copyWith` in `lib/shared` **9** → **all cleanup-first** |
| 8 | Raw taxonomy re-sum | A20.1's own scanner re-run at `9acaaa4a` | 16 + 10 + 7 + 2 + 1 + 2 + 1 = **39**, unchanged; control group of 44 guarded names **0**; zero raw `Scaffold` in `lib/features/` |

**No delta in the taxonomy**: 22 SHARED_REQUIRED + 17 allowed = 39, identical to
the figures the report already carried.

### 25.2 · Final consistency pass (docs-only)

Run at `f36307f2`. No production, test, guard, kit, Widgetbook, golden or
generated file was touched.

| # | What was checked | How | Result |
|---|---|---|---|
| 1 | **P1-07 count** — *superseded by §25.3, kept for the audit trail* | balanced-paren scan of every `.copyWith(` whose receiver is a text style, over `lib/features/**` + `lib/shared/widgets/**`, comments blanked in place so offsets survive, deduplicated by source offset | 9 feature · 14 shared · **23 pattern-matchable**. By receiver form: `textStyles.` 9 · `texts.` 9 · `withWeight(…)` 4 · `textTheme.` 1. **Zero sites matched two forms**, so no dedup was actually needed — the earlier disagreement was not double-counting. **This pass reported 23 as the total; §25.3 corrects that to 24** by counting the local alias, which is a migration site even though no pattern reaches it |
| 2 | Why the earlier **24** and this pass's **23** differed | re-read the site in dispute | `mx_search_field.dart:139` has a **local** receiver (`final text = context.texts.bodyMedium!;` then `text.copyWith(color:)`). This pass excluded it because no pattern can match it. **§25.3 reverses that**: it is a migration site regardless of whether a regex reaches it, so the total is 24 and the unreachable one gets an alias probe of its own (§9) |
| 3 | Why **18** was wrong | re-ran the line-scoped patterns | it counted only `textStyles.` (9) + `texts.` (9) and **missed 5**: the 4 `withWeight(…).copyWith(` launderings — 3 of them multi-line, which is exactly the defect P1-07 (c) describes — and the 1 `textTheme.` site. 18 + 5 = 23 |
| 4 | Guard counts | counted `§9`'s rule rows | **5** rule rows, matching `GUARD_RULE_COUNT`; `ENFORCEMENT_ACTION_COUNT` = 8 declared and Phase 6's "six" is now explicitly six *actions* (3 rules + 3 actions) |
| 5 | Owner decisions | scanned for stale references | exactly **2** retained (OD1 → P1-06 only, OD2 → P2-07 only). P2-07's resolution cell had pointed at a third, non-existent owner decision; it now points at OD2 |
| 6 | Matrix `NEW_ID` validity | every row's `NEW_ID` checked against the active registry | **0** rows reference a non-active id; A20-P1-10 and A20-P2-02 now carry `—` |
| 7 | Registry arithmetic | counted rows, excluding strikethrough | 1 + 15 + 21 + 14 = **51**, matching the stated total; every active id appears in exactly one registry row |
| 8 | Scores | recomputed from the criteria tables themselves | §23 30 rows / 13 ✅ → **13/30**; §24 22 rows / 11 ✅ → **11/22** |
| 9 | DAG hygiene | stripped `~~…~~` pointers, then checked every id | 42 ids referenced, **all active**; no retired id assigned work in the DAG, the files-by-phase list or the verification criteria |
| 10 | Raw taxonomy | re-verified at HEAD | **39 = 22 + 17**, unchanged |

All ten pass. The checker is written to fail on a bare retired id anywhere work
is assigned, which is why retired ids appear struck through wherever they are
mentioned as history.

### 25.3 · Local-alias recount and §5 correction (docs-only)

Run at `470fa622`. Two changes, both owner-directed and both verified against
source.

| # | What was checked | How | Result |
|---|---|---|---|
| 1 | **Is the local alias a migration site?** | read `mx_search_field.dart:130-140` | **Yes.** `final TextStyle text = context.texts.bodyMedium!;` then `text.copyWith(color: colors.onSurfaceVariant)` is the same open-colour restyle as the other 23 and must migrate with them. §25.2 had excluded it from the count on the grounds that no pattern can match it — that conflated *what must be migrated* with *what a regex can catch*. **`TOTAL_MIGRATION_SITES` = 24**; 23 pattern-matchable + 1 alias |
| 2 | **Are there other local aliases?** | two-pass alias-tracking scan over `lib/features/**` + `lib/shared/widgets/**`: bind every `final TextStyle <n> = <expr mentioning texts./textStyles./textTheme.>;`, then flag every `<n>.copyWith(` | **exactly 1** — `mx_search_field.dart:139`. The probe's expected value today is therefore 1, and 0 after migration |
| 3 | §5's A20-P1-10 row | re-read against §19 | it still ended *"The residual — no golden at 360 or 375 — is a picture gap … and is P3-15"*, which is stale twice over: ~~P3-15~~ is retired, and 360 **is** the component-golden surface. Corrected in place |

**Counts after this pass:** `FEATURE_UNIQUE` 9 · `SHARED_UNIQUE` 15 ·
`TOTAL_MIGRATION_SITES` 24. Registry totals, scores, guard counts and the raw
taxonomy are unchanged — this moved one site into a count, not a finding into or
out of the registry.

---

## 26 · Final source-of-truth statement

**A20.1 WAS THE PRIMARY IMPLEMENTATION REGISTRY FOR THE DESIGN SYSTEM V1 MASTER
FIX. That work is finished.**

Since the V1 freeze (M100.40, 2026-09-05) this file is historical closure
evidence: every finding of §16–§19 is dispositioned in §27, and no row here is
an open item. What a design-system task reads *now* is
`docs/design-system/v1-freeze.md` — the frozen contracts, what enforces each of
them, and the five triggers that reopen V1.

Older A7–A20 reports remain historical evidence and must not override an A20.1
finding refreshed against CURRENT_SHA.

---

## 27 · Closure matrix — `fix/design-system-v1-closure`

Every finding of §16–§19, with what closed it. Dispositions: **FIXED** ×51; **P3-10** is FIXED for its three defects and INTENTIONALLY_ACCEPTED for the SDK's own route labels. No finding is BLOCKED and none is NO_LONGER_REPRODUCIBLE: each was reproduced at START_SHA and closed against a test.

Phases 0–8 landed as one commit each (`2fe68655` → HEAD); Phase 9 is the verification recorded in §24.

| ID | Disposition | Files | Contract | Test / verification |
|---|---|---|---|---|
| **P0-01** | FIXED | `study_swipe_deck_widget.dart` | a Previous/Next pointer row under the card, 48 dp, labelled; swipe unchanged | `study_browse_pointer_path_test` |
| **P1-01** | FIXED | new `mx_sheet.dart`; 16 routes in 13 files | `showMxSheet` is the one sheet route (root navigator, safe area, scroll-controlled); `MxSheetHeader` / `Semantics(header:)` on every title | `mx_sheet_test`; guard `no_raw_sheet_route` + probes |
| **P1-02** | FIXED | `mx_loading_state.dart`; 6 spinner sites | `MxLoadingState` / `.inColumn` / `.inline` — closed constructors, one semantics owner; determinate ring excluded by contract | `mx_loading_state_test`; guard `no_raw_loading_indicator` (+ `exclude:`) and `raw_progress_exclusions_test` |
| **P1-03** | FIXED | `memox-design-system-rules.yaml`, `memox-design-token-rules.yaml`, `scopes.yaml` | GUARD_RULE_COUNT 5 (`no_raw_screen_chrome`, `no_raw_choice_chip`, `no_raw_sheet_route`, `no_raw_loading_indicator`, `no_raw_stroke_width`); ENFORCEMENT_ACTION_COUNT 8 (+ extended `no_text_restyle`, geometry const-double test, `lib/app` typography scope) | 195 pytest probes; live scan green; synthetic fault probe red on all six |
| **P1-04** | FIXED | `mx_breadcrumb.dart` | the fold sits in `MxFocusRing(AppRadius.sm)` | `mx_breadcrumb_focus_test` |
| **P1-05** | FIXED | `mx_async_confirm_dialog.dart` | `PopScope(canPop: !isSubmitting)` — no dismissal mid-write | `mx_async_confirm_dismissal_test` |
| **P1-06** | FIXED | `elevation.css`, `css_scale_parity_test.dart` | kit mirrors Dart (owner decision 1); the test parses the kit's layers and compares them to `shadowsFor(level, scheme)` | `css_scale_parity_test` |
| **P1-07** | FIXED | 24 sites (9 card, 15 shared incl. `MxSearchField`'s alias) | `.inked(context, AppInk…)` is the one restyle spelling; `no_text_restyle` runs in file mode with five patterns | `text_restyle_alias_test`; probes |
| **P1-08** | FIXED | `widgetbook/lib/main.dart`, `study_render.dart`, `deck_screens_demo_test`, `feature_screens_demo_test`, gallery | four Widgetbook themes; `ReviewApp(isHighContrast:)`; HC goldens for the densest border surface and the screen with disabled controls | `widgetbook_coverage_test`; four HC goldens authored on Linux |
| **P1-09** | FIXED | new `theme_context_extension_test.dart`; rules YAML | every public accessor is named by a guard pattern or exempted with a reason, both directions; `inputHintStyle` joined the patterns | that test; pytest probe |
| **P1-10** | FIXED | `app_typography_test.dart`, `progress_streak_hero_widget.dart`, `app_typography.dart` | weights reachable from all four themes are exactly {400, 500, 600, 700}; every w700 source on a named allowlist; the streak hero uses `heroNumeralWeight` | that test (theme enumeration + source scan) |
| **P1-11** | FIXED — **reopened and re-closed in the corrective pass** | new `app_bold_text.dart`, `app.dart`, corrective: `app_bold_text.dart` | `applyBoldText` re-weighted only `textTheme` and `AppTextStyles`; every component-theme text slot (ListTile, NavigationBar, InputDecoration, PopupMenu, Dialog, date/time pickers, SnackBar, AppBar, Chip, Tooltip, TabBar, the button families) now goes through the same `wght` path | `app_bold_text_components_test` — every slot the theme sets resolves `wght 700`, and rendered ListTile / NavigationBar / InputDecoration / PopupMenu / Dialog / pickers / SnackBar text emboldens under `MediaQuery.boldText` |
| **P1-12** | FIXED | `app_theme.dart`, `app_snackbar_theme.dart`, `component_depth_and_state_test` | `ThemeData.shadowColor = materialShadowColor(scheme)` — the FAB reads it (`button.dart:387`); SnackBar has no shadow slot (SDK) and says so | `component_depth_and_state_test` — every floating surface names its shadow colour |
| **P1-13** | FIXED | `mx_feedback_band.dart`, `mx_card.dart`, `reminder_labels_widget.dart` | `MxFeedbackTone.warning` / `MxCardFeedbackTone.warning` on `warningContainer`; permission-denied is a warning | `reminder_settings_layout_test` (documented contract change) |
| **P1-15** | FIXED — **reopened and re-closed in the corrective pass** | `mx_content_shell.dart`, corrective: `mx_content_shell.dart` (`MxShellChrome`), `study_session_screen.dart` | the bar stays whenever there is a way back; **and** the policy is explicit: `MxShellChrome { auto, none }`, `none` asserted content-free. `StudySessionScreen` chooses `none` — it had been getting a bar with an inferred Back when pushed, a regression of BR-82 | `mx_content_shell_bar_test`, `mx_content_shell_chrome_test`, `study_session_chrome_test` (pushed through a real route: no `AppBar`, no `BackButton`, `MxSessionTopBar` present) |
| **P1-16** | FIXED — **reopened and re-closed in the corrective pass** | `card_breadcrumb_widget.dart`, `card_editor_context_widget.dart`, new `card_ancestors_widget.dart`, corrective: `card_ancestors_widget.dart`, `card_editor_context_widget.dart` | one up-navigation grammar, `onUp` / `onShowAll`; **and** the editor's Up is the deck the card is in (`goUpToDeck`), not that deck's parent, and its ancestor sheet lists the deck last — both still through `onLeave` | `card_editor_up_navigation_test` — editor Up → current deck, dirty draft still asks, sheet lists and reaches the deck; card-list Up and sheet unchanged |
| **P2-01** | FIXED | `memox-design-system-rules.yaml` | `no_raw_screen_chrome` (`AppBar`, `SliverAppBar`; `Scaffold` deliberately not), `no_raw_choice_chip` | probes; live scan 0 |
| **P2-02** | FIXED | new `mx_section_label.dart`; 14 headings | one all-caps policy: painted uppercase, spoken as written, `Semantics(header:)` | `mx_section_label_test` |
| **P2-03** | FIXED | `card_bulk_overlays_widget.dart`, `card_editor_screen.dart` | `AsyncValue.error` renders `MxErrorState`, never `MxEmptyState` | card editor / bulk tests |
| **P2-04** | FIXED | `mx_action_sheet.dart` | rows carry the row overlay and `MxFocusRing`, like every other row | `mx_action_sheet_focus_test` |
| **P2-05** | FIXED | `app_app_bar_theme.dart`, `m3_role_bindings.dart` | `iconTheme` is `onSurface` — the leading is not one step quiet | `m3_role_contract_test` |
| **P2-06** | FIXED | `app_slider_theme.dart` | `year2023: false` — one Material generation | planned-themes assertion |
| **P2-07** | FIXED | new `app_well_fill.dart`, `mx_metric_well.dart`, 8 callers | owner decision 2, structural: `AppWellFill {muted, due, streak, danger}` replaces `Color? wellColor` | `app_well_fill_test` (source pin + resolution) |
| **P2-09** | FIXED | 5 sites; `memox-design-token-rules.yaml` | `AppStroke.indicator` / `.control` / `.hairline`; `no_raw_stroke_width` | `app_stroke_test`; probes |
| **P2-10** | FIXED | 16 feature `const double` declarations | on-grid or `// off-grid:` justified | `feature_geometry_grid_test` |
| **P2-11** | FIXED | `app_high_contrast.dart` | the palette's own figures re-measured (borderSubtle 5.28/6.47, borderControl 5.28/6.47, borderAccent 5.67/11.27, onDisabled 3.81/5.12) | `high_contrast_figures_test` |
| **P2-12** | FIXED | `app_sizing.dart` and the 5 spellings | `AppSizing.controlDense` is the one 32 dp control tier | `spacing_is_a_gap_test` |
| **P2-13** | FIXED | `card_tile_widget.dart`, `mx_switch_row.dart`, `reminder_toggle_row_widget.dart`, ARB | the row's state is a flag; `MxSwitchRow` is one `SwitchListTile` channel — the `value` channel and its two strings are gone | `card_selection_test`, `mx_switch_row_test`, `reminder_settings_a11y_test` (documented contract changes) |
| **P2-14** | FIXED | `app_border_colors.dart`, `colors.css`, `mx_menu_button.dart` | `borderOptionLight` `#7383FF` (3.27:1, within its family; kit mirrors it); picker rows carry `selected` + exclusive group | `css_token_parity_test`, `mx_menu_button_selection_test` |
| **P2-15** | FIXED | `app_toggle_themes.dart`, `app_radio_theme.dart` | disabled selection controls keep their boolean, as `_CheckboxDefaultsM3` / `_RadioDefaultsM3` do | `app_selection_disabled_states_test` |
| **P2-16** | FIXED | `app_date_picker_theme.dart`, `reminder_labels_widget.dart` | `selected` resolves before `disabled`; the row honours `alwaysUse24HourFormat` | `app_date_picker_theme_test` |
| **P2-17** | FIXED | four sweep tests; `mx_search_field.dart`, `card_sort_control_widget.dart`, `search_result_shell_widget.dart` | every screen swept for 48 dp and labelled targets; the search field itself stands 48; the card sort anchor is 48; result rows merge name and tap onto one node | `*_accessibility_sweep_test` ×4 |
| **P2-18** | FIXED | `mx_content_shell.dart`, new `mx_reading_column.dart`, new `mx_scroll_end_inset.dart`, 6 callers | shell owns the scrolled hairline (under the band), the reading column, the scroll-end inset and the two-line bar's 1.34 title clamp | `mx_content_shell_geometry_test` |
| **P2-19** | FIXED | icon sites; new `app_glyph_register.dart` | one glyph one meaning; check-box pair for selection; `share`, `flag`, `history`, `restore` | `glyph_register_test` |
| **P2-20** | FIXED | `mx_messenger.dart` | 4 s plain, 8 s actionable = undo | `mx_messenger_duration_test` |
| **P2-21** | FIXED | new `mx_picker_render_test.dart`, `mx_dropdown.dart` | both pickers rendered under the theme; `MxDropdown` disabled = `onChanged: null`, no error slot by decision (the row owns validation) | that test |
| **P2-22** | FIXED | `scopes.yaml`, `error_screen_widget.dart` | `lib/app/` is in the typography scopes; the error screen builds its rungs through `AppTypography` | guard live scan |
| **P3-01** | FIXED | new `keyboard_primitives_absent_test.dart` | the absence of keyboard primitives is a recorded decision (AD-04), mechanically | that test |
| **P3-02** | FIXED | `mx_icon_test.dart` | policy: a glyph is a fixed dp step at every text scale; glyphs inside a text run are the SDK's `WidgetSpan` case | that test |
| **P3-03** | FIXED | `mx_progress_bar.dart`, Widgetbook | `MxProgressBarShape` and the `shape` parameter removed — one shape | analyze; Widgetbook smoke |
| **P3-04** | FIXED | `app_theme.dart`, `app_sizing.dart`, test renamed to `app_unrendered_component_themes_test.dart`, skill references | no present-tense reference to a deleted file | grep |
| **P3-05** | FIXED | `mx_icon.dart`, `app_bottom_sheet_theme.dart`, `app_dialog_theme.dart` | prose matches code: no well citation, the handle is `onSurfaceVariant`, nothing paints a dialog shadow | read |
| **P3-06** | FIXED | `registries/projects/{memox-v4,memox-v5,memox-design-jsx}` removed; `memox-v7/rules/README.md` | `memox` stays as the guard's own test fixture, and the README says so | pytest 195 |
| **P3-07** | FIXED | `pubspec.yaml`; `Icons.share` (Phase 7) | `cupertino_icons` gone; no `ios_share` on an Android target | `glyph_register_test` |
| **P3-08** | FIXED | `scale_sections.dart`, `design_tokens_test.dart` | `mdCompact` and `AppRadius.xl` catalogued and in the ordering assertion | that test |
| **P3-09** | FIXED | four theme files (Phase 2) | `AppElevation.none` | analyze |
| **P3-10** | FIXED / INTENTIONALLY_ACCEPTED | `route_not_found_screen.dart`, `mx_session_top_bar.dart`, ARB | the 404 face and the session chip name their routes; `deckPathAncestorsHint` removed. *Accepted:* dialogs announce "Alert" and sheets "Dialog" — those are `MaterialLocalizations` route labels the SDK sets | analyze; session tests |
| **P3-11** | FIXED | `mx_form_dialog.dart`, `mx_action_sheet.dart`, hosts | `isSubmitting` and `isEnabled` removed with their tests and knobs | analyze; `mx_form_dialog_test` |
| **P3-12** | FIXED | new `mx_icon_test.dart` | null label ⇒ `ExcludeSemantics`; label spoken once; size and ink are names | that test |
| **P3-13** | FIXED | `mx_breadcrumb.dart` | `assert(lineHeight >= touchTarget || onUp != null)` — a strip below the floor must be one target | assert |
| **P3-14** | FIXED | `app_stroke.dart` (Phase 2) | `AppStroke.control` names the role, not a component | `app_stroke_test` |

### 27.1 · Corrective pass — `fix/design-system-v1-corrective`

Three closures in #460 were re-examined after merge and found short of their
own contract; each was reopened, fixed and re-closed against a rendered test:

| ID | What #460 proved | What it missed | Re-closure |
|---|---|---|---|
| P1-11 | the text theme and `AppTextStyles` re-weight through `wght` | component themes keep their own copies of those styles, so a tile, a hint, a menu row, a dialog and both pickers stayed at resting weight | every text slot the theme sets is re-weighted; rendered tests per family |
| P1-15 | a pushed loading/error screen keeps its bar and Back | the study session, custom chrome by design, gained the same inferred bar — a BR-82 regression | `MxShellChrome { auto, none }`; the session says `none`; pushed-route test |
| P1-16 | one up-navigation grammar for card trails | the editor's Up went to the deck's parent, one level too far, and its sheet could not reach the deck | `goUpToDeck`; the sheet lists the deck last; `onLeave` preserved; tests both ways |

§23 stays **30 / 30** and §24 **21 / 22** *at this pass*: the criteria were met
at #460's level of evidence, and the corrective pass raised the evidence, not
the score. §24 reached **22 / 22** later, at the V1 freeze, when the device
suite was actually run (§28).

**Corrective pass 2 (P1-11 again).** The owner's review of #462 found three
gaps the re-closure still had: `hintStyle` is a `WidgetStateTextStyle`
(`onDisabled` when disabled) and re-weighting its resting resolution dropped
the resolver; `TimePickerThemeData.dialTextStyle` and
`SliderThemeData.valueIndicatorTextStyle` are set by the theme and were not
re-weighted. Fixed by wrapping state-resolved styles in a new resolver and by
naming the two slots — and by a registry test that reads every `*Style:` /
`*TextStyle:` slot the component themes set and asserts `applyBoldText` names
each one, so a slot cannot be missed by hand a third time. Rendered proof: a
disabled field's hint is emboldened *and* keeps `onDisabled`; the slider's
value indicator and the dial resolve `wght 700` in place.


---

## 28 · V1 freeze verification — `chore/design-system-v1-release-freeze`

M100.40, 2026-09-05. **No audit was performed and no component was redesigned.**
This section records the run that closed §24 and froze V1; the frozen contracts
themselves live in `docs/design-system/v1-freeze.md`, which is where a later
task should look.

| | |
|---|---|
| START_SHA | `9443c49c` (= `origin/main`) |
| FREEZE_SHA | `b4599c35` — the last commit touching anything a gate measures |
| Flutter | 3.44.8 · Dart 3.12.2, matching `.fvmrc` and the CI runners |
| §23 architecture | **30 / 30** |
| §24 verification | **22 / 22** |

| # | Gate | Command | Result |
|---|---|---|---|
| 1 | format | `dart format --set-exit-if-changed .` | 1532 files, 0 changed |
| 2 | analyze | `flutter analyze --no-fatal-infos` (after `pub get` in `widgetbook/`, as CI does) | **No issues found** |
| 3 | guard | `guard/run.py check --ruleset memox-v7` | 84 rules, **no violations** |
| 4 | guard probes | `pytest` in `code-verification-guard-v2/` | **195 passed** |
| 5 | docs | `check_docs.py` | internally consistent |
| 6 | codegen | `check_generated.py` | fresh, complete, uncommitted |
| 7 | host suite | `TZ=UTC flutter test --exclude-tags golden` | **4772 passed**, exit 0 |
| 8 | Widgetbook | `flutter test --reporter failures-only` in `widgetbook/` | passed |
| 9 | goldens | `goldens (linux)` job reproduced in WSL Ubuntu 24.04, `TZ=UTC`, Flutter 3.44.8 | **325 / 325**, count floor 325 ≥ 70, working tree clean afterwards |
| 10 | Android integration | `flutter test integration_test/ -d emulator-5554 --flavor development` | **8 / 8**, exit 0 |

Accessibility is inside gate 7: the four `*_accessibility_sweep_test` files
(card, search, reminder, trash) run `meetsGuideline` for tap-target size and
labelled targets on every screen.

### 28.1 · The two things this branch changed, and why they are not a redesign

**The Bold-text registry is now keyed by component theme + slot.** §27.1's
corrective pass 2 added a registry that read every `*Style:` / `*TextStyle:`
slot the component themes set and asserted `applyBoldText` names each one — but
it collected **bare field names** into a single set and matched them as
substrings against the file. Four component themes spell a slot `labelStyle`
and two more spell one `labelTextStyle`, so one owner's re-weight satisfied
every other owner's check. Deleting the whole `tabBarTheme` block left
`labelStyle:` in the file twice and `unselectedLabelStyle:` once, and the
registry stayed green.

The registry is now discovered from the built `ThemeData` through its own
diagnostics — which emit all forty-odd component sub-themes and suppress a slot
the app left null — and keyed `owner.slot`: 23 pairs, identical across all four
themes, pinned. Each pair is asserted per state against
`AppTypography.withWeight(before, w700)`, so one equality carries the `wght`
resolution, the surviving resolver, the state colour and the geometry at once.
Four fault injections were run before it was trusted; the first is the one above.

**`MaterialApp.builder` is now under test.** Every one of the twenty-two
Bold-text tests wired `BoldTextWidget` by hand, so none of them could see the
wrapper leaving `app.dart`. Measured: with that line deleted, all 52 tests under
`test/core/theme/schemes/` still pass while the OS setting is once again the
exact no-op P1-11 was raised for. `CompactScaleWidget` sits on the same line and
had the same hole. `app_media_query_wiring_test` closes both against the real
root widget.

Neither changes a pixel: gate 9 compared 325 goldens against the committed PNGs
and rewrote none of them.
