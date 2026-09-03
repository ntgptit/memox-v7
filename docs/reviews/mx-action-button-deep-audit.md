# MxActionButton — deep audit of the button stack

| | |
|---|---|
| **Status** | **IMPLEMENTED — superseded by M100.36** (Phase 2, commit `refactor(button)`). Findings below keep their measurements as history; the disposition of every P1/P2 is recorded in `docs/wbs.md` M100.36. Current contract: `docs/design-system/tokyo-component-mapping.md` §2 actions/ and §6 |
| **Purpose** | Prepare the next `MxActionButton` implementation pass: what Flutter 3.44.8 paints, what MemoX paints, where they part, and which of those partings is worth acting on |
| **Scope** | `lib/shared/widgets/mx_action_button.dart` · `lib/shared/widgets/mx_text_button.dart` · `lib/core/theme/components/actions/app_button_themes.dart` · `lib/core/theme/states/app_interaction_states.dart` · every production caller under `lib/` · the tests and Widgetbook cases that cover them |
| **Audited against** | `origin/main` @ `4cfddd3d` · Flutter **3.44.8** (`058e0af2c2b`, Dart 3.12.2), SDK source read at `packages/flutter/lib/src/material/` |
| **Not in scope** | Token *values* (AD-14) · `MxIconButton` / `MxPillButton` / `MxFab` except where they share the overlay · anything the Card/theme worktree is currently holding |
| **Last updated** | 2026-09-03 |

**Method note.** Every composited colour below is computed with the same model
the repository's own `focus_ring_contrast_test.dart:224` uses —
`Color.alphaBlend(overlay, fill)` over `Color.lerp` — from the palette constants
as they stand at `4cfddd3d`. ΔE is CIEDE2000; contrast is WCAG relative
luminance. No golden was rendered or regenerated for this report; step 1 of §14
is to confirm the two headline numbers at render level rather than at
arithmetic level.

---

## 1. Executive verdict

The stack is **structurally sound and locally miscalibrated.** The layering is
right: one widget, an enum instead of a `Color`, four theme builders, a guard
that keeps raw Material buttons out of `lib/` (confirmed — the only
`FilledButton` / `OutlinedButton` / `TextButton` constructions in `lib/` are the
four inside `mx_action_button.dart` and the one inside `mx_text_button.dart`).
Nothing here needs re-architecting.

What is wrong is one decision made in one place and inherited by three
variants it was not measured for: **`buildSharedButtonStyle` gives every button
family the same `overlayColor`, and the filled family's canonical overlay role
is not the outlined family's.** On the brand fill the consequence is already
known and pinned — the overlay is a no-op. On `tonal` and `destructive` the same
overlay is *not* a no-op, and it composites on top of a background blend that
was designed to replace it. Nothing tests that, and
`docs/design-system/tokyo-component-mapping.md:45` records the divergence as a
**replacement** where the code implements an **addition**.

The second theme is coverage shaped like the app of six months ago. `tonal` has
zero production callers and a doc comment citing the call site that PR #384
removed. The state-matrix test resolves `backgroundColor` and `overlayColor`
independently and therefore cannot see a composite. The golden set covers
`primary`, `secondary` and `disabled` and stops.

**P0: none.** Nothing measured here breaks a contrast floor that a user reaches
today. The three P1s are one latent floor break (no caller yet), one role
violation with no accessibility consequence, and one state that is technically
present and perceptually marginal.

**Recommended next pass: §14, five steps, none of which needs a new abstraction.**

---

## 2. Flutter 3.44.8 canonical state-role matrix

Read from the pinned SDK at `/d/Setup/flutter/packages/flutter/lib/src/material/`.
`_XxxDefaultsM3` classes are generated from the Material token database; the line
numbers are of the 3.44.8 checkout.

### 2.1 How the two mechanisms actually compose

`ButtonStyleButton.build` (`button_style_button.dart:555–610`) builds:

```
Material(color: resolvedBackgroundColor)     ← ButtonStyle.backgroundColor
  └ InkWell(overlayColor: overlayColor,      ← ButtonStyle.overlayColor
            highlightColor: Colors.transparent)
```

So **`backgroundColor` and `overlayColor` are two different paint operations on
two different render objects, and both run.** They are not alternatives, and
nothing in the framework suppresses one when the other is set.

`InkWell` resolves the overlay three separate ways
(`ink_well.dart:1035`, `1095`, `1364–1379`):

| what | when | colour |
|---|---|---|
| hover `InkHighlight` | pointer enters | `overlayColor.resolve({hovered})` |
| focus `InkHighlight` | focus-visible | `overlayColor.resolve({focused})` |
| pressed `InkHighlight` | `handleTapDown` → `updateHighlight(pressed, true)` (`ink_well.dart:1213`) | `overlayColor.resolve({pressed})` |
| splash / ripple | `_createSplash` (`ink_well.dart:1091`) | `overlayColor.resolve(currentStates)` |

`ButtonStyleButton` sets `highlightColor: Colors.transparent`, but that is only
the **fallback** — `overlayColor?.resolve(...) ?? widget.highlightColor` — so a
non-null `overlayColor` wins and the pressed highlight is painted. **On press a
button therefore paints a full-area highlight *and* an expanding ripple, both in
the pressed overlay colour, on top of whatever `backgroundColor` resolved to.**

### 2.2 Canonical roles

| Component | slot | resting | hover | pressed | focused | disabled | source |
|---|---|---|---|---|---|---|---|
| **FilledButton** | background | `primary` | `primary` | `primary` | `primary` | `onSurface` @ .12 | `filled_button.dart:529` |
| | foreground | `onPrimary` | `onPrimary` | `onPrimary` | `onPrimary` | `onSurface` @ .38 | ` :538` |
| | **overlay** | none | **`onPrimary` @ .08** | **`onPrimary` @ .10** | **`onPrimary` @ .10** | none | ` :547` |
| | elevation | 0 | 1 | 0 | 0 | 0 | ` :562` |
| | side | *no default* | — | — | — | — | ` :601` (comment) |
| | shape | `StadiumBorder` | | | | | ` :607` |
| | minimumSize | 64 × 40 | | | | | ` :578` |
| | padding | `h 24` (→ 12 → 6 as text scales) | | | | | ` :474–485` |
| | iconSize | 18 | | | | | ` :584` |
| | icon gap | `lerpDouble(8, 4, textScale−1)` | | | | | ` :512` |
| | textStyle | `textTheme.labelLarge` | | | | | ` :521` |
| **FilledTonalButton** | background | `secondaryContainer` | " | " | " | `onSurface` @ .12 | `filled_button.dart` tonal block |
| | foreground | `onSecondaryContainer` | " | " | " | `onSurface` @ .38 | " |
| | **overlay** | none | **`onSecondaryContainer` @ .08** | **@ .10** | **@ .10** | none | " |
| **OutlinedButton** | background | `transparent` | | | | | `outlined_button.dart:~500` |
| | foreground | `primary` | " | " | " | `onSurface` @ .38 | " |
| | **overlay** | none | **`primary` @ .08** | **@ .10** | **@ .10** | none | " |
| | **side** | `outline` | `outline` | `outline` | **`primary`** | `onSurface` @ .12 | " |
| | minimumSize | 64 × 40 · padding `h 24` · `StadiumBorder` · iconSize 18 | | | | | " |
| **TextButton** | background | `transparent` | | | | | `text_button.dart:~470` |
| | foreground | `primary` | " | " | " | `onSurface` @ .38 | " |
| | **overlay** | none | **`primary` @ .08** | **@ .10** | **@ .10** | none | " |
| | side | *no default* | | | | | " |
| | padding | `h 12, v 8` (→ h 8 → h 4) · minimumSize 64 × 40 | | | | | ` :436–448` |

**The one rule to carry forward: a filled button's state layer is its own `on`
colour; an outlined or text button's state layer is `primary`.** M3 does not
share an overlay between those two families, because on a filled surface
`primary` is either the fill itself or a foreign hue.

A second consequence, easy to miss: an `on` colour is achromatic or near-
achromatic against its own fill in every one of MemoX's pairs
(`onPrimary` = `#FFFFFF` light, `onError` = `#FFFFFF` light), so **M3's state
layer moves lightness and leaves hue alone.** Measured below: M3's destructive
press holds hue at 345.7°; MemoX's moves it to 338.5°.

---

## 3. MemoX current state-role matrix

Built from `lib/core/theme/components/actions/app_button_themes.dart` and
`lib/core/theme/states/app_interaction_states.dart`.

### 3.1 What every button inherits

`buildSharedButtonStyle` (`app_button_themes.dart:43–77`):

| slot | value | vs M3 |
|---|---|---|
| `minimumSize` | `64 × 48` (`AppSizing.buttonMinWidth`, `AppSizing.touchTarget`) | **+8 height** — deliberate, the touch floor |
| `padding` | `h 24, v 12` (`AppSpacing.xl` / `md`) | horizontal `=`; vertical added, and **it does not scale down with text** where M3's does |
| `shape` | `RoundedRectangleBorder(12)` (`AppRadius.md`) | `StadiumBorder` → 12 — deliberate, `tokyo-component-mapping.md:124` |
| `textStyle` | `labelLarge` re-weighted to `w700` (`buttonLabelWeight`, ` :430`) | rung `=`, weight +1 step — deliberate, M100.30 |
| **`overlayColor`** | **`AppInteractionStates.controlOverlay(scheme)`** | **the outlined family's role, applied to all four** |

`controlOverlay` (`app_interaction_states.dart:102–107` → `_overlay:197–214`):

| state | colour | M3 filled | M3 outlined/text |
|---|---|---|---|
| pressed | `primary` @ **.12** | `on<Fill>` @ .10 | `primary` @ .10 |
| focused | `primary` @ **.10** | `on<Fill>` @ .10 | `primary` @ .10 |
| hovered | `primary` @ **.06** | `on<Fill>` @ .08 | `primary` @ .08 |
| resting | `null` | `null` | `null` |

`_overlay` reads pressed → focused → hovered, and the ordering comment at
`app_interaction_states.dart:195` is correct and load-bearing.

### 3.2 Per variant, per state — what MemoX actually paints

`buildFilledStyle` (` :169–234`) `copyWith`s **only** `backgroundColor`,
`foregroundColor` and `side` onto the shared style. `overlayColor` is **not**
overridden, so every filled variant carries `controlOverlay` as well as the
background blend.

Composited pixel = `alphaBlend(controlOverlay(state), lerp(fill, onSurface, blend))`.

**Light**

| variant | state | background resolver | + overlay | final pixel | ΔE from rest | M3 would be | M3 ΔE |
|---|---|---|---|---|---|---|---|
| brand | rest | `primary` `#4454CC` | — | `#4454CC` | — | `#4454CC` | — |
| | hover | `lerp(→onSurface, .06)` `#4252C5` | `primary` @ .06 | `#4252C5` | **1.11** | `#5362D0` | 4.55 |
| | pressed | `lerp(.12)` `#4050BE` | `primary` @ .12 | `#4051BF` | **2.08** | `#5765D1` | 5.74 |
| | focused | `primary` (no branch) | `primary` @ .10 | `#4454CC` | **0.00** | `#5765D1` | 5.74 |
| | disabled | `semantic.disabledSurface` `#E4E7EA` | — | `#E4E7EA` | 30+ | `onSurface` @ .12 | — |
| tonal | rest | `secondaryContainer` `#DADDEB` | — | `#DADDEB` | — | `#DADDEB` | — |
| | hover | `#CFD3E2` | `primary` @ .06 | `#C7CBE1` | **5.05** | `#CCCFDD` | 3.20 |
| | pressed | `#C4C9D9` | `primary` @ .12 | `#B5BBD7` | **9.92** | `#C9CCDA` | 4.03 |
| | focused | `#DADDEB` | `primary` @ .10 | `#CBCFE8` | 5.08 | `#C9CCDA` | 4.03 |
| destructive | rest | `error` `#CD0031` | — | `#CD0031` | — | `#CD0031` | — |
| | hover | `#C30333` | `primary` @ .06 | `#BB083C` | **5.85** | `#D11441` | 3.87 |
| | pressed | `#B80635` | `primary` @ .12 | `#AB0F47` | **11.71** | `#D21A46` | 4.82 |
| | focused | `#CD0031` | `primary` @ .10 | `#BF0840` | 6.10 | `#D21A46` | 4.82 |

**Dark**

| variant | state | final pixel | ΔE from rest | M3 | M3 ΔE |
|---|---|---|---|---|---|
| brand | hover | `#BDC3FC` | **0.64** | `#B0B6F4` | 3.18 |
| | pressed | `#BEC3FA` | **1.22** | `#ACB2F1` | 4.00 |
| | focused | `#BCC2FF` | **0.00** | `#ACB2F1` | 4.00 |
| tonal | hover | `#3C436A` | 5.64 | `#384064` | 4.42 |
| | pressed | `#4D547A` | **11.16** | `#3C4367` | 5.55 |
| destructive | hover | `#F87F99` | 2.80 | `#EE6E85` | 3.50 |
| | pressed | `#F188A4` | **5.62** | `#EA6C83` | 4.41 |

**Outlined (`secondary`)** — this one is *correct by role*. It paints no fill,
so only the overlay runs, and `primary` is exactly what M3 names there. Only the
alphas differ (6 / 12 vs M3's 8 / 10):

| ground | rest | hover | ΔE | pressed | ΔE | focus | ΔE | label | edge |
|---|---|---|---|---|---|---|---|---|---|
| page light `#F2F5F9` | — | `#E8EBF6` | 3.80 | `#DDE2F4` | 7.30 | `#E1E5F4` | 6.16 | 5.67:1 | 4.40:1 |
| card light `#FFFFFF` | — | `#F4F5FC` | 4.07 | `#E9EAF9` | 7.77 | `#ECEEFA` | 6.57 | 6.20:1 | 4.81:1 |
| page dark `#070C27` | — | `#121734` | 3.37 | `#1D2241` | 6.53 | `#191E3D` | 5.43 | 11.27:1 | 4.68:1 |
| card dark `#111633` | — | `#1B203F` | 3.27 | `#262B4B` | 6.57 | `#222747` | 5.47 | 10.37:1 | 4.30:1 |

Border role on focus is `primary` at `AppStroke.focus` (` :399–401`) — M3's own
answer, correctly written as the role rather than routed through
`AppInteractionStates`.

**Focus indicator on the filled family** is the `side` resolver at ` :222–232`,
drawn in the button's own **label** colour. Measured on the *resting* fill:
brand 6.20:1 light / 7.73:1 dark, tonal 9.51 / 9.05, destructive 5.77 / 6.79.
On the *focus-composited* fill — which is what is actually underneath the ring —
6.20 / 7.73, 8.37 / 7.25, 6.30 / 6.95. **All clear 3:1 in both readings**, so
the double paint does not break WCAG 1.4.11 anywhere. This is the reason none of
§4's findings is a P0.

**Disabled** is one pair for every variant: `semantic.disabledSurface` under
`semantic.onDisabled`, measuring **2.05:1 light** (`#9AA3B1` on `#E4E7EA`) and
**2.51:1 dark** (`#65697B` on `#272C46`).

---

## 4. Deviations, ranked

### P0 — none

No state reachable by a user today falls below a contrast floor, moves layout,
or leaves a control looking armed while inert. The three worst findings are one
latent floor break with no caller, one role violation with no measurable
accessibility cost, and one state that is present but weak.

### P1

**P1-1 · One overlay for two families with different canonical overlay roles.**
`buildSharedButtonStyle:76` hands `controlOverlay` — `primary`-based, which is
M3's *outlined/text* answer — to the filled family as well, and
`buildFilledStyle:178` never overrides it. Consequences, per §3.2:

- **`destructive`**: pressing red paints an indigo ripple and highlight over it.
  Hue moves **345.7° → 338.5°** light and **349.1° → 344.0°** dark, where M3's
  own state layer holds hue exactly (its overlay is `onError` = white). The
  press step is **ΔE 11.71** against M3's 4.82 — 2.4× the intended change, in a
  direction the palette never chose. This is the single most visible deviation
  in the stack, and it is on the button that most needs to look like itself.
- **`tonal`**: press ΔE **9.92** light / **11.16** dark against M3's 4.03 / 5.55.
  Label contrast drops 9.51 → 6.75 light and 9.05 → **5.40** dark. Still AA,
  but the margin is now the smallest in the button system.
- **`brand`**: the overlay is a no-op, and *worse than a no-op* — it pulls the
  composited pixel back toward `primary`, so the press step falls from ΔE 2.36
  (blend alone) to **2.08**. `focus_ring_contrast_test.dart:217–232` already
  pins this and explains why; the test reads `theme.filledButtonTheme.style`,
  which is the brand pair only, so it never sees the two variants where the
  same overlay is loud.

`docs/design-system/tokyo-component-mapping.md:45` records this row as
`FilledButton | overlay | onPrimary | blend về onSurface` — i.e. as a
substitution. **The code adds, it does not substitute.** The documented
divergence and the implemented one are different divergences.

**P1-2 · `_busyStyle`'s destructive arm is dead code, and the state it guards
falls to 2.05:1.** `mx_action_button.dart:263–276` builds the destructive
`FilledButton` from `buildFilledStyle` directly and **never consumes
`busyStyle`** — unlike `primary`/`secondary` (` :218`, ` :224`, via `styled` at
` :215`) and `tonal` (` :237–246`, which threads it explicitly and whose own
comment names this exact trap: *"`busyStyle` first, or the branch for it in
`_busyStyle` is dead code that reads as coverage"*). The
`MxActionButtonVariant.destructive` arm at ` :368–369` therefore computes a
value that is always discarded. A destructive button with
`shouldKeepLabelWhileLoading: true` resolves to `disabledSurface` /
`onDisabled` — **2.05:1 light, 2.51:1 dark** — which is the precise failure
`_busyStyle` exists to prevent, printed on the one sentence saying a deletion is
in progress. **Latent: no production caller combines the two today** (the two
destructive sites, `deck_reset_progress_widget.dart:135` and
`mx_confirm_dialog.dart:165`, both leave `shouldKeepLabelWhileLoading` off).

**P1-3 · The brand button's press feedback is marginal on the release target.**
Android is the release target (AD-04), and press is the one interaction state a
phone has. On the app's primary CTA: background moves **ΔE 2.08 light / 1.22
dark**, and the ripple — the thing Material uses to say "received" — is
`primary` on near-`primary`, contributing **ΔE 0.28 light / 0.17 dark**, i.e.
nothing. The blend at `buildFilledStyle:183–201` was introduced precisely
because the overlay was invisible; it half-fixed it. M3's own step is ΔE 5.74
light / 4.00 dark. Hover is a web/desktop concern and can stay weak; **press
cannot.**

### P2

**P2-1 · One button surface is off `buttonLabelWeight`.**
`mx_text_button.dart:142–144` builds the compact rung as
`WidgetStatePropertyAll(context.texts.labelMedium)` — the raw rung, **w500**,
with the `wght` axis at 500. `ButtonStyle.textStyle` is taken wholesale, not
merged (the theme's own comment at `app_button_themes.dart:330` says so), so
this shadows `buildTextButtonTheme`'s `labelLarge`@w700 resolver **for every
state**, taking the focus-underline branch with it. Two production callers:
`deck_list_toolbar_widget.dart:110` and `mx_session_top_bar.dart:168`.
`component_theme_typography_test.dart:151–162` pins the three *theme slots* at
`buttonLabelWeight` and cannot see a widget-level override.
Compare `MxActionButton._sized:306`, which does the same job correctly via
`AppTypography.withWeight(labelMedium, buttonLabelWeight)`.

**P2-2 · The flashcard face renders every grading action as `primary`.**
`study_card_face_section_widget.dart:389–395` builds one default-variant
(`primary`) `MxActionButton` per `widget.actions`. For `sm2` that is
`again / hard / good / easy` (`sm2_scheduler.dart:37–42`) — **four stacked brand
fills**, no hierarchy, no destructive/secondary distinction. For `eight_box`
it is two brand fills. Meanwhile `recall_timer_pieces_widget.dart:201–215`
renders the *same* eight-box pair as `secondary` (forgotten) + `primary`
(remembered), with a comment explaining exactly why they must not be equals.
**The same semantic decision is composed two different ways in two study
surfaces**, and the one that sprays four primaries is the SM-2 path.

**P2-3 · A variant with zero production callers and a doc citing a removed call
site.** `MxActionButtonVariant.tonal` (`mx_action_button.dart:44`) appears in
`lib/` only inside `mx_action_button.dart` itself. PR #384 ("the Card Detail
edit action is an icon again") removed the last caller;
`card_detail_screen.dart:141` is now an icon button. The enum doc still says
*"Card Detail's `Edit` is the case it was added for"* and quotes **10.37:1 /
9.09:1**; measured against the current palette the pair reads **9.51:1 light /
9.05:1 dark** — `app_material_roles.dart:99` and ` :109` already record the
9.55 → 9.51 move. `mx_components_test.dart:170` still frames its coverage as
*"the variant Card Detail added, tested where it lives"*.
`buildFilledTonalStyle`'s own doc (`app_button_themes.dart:142–145`) justifies
tonal as the answer for *"actions that repeat down a list (the deck row's Study
pill)"* — but both repeated list actions ship as `secondary`
(`deck_study_button_widget.dart:70`, `study_home_deck_item_widget.dart:154`),
and `deck_study_button_widget.dart:60–69` records the deliberate M99.98 decision
to make them so. **Three documents point at a use the code does not have.**

**P2-4 · A feature restates a geometry the theme owns, off the token scale.**
`deck_study_button_widget.dart:11` declares `const double _kButtonMinWidth = 80`
and applies it at ` :54`. `AppSizing.buttonMinWidth` is 64, `buildSharedButtonStyle`
states it for every button, and `tokyo-component-mapping.md:224` says in as many
words: *"MUST NOT: một `Mx*` widget hoặc một feature nêu lại các giá trị này."*
80 is on the 4px grid but on no token ladder. It is the only per-call-site
geometry override in the whole inventory — every other one of the 68 call sites
is a spacing gap, an `Expanded`, an `Align`, or `MxButtonPair`.

**P2-5 · The icon gap does not shrink with text scale.**
`mx_action_button.dart:426` uses a fixed `SizedBox(width: AppSpacing.sm)` = 8.
M3's `_FilledButtonWithIconChild` (`filled_button.dart:512`) uses
`lerpDouble(8, 4, clamp(textScale)−1)` — it gives 4dp back at textScale 2.0. On
320dp at 2.0×, where `mx_stress_test.dart` already runs, that is 4dp of
horizontal room MemoX does not recover. The same fixed 8 is in the
kept-label loading row at ` :415`.

**P2-6 · The same semantic action is composed two ways.** "Study this deck" is
`compact` + `secondary` with no icon at `deck_study_button_widget.dart:58`, and
`compact` + `secondary` **with `Icons.play_arrow`** at
`study_home_deck_item_widget.dart:151`. The first carries an owner-review
comment (2026-08-20) saying the play glyph *"said nothing the verb did not"*.
Both are right about geometry and disagree about composition.

### P3

**P3-1 · The disabled-pair contrast figure is stale in five places, and the real
number is worse.** `mx_action_button.dart:240` and ` :319`,
`app_toggle_themes.dart:80` and ` :177`, `card_export_demo_test.dart:37` and
`docs/wbs.md:9376` all cite **2.29:1**, and ` :319` quotes `#93949E` on
`#E0E0E5` — neither of which is a current token. Measured at `4cfddd3d`:
`onDisabledLight` `#223354`@0x61 over `disabledSurfaceLight` `#E4E7EA` =
`#9AA3B1`, **2.05:1**. Dark is **2.51:1** against the recorded 2.90:1. The
palette moved at M100.22/M100.25–28 and the citations did not follow. The
*decisions* those numbers justify are still right; the numbers are not.

**P3-2 · `deck_study_button_widget.dart:41` still says the compact label is
`label-md` at 600.** M100.30 moved it to `buttonLabelWeight` = 700
(`mx_action_button.dart:306`), and the same file's ` :43–45` narrates the old
w600 story as current.

**P3-3 · `MxTextButton.accent` is an open colour parameter.**
`mx_text_button.dart:100` takes an `AppInk?`, which is a closed enum rather than
a raw `Color` — so it is a narrow hatch, not an open one — but it is still the
only place in the button system where a caller chooses a colour. One production
user: `mx_feedback_band.dart:128` (`AppInk.onErrorContainer`), and that file's
own comment at ` :61` argues the case. Worth recording as the system's single
remaining colour escape hatch, not worth closing on its own.

**P3-4 · `shouldKeepLabelWhileLoading` silently drops the icon.**
`mx_action_button.dart:406–419` replaces the leading icon with the spinner. The
behaviour is right and documented; the parameter name says nothing about it, and
`card_editor_action_bar_widget.dart:86` passes both `icon: Icons.check` and
`shouldKeepLabelWhileLoading: true` — so the glyph disappears mid-save. Nothing
tests the combination.

---

## 5. The FilledButton double-feedback finding

The question the task poses, answered directly.

**Does MemoX apply two mechanisms?** Yes, and both paint. `buildFilledStyle`
(`app_button_themes.dart:169–234`) is `buildSharedButtonStyle(...).copyWith(...)`
naming `backgroundColor`, `foregroundColor` and `side`. `overlayColor` is not in
that `copyWith`, so `controlOverlay` survives from ` :76`.

**Do they paint simultaneously in the real render?** Yes — established from
3.44.8 source, not from memory. `ButtonStyleButton.build`
(`button_style_button.dart:595–610`) puts `resolvedBackgroundColor` on a
`Material` and, inside it (` :555–570`), an `InkWell` carrying `overlayColor`.
Two render objects, two paints, no suppression path between them. On press the
`InkWell` creates **both** a full-area `InkHighlight`
(`ink_well.dart:1213` → `1035`) **and** a splash (` :1091`), both taking
`overlayColor.resolve({pressed})`, because `highlightColor: Colors.transparent`
is only the `??` fallback (` :1364`).

**What does M3 paint?** `backgroundColor` constant across hover/press/focus, and
a state layer in the fill's own `on` colour: `onPrimary` @ .08/.10/.10,
`onSecondaryContainer` @ .08/.10/.10, and for a `FilledButton` themed to `error`
it would be `onError`. One mechanism, whose colour is guaranteed to read on the
fill and — in MemoX's palette, where every `on` colour is white or near-black —
guaranteed to move lightness without moving hue.

**What does MemoX paint?** `lerp(fill → onSurface, .06/.12)` **plus**
`primary` @ .06/.10/.12. Numbers in §3.2. Summarised:

| variant | who wins | net effect vs M3 |
|---|---|---|
| `brand` | the blend; the overlay cancels part of it | **under-shoots** — press ΔE 2.08 vs 5.74; focus overlay is exactly ΔE 0.00 |
| `tonal` | both, additively | **over-shoots ~2.5×** — press ΔE 9.92 vs 4.03 |
| `destructive` | both, additively, **and in a foreign hue** | **over-shoots 2.4× and rotates hue −7.2°** |

**Does MemoX change a canonical role?** For `backgroundColor` and
`foregroundColor`, no — `MxFilledPair` (`app_button_themes.dart:90–118`) binds
`primary`/`onPrimary`, `secondaryContainer`/`onSecondaryContainer`,
`error`/`onError`, exactly M3's three pairs, and the enum was introduced at
M100.31 specifically to make a wrong pair unrepresentable. **For `overlayColor`,
yes**: `primary` where M3 names `on<Fill>`. That is the deviation.

**Which tests protect the current behaviour?**

| test | what it pins | blind to |
|---|---|---|
| `mx_action_button_state_matrix_test.dart:103–158` | per variant × size × 4 themes: `backgroundColor(hover) ≠ rest`, `(pressed) ≠ rest`, `(disabled) ≠ rest`, label ≥ 4.5:1 on rest fill, focus `side` ≥ 3:1 on rest fill | **resolves `backgroundColor` and `overlayColor` separately and never composites them.** It cannot see a double paint, an over-shoot, or a hue rotation. |
| ` :166–234` | `secondary` edge is `borderControl` at rest and while loading; overlay non-null on hover and press | overlay is asserted **non-null only for `secondary`** — the filled family's overlay is never read |
| `focus_ring_contrast_test.dart:217–232` | **explicitly**: on the brand fill the focus wash composites to < 1.1:1, i.e. is a no-op, and that is why the `side` ring exists | reads `theme.filledButtonTheme.style` — brand pair only. `tonal` and `destructive` never reach it. |
| ` :186–216` | `primary` fails 3:1 on the brand fill, so `focusIndicatorOf(label)` is justified | same brand-only scope |
| `m3_role_bindings.dart` | AST bindings for `OutlinedButton.foregroundColor` / `.side`, `TextButton` accent, `SegmentedButton`, FAB, Card | **no binding for any `FilledButton` slot, and none for `overlayColor` on any component** |
| `component_theme_typography_test.dart:151–162` | all four families at `buttonLabelWeight` | theme slots only |
| `mx_components_test.dart:169–200` | tonal exact tokens per mode, 48 floor, focus ring | resting/disabled tokens; not composites |
| `app_interaction_states_test.dart:104–118` | icon button overlay resolves for hover/press/focus and is null at rest | does not assert the *filled button's* overlay at all |
| goldens `button_primary` / `button_secondary` / `button_disabled` × 2 modes | resting and disabled pixels | no hover, press, focus, tonal, destructive, compact or icon |

**Net:** the brand case is known, measured and pinned. The tonal and destructive
cases are neither tested nor documented, and they are the two where the second
mechanism is loud.

---

## 6. MxActionButton API inventory

`MxActionButton` (`mx_action_button.dart:74–86`) — 9 parameters, no `Color`, no
`TextStyle`, no `EdgeInsets`, no `Size`.

| parameter | type | semantic | callers | notes |
|---|---|---|---|---|
| `label` | `String` | already-localised copy | 68 | never reads ARB |
| `onPressed` | `VoidCallback?` | null disables | 68 | |
| `variant` | `MxActionButtonVariant` | emphasis | 38 default + 28 explicit + 1 conditional (`mx_confirm_dialog.dart:165`) | |
| `size` | `MxActionButtonSize` | body height | 2 explicit | |
| `isLoading` | `bool` | busy + disabled | 14 | disables at ` :176` |
| `shouldKeepLabelWhileLoading` | `bool` | paint the words while busy | 3 | P3-4 |
| `icon` | `IconData?` | leading glyph | 6 | fixed 16dp, fixed 8dp gap |
| `shouldAutofocus` | `bool` | initial focus | 2 | gated on `FocusHighlightMode` at ` :167–169` |
| `semanticLabel` | `String?` | accessible name override | 2 | rebuilds the node at ` :193–205` |

### Variants

| variant | Material primitive | style source | prod callers | size recipe | typography | role pair | rest → hover → press → focus | loading | icon |
|---|---|---|---|---|---|---|---|---|---|
| `primary` | `FilledButton` | `filledButtonTheme` (`MxFilledPair.brand`) | **39** | 64×48, `h24 v12`, r12 | `labelLarge` w700 | `primary` / `onPrimary` | blend `.06`/`.12` + `primary` overlay; focus = `side` in `onPrimary` | honours `busyStyle` | 16dp, gap 8 |
| `secondary` | `OutlinedButton` | `outlinedButtonTheme` | **28** | same | same | `primary` on `outline` | overlay only — **role-correct** | honours `busyStyle` (` :343–356`) | " |
| `tonal` | `FilledButton` + `buildFilledTonalStyle` | widget-supplied | **0** | same | same | `secondaryContainer` / `onSecondaryContainer` | blend + overlay, additive | honours `busyStyle` (` :237`) | " |
| `destructive` | `FilledButton` + `buildFilledStyle(pair: destructive)` | widget-supplied | **1** + 1 conditional | same | same | `error` / `onError` | blend + overlay, additive, hue-shifting | **ignores `busyStyle`** — P1-2 | " |

### Sizes

| size | painted | tap | min width | padding | textStyle | callers |
|---|---|---|---|---|---|---|
| `standard` | 48 | 48 (`minimumSize`) | 64 | `h 24, v 12` from theme | `labelLarge` w700 | 66 |
| `compact` | **40** (`AppSizing.controlCompact`) | 48 via `MaterialTapTargetSize.padded` (` :301`) | 64 | **`h 12, v 0`** — the widget's flat `padding` shadows the theme's entirely | `labelMedium` w700 (` :306`) | 2 |

`_sized` (` :289–310`) is `geometry.merge(base)`, and the direction is correct
and explained: `merge` keeps the receiver's non-null values, so `compact`'s 40
wins over the shared style's 48. The four properties it names are single-state,
so nothing that resolves is shadowed — except `textStyle`, which is intended,
and `padding`, whose vertical component silently becomes 0.

### API findings

- **Zero-caller variant:** `tonal` (P2-3).
- **Zero-caller parameter combinations:** `destructive` + `shouldKeepLabelWhileLoading`
  (the P1-2 dead path), `tonal` + anything.
- **Duplicate variants:** none. `tonal` and `secondary` are genuinely different
  weights; the problem is that no screen currently wants the middle one.
- **Escape hatches admitting drift:** none in `MxActionButton` — this is the
  strongest part of the design. The two in the wider button system are
  `MxTextButton.accent` (P3-3) and `MxTextButton.isCompact`'s unweighted rung
  (P2-1).
- **Per-call-site geometry overrides:** exactly one — `_kButtonMinWidth = 80`
  (P2-4).
- **Nothing in the codebase passes a `Color`, `TextStyle`, `EdgeInsets`,
  `ButtonStyle` or `Size` into a button.** Verified by parsing every
  `MxActionButton(` and `MxTextButton(` invocation under `lib/`: the set of
  named arguments used is exactly the declared parameter set, with no extras.

---

## 7. Production consumer inventory

68 `MxActionButton` call sites under `lib/`, in 27 files. Classified:

| class | count | representative sites |
|---|---|---|
| primary page action | 14 | `study_entry_section_widget.dart:59` · `study_summary_section_widget.dart:74` · `settings_study_defaults_section_widget.dart:227` · `starter_install_widget.dart:158` |
| dialog / sheet action | 30 | every `MxButtonPair` site — `mx_confirm_dialog.dart:153,165` · `mx_form_dialog.dart:108,113` · `deck_form_widget.dart:151,156` · `deck_reset_progress_widget.dart:135,145` · `deck_scheduler_change_widget.dart:111,127,196,205` · `tag_rename_widget.dart:149,154` · `card_tag_filter_sheet_widget.dart:194,201` |
| wizard step action | 11 | `card_import_action_bar_widget.dart:173–293` (six back/forward pairs) |
| study grading action | 8 | `recall_timer_pieces_widget.dart:188–240` · `study_card_face_section_widget.dart:379,390` |
| repeated list action | 2 | `deck_study_button_widget.dart:58` · `study_home_deck_item_widget.dart:151` — both `compact` + `secondary` |
| secondary / alternative | 6 | `study_resume_widget.dart:44,50` · `card_create_form_widget.dart:169` · `fill_answer_section_widget.dart:238` |
| destructive | 2 | `deck_reset_progress_widget.dart:135` · `mx_confirm_dialog.dart:165` (conditional) |
| empty/error-state action | 5 | `mx_empty_state.dart:100,104,111` · `mx_error_state.dart:92` · `mx_hero_card.dart:107` |
| inline / compact | 0 | — |

`MxTextButton`: 8 call sites, 6 files — `card_history_section_widget.dart:255`,
`card_list_body_widget.dart:161`, `deck_list_toolbar_widget.dart:94`,
`search_page_footer_widget.dart:74`, `settings_reset_section_widget.dart:51`,
`study_options_section_widget.dart:130`, `trash_selection_bar_widget.dart:82`,
`mx_feedback_band.dart:125`.

### Screens carrying more than one primary

| file | what | verdict |
|---|---|---|
| `study_card_face_section_widget.dart:389–395` | 2 (eight-box) or **4** (SM-2) stacked `primary` fills | **P2-2 — the one to fix** |
| `recall_timer_pieces_widget.dart:188–240` | one `primary` per phase, plus the deliberate `secondary`+`primary` assess pair | correct, and the model for P2-2 |
| `card_import_action_bar_widget.dart` | one `primary` + one `secondary` per step, six steps | correct — `MxButtonPair` per step |
| `study_resume_widget.dart:39,44,50` | 1 `primary` + 2 `secondary`, stacked | correct |
| `mx_empty_state.dart:100,104` | `primary` + `secondary` through `MxButtonPair` | correct |
| `deck_scheduler_change_widget.dart` | two separate pairs in two states of one sheet | correct — never both at once |

### Inconsistent variant for the same meaning

1. **Grade a card** — `primary` for every action in the flashcard face,
   `secondary`+`primary` in the recall timer (P2-2).
2. **Study a deck** — same variant and size on both screens, different icon
   composition (P2-6).
3. **Cancel** — uniformly `secondary` across all 12 dialog sites. Good.
4. **Back** in the import wizard — uniformly `secondary` across 4 sites. Good.

---

## 8. Typography findings

`buttonLabelWeight = FontWeight.w700` (`app_button_themes.dart:430`).

| surface | rung | weight | route | correct? |
|---|---|---|---|---|
| `filledButtonTheme` | `labelLarge` 14/20 t0.1 | **700** | `buildSharedButtonStyle:68` | ✓ |
| `outlinedButtonTheme` | " | **700** | same builder | ✓ |
| `textButtonTheme` | " | **700** | `buildTextButtonTheme:339–342` | ✓ |
| `MxActionButton` compact | `labelMedium` 12/16 t0.5 | **700** | `_sized:306`, via `AppTypography.withWeight` | ✓ |
| **`MxTextButton` compact** | `labelMedium` | **500** | ` :143`, raw rung | ✗ **P2-1** |

**Is every variant intentionally at w700?** Four of five, yes — and the
intent is well recorded (` :418–430`, `component_theme_typography_test.dart:131–162`).
The fifth is an oversight, not a decision: it predates M100.30 and nothing in
the file argues for a lighter compact link.

**Should compact/list buttons share the rung?** They already do, correctly —
`MxActionButton` compact steps the *size* down (`labelLarge` → `labelMedium`)
and holds the weight. That is the right axis to move, and the reasoning at
` :303–305` is sound: a 48-button's rung on a 40 body reads as text escaping its
control, while a lighter compact button reads as a different kind of control.

**Should TextButton share the emphasis?** Yes, and it does at standard size.
The argument at ` :335–338` — Tokyo's `fontWeight: 'bold'` sits on
`MuiButton.root`, the base all three variants share — is the right one, and it
applies to the compact link too.

**Does w700 create a hierarchy problem against titles and section labels?**
Measured against the type scale:

| role | size | weight |
|---|---|---|
| `displayLarge` / `displayMedium` | 57 / 45 | 700 |
| `headlineLarge` / `headlineSmall` / `titleLarge` | 32 / 24 / 22 | 600 |
| `titleMedium` / `titleSmall` | 16 / 14 | 600 |
| **button label** | **14** | **700** |
| `labelLarge` (chips, section labels) | 14 | 600 |
| `bodyLarge` / `bodyMedium` | 16 / 14 | 400 |

A button label is therefore **heavier than every title in the app except the two
display rungs, at a smaller size than any of them.** In isolation this is fine —
weight and size are independent channels and a control legitimately uses weight.
Where it is worth a look is the two places a 14/700 button sits directly beside
a 14/600 or 16/600 title: `deck_list_toolbar_widget.dart` (heading + sort
control) and `study_home_deck_item_widget.dart` (deck name at `titleMedium` 16/600
beside a compact Study at 12/700). In the second, the *action* is the heavier
ink on the row while the deck *name* is the larger — which is the intended
reading for a list whose job is to be studied from, and the compact size step
already does the disambiguating work.

**Recommendation: keep w700, and fix P2-1.** The evidence is that the weight is
doing its job at four of five surfaces and that the fifth is the only place the
system is visibly inconsistent with itself. Do not revisit the value; close the
gap.

**Variable-font axis:** applied correctly everywhere it is applied.
`AppTypography.withWeight` (` :174–175`) sets `fontWeight` *and* `fontVariations`
together, and three tests assert the axis rather than the reported weight
(`mx_components_test.dart:163–166`, `focus_ring_contrast_test.dart:292–297`,
`component_theme_typography_test.dart`). The one place the axis is *not* moved
is P2-1 — and there it reports 500 and paints 500, so it is honest, just wrong.

---

## 9. Geometry findings

| | standard | compact | M3 default | MemoX token |
|---|---|---|---|---|
| painted height | **48** | **40** | 40 | `AppSizing.touchTarget` / `.controlCompact` |
| min tap height | 48 | **48** (`padded`) | 48 (`materialTapTargetSize: padded`, `app_theme.dart:153`) | `AppSizing.touchTarget` |
| horizontal padding | **24** | **12** | 24 (→12→6 with text scale) | `AppSpacing.xl` / `.md` |
| vertical padding | **12** | **0** | 0 | `AppSpacing.md` / — |
| radius | **12** | 12 | `StadiumBorder` | `AppRadius.md` |
| icon size | **16** | 16 | **18** | `AppIconSize.sm` |
| icon gap | **8, fixed** | 8, fixed | `lerp(8, 4, scale)` | `AppSpacing.sm` |
| min width | **64** | 64 | 64 | `AppSizing.buttonMinWidth` |
| max lines | 2, then ellipsis (` :400`) | 2 | 1 | — |

**Deliberate and right:**

- 48 over M3's 40 — the touch floor, stated once in `buildSharedButtonStyle` so
  no screen can go under it. `mx_components_test.dart:103–116` pins it.
- 12 radius over `StadiumBorder` — `tokyo-component-mapping.md:124`, a tier
  translation rather than a pixel copy.
- 40 drawn / 48 hit for compact — `mx_components_test.dart:118–166` measures
  both halves separately, including the trap of measuring the padded outer box.
- 2 lines before ellipsis — `mx_action_button.dart:398–399` records the German
  destructive-dialog case at textScaler 3.0. This is the correct mobile answer
  and M3's single line is not.
- Icon at 16 rather than M3's 18 — `AppIconSize.sm`, consistent with every other
  16dp glyph in the app.

**Worth acting on:**

- **Vertical padding disappears in compact** (` :294–296`). The flat `padding`
  shadows the theme's `v 12` completely, so compact's height comes entirely from
  `minimumSize: 40`. It works today because `labelMedium`'s 16dp line box plus
  nothing is under 40. At textScale 2.0 the line box is 32 — still under 40, so
  no break — but the button then has zero breathing room above and below its
  label at exactly the scale where it needs the most. Not a defect; a thin
  margin nobody chose.
- **The fixed icon gap** (P2-5).
- **`_kButtonMinWidth = 80`** (P2-4) — the only geometry literal outside the
  shared component.
- **Standard vertical padding does not scale down with text.** M3 shrinks
  horizontal padding 24 → 12 → 6 as the label grows; MemoX's flat
  `WidgetStatePropertyAll` holds 24 at every scale. At 320dp × 2.0 that is 48dp
  of a 288dp content width spent on padding before the first glyph.
  `mx_stress_test.dart` currently passes with it because the label wraps to two
  lines instead of overflowing — so this is a *density* observation, not a
  breakage, and it should be measured before it is changed.

**Geometry duplicated outside the shared component:** two instances only —
`_kButtonMinWidth` (P2-4) and `MxActionButton._sized`'s compact block, which is
sanctioned by the size enum but does formally restate `minimumSize` and
`padding`, values `tokyo-component-mapping.md:224` says a widget MUST NOT
restate. The contract as written admits no size axis; either the contract gains
one or `AppSizing` gains a compact padding token.

---

## 10. Accessibility and state findings

### Single states

| state | verdict | evidence |
|---|---|---|
| rest | ✓ | label ≥ 4.5:1 on its own fill in all 4 themes — `mx_action_button_state_matrix_test.dart:117–121` |
| hover | ⚠ brand only | ΔE 1.11 light / 0.64 dark. Web/desktop only; low priority on its own |
| press | ⚠ brand only | ΔE 2.08 / 1.22, ripple ΔE 0.28 / 0.17 — **P1-3, and this one is on-device** |
| press | ⚠ tonal/destructive | ΔE 9.92–11.71, hue −7.2° on destructive — **P1-1** |
| focus | ✓ | `side` ring in the label colour, ≥ 3:1 on both the resting and the focus-composited fill, all variants, all 4 themes. Pinned by `focus_ring_contrast_test.dart` per ground |
| disabled | ✓ visually, ⚠ numerically | `disabledSurface` is a solid, so the control is unmistakably inert; the label sits at 2.05:1 / 2.51:1, which WCAG exempts for an inactive control |
| loading | ✓ | width does not move (`mx_action_button_state_matrix_test.dart:240–251`), second tap is blocked (` :266`), name survives via `alwaysIncludeSemantics` (` :269`) |

### Combined states

| combination | verdict | evidence |
|---|---|---|
| focused + destructive | ✓ | ring = `onError`, 5.77:1 on the resting fill / 6.30:1 on the focus-composited fill |
| focused + outlined | ✓ | ring replaces the hairline on the same `OutlinedBorder` side, so **focus costs zero layout** (` :389–392`) — the right mechanism |
| focused + touch device | ✓ | `_takesFocus()` (` :167–169`) suppresses autofocus under `FocusHighlightMode.touch`, so a phone does not show a ring nobody asked for. Well-reasoned at ` :148–166` |
| disabled + loading | ✓ | loading *is* disabled (` :175`); `_busyStyle` restores the fill only where the label is on show |
| **destructive + loading + kept label** | ✗ | **P1-2** — falls to 2.05:1, no caller today |
| icon + loading | ⚠ | icon is silently dropped (P3-4); reachable today at `card_editor_action_bar_widget.dart:86` |
| compact + long text | ✓ | 2 lines then ellipsis; `mx_stress_test.dart` covers 320 × 2.0 for `primary` only |
| compact + destructive/tonal | untested | no golden, no stress specimen, no production caller |

### Mechanism checks

- **Focus does not move layout.** Confirmed for both families: the filled
  variants get a `side` where none existed, and `RoundedRectangleBorder`'s side
  is painted *on* the shape rather than added to the box; the outlined variant
  thickens an existing side. Neither changes `minimumSize` or `padding`.
- **Loading does not change width.** Confirmed by construction (`Stack` +
  `Opacity(0, alwaysIncludeSemantics: true)`, ` :435–441`) and by test.
- **Ripple/Ink is correct on Android** — structurally. `splashFactory` is left
  to the theme, so `InkRipple` runs. What is wrong is its *colour*: absent on
  the brand fill, foreign on the other two (P1-1, P1-3). This is the finding
  most specific to the release target.
- **Semantics.** `semanticLabel` rebuilds the node with `container`, `button`,
  `enabled`, `focusable` and `onTap` restated (` :193–205`), which is the
  correct fix for the `ExcludeSemantics` trap and is documented at ` :98–103`.
  Hit testing is untouched, so a sighted tap keeps its splash and haptic.

---

## 11. Tokyo traits worth keeping

Tokyo is a web/desktop kit; MemoX is mobile-first. These are the traits whose
*intent* survives the translation, already applied or worth applying:

| trait | intent | status |
|---|---|---|
| `MuiButton.root` `fontWeight: bold` | an action reads as an action, not as a coloured label | **applied** — `buttonLabelWeight` w700, M100.30. Close P2-1 to finish it |
| tight control radius (`MuiButtonBase` 6) | controls feel crisper than surfaces | **applied as a tier** — `AppRadius.md` 12, not 6px |
| solid, opaque disabled fill | a disabled control is a *different surface*, not a faded one | **applied** — `semantic.disabledSurface`, and it is why `disabled` reads unmistakably even at 2.05:1 |
| one filled emphasis per view | the brand fill is scarce | **partially applied** — honoured on dialogs and lists, violated at `study_card_face_section_widget.dart` (P2-2) |
| state feedback as a *lightness* move | press darkens/lightens the same colour rather than tinting it | **the right intent, wrongly implemented** — MemoX's blend does this correctly; the surviving `primary` overlay is what tints. Fixing P1-1 is how this trait actually lands |
| destructive as a **label**, not a fill, for low-emphasis actions | red text where a red block would shout | **applied** — `MxTextButton.isDestructive`, `textLinkForeground` |

---

## 12. Tokyo desktop traits to reject

| trait | why it does not transfer |
|---|---|
| `sizeSmall/Medium/Large` 33 / 38 / 44 px | all three are under the 48dp touch floor. MemoX renders exactly two heights (48, 40) and `AppSizing:37–42` already records the refusal to invent a five-rung ladder. `tokyo-component-mapping.md` likewise defers `MuiTab` height 38 for the same reason |
| hover-first affordance | Android is the release target (AD-04). Hover is the E2E channel's state, not the user's. This is why P1-3 ranks press above hover even though both are weak |
| `disableRipple` | the ripple is the only press feedback a touch device gets. The correct action on P1-3 is to **fix the ripple colour**, never to remove it |
| exact CSS padding (`8px 20px`) | 20 is not on `AppSpacing`. Already refused — `tokyo-component-mapping.md:123` keeps 24 |
| exact radius 6 / 10 px | already translated to tiers (12 / 16), not copied |
| single-line labels | a German or Vietnamese destructive label at textScaler 3.0 ellipsises to nothing on one line. `maxLines: 2` (` :400`) is the mobile answer and must stay |
| backdrop blur behind modals | explicitly deferred at `tokyo-component-mapping.md:137` pending a shared recipe and a performance measurement. Not a button concern; noted so the next pass does not pick it up by accident |

---

## 13. Widgetbook and golden gaps

### Widgetbook — `widgetbook/lib/components/control_components.dart:24–158`

Better than the golden set. Two use cases:

- **Playground** (` :27–63`) — knobs for label, variant, size, enabled, loading, icon.
- **Variants and states** (` :64–157`) — a 6 × 4 matrix: resting (first
  autofocused, so the focus ring is on screen), with icon, disabled, loading,
  compact, long label in a 150dp column — each row across all four variants.

Missing: `shouldKeepLabelWhileLoading`, `semanticLabel`, textScale 2.0, and a
320dp frame. Hover and press are deliberately left to the reviewer's pointer,
which is the right call for a live catalogue.

### Goldens

Committed, `test/shared/widgets/goldens/`:

| key | modes | source |
|---|---|---|
| `button_primary` | light, dark | `mx_components_golden_test.dart:89` |
| `button_secondary` | light, dark | ` :94` |
| `button_disabled` | light, dark | ` :103` |
| `text_button`, `_disabled`, `_focused`, `_destructive` | light, dark | ` :122–160` |
| `compact_screen` (contains a standard `MxActionButton`) | light, dark | `mx_components_compact_golden_test.dart:98` |

Loading is **deliberately excluded** (` :172–175`): a `CircularProgressIndicator`
is an unbounded animation and a golden of it is flaky by construction. That
reasoning is sound and should be preserved — do not add a loading golden.

**Missing, in priority order:**

| gap | why it matters |
|---|---|
| `button_destructive` (rest) | the one variant whose palette is not the brand's, and the subject of P1-1 |
| `button_tonal` (rest) | zero callers today; a golden is what would let it be re-adopted safely |
| `button_compact` | 40/48 is asserted numerically but never seen |
| `button_primary_focused` | focus is the state whose *indicator mechanism* differs per variant, and only the text button has a focus golden |
| `button_icon` | icon size and gap are hand-built in the widget, not resolved from `ButtonStyle.iconSize` — nothing pins them visually |

**Minimum useful golden set — 5 new keys × 2 modes = 10 files.** Deliberately
not the 5 × 7 matrix the task sketches: a golden is worth its maintenance only
where a *pixel* can be wrong in a way a numeric test cannot see, and
`mx_action_button_state_matrix_test.dart` already covers every variant × state ×
theme *numerically* across four themes. Hover and press belong to Widgetbook,
long-label to `mx_stress_test.dart`, and loading nowhere.

A cheaper alternative worth considering first: one **specimen sheet** golden per
mode — all four variants × {rest, focus, disabled, compact, icon} in a single
grid, mirroring the Widgetbook matrix. Two files instead of ten, one diff to
read, and the pattern already exists in this repo
(`card_detail_state_grid_vi_x2`).

---

## 14. Implementation plan for the next pass

Sequenced so each step is independently reviewable and each has a gate. None
needs a new abstraction.

### Step 0 — confirm the two headline numbers at render level

Before changing anything, render `destructive` and `tonal` hovered/pressed and
read the composited pixel off the frame rather than off arithmetic. Everything
in §3.2 is computed with the repo's own `Color.alphaBlend`/`Color.lerp` model,
and the framework path is established from 3.44.8 source — but a report that
recommends a colour change should have looked at the colour. A widget test with
`WidgetStatesController` and `tester.layers` / a single `matchesGoldenFile`
against a throwaway file is enough; it does not need to be committed.

**Gate:** the measured press pixel for light destructive is `#AB0F47` ± 1 per
channel. If it is not, stop and re-derive §3 before touching §5's conclusion.

### Step 1 — give the filled family its canonical overlay (closes P1-1, P1-3)

In `app_button_themes.dart`, add an overlay resolver alongside the existing
background blend in `buildFilledStyle`, built from `pair.labelOf(scheme)` rather
than from `scheme.primary`. Two shapes are defensible and the choice is the
owner's:

- **(a) Replace, M3-faithful.** Drop the background blend, keep only
  `on<Fill>` @ .08/.10/.10. Smallest surface, exactly M3, and it fixes the brand
  button's weak press for free (ΔE 5.74 light). Cost: the blend and its
  `AppStateOpacity.filledHoverBlend` / `filledPressedBlend` tokens, and the
  `.mx-btn--primary:hover` `color-mix` lineage they transcribe, go away.
- **(b) Keep the blend, neutralise the overlay.** Keep `lerp(→onSurface)` and
  set the filled family's `overlayColor` to `on<Fill>` at a reduced alpha, or to
  transparent. Preserves the kit's press character; requires re-tuning the blend
  upward, because the current values were chosen while an overlay was (invisibly)
  also present.

**Recommendation: (a).** It is the smaller change, it restores a canonical role
rather than inventing a second calibration, it removes the need for anyone to
reason about two mechanisms again, and the divergence it retires is one the
palette no longer needs — `primary` moved at M100.18/M100.28 and the "6% accent
on accent is invisible" premise is about the *overlay colour*, which (a) also
changes.

**Gate:** extend `mx_action_button_state_matrix_test.dart` with a composite
assertion — `alphaBlend(overlay(state), background(state))` vs `background(rest)`
— asserting ΔE (or a luminance delta) within a stated band per variant, so the
next calibration cannot silently over- or under-shoot. This is the single most
valuable test to add, because it is the one the current file structurally cannot
express.

### Step 2 — thread `busyStyle` into the destructive branch (closes P1-2)

`mx_action_button.dart:263–276`: `style: _sized(context, busyStyle ?? buildFilledStyle(...))`,
matching the `tonal` branch at ` :237–246`. One line. Then simplify
`_busyStyle`'s switch (` :359–370`) so `destructive` reads as reachable.

**Gate:** add `destructive` + `shouldKeepLabelWhileLoading` to
`mx_action_button_state_matrix_test.dart`'s loading group and assert the label
pair clears 4.5:1.

### Step 3 — close the typography gap (closes P2-1)

`mx_text_button.dart:143`: `AppTypography.withWeight(context.texts.labelMedium!, buttonLabelWeight)`.
Note this style also shadows the theme's focus-underline resolver for all
states; the widget-level `_StateStyledLabel` still draws the underline, so
behaviour is preserved, but the `_style` builder should resolve rather than
flatten so the two paths agree.

**Gate:** extend `component_theme_typography_test.dart`'s button-weight test to
pump an actual `MxTextButton(isCompact: true)` and read the `wght` axis off the
`RenderParagraph`, the way `mx_components_test.dart:163–166` does for compact
`MxActionButton`. A theme-slot test cannot see a widget-level override, and that
is exactly how this one survived M100.30.

### Step 4 — decide the study grading hierarchy (closes P2-2)

This is a **product decision, not a refactor**, and it needs the owner. The
question: for a scheduler with N grading actions, which are `primary`? The
recall timer already answers it for N=2 (`secondary` for the lapse,
`primary` for the success, with the reasoning in place at
`recall_timer_pieces_widget.dart:194–198`). For SM-2's N=4 the candidates are
`again` = `secondary`, `good` = `primary`, `hard`/`easy` = `secondary` or
`tonal`. **This is where the zero-caller `tonal` variant could earn its
existence** — and note `StudyAction.isLapse` already exists
(`get_session_summary_use_case.dart:34`), so the domain can answer "is this the
miss?" without presentation inventing a rule.

Until it is decided, do not change the code. A wrong hierarchy shipped is worse
than a flat one.

### Step 5 — housekeeping (P2-3 … P3-2)

- Delete `tonal` **or** adopt it in step 4. Do not leave it with a doc citing a
  removed call site. If it stays, correct the enum doc's 10.37:1 / 9.09:1 to
  9.51:1 / 9.05:1 and re-point the "case it was added for".
- `_kButtonMinWidth` → `AppSizing`, or delete it and let `buttonMinWidth` do the
  job (measure the deck tile first — 80 may have been load-bearing for the
  gauge beside it).
- Icon gap → `lerpDouble(AppSpacing.sm, AppSpacing.xs, clamp(textScale)−1)`,
  matching `filled_button.dart:512`.
- Correct the five stale 2.29:1 / 2.90:1 citations to 2.05:1 / 2.51:1.
- Correct `deck_study_button_widget.dart:41,43–45` to say 700.
- Add the 5 golden keys (or the 2 specimen sheets) from §13.
- Add a `RoleBinding` for `FilledButton.overlayColor` in
  `m3_role_bindings.dart` so step 1's decision is held by the AST guard the way
  `OutlinedButton.side` already is. Today the guard covers no `FilledButton`
  slot at all.

---

## 15. Files a future implementation would touch

**Production**

| file | steps | what |
|---|---|---|
| `lib/core/theme/components/actions/app_button_themes.dart` | 1 | `buildFilledStyle` gains a pair-derived `overlayColor`; possibly loses the background blend |
| `lib/core/theme/states/app_interaction_states.dart` | 1 | `AppStateOpacity.filledHoverBlend` / `.filledPressedBlend` retired under option (a); `controlOverlay`'s doc corrected to say it is the *outlined* family's answer |
| `lib/shared/widgets/mx_action_button.dart` | 2, 5 | destructive branch threads `busyStyle`; `_busyStyle` switch simplified; icon gap scales; enum doc corrected |
| `lib/shared/widgets/mx_text_button.dart` | 3 | compact rung re-weighted; `_style` resolves rather than flattens |
| `lib/features/study/presentation/widgets/sections/study_card_face_section_widget.dart` | 4 | grading hierarchy — **after** the owner decides |
| `lib/features/deck/presentation/widgets/items/deck_study_button_widget.dart` | 5 | `_kButtonMinWidth` removed or promoted; stale w600 comment |
| `lib/core/theme/foundations/app_sizing.dart` | 5 | only if `_kButtonMinWidth` is promoted |
| `lib/core/theme/components/selection/app_toggle_themes.dart` | 5 | two stale 2.29:1 citations |

**Tests**

| file | steps |
|---|---|
| `test/shared/widgets/mx_action_button_state_matrix_test.dart` | **1, 2** — the composite assertion is the core new gate |
| `test/core/theme/contracts/focus_ring_contrast_test.dart` | 1 — the "focus wash changes nothing" test is asserted against the brand pair and will need re-framing per pair |
| `test/core/theme/contracts/m3_role_bindings.dart` | 5 — new `FilledButton.overlayColor` binding |
| `test/core/theme/components/component_theme_typography_test.dart` | 3 |
| `test/shared/widgets/mx_components_test.dart` | 5 — tonal framing, if tonal survives |
| `test/shared/widgets/mx_components_golden_test.dart` | 5 — new specimens |
| `test/shared/widgets/mx_stress_specimens.dart` | 5 — compact and destructive at 320 × 2.0 |
| `test/features/study/presentation/study_card_face_test.dart` | 4 |

**Goldens** — regenerate on **Linux only** (CLAUDE.md; `ci.yml`'s golden job is
`ubuntu-latest`; a Windows `--update-goldens` writes PNGs CI rejects and does it
silently). Step 1 moves hover/press/focus pixels, which the *existing* button
goldens do not capture (they are resting and disabled), so the blast radius is
small — but any screen golden showing a resting destructive or tonal button is
unaffected only if option (a) leaves resting colours alone, which it does.

**Widgetbook** — `widgetbook/lib/components/control_components.dart`: a
`shouldKeepLabelWhileLoading` row, and a textScale-2.0 frame.

**Docs**

| file | what |
|---|---|
| `docs/design-system/tokyo-component-mapping.md:45` | the FilledButton overlay row — rewrite once step 1 lands; today it describes a substitution the code does not perform |
| `docs/design-system/tokyo-component-mapping.md:224` | §5's geometry MUST NOT admits no size axis; either it gains one or `_sized` needs an explicit exemption |
| `docs/wbs.md` | the step entries, in the same commit as the code |
| `docs/reviews/design-parity-checklist.md` | the button rows' verdicts, if step 1 changes what parity means |

**Not touched:** `docs/business-rules.md`, `docs/architecture.md`,
`docs/use-cases.md` — nothing here is a business rule or an architecture
decision. Every finding is a calibration, a role binding or a composition
choice.

---

## Appendix — how to reproduce the measurements

1. `git checkout 4cfddd3d`
2. Palette constants: `lib/core/theme/foundations/app_colors.dart`,
   `app_material_roles.dart`, `app_surface_colors.dart`, `app_border_colors.dart`;
   role bindings in `lib/core/theme/schemes/app_color_scheme.dart:49–150`.
3. Alphas: `lib/core/theme/states/app_interaction_states.dart:19–89`.
4. Composite with `alphaBlend(overlay, lerp(fill, onSurface, blend))` — the same
   two functions `focus_ring_contrast_test.dart:224` and
   `app_button_themes.dart:184` use.
5. M3 side: `_FilledButtonDefaultsM3`, `_FilledTonalButtonDefaultsM3`
   (`filled_button.dart`), `_OutlinedButtonDefaultsM3` (`outlined_button.dart`),
   `_TextButtonDefaultsM3` (`text_button.dart`) at Flutter `058e0af2c2b`.
6. Call-site inventory: parse every `MxActionButton(` / `MxTextButton(`
   invocation under `lib/` with comment-stripping and quote-aware paren
   matching, then read the named arguments. Counts in §6 and §7 come from that
   parse, not from `grep`.
