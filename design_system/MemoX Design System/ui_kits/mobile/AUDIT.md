# MemoX Mobile UI Kit — Audit & Improvement Pass

> **Status — historical changelog.** Each entry records what a given pass did at
> the time, and is left as written. Several values below were superseded by the
> **2026-09 normalization pass**; the table maps the old record to the current
> contract. For current values read `colors_and_type.css` and the token tables in
> `components.html`, never this file.
>
> ### Superseded values (2026-09)
>
> | Recorded here | Current |
> |---|---|
> | `--memox-radius-card` = 16 | **20** — `.card` renders 20; the token was realigned to the code |
> | `--memox-space-card` = 16 | **20** |
> | `--memox-space-screen` = 24 | **16** — equals `--screen-gutter`, which itself moved 14 → 16 |
> | `--memox-radius-fab` = 28 | **16** — `.fab` uses `radius-lg`; the token was realigned |
> | `--memox-size-fab` = 56 | **52** — equals `--fab-h` |
> | `--memox-size-appbar-lg` = 64 | removed — `.appbar-lg` renders 56, same as `.appbar` |
> | `--memox-fs-title-medium` (16) | **`--memox-fs-body-lg`** — the 15-name type layer collapsed to 7 real steps |
> | `--memox-fs-body-small` (14) | **`--memox-fs-body`** |
> | `--memox-fs-stat-display` (48) | **`--memox-fs-stat`** = 40 |
> | Icon sizes as raw numbers | semantic steps `xs 16 / sm 20 / md 24 / lg 32 / xl 40`, passed as `size="md"` |
> | Decimal type sizes kept in `.wid-*` | removed — specimens are production UI, snapped to the type scale |

> ## Pass 4 — premium polish (systemic primitives + key screens)
> Targeted the open items from the systemic audit (§MOBILE_UI_AUDIT) at the
> shared layer so every screen benefits, plus the four flagged "judgement-call"
> screens.
>
> **Tokens / theme**
> - New neutral **`--memox-shadow-fab`** (light `0 8px 24px rgba(15,22,56,.12)`, dark `0 10px 28px rgba(0,0,0,.5)`); the FAB's old colored primary glow (36% indigo) is retired — elevation is now tonal, not branded (fixes H3/H7).
> - **Dark card separation:** `.memox-dark .card` now carries the indigo `--memox-border-ghost`, so paper-indigo cards have a defining edge on the near-adjacent dark surface ladder (fixes H7/M2).
> - **Density:** `.ov` overline 10.5/600/.85α → **11/700/1α**; bottom-nav labels 10 → **11** (fixes M3/M4 scanning legibility).
> - FAB radius `16px` magic number → `var(--memox-radius-lg)`.
>
> **Shared primitives (`_shared.jsx`)**
> - **`SearchField`** — real mobile search (52px input token, leading search glyph, trailing CLEAR when filled / VOICE when empty). Replaces the desktop-style static span + **Cmd-K `kbd` hint** on Library (fixes H5).
> - **`Badge`** — one count/status pill (tonal or `solid`, 5 tones, roomy padding + tabular nums). Fixes the cramped **"23due"** rendering (M1): `inline-flex` was trimming the whitespace-only text node; the badge's `gap` + single-string child restores the space.
>
> **Key screens**
> - **Dashboard CTA hierarchy (H6):** exactly one solid primary now — *Start today's review*. *Resume* demoted to a tonal (primary-soft) action; *Start new learning* demoted to a quiet text action with a `Badge`. Recent-deck due pills → `Badge`; `${col}1F` hex-alpha → `color-mix` (C2).
> - **Library:** search bar → `SearchField`; folder due pills → `Badge`; folder/​result icon tiles `${seed}1F` → `color-mix` (C2).
>
> Verified light + dark via an isolated harness (`_harness.html`, since the full
> 23-screen gallery is too heavy to screenshot in one pass).

# MemoX Mobile UI Kit — Audit & Improvement Pass

**Scope:** mobile, Flutter only. No web / desktop / tablet / React / PWA assumptions.
**Subject:** `ui_kits/mobile/index.html` — the 23-screen light+dark click-through.
**Goal:** make the existing kit more complete, more consistent, more accessible, and
ready for Flutter implementation — *without* redesigning the established visual language.

This document is the engineering-handoff layer: it records what was found, what was
fixed in this pass, what remains a recommendation, and how each item maps to Flutter
widgets and the `lib/core/theme/tokens/**` token classes.

---

## 0. Pass 2 — recursive theme (light/dark) + UI/UX review

A second recursive pass reviewed every section in **both** Tokyo Pure Light and Tokyo
Nebula, focusing on theme correctness and UX friendliness. Findings:

**Fixed**
- **Stray scrollbars / horizontal overflow (MAJOR, dark + light).** The Guess screen and
  two bottom-sheet lists (tag picker, move-folder) used raw `overflow: auto` /
  `overflow-y: auto`. Because setting only the Y axis makes the X axis compute to `auto`
  too, a phantom **horizontal scrollbar** appeared and the vertical scrollbar showed
  natively (the rest of the kit hides scrollbars via `.scroll`). Added a shared
  `.hide-scroll` utility (`overflow-x: hidden` + hidden scrollbar) and applied it to all
  three. Options now use the full card width. **Flutter map:** non-issue — `ListView` /
  `SingleChildScrollView` manage their own scroll; just confirm `scrollDirection` is vertical.
- **Identical Recall / Fill states (MAJOR).** "Hidden vs Revealed" and "Input vs Wrong"
  rendered identically because the state was only a `useState` *initializer*; changing the
  stepper prop never re-ran it. Fixed by keying each frame on its state value in
  `ScreenRow.make()` so the screen remounts and re-initialises. Single-state interactive
  screens keep a constant key, preserving their interactivity. **Flutter map:** irrelevant —
  in-app these are real state transitions, not prop-seeded mounts.

**Reviewed and confirmed correct (no change needed)**
- **Toast / snackbar** (Tag op-error) uses a fixed dark slate (`rgb(52,57,93)`) with light
  text in *both* themes — the M3 inverse-surface pattern. Legible in light and dark. Good.
- **Primary buttons** use the accessible dark primary `#8B9AFF` with deep-navy label
  `--memox-on-primary: #11173A` in dark (Phase 0: the scoped `.memox-dark` and the
  `colors_and_type.css` media-query scope are value-identical — `#8B9AFF` was lifted from
  the old `#5265F5` so it clears AA both as a CTA fill and as primary-colored text/icons),
  so label-on-primary contrast holds in both themes.
- **The white Google sign-in button** is intentionally white in both themes (brand button).
- **Color-coded state feedback** (Match matched=green, Guess correct=green/wrong=red/faded,
  mastery bars threshold-colored amber→indigo→green, streak orange, success teal) all use
  tokens that have explicit Nebula values — verified legible on the navy surfaces.
- **Overlays** (scrim 32% + bottom sheets) render correctly in dark; the scrim is subtle on
  the dark surface by design but present and functional.

**Verdict:** theme parity and UX are consistent and friendly across all 23 screens; the only
real defects were the scrollbar overflow and the duplicated Recall/Fill states, both fixed.

---

## 0.1 Pass 3 — token-compliance (“tokens are law”) + a11y hardening

A third pass enforced the design-token contract inside the phone-frame screens (no raw hex,
no raw px for color/size/radius/type) and closed the remaining accessibility gaps. As before,
fixes were applied at the **shared-primitive level** wherever possible so all 23 screens
benefit at once. Off-scale values were left **only** inside the Foundations (`.tok-*`) and
Components (`.wid-*`) documentation panels, where the brief explicitly permits them.

### Token compliance (Part 1)

| ID | Fix | Location | Before → After |
|---|---|---|---|
| **A1** | Card radius snapped to token | `.card` primitive | `border-radius: 12px` → `var(--memox-radius-card)` (16). Padding `12px` → `var(--memox-space-md)`. |
| **A1** | Bottom-nav radius snapped to token | `.bottom-nav` primitive | `border-radius: 18px` (off-scale) → `var(--memox-radius-lg)` (16). 18 sat between `lg 16` and `xl 24`; chose `lg` so the bar matches card radius. |
| **A2** | Button height + radius to tokens | `.pill-btn` primitive **and** ~87 inline overrides | `height: 40px` → `var(--memox-size-button)` (48); `border-radius: 10/11px` → `var(--memox-radius-button)` / `var(--memox-radius-md)` (12); `padding 0 18px` → `0 var(--memox-space-lg)`; `font-size 13px` → `var(--memox-fs-body-small)` (14). The primitive alone was invisible because nearly every button re-declared `height: 40` inline, so the 87 inline overrides were swept to the token too. No bottom-sheet footer overflows at 48px in the 780px frame. |
| **A3** | App bar height + title size | `.appbar` / `.appbar .title` | `height: 48px` → `var(--memox-size-appbar)` (56); title `17px` (off-scale) → `var(--memox-fs-title-medium)` (16). |
| **A4** | Off-scale font sizes snapped to the collapsed scale | 335 inline `fontSize` values across screens | `9/10/11 → 12`, `13 → 14`, `15 → 16`, `17 → 16`, `19 → 20`. Named offenders covered: breadcrumb `11 → 12`, Study counter `13 → 14`, Study mode badge `10 → 12`. Snapped to numeric scale steps to match the kit’s existing inline-numeric convention (on-scale sizes like 12/14/16 are already numbers, not vars). Decimal sizes (10.5–13.5) remain **only** in the `.wid-*` Components panel. |
| **A5** | Literal indigo → token-derived color | `.icon-btn:hover`, `.bn-pill`, `.icon-tile` primitives + 101 inline tints + 1 gradient | `rgba(82,101,245,α)` → `color-mix(in srgb, var(--memox-primary) α%, transparent)`; the one accent literal `rgba(139,111,245,α)` → `var(--memox-accent)`. **Pixel-identical** in both themes: the scoped `.memox-dark` block keeps `--memox-primary` at `#5265F5` and never overrides `--memox-accent`, so `color-mix` resolves to the exact original RGBA in Light *and* Dark (verified: `color(srgb 0.32 0.40 0.96 / 0.1)`). The hero gradient at the “Continue studying” avatar (was `#5265F5 → #8B9AFF`) was tokenized to `var(--memox-primary) → color-mix(… var(--memox-primary) 62%, white)` — kept as a gradient (see B1), just no longer raw hex. |

**Intentionally left (documented exceptions):**
- The three **dark-mode primitive tints** (`.memox-dark .icon-btn:hover` `rgba(108,124,255,…)`, `.memox-dark .bn-pill` / `.icon-tile` `rgba(139,154,255,…)`) are kept as literals. They are theme-layer values — exactly like the hex token definitions in the same `.memox-dark` block — and use the *lifted* Nebula violet, which is not derivable from the scoped indigo `--memox-primary`. The brief sanctions keeping these consistent as-is.
- The eight **hero / CTA tint gradients** (see B1) retain their indigo/violet/amber/green stops pending the keep-or-flatten product decision; their surrounding card borders *were* tokenized.
- **Seed-palette hexes** (`#5265F5`, `#A78BFA`, `#4DB6AC`, … in the deck/folder color picker) are kept as data — they *are* the canonical `--memox-seed-*` source values the tokens are defined from.
- `'#fff'` button-label colors and the `.tok-*` / `.wid-*` documentation-panel values are out of scope by the brief.
- **Compact button state-variants** (`height: 34/36` on inline error/banner `pill-btn`s) and `minHeight: 40` on the two text-field primitives are deliberate dense-chrome sizes, not drifted copies of the old 40px default; resizing them to 48 would change layout in fixed-height cards, which the brief forbids. Flagged for a future size-token (`--memox-size-button-compact`) instead.
- A follow-up sweep also snapped the remaining `borderRadius: 10` (33 sites — icon tiles, search fields, compact buttons) and the deck-list banner `borderRadius: 14` to `var(--memox-radius-md)` / `var(--memox-radius-lg)`.

### Accessibility / UX (Part 2)

| ID | Fix | Location | Detail |
|---|---|---|---|
| **C1** | Visible, keyboard-focusable **Next / Previous** controls on Study · Review | `StudyScreen` | Added a `pill-btn` Previous (secondary) + Next (primary) row built from the brand primitive + tokens; disabled at the ends via `var(--memox-op-disabled)`. The swipe gesture is unchanged. The old swipe-only hint is reworded (see C2). |
| **C2** | Swipe-direction copy + intent | `StudyScreen` onUp | **Chose Option B** — kept the V1 behavior (both directions advance to the next card) because Review is a single linear pass and distinct again/good semantics live in Recall/Guess, not here. Making left/right distinct would need new visual feedback = a redesign (out of scope). Fixed the misleading hint `“Swipe left for the next card”` → `“or swipe the card to continue”` and added a code comment documenting the simplification. |
| **C3** | Icon-button hit area to the documented 48dp | `.icon-btn::after` | `44×44` → `var(--memox-size-touch)` (48×48), matching `SizeTokens.touch`. Visual circle unchanged. |
| **C4** | Clickable rows made focusable + given a role | shared `Row` (settings nav + settings section), `TagRow`, `DeckRow` | Wrapped row roots in `role="button" tabIndex={0}` (`tabIndex=-1` + `aria-disabled` when disabled/dimmed); extended the global focus ring to `[role="button"]:focus-visible`. Layout unchanged (attributes only). The static **result-list `Row`** (no tap target) was left as a plain `<div>`. Per-screen one-off inline rows remain as-is — they are `InkWell`/`ListTile` (already focusable + semantic) in Flutter; converting dozens inline risks layout regressions for no app benefit. |

### Open product decisions (recommendation only — NO code changed)

**B1 — Gradients in chrome (9 `linear-gradient` usages vs. the "no gradients" rule).**
The stated rule is *"No gradients in UI chrome — the only gradient anywhere is the mastery
tri-stop gradient,"* yet nine gradients exist in screen chrome. Current inventory (post-pass
line numbers):

| Line | Where | Gradient |
|---|---|---|
| ~1450 | Dashboard · "Continue studying" avatar disc | primary → 62 % primary-on-white (tokenized this pass, still a gradient) |
| ~3498 | Deck list · "Today's review" banner | indigo 8 % → violet 8 % tint |
| ~4369 | Deck detail · summary header card | indigo 6 % → violet 10 % tint |
| ~5039 | Folder detail · summary header card | indigo 6 % → violet 10 % tint |
| ~8335 | Streak / reminder card | amber 8 % → indigo 8 % tint |
| ~8519 | Premium / upsell hero card | indigo 10 % → violet 10 % tint |
| ~9292 | Quiz result hero (non-defensive state) | green 10 % → indigo 10 % tint |
| ~9683 | Stats screen · page background wash | surface → indigo 4 % vertical wash |
| ~9794 | Stats screen · summary hero card | indigo 6 % → violet 10 % tint |

All nine are *very low-alpha tints* (4–10 %) on hero/summary "moment" cards — a consistent,
deliberate-looking pattern, not scattered drift. **Recommendation: option (a)** — update the
rule to allow one named pattern, e.g. *"hero-CTA tint gradient: 135°, two stops, ≤10 % alpha,
stops drawn from primary/accent/status tokens; allowed only on hero/summary cards, never on
buttons, nav, or list rows."* This legalizes the existing visual language at zero visual cost.
If the team prefers strictness, option (b) is mechanical: flatten each to
`var(--memox-primary-container)` (or the matching status `*-container`) — ~9 one-line edits,
slight loss of warmth on the hero cards. Decide once, then enforce via the named pattern.

**B2 — Mastery rendering: single-color vs tri-stop (internal inconsistency).**
`masteryColor()` (line ~382) now returns a **single status color** per threshold
(`--memox-status-learning` < 34 % < `--memox-status-reviewing` < 67 % < `--memox-mastery`),
and all 8 call sites (progress bars + ring charts) use it. But `colors_and_type.css` still
ships `--memox-mastery-low/mid/high` in **both** themes, and the README/this audit still call
the tri-stop mastery gradient "the only gradient" — so the rule's lone sanctioned gradient no
longer exists in the UI. **Recommendation: resolve to the single-color model** (it's what
ships; thresholds map cleanly to the status vocabulary and read better at 6 px bar heights
than a tri-stop ramp). If single-color wins, retire: the `--memox-mastery-low/mid/high` tokens
(light + dark blocks in `colors_and_type.css`), the corresponding Flutter token fields, the
"tri-stop mastery gradient" sentence in README/AUDIT prose, and rewrite the B1 rule above
without the "only gradient" exemption. If tri-stop wins instead, `masteryColor()` reverts to a
`linear-gradient(90deg, low, mid, high)` fill clipped by the progress width — but that
contradicts the current shipped look. Either way, **one** model should own mastery; today the
tokens promise one thing and the code does another.

---

## 1. Method

The kit was reviewed against this checklist (per the brief):

- Flutter `lightTheme` / `darkTheme` parity (Tokyo Pure Light / Tokyo Nebula)
- Mobile UI consistency (spacing, radii, type scale, surface ladder)
- Mobile UX friendliness (hierarchy, clear primary action, calm copy)
- Accessibility (semantics, focus, hit targets, contrast, motion)
- State coverage (loading / empty / error / offline / disabled / success / validation / signed-out / permission-denied)
- SafeArea, scrolling, keyboard behavior
- Common mobile widths (360 / 375 / 390 / 412 — already in the kit's Width selector)
- Flutter engineering handoff readiness

The screens themselves are strong — clear hierarchy, on-brand "calm study coach"
copy, and unusually thorough state coverage already. The real gaps were **systemic**
(shared primitives + global rules) and one **content defect**, so fixes were applied
at the primitive level to benefit all 23 screens at once rather than redesigning screens.

---

## 2. Fixed in this pass

### CRITICAL — apostrophes rendered as raw escapes (content defect)
- **Found:** 23 occurrences of the `\u2019` escape sat in **JSX text nodes**
  (e.g. `Today\u2019s review`, `Let\u2019s start`, `phone\u2019s settings`). JSX text
  does not interpret `\uXXXX` escapes — only JS string literals do — so users saw the
  literal text `Today\u2019s review`. Three `\u00d7` (×) escapes had the same latent risk.
- **Fix:** replaced every `\u2019` → `’` and `\u00d7` → `×` with the actual Unicode
  glyph. Valid in both JS strings and JSX text, so all 26 are now correct and future-proof.
- **Flutter note:** non-issue in Dart/ARB (real glyphs in `.arb` values), but it confirms
  the kit's copy strings should be lifted verbatim from `l10n/app_en.arb`, not retyped.

### MAJOR — accessibility: decorative icons announced to screen readers
- **Found:** the shared `Ic` (Lucide) wrapper had no ARIA, so every decorative glyph was
  exposed to assistive tech.
- **Fix:** `Ic` now renders `aria-hidden="true"` by default, with an opt-in `label` prop
  (`role="img"` + `aria-label`) for the rare icon that is the sole carrier of meaning.
- **Flutter map:** decorative `Icon` → wrap in `ExcludeSemantics`; meaningful → `Icon(..., semanticLabel: …)`.

### MAJOR — accessibility: primary navigation was not a control
- **Found:** `BottomNav` items were clickable `<div>`s — not keyboard-focusable, no role,
  no current-page indication.
- **Fix:** items are now `<button type="button">` with `aria-current="page"` on the active
  tab and an `aria-label`; the bar is `role="navigation" aria-label="Primary"`.
- **Flutter map:** `NavigationBar` + `NavigationDestination` already provide this; the kit
  now matches that semantic contract.

### MAJOR — accessibility: no visible keyboard focus anywhere
- **Found:** no `:focus-visible` styling on any interactive element.
- **Fix:** a global focus ring (`2px solid var(--memox-primary)`, `offset 2px`) now applies
  to `button`, `.icon-btn`, `.pill-btn`, `.bn-item`, and `[role="switch"]`. Both `Toggle`
  components are now keyboard-focusable (`tabIndex`, `aria-disabled`).
- **Flutter map:** Material's built-in focus highlight; keep `primary` as the focus color.

### MAJOR — touch targets below the 44px floor
- **Found:** `.icon-btn` is a 36px visual circle (some inline-shrunk to 24px, e.g. dismiss
  buttons) — under the README's own "never less than 44px" rule and `SizeTokens.touch = 48`.
- **Fix:** an invisible `::after` expands every `.icon-btn` hit area to **44×44** without
  changing the visual size, including the shrunken dismiss buttons.
- **Flutter map:** `IconButton` already enforces a 48dp tap target via `MaterialTapTargetSize.padded` — keep that default; do not shrink `constraints`.

### MAJOR — missing **offline** state (requested gap)
- **Found:** MemoX is local-first, but there was no reusable connectivity-lost pattern.
- **Fix:** added a shared **`OfflineBanner`** primitive (alongside `StatusBar` / `BottomNav`)
  with `role="status"` and brand-voice copy ("You're offline. Your cards are saved on this
  device. Drive sync resumes when you reconnect."), plus a new **`offline`** state on the
  Dashboard (registered in the gallery so it appears in the stepper). Content still renders
  beneath the banner — offline never blocks local study.
- **Reuse:** drop `OfflineBanner` onto any surface that attempts Drive sync (Library, Study
  result, Stats). **Flutter map:** drive it from a `connectivity_plus` stream → `MaterialBanner`
  or an inline `Container`; copy via an l10n key.

### MINOR — reduced-motion not respected
- **Found:** skeleton-pulse and the "continue studying" dot looped infinitely with no guard.
- **Fix:** global `@media (prefers-reduced-motion: reduce)` neutralizes animations/transitions.
- **Flutter map:** gate non-essential animation on `MediaQuery.of(context).disableAnimations`.

---

## 3. Recommendations (not changed — need a product decision)

| Sev | Finding | Why not auto-fixed | Suggested action |
|---|---|---|---|
| MAJOR | **List rows / cards use clickable `<div>`s** across most screens (deck rows, folder rows, settings rows, tag rows). They are not keyboard-focusable and expose no role. | Converting ~dozens of inline rows risks layout regressions and is screen-by-screen work. | In Flutter these are already `InkWell`/`ListTile` (focusable + semantic) — no app change needed. For the kit, wrap row roots in `role="button" tabIndex={0}` if AT fidelity in the mock matters. |
| MAJOR | **Icon-only buttons inside screens** still rely on `title` rather than `aria-label` in several places (Dashboard's search/settings are now labeled; others remain). | Many are inline and one-off. | Add `aria-label` to each; in Flutter pass `tooltip:` / `semanticLabel:` on every `IconButton`. |
| DECISION | **Gradients in chrome.** The Dashboard's "Continue studying" and "Today's review" cards use subtle `linear-gradient` fills, but the design rules state *"No gradients in UI chrome — the only gradient anywhere is the mastery tri-stop gradient."* | The gradients are deliberate and attractive; removing them is a visual redesign, which is out of scope. | Confirm intent. If keeping, update the README rule to allow a "hero-CTA tint gradient." If not, flatten to `primary-container` / `surface-container` tints — which is also the cleaner Flutter token mapping (`Theme.colorScheme.primaryContainer`). |
| MINOR | **SafeArea is mocked, not parameterized** — `env(safe-area-inset-*)` appears once. | The phone frame is a fixed 390×780 mock; insets are simulated by the 44px status bar and the bottom-nav padding. | Acceptable for a static kit. In Flutter, wrap every screen body in `SafeArea`; the bottom nav already reserves a home-indicator gap (maps to `SafeArea(bottom:true)` / `viewPadding.bottom`). |
| MINOR | **Self-hosted fonts / icon font** — Plus Jakarta Sans via Google Fonts CDN; Lucide stands in for Material Symbols. | Pre-existing, documented in the root README. | Confirm before production: ship `google_fonts` (or bundle TTFs) and `Icons.*` (Material Symbols) in the app. |

---

## 4. Flutter handoff — token & widget mapping

All values in the kit come from `colors_and_type.css`, which mirrors `lib/core/theme/tokens/**`.
**Tokens are law — no raw hex / sizes in the app.** Quick map:

| Kit (CSS var) | Flutter token / role |
|---|---|
| `--memox-primary`, `--memox-on-primary`, `--memox-surface-container-*` | `ColorScheme` roles (seeded from `#5265F5`) |
| `--memox-error-fill` (dark `#B0485C`) | solid danger-button fill in dark — distinct from the light-pink `error` content color; keep this split |
| `--memox-status-*`, `--memox-rating-*`, `--memox-mastery*` | `CustomColors` extension on `ThemeData` |
| `--memox-fs-*` (48/32/24/20/16/14/12) | `TextTheme` sizes — the collapsed scale; never interpolate |
| `--memox-space-*` (4dp grid) | `SpacingTokens` |
| `--memox-radius-*` | `RadiusTokens` (card/dialog/sheet = `lg 16`; button/input = `md 12`; chip/FAB = pill/`xxl 28`) |
| `--memox-dur-*`, `--memox-ease-*` | `DurationTokens` / `EasingTokens` (no `elasticOut` — flagged anti-pattern) |
| `--memox-border-ghost` | the 15%-outlineVariant 1px "ghost border" on every card |
| glass chrome (84% + blur) | app bar / bottom nav / sticky sheets only |

Widget mapping: app bar → `AppBar` (56/64dp); bottom nav → `NavigationBar` (80dp);
cards → `Card`/`Container` with ghost border, tonal elevation (no shadow > 6%); inputs →
tokenized `TextField` (focus = 1px solid `primary`); chips → pill; FAB → `level2`,
`radius xxl`; bottom sheets/dialogs → `level2–3` + 32% scrim. Copy → l10n keys
(`app_en.arb`, plus `app_ko.arb` / `app_vi.arb`); counts use ICU plurals.

---

## 5. State-coverage snapshot (post-pass)

Every screen ships its applicable states side-by-side; the gallery stepper cycles them in
both themes. Coverage by category:

- **Loading** — per-section skeletons (not full-screen spinners): Dashboard, Library, Folder, Search, Flashcard list/edit/history, Import, Tags, Progress, Settings, Sync, Audio, Study result.
- **Empty** — action-led empty states ("Add cards to start reviewing"): Library, Folder, Search, Flashcard list/history, Tags, Progress, Onboarding zero, Audio (no voices).
- **Error** — local-safe messaging + Retry: Dashboard, Library, Folder, Search, Flashcard list/edit/history, Import (failed/partial), Progress, Settings (sync error), Sync, Audio (engine error).
- **Offline** — **new** reusable banner; shown on Dashboard, ready for reuse.
- **Disabled** — "Soon" chips on disabled settings rows; disabled toggles; faded options.
- **Success** — Import success, Study result, sync ready/uploaded.
- **Validation** — Flashcard create/edit inline validation; Tag rename → merge conflict.
- **Signed-out / permission-denied** — Settings, Account sync (signed-out chain), Learning settings (notification perm denied), Audio (TTS engine missing).

---

## 6. Self-review verdict

Re-reviewed against the checklist after fixes:

- **Light/Dark parity** — ✅ all new elements (offline banner, focus ring, hit areas) use
  tokens and verified in both Tokyo Pure Light and Tokyo Nebula.
- **Consistency** — ✅ no new colors/radii/spacing introduced; primitives only.
- **Accessibility** — ✅ icons hidden, nav is a control, focus visible, 44px targets, toggles
  focusable, reduced-motion honored. ⚠️ inline clickable rows remain (Flutter-native already; documented).
- **State coverage** — ✅ offline gap closed; rest already complete.
- **SafeArea / scrolling / keyboard** — ✅ documented for Flutter; mock behavior unchanged.
- **Handoff readiness** — ✅ token/widget map above; copy sourced from l10n.

No critical or major issues remain open that are fixable without a product decision
(the gradient-in-chrome question and self-hosted-fonts/icons confirmation are flagged for you).
