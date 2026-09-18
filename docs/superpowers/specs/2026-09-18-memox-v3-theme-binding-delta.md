# Delta matrix — old branch (`claude/flutter-theme-implementation-5f3f2a` @ 11079dc4) against `origin/main` @ e4db53c6 (#569)

Baseline rule: **#569 wins for every Foundation value already implemented.** Theme Binding owns
classification, routing and runtime ownership. Nothing below is ported before this table exists.

## A · ALREADY_IN_MAIN — #569 did it; do not re-do, do not revert

| # | What | Evidence on main |
|---|---|---|
| A1 | The 45 `ColorScheme` role values, light + dark, from the same v3 source | `app_colors.dart:56` `primaryLight #5265F5`, `:35` `textPrimaryLight #0F1638`, `:71` `dangerLight #DC2D4E` … |
| A2 | The twelve `*Fixed` roles as independent literals | `app_material_roles.dart` |
| A3 | `inverseSurface` / `onInverseSurface` = `#34395D` / `#E8EAFC` in both themes | `app_material_roles.dart:65-72` (pair kept, equal values) |
| A4 | Accessibility **text inks** (`accentInk`, `dangerInk`, `successInk`, `warningInk`, `secondaryInk`, `tertiaryInk`, `inversePrimaryInk`) threaded through `AppSemanticColors` and `AppInk.resolve` | `app_colors.dart:83-84`, `app_semantic_colors.dart:140-146`, `app_ink.dart` |
| A5 | One family `PlusJakartaSans`; the seven-role type scale across the `TextTheme`; Inter removed (app + widgetbook) | `app_typography.dart:38`, `:222-291` |
| A6 | Legacy semantics re-pointed to derive **from** the role constants (`surfaceMuted`, `surfaceSelected`, `surfaceElevated`, `paper`, `borderSelected`, `borderOption`, `progressTrack`, `progressFill`) | #569 commit body |
| A7 | One pressed value (0.12) and one hover value (0.08) across every shape | `app_interaction_states.dart:21-70` (`pressed`, `pressedCard`, `stateLayerPressed` all 0.12) |
| A8 | Three of the four v3 shadow treatments — soft `0 1px 2px @.04` / none, card `0 12px 32px @.10` / `0 16px 40px @.42`, floating `0 8px 24px @.12` / `0 10px 28px @.5` | `app_elevation.dart` private `_Shadow` enum |
| A9 | Spacing / radius / icon ladders, screen gutter, scroll tail, foundations tests, contrast gates, **goldens** | #569 (431 files) |

Superseded on the old branch, therefore dropped: Task 1 (palette) and Task 5 (typography) in full,
including the old branch's contrast strategy (verbatim hex + three re-pinned floors 2.92 / 2.65 / 2.25).
#569 answered the same question with text inks; that answer stands.

## B · THEME_BINDING_MISSING_FROM_MAIN — this PR implements exactly these

| # | What | Why it is Theme Binding's |
|---|---|---|
| B1 | The seven BIND_NOW `MEMOX_SEMANTIC_COLOR` fields — `mastery`, `status-new`, `status-learning`, `status-reviewing`, `status-mastered`, `error-fill`, `on-error-fill` — with their literals in their own token file | Absent from main (grep: no hit in `lib/core/theme`). Registry §5.1, runtime `BIND_NOW` |
| B2 | Central `DERIVED_COLOR` derivations, once each: `danger-soft`, `surface-hero`, `chrome-glass` | Absent. Registry §5.3 — "implement each derivation once, centrally" |
| B3 | `EFFECT_TOKEN`s: `op-glass` 0.84 and the glass blur sigma, outside the state layer | Absent. Registry §5.6 |
| B4 | `DECORATION` treatments exposed **by semantic name**, including the two main has no value for at all: `shadow-chrome` (`0 -2px 12px @.05` / `0 -2px 14px @.36`) and `border-ghost` (`primary` @ 14% / 16%, 1dp) | Registry §5.4. The three A8 values become the named treatments they already are; `shadowsFor`'s level mapping is **not** touched (owner rule 8) |
| B5 | Global state policy gaps: the whole-control `op-disabled` token (main has only `disabledContent`, an ink alpha) and the focus-ring offset (2) | Registry §5.5, §8. Pressed and hover are already A7 |
| B6 | `M3_ALIAS` routing established and validated with **no new field**: `bg`→`surface`, `surface-muted`→`surfaceContainerLow`, `surface-raised`→`surfaceContainerLowest`, `progress-track`→`surfaceContainerHigh`, `text-secondary`→`onSurfaceVariant` | Registry §5.2 |
| B7 | The prerequisite validation test (routing by kind, dispositions, every DIRECT consumer role resolvable in both themes), `docs/design-system/theme-architecture.md`, and the WBS entry (**M100.98** — #569 took M100.97) | Spec §9 step 13, §14 |
| B8 | The modal barrier: the one central recipe becomes `scheme.scrim` @ **0.45 in both themes** (main: 0.48 light / 0.72 dark). Dialog, BottomSheet and the shared scrim all consume that one recipe; no component hard-codes 0.45; no new semantic colour — `scrim` stays the role and 0.45 is the treatment. The old test/comment demanding 0.48 / 0.72 is updated, and modal-overlay goldens are regenerated for this alone | **Owner ruling 2026-09-18:** confirmed in scope — a shared overlay treatment with one authored V3 value, not Dialog or BottomSheet variant behaviour |

## C · CONFLICT_WITH_569 — reported, not overwritten

| # | Conflict | Disposition |
|---|---|---|
| C1a | `AppSemanticColors.progressTrack` — a legacy field whose value #569 re-pointed at `surfaceContainerHigh` (`app_colors.dart:143-146`, both themes) | **Owner ruling 2026-09-18:** keep the field as a *compatibility alias*, not a second source of truth. Canonical routing stays `progress-track` → `ColorScheme.surfaceContainerHigh`; the validation test asserts the legacy field equals that role in both themes; the field goes on the retirement-debt list; no call site moves in this PR |
| C1b | `AppSemanticColors.surfaceMuted` — **a name collision, not an alias.** On main it resolves `AppSurfaceColors.surfaceMuted` → `surfaceContainer` (`#E9EDF7`), where V3's `surface-muted` is `surfaceContainerLow` (`#F1F4FB`). Different value, different meaning | **Owner ruling 2026-09-18:** do not reinterpret it, do not change its backing value, do not assert it equals `surfaceContainerLow`. V3's `surface-muted` resolves straight to `ColorScheme.surfaceContainerLow` with no field of its own. The legacy field stays as the old code's compatibility semantic; the slots V3 actually defines as `surface-muted` migrate in their own component task. The collision is documented so nobody reads one as the other |

**General rule the owner set:** `M3_ALIAS` means *do not introduce a new runtime field for V3*. It does
not oblige this prerequisite to delete a pre-existing legacy field — least of all one whose semantics
differ — and no feature or component call site is touched merely to make the alias table look clean.
| C2 | Contrast strategy: old branch shipped verbatim hex and re-pinned three floors; #569 added text inks so text clears 4.5:1 | #569 wins. Floors not ported |
| C3 | Dark card rim colour: registry says Card's dark edge is `border-ghost`; main draws `outlineVariant` | Card's component contract decides. Deferred, recorded in D3 |

## D · NO_LONGER_NEEDED_IN_THIS_PR / DEFER_TO_IMPLEMENT_COMPONENT

Knowledge preserved as component · slot · target semantic role, for the component tasks.

| # | Change on the old branch | Disposition |
|---|---|---|
| D1 | Task 1 palette values; collapsing the invariant `inverse*` pair into single constants | NO_LONGER_NEEDED (A1, A3). The invariant is asserted by the B7 test instead of restructured |
| D2 | Task 5 typography (family, 15-rung mapping, `stat`, compact-scale no-op, `heroNumeral` weight) | NO_LONGER_NEEDED (A5) |
| D3 | The paper/recess rung swap, 10 sites | DEFER_TO_IMPLEMENT_COMPONENT — `MxCard._MxCardFill.surface` → `surface-raised`/`surfaceContainerLowest`; `MxCard._MxCardFill.recessed` → `surface-muted`/`surfaceContainerLow`; `CardTheme.color` → `surface-raised`; `ChoiceChip` resting fill → `surfaceContainerLowest`; `BottomSheetThemeData.backgroundColor` → `surfaceContainerHigh`; `ThemeData.canvasColor` (menu) → `surface-raised`; guess-option and match-tile grounds → `surface-raised`; the two disabled blends' ground → `surface-raised` |
| D4 | Rebinding `shadowsFor`'s levels onto the V3 Card treatment (card+raised → whisper/rim, overlay → overlay-shadow) | DEFER — owner rule 8: the component contract picks the treatment |
| D5 | Component-theme colour defaults (Tasks 6–7): progress `linearTrackColor` → `surfaceContainerHigh`; BottomSheet container → `surfaceContainerHigh` and grabber → `outlineVariant`; NavigationBar background → `chrome-glass`, indicator → `primary` @14/20%, selected icon+label → `primary`; FAB → `primary`/`onPrimary`; FilterChip selected → `primary`/`onPrimary`, unselected label → `onSurface`, border → `border-ghost`; Switch thumb → `surfaceBright`; OutlinedButton side → `outlineVariant`; IconButton glyph → `onSurface`; TextField filled `surface-muted` → focused `surface-raised`, borders `border-ghost`/`primary`/`error` at hairline | DEFER_TO_IMPLEMENT_COMPONENT — each is one component's `themeRoleUsage`, not a global default |
| D6 | `AppGuessOption.naturalHeightOf` under-reserving the verdict glyph's 24dp (8 gap + 16 icon) | NO_LONGER_NEEDED here (main's type differs, the test passes). Real latent defect — recorded for the study screen's task |
| D7 | The old branch's test re-pins that only existed because Task 1/5 moved values (ladder rungs, weight registry, geometry figures, the toggle disabled band, the tooltip identity) | NO_LONGER_NEEDED — main's own tests already cover the values #569 shipped |
