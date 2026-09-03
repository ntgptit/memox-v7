# A19 — High-contrast / accessibility system deep audit

| | |
|---|---|
| Verdict | **CONDITIONAL FAIL** — one P0, five P1 (three carried from an earlier audit), thirteen P2, six P3 |
| BASE_SHA | `3207e7b7e0d3a2ecefa5e6a85fed48a65890ba6b` (`3207e7b`) — *the dark card stops glowing, and elevation stops meaning two things* (M100.35, #435) |
| Pinned SDK | Flutter **3.44.8** (`.fvmrc`) · Dart SDK `^3.12.2` |
| Scope | Every accessibility surface reachable in production UI under `lib/` — `AppHighContrast`, both high-contrast `ColorScheme`s, the semantic palette, focus, keyboard, `Semantics`/`ExcludeSemantics`/`MergeSemantics`, labels and tooltips, selection/checked/toggled semantics, touch targets, text scaling, live/feedback states — plus the guards and tests that are supposed to hold them, on EN and VI copy |
| Mode | **Report only.** No production, theme, test, Widgetbook, ARB, doc or golden file was changed. No golden was regenerated. The diff is this file |
| Concurrency | `origin/main` advanced to `55a2179` while this ran. **Deliberately not merged** — the audit is pinned to BASE_SHA so every number below is reproducible against one tree |

---

## 0 · Method, and what it could not do

Every contrast figure in this report was **computed**, not recalled: the palette
constants were transcribed out of `lib/core/theme/foundations/*.dart` and
`lib/core/theme/schemes/app_color_scheme.dart` into a throwaway Python model of
`highContrastScheme()` / `highContrastSemantics()`, and the ratios come from the
WCAG 2.x relative-luminance formula with sRGB alpha compositing for the
translucent tokens. The script lived in the session scratchpad, never in the
repository; `git status` is clean apart from this file.

**What this environment could not do, stated plainly rather than papered over.**
There is no Flutter SDK in this container (`which flutter` → not found), so:

- **no measurement harness was pumped.** The previous component audits could
  read rects, resolved styles and semantics nodes off a real tree; this one
  could not. Every *geometry* figure below is arithmetic over the tokens
  (`AppSpacing`, `AppIconSize`, the type scale's declared `fontSize`/`height`),
  and each one is labelled as such at the point it is used.
- **`dart format`, `flutter analyze`, `flutter test`, the architecture guard and
  `check_docs.py` were not run.** Nothing here changes Dart, so analyze and the
  guard have nothing to say about the diff; `docs/reviews/` is explicitly
  outside `check_docs.py`'s header contract (its own docstring names the
  directory), so the report format follows the house style of the sibling audits
  rather than the seven-line document header.
- **semantics-tree *merge* behaviour was not observed.** Where a finding depends
  on whether two annotations land on one node or two, it is written as "no test
  pins this" rather than as an assertion about what a reader hears. That is the
  honest form, and it is also the finding: the closure test is what is missing.

Everything else — which tokens exist, what re-points under high contrast, which
`Semantics` properties are set where, which screens are swept by which guard,
what the ARB files contain — is read directly off the tree at BASE_SHA and is
exact.

---

## 1 · Executive verdict

**The accessibility system in this codebase is well above the norm, and it is
uneven in a specific, diagnosable way: the answers are excellent where a shared
component owns them, and absent where the decision was left to a call site.**

`MxActionButton`, `MxIconButton`, `MxActionSheet`, `MxCheckboxRow`,
`MxNavigationBar`, `MxFeedbackBand`, `MxMessenger`, `MatchTileWidget`,
`GuessOptionItemWidget` and `AppMotionPolicy` are, individually, better than
most production Flutter. Reduced motion is read off the platform flag and
applied only to decorative transitions. Every one of 836 ARB keys exists in both
locales. `mx_stress_test.dart` pumps every shared component at 320 dp × 2.0×
scale in Vietnamese, in both brightnesses, and asserts tap targets. The
high-contrast slots on `MaterialApp` are wired, which is more than most apps do
at all.

What fails, fails at the seams:

- **One interaction has no accessible operation at all.** `browse` — the first
  stage of every `eight_box` new-learning sequence (BR-110) — advances only by a
  70 dp horizontal drag. There is no button (removed on purpose), no keyboard
  path (the repository contains zero `Shortcuts`, zero `CallbackShortcuts`, zero
  `LogicalKeyboardKey`), and no single-pointer alternative. The two
  `customSemanticsActions` serve a screen reader and nothing else.
- **High contrast re-points four tokens out of eight, and the four it skips
  include the only control boundary in the palette that fails 3:1.**
  `borderOption` measures **2.67:1** in light on the exact ground it is drawn
  on, on a component whose fill is 1.00:1 against that ground — the edge *is* the
  control — and the high-contrast palette leaves it untouched.
- **A single-choice control announces its selection with nothing.** A sort menu's
  current value is marked by `PopupMenuButton.initialValue`, which paints
  `Theme.highlightColor` at **1.18:1** (light) / **1.32:1** (dark) and emits no
  `selected`, no `checked`, no `inMutuallyExclusiveGroup`. The same interaction
  done through `MxActionSheet` is correct — so the app holds two opinions.
- **The measurement table that documents the high-contrast palette is stale in
  every row.** The argument for raising disabled ink says the result lands at
  4.88:1 in light. It lands at **3.80:1**.
- **The guard that exists for exactly this class of defect cannot see it.**
  `NonTextContrastRule`'s informational-token list carries `primary`, the four
  semantics and `borderControl` — and omits `borderOption` and `borderSelected`.
- **No screen, golden or catalog surface renders under either high-contrast
  theme.** Four test files reference them; none of the four pumps a screen. The
  role-identity property the flag is supposed to preserve is unverified above
  the token layer.

### 1.1 · Findings at a glance

| # | Finding | Sev |
|---|---|---|
| A19-01 | `browse` advances only by a 70 dp drag — no button, no keyboard, no single-pointer alternative | **P0** |
| A19-02 | `borderOption` is **2.67:1** light on its own ground, is the whole component boundary, and high contrast does not re-point it | **P1** |
| A19-03 | A single-choice `MxMenuButton` marks its value at **1.18:1 / 1.32:1** with no selection semantics | **P1** |
| A19-04 | High contrast re-points 4 of 8 border tokens, and after the swap `borderSubtle` (5.28) reads **louder** than `borderSelected` (3.96) | **P2** |
| A19-05 | Every measurement in `app_high_contrast.dart` is stale (4.88:1 is really **3.80:1**), and its "three grounds" are two | **P2** |
| A19-06 | The dimmed trash row is a raw `Opacity(0.38)`: **2.11 / 1.69:1** text, and high contrast cannot reach it | **P2** |
| A19-07 | Section headings follow four policies, one complete: **2 of 15 group headings** are announced as headings | **P2** |
| A19-08 | 21 `toUpperCase()` render sites, **1** with the TTS mitigation the codebase itself documents | **P2** |
| A19-09 | `MxErrorState` / `MxEmptyState` are not live regions; three features hand-roll it | **P2** |
| A19-10 | The card list's sort control is **24 dp** tall against the project's declared 48 | **P2** |
| A19-11 | The card row announces its state twice — dot label plus printed word | **P2** |
| A19-12 | `MxContentShell` caps its title at `maxLines: 1` + ellipsis whenever a subline is present | **P2** |
| A19-13 | `NonTextContrastRule` omits `borderOption` and `borderSelected` — the rule cannot see the token that fails it | **P2** |
| A19-14 | 10 of 17 screens have no `meetsGuideline` sweep, the whole `card` feature among them | **P2** |
| A19-15 | Nothing renders a screen, golden or catalog surface under a high-contrast theme | **P2** |
| A19-16 | `recall`'s 20 s clock has no recorded WCAG 2.2.1 position and no way to extend | **P2** *(owner decision)* |
| A19-17 | `card_import_stepper` sets `selected:` on a step node that cannot be selected | P3 |
| A19-18 | The card sort control announces its name but never its current value | P3 |
| A19-19 | `MxSwitchRow`'s announced pattern stacks `value` on a node that already carries `toggled` | P3 |
| A19-20 | `showModalBottomSheet` passes `useSafeArea: true` at 2 of 17 sites | P3 |
| A19-21 | 34 `ExcludeSemantics` wrappers, several around glyphs that self-exclude | P3 |
| A19-22 | Nothing reads `MediaQuery.boldText` or `accessibleNavigation` | P3 |

### 1.2 · Carried forward — recorded elsewhere, still open at BASE_SHA

These were measured by `docs/reviews/mx-text-field-deep-audit.md` (base
`4cfddd3d`) and re-verified in the source at BASE_SHA. They are accessibility
defects and they belong in an accessibility verdict, so they are counted in it —
but they keep their original IDs rather than being re-registered under new ones.

| Prior ID | Finding | Sev | Re-verified at BASE_SHA |
|---|---|---|---|
| F1 | `MxSearchField` has **no accessible name** once it holds a value | **P1** | `mx_search_field.dart:150-176` — the inner `TextField` carries `hintText` only; no `labelText`, no `Semantics(label:)`. `hintText` is replaced by the value |
| F2 | `MxSearchField`'s box is pinned at 48 dp and **ignores `textScaler`** | **P1** | `mx_search_field.dart:148` — `SizedBox(height: AppSizing.touchTarget)`, a constant, wrapping `expands: true` |
| F3 | **Focus is invisible on an errored field** | **P1** | `app_input_theme.dart:42-43` — `errorBorder` and `focusedErrorBorder` are both `_inputBorder(scheme.error)`, and `AppStroke.input` never moves |

---

## 2 · The contrast model this audit applied

### 2.1 · Thresholds

The task's thresholds, and the project's own where they are stricter — the
stricter one wins, which is the project's own rule (AD-14: *"when a role fails a
contrast or hierarchy ratio, the palette moves — never a substitute token, never
a lowered floor"*).

| What | Floor | Source |
|---|---|---|
| Normal text | 4.5:1 | WCAG 1.4.3 |
| Large text (≥ 18.66 px bold / ≥ 24 px) | 3:1 | WCAG 1.4.3 — applied **only** where the type scale genuinely reaches it |
| A component boundary or state indicator that is *required* to identify the component | 3:1 | WCAG 1.4.11 |
| A focus-visible indicator, against the ground adjacent to it | 3:1 | WCAG 1.4.11 |
| A decorative neutral border | **no automatic floor** | 1.4.11 covers what is *required* to identify a component; a card is identified by its content |
| Disabled ink, in high contrast | 3:1 | `app_high_contrast_test.dart` — the project declines the 1.4.3 "inactive component" exemption in this mode, and says so |
| Any touch target | **48 dp**, not 24 | `AppSizing.touchTarget` — the project's declared floor, stricter than WCAG 2.5.8's 24 |

**Which type actually qualifies as "large".** The app's scale tops out at
`titleLarge` 22/28 for an app-bar title and `AppTextStyles.cardPrompt` for the
study prompt. Only those two reach the large-text band, and only the prompt does
so at a weight that would let 3:1 apply. Every section label
(`sectionLabel` 11–14), every body rung and every state label is normal text and
is held to 4.5:1 below. No finding in this report leans on the large-text
allowance.

### 2.2 · The palette, measured — normal themes

Every border token against every ground the palette can put it on. `*` marks
under 3:1. `page` is omitted as a separate column **because it no longer is
one**: `app_theme.dart` sets `scaffoldBackgroundColor: scheme.surface`, so the
page and `surface` are one colour and have been since M100.32.

**Light**

| token | surface / page | surfaceContainerLow | surfaceContainer | surfaceContainerHigh | surfaceContainerHighest | surfaceSelected | secondaryContainer |
|---|---|---|---|---|---|---|---|
| `borderSubtle` | 1.14* | 1.24* | 1.11* | 1.04* | 1.02* | 1.03* | 1.09* |
| `borderDivider` | 1.00* | 1.09* | 1.02* | 1.09* | 1.15* | 1.10* | 1.24* |
| `borderAccent` | 1.80* | 1.97* | 1.75* | 1.65* | 1.56* | 1.63* | 1.45* |
| **`borderOption`** | **2.45\*** | **2.67\*** | **2.39\*** | **2.24\*** | **2.12\*** | **2.22\*** | **1.98\*** |
| `borderControl` / `outline` | 4.40 | 4.81 | 4.29 | 4.02 | 3.81 | 4.00 | 3.55 |
| `borderSelected` | 3.96 | 4.33 | 3.86 | 3.62 | 3.43 | 3.60 | 3.20 |
| `primary` (focus ring) | 5.67 | 6.20 | 5.53 | 5.19 | 4.91 | 5.16 | 4.58 |

**Dark**

| token | surface / page | surfaceContainerLow | surfaceContainer | surfaceContainerHigh | surfaceContainerHighest | surfaceSelected | secondaryContainer |
|---|---|---|---|---|---|---|---|
| `borderSubtle` | 1.41* | 1.30* | 1.15* | 1.06* | 1.09* | 1.09* | 1.10* |
| `borderDivider` | 1.44* | 1.32* | 1.17* | 1.08* | 1.07* | 1.07* | 1.08* |
| `borderAccent` | 3.88 | 3.57 | 3.17 | 2.90* | 2.52* | 2.52* | 2.49* |
| **`borderOption`** | 3.62 | **3.33** | **2.95\*** | **2.71\*** | **2.35\*** | **2.35\*** | **2.32\*** |
| `borderControl` / `outline` | 4.68 | 4.30 | 3.82 | 3.50 | 3.03 | 3.03 | 3.00 |
| `borderSelected` | 5.73 | 5.27 | 4.68 | 4.29 | 3.72 | 3.72 | 3.68 |
| `primary` (focus ring) | 11.27 | 10.37 | 9.20 | 8.43 | 7.31 | 7.31 | 7.24 |

Read this table with the exemption in hand. `borderSubtle` and `borderDivider`
being at 1.0–1.4 is **not** a defect: they are decoration, the project says so in
as many words (`app_high_contrast_test.dart`: *"a card is identified by its
content and its edge is decoration, which is the exemption WCAG grants"*), and
holding a hairline to 3:1 would turn a column of surfaces back into a column of
frames — which is the regression M99.94 spent a milestone undoing. `borderAccent`
is the Today card's emphasis edge, also decoration.

`borderOption` is the row that matters, and §4 is about why.

**The focus indicator clears its floor everywhere, in both modes.** `primary` is
the ring (`AppInteractionStates.focusIndicator`), its lowest reading is 4.58:1 in
light on `secondaryContainer`, and `focus_ring_contrast_test.dart` already holds
3:1 against four grounds including that one. This is the strongest part of the
system and nothing in this report asks for it to change.

### 2.3 · The high-contrast model

`highContrastSemantics()` and `highContrastScheme()` re-point **six slots across
four decisions** and add no hex:

| slot | normal | high contrast |
|---|---|---|
| `borderSubtle` | `#E4E7EA` / `#272C48` | `onSurfaceVariant` |
| `borderControl` | `#6F727B` / `#747BA3` | `onSurfaceVariant` |
| `borderAccent` | `#AAB4FF` / `#7063C0` | `primary` |
| `onDisabled` | ink @ 38 % | ink @ **62 %** |
| `ColorScheme.outline` | `borderControl` | `onSurfaceVariant` |
| `ColorScheme.outlineVariant` | `borderSubtle` | `onSurfaceVariant` |

**Role identity is preserved, and that half is right.** The high-contrast themes
go through the *same* `_buildTheme` seam as the normal ones — `app_theme.dart`
builds all four from `_light`/`_dark` — so no component's Material role is
substituted, no `ThemeData` slot is re-bound, and no shared widget takes a
different code path. `app_high_contrast_test.dart` pins the negative half
directly: the brand, the page, the surface ladder, the four semantics, the filled
button's fill and the outlined button's label are all asserted **identical**
between each theme and its high-contrast twin. This is exactly the property the
audit brief asks for — *retune the palette, do not substitute component roles* —
and it is enforced rather than asserted in prose.

`applyCompactScale()` also survives the flag correctly: it takes
`Theme.of(context)` and `copyWith`s it, so on a narrow screen the compact theme
is derived from whichever of the four `MaterialApp` selected. A version that
rebuilt from `buildLightTheme()` would have silently dropped high contrast below
the compact breakpoint. It does not.

**What high contrast measures after the swap** (against `surface`; `*` = under
3:1):

| token | light normal → HC | dark normal → HC |
|---|---|---|
| `borderSubtle` | 1.14* → **5.28** | 1.41* → **6.47** |
| `borderControl` | 4.40 → 5.28 | 4.68 → 6.47 |
| `borderAccent` | 1.80* → **5.67** | 3.88 → 11.27 |
| `outline` / `outlineVariant` | 4.40 / 1.14* → **5.28** | 4.68 / 1.41* → **6.47** |
| `onDisabled` (composited) | 2.11* → **3.80** | 2.62* → **5.11** |
| **`borderOption`** | 2.45* → **2.45\*** | 2.95* → **2.95\*** |
| **`borderSelected`** | 3.96 → 3.96 | 5.73 → 5.73 |
| **`borderDivider`** | 1.00* → 1.00* | 1.44* → 1.44* |

The three unmoved rows are A19-04. The `borderOption` row is A19-02.

---

## 3 · A19-01 (P0) — `browse` has no accessible operation

**`lib/features/study/presentation/widgets/support/study_swipe_deck_widget.dart`
· `lib/features/study/presentation/widgets/sections/study_card_face_section_widget.dart:364-376`
· `lib/features/study/presentation/widgets/support/study_mode_view_widget.dart:150-174`**

BR-110 puts `browse` first in every `eight_box` new-learning sequence. BR-111
gives it nothing to grade, and M99.xx removed the Next button on that basis —
the reasoning is written down at `study_card_face_section_widget.dart:368`:

> *"Moving between cards is the swipe (BR-155), and a Next button beside it was a
> second way to do the one thing the gesture already does — while taking a band
> of the screen from the card… What the button was carrying for accessibility is
> now a pair of custom semantics actions on the swipe itself, so a screen reader
> has the same two moves without anything being drawn."*

**That sentence is true for a screen reader and false for everyone else.** The
mode's controls are literally empty — `study_mode_view_widget.dart:166` passes
`actions: const <StudyAction>[]`, and `_controls()` opens with
`if (widget.actions.isEmpty) return const <Widget>[];` — so the whole surface is
one `GestureDetector` with `onHorizontalDragUpdate`/`End`/`Cancel` and a
`kStudySwipeThreshold` of **70 dp**.

Three populations, three outcomes:

| user | path forward | works? |
|---|---|---|
| Touch, full motor control | 70 dp horizontal drag | yes |
| Screen reader (TalkBack / VoiceOver) | `customSemanticsActions` — Continue / Previous | yes |
| **Keyboard-only** | — | **no** |
| **Touch or single-pointer, cannot drag** (tremor, one-switch, head pointer, stylus, trackpad without drag) | — | **no** |

The keyboard column is empty by construction and it is verifiable in one line:
the repository contains **zero** occurrences of `Shortcuts(`,
`CallbackShortcuts`, `LogicalKeyboardKey`, `SingleActivator`,
`KeyboardListener` or `onKeyEvent` under `lib/`. `GestureDetector` is not
focusable and nothing wraps it in a `Focus`. Tab reaches the session frame's
close button and nothing else on the card.

**Why this is P0 and not P1.** It is not that the app is unusable — the session
frame's close button still works, so nobody is trapped. It is that a *core task*
has no accessible operation on the *release target*. `browse` is not optional and
not skippable: it is the first stage of learning new cards, and a user who cannot
perform a 70 dp drag cannot begin. The screen-reader path is why the failure is
not universal, and it is also why it went unnoticed — the accessibility argument
was made, discharged for one assistive technology, and treated as discharged for
all of them.

**Standards.** WCAG 2.1.1 Keyboard (A) — no keyboard operation. WCAG 2.5.7
Dragging Movements (AA, 2.2) — *"all functionality that uses a dragging movement
… can be achieved by a single pointer without dragging"*; a custom semantics
action is not a pointer operation. AD-04 keeps the web build as the E2E channel
rather than a production target, which limits the keyboard exposure — it does not
touch 2.5.7, which is about the phone.

**Closure test.** `test/features/study/presentation/study_swipe_deck_test.dart`
already exists and already holds a semantics handle, so it is the right home:

1. pump `browse` and assert a focusable node exists whose activation calls
   `onForward` — i.e. that `tester.sendKeyEvent(LogicalKeyboardKey.tab)`
   followed by `LogicalKeyboardKey.enter` advances, with no drag;
2. assert the same target satisfies `meetsGuideline(androidTapTargetGuideline)`,
   so whatever is added is a real single-pointer target and not a 2 dp hit box;
3. assert the target is **absent** while `isLocked`, matching the existing
   guard on the custom actions — the drag's lock and the new control's lock have
   to be the same predicate, or the mode gains the double-commit window
   `study_mode_view_widget.dart:156` says it just closed.

**Owner decision required before the fix.** BR-111 and BR-155 are the reason the
button was removed, and the removal was reviewed. Restoring a full-width action
button undoes that review. Three shapes, and the choice is the owner's:

- a small paging control in the session frame's chrome (not in the card's band),
  which is where the close button already lives and costs the card no area;
- a tap-anywhere-to-advance on the card, with the drag kept as the fast path —
  cheapest, and it collides with nothing because `browse` grades nothing;
- keyboard/`Focus` support only, which closes 2.1.1 and leaves 2.5.7 open.

The second closes both criteria for the least screen. Recommend it.

---

## 4 · A19-02 (P1) — `borderOption` at 2.67:1, on a component that is only its edge

**`lib/core/theme/foundations/app_border_colors.dart:158-186` ·
`lib/features/card/presentation/widgets/sections/card_export_format_options_widget.dart:192-232`
· `lib/shared/widgets/mx_card.dart:390-424, 645-650`**

`MxCard.option` has exactly **one** production caller: the format band inside the
card export bottom sheet. (`card_import_source_step_widget.dart:192` names the
recipe in a comment and does not build it.) The geometry of that one caller is
what makes this a P1 rather than a token nit, and the call site already writes it
down:

> *"This is not only a card: it is a radio row whose fill **is** the sheet's, i.e.
> **1.00:1**, so the edge is the whole component."*

Confirmed on the tree: `buildBottomSheetTheme` sets
`backgroundColor: scheme.surfaceContainerLow`, and `.option`'s spec resolves
`_MxCardFill.surface` → `scheme.surfaceContainerLow`. Fill and ground are the
same token. Nothing but the border separates an unselected option from the sheet.

That border measures:

| | light (`#FFFFFF` ground) | dark (`#111633` ground) |
|---|---|---|
| `borderOption` resting | **2.67:1** — fails | 3.33:1 — passes |
| `borderSelected` picked | 4.33:1 | 5.27:1 |

**The token's own doc comment describes a different colour.** It argues for
`#8887CE` and quotes *"3.18:1 on a card and 3.01 on the page"* — and those
numbers reproduce: `#8887CE` measures **3.28:1** on white and **3.00:1** on the
page. The constant is `#8896FF`. That value is the design kit's
(`design_system/tokens/colors.css`: `--mx-border-option-light:#8896FF`), and
`css_token_parity_test.dart` pins the pair to the kit with no contrast floor
attached. So the kit value was adopted, the parity test locked it, and the
paragraph justifying the token it replaced was left in place — a decision whose
recorded reasoning no longer belongs to the constant beneath it.

**High contrast does not rescue it.** `highContrastSemantics()` re-points
`borderSubtle`, `borderControl`, `borderAccent` and `onDisabled`. `borderOption`
is not in the list, so a user who turns the flag on to make edges stronger gets
**2.45–2.67:1** on the one edge in the app that is a control's entire boundary,
while every decorative hairline beside it rises to 5.28:1. The mode inverts the
hierarchy it exists to sharpen.

**Why the existing guards are all blind to it**, which is A19-13:

| guard | why it misses this |
|---|---|
| `control_border_grounds_test.dart` | scoped to `semantic.borderControl` by name; `borderOption` was split *off* that token at M100.2 and the test was not widened |
| `app_high_contrast_test.dart` | iterates a hand-written list of three border tokens |
| `NonTextContrastRule` (visual audit) | `informationalColors` = `primary`, `success`, `warning`, `danger`, `info`, `borderControl`. `borderOption` and `borderSelected` are absent, so a paint in either colour is skipped before the ratio is computed |
| `card_export_sheet_test.dart:207-223` | asserts the resting edge **is** `semantic.borderOption`, in `buildDarkTheme()` only — it pins the token, not the ratio, and only in the mode that passes |
| `css_token_parity_test.dart` | asserts equality with the kit, which is what put the failing value there |

**Standards.** WCAG 1.4.11 Non-text Contrast (AA) — the visual information
required to identify a user-interface component. The card-edge exemption the
project relies on for `borderSubtle` cannot reach here, and the project has
already written the distinction down twice, at
`AppBorderColors.borderControlDark` (*"A card's edge would have been exempt; a
control's is not"*) and at `guess_option_item_widget.dart` (*"a row is a control
(WCAG 1.4.11), not a card"*).

**Closure tests.** Two, and the second is the one that stops the recurrence:

1. add `borderOption` and `borderSelected` to `control_border_grounds_test.dart`,
   with `surfaceContainerLow` in the ground list — that is the sheet, and it is
   currently absent from a test whose grounds are page / `surface` /
   `surfaceContainer`;
2. add both tokens to `NonTextContrastRule`'s `informationalColors` in
   `test/visual_audit/memox_audit.dart`, and put the export sheet on the audited
   surface list.

**Owner decision.** AD-14 says the palette moves, never the floor. The fix is a
darker `borderOptionLight`; `#8887CE` — the value this token's own comment
already argues for — clears 3:1 on the sheet at 3.28:1 and keeps the ordering
against `borderSelected`. That makes the app diverge from
`--mx-border-option-light` in the kit, so either the kit moves too or
`css_token_parity_test.dart` records a deliberate divergence with the ratio as
its reason. Both are owner calls; the divergence is the smaller one, and the kit
edit is the correct one.

---

## 5 · A19-03 (P1) — a single-choice menu with no perceivable and no announced state

**`lib/shared/widgets/mx_menu_button.dart:30-88` ·
`lib/features/card/presentation/widgets/support/card_sort_control_widget.dart:35-65`**

`MxMenuAction.isSelected` is documented as *"The currently-active choice, for
menus that pick one of a set. Material highlights it when the menu opens."* What
`MxMenuButton` does with it is one line:

```dart
initialValue: selectedIndex < 0 ? null : selectedIndex,
```

`PopupMenuButton.initialValue` does two things in Material: it scrolls the menu
to the matching entry, and it wraps that entry in a `ColoredBox` of
`Theme.of(context).highlightColor`. It sets **no** semantics — no `selected`, no
`checked`, no `inMutuallyExclusiveGroup`, no `value` — and `PopupMenuItem` adds
none of its own.

So the state is carried by one channel, and the channel is a wash. This app's
`highlightColor` is `scheme.primary` at `AppStateOpacity.pressed` (12 %),
declared in `app_theme.dart`; the popup ground is `scheme.surfaceContainer`:

| | resolved highlight | ground | contrast |
|---|---|---|---|
| light | `#DBDFF1` | `#F0F2F6` | **1.18:1** |
| dark | `#2E345C` | `#1A2045` | **1.32:1** |

**Both failures at once.** WCAG 1.4.1 Use of Color (A) — colour is the only
visual means, and at 1.18:1 it is barely even that. WCAG 4.1.2 Name, Role, Value
(A) — the value of a single-choice control is not programmatically determinable.
A screen-reader user opening the card list's sort menu hears four unlabelled
choices and cannot tell which one is in force.

**The app already has the right answer twelve files away.** `MxActionSheet` does
the same interaction correctly, and says why at `mx_action_sheet.dart:151-155`:

> *"**The row carries the state, not just the tick.** … the explicit flag is what
> makes 'Recently studied, selected' the announcement."*

`selected: action.isSelected` plus a trailing `Icons.check`. Two channels, both
perceivable. So `deck_sort_sheet_widget` (a sheet) is correct and
`card_sort_control_widget` (a menu) is not — the same product decision, two
answers, decided by which shared component the call site reached for.

**Closure test.** `test/shared/widgets/mx_menu_button_test.dart` exists. Open the
menu with `isSelected` set on one action and assert (a) the matching
`PopupMenuItem`'s semantics node reports `isSelected` (or `hasCheckedState` +
`isChecked`), and (b) a non-colour mark is present on it. Then assert the
negative that keeps the two components honest: the same fixture through
`MxActionSheet` and through `MxMenuButton` produce the same selection
annotation.

**Fix shape**, for the record and not to be implemented here: give `_MenuRow` a
trailing check when `action.isSelected` and wrap the row in
`Semantics(selected: action.isSelected, inMutuallyExclusiveGroup: true)`.
`initialValue` stays — the scroll-to behaviour is worth keeping — but it stops
being the only thing carrying the fact.

---

## 6 · Semantics inventory

72 `Semantics(` call sites under `lib/`, parsed at top level only (nested child
arguments excluded), plus 34 `ExcludeSemantics` and 3 `MergeSemantics`.

### 6.1 · Property census

| property | sites | verdict |
|---|---|---|
| `label` | 43 | correct; every one is an already-localized string from the ARB |
| `container` | 25 | correct — used to force a boundary where a merged parent would swallow the node |
| `liveRegion` | 14 | see §9 |
| `button` | 11 | **all 11 verified tappable** — no `button:` on inert content |
| `value` | 7 | correct — state in words beside a colour or a glyph |
| `selected` | 6 | 5 correct, **1 wrong** (A19-17) |
| `excludeSemantics` | 5 | correct — paired with a replacement `label` in every case |
| `header` | 5 | **the gap** — see §7 |
| `enabled` | 4 | correct — `MxCard`'s disabled option, `MxActionButton`, `MxTextButton`, settings rows |
| `focusable` | 2 | correct — follows `enabled` on the two button wrappers |
| `onTap` | 2 | correct — restated on the two wrappers that replace a button's own node |
| `explicitChildNodes` | 1 | `MxBreadcrumb` — correct, the trail's steps must stay separate stops |
| `inMutuallyExclusiveGroup` | 1 | correct, and **the only one in the app** — see §6.4 |
| `expanded` | 1 | correct, and notably well-argued (`card_editor_details_widget.dart:104`) |
| `textField` | 1 | correct — `fill_answer_pieces_widget`'s bespoke editable |
| `customSemanticsActions` | 1 | present but insufficient — A19-01 |
| `toggled` | **0** | correct: every toggle in the app is a Material `Switch`/`Checkbox`, which sets it |
| `checked` | **0** | correct for the same reason — but see §6.4 for what that leaves uncovered |
| `sortKey` / `BlockSemantics` | **0** | acceptable; reading order is the DOM order everywhere, and modal blocking is the framework's |

**Nothing sets `selected` on a non-selectable control except one site, and
nothing sets `button` on inert content at all.** Both audit items came back
essentially clean, and that is worth stating as a result rather than as an
absence: eleven `button:` annotations were each traced to a live `onTap`, and
five of six `selected:` annotations sit on genuinely selectable things — a card
tile in selection mode, a trash row in selection mode, a match tile, an action
sheet row, and `MxCard`'s tri-state (whose `null` explicitly means "not
selectable at all", which is the distinction most codebases lose).

### 6.2 · A19-17 (P3) — `selected` on a stepper node

`lib/features/card/presentation/widgets/sections/card_import_stepper_widget.dart:177`

```dart
Semantics(
  selected: state == _NodeState.current,
  label: … cardImportStepStateSemantics(step, label, stateLabel),
  excludeSemantics: true,
  child: Row(…),
)
```

`_StepNode` has no `onTap`, no ink, no gesture — a step in a progress indicator
cannot be selected. TalkBack maps `isSelected` to `AccessibilityNodeInfo
.setSelected(true)` and announces "selected", which describes an affordance that
does not exist. The information is *already* in the label, correctly and in
three parts (position, name, `cardImportStepStateCurrent`), so the flag is both
wrong and redundant.

P3 because the label carries the fact and nothing is lost, only added.
**Closure:** drop `selected:` and assert in `card_import_*_test.dart` that the
step node reports `hasSelectedState == false` while its label still contains the
state word.

### 6.3 · A19-11 (P2) — the card row announces its state twice

`lib/features/card/presentation/widgets/items/card_tile_widget.dart:68-71,
125-152, 205-215`

The row builds, in one subtree:

- `_StateDot` — a bare coloured `Container` wrapped in
  `Semantics(label: cardStateDotSemantics(cardStateLabel(state)))`;
- `_CardFace` — a `Text(cardStateLabel(state).toUpperCase())` in the state's own
  ink.

Both derive from `cardStateLabel(item.state)`. The outer
`Semantics(label: isSelected ? … : null)` at line 68 does not exclude either.
The state is therefore in the tree twice, from two nodes.

**The project has already ruled on this exact shape.** `reminder_settings_a11y_test.dart`
asserts, with the reasoning in the test body:

> *"One node carries both, and the time appears exactly once. It used to be in the
> merged label **and** in a `Semantics(value:)` wrapper, so a reader heard
> 'Reminder time 8:00 PM, 8:00 PM'."*

Same defect, unswept feature. And the dot is the half to drop: once the word is
printed beside it the dot is decoration, which is what `MxIcon` does by default
(`semanticLabel == null → ExcludeSemantics`).

Note what is *right* here and must survive the fix: the state is **not** carried
by colour alone. The word is printed, the comment records the measurement
(*"every state clears 4.5:1 — info 5.23/7.84, warning 4.58/8.58, accent
7.27/5.51, success 5.20/8.10"*), and the selection mark replaces the dot in the
same column so the row does not reflow. WCAG 1.4.1 is satisfied. This is a
duplicate-announcement defect only.

**Closure:** wrap `_StateDot`'s `Container` in `ExcludeSemantics` (or delete the
`Semantics` wrapper), and add to a card-list test that the row's merged label
contains the state word exactly once — the same assertion shape
`reminder_settings_a11y_test.dart` already uses.

### 6.4 · What the zero `checked:` count leaves uncovered

`toggled` and `checked` being absent is correct where a Material control is
present, and it is the whole story for `MxSwitchRow` and `MxCheckboxRow`. It is
**not** the whole story for group semantics:

- `inMutuallyExclusiveGroup` appears **once** in the entire app, on the export
  format band. Every other pick-one-of-a-set surface announces its *selection*
  correctly and its *group* not at all: `MxRadioRows` wraps a `RadioGroup` and
  gets both from Material's `Radio`; `MxActionSheet` sets `selected:` plus a
  trailing check; the study direction chooser goes through
  `MxListTile(isSelected:)`, which annotates `selected` at
  `mx_list_tile.dart:117`, and adds a `radio_button_checked` glyph. So the group
  flag is missing in three places and the fact it would carry is redundant in
  all three.
- `MxMenuButton` is the one surface that announces **neither** — A19-03. That is
  what makes it a P1 and the others a footnote.
- No `Semantics(role: SemanticsRole.radioGroup)` or equivalent container exists
  anywhere, so "2 of 3" positional context is never announced for a chooser.

Folded into A19-03's closure rather than registered separately: the fix for the
menu is the fix for the pattern, and declaring the group on the three that
already announce their selection is a one-line addition each.

### 6.5 · A19-19 (P3) — `MxSwitchRow`'s announced pattern stacks two state channels

`lib/shared/widgets/mx_switch_row.dart:64-80`

```dart
Semantics(label: label, value: announcedValue, child: Switch(value: isOn, …))
```

`Switch` already sets `toggled`, which Android maps to
`setCheckable(true) + setChecked(isOn)`. Adding `value: "On"` puts the same fact
on the same node through a second channel, so the reader is liable to hear the
state twice ("Reminder, On, on/off switch"). This is a documented owner decision
(M6 R7 — *"a reader hears the value in words"*), the reminder screen's test pins
both fields, and the redundancy is mild.

P3, and it stays P3: the trade was made deliberately and the alternative
(dropping `value`) loses a genuinely useful spoken state on platforms whose
switch announcement is terse. **Recorded, not recommended for change** — but it
is worth one line of prose at the widget saying the duplication is accepted, so
the next audit does not re-open it.

### 6.6 · A19-21 (P3) — `ExcludeSemantics` inflation

34 `ExcludeSemantics` wrappers. `MxIcon` self-excludes when `semanticLabel` is
null, and Flutter's bare `Icon` contributes no node when its `semanticLabel` is
null either — so a wrapper around either is a no-op render object. Several are
exactly that; `trash_row_widget.dart:115-119` even documents the reasoning from the
other side (*"a bare `Icon` self-excludes its glyph, so they contribute no
narration — but give one a `semanticLabel` and it must move inside here"*).

P3 and arguably not worth fixing: the wrappers are cheap, and the comment above
shows at least one is deliberate insurance against a future `semanticLabel`.
Recorded so it is not mistaken for a defect by the next pass.

---

## 7 · A19-07 (P2) — four heading policies, one of them complete

`header: true` appears at **5** sites in the whole app. The section-heading
treatment (`textStyles.sectionLabel` / `sectionLabelSmall`) is rendered at
**16** sites, of which **14** are group headings — the other two are the session
top bar's and the study frame's mode label, which are not headings. Counting
`search_group_header_widget`, which is a group heading rendered at `labelSmall`
rather than the section treatment, the app has **15 group headings and announces
2 of them**.

The app holds four mutually inconsistent policies:

| policy | site | `header:` | uppercase | TTS mitigation |
|---|---|---|---|---|
| **complete** | `study_home_body_section_widget.dart:182` | ✅ | painted | ✅ `label` + `excludeSemantics` |
| no header | `settings_section_widget.dart:52` | ❌ | painted | ✅ `label` + `excludeSemantics` |
| no uppercase | `search_group_header_widget.dart:26` | ✅ | none, by argument | n/a |
| **nothing** | 14 further sites | ❌ | painted | ❌ |

The first is the exemplar and its comment is the specification:

> *"**A heading, declared.** The `xl` above it builds the section break visually;
> without `header: true` that break is invisible to a screen reader, which hears
> the Resume card run straight into the first deck and cannot jump by heading at
> all."*
>
> *"**The name is the sentence, not the shouting.** The uppercase is a
> typographic treatment; some TTS engines spell an all-caps run out letter by
> letter, so the label states the heading as written and the painted text is
> excluded."*

`settings_section_widget.dart` calls itself *"the app's one section-heading
treatment (D18)"* and carries the second half and not the first — so **the whole
Settings screen has no heading landmarks**: Appearance, Language, Study defaults
and Reminder are all unreachable by heading navigation. `card_detail_state_widget`,
`card_progress_panel_widget`, `card_history_section_widget` and the four import
step headings are in the fourth row: no header, no mitigation.

`search_group_header_widget` reaches the right destination by a different route
and writes down an argument worth promoting:

> *"`toUpperCase()` on a localized string is the translator's decision to make,
> not the widget's — it is wrong for locales with no case and changes the width
> the layout was measured at."*

**Standards.** WCAG 1.3.1 Info and Relationships (A) — a visual heading that is
not marked up as one. WCAG 2.4.10 Section Headings (AAA) is the aspirational
half; 1.3.1 is the failing one.

**Closure.** One shared component — `MxSectionHeading(label)` — carrying
`header: true`, `container: true`, the localized sentence as `label`,
`excludeSemantics: true` and the `sectionLabel` treatment; then a test that walks
`lib/features/**/presentation/**` for `textStyles.sectionLabel` and fails on any
site not routed through it. That is the same shape as
`mx_stress_test.dart`'s "the specimen list covers every shared component" check,
which is the pattern in this repo that has actually held.

---

## 8 · A19-08 (P2) — 21 uppercase sites, one mitigation

The census, run over `lib/`:

| | count |
|---|---|
| `toUpperCase()` render sites | **21** |
| of those, carrying `Semantics(label: <sentence case>, excludeSemantics: true)` | **1** |

The one is `study_home_body_section_widget.dart:182`. The other twenty paint an
all-caps run straight into a `Text` with nothing standing in for it: the export
sheet's format heading, four import-step headings, two import format extensions
(`CSV`, `JSON` — these are genuinely initialisms and are fine), the card
history and card progress and card detail state headings, the deck list
toolbar's two variants, all four Settings section headings via
`settings_section_widget`, the session top bar's mode label, the study card
face's overline, the guess overline, and the card row's state word.

**Why this is a P2 and not a P3.** The project has already decided this matters
— twice, in prose, at two different files — and the two files that acted on the
decision are the two smallest. Meanwhile the label the *card list* row announces
for every card is `NEW`, `LEARNING`, `MASTERED` as an all-caps run, which is the
highest-frequency uppercase string in the app.

Note this interacts with A19-11: fixing the duplicate-announcement defect there
by keeping the dot's label and excluding the word would close both at once for
the card row. That is not the recommendation — the *printed* word is what
satisfies 1.4.1 and must stay painted — but the label the reader hears should be
the sentence-case string, from one channel.

**Closure.** The shared heading component from §7 covers 14 sites by
construction. For the remaining non-heading cases (state word, mode label,
overlines), a targeted test: assert that any `Text` whose data differs from its
`semanticsLabel` only by case is either excluded or carries the sentence-case
string.

---

## 9 · Keyboard, focus, touch targets, text scale

### 9.1 · Keyboard — what exists and what does not

| capability | state |
|---|---|
| Tab / Shift+Tab traversal | Framework default, reading order. **No** `FocusTraversalGroup` or `FocusTraversalPolicy` anywhere, and none is needed: no screen has a layout whose visual order differs from its widget order |
| Enter / Space activation | Everything interactive routes through `InkWell` — `MxPressable`, `MxCard`, `MxListTile`, `MxBreadcrumb`, or a Material button. All are focusable and activate on both keys |
| Esc | Framework only. `showModalBottomSheet` is called **17 times** and `showDialog` **4**, and **not one** of the 21 passes `barrierDismissible: false` or `isDismissible: false`, so `ModalBarrier`'s `DismissIntent` handler is live on every overlay in the app. This is the right outcome reached by not overriding a default — worth pinning, see §9.2 |
| Arrow keys | None. Correct: the only 2-D surface is the match board, whose tiles are `MxPressable` and traverse linearly; a grid arrow policy would be an invented interaction |
| App-level shortcuts | **Zero.** No `Shortcuts`, no `CallbackShortcuts`, no `SingleActivator`, no `LogicalKeyboardKey` |
| The one interaction with no keyboard path | `browse` — A19-01 |

`autofocus` appears at 9 sites and its policy is unusually careful.
`MxActionButton._takesFocus()` gates it on
`FocusManager.instance.highlightMode != FocusHighlightMode.touch`, with the
argument written out: *"a stray Enter needs a keyboard, and
`FocusHighlightMode.touch` means there is not one"*. So a destructive dialog does
not arrive with its confirm button focused on a phone, and does the moment a
keyboard is used. `MxConfirmDialog:160` records that neither action is
autofocused on a normal dialog. This is correct and better than the norm.

### 9.2 · Modal focus capture and return

Both are the framework's and both are correct by default: `ModalRoute` owns a
`FocusScopeNode` per route, captures focus on push and restores it to the
previously-focused node on pop, and `showModalBottomSheet` wraps its content in
`Semantics(scopesRoute: true, namesRoute: true, explicitChildNodes: true)`. The
app does nothing to disturb any of it — no `FocusScope` calls, no manual
`unfocus()` (zero occurrences), no `canRequestFocus: false` on a container.

**But nothing pins it.** A single `barrierDismissible: false` added later, or a
`FocusScope` introduced to fix a keyboard-inset problem, would remove Esc or
break focus return with no test objecting. Folded into A19-14's closure as one
assertion rather than registered on its own: for each overlay helper in
`lib/shared/widgets/`, send Escape and assert the route popped, then assert the
pre-push focus node is focused again.

### 9.3 · Touch targets

The floor is declared once (`AppSizing.touchTarget = 48`) and enforced
structurally in three places, which is the right architecture:
`iconButtonTheme.minimumSize`, `buildSharedButtonStyle`, and `MxPressable`'s
`ConstrainedBox(minHeight: 48)`. `MxCard` adds `minWidth`/`minHeight` 48 around
its ink when it is tappable. `applyCompactScale` explicitly refuses
`VisualDensity.compact` because *"it subtracts 8dp from every button, taking the
icon button to 40x40 — under the floor a thumb needs"*.

`mx_stress_test.dart` then asserts `meetsGuideline(androidTapTargetGuideline)`
on every interactive shared component at 320 dp × 2.0× scale, and a completeness
test fails if a file in `lib/shared/widgets/` has no specimen. That is a real
guard and it holds the component layer.

**A19-10 (P2) — the one target that escapes all of it.**
`lib/features/card/presentation/widgets/support/card_sort_control_widget.dart:48-65`

`MxMenuButton` floors nothing when a caller passes `child:` —
`PopupMenuButton(child: …)` wraps it in an `InkWell` with no `minimumSize`, and
`MxPressable` is not involved. The card sort control is the only site that
passes a `child`, and it builds:

```
Padding(vertical: AppSpacing.xs = 4)
  └ Row(Text(labelSmall), MxIcon(size: MxIconSize.sm))
```

`labelSmall` is declared `size: 11, height: 16/11` → a 16 dp line box.
`MxIconSize.sm` is `AppIconSize.sm` = 16. Row height = max(16, 16) = 16, plus
4 + 4 = **24 dp**.

Half the project's declared floor, at `textScaler` 1.0. Under WCAG 2.5.8 (AA,
2.2) 24 × 24 is exactly the minimum and would pass by nothing at all; the
project's own threshold is 48 and, per the audit brief, the stricter one wins.

*(Arithmetic over the tokens, not a measured render — no SDK in this
environment. The closure test is what turns it into a measurement.)*

The deck list's equivalent control **is** swept —
`deck_sort_control_width_test.dart` calls `meetsGuideline(androidTapTargetGuideline)`
on it and its comment names the exact failure mode. The card list's is not,
because `card_list_screen` has no guideline sweep at all (A19-14).

**Closure.** Give `MxMenuButton`'s `child:` path the same `MxPressable` floor its
default icon path gets from `IconButton`, then add `card_list_screen` to the
sweep. One `meetsGuideline(androidTapTargetGuideline)` on the card list toolbar
fails today and passes after.

**Nested gestures came back clean.** Two `GestureDetector`s exist in `lib/`, both
in `study/`, and both are deliberate: `fill_answer_pieces_widget` uses
`HitTestBehavior.opaque` purely to forward a tap to the field's own `FocusNode`
(*"so the strip of padding between the card's edge and the editable is part of
the target rather than a hole in it"*), and `study_swipe_deck_widget` claims the
horizontal axis only, with the reason written down (*"the card's halves scroll
vertically at a large text scale, and claiming the vertical axis here would take
that away"*). The one card-plus-nested-button case — the deck tile's overflow
menu inside a tappable card — is correct and documented: *"`MxCard` takes the
tap; the overflow menu is a nested button and wins the gesture arena over it"*.

### 9.4 · Text scaling

This is the strongest dimension in the codebase. 15 sites read
`MediaQuery.textScalerOf`, several to scale a *minimum* rather than to branch —
`progress_metric_widget.dart:58` writes down why (*"Comparing a fixed width
against a growing demand is how the…"*). `mx_stress_test.dart` pumps every
shared component at 320 × 640 with `TextScaler.linear(2.0)` in both
brightnesses and fails on `RenderFlex overflowed`, which is otherwise reported
as an error and not thrown. `mx_accessibility_test.dart` goes to **3.0** on a
320 × 568 surface for the confirm dialog and asserts the message stays
*scrollable* rather than merely un-clipped, plus that both action labels keep
`maxLines: 2`. `test/demo/goldens/` carries `card_detail_320_x2_vi.png` and a
scrolled variant, so at least one screen is pinned at 320 dp × 2.0× in
Vietnamese.

**A19-12 (P2) — the one place scale is answered by truncation.**
`lib/shared/widgets/mx_content_shell.dart:243-259`

```dart
Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
```

Applied whenever a `titleSubline` is present — which is every screen with a
breadcrumb, i.e. every deck and card screen below the root. `_toolbarHeight()`
grows the bar with the scale, so the *vertical* half is handled; the horizontal
half is not, and a one-line cap cannot be widened by a taller bar. At 2.0× a
Vietnamese deck name is truncated to a few characters.

`applyCompactScale` drops `titleLarge` from 22 to 20 at narrow widths for exactly
this reason and records the symptom (*"a real deck name truncates to 'Academic
Word …' on a 320-wide screen; the name is the one thing that screen is
about"*) — the token was lowered, the `maxLines: 1` above it was not revisited.

Standards: WCAG 1.4.4 Resize Text (AA) — content lost at 200 %. Visual only; the
full string stays in the semantics tree, so a screen reader is unaffected.

**Closure.** `maxLines: 2` with the bar height already following the scale, and
a widget test at 320 dp × 2.0× in VI asserting the rendered `Text` reports no
`didExceedMaxLines` for a representative deck name — the same assertion shape
`mx_accessibility_test.dart` uses for the confirm dialog's buttons.

**A19-20 (P3) — `useSafeArea`.** `showModalBottomSheet` is called 17 times;
`useSafeArea: true` is passed twice (`study_entry_screen.dart:206`,
`trash_restore_target_sheet_widget.dart:30`). With `isScrollControlled: true` and
`useSafeArea` at its `false` default, a sheet grown by a large text scale can
run under the status bar. `MxSheetInsets` handles the *bottom* obstruction and
has its own test; the top is unhandled. P3 — no evidence of a live clip, and the
right fix is one line inside `MxFormSheet` plus a default in the two overlay
helpers rather than 15 call-site edits.

---

## 10 · State cues — what is carried by colour alone

The audit brief's item 10, worked through every state the app paints. The result
is mostly a commendation, with one measured failure and one measured near-miss.

| state | non-colour channel | verdict |
|---|---|---|
| Navigation tab current | outlined → filled icon **and** an always-visible label **and** Material's `selected` | ✅ and the reasoning is at `app_navigation_shell.dart:38` |
| Card state (new/learning/mastered) | the word, printed, in the state's own ink at ≥ 4.5:1 | ✅ (announced twice — A19-11) |
| Match tile paired / wrong | tick / cross glyph **and** `Semantics(value:)` | ✅ — `match_tile_widget.dart:61-64` argues it explicitly |
| Guess option correct / chosen-wrong | check / close glyph **and** `Semantics(value:)` **and** a 1.5 px edge | ✅ |
| Import step completed / current | a check vs a number — *"a check is a fact, a number is an address"* | ✅ |
| Card selected in selection mode | a check replacing the dot in the same column, **and** `MxCard.isSelected` announcing | ✅, including the no-reflow property |
| Trash row selected | checkbox glyph **and** `Semantics(selected:)` | ✅ |
| Export format picked | a border at 4.33:1 **and** `MxCard.isSelected` **and** `inMutuallyExclusiveGroup` | ✅ selected; ✗ **resting** — A19-02 |
| Focus | `primary` ring at ≥ 4.58:1 in light, ≥ 7.24:1 in dark, on a stroke that never changes width | ✅ best-in-class |
| Field error | `scheme.error` border **and** `errorText` on the field's own semantics node | ✅ for error; ✗ **focus within error** — carried F3 |
| **Menu current choice** | **nothing** — a 1.18:1 wash | ✗ **A19-03** |
| **Trash row unavailable** | **an opacity layer only** | ✗ **A19-06** |
| Disabled control | `disabledSurface` fill **and** `onDisabled` ink | ✅, and raised in high contrast |
| Loading | `CircularProgressIndicator(semanticsLabel:)`, plus `SemanticsRole.loadingSpinner` on a busy button | ✅ and tested |

### 10.1 · A19-06 (P2) — the dimmed trash row

`lib/features/trash/presentation/widgets/items/trash_row_widget.dart:75-76`

```dart
Opacity(opacity: isDimmed ? 0.38 : 1, child: MxPressable(…))
```

Three problems in one line.

**One: a raw literal where a token exists.** `AppStateOpacity.disabledContent`
*is* 0.38 and is the declared name for this decision. `0.38` inline is exactly
the magic value CLAUDE.md's "No magic values" rule and `AppStateOpacity`'s own
file header exist to prevent.

**Two: the ratios.** The row's text composites against `surface`:

| ink | at 1.0 | at 0.38 |
|---|---|---|
| `onSurface` (the item name) light | 11.50:1 | **2.11:1** |
| `onSurface` dark | 12.01:1 | **2.62:1** |
| `onSurfaceVariant` (the metadata lines) light | 5.28:1 | **1.69:1** |
| `onSurfaceVariant` dark | 6.47:1 | **1.89:1** |

The comment above it says *"The row stays legible and stops responding"*. At
1.69:1 the second line is not legible. WCAG 1.4.3's inactive-component exemption
is arguable here — but the project has already declined that exemption for this
exact case, in writing, at `app_high_contrast.dart:46`: *"2.37:1 in light is
below the 3:1 floor for any graphic a user has to perceive at all, and a control
nobody can read is worse than one whose unavailability takes a moment longer to
notice."* Per the brief, the stricter project threshold wins.

**Three: high contrast cannot reach it.** The palette raises `onDisabled` from
2.11 → 3.80 (light) and 2.62 → 5.11 (dark). An `Opacity` render object is
invisible to the palette, so this row stays at 2.11 / 1.69 with the flag on —
the one screen state that most needs the mode is the one the mode cannot touch.
This is the structural reason `AppColors` flattens `disabledSurface` over the
surface instead of using Material's alpha idiom, and the reason is defeated by
compositing at paint time one layer up.

**Closure.** Two tests. (a) A widget test at both brightnesses asserting the
dimmed row's resolved text colour clears 3:1 against `surface`. (b) A guard
assertion that `lib/features/` contains no bare opacity literal equal to a
member of `AppStateOpacity` — the same shape as the existing icon-ink boundary
test, which already holds an allowlist for exactly this class of rule.

**Fix shape.** Replace the `Opacity` with the `disabledSurface`/`onDisabled`
token pair the buttons and `MxCard`'s disabled option already use — which is
what `mx_card.dart:629-631` says it does *"so a disabled option reads as the
app's disabled and not as a card variant"*. That routes the state through the
palette, so high contrast raises it. Also worth adding while there:
`enabled: false` on the row's `Semantics`, so a reader hears that the row is
excluded rather than inferring it from the selection bar.

---

## 11 · A19-05 (P2) — the high-contrast file's measurements are stale in every row

`lib/core/theme/schemes/app_high_contrast.dart:20-60`

The file's whole content is an argument built on a measurement table, and it
declares its ground: *"Light figure first, dark second, each measured against
`surface`."* Recomputed at BASE_SHA, against `surface` and against the two other
plausible grounds, no ground reproduces any row:

| claim in the file | claimed | on `surface` | on `surfaceContainerLow` | on `surfaceMuted` |
|---|---|---|---|---|
| `borderSubtle` normal | 1.45 / 2.04 | 1.14 / 1.41 | 1.24 / 1.30 | 1.04 / 1.06 |
| `borderControl` normal | 3.19 / 3.00 | 4.40 / 4.68 | 4.81 / 4.30 | 4.02 / 3.50 |
| `borderAccent` normal | 1.89 / 1.45 | 1.80 / **3.88** | 1.97 / 3.57 | 1.65 / 2.90 |
| `onDisabled` normal | 2.37 / 3.20 | **2.11 / 2.62** | 2.15 / 2.65 | — |
| `onDisabled` @ 62 % | **4.88 / 6.33** | **3.80 / 5.11** | 3.93 / 4.96 | — |
| `onSurfaceVariant` (HC target) | 6.41 / 7.30 | 5.28 / 6.47 | 5.77 / 5.95 | 4.83 / 4.84 |
| `primary` (HC target) | 7.27 / 10.02 | 5.67 / **11.27** | 6.20 / 10.37 | 5.19 / 8.43 |

Two of these drifts change an argument rather than a digit.

**The disabled-ink trade lands 1.08 lower than the file says it does.** The
paragraph reads: *"62 % lands at 4.88:1 — legible, and still less than a third of
`onSurface`'s 14.81:1, so the hierarchy survives."* It lands at **3.80:1**. That
still clears the 3.0 floor `app_high_contrast_test.dart` asserts, so nothing is
broken today — but the margin is 0.80, not 1.88, and the constant
`highContrastDisabledAlpha = 0.62` was chosen against a number that is no longer
the number. One more palette step in the same direction and the test goes red
with the file still explaining why it cannot.

**`borderAccent` in dark no longer has the problem the swap was made to fix.**
The file says *"the Today card's edge is decoration at 1.45"*. It measures
**3.88:1** in dark at BASE_SHA — above the 3.0 floor on its own. Re-pointing it
to `primary` in high contrast is still defensible (11.27 vs 3.88 is a real
strengthening), but the recorded reason is void in one of the two modes, and a
future reader checking the argument will find it does not hold.

**The cause, and why it is systemic rather than sloppy.** `surface` changed
meaning at **M100.32** — it stopped being the paper and became the page — and
several tokens moved at M100.22, M100.3 and M100.35 for reasons recorded at
*their* files. Each of those edits updated the measurement at the token it
touched and did not walk back to the cross-token table one directory over. The
project's own convention is that *"Measurements quoted at older tokens describe
the state when that token was decided and are kept as the record of why it
exists"* (`app_colors.dart` header) — that convention is right for a token's own
history, and it does not cover a table whose purpose is to say what the mode
does *today*.

**The compounding error the tests share.** `groundsOf()` in
`app_high_contrast_test.dart` lists three grounds — `('surface', …)`,
`('page', t.scaffoldBackgroundColor)`, `('muted tile', …)` — and
`app_theme.dart` sets `scaffoldBackgroundColor: scheme.surface`. **The first two
are the same colour.** The test measures two grounds and reports three.
`control_border_grounds_test.dart` has the same shape and *nearly* guards it: its
premise test asserts `surfaceContainer != page` and `surfaceContainer != surface`
— but never `page != surface`, which is the pair that collapsed.

**Closure.** (a) Regenerate every figure in `app_high_contrast.dart`'s table from
a throwaway run and commit the current numbers. (b) Add to
`app_high_contrast_test.dart` a premise assertion that the grounds it iterates
are pairwise distinct — the same tripwire `control_border_grounds_test.dart`
already has, extended to the pair it omits. (c) Consider naming the disabled
alpha's *outcome* in a test constant so the file's prose and the assertion cannot
part again.

---

## 12 · A19-04 (P2) — high contrast re-points four of eight border tokens

`highContrastSemantics()` takes `base.copyWith(…)` over four slots. The argument
for taking the built extension rather than rebuilding is good and should stay:
*"A named constructor would have to list all eighteen, and the seventeenth would
be the one someone forgot."* The failure is not the mechanism — it is that the
four were chosen from a mental list of "hairlines" and the palette has eight
border tokens.

| token | re-pointed? | what it draws | should it be? |
|---|---|---|---|
| `borderSubtle` | ✅ | card/nav hairlines | yes |
| `borderControl` | ✅ | outlined button, text field | yes |
| `borderAccent` | ✅ | the Today card's emphasis edge | yes (reason stale — §11) |
| `outline` / `outlineVariant` | ✅ | untended and third-party widgets | yes, and the reasoning is exactly right |
| **`borderOption`** | ❌ | the export sheet's option cards — **a control's whole boundary at 2.67:1** | **yes — A19-02** |
| **`borderSelected`** | ❌ | "this one is picked", on cards and sheet rows | **yes** — it passes at 3.20–5.73, but high contrast is where the *selected* edge should out-shout a hairline that just rose to 5.28; after the swap `borderSubtle` (5.28) is **louder** than `borderSelected` (3.96) in light, which inverts the ladder the palette maintains everywhere else |
| `borderDivider` | ❌ | the hairline between rows *inside* one card | **no** — it is decoration by design at 1.00–1.44, and raising it would reinstate the frame-in-a-frame M100.0 argued against. Leave it, and say so at the file |

The `borderSelected` inversion is the interesting half. In the normal themes the
ladder is `borderSubtle` 1.14 → `borderControl` 4.40 → `borderSelected` 3.96 →
`primary` 5.67 (light) — already slightly out of order — and after the
high-contrast swap it becomes `borderSubtle` **5.28** → `borderSelected` 3.96.
A user who turns the flag on to see edges better gets a decorative hairline
drawn *louder* than the edge that says which option is chosen. That is a
role-identity regression of the kind §2.3 says the mode is otherwise careful to
avoid.

**Closure.** Extend `app_high_contrast_test.dart`'s border loop from three
tokens to five (adding `borderOption`, `borderSelected`), keep `borderDivider`
out with the exemption written at the assertion, and add one ordering assertion:
in both high-contrast themes, `borderSelected` and `borderOption` must each
measure strictly above `borderSubtle` on every ground. That last one is the
assertion that would have caught the inversion, and it is the one the file has
no equivalent of today.

---

## 13 · A19-09 (P2) — the shared failure and empty faces are silent

`lib/shared/widgets/mx_error_state.dart` · `lib/shared/widgets/mx_empty_state.dart`

14 `liveRegion` sites exist, and five shared components own one each —
`MxMessenger`, `MxUndoSnackBar`, `MxConfirmDialog`, `MxFormDialog` and
`MxFeedbackBand`. `MxFeedbackBand`'s doc records the defect that put it
there: *"a band a screen-reader user never hears — a defect"*.

`MxErrorState` and `MxEmptyState` carry none. `MxAsyncView` swaps
`MxLoadingState` for the caller's `error` builder in place, so a screen-reader
user who was told "Loading decks" is told nothing when the load fails — the
spinner's node simply disappears and a static error face takes its place.

Three features noticed independently and patched it at the call site:

- `progress_screen.dart:102` — `Semantics(container: true, liveRegion: true)`,
  with the reasoning *"because the failure arrives while the user is already…"*;
- `progress_level_error_widget.dart:87`;
- `search_page_footer_widget.dart:45`, whose comment names the same class of bug.

Three hand-rolls of one policy is the signature of a missing default, and it is
the same argument `MxAsyncView`'s own header makes about `skipLoadingOnRefresh`:
*"it should be a decision written down once, not a default nobody looked at in
three separate files."*

`MxErrorState`'s retry state, by contrast, is exemplary — `isRetrying` exists
precisely because *"six frames were measured after a tap and not one pixel
moved"*, and the label survives the spinner through
`MxActionButton`'s `alwaysIncludeSemantics`. The gap is the arrival of the error,
not the response to it.

**Closure.** Put `Semantics(container: true, liveRegion: true)` inside
`MxErrorState` and `MxEmptyState`, drop the three call-site wrappers (a nested
live region announces twice), and add to `mx_async_view_test.dart` an assertion
that the error branch's node reports `isLiveRegion`. Then a negative assertion at
the three former sites that they no longer wrap one.

---

## 14 · Forms, modals, feedback, navigation

**Forms.** Stronger than the rest of the system. `MxTextField` requires
`label`, hands `errorText` to `InputDecoration` (so it lands on the field's own
semantics node, where a reader gets it as part of the field rather than as a
stray sentence), and takes no `InputDecoration` and no `Color` — one visual
escape hatch with one caller. The card editor puts BR-10's reassurance in
`helperText` rather than as a floating `Text`, with the reason recorded (*"as a
floating `Text` below it belonged to neither — it read as a heading for whatever
came next"*). Save failures are `liveRegion` at three sites in the editor alone,
because *"the button is pinned at the bottom and this paints beside the fields —
so a screen-reader user pressed Save and was told nothing at all."* There is no
`Form`, no `validator:` and no `TextFormField` in the repository; validation is a
value-object concern per AD-13, and error text arrives already localized and
already field-scoped.

The two open form defects are carried F1 (search field with no name) and carried
F3 (focus invisible on an errored field). Both are in §1.2.

**Modals.** Esc works everywhere by default (§9.1). Focus capture and return are
the framework's and undisturbed (§9.2). `MxFormDialog`, `MxConfirmDialog` and
`MxAlertDialog` all scroll their content — `mx_accessibility_test.dart` asserts
`maxScrollExtent > 0` at 320 × 568 × 3.0×, which is the assertion that catches a
clip rather than an overflow, and its comment records the bug it replaced
(*"the sentence was cut mid-word and the user confirmed a delete having read
half of the description"*). `MxButtonPair` stacks when a 320 dp screen at 2.0×
leaves no room. The gap is that none of Esc, focus capture or focus return is
pinned by a test — folded into A19-14.

**Feedback.** `MxMessenger` clears the queue and wraps in `liveRegion`;
`MxUndoSnackBar` guarantees a single tap; `MxFeedbackBand` is
`Semantics(container: true, liveRegion: true)` by construction; `MxProgressBar`
carries `label` + `value` with `ExcludeSemantics` beneath, and the study frame's
progress figure is labelled because *"'8 / 12' read out on its own says nothing
about what is being counted"*. Reduced motion is read off
`MediaQuery.disableAnimationsOf` and applied to decorative transitions only,
with an explicit refusal to freeze an indeterminate spinner (*"its motion is the
information"*). The open gap is A19-09.

**Navigation.** `AppBar` supplies `header: true` + `namesRoute` on every screen
title through `MxContentShell`, so screens announce themselves. `MxBreadcrumb`
uses `container: true, explicitChildNodes: true` so each step stays its own
stop, and `MxBreadcrumbStep` annotates `button`. `MxNavigationBar` is a Material
3 `NavigationBar`, which supplies `selected` and "tab n of m", and the
destination pair is outlined/filled with an always-visible label. Re-tapping the
current tab pops to that branch's root. The open gaps are A19-07 (section
headings below the app bar) and A19-12 (the title's one-line cap).

---

## 15 · Localization — EN / VI long-copy stress

**Parity is exact.** 836 keys in `app_en.arb`, 836 in `app_vi.arb`, zero keys in
one and not the other. 50 keys whose name ends `Semantics`, 214 whose name
suggests a label, all present in both. There is no fallback-to-English path in
the app for a missing key because there is no missing key.

**Length pressure, measured.** Mean VI/EN character ratio across all 836 strings
is **1.031** — so the "Vietnamese is ~25 % longer" figure in
`mx_stress_test.dart`'s header is true of *prose sentences* and not of the
corpus, which is mostly short labels. The pressure is concentrated:

| key | VI / EN ratio |
|---|---|
| `deckPathSemanticLabel` | 1.78 |
| `cardHistoryModeUnknownSemantics` | 1.75 |
| `progressRangeSelectorSemanticLabel` | 1.56 |
| `cardDueBadgeSemantics` | 1.40 |
| `cardStateDotSemantics` | 1.36 |

**All five are semantics strings, which is exactly the right place for the
overflow to land** — a spoken label has no layout to break. The longest *painted*
strings run the other way (`deckDeleteImpactMessage` 355 EN → 240 VI,
`reminderNotificationBodyManyDecks` 208 → 79), so the layouts under most
pressure are pressured by English.

`mx_stress_test.dart` pumps Vietnamese specimens at 320 × 2.0× for every shared
component. `test/demo/goldens/card_detail_320_x2_vi.png` pins one screen at that
combination. `mx_accessibility_test.dart` uses German for the confirm dialog,
deliberately, because it is longer than either shipped locale.

`search_group_header_widget` carries the one localization *rule* worth promoting
out of a comment and into the design system, since §7 and §8 both turn on it:

> *"`toUpperCase()` on a localized string is the translator's decision to make,
> not the widget's — it is wrong for locales with no case and changes the width
> the layout was measured at."*

No finding in this section. Localization is the healthiest dimension audited.

---

## 16 · Coverage gaps

### 16.1 · A19-14 (P2) — 10 of 17 screens have no guideline sweep

12 test files call `meetsGuideline`, 22 calls in all. Mapped to production
screens:

| screen | swept by |
|---|---|
| `deck_list_screen` | `deck_list_screen_test`, `deck_path_test`, `deck_sort_control_width_test` |
| `progress_screen` | `progress_screen_updates_test`, `progress_error_face_test`, `progress_composition_test` |
| `progress_deck_screen` | `progress_composition_test` |
| `settings_screen` | `settings_accessibility_test` |
| `study_home_screen` | `study_home_accessibility_test` |
| `study_session_screen` | `study_accessibility_test` — **frame only**, not the five mode bodies |
| *(overlay)* study direction chooser | `study_direction_chooser_layout_test` |
| **`card_detail_screen`** | **— none —** |
| **`card_editor_screen`** | **— none —** |
| **`card_import_screen`** | **— none —** |
| **`card_list_screen`** | **— none —** |
| **`tag_catalog_screen`** | **— none —** |
| **`library_search_screen`** | **— none —** |
| **`reminder_settings_screen`** | **— none —** *(has a semantics test, no guideline sweep)* |
| **`starter_library_screen`** | **— none —** |
| **`study_entry_screen`** | **— none —** |
| **`study_options_screen`** | **— none —** |
| **`trash_screen`** | **— none —** *(has `ensureSemantics`, no guideline sweep)* |

The unswept set is not random: it is the entire `card` feature plus search,
trash, reminder and the two study entry surfaces. A19-10 — a 24 dp target — lives
in the card list, and it is unswept for that reason and no other. Its counterpart
in the deck list is swept and its test's comment names the exact failure it
guards.

`mx_stress_test.dart` covers the *component* layer thoroughly, which is why the
gap has been survivable: a component with a bad target fails there. What escapes
is a target composed at a *call site* — which is precisely what A19-10 is.

**Closure.** One `meetsGuideline(androidTapTargetGuideline)` +
`meetsGuideline(labeledTapTargetGuideline)` pair per screen, on the existing
harnesses (`card_*_test.dart` files already hold `ensureSemantics` handles, so
the harness work is done). Expect A19-10 to fail immediately on the card list.

### 16.2 · A19-15 (P2) — nothing renders a screen under a high-contrast theme

Four files reference `buildHighContrastLightTheme` / `buildHighContrastDarkTheme`:

| file | what it does |
|---|---|
| `app_high_contrast_test.dart` | token-level assertions, no widget pumped |
| `color_scheme_roles_test.dart` | role-level assertions, no widget pumped |
| `mx_card_recipes_test.dart` | **pumps `MxCard` recipes** under all four themes |
| `mx_action_button_state_matrix_test.dart` | pumps the button matrix under all four |

So exactly **two components** render under the flag, and:

- **zero goldens** — `test/demo/goldens/` holds 152 PNGs and not one is a
  high-contrast render;
- **zero Widgetbook surface** — `widgetbook/lib/main.dart` declares
  `MaterialThemeAddon`, `TextScaleAddon`, `LocalizationAddon`, `ViewportAddon`,
  `InspectorAddon` and `BuilderAddon`; the theme addon carries light and dark
  only, so a reviewer cannot look at high contrast at all;
- **zero screens.**

The consequence is precisely A19-02 and the `borderSelected` inversion in
A19-12: a token-level test can only check the tokens it was told about, and
nothing above it ever renders. Both defects are visible on one screen — the
export sheet — under one theme nobody builds.

**Closure, in cost order.** (a) Add the two high-contrast themes to the
Widgetbook `MaterialThemeAddon` — one line, and it makes the mode reviewable by
a person, which is what would have caught the inversion. (b) Extend the
guideline sweeps from §16.1 to run under all four themes rather than two.
(c) Do **not** add high-contrast goldens: 152 → 456 PNGs for a palette
difference is the wrong trade, and `CLAUDE.md`'s gallery rule (*"one surface and
one only"*) is the same argument in the other direction.

### 16.3 · A19-13 (P2) — the guard cannot see the token that fails it

Restated from §4 because it is a coverage finding as much as a contrast one.
`test/visual_audit/memox_audit.dart:32-44` builds
`NonTextContrastRule(<Color>[primary, success, warning, danger, info,
borderControl])`. The rule's own doc explains why the list is a list and not
"every stroke" — *"Intent cannot be inferred from a rectangle, so it comes from
the token vocabulary, which already encodes it"* — and that reasoning is right.
The list is just incomplete: `borderOption` and `borderSelected` are the two
tokens in the palette whose entire job is to identify a control or its state,
and neither is in it.

The list already records one such omission being found the hard way:
*"`borderControl` joined the list with the card-detail timeline (M99.31) … The
omission is why the connector shipped its first draft at 1.38:1 on the page
ground and the audit reported PASS."* This is the second instance of the same
mechanism.

**Closure.** Add both tokens; put the export sheet on the audited surface list;
and consider deriving the list from `AppSemanticColors`' fields rather than
hand-writing it, with an explicit exemption list for the decorative three
(`borderSubtle`, `borderDivider`, `borderAccent`) — an allowlist of exemptions
fails closed where an allowlist of subjects fails open, and this file has now
failed open twice.

### 16.4 · A19-16 (P2, owner decision) — the recall clock has no recorded WCAG position

BR-128 (frozen): *"`recall` MUST cho tối đa **20 giây** mỗi lượt"* — 20 seconds
per turn, measured in real interaction time, paused when the app backgrounds.
BR-107: running out is graded `forgotten`. BR-160: the timeout end shows a Next
button rather than auto-advancing.

The pausing behaviour is genuinely good and is more than most timed UIs do. What
is missing is a *position*: WCAG 2.2.1 Timing Adjustable (Level A) requires that
a time limit be turnable-off, adjustable to ten times the default, or extendable
— **unless** the limit is essential, and *"extending it would invalidate the
activity"*.

A timed recall exercise is a strong candidate for the essential exception, and
BR-146 supplies real mitigation: `recall` is one of four gradable
`eight_box` modes and the learner picks the mode when more than one is
available, so nobody is forced into the clock. But none of that is written down
as an accessibility argument anywhere — not in `business-rules.md`, not at
`recall_mode.dart`, not in a test. A frozen business rule with an unstated
standards position is exactly the thing an external accessibility review will
open first, and the answer will then be reconstructed under time pressure.

**This is not a code finding and no code change is proposed.** It is an owner
decision with three shapes:

1. **Record the essential exception.** Add the 2.2.1 argument and the BR-146
   mitigation to `business-rules.md` beside BR-128 and cite it at
   `recall_mode.dart`. Costs nothing, changes no behaviour, and is almost
   certainly the right answer.
2. **Make the duration a study default.** `settings_study_defaults_section_widget`
   already exists and already holds a numeric field. A user-set recall duration
   would satisfy 2.2.1 outright. It changes a frozen BR and it changes what a
   session means across devices.
3. **Extend on request.** A "+20 s" affordance on the running clock. Smallest
   behavioural change that satisfies the criterion literally; also the one most
   likely to be used accidentally and to make two learners' histories
   incomparable.

Recommend (1), and recommend it be done in the same pass as the code fixes so
the position exists before anyone asks.

### 16.5 · A19-22 (P3) — two platform flags nothing reads

`MediaQuery.highContrast` is read (by `MaterialApp`, correctly) and
`disableAnimations` is read (by `AppMotionPolicy`, correctly). Nothing reads
`boldText` or `accessibleNavigation`.

`boldText` matters most: on iOS and Android the OS applies it to system text
automatically, but this app pins `fontFamily: AppTypography.bodyFamily` and uses
variable-font `fontVariations` throughout — `AppTypography.withWeight` exists
because *"a bare `fontWeight:` paints the rung's old weight"*. A variable font
driven by an explicit `wght` axis will **not** follow the platform's bold-text
setting. So a user who has turned it on gets the app's declared weights.

P3 — iOS is deferred (AD-04), the effect on Android is smaller, and the fix
touches the type scale, which is a design decision rather than a bug fix. Worth
recording so it is a decision next time rather than a discovery.

---

## 17 · Severity registry

Severity here means: **P0** no accessible operation for a core task; **P1** a
measured WCAG A/AA failure on a live surface; **P2** a measured failure with a
mitigation present, or a coverage hole that permits one; **P3** correctness or
consistency with no measured user-facing failure.

| ID | Sev | Finding | Evidence (all at BASE_SHA) | Closure test |
|---|---|---|---|---|
| A19-01 | **P0** | `browse` advances only by a 70 dp drag | `study_swipe_deck_widget.dart:169-197`; `study_card_face_section_widget.dart:375`; `study_mode_view_widget.dart:166`; 0 occurrences of `Shortcuts`/`LogicalKeyboardKey` in `lib/` | Tab+Enter advances without a drag; target meets `androidTapTargetGuideline`; absent while `isLocked` — `study_swipe_deck_test.dart` |
| A19-02 | **P1** | `borderOption` 2.67:1 light on its own ground; HC does not re-point it | computed table §2.2; `card_export_format_options_widget.dart:192`; `app_bottom_sheet_theme.dart:12` == `mx_card.dart:586`; `app_high_contrast.dart:69-77` | `borderOption` on `surfaceContainerLow` ≥ 3:1 in all four themes — `control_border_grounds_test.dart` |
| A19-03 | **P1** | single-choice menu marks its value at 1.18/1.32:1, no semantics | `mx_menu_button.dart:78`; `app_theme.dart` `highlightColor`; `app_popup_menu_theme.dart:42` | selected item's node reports `isSelected` + a non-colour mark — `mx_menu_button_test.dart` |
| F1 *(carried)* | **P1** | `MxSearchField` unnamed once it holds a value | `mx_search_field.dart:150-176` | node label non-empty with a value present |
| F2 *(carried)* | **P1** | `MxSearchField` box ignores `textScaler` | `mx_search_field.dart:148` | height grows at 1.3 / 2.0 / 3.0 |
| F3 *(carried)* | **P1** | focus invisible on an errored field | `app_input_theme.dart:42-43` | `focusedErrorBorder != errorBorder` |
| A19-04 | **P2** | HC re-points 4 of 8 border tokens; `borderSelected` ladder inverts | §2.3 / §12 tables; `app_high_contrast.dart:69-77` | HC: `borderSelected` and `borderOption` each > `borderSubtle` on every ground |
| A19-05 | **P2** | every figure in `app_high_contrast.dart` stale; 4.88 → 3.80 | §11 reconciliation | grounds pairwise distinct; regenerate the table |
| A19-06 | **P2** | dimmed trash row 2.11 / 1.69:1, unreachable by HC, raw literal | `trash_row_widget.dart:75-76`; `AppStateOpacity.disabledContent` | dimmed row text ≥ 3:1 both modes; no bare `AppStateOpacity` literal in `lib/features/` |
| A19-07 | **P2** | 4 heading policies; 2 of 15 group headings announced | `settings_section_widget.dart:52`; `study_home_body_section_widget.dart:182`; §7 table | every `sectionLabel` site routes through one shared heading component |
| A19-08 | **P2** | 21 `toUpperCase()` sites, 1 mitigated | census §8 | painted case differs from `semanticsLabel` ⇒ excluded or sentence-case label |
| A19-09 | **P2** | `MxErrorState` / `MxEmptyState` not live regions | the two files; 3 call-site hand-rolls | error branch node `isLiveRegion` — `mx_async_view_test.dart` |
| A19-10 | **P2** | card sort control 24 dp against the project's 48 | `card_sort_control_widget.dart:48-65`; `labelSmall` 11/16; `AppIconSize.sm` 16; `AppSpacing.xs` 4 | `androidTapTargetGuideline` on the card list toolbar |
| A19-11 | **P2** | card row announces its state twice | `card_tile_widget.dart:137` and `:210` | merged row label contains the state word exactly once |
| A19-12 | **P2** | shell title `maxLines: 1` + ellipsis with a subline | `mx_content_shell.dart:254` | no `didExceedMaxLines` at 320 dp × 2.0× VI |
| A19-13 | **P2** | `NonTextContrastRule` omits `borderOption`, `borderSelected` | `memox_audit.dart:32-44` | both in `informationalColors`; export sheet audited |
| A19-14 | **P2** | 10 of 17 screens unswept | §16.1 matrix | one tap-target + labelled-target pair per screen |
| A19-15 | **P2** | nothing renders a screen/golden/catalog under HC | 4 referencing files, 0 screens; `widgetbook/lib/main.dart:76` | HC themes in the Widgetbook theme addon; sweeps run under 4 themes |
| A19-16 | **P2** | recall clock has no recorded 2.2.1 position | BR-128, BR-107, BR-146 | *n/a — documentation, §16.4* |
| A19-17 | P3 | `selected:` on a non-selectable stepper node | `card_import_stepper_widget.dart:177` | step node `hasSelectedState == false`, label unchanged |
| A19-18 | P3 | card sort control announces name, never value | `card_sort_control_widget.dart:48` | node `value` == active sort label |
| A19-19 | P3 | `MxSwitchRow` stacks `value` on a `toggled` node | `mx_switch_row.dart:76` | *accepted — record the trade at the widget* |
| A19-20 | P3 | `useSafeArea: true` at 2 of 17 sheet sites | 17 `showModalBottomSheet` call sites | sheet content respects top padding at 2.0× |
| A19-21 | P3 | 34 `ExcludeSemantics`, several redundant | census §6.1 | *none — recorded* |
| A19-22 | P3 | nothing reads `boldText` / `accessibleNavigation` | 0 occurrences in `lib/` | *n/a — §16.5* |

---

## 18 · Implementation order

Sequenced so each step's test exists before the step that needs it, and so no
step lands without a guard that would catch its regression. Nothing in this
report has been implemented.

### Step 1 — make the guards able to see the defects (no production change)

Every later step is verified by one of these, and two of them fail today, which
is the point of doing this first.

| file | change |
|---|---|
| `test/visual_audit/memox_audit.dart` | add `borderOption`, `borderSelected` to `informationalColors`; add the export sheet to the audited surfaces — **A19-13** |
| `test/core/theme/contracts/control_border_grounds_test.dart` | add both tokens; add `surfaceContainerLow` to the grounds; assert `page != surface` — **A19-02, A19-05** |
| `test/core/theme/schemes/app_high_contrast_test.dart` | five border tokens not three; grounds pairwise distinct; the `borderSelected > borderSubtle` ordering assertion — **A19-04, A19-05** |
| `widgetbook/lib/main.dart` | high-contrast themes in `MaterialThemeAddon` — **A19-15** |

Expected: `control_border_grounds_test` and `app_high_contrast_test` go red on
`borderOption` in light. That is the finding, reproduced.

### Step 2 — the P0

| file | change |
|---|---|
| `lib/features/study/presentation/widgets/support/study_swipe_deck_widget.dart` *(or the session frame — owner's choice per §3)* | a single-pointer, keyboard-operable path forward, sharing the drag's `isLocked` predicate |
| `test/features/study/presentation/study_swipe_deck_test.dart` | the three assertions in §3 |

**Blocked on an owner decision** (which of the three shapes). Everything else in
this list can proceed without it.

### Step 3 — the palette, one commit

| file | change |
|---|---|
| `lib/core/theme/foundations/app_border_colors.dart` | `borderOptionLight` to a value clearing 3:1 on `surfaceContainerLow`; delete or correct the stale `#8887CE` paragraph — **A19-02** |
| `lib/core/theme/schemes/app_high_contrast.dart` | re-point `borderOption` and `borderSelected`; regenerate the whole measurement table; state why `borderDivider` is exempt — **A19-02, A19-04, A19-05** |
| `design_system/tokens/colors.css` + `test/design_audit/css_token_parity_test.dart` | move the kit with the app, or record the divergence with the ratio as its reason — **owner decision**, §4 |

Goldens move here. `card_export_sheet` and any deck/card surface drawing an
option edge will shift, so this is the commit that regenerates and republishes
the gallery per `CLAUDE.md`.

### Step 4 — semantics, no pixels

| file | change |
|---|---|
| `lib/shared/widgets/mx_menu_button.dart` | trailing check + `Semantics(selected:, inMutuallyExclusiveGroup:)` on `_MenuRow` — **A19-03** |
| `lib/shared/widgets/mx_error_state.dart`, `mx_empty_state.dart` | `liveRegion` inside; drop the three call-site wrappers — **A19-09** |
| `lib/features/card/.../items/card_tile_widget.dart` | `ExcludeSemantics` the state dot — **A19-11** |
| `lib/features/card/.../sections/card_import_stepper_widget.dart` | drop `selected:` — **A19-17** |
| `lib/features/card/.../support/card_sort_control_widget.dart` | `value:` for the active sort — **A19-18** |
| `lib/features/trash/.../items/trash_row_widget.dart` | token pair instead of `Opacity(0.38)`; `enabled: false` — **A19-06** |

### Step 5 — the shared heading component

| file | change |
|---|---|
| `lib/shared/widgets/mx_section_heading.dart` *(new)* | `header` + `container` + sentence-case `label` + `excludeSemantics` + the `sectionLabel` treatment — **A19-07, A19-08** |
| 14 call sites across `card/`, `deck/`, `settings/`, `study/` | route through it |
| `test/shared/widgets/mx_stress_specimens.dart` | a specimen, so the completeness test admits it |
| a new guard test | fail on any `textStyles.sectionLabel` site not routed through the component |

Goldens move again (tracking changes on 14 headings), so this is a second
regenerate-and-republish. Keeping it out of step 3 keeps each golden diff
readable, which is the whole reason the gallery exists.

### Step 6 — geometry and coverage

| file | change |
|---|---|
| `lib/shared/widgets/mx_content_shell.dart` | title `maxLines: 2` — **A19-12** |
| `lib/shared/widgets/mx_menu_button.dart` | floor the `child:` anchor at 48 — **A19-10** |
| `lib/shared/widgets/mx_form_sheet.dart` + 2 overlay helpers | `useSafeArea: true` — **A19-20** |
| 10 screen test files | the tap-target + labelled-target pair — **A19-14** |
| the same 10 | run the sweeps under all four themes — **A19-15** |

### Step 7 — documentation, no code

| file | change |
|---|---|
| `docs/business-rules.md` (beside BR-128) + `recall_mode.dart` | the WCAG 2.2.1 essential-exception argument and the BR-146 mitigation — **A19-16** |
| `lib/shared/widgets/mx_switch_row.dart` | one line recording that the `value`/`toggled` duplication is accepted — **A19-19** |
| `docs/wbs.md` | the A19 entry, in the same commit as the code it describes |

---

## 19 · Owner decisions required

Four, and the audit deliberately stops at each rather than choosing:

1. **A19-01 — how `browse` gains an accessible operation.** BR-111 and BR-155
   are the reason its button was removed, and the removal was reviewed.
   Recommend tap-anywhere-to-advance with the drag kept as the fast path: it
   closes both 2.1.1 and 2.5.7, costs the card no area, and collides with
   nothing because `browse` grades nothing.
2. **A19-02 — kit or divergence.** `borderOptionLight` must darken to clear 3:1.
   Either `design_system/tokens/colors.css` moves with it, or
   `css_token_parity_test.dart` records a deliberate divergence with the ratio
   as its reason. Recommend moving the kit; a parity test with an exemption is a
   parity test with a hole in it.
3. **A19-16 — the recall clock.** Recommend recording the essential exception
   (§16.4 option 1). It changes no behaviour, does not touch a frozen BR, and
   the mitigation BR-146 already provides is genuine.
4. **A19-15 scope — how far high-contrast rendering goes.** Recommend the
   Widgetbook addon plus running the existing sweeps under four themes, and
   recommend **against** high-contrast goldens: 152 → 456 PNGs for a palette
   delta is the wrong trade, and `CLAUDE.md`'s one-surface gallery rule is the
   same argument pointing the same way.

---

## 20 · What must not be touched

Recorded because a later pass working from the registry alone could undo it.

- **The high-contrast build seam.** All four themes go through one `_buildTheme`,
  and `app_high_contrast_test.dart` asserts the brand, page, ladder, semantics,
  filled fill and outlined label are identical across the pair. That is what
  makes role identity a structural property rather than a review promise. Fixing
  A19-02 and A19-04 means adding tokens to `copyWith` — never adding a second
  builder.
- **`borderSubtle`, `borderDivider` and `borderAccent` at 1.0–1.9:1 in the
  normal themes.** They are decoration; M99.94 and M100.0 spent milestones
  establishing it, and a well-meaning 3:1 sweep would turn the app back into a
  grid of frames.
- **The focus ring.** `primary` at ≥ 4.58:1 light and ≥ 7.24:1 dark, on a stroke
  that never changes width so focus never nudges layout. Best part of the
  system.
- **`AppMotionPolicy`'s refusal to freeze an indeterminate spinner.** *"Its
  motion is the information."* A blanket reduced-motion sweep would break it.
- **`MxActionButton._takesFocus()`'s `highlightMode` gate.** Removing it puts
  focus on a destructive confirm on a phone that has no keyboard.
- **`search_group_header_widget`'s refusal to uppercase a localized string.** It
  is the correct rule and §7's shared component should adopt it, not override it.
- **`MxCard.isSelected`'s tri-state.** `null` means "not selectable at all", and
  collapsing it to `bool` would make every non-selectable card announce a
  selection state.
