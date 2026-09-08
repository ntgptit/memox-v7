# A17 · Interaction state and motion system deep audit

| | |
|---|---|
| **Status** | active |
| **Purpose** | Establish the interaction-state taxonomy the app actually implements, reconcile it against Flutter 3.44.8's own resolution order, and record every place the two disagree — so a later implementation pass has a decided list rather than a search |
| **Scope** | `AppInteractionStates` · `AppStateOpacity` · `AppDurations` · `AppMotionPolicy` · `AppInk` · every `WidgetStateProperty` in `lib/core/theme/` · every `InkWell`/`InkResponse`/`MxPressable` in `lib/` · every focus mechanism in `lib/shared/widgets/` · every `Animated*`/`Tween*`/`AnimationController` in `lib/`. **Out of scope:** colour role values (AD-14 owns those), typography, layout, anything under `docs/` other than this file |
| **Source of truth for** | Nothing. This is a discovery report; every finding must land in `docs/wbs.md` and the owning component doc before it becomes a rule |
| **Depends on** | `document-conventions.md` · `architecture.md` (AD-13, AD-14, AD-15, AD-23) · `reviews/mx-chip-pill-deep-audit.md` · `reviews/mx-action-button-deep-audit.md` · `reviews/mx-text-field-deep-audit.md` |
| **Updated by task** | — (audit only, no implementation) |
| **Last updated** | 2026-09-03 |

---

## 0. Provenance

| | |
|---|---|
| **BASE_SHA** | `3207e7b7e0d3a2ecefa5e6a85fed48a65890ba6b` |
| Base subject | `refactor(theme): the dark card stops glowing, and elevation stops meaning two things (M100.35) (#435)` |
| Base date | 2026-09-03 15:44:39 +0900 |
| Branch | `claude/a17-interaction-motion-audit-ltwu5m` (the session's designated branch; the prompt's `audit/a17-interaction-motion` is recorded here as the intended name) |
| Flutter | 3.44.8, the version pinned in `.fvmrc` |
| Method | **Static.** No Flutter SDK is installed in this container (`flutter: command not found`), so nothing was rendered and nothing was measured. Every SDK claim below is quoted from the 3.44.8 tag fetched from `raw.githubusercontent.com/flutter/flutter/3.44.8/packages/flutter/lib/src/…`, with file and line. Every composite-alpha figure is **arithmetic on the declared constants**, labelled *computed*, never *measured* |
| SDK files read | `material/ink_well.dart`, `material/chip.dart`, `material/choice_chip.dart`, `material/list_tile.dart`, `material/button_style_button.dart`, `material/theme_data.dart`, `material/ink_highlight.dart`, `material/ink_ripple.dart`, `material/ink_sparkle.dart`, `material/input_decorator.dart`, `material/floating_action_button.dart`, `material/material_button.dart` (`RawMaterialButton`), `material/navigation_bar.dart`, `material/material.dart`, `widgets/focus_manager.dart`, `widgets/implicit_animations.dart`, `widgets/tween_animation_builder.dart`, `widgets/media_query.dart`, `animation/animation_controller.dart` |
| Not verified | Any rendered pixel, any device behaviour, any golden. Every P0–P2 below therefore carries a **closure test** that is the thing which would verify it |

**Nothing in this branch is a change.** The only file it adds is this one. No production file, test, story or golden was touched.

---

## 1. Executive verdict

**The state *vocabulary* is sound and the state *plumbing* is not finished.**
`AppStateOpacity` and `AppInteractionStates` are a real single definition — four
control shapes, one focus ring, one press weight — and where a component routes
through them the result is correct and ordered correctly. Three things are open:

1. **Focus-visible is not a state this app models.** Material distinguishes
   *having* focus from *showing* focus, and says so in a source comment
   (`ink_well.dart:1159-1162`). This app collapses the two everywhere except
   `MxCard`, which was fixed for exactly this at M99.83 and is the only place the
   fix landed. Eight further focus painters — a row, a pill, a breadcrumb step,
   and every theme slot resolved off `WidgetState.focused` — still draw on plain
   focus. One control, `_MxBreadcrumbFold`, draws **nothing at all**.

2. **The transient states are not painted once each.** Every `InkWell` in
   Flutter paints press twice by construction (a rect highlight *and* a splash)
   and that is the framework's uniform baseline. The chip adds a third layer,
   because this app composites hover/focus/press into `ChipThemeData.color` and
   `RawChip` zeroes only `hoverColor` for that case (`chip.dart:1427`). Computed
   from the declared constants, a focused pill paints **19 %** where the token
   says 10, and a pressed pill **31.9 %** at the ripple centre where the token
   says 12.

3. **The motion vocabulary is clean and completely untested.** Three durations,
   two curves, no stray `Curves.` anywhere in `lib/`, every one of the five
   implicit animations routed through `AppMotionPolicy`. There is not a single
   test for any of it, no guard forbids the next raw `Duration(milliseconds:
   250)`, and `app_motion_policy.dart`'s own rationale is factually wrong about
   what the framework already does.

Two things audited came back **clean and are worth recording as such**: there is
no press-scale or shrink effect anywhere in `lib/`, and no hover state gates a
behaviour a touch device cannot reach.

---

## 2. State taxonomy

The brief fixes the split, and the codebase agrees with it. Restated with what
each state is carried by *here*:

### 2.1 Persistent

A persistent state is a fact about the control that survives the pointer
leaving. It is stored, passed in, or derived from data.

| State | Carried by | Where it is decided |
|---|---|---|
| `selected` | `WidgetState.selected` on chip / segment / switch / checkbox / radio / nav destination; `ListTile.selected`; `MxCard.isSelected` (tri-state) | The caller. Never inferred from interaction |
| `checked` | `WidgetState.selected` — Material has no separate `checked`; a `Checkbox`'s tick is `selected` | `MxCheckboxRow`, `MxSwitchRow`, `MxRadioRows` |
| `error` | **Not a `WidgetState` in this app.** `grep -rn "WidgetState.error" lib/ test/` returns nothing. Error exists only as `InputDecoration.errorText != null`, which `InputDecorator` turns into `WidgetState.error` internally (`input_decorator.dart:2254`) and resolves through a five-border ladder rather than a resolver | `MxTextField.errorText` |
| `disabled` | `WidgetState.disabled`, set by `ButtonStyleButton` (`button_style_button.dart:336`), by `InkResponse` (`ink_well.dart:924`) and by `RawChip` (`chip.dart:1221`) from the absence of a callback | `onPressed: null` / `isEnabled: false` |

### 2.2 Transient

A transient state is a fact about the *interaction*, held only while it lasts.

| State | Carried by | Visibility rule |
|---|---|---|
| `hover` | `WidgetState.hovered`, from `InkResponse`'s own `MouseRegion` (`ink_well.dart:1316-1331`) | Pointer only. Cannot occur on a phone |
| `press` | `WidgetState.pressed`, set in `_startNewSplash` **before** the splash is created (`ink_well.dart:1205`) | Always |
| **`focus-visible`** | **Nothing.** `WidgetState.focused` is *focus*, not focus-visible — see §3.2. The distinction is available only as `FocusManager.instance.highlightMode` | Should be `FocusHighlightMode.traditional` only |

**The missing third row is the report's largest single finding.** The app has a
two-value focus model where the platform has three: *no focus*, *focus*, *focus
being shown*. Nine of eleven focus painters read the middle value and behave as
if it were the third.

---

## 3. Precedence evidence — read from Flutter 3.44.8

### 3.1 The app's own resolver order is correct, and it matters in exactly one place

`app_interaction_states.dart:197-214`:

```dart
WidgetStateProperty.resolveWith((states) {
  if (states.contains(WidgetState.pressed)) { … pressedAlpha }
  if (states.contains(WidgetState.focused)) { … AppStateOpacity.focus }
  if (states.contains(WidgetState.hovered)) { … hoverAlpha }
  return null;
});
```

The file's comment says the order is load-bearing "because a control being
pressed is also hovered". **That is true of the splash and not of the
highlights**, and the difference is worth writing down because it decides where
a future resolver may be sloppy and where it may not.

`ink_well.dart:1341-1352` resolves each highlight against a *synthetic* state
set containing exactly one highlightable state:

```dart
const highlightableStates = <WidgetState>{
  WidgetState.focused, WidgetState.hovered, WidgetState.pressed,
};
final Set<WidgetState> nonHighlightableStates =
    statesController.value.difference(highlightableStates);
final pressed = <WidgetState>{...nonHighlightableStates, WidgetState.pressed};
final focused = <WidgetState>{...nonHighlightableStates, WidgetState.focused};
final hovered = <WidgetState>{...nonHighlightableStates, WidgetState.hovered};
```

So the hover highlight is resolved with `{hovered}` — plus `selected`/`disabled`
if present — and never with `{hovered, focused}`. Precedence *between the three
transient layers* is therefore paint order, not resolver order.

The splash is the exception. Both `_createSplash` (`ink_well.dart:1090-1093`) and
the per-build refresh (`ink_well.dart:1374-1377`) resolve against the **full**
`statesController.value`:

```dart
final Color color = widget.overlayColor?.resolve(statesController.value) ??
    widget.splashColor ?? Theme.of(context).splashColor;
```

and `_startNewSplash` sets `pressed` before that call (`ink_well.dart:1205`, with
the SDK's own trailing comment `// … before creating the splash`). A control
that is focused and then pressed resolves `{focused, pressed}` here. Reading
hover or focus first would give the splash the lighter wash. **The app's order is
right, and the reason recorded in the file is right for the splash and
over-general for the highlights.**

### 3.2 `WidgetState.focused` is focus, not focus-visible — the SDK says so

`ink_well.dart:1157-1165`:

```dart
void handleFocusUpdate(bool hasFocus) {
  _hasFocus = hasFocus;
  // Set here rather than updateHighlight because this widget's
  // (WidgetState) states include WidgetState.focused if
  // the InkWell _has_ the focus, rather than if it's showing
  // the focus per FocusManager.instance.highlightMode.
  statesController.update(WidgetState.focused, hasFocus);
  updateFocusHighlights();
  widget.onFocusChange?.call(hasFocus);
}
```

and `ink_well.dart:1305-1310`:

```dart
void updateFocusHighlights() {
  final bool showFocus = switch (FocusManager.instance.highlightMode) {
    FocusHighlightMode.touch => false,
    FocusHighlightMode.traditional => _shouldShowFocus,
  };
  updateHighlight(_HighlightType.focus, value: showFocus);
}
```

**Two channels, two rules.** The *state layer* is gated on highlight mode. The
*state set* is not. Therefore:

- anything resolved from `overlayColor` under `{focused}` is focus-visible;
- anything resolved from `side`, `backgroundColor`, `labelStyle`, `iconColor` or
  a `ChipThemeData.color` under `{focused}` is **plain focus**.

That splits several of this app's components down the middle. `MxIconButton`'s
wash (`app_icon_button_theme.dart:31`) is focus-visible; its **ring**
(`app_icon_button_theme.dart:35-38`, resolved off `WidgetState.focused` in
`side`) is not. One control, two visibility rules.

`FocusHighlightMode` transitions (`focus_manager.dart:2325-2355`, `2357-2377`):
`automatic` strategy, `touch` after a touch interaction, `traditional` after a
key or mouse event, and the initial value from `defaultTargetPlatform` — Android
with no mouse starts at `touch`. Note `defaultTargetPlatform`, **not**
`Theme.of(context).platform`: `app_theme.dart:171` pins `TargetPlatform.android`
for Material's benefit and it does not reach `FocusManager`.

### 3.3 Disabled precedence

`disabled` is decided before every interaction state in every resolver this app
writes — `app_button_themes.dart:180`, `:205`, `:250`, `app_chip_theme.dart:82`,
`:113`, `app_toggle_themes.dart`, `app_icon_button_theme.dart` (by construction:
`ButtonStyleButton` refuses focus while disabled, so the `focused` branch is
unreachable, and the file at `app_button_themes.dart:224-226` states that
explicitly rather than relying on it).

Flutter reinforces it structurally rather than by order: with no callback,
`InkResponse.enabled` is false (`ink_well.dart:1310-1313`), `handleMouseEnter`
short-circuits (`ink_well.dart:1315-1320`), `_canRequestFocus` is false
(`ink_well.dart:1333-1336`), and any highlight that does exist is created at
`resolvedOverlayColor.withAlpha(0)` (`ink_well.dart:1046`).

**One component inverts it, and it is Material's, not the app's** —
`input_decorator.dart:2362-2369`:

```dart
if (!decoration.enabled) {
  border = _hasError ? decoration.errorBorder : decoration.disabledBorder;
} else if (isFocused) {
  border = _hasError ? decoration.focusedErrorBorder : decoration.focusedBorder;
} else {
  border = _hasError ? decoration.errorBorder : decoration.enabledBorder;
}
```

`error` beats `disabled`. `app_input_theme.dart:39-51` declares all five borders,
so a `MxTextField(isEnabled: false, errorText: …)` — both are public parameters,
`mx_text_field.dart:84-85` — draws a `scheme.error` border at `AppStroke.input`
around a field whose content is `onDisabled`. See §11 P2-3.

### 3.4 Selected precedence

`selected` is decided before every interaction state, and `m3_combined_state_test
.dart` pins it for chip `side`, switch `trackOutlineColor`, segmented button
`side`, checkbox `side` and nav-bar icon/label under `{selected, focused}`. That
test exists because reading focus first was a real bug (M100.23) in four slots at
once. The contract it encodes is the right one and is quoted here so the rest of
this report is read against it: *a slot's colour answers what the component is;
an interaction state answers what is happening to it.*

**What it does not cover:** `{selected, hovered}` and `{selected, pressed}` on
any slot, and no combination at all involving `disabled` + a transient state. See
§10.

---

## 4. Interaction helper audit

### 4.1 `AppStateOpacity` — `lib/core/theme/states/app_interaction_states.dart:19-89`

Thirteen constants, each with the CSS selector it was transcribed from. Four
hover weights by control area (card .04 < control .06 < row .07 < icon .08),
press .12 with a card exception at .10, focus .10, four blend constants for the
two controls that have no ground to wash (filled button, text link), and two
disabled constants.

**Verdict: conforming.** The one thing worth stating is that this is a *token*
file with no opinion about how many times a token is painted, which is the gap
§5 is about.

### 4.2 `AppInteractionStates` — same file, `:100-215`

Four `WidgetStateProperty<Color?>` shapes plus two `BorderSide` factories.
Consumers: 13 files under `lib/`, 9 test files.

| Consumer | Property | Notes |
|---|---|---|
| `app_button_themes.dart:76` | `controlOverlay` | via `buildSharedButtonStyle` |
| `app_icon_button_theme.dart:31` | `iconOverlay` | + `side` ring at `:35-38` |
| `app_tab_bar_theme.dart:30` | `controlOverlay` | |
| `app_radio_theme.dart:39` | `controlOverlay` | |
| `app_segmented_button_theme.dart:57` | `controlOverlay` | |
| `app_toggle_themes.dart:119`, `:216` | `controlOverlay` | switch + checkbox |
| `app_date_picker_theme.dart` | `controlOverlay` | |
| `mx_card.dart:790` | `cardOverlay` | |
| `mx_list_tile.dart:122-124` | `rowOverlay`, unpacked into three loose colours | `ListTileThemeData` has no `overlayColor` slot |
| `mx_focus_ring.dart:69` | `focusIndicator` | |
| `search_result_shell_widget.dart` | via `MxCard` | |

**Not routed through it, and each for a different reason:**

| Component | What it resolves from instead | Assessment |
|---|---|---|
| `MxPressable` (`mx_pressable.dart:68`) | Nothing — a bare `InkWell` falling through to `ThemeData.hoverColor/focusColor/highlightColor/splashColor` (`app_theme.dart:197-202`) | Colours land correctly because the fall-through is seeded with the same values. **The ring does not** — see P1-2 |
| `MxFab` → `app_fab_theme.dart:40-48` | `hoverColor`/`focusColor`/`splashColor` in `onPrimaryContainer`, deliberately, because a `primary` wash on a `primaryContainer` fill is invisible | Right decision, **incomplete** — see P2-1 |
| `MxPillButton` → `app_chip_theme.dart:76-96` | Composited into `ChipThemeData.color` as an opaque blend | See P1-3 |
| `MxTextButton` → `app_button_themes.dart:326-327` | `overlayColor: transparent` + `NoSplash`; states live on the text via `textLinkForeground` | Conforming — a link has no surface |
| `MxBreadcrumbStep`, `_MxBreadcrumbFold` | `_noOverlay` + `NoSplash` (`mx_breadcrumb.dart:421-426`) | Step conforming; fold is **P0** |
| `MxNavigationBar` → `app_navigation_bar_theme.dart` | Nothing; `_NavigationBarDefaultsM3` declares no `overlayColor`, so `_IndicatorInkWell` (`navigation_bar.dart:624-632`) falls to the theme's four | Works by accident — see P2-6 |
| `MxDropdown` → `DropdownButton` | `ThemeData.focusColor` | No ring; see the P1-2 inventory |

**`focusIndicator` vs `focusIndicatorOf`.** The split — one ring in `primary` for
surfaces, one in the caller's own label colour for a filled button whose ground
*is* `primary` — is the right shape and is pinned per-ground in both modes by
`focus_ring_contrast_test.dart`. **Conforming, and the model the rest of the
focus work should extend rather than replace.**

### 4.3 `AppDurations` — `lib/core/theme/foundations/app_durations.dart`

`fast` 120 · `normal` 200 · `slow` 320 · `standard` `Cubic(0.2, 0, 0, 1)` ·
`decelerate` `Cubic(0, 0, 0, 1)`.

`grep -rn "Curves\.\|Cubic(" lib/` returns **only this file**. The curve
vocabulary is closed in practice. Duration literals in `lib/` are 15, and every
one of them is a *hold, delay, timer or debounce* rather than a transition —
§9.2 has the inventory. **Verdict: conforming, unguarded.**

### 4.4 `AppMotionPolicy` — `lib/core/theme/foundations/app_motion_policy.dart`

One function, `durationOf(context, duration)`, returning `Duration.zero` when
`MediaQuery.disableAnimationsOf(context)`. Five call sites, which is **every
implicit animation and every animation controller in `lib/`**:

| Site | Widget | Duration |
|---|---|---|
| `mx_progress_bar.dart:126` | `TweenAnimationBuilder` | `slow` |
| `mx_search_field.dart:108` | `AnimatedContainer` | `fast` |
| `guess_option_item_widget.dart:97` | `AnimatedContainer` | `normal` |
| `match_tile_widget.dart:115` | `AnimatedContainer` + `AnimatedOpacity` | `normal` |
| `study_swipe_deck_widget.dart:148` | `AnimationController` (settle) | `normal` |

**Coverage of the surface is complete.** Coverage by tests is zero — `grep -rn
"AppMotionPolicy" test/ widgetbook/` returns nothing. See P2-8, and see P3-1 for
the file's rationale, which is wrong about the framework.

### 4.5 `AppInk` — `lib/core/theme/extensions/app_ink.dart`

Twenty-two named inks and an `InkedTextStyle.inked` extension. It is a
**persistent**-colour enum: `stated`, `quiet`, `accent`, the verdict family, the
`on*Container` family, and `disabled`. There is no hovered, pressed or focused
ink, and `inked()` takes one `AppInk` with no state-aware form.

Two sites therefore express a transient state by *choosing between two persistent
inks* at the call site:

```dart
// mx_breadcrumb.dart:410
ink: _isHovered ? AppInk.stated : AppInk.quiet,
// mx_breadcrumb_step.dart:159
?_icon(_isHovered ? AppInk.stated : AppInk.quiet),
```

That is not wrong — a link legitimately carries its states on the text, and
`textLinkForeground` does the same thing one layer down — but it means the ink
system and the state system meet only at a call site, so nothing can audit
"which inks are allowed to change on hover". P3-3.

**Naming.** `AppInk` is text colour; `MxPressable`'s doc calls itself "the ripple
leg", `ink_probe.dart` reads "the ink layer", and `app_ink.dart` sits beside
`app_interaction_states.dart`. Two unrelated meanings of *ink* in one design
system, one of them Material's. P3-4.

---

## 5. Same state, painted twice

### 5.1 The framework baseline: press is two layers, everywhere

`_startNewSplash` creates a splash **and** calls `updateHighlight(_HighlightType
.pressed, value: true)` (`ink_well.dart:1204-1215`). The build method's own
comment says a separate pressed highlight "is no longer used", and the code four
lines below resolves one anyway (`ink_well.dart:1359-1363`).

`ButtonStyleButton` passes `highlightColor: Colors.transparent`
(`button_style_button.dart:567`) to suppress it — and that is **defeated by
`overlayColor`**, which is checked first:

```dart
_HighlightType.pressed =>
    widget.overlayColor?.resolve(pressed) ?? widget.highlightColor ?? theme.highlightColor,
```

Every button in this app declares `overlayColor` (`app_button_themes.dart:76`),
so every button resolves a non-null pressed highlight and the transparent hint is
dead. Computed, over the resting ground, a pressed control paints

`0.12 + 0.12 × 0.88 = 0.2256` of `primary`,

and a pressed card `0.10 + 0.10 × 0.90 = 0.19` of `primary`, against tokens that
say 12 and 10. **This is uniform across every `InkWell`-based control in the app
and across stock Flutter M3**, so it is a baseline to know rather than a
divergence to fix. Two exceptions, both correct: `MxTextButton` and the
breadcrumb resolve their overlay to a transparent/alpha-zero colour, so both
layers are nothing; `NavigationBar`'s `_IndicatorInkWell` is constructed with
`highlightColor: Colors.transparent` **and** no `overlayColor` in this app, so it
is the one control that presses once.

### 5.2 The divergence: the chip paints focus twice and press three times

`app_chip_theme.dart:76-96` composites the transient states into the chip's
**fill**, as an opaque `Color.alphaBlend`:

```dart
if (states.contains(WidgetState.pressed)) return _tint(resting, scheme.primary, AppStateOpacity.pressed);
if (states.contains(WidgetState.focused)) return _tint(resting, scheme.primary, AppStateOpacity.focus);
if (states.contains(WidgetState.hovered)) return _tint(resting, scheme.primary, AppStateOpacity.hoverControl);
```

Stock M3 does not: `_ChoiceChipDefaultsM3.color` (`choice_chip.dart:308-327`)
resolves `{selected, disabled}`, `{disabled}`, `{selected}` and a fall-through,
and **no transient state at all** — a chip's hover, focus and press are the
`InkWell` overlay in Material's design.

Flutter compensates for exactly one of the three. `chip.dart:1427`:

```dart
hoverColor: (widget.color ?? chipTheme.color) == null ? null : Colors.transparent,
```

`focusColor`, `highlightColor`, `splashColor` and `overlayColor` are **not**
passed on that `InkWell` (`chip.dart:1411-1428`), so they fall through to
`app_theme.dart:200-202`: `focusColor` = `primary` @ .10, `highlightColor` =
`primary` @ .12, `splashColor` = `primary` @ .12. Both the fill tint and the
overlay are live, and the chip's own `statesController` carries `pressed`
(`chip.dart:1103`), `focused` (`:1413`) and `hovered` (`:1423`) into
`_getBackgroundColor` → `resolveColor` → `chipTheme.color.resolve(states)`
(`chip.dart:1154-1194`).

Computed composite over the resting fill:

| State | Token says | Layers actually painted | Effective `primary` fraction |
|---|---|---|---|
| hover | .06 | fill tint only (`hoverColor` zeroed by the SDK) | **0.060** ✅ |
| focus | .10 | fill tint .10 + focus highlight .10 | **0.190** |
| press | .12 | fill tint .12 + pressed highlight .12 + splash .12 | **0.319** at the ripple centre |

So a focused pill is 1.9× its token and a pressed pill 2.7×, and the one state
the SDK protected is the one state a phone can never enter. P1-3.

### 5.3 Everything else, checked

- `MxCard` — the `DecoratedBox` fill carries **no** transient state
  (`mx_card.dart:772-800`); all three come from `overlayColor`. Single, at the
  §5.1 baseline. Conforming.
- `MxListTile` — `ListTile` passes `focusColor`/`hoverColor`/`splashColor` to its
  `InkWell` (`list_tile.dart:981-991`) and no `tileColor` change for transient
  states. Single. Conforming.
- Segmented button, tab bar, switch, checkbox, radio, date picker — `overlayColor`
  only; `backgroundColor`/`fillColor` resolve `selected`/`disabled` and nothing
  transient. Conforming.
- Filled button — the **fill** blends on hover and press
  (`app_button_themes.dart:182-201`) *and* `overlayColor` washes `primary` at the
  same alphas. Two layers, but the second is `primary` on `primary` — the file
  says so at `:190-194`, which is why the blend exists. Not a double-paint: it is
  a visible layer plus an invisible one. Worth stating so nobody "fixes" the
  overlay and expects a change.
- `MxSearchField` — the focused surface/border is an `AnimatedContainer`
  decoration only; no ink layer, no `InkWell`. Single.

---

## 6. Focus mechanisms — the full inventory

Eleven distinct focus treatments across the shared controls. The columns that
matter are *what it draws*, *whether it is gated on highlight mode*, and *whether
the thing it draws can reach 3:1*.

| # | Control | Indicator | Geometry | Gated? | ≥3:1? |
|---|---|---|---|---|---|
| 1 | `MxCard` | foreground `Border` + 10 % wash | box around the child, card radius | **yes** — `mx_card.dart:539-542` | yes (`primary`, pinned) |
| 2 | `MxListTile` | foreground `Border` + 10 % wash | box around the child, `AppRadius.md` | **no** — `mx_list_tile.dart:69-74` | yes |
| 3 | `MxPillButton` via `MxFocusRing` | foreground `Border` + fill tint | **box around the 48dp tap target**, pill radius | **no** — `mx_focus_ring.dart:59-62` | yes, but mis-fitted (P2-2) |
| 4 | `MxIconButton` | `side` ring in `primary` + 8 % wash | inside the shape (`OutlinedBorder.side`) | ring **no**, wash yes | yes |
| 5 | `MxActionButton.primary`/`.tonal`/`.destructive` | `side` ring in the label colour | inside the shape | ring **no**, wash yes | yes (`onPrimary` on `primary`, 5.76:1 at tightest per `app_interaction_states.dart:186-188`) |
| 6 | `MxActionButton.secondary` | `side` → `primary` at `AppStroke.focus` | replaces the hairline, zero layout cost | **no** | yes; and M3's own answer (`_OutlinedButtonDefaultsM3.side`) |
| 7 | `MxTextButton` / bare `TextButton` | underline at `decorationThickness: AppStroke.focus` | on the glyphs | **no** | see P2-4 (units) |
| 8 | `MxBreadcrumbStep` | underline, thicker than hover's | on the glyphs | **no** — `mx_breadcrumb_step.dart:139` | distinguished from hover only by thickness |
| 9 | `MxPressable` (guess option, match tile, radio row) | 10 % wash **only** | full ink box | yes (framework) | **no — ~1.15:1** |
| 10 | `MxCheckboxRow` / `MxSwitchRow` / `MxRadioRows` / `MxDropdown` / `MxFab` | 10 % wash only (`ListTile` focus wash, or `focusColor`) + the control's own `controlOverlay` circle | — | yes (framework) | **no — ~1.15:1** |
| 11 | `_MxBreadcrumbFold` | **nothing** | — | n/a | **no indicator at all** |

Two structural observations:

**No layout shift anywhere.** Rows 1–3 use `DecorationPosition.foreground`, which
does not participate in layout; rows 4–6 paint an `OutlinedBorder.side`, which is
painted inside the shape rather than added to the box; rows 7–8 use a text
decoration. `mx_card_interaction_test.dart:141` and `:330` pin it for the card,
`mx_list_tile_test.dart:181` for the row. **Conforming, and pinned.**

**No role hijack.** M100.23 removed the four slots that resolved a semantic
border role to `primary` on focus, and `m3_combined_state_test.dart` keeps them
removed. The one component whose border role Material itself moves on focus —
`OutlinedButton` — is stated as the exception rather than assumed. **Conforming,
and pinned.**

### 6.1 Why one universal focus painter is the wrong fix

The four geometries in the table are genuinely different problems:

1. **A box around a child** (card, row, pill) — the child has a paintable
   rectangle and the ring can sit outside it at zero layout cost. This is CSS's
   `outline`, and `MxFocusRing` is the right idea.
2. **A shape's own side** (icon button, filled button, outlined button) — Material
   already paints an `OutlinedBorder` here and `ButtonStyle.side` is the slot. A
   second foreground ring would double the stroke.
3. **Glyphs with no box** (text button, breadcrumb step) — zero padding is the
   whole design; a ring would trace the letters. An underline is the only
   indicator that fits, and `app_button_themes.dart:292-301` already argues this.
4. **A control inside a row** (checkbox, switch, radio) — the focusable thing is
   the *row*, the semantic thing is the *control*. Marking the row is right;
   marking the 18dp box is what inset the checkbox fill at M100.21.

The fix is therefore **one contract with four sanctioned painters**, not one
widget:

> A focus indicator MUST (a) reach 3:1 against every ground the control can sit
> on, (b) appear only in `FocusHighlightMode.traditional`, and (c) cost no
> layout. It MAY be a foreground ring, a shape side, a text underline or a row
> ring, and the component picks the one its geometry admits.

---

## 7. Press and ripple

**Android's ripple is retained.** `theme_data.dart:415-420`:

```dart
final bool useInkSparkle = platform == TargetPlatform.android && !kIsWeb;
splashFactory ??= useMaterial3
    ? useInkSparkle ? InkSparkle.splashFactory : InkRipple.splashFactory
    : InkSplash.splashFactory;
```

`app_theme.dart:171` pins `platform: TargetPlatform.android` and the app sets no
`splashFactory`, so an Android build gets `InkSparkle` — the platform's own
617 ms turbulent splash (`ink_sparkle.dart:182`). **Item 4 of the brief passes.**

The caveat is worth recording: `kIsWeb` is not the pinned platform, so the web
build renders `InkRipple` (75 / 225 / 375 ms, `ink_ripple.dart:19-23`). The
comment at `app_theme.dart:155-165` explains that the platform was pinned *so the
web E2E channel measures Android's geometry*; the splash is the one thing that
pin cannot carry across. P3-2 — a documentation gap, not a defect.

**Transparent / disabled splash hacks — three, all deliberate and all stated:**

| Site | Mechanism | Verdict |
|---|---|---|
| `app_button_themes.dart:326-327` | `overlayColor: transparent` + `NoSplash.splashFactory` on `TextButton` | Conforming. A link has no surface; the states are on the text and the theme says so |
| `mx_breadcrumb.dart:421-426` | `_noOverlay` = `colors.primary.withAlpha(0)` + `NoSplash` | Conforming *mechanism* — a scheme colour at alpha zero rather than `Colors.transparent`, so the token guard can still read it. The comment explaining that is the model for this class of suppression |
| `mx_breadcrumb_step.dart:141-142` | same | Conforming |

None of the three is a hack in the pejorative sense; all three are a suppression
with a written reason. **The problem is not that ink was suppressed, it is that
`_MxBreadcrumbFold` suppressed it and put nothing back** (P0-1).

**Press-scale / shrink: none.** `grep -rn "Transform.scale\|AnimatedScale" lib/`
returns only `ProgressMetricScale`, an unrelated layout enum. **Item 6 of the
brief is clean.** Worth keeping clean: a press-scale is the one press effect that
moves the thing under the finger, and this app's `AppMotionPolicy` has no way to
express "shrink less".

---

## 8. Hover

**Hover never dictates behaviour a touch device cannot reach.** Every `onHover`
in `lib/` is additive:

- `mx_breadcrumb.dart:399-410` — the `…` glyph moves `quiet` → `stated`. The
  button is fully operable without it.
- `mx_breadcrumb_step.dart:137,159` — underline + glyph ink. Operable without.
- `mx_text_button.dart:207-223` — underline on hover, same on focus. Operable.
- Everything else is a `WidgetStateProperty` wash, which is by definition
  additive.

**Item 7 of the brief is clean.**

Two secondary observations:

- Hover weight is the one place the design's four control shapes are actually
  distinguishable (`.04`/`.06`/`.07`/`.08`), pinned by
  `app_interaction_states_test.dart:301-315`. Press and focus collapse to one
  value each. That is a deliberate asymmetry and reads correct: hover is the
  state whose perceived weight scales with area.
- `MxPressable` is used for a guess option row and a match tile — both *card*-
  sized — and takes the **row** hover weight (.07) from the theme fall-through,
  where `cardOverlay` would give .04. A four-shape vocabulary that a component
  cannot select from is a three-shape vocabulary. Folded into P1-2, since the fix
  is the same edit.

---

## 9. Motion

### 9.1 Vocabulary

Three durations, two curves, zero raw `Curves.` in `lib/`. Every `Animated*`,
`Tween*` and `AnimationController` in `lib/` — there are six widgets total — uses
`AppDurations` and `AppMotionPolicy`. For the size of the surface, this is as
clean as the colour system.

**What the vocabulary deliberately does not cover, and should say so:** the
framework paints motion this app never names.

| Source | Duration | On screen as |
|---|---|---|
| `ink_well.dart:998` | 200 ms | the pressed highlight's fade |
| `ink_well.dart:1001` | 50 ms | hover and focus highlight fades |
| `ink_sparkle.dart:182` | 617 ms | the Android splash |
| `ink_ripple.dart:20-22` | 75 / 225 / 375 ms | the web splash |
| `chip.dart:42-46, 999` | 195 / 150 / 75 ms | chip select, disable, press-elevation |
| `input_decorator.dart:39, 62` | 167 / 20 ms | the floating label, the hint fade |
| `material.dart:205` | `kThemeChangeDuration` 200 ms | `Material` shape/elevation changes |

`AppDurations`' doc says "the longest anything in the app is allowed to take" is
320 ms. A 617 ms splash is longer, and it is the right answer. The sentence
should be scoped to app-authored motion. P3-6.

### 9.2 Duration literals — 15 in `lib/`, none of them a transition

| Site | Value | Kind |
|---|---|---|
| `mx_undo_snack_bar.dart:12` | 8 s | snack bar lifetime |
| `app_tooltip_theme.dart:22` | 500 ms | tooltip wait |
| `library_search_controller.dart:20` | 250 ms | debounce |
| `recall_mode.dart:7` | 20 s | turn limit (BR) |
| `recall_timer_section_widget.dart:122` | 100 ms | countdown tick |
| `match_tile_widget.dart:315, 327` | 500 / 700 ms | verdict holds |
| `study_mode_feedback_widget.dart:37-50` | 800–2200 ms | reading budgets |
| `study_mode_view_widget.dart:215` | from domain | remaining time |
| `reminder_time_model.dart:82` | from domain | clock arithmetic |
| `query_log_interceptor.dart:17` | 10 ms | slow-query threshold |

**All correct, and `match_tile_widget.dart:300-315` states the reason better than
this report could**: a hold is how long a state is *visible*, a transition is how
long it takes to *arrive*, and borrowing `AppDurations.slow` for a legibility
budget is how the budget ended up at a third of what it needed. That distinction
is the right one and should not be consolidated away. What is missing is a guard
that keeps a *transition* from acquiring a literal — see P2-7.

---

## 10. Reduced motion and accessibility

### 10.1 What the policy does, and what the framework already did

`AppMotionPolicy.durationOf` returns `Duration.zero` under
`MediaQuery.disableAnimationsOf`. Applied at all five animation sites. The
disable/shorten/preserve split it encodes is right:

| Class | Policy | Sites | Assessment |
|---|---|---|---|
| **Disabled** — decoration on a state change | `Duration.zero` | progress sweep, search-pill crossfade, guess/match tile skins, swipe settle | Correct. The state itself is carried by colour and border, which are right in the first frame |
| **Preserved** — motion *is* the information | untouched | the indeterminate spinner, the recall countdown, the drag under the finger in `study_swipe_deck_widget` | Correct, and `app_motion_policy.dart:20-24` argues it |
| **Preserved** — holds and reading budgets | untouched | `AppStudyFeedback`, `MatchTile.successFlash`/`wrongHold` | Correct. `match_tile_widget.dart:112-115` states it: the hold is feedback, the crossfade is decoration |

**Item 9 of the brief passes on design.** It fails on evidence: zero tests.

### 10.2 The framework already shortens implicit animations, and the policy file says it does not

`app_motion_policy.dart:6-11` claims that before the policy "every custom
animation in the app ran unconditionally: the progress bar swept for 320 ms …
even when the operating system had been told to reduce motion". **That is not
what would have happened.**

`TweenAnimationBuilder` extends `ImplicitlyAnimatedWidget`
(`tween_animation_builder.dart:105`), whose state creates an `AnimationController`
with the default `animationBehavior` (`implicit_animations.dart:362-366`) and
drives it with `controller.forward(from: 0.0)` (`:393`). And
`animation_controller.dart:645-651`:

```dart
final double scale = switch (animationBehavior) {
  AnimationBehavior.normal when SemanticsBinding.instance.disableAnimations => 0.05,
  AnimationBehavior.normal || AnimationBehavior.preserve => 1.0,
};
```

So the progress bar would have swept for **16 ms**, not 320. The same applies to
every `AnimatedContainer` and `AnimatedOpacity` in the app, and to
`study_swipe_deck_widget`'s controller.

**The policy is still correct** — 16 ms is one frame of movement where the
request was for none, and `Duration.zero` takes the explicit
`if (simulationDuration == Duration.zero)` fast path
(`animation_controller.dart:673-684`) that lands on the target value with no
ticker at all. But the *reason written down* is wrong, and a future reader who
discovers the 5 % scale will read the file as obsolete and delete it. P3-1.

### 10.3 What reduced motion does not reach

Nothing in the app can shorten the framework motion in §9.1, nor page
transitions: `grep -l disableAnimations` across the SDK files read returns only
`animation_controller.dart` and `media_query.dart`. Route transitions,
`InputDecorator`'s label float, chip select fades and ink splashes all run at
full duration under reduced motion, except where they go through an
`AnimationController` at `AnimationBehavior.normal` — which the ink features and
`InputDecorator` do, so they get the 5 % scale, and `PageRoute` transitions do
too. This is Flutter's answer, not the app's, and the report records it so nobody
attempts an app-level fix for it.

---

## 11. Severity registry

Severity is *user impact at HEAD*, not effort.

### P0

#### P0-1 · `_MxBreadcrumbFold` is keyboard-reachable and has no focus indicator

**Evidence.** `mx_breadcrumb.dart:396-404`:

```dart
child: InkWell(
  onTap: widget.onExpand,
  onHover: (bool value) => setState(() => _isHovered = value),
  overlayColor: _noOverlay(context),      // primary.withAlpha(0) — hover, focus AND press
  splashFactory: NoSplash.splashFactory,
```

`_noOverlay` is a `WidgetStatePropertyAll`, so it answers every state including
`focused`; `ink_well.dart:1360-1362` takes `overlayColor` before `focusColor`, so
the theme's seeded `focusColor` never applies. There is no `onFocusChange`
(unlike `mx_breadcrumb_step.dart:139`), no `MxFocusRing`, and no `side`. The
`InkWell` is enabled, so `_canRequestFocus` is true (`ink_well.dart:1333-1336`)
and the control is in the tab order.

**Impact.** A keyboard, switch-access or directional-pad user can focus and
activate the crumb-trail expander with no visible change of any kind. WCAG 2.4.7
Focus Visible is a level-AA failure, and this is the total-absence case, not the
weak-indicator case. Reachable whenever a deck path overflows the header —
BR-55 allows 10 levels, so it is a normal state of the app, not an edge.

**Closure test.** `test/shared/widgets/mx_breadcrumb_focus_test.dart`: pump a
`MxBreadcrumb` narrow enough to fold, `sendKeyEvent(LogicalKeyboardKey.tab)`
until the fold node holds focus, and assert a foreground `BoxDecoration.border`
exists at `AppStroke.focus` in `AppInteractionStates.focusIndicator(scheme)
.color`; then assert it is absent at rest and absent under
`FocusHighlightStrategy.alwaysTouch`.

---

### P1

#### P1-1 · Focus-visible is ungated in eight of eleven focus painters

**Evidence.** The SDK distinction is quoted in §3.2. The app applies it in
exactly one place — `mx_card.dart:539-542`:

```dart
bool get _isFocusVisible =>
    _isInteractive && _isFocused &&
    FocusManager.instance.highlightMode == FocusHighlightMode.traditional;
```

with a `addHighlightModeListener` in `initState`/`didUpdateWidget`/`dispose`
(`:487-518`) so the mode can change while a control is focused. `docs/wbs.md:14506`
records this as one of M99.83's three real defects: *"focus ring vẽ ở mọi
`FocusHighlightMode` — cùng bug class autofocus M99.75"*.

The same bug class is live in:

| Site | Line |
|---|---|
| `MxListTile` — ring on `_focusNode.hasFocus` | `mx_list_tile.dart:69-74`, `:96-101` |
| `MxFocusRing` → `MxPillButton` — ring on `Focus.onFocusChange` | `mx_focus_ring.dart:59-75` |
| `MxBreadcrumbStep` — underline on `onFocusChange` | `mx_breadcrumb_step.dart:124-128`, `:139` |
| `MxIconButton` — `side` ring off `WidgetState.focused` | `app_icon_button_theme.dart:35-38` |
| `MxActionButton` filled/tonal/destructive — `side` ring | `app_button_themes.dart:222-228` |
| `MxActionButton.secondary` — `side` → `primary` | `app_button_themes.dart:385-395` |
| `MxTextButton` / `TextButton` theme — focus underline | `app_button_themes.dart:344-352`, `mx_text_button.dart:206-223` |
| `MxPillButton` fill tint — `_fillFor` focus branch | `app_chip_theme.dart:88-90` |

**Impact.** `MxActionButton._takesFocus` (`mx_action_button.dart:168-170`) already
gates *autofocus* on highlight mode, and its doc records the reported symptom:
a delete dialog's Cancel came out with an indigo ring on a touch device while the
identical button two screens away had the grey control edge, "and the two read as
different components rather than as one button in two states" — 10 551 pixels of
it on `deck_delete_confirm_light.png`. That gate covers the case where *this app*
moves focus. It does not cover focus arriving any other way: a dismissed sheet or
dialog returning focus to its opener, `_frontFocus.requestFocus()` in the card
editor and tag section, `fill_answer_section_widget.dart:115` and `:173`, or a
phone with a keyboard that was unplugged. In all of those the control shows a
keyboard affordance with no keyboard.

**Closure test.** Extend the existing pattern rather than inventing one:
`mx_card_interaction_test.dart:266` ("focus without a keyboard draws no ring") is
already the right test and covers one component. Parameterise it over a list of
`(widget, indicatorFinder)` pairs covering rows 2–8 of the §6 table, with
`FocusManager.instance.highlightStrategy = FocusHighlightStrategy.alwaysTouch` in
`setUp` for the negative half and `alwaysTraditional` for the positive half.

#### P1-2 · Nine control shapes have no focus indicator that can reach 3:1

**Evidence.** Rows 9 and 10 of the §6 table: `MxPressable` (`mx_pressable.dart:66-77`
— a bare `Material` + `InkWell`, no `overlayColor`, no ring), `MxCheckboxRow`,
`MxSwitchRow`, `MxRadioRows`, `MxDropdown` and `MxFab`. Their entire focus
indicator is a 10 % `primary` wash, which `mx_focus_ring.dart:17-21`,
`app_interaction_states.dart:51-54`, `mx_list_tile.dart:26-28` and
`app_icon_button_theme.dart:32-34` all independently record as **~1.15:1 light,
~1.25:1 dark** against the 3:1 WCAG 1.4.11 asks.

**The project has already reasoned this through and fixed it once.**
`search_result_shell_widget.dart:16-25`:

> It had no **focus ring**: the row declares itself a button, this screen is
> reached with the keyboard already in the field, and a bare `InkWell` falls back
> to a 10 % wash that `AppStateOpacity.focus`'s own documentation measures at
> ~1.15:1 — below the 3:1 WCAG 1.4.11 asks of a focus indicator.

The fix there was to stop hand-rolling and use `MxCard`. `MxPressable` is the
sanctioned way to hand-roll, and it carries the defect the hand-rolling was
banned for.

Call sites: `guess_option_item_widget.dart:118`, `match_tile_widget.dart:139`,
`mx_radio_rows.dart`. Two of the three are the study session's primary answer
controls.

**Secondary defect, same edit:** `MxPressable` has no way to select a hover
weight, so a card-sized guess option takes the **row** weight (.07) from the
theme fall-through where `cardOverlay` gives .04. The four-shape vocabulary is
unreachable from the one component built for custom surfaces.

**Closure test.** `test/shared/widgets/mx_pressable_focus_test.dart` and one
per selection row: tab to the control, assert a border/ring exists, and assert
its colour clears 3:1 against the ground the control sits on using the same
contrast helper `focus_ring_contrast_test.dart` already uses. Plus a scope test
that enumerates every `lib/` file containing `InkWell(` or `MxPressable(` and
requires each to be in an allowlist of "has a ≥3:1 focus indicator", the same
shape as `card_activation_wrapper_test.dart`.

#### P1-3 · The pill paints focus twice and press three times

**Evidence.** §5.2 in full: `app_chip_theme.dart:76-96` composites into the fill,
`choice_chip.dart:308-327` shows M3 does not, `chip.dart:1427` shows the SDK
zeroes only `hoverColor`, `chip.dart:1411-1428` shows `focusColor`/
`highlightColor`/`splashColor`/`overlayColor` are all unset, and
`app_theme.dart:200-202` shows what they fall through to.

**Impact.** Computed: focus 0.19 against a 0.10 token, press 0.319 against a 0.12
token. Two consequences beyond the number. First, the app's `AppStateOpacity`
constants stop describing what a pill renders, so `css_scale_parity_test.dart`
can pass while the pixel is wrong. Second, and worse for the design: the pill's
selected/unselected fill delta is already recorded as **1.35:1 light / 1.43:1
dark** (`reviews/mx-chip-pill-deep-audit.md` §1), so a 31.9 % press tint is more
than twice the contrast that distinguishes selection itself — pressing an
unselected pill makes it read as more selected than a selected one.

**Fix direction (a decision the owner still has to take).** Two coherent options,
and the report recommends the first:

- **(a) Keep the composited fill, suppress the overlay.** Add
  `overlayColor: WidgetStatePropertyAll(scheme.primary.withAlpha(0))` to the
  chip's `InkWell` — which requires `ChipThemeData` to gain nothing, because
  `RawChip` reads no overlay slot from the theme, so it must go on
  `MxPillButton`'s `ChoiceChip.elevated(…)` call. Preserves R7 (opaque blend over
  a known ground) which is why `_fillFor` exists.
- **(b) Move the transient states out of `color` and into an `overlayColor`.**
  Matches M3 exactly, loses the R7 property — the wash would be translucent over
  the pill's own fill, which is *known*, so R7's exemption arguably applies.

**Closure test.** A widget test that hovers, focuses and presses a real
`MxPillButton` under `theme_probe` and uses `ink_probe.dart`'s `expectNoInkColor`
to assert **no** ink layer paints `primary` at .10 or .12 while the fill carries
the tint — the probe already exists and already reads packed ARGB for exactly
this class of question.

---

### P2

#### P2-1 · A pressed `MxFab` paints a second layer in the wrong colour

**Evidence.** `app_fab_theme.dart:40-48` declares `hoverColor`, `focusColor` and
`splashColor` in `onPrimaryContainer`, with a comment (`:32-39`) explaining that
M3's hardcoded defaults describe another system's pair. `highlightColor` is not
declared, `FloatingActionButton` does not pass one
(`floating_action_button.dart:579-600` — `focusColor`, `hoverColor`, `splashColor`
only), and `RawMaterialButton` falls through: `material_button.dart:406`,
`highlightColor: highlightColor ?? theme.highlightColor`. That is
`app_theme.dart:201` — `primary` @ .12. So a pressed FAB paints
`onPrimaryContainer` @ .12 as a splash **and** `primary` @ .12 as a rect
highlight, the second being the invisible-on-`primaryContainer` colour the whole
override existed to avoid.

**Closure test.** `expectInkColor(tester, onPrimaryContainer@.12)` **and**
`expectNoInkColor(tester, primary@.12)` on a pressed `MxFab`.

#### P2-2 · `MxFocusRing` fits the tap target, not the pill

**Evidence.** `MxFocusRing` decorates the box it wraps
(`mx_focus_ring.dart:63-74`); the box it wraps is `ChoiceChip.elevated` with
`materialTapTargetSize: MaterialTapTargetSize.padded`
(`mx_pill_button.dart:130-133`), and `chip.dart:1490-1499` grows that box to
`kMinInteractiveDimension` (48) via `_ChipRedirectingHitDetectionWidget`. The
painted pill is 32 content + two hairlines = 34 (`app_chip_theme.dart:249`,
`:271`). `reviews/mx-chip-pill-deep-audit.md` §1 measured it on a real render:
ring 48.0 × 48.0, painted pill 33.4 × 34.0 — 7.3 dp clear on each side, 7.0 above
and below, at a different corner curvature. **Still present at this BASE_SHA.**

This is the finding the brief's "do not force one universal focus painter when
geometries differ" is about: `MxFocusRing` is the right painter for a box, and
the pill's box is not the pill.

**Closure test.** Pin `tester.getRect` of the `DecoratedBox` against the painted
`Material`'s rect on a focused pill and require equality within 1 dp.

#### P2-3 · `error` beats `disabled` on a text field, against every other resolver

**Evidence.** `input_decorator.dart:2362-2369` (quoted in §3.3);
`app_input_theme.dart:39-51` declares all five borders; `mx_text_field.dart:84-85`
exposes `errorText` and `isEnabled` as independent public parameters.

**Impact.** A disabled field carrying a validation message draws a live
`scheme.error` border at `AppStroke.input` around content in `onDisabled`. The
control says "you cannot touch this" and "fix this" at once. Not a crash, and it
may even be the desired reading — but it is undecided, undocumented and untested,
and it inverts the precedence every other resolver in the app follows.

**Closure test.** A widget test pumping `MxTextField(isEnabled: false, errorText:
'…')` in both modes that asserts whichever border the owner decides, plus a line
in `docs/design-system/` recording the decision.

#### P2-4 · `AppStroke.focus` is a dp width in five places and a multiplier in three

**Evidence.** `app_stroke.dart:25-28` documents `focus = 2` as "a focus-visible
indicator — `--border-focus` … and the thickness of the underline a text button
focuses with". It is used as a `BorderSide.width` (dp) in
`app_interaction_states.dart:192`, `app_icon_button_theme.dart`,
`app_button_themes.dart:395`, `mx_focus_ring.dart`, `mx_list_tile.dart`; and as a
`TextStyle.decorationThickness` in `app_button_themes.dart:352`,
`mx_text_button.dart:223` and (as a private twin) `mx_breadcrumb_step.dart:128`.
`decorationThickness` is documented by Flutter as *"a multiplier of the thickness
defined by the font"*, and `mx_text_button.dart:25` knows this — "focus
underlines at twice the font's stroke" — while `app_stroke.dart` does not.

**Impact.** No wrong pixel today; a wrong pixel on the next edit. Raising `focus`
to 3 would make every ring 3 dp and every underline 3× the font's stroke, which
for a 14 sp face is roughly 2 dp — the two indicators would diverge silently, and
the token's own doc would still claim they are one decision.

**Closure test.** Split the token — `AppStroke.focus` (dp) and
`AppStroke.focusUnderlineScale` (multiplier) — and add a guard test that
`decorationThickness:` never receives an `AppStroke` member that is a dp width.

#### P2-5 · Three ink policies inside one breadcrumb

**Evidence.** `mx_breadcrumb.dart:189` builds a bare `InkWell` with no overlay
suppression (the collapsed single-target variant), while `:400-401` and
`mx_breadcrumb_step.dart:141-142` suppress ink entirely. So the same component
ripples in `primary` @ .12 in one layout and paints nothing in the other, and
which one the user sees depends on how wide their deck names are.

**Closure test.** A widget test that renders the breadcrumb at two widths, taps
each, and asserts the same ink answer from `ink_probe.dart` in both.

#### P2-6 · The navigation bar resolves its state layer outside the app's system

**Evidence.** `app_navigation_bar_theme.dart` declares no `overlayColor`.
`_NavigationBarDefaultsM3` (`navigation_bar.dart:1427-1475`) declares none
either. `_IndicatorInkWell` (`:624-632`) is constructed with
`highlightColor: Colors.transparent` and takes `overlayColor: info.overlayColor
?? navigationBarTheme.overlayColor` (`:605`) — null. So the bar's four
destinations fall all the way through to `app_theme.dart:197-202`.

The colours land correctly because that fall-through is seeded, which is exactly
what `app_theme.dart:191-196` says it is for. **The bar works by the safety net
rather than by a decision**, and it is the one control in the app whose press is
a single layer (because the SDK zeroed the highlight) — so the four bottom-bar
destinations press *lighter* than everything else in the app and nothing records
why.

**Closure test.** Add `overlayColor: AppInteractionStates.controlOverlay(scheme)`
to `buildNavigationBarTheme` and extend `theme_coverage_test.dart`'s
widget-to-slot map to require it, or record the fall-through as the decision in
that test's blind-spot list.

#### P2-7 · No guard stops the next raw `Duration` or `Curve` on an animation

**Evidence.** `grep -n "Duration\|motion" check_architecture.py verify_invariants.py`
returns nothing. `test/design_audit/` has no motion rule. The vocabulary holds
today by discipline alone.

**Closure test.** A source-scan test in `test/design_audit/` in the shape of the
existing colour rules: any `duration:` or `curve:` argument inside `lib/` whose
expression is not `AppDurations.*` or `AppMotionPolicy.durationOf(…)` fails,
with a stated exemption list for holds and delays (§9.2) that names each one and
its reason — so the exemption list becomes the "durations that are not motion"
registry the app currently lacks.

#### P2-8 · `AppMotionPolicy` has no test at all

**Evidence.** `grep -rn "AppMotionPolicy" test/ widgetbook/` returns nothing.
Five call sites, one accessibility contract, zero coverage. A refactor that drops
`durationOf` from any of the five sites is invisible to CI, to the guard and to
the goldens — every golden shoots a resting state.

**Closure test.** `test/core/theme/foundations/app_motion_policy_test.dart`:
pump each of the five animating widgets inside
`MediaQuery(data: …copyWith(disableAnimations: true))`, change the value that
animates, `pump()` **one** frame, and assert the widget is already at its final
value; then the same with `disableAnimations: false` and assert it is not.
That is the assertion that survives the framework's own 5 % scale, which a
duration-equality assertion would not.

---

### P3

| # | Finding | Evidence |
|---|---|---|
| **P3-1** | `app_motion_policy.dart:6-11`'s rationale is wrong about the framework: `ImplicitlyAnimatedWidget` drives an `AnimationController` at `AnimationBehavior.normal`, which already scales to 5 % under `SemanticsBinding.disableAnimations`. The progress bar would have swept 16 ms, not 320. The policy is still right — `Duration.zero` takes the no-ticker fast path — but the reason invites deletion | `implicit_animations.dart:362-366`, `:393`; `tween_animation_builder.dart:105`; `animation_controller.dart:645-651`, `:673-684` |
| **P3-2** | The Android splash is `InkSparkle` and the web splash is `InkRipple`, because the SDK gates on `kIsWeb` rather than on the pinned `platform`. The web E2E channel therefore cannot see the shipped ripple, which `app_theme.dart:155-165` implies it can | `theme_data.dart:415-420`; `app_theme.dart:171` |
| **P3-3** | Two sites express a transient state by picking between two persistent `AppInk` members, and `InkedTextStyle.inked` has no state-aware form — so no audit can ask "which inks may change on hover" | `mx_breadcrumb.dart:410`; `mx_breadcrumb_step.dart:159`; `app_ink.dart:130-147` |
| **P3-4** | *Ink* means two unrelated things in one design system: `AppInk` (text colour) and Material ink (the splash layer, as in `MxPressable`'s doc and `ink_probe.dart`) | `app_ink.dart:7`; `mx_pressable.dart:27` |
| **P3-5** | `MxListTile` unpacks `rowOverlay` into `hoverColor`/`focusColor`/`splashColor` but not `highlightColor` — `ListTile` has no such parameter, so the pressed highlight falls through to `ThemeData.highlightColor`. Correct only because the seeded fall-through happens to carry the identical value; the comment at `:120-121` claims a single definition that the pressed layer does not actually have | `mx_list_tile.dart:118-125`; `list_tile.dart:981-991`; `app_theme.dart:201` |
| **P3-6** | `AppDurations`' "the longest anything in the app is allowed to take" (320 ms) is contradicted on screen by seven framework durations, the longest being a 617 ms splash. The sentence should be scoped to app-authored motion | `app_durations.dart:14-15`; §9.1 table |
| **P3-7** | `study_swipe_deck_widget.dart:148` mutates `_settle.duration` inside `build()`. Correct behaviour (the flag can change mid-session) and the wrong place for a side effect; `didChangeDependencies` is where a `MediaQuery` read belongs | `study_swipe_deck_widget.dart:144-148` |

---

## 12. Coverage and guard gaps

### 12.1 What is covered

| Area | Test | What it pins |
|---|---|---|
| Resolver ordering | `app_interaction_states_test.dart:279-299` | `{hovered, pressed}` == `{pressed}` on `cardOverlay` |
| Four hover weights | `:301-315` | card < row < icon, by alpha |
| Combined `{selected, focused}` | `m3_combined_state_test.dart` | 5 components, both modes, both directions |
| `{disabled}` / `{disabled, selected}` | `m3_combined_state_test.dart:285-310` | a disabled control never resolves to an enabled accent |
| Focus-ring contrast | `focus_ring_contrast_test.dart` | ≥3:1 per ground, both modes, ring ≠ resting border, filled-button variant |
| Focus costs no layout | `mx_card_interaction_test.dart:118`, `:141`, `:330`; `mx_list_tile_test.dart:181` | geometry unchanged on press and focus |
| Focus-visible gate | `mx_card_interaction_test.dart:266` | **`MxCard` only** |
| Real ink, not a property | `ink_probe.dart` + `mx_card_interaction_test.dart:83`, `mx_list_tile_test.dart:150` | hover paints and *unpaints*, on a real mouse |
| Ring appears / disappears | `mx_pill_button_focus_test.dart` | via a real `Tab`, because `MxFocusRing` is `skipTraversal` |
| Selected ≠ hover | `mx_list_tile_test.dart:206` | the pointer leaving does not deselect |

The `ink_probe.dart` approach — drive a real pointer, then read the paint
commands off `_RenderInkFeatures` — is the right instrument and already exists.
Every closure test in §11 that needs a pixel should use it rather than asserting
a property.

### 12.2 Gaps, ordered by what they would have caught

1. **No combined state involving a transient one.** `m3_combined_state_test.dart`
   covers `{selected, focused}` and `{disabled, selected}` and stops. Missing:
   `{selected, hovered}`, `{selected, pressed}`, `{disabled, focused}`,
   `{disabled, hovered}`, `{error, focused}`, `{error, disabled}`. P2-3 lives in
   the last of those.
2. **No focus-visible gate outside `MxCard`.** P1-1.
3. **No test asserts a state is painted exactly once.** Every existing ink test
   asks "did it paint X"; none asks "did it paint X twice". P1-3 and P2-1 both
   live in that gap, and `ink_probe.dart` would need one addition — a
   *count* of layers painting a colour rather than a boolean.
4. **No golden shoots a non-resting state.** `mx_pill_button_focus_test.dart:11-13`
   says so in its own header, and `grep -l focus test/demo/*.dart` confirms it:
   152 committed PNGs, all at rest. Widgetbook has `isEnabled` knobs and one
   `shouldAutofocus` (`control_components.dart:106`), which is the only rendered
   focus state anywhere in the project.
5. **No reduced-motion test.** P2-8.
6. **No motion guard.** P2-7.
7. **No focus-indicator scope test.** Nothing enumerates the interactive
   components and requires each to have an indicator, so P0-1 and P1-2 were both
   invisible to a green suite.

---

## 13. Implementation order

Sequenced so each step is independently reviewable and no step depends on a
decision a later step makes.

| Step | Findings | Files | Why here |
|---|---|---|---|
| **1** | P0-1 | `lib/shared/widgets/mx_breadcrumb.dart` + new focus test | A total absence of a focus indicator on a shipped control. One widget, no decision to take — `MxBreadcrumbStep` next to it already shows the answer for this geometry |
| **2** | P1-2 | `lib/shared/widgets/mx_pressable.dart` (+ a `MxPressableShape`-shaped way to select an overlay weight), `mx_checkbox_row.dart`, `mx_switch_row.dart`, `mx_radio_rows.dart`, `mx_dropdown.dart`, `mx_fab.dart` | The largest accessibility surface, and the fix is additive: nothing that renders today changes at rest |
| **3** | P2-1, P3-5 | `app_fab_theme.dart`, `mx_list_tile.dart` | The two "one layer is unowned" cases. Small, mechanical, and both fall out of the §5.1 baseline being written down |
| **4** | **P1-1** | `mx_list_tile.dart`, `mx_focus_ring.dart`, `mx_breadcrumb_step.dart`, `app_icon_button_theme.dart`, `app_button_themes.dart`, `app_chip_theme.dart` | After steps 1–2, because those add indicators and this decides when *every* indicator shows. Needs one shared piece first: a `focus-visible` listener that is not copy-pasted from `mx_card.dart` five times — the natural home is `MxFocusRing`, extended to answer the question for the `side:`-based painters too |
| **5** | **P1-3** | `mx_pill_button.dart` or `app_chip_theme.dart` | Owner decision required (§11 P1-3 options a/b). Last of the P1s because it is the only one that changes a rendered pixel at a state a golden could shoot |
| **6** | P2-2 | `mx_pill_button.dart` / `mx_focus_ring.dart` | Depends on step 5: if the pill's fill treatment changes, the ring's ground changes with it |
| **7** | P2-3, P2-4, P2-5, P2-6 | `mx_text_field.dart` + a design-system note; `app_stroke.dart`; `mx_breadcrumb.dart`; `app_navigation_bar_theme.dart` | Independent of everything above; can run in any order or in parallel |
| **8** | P2-7, P2-8 | `test/design_audit/`, `test/core/theme/foundations/` | The guards, added once the thing they guard has stopped moving |
| **9** | P3-1, P3-2, P3-3, P3-4, P3-6, P3-7 | doc comments only, plus one `didChangeDependencies` move | Documentation accuracy, batched |

### 13.1 Decisions the owner has to take, not the implementer

1. **P1-3 option (a) or (b)** — suppress the chip's overlay and keep the
   composited fill, or move the transient states into an overlay and accept a
   translucent layer over a known ground. Recommendation: **(a)**, because R7's
   "no paint over an unknown ground" property is the reason `_fillFor` exists,
   and (b) trades a live defect for a rule violation.
2. **P2-3** — does a disabled field with an error message draw the error border
   or the disabled one? Recommendation: **disabled wins**, matching every other
   resolver in the app, implemented by not passing `errorText` when
   `isEnabled: false` rather than by fighting `InputDecorator`.
3. **P2-6** — is the navigation bar's lighter press a decision or an accident?
   Recommendation: declare `controlOverlay` and let it match everything else.

### 13.2 Two things the implementation must not do

- **Do not unify the focus painters.** §6.1: four geometries, four painters, one
  contract. `MxFocusRing` applied to a button would double its stroke; applied to
  a text link it would trace the glyphs; applied to a checkbox it would repeat
  M100.21's inset.
- **Do not consolidate the hold durations into `AppDurations`.**
  `match_tile_widget.dart:300-315` already records why that was wrong once: a
  hold is a legibility budget, and borrowing the motion scale's top rung put it
  at a third of what it needed.

---

## 14. What this audit did not reach

- **Any rendered pixel.** No Flutter SDK in this container. Every composite-alpha
  figure is arithmetic on declared constants; every contrast figure is quoted
  from an existing file that measured it. The closure tests in §11 are the ones
  that would turn these into measurements.
- **Android device behaviour.** `InkSparkle`, the real `FocusHighlightMode`
  transitions on a phone with a keyboard attached, and TalkBack's interaction
  with focus were not exercised.
- **Route and page transitions.** `pageTransitionsTheme` is left at Material's
  default for the pinned `TargetPlatform.android` (`app_theme.dart:166-171`) and
  was not audited; it is motion the app authors none of.
- **`lib/features/**` beyond the six widgets that animate and the four that build
  their own interactive surfaces.** The feature layer was scanned for
  `Animated*`, `InkWell`, `GestureDetector`, `MouseRegion`, `FocusNode` and
  `Duration`, and each hit is accounted for above; it was not read line by line.
