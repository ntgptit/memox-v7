# A9 — the modal / sheet / overlay system, audited as one language

| | |
|---|---|
| **Status** | report only — no code, test, theme, Widgetbook, golden, CI or generated file was changed |
| **Purpose** | Judge every modal surface in the app as **one** language: what Flutter 3.44.8 actually builds when `showDialog` and `showModalBottomSheet` are called, what memox layers on top, and where the two families have quietly stopped agreeing with each other |
| **Scope** | `DialogThemeData` · `BottomSheetThemeData` · the backdrop recipe · `MxConfirmDialog` · `MxAsyncConfirmDialog` · `MxFormDialog` · `MxAlertDialog` · `MxDialogHeader` / `MxDialogTone` · `MxDialogMetrics` · `MxActionSheet` · `MxSheetInsets` / `MxFormSheet` · `MxButtonPair` where a modal owns it · all **22** production modal entry points |
| **Audited against** | worktree HEAD **`3207e7b7e0d3a2ecefa5e6a85fed48a65890ba6b`** (`refactor(theme): the dark card stops glowing…` #435), identical to `origin/main` at the time of the audit · Flutter **3.44.8** (`.fvmrc`), SDK source read verbatim from the 3.44.8 tag |
| **Not in scope** | Token *values* (AD-14) · `SnackBar` / `MxMessenger` (a float, not a modal — no barrier, no route) · `PopupMenuButton` (no scrim; owned by `app_popup_menu_theme.dart`) · full-screen routes (card editor, import wizard) · anything another worktree is currently holding |
| **Last updated** | 2026-09-03 |

**Method note.** Every framework claim below was read from the Flutter 3.44.8
source (`packages/flutter/lib/src/material/dialog.dart`,
`bottom_sheet.dart`, `packages/flutter/lib/src/widgets/routes.dart`,
`navigator.dart`, `focus_traversal.dart`), not recalled. Every composited
colour was computed from the palette constants as they stand at `3207e7b7`
using the same model `focus_ring_contrast_test.dart` uses —
`Color.alphaBlend(overlay, ground)` — with WCAG relative luminance for contrast
and CIE L\* for perceptual steps. **Both numbers are reported for every dark
surface on purpose:** the WCAG ratio compresses badly near black and reading it
alone is exactly how a dark surface gets "fixed" with a glow, which is what
#435 has just finished removing. No golden was rendered or regenerated; the
three photographic pieces of evidence are goldens already committed at this SHA.

---

## 1. Executive verdict

**The dialog half of this system is finished work. The sheet half is seven
call sites that each configured `showModalBottomSheet` themselves, and the
framework's defaults are not the ones this app needs.**

That split is the whole finding, and it is structural rather than cosmetic.
Dialogs reach Material through exactly four `showDialog` calls, all four inside
`lib/shared/widgets/`, all four behind a named `showMxX` function.
`lib/features/` contains **zero** `showDialog`, **zero** raw `AlertDialog`,
**zero** raw `Dialog`. That is as clean as this kind of boundary gets, and the
five API escape hatches a dialog could have leaked through are all closed.

Sheets have no such boundary. `showModalBottomSheet` is called **17 times**,
**16 of them directly from a feature**, each restating `isScrollControlled`,
`useSafeArea`, the barrier and the content inset by hand.
`showMxFormSheet` exists and is used by five of them; the other twelve are
hand-rolled. The three P1s below are all consequences of that, and each of them
has already been discovered once, spot-fixed at one call site, and left
standing at the rest:

- **The scrim does not cover the app's own navigation.** `showDialog` defaults
  to the root navigator and `showModalBottomSheet` defaults to the nearest one —
  which in a `StatefulShellRoute` app is the branch navigator, *inside* the
  shell `Scaffold`'s body. Two goldens committed at this SHA show it side by
  side: `deck_delete_confirm_light.png` dims the bottom navigation bar,
  `deck_sort_sheet_light.png` leaves it fully lit and fully tappable.
- **Seven scroll-controlled sheets can reach the top of the screen with
  nothing between their first line and the status bar.** `useSafeArea` defaults
  to `false`, and the framework then applies `MediaQuery.removePadding(removeTop:
  true)` — which makes an inner `SafeArea` a **no-op at the top**. Two call
  sites already carry `useSafeArea: true` as a spot fix, and one of them
  (`study_entry_screen.dart:186`) documents the exact failure in prose. The
  shared `showMxFormSheet` is one of the seven that does not.
- **A confirmation that disables both its buttons while a write runs leaves
  the barrier and the back gesture live.** Dismissing mid-write skips `onDone`,
  so the deck and card delete commit and their Undo batch id (BR-263) is never
  delivered. `mx_async_confirm_dialog_test.dart` has a group called *"both
  actions go inert while the write runs"* — it asserts the two buttons and
  stops there.

**P0: none.** Nothing measured here breaks a contrast floor, and nothing
destroys data without a confirmation. The dark surfaces are clean: the sheet in
dark is `surfaceContainerLow`, `elevation: 0`, `surfaceTint` transparent, no
shadow, no rim — the dark action-sheet golden is a flat panel, and #435's
property holds across the whole modal family.

**One thing this report deliberately does not recommend: giving the dark sheet
an edge.** It measures 1.14:1 against the scrimmed page, which reads alarming
and is the wrong number to act on — see §8.3.

**Recommended next pass: §14, six steps.** Two of them need an owner decision
before any code moves, because they change every sheet golden in the repo.

---

## 2. BASE_SHA and audit conditions

```
BASE_SHA  3207e7b7e0d3a2ecefa5e6a85fed48a65890ba6b
subject   refactor(theme): the dark card stops glowing, and elevation stops
          meaning two things (M100.35) (#435)
tree      clean (git status --porcelain empty)
branch    claude/a9-modal-overlay-audit-z2gs5x
```

No pull, merge or rebase was performed. `HEAD` was identical to `origin/main`
at audit time, so every line and every golden cited is the one a reader will
find at that SHA.

**One deviation from the brief, stated rather than hidden.** The task names the
branch `audit/a9-modal-overlay`; this session is bound by its harness to
`claude/a9-modal-overlay-audit-z2gs5x`, which is also the convention the last
three audit branches used (`claude/a7-icon-actions-audit-vnv9sz`). The report
path is exactly as specified.

---

## 3. Modal taxonomy — what this app actually opens

22 entry points — 4 dialog, 17 bottom sheet, 1 platform picker. The
classification is by **what the surface asks of the user**, not by which widget
class it happens to be, because that is the axis on which two of them turned out
to disagree.

### 3.1 Dialogs (4 shared entry points, root navigator, `closedLoop` traversal)

| # | Class | Entry point | Callers | Shape |
|---|---|---|---|---|
| D1 | confirm (one-shot) | `showMxConfirm` | 5 — card bulk delete, card discard, card import, starter add-again, trash purge | `MxConfirmDialog` → `AlertDialog` |
| D2 | confirm (async, stays mounted) | `showMxAsyncConfirm` | 4 — deck delete, card delete, tag delete, settings reset | `MxAsyncConfirmDialog` → `MxConfirmDialog` |
| D3 | form (single field) | `showMxPromptDialog` | 1 — card bulk tag | `MxFormDialog` → `AlertDialog` |
| D4 | informational | `showMxAlert` | **0** — deliberate, recorded in `mx_alert_dialog.dart` and WBS M99.59 | `MxAlertDialog` → `AlertDialog` |

Destructive-confirm is a **variant**, not a fifth shape:
`MxConfirmDialogVariant.destructive` has exactly one production caller
(`showTrashPurgeDialog`), and every soft delete correctly uses `cautious`
(BR-266). That is the taxonomy working — the destructive colour still means
something because only one dialog spends it.

### 3.2 Sheets (17 `showModalBottomSheet` calls, branch navigator, `parentScope` traversal)

| # | Class | Call site | `isScrollControlled` | `useSafeArea` | Content inset |
|---|---|---|---|---|---|
| S1 | action chooser | `deck_actions_widget.dart:64` | — | — | `MxActionSheet` (`SafeArea` + `sm`) |
| S2 | action chooser | `library_menu_widget.dart:25` | — | — | `MxActionSheet` |
| S3 | action chooser | `deck_create_child_widget.dart:71` | — | — | `MxActionSheet` |
| S4 | navigation chooser | `deck_ancestors_widget.dart:25` | — | — | `MxActionSheet` |
| S5 | picker (state-marking) | `deck_sort_sheet_widget.dart:62` | — | — | `MxActionSheet` |
| S6 | action chooser | `trash_row_menu_widget.dart:18` | — | — | `MxActionSheet` |
| S7 | action chooser | `study_entry_screen.dart:73` (resume) | — | — | `StudyResumeWidget` |
| S8 | action chooser | `study_entry_screen.dart:162` (mode) | — | — | `StudyModeChooserWidget` |
| S9 | form host | `mx_form_sheet.dart:40` — 5 callers | **yes** | **no** | `MxSheetInsets` |
| S10 | picker host | `card_bulk_overlays_widget.dart:65` (move target) | **yes** | **no** | `SafeArea` + `all(lg)` |
| S11 | feature-specific | `card_export_sheet_widget.dart:73` | **yes** | **no** | bare `mxSheetBottomObstruction`, **no top gutter** |
| S12 | picker host | `deck_actions_widget.dart:264` (move deck) | **yes** | **no** | `SafeArea` + `all(lg)` |
| S13 | feature-specific | `starter_install_widget.dart:31` | **yes** | **no** | `MxSheetInsets` |
| S14 | destructive confirm | `deck_reset_progress_widget.dart:30` | **yes** | **no** | `SafeArea` + `all(lg)` |
| S15 | form / explanation | `deck_scheduler_change_widget.dart:39` | **yes** | **no** | `SafeArea` + `all(lg)` |
| S16 | picker host | `trash_restore_target_sheet_widget.dart:27` | **yes** | **yes** | `SafeArea` + `all(lg)` |
| S17 | form (locked choice) | `study_entry_screen.dart:192` (direction) | **yes** | **yes** | own `SafeArea(top: false)` |

### 3.3 Picker host outside both families

| # | Class | Call site | Notes |
|---|---|---|---|
| P1 | platform picker | `reminder_time_picker_widget.dart:24` — `showTimePicker` | Reconciled: `buildTimePickerTheme` restates `dialogTheme`'s answers in the slots `TimePickerDialog` actually reads, and the barrier still resolves through `dialogTheme.barrierColor`. **No finding.** |

### 3.4 Two rows that do not fit their own family

- **S14 `deck_reset_progress` is a destructive confirmation drawn as a sheet.**
  The reason is stated and good (BR-50 needs two lists plus a scheduler picker;
  `MxConfirmDialog` takes one `message` string). But it means the app's
  *second* destructive confirmation does not inherit `MxConfirmDialog`'s focus
  rule, does not sit behind a full-screen barrier (§8.1), and can be dismissed
  by a downward drag mid-write. It is the one surface where the taxonomy's
  seam is load-bearing and unguarded.
- **S11 `card_export` is the only modal in the app with a `PopScope`.** It is
  also the only one whose author thought about being dismissed mid-flight —
  which is the direct evidence for A9-03 and A9-04.

---

## 4. The Flutter 3.44.8 contract, read rather than recalled

Line numbers are of the 3.44.8 checkout.

### 4.1 What `showDialog` builds (`dialog.dart:1622`)

| Knob | 3.44.8 default | What memox gets |
|---|---|---|
| `barrierColor` | `barrierColor ?? DialogTheme.of(context).barrierColor ?? Theme.of(context).dialogTheme.barrierColor ?? Colors.black54` (1655–1659) | `modalBarrierColor(scheme)` ✓ |
| `barrierDismissible` | `true` | `true` at all four call sites |
| `barrierLabel` | `MaterialLocalizations.of(context).modalBarrierDismissLabel` (1852) | localized, `GlobalMaterialLocalizations` is wired (`app.dart:74`) ✓ |
| `useSafeArea` | `true` → `SafeArea(child: dialog)` (1845) | **top is protected** ✓ |
| `useRootNavigator` | `true` | root navigator — barrier covers the shell ✓ |
| `traversalEdgeBehavior` | **pinned to `TraversalEdgeBehavior.closedLoop`** (1666) | Tab is trapped in the dialog ✓ |
| back gesture | `_DialogPopScope(canPop: false, onPop: navigator.pop)` (1435) | Back pops, always |

### 4.2 What `Dialog.build` paints (`dialog.dart:264`)

```
Semantics(role: SemanticsRole.alertDialog)
  AnimatedPadding(padding: MediaQuery.viewInsetsOf(context) + insetPadding)   ← keyboard
    MediaQuery.removeViewInsets(all four edges)
      Align(alignment)
        ConstrainedBox(constraints ?? dialogTheme.constraints ?? minWidth: 280)
          Material(color, elevation, shadowColor, surfaceTintColor, shape, type: card)
```

Three consequences that matter here:

1. **`effectivePadding` is `viewInsets + insetPadding` (269).** A dialog moves
   itself above the keyboard without anyone asking. `MxFormDialog` therefore
   needs no keyboard handling of its own, and has none — correct.
2. **There is no `maxWidth`** unless the theme sets `constraints`
   (275). memox does not, so a dialog's width is
   `min(screen − 80, AlertDialog's IntrinsicWidth)`. On the release target
   (393dp) that is 313dp; on a tablet or the web E2E channel it is
   `screen − 80` capped by the longest unwrapped line of `message`. Harmless
   today because AD-04 fixes the target, but it is the one geometry slot in the
   modal system nobody has stated.
3. **`_DialogDefaultsM3.shadowColor` is `Colors.transparent` (1982).** M3's own
   dialog paints **no shadow** at its nominal `elevation: 6.0`. So memox's
   `elevation: 0` is not a departure from M3's rendered result — it is
   identical. See A9-10: the code comment says something else.

### 4.3 What `AlertDialog.build` adds (`dialog.dart:765`)

- **Route naming.** `label = semanticLabel ?? MaterialLocalizations.alertDialogLabel`
  on Android (773–780), then `Semantics(scopesRoute, namesRoute, label)`. Because
  `label != null`, the **title deliberately does not name the route** (843). No
  memox dialog passes `semanticLabel`, so every dialog in the app announces
  itself as *"Alert"* / *"Hộp thoại cảnh báo"* — canonical, and see A9-13.
- **Content semantics.** `Semantics(container: true, explicitChildNodes: true)`
  (874). `MxConfirmDialog`'s `Semantics(liveRegion: true)` sits inside that as
  its own node — correct, and `mx_confirm_dialog_test.dart` pins it.
- **`actions` go into `OverflowBar(alignment: end, spacing: 8)`** (886–898),
  laid out inside `IntrinsicWidth` (925). `MxButtonPair` is a `RenderBox`
  precisely because `LayoutBuilder` cannot answer an intrinsic query here — the
  reasoning in `mx_button_pair.dart:50` is correct and load-bearing.
- **`_scalePadding` (1892)** shrinks all dialog padding from ×1 to ×⅓ as the
  text scale climbs 1→2. So the dialog's own gutters shrink at large text while
  `MxDialogMetrics.actionsPadding` — which the widget states explicitly — does
  not. That is *why* the two must be stated together, and they are.
- **`icon:` centres the title** (842: `textAlign: icon == null ? start : center`).
  `MxDialogHeader` refuses that slot for exactly this reason, and its doc comment
  is accurate.

### 4.4 What `showModalBottomSheet` builds (`bottom_sheet.dart:1289`)

| Knob | 3.44.8 default | What memox gets |
|---|---|---|
| `useRootNavigator` | **`false`** | **branch navigator** — A9-01 |
| `useSafeArea` | **`false`** → `MediaQuery.removePadding(removeTop: true)` (1163) | **inner `SafeArea(top:)` is a no-op** — A9-02 |
| `isScrollControlled` | `false` → child capped at `maxHeight × 9/16` (`_getConstraintsForChild`, 92–100) | 8 sheets capped, 9 uncapped |
| `barrierColor` | `Theme.of(context).bottomSheetTheme.modalBarrierColor` (1331) | `modalBarrierColor(scheme)` ✓ |
| `barrierLabel` | `localizations.scrimLabel`, hint `scrimOnTapHint(bottomSheetLabel)` (1323–4) | localized ✓ |
| `isDismissible` / `enableDrag` | `true` / `true` | never overridden — A9-03/A9-04 |
| `traversalEdgeBehavior` | **not set** → `kDefaultRouteTraversalEdgeBehavior` = `parentScope` (`navigator.dart:1255`) | **not `closedLoop`** — A9-12 |
| route naming | `Semantics(scopesRoute, namesRoute, label: localizations.dialogLabel)` (787–790) | every sheet announces *"Dialog"* — A9-13 |
| `elevation` | `sheetTheme.modalElevation ?? sheetTheme.elevation ?? defaults.modalElevation (1.0)` | memox sets `elevation: 0`, leaves `modalElevation` null → **0** ✓ |
| `backgroundColor` | `modalBackgroundColor ?? backgroundColor ?? defaults (surfaceContainerLow)` | `surfaceContainerLow` ✓ canonical |
| `constraints` | not set by memox → `_BottomSheetDefaultsM3.constraints` = `maxWidth: 640` | inherited; correct, and unstated |

### 4.5 The drag handle (`bottom_sheet.dart`, `_DragHandle`)

```
MouseRegion
  Semantics(label: modalBarrierDismissLabel, container: true, button: true, onTap: onClosing)
    SizedBox(width: max(32, 48), height: max(4, 48))      ← kMinInteractiveDimension
      Center → Container(32 × 4, radius 2, colour = resolveAs(dragHandleColor, states))
```

- The 48 × 48 target is the framework's, not memox's — **it cannot regress**, and
  it is why the handle needs no tap-target test of its own.
- `WidgetStateProperty.resolveAs` resolves a `WidgetStateColor` correctly, so
  `buildBottomSheetTheme`'s `resolveWith` closure does reach the paint. ✓
- **With a handle shown, `widget.builder(context)` is wrapped in
  `Padding(top: kMinInteractiveDimension)` = 48dp** (`_BottomSheetState.build`,
  147–150). Every sheet's content therefore already starts 48dp down. This is
  the number A9-06 is about.

---

## 5. Dialog

### 5.1 Surface — role, radius, elevation, tint, constraints

| Slot | memox | M3 3.44.8 | Verdict |
|---|---|---|---|
| `backgroundColor` | `scheme.surfaceContainerHigh` | `surfaceContainerHigh` | **canonical** ✓ |
| `surfaceTintColor` | `Colors.transparent` | `Colors.transparent` | canonical ✓ |
| `elevation` | `0` | `6.0` with `shadowColor: transparent` | **renders identically** ✓ |
| `shape` radius | `AppRadius.lg` = 16 | 28 | deliberate app scale ✓ |
| `shape` side | `BorderSide(outlineVariant)` | none | **memox addition** — carries the separation the zero elevation gives up |
| `titleTextStyle` | `titleMedium` + `onSurface` | `headlineSmall` | deliberate downshift; `component_theme_typography_test.dart` covers the family |
| `contentTextStyle` | `bodyMedium` + `onSurfaceVariant` | `bodyMedium` (inherited colour) | **more** canonical than M3 — `onSurfaceVariant` is what the M3 spec asks of supporting text ✓ |
| `constraints` | unset → `minWidth: 280`, **no max** | same | stated nowhere; see §4.2 |
| `insetPadding` | `MxDialogMetrics.insetPadding` = `symmetric(h: 40, v: 24)` | `_defaultInsetPadding` = `symmetric(h: 40, v: 24)` | **byte-identical to the framework default, stated on purpose** ✓ |
| `actionsPadding` | `MxDialogMetrics.actionsPadding` = `fromLTRB(24, 0, 24, 24)` | `only(l:24, r:24, b:24)` | identical ✓ |

**Measured, light** (dialog on `surfaceContainerHigh` #E9EBEE):

| Pair | Contrast | Floor |
|---|---|---|
| title `onSurface` | **10.53:1** | 4.5 ✓ |
| body `onSurfaceVariant` | **4.83:1** | 4.5 ✓ |
| tone glyph `danger` / `warning` / `success` / `info` | 4.83 / **4.15** / 4.65 / 4.54 | 3.0 (graphic) ✓ |
| dialog vs scrimmed page | **3.08:1**, ΔL\* 37.4 | — |
| hairline `outlineVariant` vs scrimmed page | 2.97:1 | — |

**Measured, dark** (dialog on #21274C):

| Pair | Contrast | Floor |
|---|---|---|
| title `onSurface` | **8.98:1** | 4.5 ✓ |
| body `onSurfaceVariant` | **4.84:1** | 4.5 ✓ |
| tone glyph `danger` / `warning` / `success` / `info` | 5.65 / 7.20 / 6.77 / 7.06 | 3.0 ✓ |
| dialog vs scrimmed page | 1.40:1, **ΔL\* 15.14** | — |

`warning` at **4.15:1** in light is the tightest number in the dialog set. It is
a **glyph**, so 3:1 is the applicable floor (WCAG 1.4.11) and it clears it with
room. Recorded because it is the first number that would move if the dialog
surface ever changed rung.

**Evidence, dark, #435:** `deck_delete_confirm_dark.png` at this SHA is a flat
`surfaceContainerHigh` panel with a hairline and no halo. The dark dialog does
not glow.

### 5.2 The three dialog shapes do not share their geometry

`MxConfirmDialog` (115–120) and `MxFormDialog` (81–88) both state
`insetPadding: MxDialogMetrics.insetPadding` and
`actionsPadding: MxDialogMetrics.actionsPadding`.

**`MxAlertDialog` (55–58) states neither.** It falls through to
`_defaultInsetPadding` and `_DialogDefaultsM3.actionsPadding` — which today are
the *same numbers*, so nothing renders differently. That is precisely the
problem: `MxDialogMetrics`' own doc says it "lives here rather than on
`MxConfirmDialog` because there are now **three** dialogs — confirm, form and
alert", and the third one does not read it. An SDK bump that moves
`_defaultInsetPadding` moves one of the three dialogs and not the other two,
silently, with no golden covering the one that moves (§12). → **A9-07 (P2)**

### 5.3 Header and tone

`MxDialogHeader` is shared by `MxConfirmDialog`, `MxFormDialog` and
`MxAlertDialog` — one header layout, three shapes. The two-axis split
(`MxConfirmDialogVariant` = what happens to my data; `MxDialogTone` = how
serious this is) is used correctly at every call site, including the one pair
that proves the axes are independent: `showStarterAddAgainConfirm` is
`cautious` + `info`.

Tone glyph shapes are four distinct silhouettes, not one glyph tinted four ways
— correct for the ~1-in-12 readers who cannot separate the amber from the red,
and `mx_alert_dialog_test.dart` pins glyph *and* token for two of the four.

### 5.4 Async confirmation

`MxAsyncConfirmDialog` fires `onDone` on the **crossing** into `closeWhen`, from
a post-frame callback, guarded by `mounted` (134–164). The reasoning is right and
the four hand-written copies it replaced are gone. Two flags rather than one
(`isSubmitting` disables both actions; `isBlocked` disables confirm only, so the
way out stays open during BR-04's impact read) is the correct decomposition and
is tested.

**What is not guarded is the third and fourth way out.** See §10.3 / A9-03.

---

## 6. Bottom sheet

### 6.1 Surface

| Slot | memox | M3 3.44.8 | Verdict |
|---|---|---|---|
| `backgroundColor` | `scheme.surfaceContainerLow` | `surfaceContainerLow` | **canonical** ✓ |
| `modalBackgroundColor` | unset → falls to `backgroundColor` | — | ✓ |
| `surfaceTintColor` | `Colors.transparent` | `Colors.transparent` | ✓ |
| `elevation` | `0` (and `modalElevation` unset) | `elevation: 1.0`, `modalElevation: 1.0`, `shadowColor: transparent` | renders identically ✓ |
| `shape` | `vertical(top: circular(16))` | `vertical(top: circular(28))` | app scale ✓ |
| `shape` side | **none** | none | ✓ canonical — see §8.3 |
| `showDragHandle` | `true` | `false` | deliberate ✓ |
| `dragHandleColor` | `onSurfaceVariant`, `dragged`/`hovered` = `alphaBlend(onSurface @ 0.12, onSurfaceVariant)` | `onSurfaceVariant`, no state variance | **role preserved, state as a layer** ✓ — exactly the correction M100.23 made in four other resolvers |
| `dragHandleSize` | unset → `Size(32, 4)` | same | ✓ |
| `constraints` | unset → `maxWidth: 640` | same | inherited ✓ |

**Measured, light** (sheet on `surfaceContainerLow` = #FFFFFF):

| Pair | Contrast |
|---|---|
| drag handle `onSurfaceVariant` | **5.77:1** (floor 3.0 — it is a `button`) ✓ |
| drag handle, `dragged` | **6.33:1** ✓ |
| sheet title `onSurfaceVariant` | 5.77:1 ✓ |
| row label `onSurface` | 12.58:1 ✓ |
| row `destructive` `danger` | 5.77:1 ✓ |
| sheet vs scrimmed page | 3.68:1, ΔL\* 44.4 |

**Measured, dark** (sheet on #111633):

| Pair | Contrast |
|---|---|
| drag handle `onSurfaceVariant` | **5.95:1** ✓ |
| drag handle, `dragged` | **6.49:1** ✓ |
| sheet title `onSurfaceVariant` | 5.95:1 ✓ |
| row label `onSurface` | 11.05:1 ✓ |
| row `destructive` `danger` | 6.95:1 ✓ |
| sheet vs scrimmed page | 1.14:1, **ΔL\* 6.58** — §8.3 |

### 6.2 Height, keyboard and view insets

`_RenderBottomSheetLayoutWithSizeListener._getConstraintsForChild` gives the child
`maxHeight = constraints.maxHeight × (isScrollControlled ? 1 : 9/16)`. **The
framework applies no keyboard inset to a bottom sheet at all** — that is the
whole reason `mxSheetBottomObstruction` exists, and its formula
(`max(viewInsets.bottom, viewPadding.bottom)`, never a sum) is right and is
tested against `viewPadding` explicitly, which is the configuration that made
the original bug invisible (`mx_sheet_insets_test.dart`).

`showMxFormSheet` composes it correctly: `MxSheetInsets` sits **outside** the
`SingleChildScrollView`, so the scroll viewport shrinks to the space above the
keyboard rather than scrolling under it. ✓

### 6.3 The top, which nobody has measured

`useSafeArea: false` — the default at 15 of 17 call sites — makes the framework
apply `MediaQuery.removePadding(context, removeTop: true)` (`bottom_sheet.dart:1163`).
The SDK doc on that parameter says it outright:

> *If false, then moreover `MediaQuery.removePadding` will be used to remove top
> padding, so that a `SafeArea` widget inside the bottom sheet will have **no
> effect at the top edge**.*

So the `SafeArea` in `MxActionSheet`, in `_ResetProgressSheet`, in
`_SchedulerSheet`, in `MoveDeckSheetWidget`, in `_MoveTargetSheet` protects the
**bottom only**. For the eight sheets that are not scroll-controlled this costs
nothing — 9/16 of the screen cannot reach the status bar. For the seven that
**are** scroll-controlled and do not pass `useSafeArea: true`, the top is
unprotected and reachable:

| Sheet | Can it reach full height? | Top inset if it does |
|---|---|---|
| S9 `showMxFormSheet` × 5 | yes — keyboard + form at 320dp × 2.0 | `AppSpacing.lg` = **16dp** |
| S10 card move target | yes — `Flexible(ListView)` over an unbounded deck list | **16dp** |
| S11 card export | yes — `Flexible(SingleChildScrollView)` | **0dp** |
| S12 move deck | yes — `Flexible(MxAsyncView)` over every deck in the tree | **16dp** |
| S13 starter install | yes at 320dp × 2.0 | **16dp** |
| S14 reset progress | yes at 320dp × 2.0 (two sections + picker + pair) | **16dp** |
| S15 scheduler change | yes at 320dp × 2.0 | **16dp** |

A modern Android cutout is 24–48dp. **The project has already found this
twice** and fixed it twice, in place:

- `study_entry_screen.dart:186–192` — *"**And a safe area, because the cap is
  gone.** … Scroll-controlled it can [reach the top], and at 320dp × 2.0 it
  does — its 16dp top padding is less than a modern cutout, so the title lost
  glyphs to the status bar."*
- `trash_restore_target_sheet_widget.dart:30` — `useSafeArea: true`, no comment.

**And the audit that should have caught the rest looked only downward.** WBS
M99.58 (`MxSheetInsets`) swept every `showModalBottomSheet` in `lib/`, found the
`starter_install` bug, and concluded of four sheets: *"`SafeArea` **đã** là câu
trả lời đúng cho system bar"* — true of the bar at the bottom, and the sentence
that quietly made the top look answered too. → **A9-02 (P1)**

---

## 7. Action sheet

`MxActionSheet` is the best-behaved component in this report. It paints no
surface of its own, states that in its doc, decides nothing about which actions
exist, and its three-way ink resolution is ordered correctly — **disabled beats
destructive**, so a greyed row is never also red.

| Property | Verdict |
|---|---|
| Row height | `ListTile` + `materialTapTargetSize.padded` + `minVerticalPadding: 8` → ≥48dp. The dark golden measures 64dp row pitch. ✓ (untested — §12) |
| `enabled: false` | blocks the callback **and** sets `Semantics(enabled: false)` ✓ |
| destructive | carried by an enum, not a colour, so it can be styled *and* announced ✓ |
| `isSelected` | `ListTile(selected: true)` **plus** an explicit trailing check — the state does not live in colour alone ✓ |
| label overflow | `maxLines: 2` + ellipsis ✓ |
| icon ink | `AppInk.quiet` for normal rows so the glyph does not carry the label's weight; full ink for destructive and disabled ✓ |
| scrolling | `SingleChildScrollView` — survives the 9/16 cap at 8 rows × textScale 2.0 ✓ |

**Measured (light / dark):**

| Row state | Ground it is actually drawn on | Contrast |
|---|---|---|
| normal label `onSurface` | sheet `surfaceContainerLow` | 12.58 / 11.05 ✓ |
| destructive `danger` | sheet | 5.77 / 6.95 ✓ |
| disabled `onDisabled` (38%) composited | sheet | 2.15 / 2.65 — **exempt** (WCAG 1.4.3, inactive component) |
| selected check `AppInk.accent` = `primary` | **`selectedTileColor` = `surfaceContainerHigh`** | **5.19 / 8.43** ✓ |
| selected tile vs sheet | — | 1.19 / 1.23, ΔL\* **7.02 / 8.56** ✓ |

The selected check passes. But `mx_action_sheet.dart:180` records its
justification as *"a sheet sits on `surface`, where the old fill tone measured
2.90:1 … Tone 80 reads **10.02:1 there**"* — and a sheet does not sit on
`surface`; it sits on `surfaceContainerLow`, and a *selected* row's check sits
on `surfaceContainerHigh`. The recorded number is for a ground this widget never
draws on. → **A9-11 (P3)**

**Two API surfaces with no production caller.** `MxActionSheetAction.isEnabled:
false` appears exactly once in the repository — in `golden_hosts.dart`. So the
"disabled row stays visible so the menu does not change shape" rule is currently
a rule about a case the app does not have, and the row has no way to *say why*
it is unavailable (compare `move_deck_sheet_widget.dart`, which disables rows and
gives each a `subtitle` naming the rejection). `isSelected` has one caller
(deck sort). Neither is a defect; both are recorded in §13 so the next feature
that needs a disabled row knows the affordance is untried.

---

## 8. Scrim and barrier

### 8.1 The scrim does not cover the app's own navigation — A9-01 (P1)

`showDialog` defaults `useRootNavigator: true`; `showModalBottomSheet` defaults
it to **`false`**. This app mounts `StatefulShellRoute.indexedStack` inside an
outer `Scaffold` whose `bottomNavigationBar` is `MxNavigationBar`
(`app_navigation_shell.dart:33–37`), with each branch's `Navigator` inside that
Scaffold's `body`.

So a modal bottom sheet's route, overlay and **barrier** are confined to the
shell body's rectangle. Two goldens committed at `3207e7b7` show it:

| Golden | Bottom navigation bar |
|---|---|
| `test/demo/goldens/deck_delete_confirm_light.png` (dialog, root navigator) | **dimmed** by the barrier |
| `test/demo/goldens/deck_sort_sheet_light.png` (sheet, branch navigator) | **fully lit, undimmed, outside the modal route** |

Both were captured through the real `createAppRouter()` (`deck_audit_harness.dart`),
so this is production geometry, not a harness artefact.

Three consequences:

1. **The modality claim is false for sheets.** The scrim's whole meaning is
   "everything behind this is blocked". Four destinations behind it are not.
2. **A tab tap escapes the modal without dismissing it.** `_goBranch` passes
   `initialLocation: index == currentIndex`, so switching branches *preserves*
   each branch's stack — the sheet stays pushed on the branch the user left and
   is still there when they come back.
3. **Two modal families, two footprints, one app.** A user cannot learn one rule
   for "what a scrim means here".

**This is an owner decision, not a silent fix**, and §14 treats it as one:
`useRootNavigator: true` on sheets is the Material-correct rendering, but it
changes the sheet's `MediaQuery` (the shell `Scaffold` currently removes the
bottom padding for its body; the root navigator does not), so
`mxSheetBottomObstruction` would start returning the system-bar inset and every
sheet would grow. That moves 6 committed sheet goldens and the gallery.

### 8.2 The barrier recipe itself

`modalBarrierColor(scheme)` = `scheme.scrim` at **0.48 light / 0.72 dark**.
Derived from the token, not `Colors.black54`; deeper in dark because a 54% black
over a `#070C27` page barely registers. Both halves are pinned by
`app_overlay_themes_test.dart`, including that the two modes are not symmetric.
Correct, and the file's own note on why this is a *render audit* blind spot
(half an overlay's tree is content the user is deliberately being stopped from
reading) is the right call.

Composited:

| Mode | Scrim over page | Scrim over a card |
|---|---|---|
| light | `#83858D`, L\* 55.61 | `#898A90`, L\* 57.57 |
| dark | `#040613`, L\* 1.83 | `#070916`, L\* 2.70 |

`design-parity-checklist.md` B7 records the divergence from the design kit's flat
60% and calls it measured. Agreed — no finding.

### 8.3 The dark sheet's edge — measured, and explicitly **not** a call for a glow

The dark bottom sheet against the scrimmed page reads **1.14:1**, the lowest
number anywhere in this report. It is the wrong number to act on.

At these luminances the WCAG ratio is compressed to uselessness: the same pair
is **ΔL\* 6.58**, which is *larger* than the ΔL\* 4.31 page→card step this app's
entire dark surface ladder is built on (`app_elevation.dart`). The dark
action-sheet golden confirms it by eye: the sheet's top edge and its 16dp
corners are legible against the dimmed page.

Adding a border, a rim or a shadow to close a 1.14:1 gap would re-introduce
exactly the halo #435 removed six commits ago, in the one place where the ground
behind is a translucent barrier and therefore cannot be pre-composed against.
**Recorded as a measurement (A9-16, P3), with the explicit conclusion: do not
act on it.**

### 8.4 Barrier semantics

| | Dialog | Sheet |
|---|---|---|
| `barrierLabel` | `modalBarrierDismissLabel` | `scrimLabel` |
| `barrierOnTapHint` | — | `scrimOnTapHint(bottomSheetLabel)` → *"Double tap to close bottom sheet"* |
| dismissible | yes | yes |
| semantics clip | — | `_clipDetailsNotifier` clips the barrier's semantics rect above the sheet ✓ |

All localized through `GlobalMaterialLocalizations`, which `app.dart:74` wires
and which ships `vi`. **No l10n gap on the framework strings.**

---

## 9. Actions — ordering, hierarchy, submitting

### 9.1 Ordering is consistent, and it is consistent because one widget owns it

`MxButtonPair` puts **secondary left / primary right** in a row and **primary
top** when stacked, at one shared size in both orientations. Every modal action
row in the app goes through it: `MxConfirmDialog`, `MxFormDialog`,
`_ResetProgressSheet`, `_SchedulerSheet`, `CardExportActionBarWidget`,
`_TagFilterForm._Actions`. `deck_delete_confirm_light.png` measures the two
buttons at 298 and 300 device px — equal, which is the promise.

The row/stack decision reads the children's own intrinsics rather than a
constant (`_fitsAsRow` on `getMinIntrinsicWidth`, i.e. the **longest word**),
which is the right measurement: a wrapped label is readable, a label cut
mid-word is not. The rendered counter-example that justified keeping the
fallback — `Ca` beside `Mov…` at 320dp × 2.0 — is recorded in the source.

### 9.2 Focus placement

| Variant | Autofocus | Correct? |
|---|---|---|
| `normal` | neither action | ✓ — pre-selecting "confirm" skips the question |
| `destructive` | Cancel | ✓ |
| `cautious` | Cancel | ✓ — the split BR-266 asked for |
| `MxAlertDialog` (one action) | the single action | ✓ — the "least destructive of two" rule needs two |

`MxActionButton._takesFocus()` honours `shouldAutofocus` only outside
`FocusHighlightMode.touch`, so on the release target **no dialog action is
focused at all** and no focus ring is painted. That is deliberate and its
rendered justification is recorded (10 551 ring pixels on
`deck_delete_confirm_light.png`). With a keyboard present the mode flips and the
autofocus applies; `mx_alert_dialog_test.dart` pins both halves.

One property worth naming: `_takesFocus()` reads
`FocusManager.instance.highlightMode` at **build time** and the button does not
listen to it, so a keyboard attached while a dialog is already open does not
move the focus until something else rebuilds. Cosmetic, no data at risk, not
filed.

### 9.3 Submitting

`isSubmitting` disables both actions and puts a spinner on the primary;
`isConfirmBlocked` disables confirm only and leaves Cancel live during BR-04's
impact read. Both are correct and both are tested
(`mx_async_confirm_dialog_test.dart`, group *"both actions go inert while the
write runs"*). The gap is what that group does **not** cover — §10.3.

### 9.4 One sheet has no way out but the gesture — A9-08 (P2)

`CardExportActionBarWidget`'s own doc states the rule:

> *"**`Cancel` sits beside the primary** … a sheet has no app bar, so without it
> the only way out is the drag-down gesture — no affordance, and nothing a screen
> reader can announce."*

`starter_install_widget.dart:158` is a lone `MxActionButton` labelled *Install*.
Every other form-shaped sheet in the app pairs its primary with a secondary.
The drag handle *is* announced (`_DragHandle` carries `button: true` and the
dismiss label), so this is not an accessibility dead end — it is the one sheet
that breaks a rule the app wrote down for itself.

`_TagFilterForm._Actions` pairs *Clear* with *Apply* and has no Cancel either,
but there the barrier discards a draft that was never applied — a correct
divergence, recorded rather than filed.

---

## 10. Keyboard, focus, dismissal, accessibility

### 10.1 Keyboard and view insets

| Surface | Mechanism | Verdict |
|---|---|---|
| Dialog | `Dialog.build`: `effectivePadding = viewInsets + insetPadding`, then `removeViewInsets` for the child; `scrollable: true` on all three shapes | ✓ correct, and free |
| `showMxFormSheet` | `isScrollControlled` + `MxSheetInsets` outside the scroll view | ✓ correct |
| `card_export` | bare `mxSheetBottomObstruction`, `Flexible(SingleChildScrollView)` + a non-scrolling action row | ✓ correct, and the action row staying put is right (W6) |
| Sheets with no text field | `SafeArea` bottom only | ✓ — `viewInsets` is genuinely always 0 there |

`scrollable: true` on all three dialog shapes is load-bearing rather than
defensive: the alternative at textScale 3.0 on 320dp is **silent** truncation
mid-word with no exception and no overflow stripe, and
`mx_accessibility_test.dart` pins that the scrollable actually gains extent.

### 10.2 Focus capture, traversal, return

| | Dialog | Sheet |
|---|---|---|
| scope | `_ModalScopeState.focusScopeNode`, `setFirstFocus` on push | same |
| traversal edge | **`closedLoop`** (pinned by `showDialog`) | **`parentScope`** (Navigator default) |
| initial focus | per §9.2 | first traversable descendant |
| focus return on pop | scope disposal restores the parent scope's previous `focusedChild` | same |
| below-route participation | `focusScopeNode.skipTraversal = !isCurrent` (`routes.dart:1174`) | same |

The dialog side is airtight. On the sheet side, `parentScope` means Tab at the
last control asks the **enclosing** scope for the next node
(`focus_traversal.dart:617–621`). Because the route below carries
`skipTraversal = true` and `_getDescendantsWithoutExpandingScope` does not
recurse into sibling scopes, the practical result in the single-navigator case
is the same wrap `closedLoop` would give — **but that is a derivation, not a
guarantee, and the app has a shell with nested navigators.** Nothing in the
repository asserts either behaviour. Filed as **A9-12 (P3)** with a closure test
rather than as a defect claim, because a claim that focus escapes would need a
render to stand up.

### 10.3 Dismissal during a write — A9-03 (P1)

`showMxAsyncConfirm` (`mx_async_confirm_dialog.dart:203`) calls
`showDialog<void>` with `barrierDismissible` left at its default `true`, and
neither it nor `MxConfirmDialog` installs a `PopScope`.

While `isSubmitting` is true, both buttons are inert — and the **barrier** and
the **system back gesture** are not. Both pop the route. The controller is a
provider, so the write continues to completion; the widget is gone, so
`didUpdateWidget` never sees the crossing and `onDone` never fires.

For the two deletes that matter, `onDone` is where the batch id is handed over:

```
_DeleteDeckDialogState._finish()  →  widget.onClose(); widget.onDeleted(_batchId);
_DeleteCardDialogState._finish()  →  same shape
```

`_batchId` is what BR-263's Undo affordance acts on. So the reachable sequence
is: confirm the delete → tap the scrim while the transaction runs → **the deck
goes to Trash, no Undo is offered, and no message is shown at all.** For the
settings reset (`closeWhen: settled`) the failure mode is milder — the error
band behind the dialog still renders — but it is the same hole.

`card_export_sheet_widget.dart` is the only modal in `lib/` with a `PopScope`,
and its comment describes precisely this class of bug ("on the frame the pop
starts rather than the frame the provider happens to die"). One author found it;
the shared component did not.

The same hole in sheet form is **A9-04 (P2)**: `_StarterInstallFormState._install`
awaits the install and then `Navigator.pop(outcome)` guarded by `mounted`. Drag
the sheet away mid-install and `showStarterInstallSheet` resolves to `null`,
which its own doc defines as *"cancelled or failed — the caller draws nothing
for null, because nothing happened"*. Something did happen: a deck was
installed.

### 10.4 Route naming and announcement — A9-13 (P3)

| Surface | Announced route name | Source |
|---|---|---|
| every dialog | *"Alert"* / the `vi` equivalent | `MaterialLocalizations.alertDialogLabel`, because no call site passes `semanticLabel` |
| every sheet | *"Dialog"* | `MaterialLocalizations.dialogLabel`, hard-coded in `_ModalBottomSheetState.build:790` |

The dialog side is fixable in one place — `AlertDialog.semanticLabel` exists
precisely so a destructive confirmation can name itself instead of announcing a
category. The sheet side is **not** fixable through the framework's public API:
`showModalBottomSheet` takes no `semanticLabel`, and the route's own
`Semantics(namesRoute: true)` already occupies the slot.

Related and cheaper: **exactly one of 17 sheets marks its own title as a
header.** `card_export_sheet_widget.dart:307` wraps its title in
`Semantics(header: true)`; the other sixteen do not, so a screen-reader user
cannot jump to a sheet's heading. See A9-05.

### 10.5 Live regions

`MxConfirmDialog` marks `content` a live region and deliberately does not mark
the title; `MxFormDialog._FormError` marks the form-level failure;
`MxAlertDialog` marks **nothing**, because `AlertDialog` already reads its
content on open and a live region would read it twice. All three decisions are
right, all three are tested, and the three-way divergence in *what* each caller
puts in `message` (D26) is recorded in the parity checklist rather than being an
accident.

---

## 11. Raw modal drift and API escape hatches

### 11.1 Dialogs: closed

| Escape hatch | Occurrences in `lib/features/` |
|---|---|
| `showDialog` | **0** |
| `showGeneralDialog` | **0** |
| raw `AlertDialog(` | **0** |
| raw `Dialog(` / `Dialog.fullscreen` | **0** |
| `SimpleDialog` | **0** |
| `CupertinoAlertDialog` / `CupertinoActionSheet` | **0** |

All four `showDialog` calls live in `lib/shared/widgets/`. No feature builds a
dialog by hand. This is the cleanest boundary in the report.

### 11.2 Sheets: open, and 16 call sites wide

| Escape hatch | Occurrences |
|---|---|
| `showModalBottomSheet` in `lib/features/` | **16** |
| `showModalBottomSheet` behind a shared function | **1** (`showMxFormSheet`, 5 callers) |
| `showBottomSheet` (non-modal) | 0 |
| raw `BottomSheet(` | 0 |
| `DraggableScrollableSheet` | 0 |

Every one of those 16 restates the route configuration. The evidence that this
costs something is that **five different knobs are set inconsistently across
them** — `isScrollControlled` (9 yes / 8 no), `useSafeArea` (2 yes / 15 no),
`isDismissible` (never overridden), `enableDrag` (never overridden), and the
content inset (four spellings, §11.3).

**There is no guard.** `check_architecture.sh` has no rule about modal
construction, and `code-verification-guard.yaml` has none either — grep for
`dialog`, `bottomsheet`, `showModal` in both returns nothing. The only thing
watching this surface is `theme_coverage_test.dart`, which asks whether the
*slot* is filled, not whether the *route* is configured.

### 11.3 The sheet content inset, in four spellings

Every sheet already starts **48dp** down, because `_BottomSheetState.build`
pads `widget.builder(context)` by `kMinInteractiveDimension` when a handle is
shown. On top of that:

| Spelling | Top gutter | Total | Used by |
|---|---|---|---|
| `MxSheetInsets` | `lg` = 16 | **64** | S9 (× 5), S13 |
| `SafeArea` + `EdgeInsets.all(lg)` | 16 | **64** | S10, S12, S14, S15, S16 |
| `MxActionSheet` (`SafeArea` + `symmetric(vertical: sm)`) | 8 | **56** | S1–S6 |
| bare `mxSheetBottomObstruction`, no top | 0 | **48** | S11 |

`MxSheetInsets`' own doc explains the fourth ("the export sheet has no top
gutter because its drag handle already provides one") — and the handle provides
that gutter to *all four*, which is what makes 0/8/16 three answers to a
question that was asked once. → **A9-06 (P2)**

### 11.4 Sheet header grammar, in five treatments

| Style | Colour | `Semantics(header:)` | Sheets |
|---|---|---|---|
| `titleSmall` | `onSurfaceVariant` | no | `MxActionSheet` (S1–S6) |
| `titleMedium` | inherited | no | S10, S12, S16, tag filter |
| `titleMedium` | inherited | **yes** | S11 card export |
| `titleLarge` | inherited | no | S13, S14, S15 |
| (dialog, for contrast) `titleMedium` + `onSurface` via `dialogTheme` | — | (route-level) | D1–D4 |

`MxDialogHeader` exists so the three dialogs cannot drift into three header
layouts. **There is no `MxSheetHeader`**, and the seventeen sheets have drifted
into five. → **A9-05 (P2)**

### 11.5 Two documented facts that contradict their own code

- **`app_bottom_sheet_theme.dart:24–30`** argues at length for `borderControl`
  over `onSurfaceVariant` for the drag handle ("`borderControl` reads as an
  affordance at 3.19 and 3.00 without competing"). Twenty lines later the same
  comment says the role *is* `onSurfaceVariant` in every state, and the code
  returns `scheme.onSurfaceVariant`. The **later** paragraph and the code are
  right — `onSurfaceVariant` is `_BottomSheetDefaultsM3`'s own role, and M100.23
  correctly identified the alternative as a slot moving off its canonical role.
  The earlier paragraph is a stale argument for a decision that was reversed,
  sitting in the same doc comment. → **A9-09 (P3)**
- **`app_dialog_theme.dart:26–28`** — *"Zero, and the shadow is **hand-painted
  instead**"*. Nothing hand-paints a dialog shadow: `MxConfirmDialog`,
  `MxFormDialog` and `MxAlertDialog` all build a plain `AlertDialog` with no
  `boxShadow` anywhere. The true statement is the one this audit read from the
  SDK: `_DialogDefaultsM3.shadowColor` is `Colors.transparent`, so **M3's own
  dialog paints no shadow either** and `elevation: 0` renders identically. This
  is also the correct rebuttal to the parity checklist's F15, which is still
  open on the premise that light "should" carry `--shadow-overlay`; the measured
  separation without one is 3.08:1 / ΔL\* 37.4 plus a hairline. → **A9-10 (P3)**

### 11.6 One stale parity row

`design-parity-checklist.md` C13 records `MxConfirmDialog` as
*"`shouldAutofocus: _isDestructive`"*. The code is `_shouldFocusCancel`, which is
`destructive || cautious` — the BR-266 split. Since every soft delete in the app
is `cautious`, the checklist under-describes the focus rule at exactly the nine
dialogs that use it. Documentation only. → folded into A9-15.

---

## 12. Coverage gaps — tests, Widgetbook, Linux goldens

### 12.1 The headline gap

**No test in the repository opens a modal through `showDialog` or
`showModalBottomSheet` at a phone surface with a raised text scale.**

- `mx_responsive_test.dart` pumps `MxConfirmDialog` inside `Center(...)` and
  `MxActionSheet` inside `Align(bottomCenter, ...)` — the widgets, never the
  routes. It therefore cannot see `IntrinsicWidth`, `insetPadding + viewInsets`,
  the 9/16 cap, `removePadding(removeTop: true)`, or the barrier.
- `mx_accessibility_test.dart` pumps a bare `MxConfirmDialog` at 320 × 568 ×
  3.0 — the best modal stress case in the suite, and still not a route.
- `mx_stress_test.dart` pumps specimens at 320 × 640 × 2.0 — widgets.
- The four tests that *do* use the real entry points (`mx_confirm_dialog_test`,
  `mx_alert_dialog_test`, `mx_form_dialog_test`, `mx_form_sheet_test`) run at
  the default 800 × 600 test surface with no text scale.

All three P1s live in exactly that intersection. That is not a coincidence — it
is the shape of the blind spot.

### 12.2 Surfaces and scales actually exercised

| Requested by the brief | In the suite |
|---|---|
| 320 | ✓ (320 × 568 ×49, 320 × 640 ×20) |
| 360 | ✓ (360 × 640 ×27 — the component-golden surface) |
| 375 | ✗ — bracketed by 360 and 390, not a defect |
| 393 | ✓ (393 × 852 ×30 — the demo-golden surface) |
| textScale 1 | ✓ | 
| textScale 1.3 | ✗ — the suite uses 1.5 (×7), 2 (×88), 3 (×2) |
| textScale 2 | ✓ |
| EN | ✓ |
| VI | partial — 3 demo goldens (`deck_delete_confirm_vi`, `card_export_sheet_vi_light`) + `mx_stress_specimens` |

### 12.3 Golden coverage, by taxonomy row

| Surface | Goldens at `3207e7b7` |
|---|---|
| `MxConfirmDialog` normal / destructive | light + dark ✓ |
| `MxConfirmDialog` **cautious** | **none** — and it is the variant nine production dialogs use |
| `MxConfirmDialog` **with a tone** (4 tones) | none as a component; two demo goldens happen to carry `warning` |
| `MxFormDialog` / prompt | **none** |
| `MxAlertDialog` | **none** (Widgetbook + stress specimen only) |
| `MxActionSheet` | light + dark ✓ (real route, disabled + destructive rows) |
| `MxActionSheet` **selected row** | only via `deck_sort_sheet_light` (light only) |
| Feature modals with a golden | deck delete (l/d/vi), card bulk delete (l), card import confirm (l), tag delete (l), deck sort sheet (l), card export sheet (l/d/vi), tag filter sheet (l/d) |
| Feature modals with **no** golden | deck actions, library menu, deck ancestors, deck create child, **reset progress**, **scheduler change**, **starter install**, **move deck**, card move target, trash restore target, trash row menu, study resume / mode / direction |

Fourteen feature modal surfaces have no picture at all. Six of the seven sheets
carrying A9-02 are among them, which is why the top-edge failure has survived two
discoveries.

### 12.4 Widgetbook

`overlay_components.dart` catalogues `MxConfirmDialog` (+ a toned use case),
`MxActionSheet`, `MxFormDialog`, `MxAlertDialog` — four of four dialog shapes,
one of the sheet shapes. Not catalogued: `MxAsyncConfirmDialog` (stateful, takes
a `SubmitState` — a fair omission), `MxSheetInsets`, `MxFormSheet`.

The file's header states the real constraint honestly: *"Both overlay components
render inline rather than through `showDialog` / `showModalBottomSheet`: a
popped route builds outside the use-case subtree, where the theme and viewport
addons cannot reach it."* True, and it means **Widgetbook can never cover the
route-level behaviour either.** The gap in §12.1 has to be closed by tests, not
by the catalog.

### 12.5 One specimen photographed on the wrong ground

`golden_surfaces.dart`'s `OnSheetSurface` stands in for a sheet with
`Material(color: Theme.of(context).colorScheme.surface)`. A sheet's background
is `surfaceContainerLow`. So `MxListTile`'s goldens — whose one production
caller is the move-deck **sheet** — are photographed on the page, one rung below
the surface the row actually appears on (light: ΔL\* 3.9; dark: ΔL\* 4.3). Same
class of error as A9-11, from the other end. → folded into A9-15.

---

## 13. Severity registry

P0/P1/P2 carry **evidence** (a file:line, a measurement, or a committed golden)
and a **closure test** — the assertion that would have gone red.

| ID | Sev | Finding | Evidence | Closure test |
|---|---|---|---|---|
| **A9-01** | **P1** | A modal sheet's scrim stops above the bottom navigation bar; the bar stays lit and tappable, and a tab tap leaves the sheet pushed on the branch the user left. Dialogs (root navigator) do cover it. | `bottom_sheet.dart:1301` `useRootNavigator = false` vs `dialog.dart:1629` `= true`; `app_navigation_shell.dart:33`; goldens `deck_sort_sheet_light.png` (bar lit) vs `deck_delete_confirm_light.png` (bar dimmed), both captured through `createAppRouter()` | Route test: open a sheet from a branch screen, assert the `ModalBarrier`'s global rect covers the full `tester.view` height — currently it stops at the shell body's bottom. |
| **A9-02** | **P1** | Seven scroll-controlled sheets have 0–16dp between their first line and the status bar; `useSafeArea: false` makes their inner `SafeArea(top:)` a no-op. | `bottom_sheet.dart:1163` `MediaQuery.removePadding(removeTop: true)`; `mx_form_sheet.dart:40–43`; the two existing spot fixes at `study_entry_screen.dart:192` and `trash_restore_target_sheet_widget.dart:30`; WBS M99.58's bottom-only conclusion | Route test at 320 × 568, `viewPadding.top: 48`, textScale 2.0: open each scroll-controlled sheet and assert its topmost `Text`'s `globalTopLeft.dy >= 48`. |
| **A9-03** | **P1** | `MxAsyncConfirmDialog` disables both buttons while the write runs but leaves the barrier and the back gesture live; dismissing mid-write skips `onDone`, so the deck/card delete commits with no Undo (BR-263) and no message. | `mx_async_confirm_dialog.dart:203` (`showDialog`, `barrierDismissible` defaulted, no `PopScope`); `deck_confirm_widget.dart:130`; `card_confirm_widget.dart` `_finish`; the covering test group stops at the two buttons | Route test: submit, tap the barrier while `isSubmitting`, drive the state to `savedAndClose`, assert `onDone` fired exactly once (or that the barrier did not pop). |
| **A9-04** | **P2** | `showStarterInstallSheet` resolves to `null` when the sheet is dragged away mid-install, while the install commits; the caller's contract defines `null` as "nothing happened". | `starter_install_widget.dart:102–115`; contrast with the only `PopScope` in `lib/`, `card_export_sheet_widget.dart:205` | Widget test: start the install, pop the sheet before it settles, assert the caller is told an install happened (or that the install is cancelled). |
| **A9-05** | **P2** | Five sheet-header treatments across 17 sheets; exactly one marks itself `Semantics(header: true)`. No `MxSheetHeader` counterpart to `MxDialogHeader`. | §11.4 table; `card_export_sheet_widget.dart:306` is the only `header: true` in any `overlays/` file | Semantics test: every sheet's title node has `isHeader: true`; a source scan that every sheet title comes from one shared widget. |
| **A9-06** | **P2** | Sheet content inset written four ways → top gutters of 0 / 8 / 16 on top of the handle's mandatory 48. | `_BottomSheetState.build:147` (`Padding(top: kMinInteractiveDimension)`); §11.3 table | Layout test: for each sheet, the distance from the sheet's own top to its first line is one value. |
| **A9-07** | **P2** | `MxAlertDialog` does not state `MxDialogMetrics.insetPadding` / `actionsPadding`; the third dialog is geometrically not the other two, and no golden covers it. | `mx_alert_dialog.dart:55–58` vs `mx_confirm_dialog.dart:119–120` and `mx_form_dialog.dart:87–88`; `MxDialogMetrics`' own doc names three dialogs | Widget test: all three dialogs report the same `insetPadding` and `actionsPadding`. |
| **A9-08** | **P2** | `starter_install` is the only form-shaped sheet with no secondary action, against the rule `CardExportActionBarWidget`'s doc states. | `starter_install_widget.dart:158`; `card_export_action_bar_widget.dart:10–12` | Widget test: the sheet offers a labelled way out that is not the drag handle. |
| A9-09 | P3 | `app_bottom_sheet_theme.dart`'s drag-handle comment argues for `borderControl` and the code returns `onSurfaceVariant`; the stale half was reversed by M100.23. | `app_bottom_sheet_theme.dart:24–30` vs `:64` | — |
| A9-10 | P3 | `app_dialog_theme.dart` says the dialog shadow is "hand-painted instead"; nothing paints one. The true reason `elevation: 0` is correct is that `_DialogDefaultsM3.shadowColor` is transparent. Also settles parity F15's premise. | `app_dialog_theme.dart:26–28`; `dialog.dart:1982`; measured 3.08:1 / ΔL\* 37.4 light | — |
| A9-11 | P3 | `MxActionSheet`'s selected-check contrast note names `surface`; the check is drawn on `selectedTileColor` = `surfaceContainerHigh`, inside a sheet on `surfaceContainerLow`. Real numbers 5.19 / 8.43 — passes. | `mx_action_sheet.dart:178–182`; `app_list_tile_theme.dart:36` | — |
| A9-12 | P3 | Sheet routes leave `traversalEdgeBehavior` at `parentScope` while `showDialog` pins `closedLoop`. Nothing asserts either. | `dialog.dart:1666` vs `navigator.dart:1255`; `routes.dart:1119–1134` | Focus test: Tab past the last control in a sheet, assert focus is still inside the sheet's scope. |
| A9-13 | P3 | Every dialog announces "Alert" and every sheet "Dialog"; no modal passes `semanticLabel`. Fixable for dialogs, framework-limited for sheets. | `dialog.dart:773–780`; `bottom_sheet.dart:787–790` | — |
| A9-14 | P3 | `MxFormDialog.isSubmitting`, `MxActionSheetAction.isEnabled` and `MxAlertDialog` have no production caller; a disabled action-sheet row also has no way to say *why*. | grep: `isEnabled: false` appears only in `golden_hosts.dart` | — |
| A9-15 | P3 | Documentation and specimen drift: parity C13 records `_isDestructive` (code: `_shouldFocusCancel`); `OnSheetSurface` stands in for a sheet with `colorScheme.surface`. | `design-parity-checklist.md:138`; `golden_surfaces.dart:33` | — |
| A9-16 | P3 | **Measurement, with the conclusion "do not act".** The dark sheet reads 1.14:1 against the scrimmed page — the lowest number in this report — but ΔL\* 6.58, larger than the ladder's own 4.31 page→card step. Closing it with a border, rim or shadow would re-introduce #435's halo on the one surface whose ground cannot be pre-composed. | §8.3; `mx_action_sheet_dark.png` | — |

**Distribution: 0 × P0 · 3 × P1 · 5 × P2 · 8 × P3.**

---

## 14. Implementation order, files, and the two owner decisions

Ordered so that each step is independently shippable and none of them
invalidates the next. Steps 1–3 move no pixel; steps 4–6 do.

### Step 1 — close the mid-write exits (A9-03, A9-04)

No visual change, no golden, and it is the only finding on this list that can
lose user data's recoverability.

- `lib/shared/widgets/mx_async_confirm_dialog.dart` — pass
  `barrierDismissible: !isSubmitting` is **not** available (the flag is fixed at
  route construction), so the shape is a `PopScope` inside `MxConfirmDialog`
  driven by `isSubmitting`, matching `card_export_sheet_widget.dart`'s precedent.
  Decide between blocking the exit and making the exit deliver `onDone`; the
  export sheet chose the latter and its reasoning transfers.
- `lib/features/deck/presentation/widgets/overlays/starter_install_widget.dart`
  — same treatment for the sheet.
- Tests: extend `test/shared/mx_async_confirm_dialog_test.dart`'s existing group,
  which already has the right name.

### Step 2 — one sheet header, one sheet inset (A9-05, A9-06)

- New `lib/shared/widgets/mx_sheet_header_widget.dart` — the `MxDialogHeader`
  counterpart: one type ramp, one colour, `Semantics(header: true)`.
- Fold the four inset spellings into `MxSheetInsets` with the handle's 48dp
  accounted for once. `MxSheetInsets`' doc already argues that a second layout
  is a second widget rather than a boolean — that argument decides the shape
  here too.
- Files: `mx_action_sheet.dart`, `mx_sheet_insets.dart`, and the seven feature
  sheets in §11.3/§11.4.
- **This moves goldens** — `deck_sort_sheet_light`, `card_export_sheet_*`,
  `tag_filter_sheet_*`, `mx_action_sheet_*`. Regenerate on **Linux**
  (`TZ=UTC flutter test --tags golden --update-goldens`), rebuild the gallery,
  republish to the existing artifact URL.

### Step 3 — correct the three documented facts (A9-09, A9-10, A9-11, A9-15)

Comment-only, plus one parity-checklist row. Worth doing before step 4, because
two of the three are load-bearing arguments a later reader would act on: A9-10
is the premise F15 is still open on, and A9-09 says the opposite of the code in
the file a sheet re-theme would start from.

- `app_bottom_sheet_theme.dart`, `app_dialog_theme.dart`, `mx_action_sheet.dart`,
  `docs/reviews/design-parity-checklist.md` (C13, F15).

### Step 4 — `useSafeArea: true` for the seven (A9-02) — **owner decision #1**

The mechanical change is one flag at seven call sites, and two call sites
already carry it. What needs the owner is whether it goes on the flag or on the
shared function:

| Option | Cost |
|---|---|
| (a) `useSafeArea: true` at the seven call sites | smallest diff; the eighth author still has to remember |
| (b) `useSafeArea: true` inside `showMxFormSheet`, flag at the other six | closes five of seven structurally |
| (c) a shared `showMxSheet(...)` that all 17 go through | closes it for good; touches every sheet and every sheet golden |

**Recommendation: (b) now, (c) when a guard rule lands** (see step 6). Option (c)
alone is a large diff with no test to prove it worked; (b) is the half that pays
immediately.

Goldens affected: only the sheets that actually reach full height under the
golden's own 393 × 852 × 1.0 conditions — likely none, which is exactly why this
survived. The closure test in §13 is what makes the change provable.

### Step 5 — the scrim and the navigation bar (A9-01) — **owner decision #2**

The largest visual change in this report and the one that must not be made
silently.

| Option | Consequence |
|---|---|
| (a) `useRootNavigator: true` on all 17 sheets | Material-correct: the sheet and its scrim cover the nav bar. **But** the root navigator does not carry the shell `Scaffold`'s removed bottom padding, so `mxSheetBottomObstruction` starts returning the system-bar inset and every sheet grows by 24–48dp. Moves all 6 sheet goldens. |
| (b) leave sheets on the branch navigator and accept the asymmetry | Zero diff, and the scrim keeps meaning two different things. |
| (c) root navigator for sheets that are *decisions* (S9–S17), branch for menus (S1–S8) | Splits the rule by taxonomy row rather than by accident — defensible, and the hardest to explain. |

**Recommendation: (a).** The asymmetry is not a design position anyone took; it
is `useRootNavigator`'s default arriving unexamined at 17 call sites, and the
two goldens make the result legible. But it is the owner's call, it should be
made against a rendered before/after, and it should not be bundled with any
other change in the same PR.

### Step 6 — make the surface guardable (A9-07, A9-08, A9-12, coverage)

- `mx_alert_dialog.dart` — state the two metrics (A9-07).
- `starter_install_widget.dart` — pair the primary (A9-08).
- New route-level test file, e.g. `test/shared/widgets/mx_modal_route_test.dart`,
  covering §12.1's gap: every `showMxX` and every feature `showX` opened as a
  **route**, at 320 × 568 with `viewPadding.top` set and textScale 2.0,
  asserting top inset, barrier rect, focus containment (A9-12) and mid-write
  dismissal.
- Goldens for the seven surfaces in §12.3 that carry a P1/P2: reset progress,
  scheduler change, starter install, move deck, card move target, deck actions,
  `MxConfirmDialog` **cautious**.
- A `check_architecture.sh` rule once (c) in step 4 lands: no
  `showModalBottomSheet` outside `lib/shared/widgets/`, mirroring the boundary
  dialogs already have de facto.

### What this report deliberately does not propose

- **No edge, rim, border or shadow on the dark bottom sheet.** A9-16 explains
  why the number that would motivate it is the wrong number.
- **No change to `modalBarrierColor`.** Measured, tested, and recorded as a
  deliberate divergence from the design kit (parity B7).
- **No `MxAlertDialog` removal.** Zero callers is recorded and intentional
  (WBS M99.59); it completes the taxonomy and it is what a first real caller
  will start from.
- **No re-theming of `showTimePicker`.** `buildTimePickerTheme` already restates
  `dialogTheme`'s answers in the slots that component reads, which is the right
  shape for a picker host whose dialog does not inherit `dialogTheme`.
