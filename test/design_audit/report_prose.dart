/// The written half of the colour-system audit.
///
/// Every table in the report is generated from JSON; everything here is the part
/// a person judged. Separated so the two are obvious at a glance — and because
/// the report generator crossed the 400-line guard, which forced the question of
/// which half was which.
///
/// Nothing in this file is asserted. If a claim below stops matching the numbers
/// it explains, the numbers do not change and no test goes red — that is the
/// standing risk of narrative, and the reason each claim quotes the figure it
/// rests on.
library;

const Map<String, String> codeMeanings = <String, String>{
  'V1': 'neutral not derived from the seed',
  'V2': 'role component using a colour outside its role',
  'V3': 'literal duplicating an existing token',
  'V4': 'hand-picked role variant instead of a generated one',
  'V5': 'translucency applied at the paint site',
  'V6': 'defined for one brightness, different mechanism in the other',
};

const String scopeNote = '''
**Scope and method.** Every hand-written `.dart` file under `lib/` was parsed
with `package:analyzer` — not grepped — so a colour named in a doc comment is not
a site and a colour inside a conditional is. Values are resolved against the
**built `ThemeData`**, not against `AppColors`, because `ColorScheme.fromSeed`
fills roles this app then overrides and only the theme says what ships.

Resolution has one real limit, stated rather than hidden: the parse is
unresolved, so a reference is matched by its written form. A site whose value
depends on runtime state resolves to `unresolvable` with the reason, never to a
guess.
''';

const String perceptualPreamble = '''
The brief's band for a neutral border is **1.06:1 floor, 1.6:1 ceiling** — below
the floor it is invisible, above the ceiling it draws a frame instead of defining
an edge.
''';

const String perceptualVerdict = '''
**The light-mode border-prominence answer, plainly:** `borderSubtle` is
**1.50:1** against the card and **1.38:1** against the page — inside the brief's
band. Dark is **1.82:1** and **2.12:1**, above the ceiling, and stays there
deliberately.

**This section has been through three positions and only the last one is
measured.** It first reported both modes above the ceiling and rejected the
ceiling, on the grounds that the app was flat *by decision* and the border was
therefore the only cue it had. The flatness was never a decision — no AD, no BR,
no test — and the project owner has since said the app needs real elevation. At
M4.10h it got one, and the ceiling is met in light because the border no longer
carries the edge alone.

**Dark keeps its heavier border for a reason that is a number.** A dark shadow at
four times the alpha light uses moves the page by **0.26 L****, against a surface
step already worth 7.70 — the dark page sits at the bottom of the lightness scale
and there is no room beneath it. Dark has no second cue to hand the work to, so
its border keeps it. Material 3 drops dark shadows for the same reason.

**The modes remain symmetric, in the property that matters.** Not border contrast
— light's border is now the lighter of the two — but total lift of a card off its
page: **7.62 L** in light against 7.70 in dark**. The shadow alpha was solved for
that number rather than picked; a first draft used 0.12 and overshot to 13.28,
which made light cards float where dark's sat. `app_theme_test.dart` now pins the
lift instead of the border, and `app_elevation_test.dart` pins the measurement
that says dark should not paint.

**The light-mode background-tint answer, plainly:** both are tinted. The page is
`#F4F5F8` and the card is `#FBFBFE` — `seed @ 0.02` over white, hue 240.

**It was the audit's largest finding and it is closed.** The card was pure
`#FFFFFF` with no hue at all, along with `surfaceBright`,
`surfaceContainerL*owest`, `surfaceElevated` and every dialog and sheet that
follows them: a tinted canvas with an untinted surface sitting on it, which is
why light read as a different palette from dark.

Closing it cost lightness, and the cost was paid rather than waived. A tinted
card is a darker card, so the surface step fell from 3.46 L** to 2.15. Two things
absorbed that: the shadow's alpha was re-solved from 0.05 to 0.07, and the light
ladder's minimum step went from 3.0 to 2.0 — the step it gave up is exactly what
the shadow took on, and the total lift is unchanged at **7.75 L** against dark's
7.70**.

**Neutral family coherence:** both are one family now. Every neutral in both
modes carries a hue and sits within 25° of the seed — pinned by MX-VIS-002 rule
R9, which was a proposal in this report until it started passing.
''';

const String asymmetryNote = '''
Every row here is a token that exists under both brightnesses and is *built
differently* in each. These are the 🔴 findings: a mode-dependent mechanism cannot
be kept in step by editing one value.
''';

const String roleVerdict = '''
**V2 and V4 are zero, and that is a measured result rather than an unchecked
box.** Each role's fill and container sit within 2° of one hue, so no component
is borrowing another role's colour and no variant was hand-picked away from its
family. The palette file's own doc explains why: every M3 role is declared
explicitly after a generated set was found to contain a pink `tertiary` and a
competing `error` red.

The gap the model does name: **`success`, `warning` and `info` have a fill and
nothing else** — no container, no border, no focus token. Nothing on screen needs
them yet, so this is a hole in the model rather than a defect in the app, and it
is the first thing to fill if a success badge or a warning banner is ever
designed.
''';

const String componentMapNote = '''
**`component-map.json` does not exist in this repository.** Nothing was
cross-checked against it, and no stale entries could be reported. A search of the
whole tree (excluding `.git`) returned no file of that name. If it lives outside
the repo, re-run the cross-check with the file present.
''';

const String notVerified = '''
- **`component-map.json` cross-check** — the file is absent (see section 6).
  Retry: place it at the repository root and re-run
  `flutter test test/design_audit/`.
- **The brief's `#0B1220` dark-surface family** — this app's dark page is
  `#0A082D`. Both seed hypotheses are measured in `tokens_current.json`; they
  differ by 3.2°, so the choice does not change any verdict here, but the value
  in the brief does not appear in this codebase.
- **Runtime-dependent values** — sites whose colour comes from a
  `WidgetStateProperty` resolver or a data-driven ternary are recorded as
  `unresolvable` with the reason. They are correctly *classified* (their source
  is a token either way); only the final hex is unavailable without rendering.
- **Colours introduced by Material's own defaults** — anything the framework
  paints that this app never names is out of scope for a source scan. The strict
  visual audit under `test/visual_audit/` covers that from the other direction,
  by walking the render tree.
''';

const String migrationPreamble = '''
**Nothing here has been applied.** The audit changed no colour. Each batch below
is written so it can be taken on its own and judged by its golden diff.

Two of the proposals are genuinely contested and are marked as such — a migration
map that presented them as settled would be smuggling a design decision through a
conformance report.
''';

const String targetTokens = '''
### Global, seed-derived

The seed is `#4646B4` (hue 240 degrees), already declared as `AppColors.seed`.
The canonical derivation is
`Color.alphaBlend(seed.withValues(alpha: a), base)`, precomputed to a constant.

**Every proposed value below was computed, then re-measured.** Three of them were
wrong when first written by hand and are corrected here; the working is in
section 4.

| target token | light now | light proposed | dark now | dark proposed | note |
|---|---|---|---|---|---|
| `surface` | `#FFFFFF` (no hue) | `#FCFCFE` = seed @ 0.015 over white | `#1B1D32` | keep | **Closes the headline V1.** Hue becomes 240, chroma 0.008 — far inside the light canvas budget. **But see the cost below.** |
| `surfaceDim` | `#DEE0E7` | keep (hue 227) | `#08061F` | keep | Already in family. |
| `borderSubtle` | `#BEC0C3` (hue 216) | `#BFBFCB` = the same lightness at hue 240 | `#414762` | keep | Contrast against the card is **1.82 before and 1.82 after**, so the M4.10e depth decision survives untouched. Chroma 0.047, inside the 0.06 budget. |
| `borderDefault` | — | `#A8A8B8` | — | `#5A6180` | New. Nothing needs a second border weight today; listed because the model names it. |
| `shadowTint` | `#0B0C18` (hue 235) | keep | `#000000` (no hue) | `#04040B` = seed @ 0.06 over black | **Closes a V6.** L*ight's shadow already carries the seed; dark's does not. |
| `textMuted` | `#565C72` | keep | `#A6ABC2` | keep | Already in family, 11-13 degrees off seed. |

**The cost of the `surface` proposal, stated rather than buried.** Tinting the
white card moves it *toward* the page: the card-to-page contrast goes from
**1.090:1 to 1.064:1**. So the change that closes the largest V1 also shrinks the
very surface step that already fails to separate a card from its background. The
two are not independent — a tint that is visible enough to count as
"seed-derived" is a tint that darkens white — and this is the reason batch 4 is
marked contested rather than obvious.

If the tint is adopted, the border has to keep carrying the boundary alone, which
it does today at 1.82:1 and would continue to do unchanged.

### Per-role

`RoleTokens(fill, onFill, container, onContainer, border, focus)`, one generator
per role.

| role | fill (light / dark) | container (light / dark) | border | focus |
|---|---|---|---|---|
| `primary` | `#4646B4` / `#5656C9` | `#DCDCF2` / `#2B2B6E` | derive @ 0.35 | `#4141C0` / `#8A8AE0` (exists) |
| `danger` | `#B02233` / `#E88794` | `#F8DDE1` / `#5E2831` | derive @ 0.35 | derive |
| `success` | `#1E7156` / `#68BB9C` | **missing** - derive | **missing** | **missing** |
| `warning` | `#856520` / `#D2AC76` | **missing** - derive | **missing** | **missing** |
| `info` | `#456480` / `#8FAEC6` | **missing** - derive | **missing** | **missing** |

Every fill above is a current value that measured clean and is kept. The work is
in the empty cells, not in re-picking what exists.
''';

const String fillOrder = '''
| value | goes in | why |
|---|---|---|
| `surface`, `surfaceDim`, `outline`, `outlineVariant`, `shadow`, `scrim` | `ColorScheme` | Material widgets read these directly. A token that Material already has a slot for must live in that slot, or the framework paints one value and the app another. |
| `primary` / `error` full sets | `ColorScheme` | M3 already models fill + on + container + onContainer for these two. |
| `success`, `warning`, `info` sets | `ThemeExtension` (`AppSemanticColors`) | Material has no slot for them, and mapping `warning` onto `tertiary` is how a semantic colour gets repurposed by an unrelated widget. |
| `borderDefault`, `shadowTint` | `ThemeExtension` | No M3 equivalent; both are app concepts. |
| per-role `border` and `focus` | `ThemeExtension` | Derived values with no M3 slot. `focusRing` already lives there. |
''';

const String batchPlan = '''
Ordered so each batch is independently reviewable, smallest blast radius first.

**Batch 1 — `shadowTint` symmetry (V6, 🔴).** Dark `shadow` and `scrim`
`#000000` → `#050414`. One file, `app_colors.dart`.
*Goldens expected to change:* none — no shipped surface paints a shadow today
(`cardTheme.elevation` is 0). This is a latent fix, which is exactly why it is
first.

**Batch 2 — the two literals (V6 🟡 / V3 🟡).**
`error_screen_widget.dart` gets a const pair chosen from
`PlatformDispatcher.platformBrightness` — it cannot read a theme, so this is the
only mechanism available. `mobile_frame_widget.dart` gets a named constant.
*Goldens:* none. Neither surface is in a golden.

**Batch 3 — precompute the translucent values (V5, 🟢).** Four sites:
`app_button_themes.dart` ×2, `app_theme.dart` disabled input border,
`mx_action_sheet.dart`. Each becomes a `blendOver(...)` constant.
*Goldens:* `mx_text_field_disabled_light/dark`, `mx_action_sheet_*`,
`button_*_disabled` if present — the rendered pixels should be **identical**,
because the blend reproduces what compositing already produced over the standard
surface. A diff means the site was compositing over something else, which is the
bug this batch exists to remove.

**Batch 4 — `surface` gets a seed trace (V1, 🔴). Contested.**
L*ight `surface` `#FFFFFF` → `#FCFCFE`, and with it `surfaceBright`,
`surfaceContainerL*owest`, `surfaceElevated`, `cardTheme.color`,
`dialogTheme.backgroundColor`, `bottomSheetTheme.backgroundColor`.
*Goldens:* nearly every light golden — 12+ files.
*Contested because* a pure-white card is a legitimate design position, and this
change is visible on every screen. It closes the audit's single largest finding
and it is a decision, not a correction.

**Batch 5 - `borderSubtle` hue (V1, 🟢).**
L*ight `#BEC0C3` -> `#BFBFCB`. Hue 216 -> 240, contrast against the card
**1.82 before and after**, chroma 0.047 against a 0.06 budget.

*Goldens:* every light golden with a card, input or chip - around 12 files, all
of them a hue shift at identical lightness.

*This was drafted as contested and the measurement withdrew the objection.* The
first draft claimed the seed rule and the chroma budget pull opposite ways at
this lightness, and proposed `#BFC1C9` on that basis. Solving for the constraints
instead of guessing found a value that satisfies all three at once - the two
rules are compatible here, and the 24-degree drift introduced at M4.10e was
avoidable rather than forced.

**Not planned: adopting the brief's 1.6:1 border ceiling.** See section 3 of the
report — it would flag both modes, and satisfying it means adding a shadow or
widening the surface step first.
''';
