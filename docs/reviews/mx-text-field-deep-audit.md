# MxTextField / input system — deep audit

| | |
|---|---|
| Base commit | `4cfddd3d` (`main`) — *the screen gallery is drawn as a proof sheet* (M100.34) |
| Pinned SDK | Flutter **3.44.8** stable · framework `058e0af2c2` · Dart 3.12.2 |
| Scope | Every text-input surface under `lib/`, its `InputDecorationTheme`, its Widgetbook stories and its tests |
| Mode | **Report only.** No production, theme, test, Widgetbook or design-system file was changed; no golden was regenerated |
| Method | Flutter source read at the pinned SDK (`input_decorator.dart`, `text_field.dart`), plus a throwaway measurement suite run against the real themes and deleted before commit |

Every number in this report was **measured**, not recalled. The measurement
harness pumped `MxTextField` and `MxSearchField` in `buildLightTheme()` /
`buildDarkTheme()` at 320 / 360 / 375 / 393 dp and `textScaler` 1.0 / 1.3 / 2.0 /
2.5 / 3.0, and read sizes, rects, resolved styles and semantics nodes off the
tree. It lived at `test/zz_audit_measure_tmp_test.dart` for the duration of the
audit and was deleted; `git status` was verified clean afterwards. Contrast
ratios were computed from the palette constants with the WCAG 2.x relative
luminance formula.

---

## 1 · Executive verdict

**The form input is in good shape and is very close to canonical M3-outlined.
The search field is not, and it is the one place where an app-specific surface
token has quietly replaced a canonical input role.** Nothing here is a
correctness bug; the P1s are accessibility and state-feedback holes that the
current gate cannot see.

What is genuinely right, and should not be touched by the next pass:

- `InputDecorationTheme` is a **canonical outlined** M3 recipe. `filled: false`,
  five hand-declared `OutlineInputBorder`s, every colour a `ColorScheme` role.
- The resting border is bound to `scheme.outline` (= `borderControl`) precisely
  because the edge *is* the component boundary, and
  `control_border_grounds_test.dart` already enforces 3:1 on three grounds. The
  post-#429 `surface` page did **not** weaken it: measured **4.40:1** light and
  **4.68:1** dark against the page.
- `MxTextField` takes no `Color`, no `InputDecoration` and no radius. There is
  exactly **one** visual escape hatch (`textStyle`), it has one caller, and that
  caller passes a theme rung rather than a literal.
- The field is **48.0 dp** tall at `textScaler` 1.0 — the touch floor exactly —
  and grows 55 / 72 / 84 / 96 at 1.3 / 2.0 / 2.5 / 3.0.
- There is exactly **one** raw `TextField` under `lib/features/`, and it is a
  legitimate framework-level special case with the argument written down beside
  it. Zero `TextFormField`, zero `Form`, zero `validator:` in the repository.

What the next pass has to fix:

| # | Finding | Sev |
|---|---|---|
| F1 | `MxSearchField` has **no accessible name** once it holds a value | **P1** |
| F2 | `MxSearchField`'s box is pinned at 48 dp and **ignores `textScaler`** | **P1** |
| F3 | **Focus is invisible on an errored field** — `focusedErrorBorder` is byte-identical to `errorBorder` and the stroke never moves | **P1** |
| F4 | The suffix icon **does not follow the error state** — `IconButtonTheme` wins over `defaults.suffixIconColor` | P2 |
| F5 | An arriving error **shifts layout 20 dp** on any field without `maxLength` | P2 |
| F6 | The hint is one type rung **below** the value it is replaced by (14 vs 16) | P2 |
| F7 | No `inputFormatters` on the API — a `TextInputType.number` field accepts `"abc-12.5"` | P2 |
| F8 | `isReadOnly` has **no visual cue** — identical ink to enabled | P3 |
| F9 | The custom counter loses `semanticCounterText` and never turns error-coloured | P3 |
| F10 | Effective horizontal text inset is **20 dp**, not the 16 the token names | P3 |
| F11 | The kit's `.mx-field__input` still names retired tokens (`border-subtle`, `focus-ring`) | P3 |

And the coverage holes that let F3, F4 and F5 exist unnoticed:

| # | Gap | Sev |
|---|---|---|
| G1 | `TextField` is absent from `m3_role_bindings.dart` (24 bindings, 11 components) | P2 |
| G2 | `TextField` is absent from `m3_combined_state_test.dart` — the file that exists for exactly this class of bug | **P1** |
| G3 | `focusedErrorBorder` and `disabledBorder` are unpinned in `m3_role_contract_test.dart` | P2 |
| G4 | No golden and no test covers `focused + error`, `suffix + error`, or multiline | P2 |
| G5 | Widgetbook has one `Playground` use case; `minLines`/`maxLines` are not knobbed, so multiline is unreachable in the catalog | P3 |

---

## 2 · Current input architecture

```
TextField (Material)                     ← 3 implementations under lib/
  └ InputDecorator                       ← reads InputDecorationTheme
      └ _InputDecoratorDefaultsM3        ← fills every slot MemoX leaves null

lib/core/theme/components/inputs/
  app_input_theme.dart          buildInputDecorationTheme(scheme, semantic, texts)
  app_text_selection_theme.dart buildTextSelectionTheme(scheme)
        ↑ wired at lib/core/theme/app_theme.dart:255 and :272

lib/shared/widgets/
  mx_text_field.dart      MxTextField        ← the form control
  mx_search_field.dart    MxSearchField      ← its own composition, bypasses the theme

lib/features/study/.../fill_answer_pieces_widget.dart
  _FillInput              raw TextField      ← every border state explicitly off
```

### 2.1 · The three primitives, classified

The brief asked whether these are (A) one component with variants, (B) genuinely
different components, or (C) duplicates that should converge. The answer is
different for each, and none of them is (C).

| Primitive | Verdict | Evidence |
|---|---|---|
| `MxTextField` | **(A)** one component, three semantic variants: label placement (`floating` / `external`), line count (`minLines`/`maxLines`), and an optional typed trailing action | 13 call sites, all reachable through the same closed API; no caller needs a decoration |
| `MxSearchField` | **(B)** genuinely different | No label at all, pill radius, *filled* model, `TextInputAction.search`, a result-count slot and a clear button. None of that is expressible through `InputDecoration` without opening `MxTextField` to a decoration — which is the one thing it exists to refuse |
| `_FillInput` | **(B)**, and correctly private | The study card *is* the field: `expands: true`, all six border states off, `isCollapsed`, zero content padding. Its docstring already argues the case and it is unreachable from outside its file |

**There is no duplication to converge.** Three implementations, three distinct
reasons, all documented in situ.

### 2.2 · What does *not* exist, and should stay that way

Confirmed by exhaustive grep over `lib/`: **zero** `TextFormField`, **zero**
`Form(`, **zero** `validator:`, **zero** `obscureText`, **zero**
`autofillHints`, **zero** `inputFormatters`. There is no password field and no
login screen, which is AD-08 holding. Validation runs in the domain (value
objects with private constructors) → controller state → a localized
`errorText` string handed to the widget. That is the right shape and the next
pass must not introduce `Form`/`validator` to "fix" anything below.

---

## 3 · Flutter 3.44.8 canonical role/state matrix

Read from `packages/flutter/lib/src/material/input_decorator.dart`
`_InputDecoratorDefaultsM3` (lines 5936–6104) and
`packages/flutter/lib/src/material/text_field.dart` (`_m3StateInputStyle` :1886, `_m3InputStyle` :1893, `_m3CounterErrorStyle` :1895, cursor
block at :1636–1642).

### 3.1 · The resolver's state set and its documented precedence

```dart
// input_decorator.dart:2251-2256
Set<WidgetState> get widgetState => <WidgetState>{
  if (!decoration.enabled) WidgetState.disabled,
  if (isFocused)           WidgetState.focused,
  if (isHovering)          WidgetState.hovered,
  if (_hasError)           WidgetState.error,
};
```

Flutter states its own precedence rule in a comment at `input_decorator.dart`
5945–5953, and it is the **opposite** of every other Material widget:

> For `InputDecorator`, **focused state should take precedence over hovered
> state** … For other widgets, hovered takes precedence over focused.

Inside each resolver the branch order is fixed and identical across
`outlineBorder`, `activeIndicatorBorder`, `labelStyle` and `floatingLabelStyle`:

`disabled` → `error` (→ `focused` → `hovered` → plain) → `focused` → `hovered` → resting.

So canonically: **disabled beats error beats focus beats hover.**

### 3.2 · The one place that inverts it — the painted border

`input_decorator.dart:2362-2370` picks the *explicit* per-state border **before**
any resolver runs:

```dart
InputBorder? border;
if (!decoration.enabled) {
  border = _hasError ? decoration.errorBorder : decoration.disabledBorder;   // error wins
} else if (isFocused) {
  border = _hasError ? decoration.focusedErrorBorder : decoration.focusedBorder;
} else {
  border = _hasError ? decoration.errorBorder : decoration.enabledBorder;
}
border ??= _getDefaultBorder(themeData, defaults);
```

**Inside the disabled branch, error wins.** A disabled field carrying an
`errorText` paints the full-strength `errorBorder`, not `disabledBorder`. That
is canonical Flutter, and MemoX inherits it (§6.3).

Note also the consequence for MemoX: because the theme supplies all five
borders, `_getDefaultBorder` is **never reached**, so `outlineBorder`'s
`hovered` branch and its focused `width: 2.0` never apply. That is deliberate
and correct for a mobile app — see §7.

### 3.3 · Canonical slot table

`0.38` / `0.12` / `0.04` below are `withOpacity` over the named role.

| Slot | resting | hover | focused | error | focused + error | disabled | Source |
|---|---|---|---|---|---|---|---|
| `fillColor` | `surfaceContainerHighest` | — | — | — | — | `onSurface` @ .04 | `input_decorator.dart:5964-5970` |
| `outlineBorder` (unfilled) | `outline` @ 1.0 | `onSurface` @ 1.0 | `primary` @ **2.0** | `error` @ 1.0 | `error` @ **2.0** | `onSurface` @ .12 | `:5995-6016` |
| `activeIndicatorBorder` (filled) | `onSurfaceVariant` | `onSurface` | `primary` @ **2.0** | `error` | `error` @ **2.0** | `onSurface` @ .38 | `:5972-5993` |
| hover under error | — | `onErrorContainer` | — | — | — | — | `:6005-6007` |
| `iconColor` | `onSurfaceVariant` | = | = | = | = | = (no state resolver) | `:6018` |
| `prefixIconColor` | `onSurfaceVariant` | = | = | = | = | `onSurface` @ .38 | `:6021-6027` |
| `suffixIconColor` | `onSurfaceVariant` | `onErrorContainer` *(only under error)* | `onSurfaceVariant` | **`error`** | **`error`** | `onSurface` @ .38 | `:6029-6041` |
| `labelStyle` | `bodyLarge`/`onSurfaceVariant` | `onSurfaceVariant` | `primary` | `error` | `error` | `onSurface` @ .38 | `:6043-6065` |
| `floatingLabelStyle` | identical branch set to `labelStyle` | | `primary` | `error` | `error` | `onSurface` @ .38 | `:6067-6089` |
| `hintStyle` | `onSurfaceVariant` (size from `bodyLarge`, see below) | = | = | = | = | `onSurface` @ .38 | `:5956-5962` |
| `helperStyle` | `bodySmall`/`onSurfaceVariant` | = | = | = | = | `onSurface` @ .38 | `:6091-6098` |
| `errorStyle` | `bodySmall`/`error` — **no state branches at all** | | | | | | `:6100-6103` |
| `counterStyle` | *(not defined in the M3 defaults)* — falls to `helperStyle`; `TextField` swaps it to `bodySmall`/`error` when `maxLength` is exceeded | | | | | | `text_field.dart:1256-1266`, `:1895-1896` |
| input `style` | `bodyLarge` | = | = | = | = | `bodyLarge.color` @ .38 | `text_field.dart:1886-1891` |
| `cursorColor` | `DefaultSelectionStyle.cursorColor ?? primary` | = | = | **`cursorErrorColor ?? errorStyle.color ?? error`** | same | n/a | `text_field.dart:1637-1642`, `:1199-1202` |
| `selectionColor` | `primary` @ .40 | = | = | = | = | n/a | `text_field.dart:1640-1641` |

Two mechanics worth stating because they surprise people:

- **`hintStyle`'s size does not come from `hintStyle`.** `_getInlineHintStyle`
  (`:2199-2210`) starts from `textTheme.bodyLarge`, then merges the theme's
  `hintStyle` over it — so a theme `hintStyle` carrying a `fontSize` *replaces*
  the canonical 16. MemoX's does (§13).
- **`errorText` reaches semantics as `Semantics(hint:)`**
  (`input_decorator.dart:2692-2694`), and the error subtext is separately
  wrapped `Semantics(container: true, liveRegion: !MediaQuery.supportsAnnounceOf(context))`
  (`:415-419`). Error announcement is handled by the framework; MemoX inherits
  it and it works (§18).

### 3.4 · Canonical geometry, for comparison

| | M3 outlined, non-dense | MemoX |
|---|---|---|
| `contentPadding` | `fromSTEB(12, 20, 12, 12)` (`:2630-2636`) | `symmetric(h: 16, v: 12)` |
| extra horizontal `inputGap` | `OutlineInputBorder.gapPadding` = **4.0** on each side (`:2639-2645`) | inherited — see F10 |
| resulting field height @ 1.0 | 56 | **48.0** (measured) |

MemoX's 48 is the touch floor exactly, and the 8 dp it gives up against M3's 56
is bought back nowhere else. This is a deliberate, correct mobile adaptation and
should not be "corrected" toward 56.

---

## 4 · MemoX current role/state matrix

Source: `lib/core/theme/components/inputs/app_input_theme.dart` and
`app_text_selection_theme.dart`. Everything MemoX leaves `null` resolves through
`_InputDecoratorDefaultsM3`, so the "canonical" rows below are live behaviour,
not aspiration.

`⬤` = MemoX states it · `○` = falls through to the M3 default · `⚠` = diverges

| Slot | State | MemoX value | Canonical role | Match? |
|---|---|---|---|---|
| `filled` | all | `false` | n/a — outlined | ⬤ canonical outlined |
| `border` | base | `outline` @ 1.5, `radius 12` | `outline` @ 1.0 | ⬤ role ✓, **width 1.5 by house rule** |
| `enabledBorder` | resting | `scheme.outline` @ 1.5 | `outline` | ⬤ ✓ |
| `enabledBorder` | hover | *unreachable* | `onSurface` | ⬤ deliberately dropped (mobile) |
| `focusedBorder` | focused | `scheme.primary` @ **1.5** | `primary` @ **2.0** | ⬤ role ✓, **width intentionally frozen** |
| `errorBorder` | error, unfocused | `scheme.error` @ 1.5 | `error` @ 1.0 | ⬤ ✓ |
| `focusedErrorBorder` | error + focused | `scheme.error` @ 1.5 | `error` @ **2.0** | ⚠ **byte-identical to `errorBorder`** → F3 |
| `disabledBorder` | disabled | `alphaBlend(outline @ .5, surfaceContainerLow)` | `onSurface` @ .12 | ⚠ app blend, not a role — see §5.4 |
| `disabled + error` | | `errorBorder` (framework picks it) | `errorBorder` | ⬤ ✓ canonical |
| `hintStyle` | all | `bodyMedium` + `onSurfaceVariant` | `bodyLarge` size + `onSurfaceVariant` | ⚠ colour ✓, **size 14 vs 16** → F6 |
| `hintStyle` | disabled | `onSurfaceVariant` (state branch lost) | `onSurface` @ .38 | ⚠ a stated `hintStyle` has no state resolver, so a disabled empty field's placeholder stays full strength |
| `labelStyle` | every state | ○ | `onSurfaceVariant` / `primary` / `error` / `.38` | ○ canonical |
| `floatingLabelStyle` | every state | ○ | as above | ○ canonical |
| `helperStyle` | every state | ○ | `bodySmall`/`onSurfaceVariant`, `.38` disabled | ○ canonical — measured `.38` at disabled |
| `errorStyle` | all | ○ | `bodySmall`/`error` | ○ canonical |
| `counterStyle` | all | ○ but **overridden by `buildCounter`** | `bodySmall`/`onSurfaceVariant`, `error` on overflow | ⚠ see F9 |
| `iconColor` | all | ○ | `onSurfaceVariant` | ○ (no `icon:` caller exists) |
| `prefixIconColor` | all | ○ | `onSurfaceVariant` / `.38` | ○ (no `prefixIcon` caller exists) |
| `suffixIconColor` | rest | ○ → measured `onSurfaceVariant` | `onSurfaceVariant` | ○ ✓ |
| `suffixIconColor` | **error** | ○ → measured **`onSurfaceVariant`** | **`error`** | ⚠ **F4** |
| `suffixIconColor` | disabled | ○ → measured `onSurface` @ .38 | `onSurface` @ .38 | ○ ✓ |
| input `style` | enabled | ○ → measured `bodyLarge` 16/1.5, `onSurface` | `bodyLarge` | ○ ✓ |
| input `style` | disabled | ○ → measured `onSurface` @ .3804 | `.38` | ○ ✓ |
| `cursorColor` | non-error | `scheme.primary` (via `TextSelectionThemeData`) | `primary` | ⬤ ✓ |
| `cursorColor` | error | `scheme.error` (framework overrides) | `error` | ○ ✓ |
| `selectionColor` | all | `primary` @ **0.24** | `primary` @ **0.40** | ⬤ deliberate — documented as "the default is too light on a tinted card" |
| `selectionHandleColor` | all | `scheme.primary` | `primary` | ⬤ ✓ |
| `contentPadding` | all | `symmetric(16, 12)` | `(12, 20, 12, 12)` | ⬤ deliberate — 48 dp touch floor |

### 4.1 · MxSearchField — outside the matrix entirely

`MxSearchField` builds an `AnimatedContainer` and passes
`InputBorder.none` / `isCollapsed: true` / `contentPadding: zero` to its inner
`TextField`. **It reads no input role at all.**

| Slot | Resting | Focused | Canonical input role it stands in for |
|---|---|---|---|
| fill | `semantic.surfaceMuted` | `colors.surface` | `fillColor` → `surfaceContainerHighest` |
| border | `semantic.surfaceMuted` (self-coloured, invisible) | `colors.primary` | `outlineBorder` / `activeIndicatorBorder` |
| radius | `AppRadius.pill` (999) | = | `AppRadius.md` (12) elsewhere |
| stroke | `Border.all` default 1.0, `strokeAlignOutside` | = | `AppStroke.input` (1.5) elsewhere |
| text | `context.texts.bodyMedium` | = | `bodyLarge` |
| hint | theme `hintStyle` (bodyMedium) | = | ✓ the one thing it shares |

This is the direct answer to the brief's §4 question *"is any app-specific
surface token substituting for a canonical input role?"* — **yes, in
`MxSearchField`, and only there.** `semantic.surfaceMuted` does the job of
`fillColor` and of the resting border at once. Whether that is a defect is an
owner call (Q3, §22): the pill's *identity* is arguably carried by the magnifier
glyph and the placeholder rather than by its edge, which is the WCAG 1.4.11
exemption. Measured, the pill's fill is **1.09:1** against the light page and
**1.34:1** against the dark one, so the edge contributes nothing.

---

## 5 · Border system audit

### 5.1 · Measured state table

Read off `buildLightTheme().inputDecorationTheme`:

| State | Colour | Width | Radius | Contrast vs page | vs card (`surfaceContainerLow`) | vs dialog (`surfaceContainerHigh`) |
|---|---|---|---|---|---|---|
| resting | `outline` `#6F727B` L / `#747BA3` D | 1.5 | 12 | **4.40** L · **4.68** D | 4.81 L · 4.30 D | 4.02 L · 3.50 D |
| focused | `primary` `#4454CC` L / `#BCC2FF` D | 1.5 | 12 | 5.67 L · 11.27 D | 6.20 L · 10.37 D | 5.19 L · 8.43 D |
| error | `error` `#CD0031` L / `#FF768F` D | 1.5 | 12 | 5.28 L · 7.55 D | 5.77 L · 6.95 D | 4.83 L · 5.65 D |
| focused + error | **identical to error** | 1.5 | 12 | — | — | — |
| disabled | `#B7B8BD` L / `#42486B` D (blended) | 1.5 | 12 | 1.81 L · 2.17 D | 1.98 L · 2.00 D | — |

### 5.2 · Which boundary must clear 3:1

The brief is right to warn against porting the Card rule here, and the codebase
already makes the distinction explicitly. `control_border_grounds_test.dart`
states it:

> a card is identified by its content and its edge is decoration, which is the
> exemption WCAG grants … An outlined button and an empty text field are **not**
> identified by their content — the edge *is* the component boundary.

So the floors that are actually owed:

| Boundary | 3:1 owed? | Why | Status |
|---|---|---|---|
| **resting** | **yes** — WCAG 1.4.11 | an empty field with a placeholder is identified by its edge alone | ✅ 4.40 / 4.68, and **enforced** by `control_border_grounds_test.dart` on page / `surface` / `surfaceContainer` |
| **focused** | **yes** — 1.4.11 (and 2.4.11 for focus appearance) | it is the entire focus indicator; the stroke never changes width | ✅ ≥5.19 everywhere, **enforced** by `app_theme_test.dart` "the focus ring is visible on every surface a field can sit on" |
| **error** | *not strictly* | error is never colour-alone here — `errorText` is required to enter the state | ✅ ≥4.83 anyway, **not enforced** anywhere |
| **focused + error** | yes, same as focused | | ⚠ passes on contrast, **fails on discriminability** — F3 |
| **disabled** | **no** | WCAG exempts inactive components | n/a at 1.81–2.17 |

Two grounds a field is actually drawn on are **missing** from
`control_border_grounds_test.dart`'s list: `surfaceContainerLow` (the bottom
sheet that holds `deck_form_widget` and `tag_rename_widget`) and
`surfaceContainerHigh` (the `MxFormDialog` background). Both pass — 4.81 / 4.30
and 4.02 / 3.50 — so this is a gap in the guard, not a defect in the palette.
Dark-on-dialog at **3.50** is the thinnest margin in the table and is the one to
watch when the palette next moves.

### 5.3 · Stroke width and state precedence — F3

`AppStroke.input = 1.5` in every state is a deliberate house rule with a written
reason: Material's 1 → 2 jump nudges whatever is laid out beside the field.
That reason is sound and `app_theme_test.dart` pins it.

**But the rule was applied without noticing what M3 was using the width jump
for.** In canonical M3 the border carries two independent signals at once:

- *hue* says **what kind of state** (neutral / accent / error),
- *width* says **whether the field has focus**.

MemoX kept the hue channel and dropped the width channel, then set
`focusedErrorBorder` and `errorBorder` to the same colour. The two channels
therefore collapse:

```dart
errorBorder:        _inputBorder(scheme.error),
focusedErrorBorder: _inputBorder(scheme.error),   // same colour, same width
```

Measured: `focusedErrorBorder.borderSide == errorBorder.borderSide` → **`true`**.

**Consequence: an errored field gives no border feedback whatsoever when it
gains focus.** The only remaining cue is the caret — which is itself recoloured
to `scheme.error` by `text_field.dart:1637-1642`, so it is not even a
*different* colour from the border. In the two fields most likely to be in this
state (`settings_study_defaults` and `study_options` card-limit, which show
"enter 1–500"), a sighted user tapping the field to correct it gets no
acknowledgement that the tap landed.

This is not a colour problem — both states measure ≥4.83:1. It is a **missing
channel**, and it needs a *third* signal that is neither hue nor width. Options
are laid out in §20; the decision is the owner's (Q1).

### 5.4 · `disabledBorder` is the one non-role value in the theme

```dart
disabledBorder: _inputBorder(
  Color.alphaBlend(scheme.outline.withValues(alpha: 0.5), scheme.surfaceContainerLow),
),
```

Solid rather than translucent, per MX-VIS-002 R7 — correct, and the comment
explains why the blend base is the *surface* and not `disabledSurface`. Two
observations, neither urgent:

- The blend base is hardcoded to `surfaceContainerLow` (white / `#111633`). A
  disabled field on the **page** (`#F2F5F9`) or in a **dialog** (`#E9EBEE`) is
  blended against the wrong ground. Measured drift is small (1.98 → 1.81 on the
  page) and disabled is contrast-exempt, so this is cosmetic.
- It is the only slot in `app_input_theme.dart` that cannot be pinned to a role,
  which is exactly why it is missing from `m3_role_contract_test.dart` (G3). The
  canonical M3 value is `onSurface @ 0.12`; MemoX's is visibly stronger. That is
  a defensible choice for a field whose whole identity is its edge, but it is
  undocumented.

---

## 6 · State precedence — the resolver matrix

### 6.1 · What MemoX actually resolves

Built by reading the framework's selection block (§3.2) against MemoX's declared
borders. `→` marks the branch the framework takes.

| Combination | Framework branch | Painted border | Label ink | Suffix icon | Correct? |
|---|---|---|---|---|---|
| rest | `else` → `enabledBorder` | `outline` | `onSurfaceVariant` | `onSurfaceVariant` | ✅ |
| hover | `else` → `enabledBorder` | `outline` (unchanged) | `onSurfaceVariant` | `onSurfaceVariant` | ✅ mobile-correct |
| focus | `isFocused` → `focusedBorder` | `primary` | `primary` | `onSurfaceVariant` | ✅ |
| error | `else` + `_hasError` → `errorBorder` | `error` | `error` | ⚠ `onSurfaceVariant` (F4) | ⚠ |
| **focus + error** | `isFocused` + `_hasError` → `focusedErrorBorder` | `error` | `error` | ⚠ `onSurfaceVariant` | ⚠ **F3** — indistinguishable from `error` |
| focus + hover | `isFocused` first | `primary` | `primary` | — | ✅ matches the SDK's stated precedence |
| disabled | `!enabled` → `disabledBorder` | blended | `.38` | `.38` | ✅ |
| **disabled + error** | `!enabled` + `_hasError` → **`errorBorder`** | **full-strength `error`** | `.38` | `.38` | ✅ canonical, but see below |
| disabled + focus | unreachable — `enabled: false` removes the node from the focus order | — | — | — | ✅ |

### 6.2 · Does MemoX's order match canonical intent?

**Yes.** MemoX declares no `WidgetStateProperty` of its own for any input slot,
so every precedence decision is the framework's. There is no MemoX resolver to
get wrong here — which is a real strength of the current design and the reason
none of the classic inversions (focus over error, hover over focus, disabled
still showing an active accent) can occur.

The three specific inversions the brief asked about:

- *focus wins over error* — **no.** `focusedErrorBorder` is selected, and its
  colour is `error`. Error's hue wins, which is canonical.
- *error wins over disabled* — **yes**, and that is canonical Flutter
  (`input_decorator.dart:2364`). It is worth knowing, because a busy form that
  disables its fields during submit while an error is still on screen will paint
  a full-strength red outline on a greyed-out field. Reachable today:
  `deck_form_widget` and `tag_rename_widget` both set
  `isEnabled: !isSubmitting` while `errorText` may still be non-null. Nothing
  screenshots it.
- *hover overwrites focus* — **no.** The theme's explicit borders mean the hover
  branch is never reached at all.

### 6.3 · Combined-state coverage — G2

`test/core/theme/contracts/m3_combined_state_test.dart` exists for precisely
this class of bug. Its own docstring says so:

> This file asks `{}` and `{selected}` only, which is the answer a resolver
> gives last — the failures were all in `{selected, focused}`, where a `focused`
> branch sat above the `selected` one.

It covers `ChoiceChip`, `Switch`, `SegmentedButton`, `Checkbox`,
`OutlinedButton`, `NavigationBar` and a cross-cutting "disabled does not leak a
live role" group. **`TextField` is not in it** — and `TextField` is the only
component in the app whose theme declares five state borders by hand. F3 is
exactly the bug that file was written to catch, in the one component it skips.

`m3_role_bindings.dart` has the same hole (G1): 24 bindings over 11 components —
`AppBar`, `Card`, `Checkbox`, `ChoiceChip`, `FloatingActionButton`,
`NavigationBar`, `OutlinedButton`, `SegmentedButton`, `Switch`, `TabBar`,
`TextButton` — and no `TextField`. So `app_input_theme.dart` is the one
component theme whose *named* roles nothing parses.

---

## 7 · Focus architecture

**MemoX is compliant with the rule the brief states, and no external focus ring
should be added.**

| Mechanism | Used by `MxTextField`? | Verdict |
|---|---|---|
| canonical `focusedBorder` slot | **yes** — `scheme.primary` @ 1.5 | ✅ correct channel |
| fill / state layer | no — `filled: false` and no overlay | ✅ correct for an outlined field |
| external `MxFocusRing` | **no** | ✅ correct — `InputDecorator` owns a canonical focus channel, so wrapping one would be a second indicator |
| multiple mechanisms at once | no | ✅ |

`MxSearchField` also expresses focus through its own border and fill and does
**not** stack a ring on top. Its focus is `colors.primary` on a border that is
transparent-by-fill at rest, which is the same one-channel discipline. It is
tested (`mx_search_field_test.dart` — "the border is there at rest, so focus
costs no layout").

**The one hole is F3**, and it is not an argument for an external ring: the
answer is to make the *existing* `focusedErrorBorder` slot say something
different from `errorBorder`, not to add a second indicator on top of it. §20
lists the candidates.

One thing worth recording for the next pass: `AppStroke.focus = 2` exists and is
used by the icon button, the outlined button, the tappable card and the text
button's underline. `AppStroke.input = 1.5` is a *separate* constant with a
separate docstring. Whatever fixes F3 must not quietly merge them — the
docstring on `AppStroke.selectionControl` already records that "it happens to
equal `focus`. That is a coincidence, not a relationship."

---

## 8 · Error architecture

### 8.1 · End to end

```
domain value object (DeckName, TagName, CardText…)  ← the rule lives here
      ↓ ValidationProblem enum
controller state (…Problem field)
      ↓ context.<x>Error(problem)  → localized ARB string
MxTextField.errorText: String?
      ↓ InputDecoration.errorText  + errorMaxLines: 3
InputDecorator → errorBorder / errorStyle / Semantics(hint:) / liveRegion subtext
```

This is a clean chain and it does several things right that are easy to get
wrong:

- **The state is carried by real text, not a boolean.** `errorText: String?`
  makes it structurally impossible to enter the error state without a message.
  Colour is therefore never the only cue — WCAG 1.4.1 satisfied *by
  construction*, and `mx_form_components_test.dart` asserts it.
- **`errorMaxLines: 3` is app-wide and not a parameter**, with the reasoning
  written down (`_maxMessageLines`). Correct call — a per-caller option would
  have left every existing field on Material's truncating default.
- **Features never bypass shared input styling for errors.** All 11 of the 13
  call sites that pass `errorText` pass a localized string from an ARB key.

### 8.2 · Role check — no `semantic.danger` leakage into the input

Grepped: `app_input_theme.dart` reads `scheme.error` only. No
`semantic.danger`, no `AppInk.danger`, no hardcoded red, no literal border
colour anywhere in the input stack. `scheme.error` is bound to
`AppColors.danger*` at the *palette* level (`app_color_scheme.dart` — "`error`
is `danger`, not a second red system"), which is the right place for that
identity to live.

Two feature files paint error *text* with `AppInk.danger` rather than
`scheme.error` — `deck_form_widget.dart:141` and
`card_create_form_widget.dart:144` — but both are **form-level failure banners
outside the field**, not the Material input slot. That is a different component
and it is out of scope for this audit.

### 8.3 · What is missing

- **F3** — focus is invisible under error (§5.3).
- **F4** — the trailing action icon stays neutral while the border is red
  (§12). The most visible instance is the tag-add field: the border goes red,
  the `+` beside it does not.
- **F5** — the error's *arrival* moves the page (§9.4).
- No **error icon** exists in the design and none is expected; the brief's
  "error icon role if any" resolves to *none*, correctly.
- `disabled + error` paints a full red outline on a greyed field (§6.2). Nothing
  in the repo screenshots or asserts it, and two overlays can produce it.

---

## 9 · Mobile-first geometry audit

All figures measured, `devicePixelRatio: 1`, real themes.

### 9.1 · Field height — every width, every scale

| `textScaler` | 320 dp | 360 dp | 375 dp | 393 dp |
|---|---|---|---|---|
| 1.0 | **48.0** | 48.0 | 48.0 | 48.0 |
| 1.3 | 55.0 | 55.0 | 55.0 | 55.0 |
| 2.0 | 72.0 | 72.0 | 72.0 | 72.0 |
| 2.5 | 84.0 | — | — | — |
| 3.0 | 96.0 | — | — | — |

Width has **zero** effect on height, which is correct for a stretched field.
48.0 at 1.0 is the Android touch floor exactly, with no slack — which is why
`contentPadding` is `12` vertical rather than M3's `20/12`.

### 9.2 · Inner metrics at `textScaler` 1.0

| Metric | Measured | Token | Note |
|---|---|---|---|
| decorator box | 48.0 tall | — | |
| editable line box | 24.0 tall | `bodyLarge` 16 × 1.5 | |
| top inset | **12.0** | `AppSpacing.md` | ✓ |
| bottom inset | **12.0** | `AppSpacing.md` | ✓ |
| left text inset | **20.0** | `AppSpacing.lg` = 16 | ⚠ **F10** — +4 |
| right text inset | **20.0** | `AppSpacing.lg` = 16 | ⚠ **F10** — +4 |
| border radius | 12 | `AppRadius.md` | ✓ |
| stroke | 1.5 | `AppStroke.input` | ✓ |

**F10 explained.** `input_decorator.dart:2639-2645` adds
`OutlineInputBorder.gapPadding` (default **4.0**) to *both* horizontal insets
whenever the border is an `OutlineInputBorder` under M3. So the theme names 16
and the app draws 20. Harmless on its own, but it means a field's text does not
line up with a `Text` in the same column padded to `AppSpacing.lg`, and nothing
in the repo says why. Not a defect to fix blindly — changing
`contentPadding.horizontal` to 12 to compensate would break the label gap.

### 9.3 · Suffix icon box

Measured with `trailingAction` at 393 dp / scale 1.0:

| Metric | Measured |
|---|---|
| decorator rect | `LTRB(16, 16, 377, 64)` |
| `IconButton` rect | `LTRB(329, 16, 377, 64)` → **48 × 48** |
| decorator height with suffix | **48.0** — unchanged |
| icon size | `AppIconSize.md` = 24 via `MxIconButton` |
| icon-to-right-border gap | 0 dp of *touch box*, ~12 dp of optical gap |

The explicit `suffixIconConstraints` in `MxTextField` is doing real work, and
its comment is accurate: without it the box would be sized by the field, which
is under 48 at small scales. `mx_editor_surface_test.dart` asserts the 48×48.

The touch box being flush with the outline is not a defect — the glyph is
optically inset by 12 — but it does mean the tap target and the border share an
edge, so a tap on the border's right end activates the button.

### 9.4 · The subtext row — F5

Total `MxTextField` height at 393 dp / scale 1.0, one line of value:

| Configuration | Height | Δ from plain |
|---|---|---|
| plain | 48.0 | — |
| `+ helperText` | 68.0 | +20 |
| `+ errorText` | 68.0 | +20 |
| `+ maxLength` (counter reserved) | 68.0 | +20 |
| `+ maxLength + errorText` | 68.0 | **0 from the counter state** |
| `+ helperText + errorText` | 68.0 | 0 |

So the subtext row is a flat **20 dp**, and it is reserved **only when the
caller passes `maxLength`** (the `Visibility(maintainSize: true)` counter) or a
`helperText`.

| Transition | Measured shift |
|---|---|
| field **with** `maxLength`, error appears | **0 dp** ✅ |
| field **without** `maxLength`, error appears | **+20 dp** ⚠ |

The widget's own docstring claims otherwise:

> Hidden, it still keeps its line (`maintainSize`), so its arrival never
> reflows the field below — **state-change layout stability is the same rule the
> error slot follows.**

The counter half is true. The error half is not, for any field without a limit.
Fields affected today, both of which validate:

- `settings_study_defaults_section_widget.dart:180` — card limit, `errorText`, no `maxLength`
- `study_options_section_widget.dart:81` — card limit, `errorText`, no `maxLength`

In both, a radio group / pill row sits directly below and jumps 20 dp when the
user types an out-of-range number.

### 9.5 · Multiline

| Configuration | Height @ 1.0 |
|---|---|
| `minLines: 1, maxLines: 2` | 48.0 |
| `minLines: 3, maxLines: 5` | 96.0 (= 3 × 24 + 24 padding) |

Exactly linear in `minLines`. The symmetric 12/12 padding is correct for both
orientations — single-line centres, multiline starts at top + 12. No geometry
defect. See §10.

### 9.6 · Stress at 320 dp

At 320 dp / scale 2.0 with `maxLength: 60` and a 41-character error string, the
field measures **172.0** dp with no exception. `mx_stress_test.dart` already
covers `MxTextField` and `MxSearchField` at 320 / 2.0 in both themes plus
`meetsGuideline(androidTapTargetGuideline)`. That harness is sound; its blind
spot is silent clipping (§11.2), not overflow.

### 9.7 · No Tokyo desktop dimension is present

Checked `design_system/components/mx.css`. The kit's `.mx-field__input` uses
`padding: var(--space-md) var(--space-lg)` = **12 / 16**, which is what MemoX
uses — the kit's field is not a desktop-height field and porting it caused no
harm. The kit's `.mx-search` is **44 px** tall with a **32 px** clear button;
MemoX correctly overrode both to 48, and `mx_search_field.dart` says why. The
kit's `:hover` on `.mx-search__clear` was correctly dropped. **No desktop
dimension has leaked in.**

---

## 10 · Single-line vs multiline

One theme recipe serves both. The question is whether it should.

| Concern | Single-line | Multiline | Same recipe OK? |
|---|---|---|---|
| vertical alignment | centred in 48 | top-aligned at +12 | ✅ `symmetric(v: 12)` is right for both |
| `minLines`/`maxLines` | 1 / 1 | expressed per caller | ✅ already parameters |
| `expands` | n/a | not exposed | ✅ only `_FillInput` needs it, and it has it |
| `contentPadding` | 12/16 | 12/16 | ✅ measured linear growth, no drift |
| label behaviour | floats onto the border | floats onto the border | ✅ identical |
| error / helper position | below, 20 dp | below, 20 dp | ✅ identical |

**Production callers and their line counts:**

| Caller | `minLines` / `maxLines` | Also |
|---|---|---|
| `card_create_form_widget` front | 1 / 2 | `textInputAction: next` |
| `card_create_form_widget` back | 2 / 4 | |
| `card_details_section_widget` example | 1 / 2 | |
| `card_details_section_widget` hint | 1 / 2 | |
| `card_details_section_widget` pronunciation | — / 1 | |
| `card_editor_field_widget` (pass-through) | caller's | |
| `card_import_source_step_widget` paste | 4 / 8 | `keyboardType: multiline` |
| every other call site | — / 1 | |

**Verdict: a separate multiline recipe is NOT warranted, and the next pass
should not add one.** The callers differ only in *line count*, which
`minLines`/`maxLines` already express, and the measured geometry is linear and
correct. Adding a variant would create a second input style for zero
incompatible requirement — the exact drift `MxTextField`'s closed API exists to
prevent.

One real multiline observation that is **not** a recipe problem:
`card_import_source_step_widget`'s paste field is the only multiline field with
no `maxLength`, so it has no reserved subtext row — but it also has no
`errorText`, so F5 cannot bite it.

---

## 11 · Search field audit

### 11.1 · Feature table

| Aspect | `MxSearchField` | Assessment |
|---|---|---|
| shape | `AppRadius.pill` (999) | intentional, distinguishes it from the form field |
| fill | `surfaceMuted` → `surface` on focus | ⚠ not an input role (§4.1) |
| border | `surfaceMuted` at rest → `primary` on focus, `strokeAlignOutside` | ✅ clever — costs no layout, and tested |
| leading icon | `Icons.search`, `MxIconSize.sm` (16) | ✅ |
| clear action | `IconButton` 48², tooltip + `Icon.semanticLabel`, only when non-empty | ✅ meets the floor; kit's 32 correctly overridden |
| hint | required, and the doc asks callers to name the **scope** | ✅ good API discipline |
| focus | fill + border, `AnimatedContainer`, honours `AppMotionPolicy` reduced motion | ✅ and tested in `mx_search_field_test.dart` |
| submit | `TextInputAction.search`; `onChanged` is the whole contract, no `onSubmitted` | ✅ live-search is the right model here |
| keyboard type | **not set** → defaults to `TextInputType.text` | ⚠ minor; `TextInputType.text` is right, but stating it would be better |
| semantics | **no label** — only the hint, which vanishes when typed | ⚠ **F1** |
| touch targets | pill fixed at 48; clear button 48² | ⚠ **F2** — the 48 is *fixed*, not a minimum |

### 11.2 · F2 — the pill ignores `textScaler`

Measured, 320 dp, empty field with hint:

| `textScaler` | `MxSearchField` height | `MxTextField` height (comparison) | hint text height |
|---|---|---|---|
| 1.0 | **48.0** | 48.0 | 20.0 |
| 1.3 | **48.0** | 55.0 | 26.0 |
| 2.0 | **48.0** | 72.0 | 41.0 |
| 2.5 | **48.0** | 84.0 | **48.0 — capped** |
| 3.0 | **48.0** | 96.0 | **48.0 — capped** |

The cause is `SizedBox(height: AppSizing.touchTarget)` wrapping a field with
`expands: true` and `isCollapsed: true`. `AppSizing.touchTarget` is documented
as a *floor*; here it is used as a *fixed* height. At 2.0 the hint fits with
7 dp of slack; from 2.5 the text is constrained to the box and clips.

**Why no test catches it:** clipping is not a `RenderFlex overflowed`, so
`mx_stress_test.dart`'s `tester.takeException()` check stays green, and the
tap-target guideline is satisfied by the 48 itself. Measured
`tester.takeException()` is `null` at every scale including 3.0.

The `SizedBox` was added deliberately — the comment records that asking
`InputDecoration` for a minimum height "grew the box and left the text against
its ceiling". That is a real problem, correctly diagnosed; the fix chosen just
solved it by pinning rather than by flooring.

### 11.3 · F1 — no accessible name once typed

Measured semantics of the inner `EditableText`:

| Field state | `label` | `value` |
|---|---|---|
| empty | `"Search decks"` | `""` |
| holding `"nouns"` | **`""`** | `"nouns"` |

The mechanism is exactly the one `MxTextField`'s own docstring warns about:

> a hint-only field is unlabelled the moment the user types, both on screen and
> to a screen reader.

`MxTextField` acts on that by making `label` required. `MxSearchField` does the
thing the warning describes. Confirmed in the SDK:
`input_decorator.dart:878-884` visits the hint when `label == null`, but with
`maintainHintSize: true` the hint is wrapped in an `AnimatedOpacity` at `0`,
and `RenderOpacity` drops a zero-alpha child from the semantics tree.

Affected screens: `library_search_screen`, `card_list_screen`,
`tag_catalog_screen` — i.e. every search in the app.

### 11.4 · Should search reuse the `InputDecoration` foundation?

**Neither merge it into `MxTextField` nor leave it fully detached — keep the
composition, fix the two holes in place.**

Evidence for keeping it separate (option B):

- It has **no label**, and `MxTextField` requires one. Making `label` optional
  to accommodate search would remove the guard that produced F1 in the first
  place.
- It is **filled**; the form field is unfilled by an explicit, documented
  decision. Expressing both through one `InputDecorationTheme` needs a
  per-instance `filled` override, which is a decoration escape hatch.
- Pill vs `AppRadius.md`, count slot, clear button, `TextInputAction.search` —
  four more axes with no form-field analogue.
- It already reuses the one thing worth sharing: the theme's `hintStyle`.

Evidence *against* the current detachment:

- It reads `semantic.surfaceMuted` where a canonical input role exists
  (`fillColor` → `surfaceContainerHighest`).
- It re-implements focus, which means F3-shaped bugs can appear in two places
  independently.
- Its own type rung (`bodyMedium`) differs from the form field's (`bodyLarge`)
  for no stated reason.

The proportionate answer is in §20: keep the composition, give the pill a
minimum rather than a fixed height, give it a label, and record the
`surfaceMuted` substitution as a deliberate decision rather than leaving it
undeclared.

---

## 12 · Prefix / suffix / icon state audit

| Slot | Exists in MemoX? | rest | focus | error | disabled |
|---|---|---|---|---|---|
| `icon` | no caller | — | — | — | — |
| `prefixIcon` | no caller | — | — | — | — |
| `suffixIcon` | **yes** — `MxTextFieldAction` → `MxIconButton` | `onSurfaceVariant` ✅ | `onSurfaceVariant` ✅ | ⚠ **`onSurfaceVariant`** | `onSurface` @ .38 ✅ |
| clear button | `MxSearchField` only, plain `IconButton` | `onSurfaceVariant` | = | n/a | n/a |
| visibility toggle | none — no password field exists | — | — | — | — |
| error icon | none by design | — | — | — | — |
| dropdown icon | `MxDropdown`, out of scope | — | — | — | — |

### F4 — why the suffix icon misses the error state

`_getSuffixIconColor` (`input_decorator.dart:2165-2173`):

```dart
return WidgetStateProperty.resolveAs(decoration.suffixIconColor, widgetState) ??
    iconButtonTheme.style?.foregroundColor?.resolve(widgetState) ??   // ← wins
    WidgetStateProperty.resolveAs(defaults.suffixIconColor!, widgetState);
```

MemoX themes `IconButton` (`app_icon_button_theme.dart`), so
`iconButtonTheme.style.foregroundColor` is non-null and **short-circuits the M3
default** — which is the only resolver that has an `error` branch
(`:6029-6041` → `_colors.error`).

Measured `IconTheme.of(...).color` at the suffix:

| Field state | Measured | Canonical M3 |
|---|---|---|
| rest | `#596680` (`onSurfaceVariant`) | `onSurfaceVariant` ✅ |
| **error** | `#596680` (`onSurfaceVariant`) | **`error`** ⚠ |
| disabled | `onSurface` @ .3804 | `onSurface` @ .38 ✅ |

So it *does* follow disabled correctly and *does not* follow error — exactly the
"error border is red, icon stays neutral" case the brief names. The one
production instance is `card_tag_section_widget.dart:338` — the tag-add `+`
button, on a field that shows a real `errorText` for a duplicate or invalid tag.

Note this is a **framework precedence interaction**, not a MemoX mistake in the
usual sense: theming `IconButton` at all is what disables the input's suffix
error branch. Any fix has to be aware that removing `IconButtonTheme`'s
foreground would change every icon button in the app.

---

## 13 · Typography audit

| Slot | Style used | Size / height / tracking | Source |
|---|---|---|---|
| input text | `bodyLarge` | **16 / 1.5 / 0.5** | `_m3InputStyle` — canonical |
| hint | `bodyMedium` + `onSurfaceVariant` | **14 / 1.45 / 0.25** | MemoX `hintStyle` override |
| label (inline) | `bodyLarge` | 16 / — | M3 default |
| floating label | `bodyLarge`, scaled by `_floatingLabelController` | 16 → smaller | M3 default |
| helper | `bodySmall` | 12 / 1.333 / 0.4 | M3 default |
| error | `bodySmall` + `error` | 12 / 1.333 / 0.4 | M3 default |
| counter | `bodySmall` + `onSurfaceVariant` | 12 / 1.333 / 0.4 | MemoX `buildCounter` |
| search field text | `bodyMedium` | 14 / 1.45 | `MxSearchField` |
| search result count | `labelSmall` @ w600 + `sectionLabelTracking` + tabular figures | 11 / 1.45 / 1.1 | `MxSearchField` |

**Weights:** exactly two across the whole input stack — `w400` for every body
rung and `w600` on the search count. No new weight, no new rung, no invented
scale. ✅

**Dark-mode readability** (contrast against the light/dark page):

| Ink | Light | Dark |
|---|---|---|
| input value (`onSurface`) | **11.50** | **12.01** |
| hint (`onSurfaceVariant`) | **5.28** | **6.47** |
| disabled value (`onSurface` @ .38) | 2.11 | 2.61 |

Value and hint clear 4.5:1 in both themes with room. Disabled is contrast-exempt.

### F6 — the hint is a rung below the value

`_getInlineHintStyle` (`input_decorator.dart:2199-2210`) starts from
`textTheme.bodyLarge` and then merges the theme's `hintStyle` over it, so a
`hintStyle` carrying its own `fontSize` **replaces** the canonical 16.

Measured: hint renders at **14 / 1.45**, the value it is replaced by at
**16 / 1.5**. So the text in the field grows by 2 dp and shifts line box at the
moment the first character lands.

`component_theme_typography_test.dart:187-195` **pins this on purpose** ("an
input hint is body-md, leading included"), so it is a decision that was made,
not an accident. What is missing is the *reason*: nothing in the repo says why
the placeholder should be smaller than the text replacing it, and Material's
own answer is that it should not be. Owner call (Q4).

Note the same override also drops `hintStyle`'s state resolver: the M3 default
is a `WidgetStateTextStyle` with a `disabled → onSurface @ .38` branch, and a
plain `TextStyle` has no branches. So the placeholder in a **disabled empty
field** stays at full `onSurfaceVariant` strength while everything around it
fades. Small, real, and reachable — every `isEnabled: !isSubmitting` field that
is empty during a submit.

---

## 14 · Form composition audit

### 14.1 · The forms that exist

| Form | Kind | Host surface | Fields |
|---|---|---|---|
| `deck_form_widget` | dialog / sheet form | `surfaceContainerLow` | 1 text + scheduler radios |
| `tag_rename_widget` | sheet form | `surfaceContainerLow` | 1 text |
| `mx_form_dialog` | dialog, single field | `surfaceContainerHigh` | 1 text |
| `card_create_form_widget` | long form | page | 2 text + expandable details |
| `card_details_section_widget` | long form (nested) | page | 3 text |
| `card_editor_field_widget` | field composite | page | 1, external label |
| `card_tag_section_widget` | inline entry | page | 1 + trailing action |
| `card_import_source_step_widget` | long form | page | 1 multiline paste |
| `settings_study_defaults_section_widget` | long form | card | 1 numeric + radios |
| `study_options_section_widget` | sheet form | sheet | 1 numeric + pills |
| `library_search` / `card_list` / `tag_catalog` | search | subheader strip | 1 search pill |
| study fill | study answer | card | 1 `_FillInput` |

### 14.2 · Measured rhythm

| Relationship | Value | Token | Where |
|---|---|---|---|
| field → field | **16** | `AppSpacing.lg` | `card_create_form_widget:129`, `card_details_section_widget:100,111` |
| external label → field | **8** | `AppSpacing.sm` | `card_editor_field_widget.dart:83` |
| field → next control (radios/pills) | **12** | `AppSpacing.md` | `deck_form_widget:125` |
| field → failure banner | **12** | `AppSpacing.md` | `deck_form_widget:139`, `mx_form_dialog:99` |
| form → button pair | **24** | `AppSpacing.xl` | `deck_form_widget:145` |
| field → helper/error (internal) | **20** | framework | measured, §9.4 |
| section → section | **24** | `AppSpacing.xl` | `card_import_source_step_widget:89` |

The rhythm is consistent and the label-to-field gap is deliberately tighter than
the field-to-field gap, with the reason written down ("a label belongs to the
box under it, and equal gaps make it float between the two"). This is good
work; nothing here needs changing.

### 14.3 · Ownership — which layer owns which problem

This classification is the brief's mandatory one, and it matters because F5 is
easy to misfile.

| Problem | Owner | Why |
|---|---|---|
| **F5** — 20 dp jump when an error arrives | **A · Input component** | The subtext slot is inside `InputDecorator`; the caller cannot reserve it. The fix belongs in `MxTextField` (reserve the row) or in `InputDecorationTheme`, not in the screens |
| **F1 / F2** — search field name and height | **A · Input component** | Both are inside `MxSearchField` |
| **F3 / F4** — state feedback | **A · Input component** (theme layer) | `app_input_theme.dart` and `IconButtonTheme` |
| field-to-field gap consistency | **C · Feature composition** — currently correct | Every form states its own `SizedBox`; there is no form-layout primitive, and none is needed at this size |
| label-row grammar (`Required`, live count) | **C · Feature composition** | Correctly kept in `card_editor_field_widget`, out of `MxTextField` |
| numeric input constraint | **A · Input component** (F7) | The API has no way to express it |

**There is no B-class problem.** No form-layout primitive exists and none is
missing — with 12 forms, all of which state one to three gaps from the spacing
scale, a primitive would be an abstraction ahead of its need. **No screen-spacing
problem should be pushed into `InputDecorationTheme`.**

---

## 15 · Input API audit

### 15.1 · `MxTextField` — 20 public parameters, classified

Caller counts are exact, over all 13 production call sites.

| Parameter | Class | Callers | Verdict |
|---|---|---|---|
| `controller` | behavioural | 13 | required, keep |
| `label` | semantic | 13 | required, keep — it is what prevents F1 here |
| `hintText` | semantic | 7 | keep |
| `helperText` | semantic | **1** | keep — the one caller is the pass-through composite |
| `errorText` | semantic | 11 | keep — the `String?`-not-`bool` shape is load-bearing |
| `isEnabled` | behavioural | 10 | keep |
| `isReadOnly` | behavioural | **0** | ⚠ **zero callers**, and no visual cue (F8) |
| `keyboardType` | behavioural | 3 | keep |
| `textInputAction` | behavioural | 5 | keep |
| `minLines` | layout | 6 | keep |
| `maxLines` | layout | 6 | keep |
| `maxLength` | semantic | 10 | keep |
| `focusNode` | behavioural | 4 | keep |
| `shouldAutofocus` | behavioural | 4 | keep |
| `onChanged` | behavioural | 2 | keep |
| `onSubmitted` | behavioural | 4 | keep |
| `textAlign` | layout | **0** | ⚠ **zero callers** — its documented reason moved to `_FillInput` |
| `textStyle` | **visual escape hatch** | **1** | the only hatch; see below |
| `trailingAction` | semantic | 1 | keep — the typed triple is the right shape |
| `labelPlacement` | semantic | 1 | keep |

### 15.2 · The escape-hatch question

The brief asks whether callers can bypass the design system via `borderColor`,
`fillColor`, `radius`, `contentPadding` or `textStyle`.

**Four of the five do not exist.** `MxTextField` takes no `Color`, no
`InputDecoration`, no radius and no padding, by explicit design. That is the
strongest part of this API and it should be preserved exactly.

`textStyle` is the sole hatch. Its single production caller is
`card_editor_form_widget.dart:93`, which passes `context.texts.titleLarge` — a
theme rung, not a literal. So today it permits no drift. But the type is
`TextStyle?`, so nothing *structurally* prevents
`TextStyle(color: Colors.red, fontSize: 19)`, and no guard scans it: the
hardcoded-colour rules cover `lib/` broadly, but a `TextStyle` built from a
theme rung and a literal colour in a feature file is not something the current
rules catch here.

**Recommended closed replacement** (do not remove the parameter — replace its
type): a small enum, e.g.

```dart
enum MxTextFieldEmphasis { body, prominent }   // bodyLarge · titleLarge
```

One caller, one need, two values. That converts an open hatch into a closed set
without changing a pixel.

### 15.3 · What the API is missing — F7

There is no `inputFormatters`. Measured: a field with
`keyboardType: TextInputType.number` accepted `"abc-12.5"` into its controller
verbatim, and `tf.inputFormatters` is `null`.

On Android the soft numeric keyboard hides letters, so this is not a *typical*
path — but paste, a hardware keyboard, and third-party IMEs all reach it, and
both numeric fields (`settings_study_defaults`, `study_options`) then fall
through to a parse failure that the user has to read as an error. A closed
addition — not a raw `List<TextInputFormatter>` — would fit the existing
grammar:

```dart
enum MxTextFieldContent { text, digits }   // digits → FilteringTextInputFormatter.digitsOnly
```

### 15.4 · `MxSearchField` — 6 parameters

| Parameter | Class | Verdict |
|---|---|---|
| `value` / `onChanged` | behavioural | controlled-component pair, correct |
| `hintText` | semantic | required ✅ but doubles as the accessible name → **F1** |
| `resultCount` | semantic | correct, `null` means "not known yet" |
| `clearSemanticLabel` | semantic | ⚠ **optional** — a `null` here gives the clear button no name and no tooltip. Two of three callers pass it; the golden specimen's first instance does not |
| `shouldAutofocus` | behavioural | 1 caller, justified |

No visual escape hatch at all. ✅

---

## 16 · Production usage inventory

Every text-input instance under `lib/`, classified.

| # | File : line | Primitive | Kind | Notes |
|---|---|---|---|---|
| 1 | `features/card/.../card_list_screen.dart:275` | `MxSearchField` | search | in-deck scan |
| 2 | `features/card/.../tag_catalog_screen.dart:132` | `MxSearchField` | search | |
| 3 | `features/search/.../library_search_screen.dart:139` | `MxSearchField` | search | `shouldAutofocus` |
| 4 | `features/card/.../tag_rename_widget.dart:130` | `MxTextField` | name/title | autofocus, submit-on-done |
| 5 | `features/card/.../card_create_form_widget.dart:116` | `MxTextField` | multiline (1–2) | front |
| 6 | `features/card/.../card_create_form_widget.dart:130` | `MxTextField` | multiline (2–4) | back |
| 7 | `features/card/.../card_details_section_widget.dart:90` | `MxTextField` | multiline (1–2) | example |
| 8 | `features/card/.../card_details_section_widget.dart:101` | `MxTextField` | multiline (1–2) | hint |
| 9 | `features/card/.../card_details_section_widget.dart:112` | `MxTextField` | form text | pronunciation |
| 10 | `features/card/.../card_editor_field_widget.dart:84` | `MxTextField` | form text (composite) | external label |
| 11 | `features/card/.../card_import_source_step_widget.dart:78` | `MxTextField` | multiline (4–8) | paste, `keyboardType: multiline` |
| 12 | `features/card/.../card_tag_section_widget.dart:325` | `MxTextField` | name/title | `trailingAction` |
| 13 | `features/deck/.../deck_form_widget.dart:108` | `MxTextField` | name/title | autofocus, submit-on-done |
| 14 | `features/settings/.../settings_study_defaults_section_widget.dart:180` | `MxTextField` | **numeric** | `TextInputType.number` |
| 15 | `features/study/.../study_options_section_widget.dart:81` | `MxTextField` | **numeric** | `TextInputType.number` |
| 16 | `shared/widgets/mx_form_dialog.dart:252` | `MxTextField` | form text | generic single-field dialog |
| 17 | `features/study/.../fill_answer_pieces_widget.dart:187` | **raw `TextField`** | study answer | see §17 |

Password: **none.** Numeric: **2.** Search: **3.** Multiline: **5.** Study
answer: **1.**

---

## 17 · Raw `TextField` inventory

Exactly one, in `lib/features/`.

| File | Classification | Verdict |
|---|---|---|
| `features/study/presentation/widgets/sections/fill_answer_pieces_widget.dart:187` (`_FillInput`) | **A — legitimate framework-level special case** | **Leave it.** |

The argument is already written in the file and it holds up. What the screen
needs is *the absence* of the shared style in all six border states, plus
`expands: true`, `textAlignVertical` and a collapsed inset — "which is either a
second public style on the shared widget for exactly one caller, or a hole in it
through which any caller can pass a decoration."

Two details that make this a good citizen rather than an exception:

- `_fillInputDecoration` turns off **all six** border states, not just `border`.
  The comment explains why — clearing only `border` leaves the theme's
  `focusedBorder` to appear in the one state nobody screenshots. That is a
  correct reading of `input_decorator.dart:2362-2370`.
- The `hint` is a `hint:` widget wrapped in `ExcludeSemantics`, not a
  `hintText`, because the outer `Semantics(label:, textField: true)` already
  names the control. This is the exact fix F1 needs in `MxSearchField`.
- No colour, radius or metric in it is a literal; the type comes from
  `context.texts`.

**No raw use is class B or class C.** There is nothing to migrate.

Also worth recording: the theme is applied to `TextField` and `TextFormField`
in `theme_coverage_test.dart:113-114`, so both are covered by the coverage
contract even though only `TextField` is used.

---

## 18 · Keyboard / mobile behaviour

### 18.1 · Per-call-site table

| Call site | `keyboardType` | `textInputAction` | `autofocus` | submit | Note |
|---|---|---|---|---|---|
| `deck_form_widget` | — (`text`) | `done` | ✅ | `onSubmitted` → `_submit` | ✅ exemplary |
| `tag_rename_widget` | — (`text`) | — | ✅ | `onSubmitted` → `_submit` | ⚠ no `done`; the key label is the platform default |
| `mx_form_dialog` | — (`text`) | `done` | ✅ | `onSubmitted` → `_submit` | ✅ |
| `card_tag_section_widget` | — (`text`) | `done` | — | `onSubmitted` + `trailingAction` | ✅ visible and keyboard paths agree |
| `card_create_form_widget` front | *inferred* `multiline` | `next` | ✅ | — | ⚠ multiline keyboard + `next` — the Enter key cannot insert a newline |
| `card_create_form_widget` back | *inferred* `multiline` | — | — | — | ✅ newline is right for a 4-line field |
| `card_details_*` × 3 | *inferred* `multiline` / `text` | — | — | — | ⚠ no `next` chain through the details group |
| `card_import_source_step` | `multiline` | — | — | — | ✅ |
| `settings_study_defaults` | `number` | — | — | — | ⚠ no `done`, no formatter (F7) |
| `study_options_section` | `number` | — | — | — | ⚠ no `done`, no formatter (F7) |
| `card_editor_field_widget` | caller's | caller's | — | — | pass-through |
| `MxSearchField` × 3 | — (`text`) | `search` | 1 of 3 | live `onChanged` | ✅ |
| `_FillInput` | **`text`** (explicit) | `done` | — | `onSubmitted` → check | ✅ and the comment explains why `text` and not the multiline default |

Measured confirmations:

- `MxTextField(minLines: 2, maxLines: 4)` with no `keyboardType` resolves to
  **`TextInputType.multiline`** (`text_field.dart:356`).
- The same field with `textInputAction: next` keeps `multiline` and takes
  `next` — no assertion fires, and the user loses the newline key. Deliberate
  for a 2-line "front" field, but nothing says so.

### 18.2 · Inconsistencies present today

1. **No focus traversal chain.** `next` appears exactly once
   (`card_create_form_widget` front → back). The three `card_details` fields, the
   deck form and the settings form have no `next`, so a user filling a
   multi-field form must dismiss the keyboard and tap the next field. Nothing
   calls `FocusScope.nextFocus`, and `onEditingComplete` is used nowhere.
2. **No explicit keyboard dismissal anywhere.** `unfocus()` appears zero times
   in `lib/`. Dismissal is whatever the platform does on scroll/back.
3. **Numeric fields have no `done` action** and no formatter (F7). On iOS the
   number pad has no return key at all, so those two fields have no keyboard
   path to commit — Android only.
4. **`tag_rename_widget` submits on the keyboard's key but never names it**
   (`textInputAction` unset), so the key reads as the platform default rather
   than `Done`.
5. `autofillHints` is unused everywhere. Correct today — there is no auth, no
   address, no name-of-person field. Do **not** add it speculatively.
6. `obscureText` is unused. Correct — there is no password.

None of these is a defect that ships broken; all are the kind of thing that
compounds. They belong to the feature layer (class C), not to `MxTextField`.

---

## 19 · Accessibility audit

| Check | Status | Evidence |
|---|---|---|
| field has an accessible name (`MxTextField`) | ✅ | `label` is required; measured `label: "Deck name"` with a value present |
| field has an accessible name (`MxSearchField`) | ⚠ **F1** | measured `label: ""` once typed |
| hint vs label distinction | ✅ | `label` is the persistent name, `hintText` is the example; the docstring states the rule |
| external label merged into the field's node | ✅ | `MergeSemantics` in `card_editor_field_widget.dart:76`; asserted in `mx_editor_surface_test.dart` |
| error is announced | ✅ framework | `Semantics(container: true, liveRegion: !MediaQuery.supportsAnnounceOf(context))` at `input_decorator.dart:415-419`, plus `Semantics(hint: errorText)` at `:2692-2694` |
| error is not colour-alone | ✅ | structural — `errorText: String?` |
| error is not truncated | ✅ | `errorMaxLines: 3`, app-wide, asserted |
| icon-only suffix has a name | ✅ | `MxTextFieldAction.semanticLabel` is **required**; `MxIconButton` requires one too. Not tooltip-only |
| search clear button has a name | ⚠ | `clearSemanticLabel` is **optional**; a `null` leaves both `tooltip` and `Icon.semanticLabel` null. All three production callers pass it — the risk is the next one |
| suffix is a separate focus node | ✅ framework | `_childSemanticsConfigurationDelegate` marks prefix/suffix as sibling merge groups (`input_decorator.dart:1708-1733`), so the action is reachable separately from the field |
| touch targets ≥ 48 | ✅ | field 48.0; suffix 48×48 (`suffixIconConstraints`); search clear 48×48 |
| contrast — resting border | ✅ | 4.40 / 4.68 vs page; enforced |
| contrast — focus border | ✅ | ≥5.19 everywhere; enforced |
| contrast — value / hint ink | ✅ | 11.50 / 5.28 light, 12.01 / 6.47 dark |
| large text scale — form field | ✅ | 48 → 96 across 1.0 → 3.0 |
| large text scale — search field | ⚠ **F2** | pinned at 48; clips from 2.5 |
| disabled state is clear | ✅ mostly | value, helper, label and suffix all at `.38`; ⚠ the *hint* does not fade (§13) |
| `isReadOnly` is distinguishable | ⚠ **F8** | measured identical ink to enabled; a user cannot tell why typing does nothing |
| counter announcement | ⚠ **F9** | see below |

### F9 — what the custom counter costs

`text_field.dart:1221-1239` returns **early** when `buildCounter` is provided:

```dart
if (… widget.buildCounter != null) {
  final Widget? builtCounter = widget.buildCounter!(…);
  if (builtCounter != null) {
    counter = Semantics(container: true, liveRegion: isFocused, child: builtCounter);
  }
  return effectiveDecoration.copyWith(counter: counter);      // ← returns here
}
```

Everything below that line is skipped, which means:

- **`semanticCounterText` is never set.** The framework would otherwise supply
  the localized `remainingTextFieldCharacterCount` ("4 characters remaining").
  What a screen reader gets instead is the literal `"55/60"`.
- **The overflow style never applies.** `_hasIntrinsicError` swaps
  `counterStyle` to `bodySmall`/`error`; a custom counter widget ignores
  `counterStyle` entirely. Low impact — `maxLengthEnforcement` defaults to
  `enforced` on Android, so overflow is only reachable by paste on platforms
  that allow it — but it is a silent divergence.

The `Visibility(maintainSize: true, …)` wrapper is fine for semantics:
`maintainSemantics` defaults to `false`, so the hidden counter is correctly
absent from the tree. Measured: `find.text('26/30')` finds it when visible.

---

## 20 · Tokyo — keep vs reject

### 20.1 · Traits worth adapting

| Trait | Why it survives the mobile filter | Where it already is |
|---|---|---|
| **Restrained surface hierarchy** | An unfilled field that lets the page show through works on a page *and* on a card with no override. This is the single best decision in the input stack | `filled: false` |
| **Clean input chrome** | One stroke, one radius, no fill, no shadow, no inner rule. Cheap to render, legible at 320 dp | `_inputBorder` |
| **Focus is a hue change, not a size change** | Directly mobile-useful: nothing beside the field is nudged, and it is the same rule in the search pill | `AppStroke.input` in all states |
| **Low visual noise around the field** | Counter appears only near the limit; clear button appears only with a query. Both remove chrome that says nothing | `_counterVisibleFraction`, `hasQuery` |
| **Typography confidence** | Two weights, no invented rung, tabular figures on a live count | `AppTypography` |
| **A transparent-at-rest border so focus costs no layout** | Genuinely clever and worth keeping as a pattern | `MxSearchField` |

### 20.2 · Web traits to reject

| Trait | Status | Note |
|---|---|---|
| `.mx-search` **44 px** height | ✅ already rejected → 48 | correctly, with the reason recorded |
| `.mx-search__clear` **32 px** button | ✅ already rejected → 48 | ditto, and `mx_stress_test` enforces it |
| `:hover` on the clear button | ✅ already rejected | pointer-first |
| `:hover` border darkening on the field | ✅ never ported | M3's `outlineBorder` hover branch is unreachable because the theme states all five borders |
| `:focus-visible` `box-shadow` ring | ✅ rejected | Material's focus channel is the border |
| CSS `transform: translateY(-21px)` label float | ✅ rejected | `InputDecorator` owns the float |
| `textarea { resize: vertical; min-height: 96px }` | ✅ rejected | `minLines`/`maxLines` instead |
| Desktop breakpoint behaviour | ✅ n/a | no width branch in any input |
| Exact CSS shadows / blur | ✅ n/a | no shadow on any field |
| Dense admin form layout | ✅ rejected | 16 dp between fields, not 8 |

**Do not recommend Tokyo parity.** The two places the Dart and the CSS disagree
are both places where Dart is *more* correct: the resting border token
(§20.3) and the two touch dimensions above.

### 20.3 · F11 — kit drift, informational

`design_system/components/mx.css` still names retired tokens:

```css
.mx-field__input        { border: var(--border-input) solid var(--color-border-subtle) }
.mx-field__input:focus  { border-color: var(--color-focus-ring) }
.mx-field--disabled …   { border-color: var(--color-disabled-surface) }
.mx-search:focus-within { border-color: var(--color-focus-ring) }
```

Dart uses `scheme.outline` (= `borderControl`) for the resting border — the
change was made deliberately for WCAG 1.4.11, and the comment records that the
hairline measured **1.38:1**. `focusRing` was retired at M100.19 and the role
carries the job now. `docs/reviews/design-parity-checklist.md:105` still records
row B5 as **match**, which is now stale on the token names.

This is a documentation-parity item, not a rendering defect. Per the standing
rule that the kit mirrors decisions but no longer *makes* them, it should be
resolved by updating the kit and the checklist row — never by moving Dart back
to `borderSubtle`.

---

## 21 · Widgetbook coverage

**Existing:**

| Component | File | Use cases |
|---|---|---|
| `MxTextField` | `widgetbook/lib/components/form_components.dart:19-72` | 1 — `Playground` with knobs: `label`, `hintText`, `helperText`, `errorText`, `enabled`, `readOnly`, `maxLength`, `trailingAction`, `labelPlacement` |
| `MxSearchField` | `widgetbook/lib/components/structure_components.dart:184-210` | 1 |

**Gaps, ranked by whether they are worth a story:**

| Case | Reachable today? | Worth adding? |
|---|---|---|
| resting / filled content / error / disabled / prefix-less / suffix | ✅ via knobs | no — the Playground covers them |
| **`focused + error`** | ❌ — no focus knob, and it is the F3 state | **yes** — the one combination that should be visible in the catalog |
| **multiline** | ❌ — `minLines`/`maxLines` are not knobbed at all | **yes** — 5 of 13 production callers are multiline and none is reachable in the catalog |
| **numeric** | ❌ — no `keyboardType` knob | maybe — low value in a catalog that has no soft keyboard |
| long value | ⚠ typeable but not preset | no — `mx_stress_specimens.dart` covers it |
| textScale 2.0 | Widgetbook addon | no — already an addon |
| narrow 320 dp | Widgetbook addon | no — already an addon |
| search: focused | ❌ | **yes** if F2 is fixed, to show the pill growing |

Do not snapshot every theoretical state. Three additions — a `focused + error`
case, a multiline knob pair, and one search-focused case — cover everything the
audit found and nothing it did not.

---

## 22 · Golden and test coverage

### 22.1 · Existing input goldens

| Golden | Specimen | Light | Dark |
|---|---|---|---|
| `input_resting` | bare `TextField` with a hint (palette-level) | ✅ | ✅ |
| `input_focused` | `AutoFocusedField` | ✅ | ✅ |
| `mx_text_field_resting` | `TextFieldSpecimen` — value + label + helper + `maxLength: 200` | ✅ | ✅ |
| `mx_text_field_focused` | same, `shouldAutofocus` | ✅ | ✅ |
| `mx_text_field_error` | same, `errorText` — **not focused** | ✅ | ✅ |
| `mx_text_field_disabled` | same, `isEnabled: false` | ✅ | ✅ |
| `mx_search_field` | two pills: empty, and with a query + count | ✅ | ✅ |

Plus screen-level demo goldens that contain inputs: `card_editor_edit(+dark)`,
`deck_create_root_light`, `deck_rename_form_light`, `library_search_(light|dark)`,
`card_list_search_empty_(light|dark)`, `tag_rename_merge_light`,
`tag_catalog_320_x2`, `settings_(light|dark)`.

### 22.2 · What the component set is missing

The brief's proposed `text_field_light/dark/states_*/stress` set would **largely
duplicate** what exists — resting, focused, error and disabled are already
pinned in both themes at component level, and `mx_stress_specimens.dart` already
carries a long-value / long-error `MxTextField` and a long-hint `MxSearchField`
at 320 / 2.0.

The genuinely uncovered pictures are three:

| Recommended golden | Why it is not a duplicate |
|---|---|
| `mx_text_field_focused_error` (× 2) | The **F3** state. Nothing renders it, which is why the collapse was never seen |
| `mx_text_field_suffix_error` (× 2) | The **F4** state — red border, neutral `+`. One picture makes it obvious |
| `mx_text_field_multiline` (× 2) | 5 of 13 callers are multiline and no golden shows one |

Optionally `mx_search_field_focused` (× 2) once F2 is settled, since the pill's
size would then change with scale.

That is 6–8 new PNGs, not a new sheet. **Note the platform rule:** goldens have
one authoring platform and since M100.24 it is Linux — a Windows checkout cannot
regenerate them, and this audit did not attempt to.

### 22.3 · Test quality

**Tests that correctly protect a canonical M3 contract:**

| Test | What it protects |
|---|---|
| `m3_role_contract_test.dart:232-245` | `enabledBorder` → `outline`, `focusedBorder` → `primary`, `errorBorder` → `error`, resolved-value identity, both themes |
| `app_theme_test.dart:274-298` | focus changes hue, not width or radius — the house rule, both themes |
| `app_theme_test.dart:300-316` | `primary` ≥ 3:1 on tile / card / page |
| `control_border_grounds_test.dart` | `borderControl` ≥ 3:1 on page / `surface` / `surfaceContainer`, with a fault-injection note in its own docstring |
| `component_theme_typography_test.dart:187-195` | the hint's rung *and* its leading |
| `mx_stress_test.dart` | 320 dp × 2.0 × both themes, no overflow; `meetsGuideline(androidTapTargetGuideline)` on every interactive specimen |
| `mx_form_components_test.dart` | error is text and not colour alone; the field enforces no business rule of its own |
| `mx_editor_surface_test.dart:185-300` | external label does not lose the name; `suffixIconConstraints` ≥ 48; `helperMaxLines`/`errorMaxLines` = 3 |
| `mx_search_field_test.dart` | focus changes fill and border but **not size**; reduced motion drops the fade and keeps the state |

That is a strong set, and the reduced-motion pair in particular is written the
right way round — with a control case that would fail if the pill were instant
either way.

**Tests that pin an implementation detail rather than a contract:** none found.
Every assertion above traces to either a house rule with a written reason or a
WCAG floor.

**Where `Color` equality is used but role identity is what is meant:**
`m3_role_contract_test.dart` says so itself and points at
`m3_role_binding_guard_test.dart` for the other half — but **`TextField` is in
the first file and absent from the second** (G1). Given that `outlineVariant`
and the retired `borderSubtle` were byte-identical in this palette, a
re-pointing of `enabledBorder` from `outline` to `outlineVariant` would pass
every existing input assertion. That is the concrete risk the missing binding
leaves open.

**Missing combined states** (G2, G4):

| Combination | Test | Golden |
|---|---|---|
| focus + error | ❌ | ❌ |
| disabled + error | ❌ | ❌ |
| suffix + error | ❌ | ❌ |
| suffix + disabled | ❌ | ❌ |
| multiline + error | ❌ | ❌ |
| search, typed, semantics | ❌ | n/a |
| search at textScale > 1.0 | ❌ (only via the 2.0 overflow sweep) | ❌ |

`m3_combined_state_test.dart` — the file whose entire purpose is combinations —
covers six components and not this one.

---

## 23 · Recommended implementation plan

Ordered so that each step is independently mergeable and each has a gate that
would have failed before it.

### Phase 1 — close the guard holes first (no pixels move)

Doing this before any fix means every later step has a test that goes red first.

| Step | Change | Gate |
|---|---|---|
| 1.1 | Add `TextField` bindings to `m3_role_bindings.dart`: `enabledBorder`→`outline`, `focusedBorder`→`primary`, `errorBorder`→`error`, `focusedErrorBorder`→`error` | `m3_role_binding_guard_test.dart` |
| 1.2 | Add `focusedErrorBorder` and a documented exception for `disabledBorder` to `m3_role_contract_test.dart` | that test |
| 1.3 | Add a `TextField` group to `m3_combined_state_test.dart` covering `{focused, error}`, `{disabled, error}`, `{focused}` vs `{error}` **discriminability** | red on F3 |
| 1.4 | Add `surfaceContainerLow` and `surfaceContainerHigh` to `control_border_grounds_test.dart`'s ground list (both already pass; dark-on-dialog at 3.50 is the thin one) | that test |

### Phase 2 — the P1s

| Step | Change | Files |
|---|---|---|
| 2.1 | **F1** — give `MxSearchField` a real accessible name. Wrap in `Semantics(label: …, textField: true)` and `ExcludeSemantics` the hint, exactly as `_FillInput` already does. Needs a new required `semanticLabel` (or promote `hintText` to double duty explicitly). **Owner decision Q2** | `mx_search_field.dart`, ARB, 3 callers |
| 2.2 | **F2** — replace `SizedBox(height: touchTarget)` with `ConstrainedBox(minHeight: touchTarget)` and drop `expands: true` / `maxLines: null` in favour of a single line that can grow. Re-check the icon/hint baseline the current nudge (`TextAlignVertical(y: -0.1)`) was added for | `mx_search_field.dart` |
| 2.3 | **F3** — make `focusedErrorBorder` say something `errorBorder` does not. **Owner decision Q1**; the audit's recommendation is the *third channel* rather than hue or width | `app_input_theme.dart` |

### Phase 3 — the P2s

| Step | Change | Files |
|---|---|---|
| 3.1 | **F5** — reserve the subtext row unconditionally. The narrow fix is `helperText: ' '` behaviour inside `MxTextField` when neither helper nor counter is present; the cleaner one is a `Visibility`-style reserved slot mirroring the counter's | `mx_text_field.dart` |
| 3.2 | **F4** — restore the error branch for the suffix. Either state `suffixIconColor` in `InputDecorationTheme` as a `WidgetStateColor` (it then wins over `IconButtonTheme`), or resolve the tint inside `MxTextField._buildSuffix` from `errorText != null`. The first is canonical; **do not** remove `IconButtonTheme.foregroundColor` — it would move every icon button in the app | `app_input_theme.dart` or `mx_text_field.dart` |
| 3.3 | **F6** — decide the hint rung. **Owner decision Q4.** If it moves to `bodyLarge`, restore the state resolver too (`WidgetStateTextStyle` with the `.38` disabled branch) | `app_input_theme.dart`, `component_theme_typography_test.dart` |
| 3.4 | **F7** — add a closed `MxTextFieldContent` enum (`text` / `digits`) mapping to `FilteringTextInputFormatter.digitsOnly`; apply at the two numeric call sites | `mx_text_field.dart`, 2 callers |

### Phase 4 — the P3s and the API tidy

| Step | Change |
|---|---|
| 4.1 | **F8** — either give `isReadOnly` a cue (the `disabledBorder` hue with live ink is the obvious candidate) or remove the parameter. It has zero callers |
| 4.2 | Replace `textStyle` with a closed `MxTextFieldEmphasis` enum; remove `textAlign` (zero callers) |
| 4.3 | Make `MxSearchField.clearSemanticLabel` required |
| 4.4 | **F9** — pass a `semanticsLabel` on the counter `Text` carrying the localized "N characters remaining", per the `buildCounter` doc at `text_field.dart:788-791` |
| 4.5 | **F10** — record the +4 `gapPadding` in `app_input_theme.dart`'s docstring so the next person measuring 20 against a 16 token does not go looking for a bug |
| 4.6 | **F11** — update `mx.css` `.mx-field__input` / `.mx-search` to the current token names and refresh `design-parity-checklist.md` row B5 |

### Phase 5 — pictures and catalog

| Step | Change |
|---|---|
| 5.1 | Add specimens + goldens: `mx_text_field_focused_error`, `mx_text_field_suffix_error`, `mx_text_field_multiline` (× light/dark) |
| 5.2 | Widgetbook: a `focused + error` use case, `minLines`/`maxLines` knobs, and a search-focused case |
| 5.3 | Regenerate goldens **on Linux/WSL only**, then rebuild and republish `build/screen_gallery.html` **at the pinned artifact URL** |

### Sequencing note

Phases 2.3 and 3.2 both move pixels in `mx_text_field_error_*`; do them in one
PR or accept two golden regenerations. Phase 2.2 moves `mx_search_field_*` and
every screen golden that carries a search strip
(`library_search_*`, `card_list_search_empty_*`, `tag_catalog_*`) — that is the
largest golden churn in the plan and should be its own PR.

---

## 24 · Files a future implementation pass would touch

**Production**

- `lib/core/theme/components/inputs/app_input_theme.dart` — F3, F4, F6, F10
- `lib/shared/widgets/mx_text_field.dart` — F5, F7, F8, F9, API tidy
- `lib/shared/widgets/mx_search_field.dart` — F1, F2, `clearSemanticLabel`
- `lib/features/settings/presentation/widgets/sections/settings_study_defaults_section_widget.dart` — F7
- `lib/features/study/presentation/widgets/sections/study_options_section_widget.dart` — F7
- `lib/features/card/presentation/widgets/sections/card_editor_form_widget.dart` — `textStyle` → enum
- `lib/features/search/presentation/screens/library_search_screen.dart`, `lib/features/card/presentation/screens/card_list_screen.dart`, `lib/features/card/presentation/screens/tag_catalog_screen.dart` — F1 label
- `lib/l10n/app_en.arb`, `lib/l10n/app_vi.arb` — search label, counter semantics string

**Tests**

- `test/core/theme/contracts/m3_role_bindings.dart` — add the `TextField` bindings
- `test/core/theme/contracts/m3_role_contract_test.dart` — `focusedErrorBorder`, `disabledBorder`
- `test/core/theme/contracts/m3_combined_state_test.dart` — the `TextField` group
- `test/core/theme/contracts/control_border_grounds_test.dart` — two more grounds
- `test/core/theme/components/component_theme_typography_test.dart` — only if F6 moves
- `test/shared/widgets/golden_specimens.dart` — three new specimens
- `test/shared/widgets/mx_components_golden_test.dart` — three new cases
- `test/shared/widgets/mx_search_field_test.dart` — semantics + scale assertions
- `test/shared/widgets/mx_form_components_test.dart` / `mx_editor_surface_test.dart` — F5, F7, F8

**Goldens** — `test/shared/widgets/goldens/` (6–8 new) and, for phase 2.2, the
search-bearing subset of `test/demo/goldens/`. Linux authoring only.

**Widgetbook** — `widgetbook/lib/components/form_components.dart`,
`widgetbook/lib/components/structure_components.dart`

**Design system** — `design_system/components/mx.css`,
`docs/reviews/design-parity-checklist.md`

**Docs** — `docs/wbs.md` (the milestone entry), and this file marked superseded
when the plan lands.

---

## 25 · Questions that genuinely need an owner decision

**Q1 — How should a focused, errored field say it has focus? (blocks F3)**

Four candidates, none free:

| Option | Cost |
|---|---|
| Let `focusedErrorBorder` go to `AppStroke.focus` (2.0) | Breaks the "focus never changes width" rule *in one state only*, so the rule becomes conditional. Layout shift is 0.5 dp per side |
| Give it a distinct hue (e.g. `onErrorContainer`, which is M3's own hover-under-error colour) | Three border hues instead of two; needs a 3:1 measurement |
| Add a state layer / faint fill only in this state | Introduces a fill to an explicitly unfilled field |
| Accept it — the caret is the focus cue | Cheapest, but the caret is recoloured to `error` too, so there is no colour delta at all |

The audit's recommendation is the **second** — it keeps the width rule intact,
uses a role M3 already assigns to the error family, and is one line. But it adds
a hue to the input palette, which is a design decision, not an engineering one.

**Q2 — What is a search field's accessible name? (blocks F1)**

The hint names the *scope* ("Search in Academic Word List"), which is exactly
what a screen reader wants — but it must survive the first keystroke. Either
(a) keep one string and stop it disappearing (`Semantics(label: hintText)` +
`ExcludeSemantics` on the visible hint), or (b) add a separate
`semanticLabel` so the spoken name and the visible placeholder can differ.
(a) is less API and less ARB; (b) is more precise. Both need the same three
callers touched.

**Q3 — Is `MxSearchField`'s `surfaceMuted` fill an accepted substitution for the
canonical `fillColor` role?**

Measured, the pill's fill is **1.09:1** against the light page and **1.34:1**
against the dark one, and its resting border is the fill's own colour — so the
pill has no boundary contrast at all. It is identified by the magnifier glyph
and the placeholder, which is a legitimate WCAG 1.4.11 exemption *if that is the
intent*. Today it is not written down anywhere, and `control_border_grounds_test`
explicitly excludes `surfaceMuted` from its grounds because the pixel census
found no control edge on it — which was true when the census ran. Owner call:
declare the exemption, or give the pill a real edge.

**Q4 — Should the hint stay a rung below the value? (blocks F6)**

Material says the placeholder and the value are the same size. MemoX pins 14
against 16, deliberately (`component_theme_typography_test.dart` asserts it) but
without a recorded reason. Moving it to `bodyLarge` also restores the
disabled-hint fade for free. Moving it changes every field's placeholder in
every golden.

**Q5 — Should the form fields chain with `TextInputAction.next`?**

Five multi-field forms have no chain. Adding one is cheap and improves every
form, but it is product behaviour, and §17 of the brief is explicit that this
audit must not invent it. Related: the two numeric fields have no keyboard
commit path at all on iOS — irrelevant while Android is the release target
(AD-04), relevant the day iOS is not deferred.

**Q6 — Does `isReadOnly` stay?**

Zero callers, no visual cue, and a real trap if someone reaches for it (it looks
exactly like an editable field). Remove it, or give it a cue. Keeping it as-is
is the one option the audit recommends against.
