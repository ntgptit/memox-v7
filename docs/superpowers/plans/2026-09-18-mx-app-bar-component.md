# Plan — `MxAppBar` shared component

Spec: the AppBar design-handoff prompt (MemoX v3 kit · A · Chrome & navigation),
delivered as this session's slash-command arguments. Checklist authority:
`.claude/skills/flutter-theme-design/references/chrome-navigation.md` §8
(`AppBarThemeData` / `MxAppBar`) — this task closes that row.

## Context (read once, do not re-derive per task)

- No `MxAppBar` widget exists today. `lib/shared/widgets/mx_content_shell.dart`
  builds a Flutter `AppBar` **inline** in `_buildAppBar` (mx_content_shell.dart:252-303),
  including a second contract this spec never mentions: `titleSubline` — a
  second line under the title, which grows the bar past a fixed height via
  `_toolbarHeight` (mx_content_shell.dart:335-349, dynamic, text-scale-aware).
  No screen calls `AppBar(...)` directly (`grep` confirmed zero hits under
  `lib/features`) — every screen goes through `MxContentShell.title/leading/actions`.
- The AppBar theme role binding is **already done** — `lib/core/theme/components/navigation/app_app_bar_theme.dart`
  already sets `backgroundColor: scheme.surface`, `foregroundColor: scheme.onSurface`,
  `iconTheme: onSurface`. This matches the spec's DIRECT roles (`surface`,
  `onSurface`, focus ring `primary`) exactly. **No theme gap. Do not touch
  `app_app_bar_theme.dart`'s colour bindings.**
- Typography: the GC-4 scale (`lib/core/theme/typography/app_typography.dart`)
  has no role matching the spec's `16/700/-0.3` (content title) or
  `24/700/-0.5` (screen title) — closest neighbours are `bodyLargeSize=16`
  (weight 500, tracking 0) and `headlineSize=24` (weight 700, tracking
  **-0.64**). Precedent for this mismatch already exists in the same file:
  `cardPromptSize/Height/Tracking` are named **component-level constants that
  intentionally sit outside GC-4** ("Component metrics, so GC-4's roles do not
  move them (R6)", app_typography.dart:117-122). Follow that precedent — do
  not bend GC-4's `titleLarge`/`headlineMedium` to fit the AppBar, and do not
  invent a general "restyle" path (`AppTypography.withWeight` exists for the
  weight axis only, not size/tracking).
- Icon glyphs: standard Material Symbols, chosen by meaning per the spec's
  Lucide→Material mapping instruction — `arrow-left`→`Icons.arrow_back`,
  `x`→`Icons.close`, `more-vertical`→`Icons.more_vert`, `search`→`Icons.search`,
  `plus`→`Icons.add`, `check`→`Icons.check`. All icon buttons must be
  `MxIconButton` (checklist item, chrome-navigation.md:27), never a bare
  `IconButton`.
- Selection mode (leading→✕, actions→Select all/Done) is an **established
  screen-level convention**, not a widget-level one: `trash_screen.dart:43-83`
  and `card_selection_bar_widget.dart:35-49` both swap `title`/`leading`/`actions`
  at the call site, explicitly documented as deliberate (not "a swapped app
  bar" — avoids overflow at 320dp/2.0x scale). **Ruling:** `MxAppBar` exposes
  `leading`/`title`/`actions` slots that a caller can swap for selection mode;
  it does not grow a `selectionMode` enum of its own. This matches the
  checklist's own hedge ("nếu thực sự cần" — only if genuinely needed) and
  costs nothing if a future screen needs more: the slots already compose.

## Global constraints (bind every task)

- `MxAppBar` is a **surface, not a control**: no `onPressed`/interaction state
  of its own, no background/radius/elevation parameters (checklist: "Không
  nhận background/radius/elevation"). It reads `surface`/`onSurface` from the
  ambient `Theme`, never a passed-in colour.
- Two densities via a required enum, not two widgets and not a bool:
  `MxAppBarDensity.compact` (0/8 padding, 16/700/-0.3 title) and
  `MxAppBarDensity.large` (0/16 padding, 24/700/-0.5 title). Height is fixed
  56 in both — `kToolbarHeight` already **is** 56 in Flutter's own SDK
  (`material/app_bar.dart`), so reuse that constant rather than inventing a
  new one; do not add a `sizeAppBar` token to `AppSizing` for a value the SDK
  already names.
- Title: exactly one line, `TextOverflow.ellipsis`, never wraps — for both
  densities (spec's long-content + responsive sections agree on this).
- Leading and actions never shrink or drop; only the title yields width
  (`Expanded` + `overflow: ellipsis`, no custom flex math needed).
- Trailing action gap: 4 between actions, 4 leading↔title↔actions — use
  `AppSpacing.xs` (`app_spacing.dart:11`, already named "4"); do not add a new
  bar-specific gap constant, per the ladder (rung 2: reuse what's here).
- `MxAppBar` implements `PreferredSizeWidget` (`preferredSize: Size.fromHeight(kToolbarHeight)`)
  so it drops into `Scaffold.appBar` and into `MxContentShell`'s existing
  `_buildAppBar` return type without changing that method's signature.
- **Do not touch `titleSubline`/`subheader` behaviour.** That is existing,
  spec-silent functionality (see Context). `MxContentShell` keeps its own
  inline `AppBar(...)` construction for the `subline != null` branch exactly
  as it is today; `MxAppBar` is wired in only for the common, no-subline case
  (the vast majority of screens: card/deck/trash/etc., which pass only
  `title`/`leading`/`actions`). This is a scope ruling, recorded here so the
  task doesn't silently expand into a subline redesign nobody asked for.
- No new dependency (ladder rung 5) — Material icons, existing `MxIconButton`,
  existing `AppSpacing`/`AppTypography` machinery are enough.
- Definition of Done per this repo's CLAUDE.md: `dart format`, `flutter
  analyze` (0 errors/warnings), tests green, Widgetbook entry added, checked
  light+dark+small screen+large text scale, WBS updated. Golden regeneration
  (`TZ=UTC flutter test --tags golden --update-goldens` + gallery rebuild) is
  needed **only if** any existing screen's rendered app bar changes pixels —
  which it will, wherever `MxContentShell` starts calling `MxAppBar` with the
  new 16/700/-0.3 title style instead of the current `titleLarge` (20/700/-0.64).
  That is an intended, in-scope visual change (the v3 pass), not a regression —
  regenerate goldens for the affected screens in the same task, do not defer.

## Task 1 — `MxAppBar` widget, `MxContentShell` wiring, Widgetbook, tests

**Files to touch:**
- New: `lib/shared/widgets/mx_app_bar.dart`
- Edit: `lib/shared/widgets/mx_content_shell.dart` (`_buildAppBar`: delegate to
  `MxAppBar` when `titleSubline == null`; keep the existing inline `AppBar(...)`
  build when a subline is present)
- Edit: `widgetbook/lib/components/structure_components.dart` (or the file
  that already groups `MxContentShell`/chrome widgets — check first) — add an
  `MxAppBar` use case with knobs for `density`, presence of `leading`, and
  action count
- New or extended test file: `test/shared/widgets/mx_app_bar_test.dart`
- Golden updates: run the golden suite after wiring, diff which
  `test/demo/` screens moved pixels, regenerate only those (see Global
  Constraints)

**Requirements:**

1. `MxAppBar` constructor: `required Widget? title`, `Widget? leading`,
   `List<Widget>? actions`, `MxAppBarDensity density = MxAppBarDensity.compact`.
   `title` takes a `Widget?` (not `String`) so a caller can still pass a
   pre-built `Text` — matches `MxContentShell.title`'s existing `String?` at
   the call site, which wraps it in `Text(title)` before handing it down (do
   not force every existing call site to change its API — `MxContentShell`
   does the wrapping, `MxAppBar` itself takes the widget).
2. Compact density: `EdgeInsets.symmetric(horizontal: AppSpacing.sm)` — the
   repo's 8 token, check `app_spacing.dart` for the exact name (likely `sm`);
   confirm before use, do not guess. Large density: `AppSpacing.lg`
   (confirmed 16 in `mx_content_shell.dart:190`/`mxScreenGutter`).
3. Title style: compact = a new `AppTypography.appBarContentTitleSize/Weight/Tracking`
   trio (16, `FontWeight.w700`, `-0.3`) built through the same `_role`-shaped
   helper the file already uses for `cardPrompt`; large =
   `AppTypography.appBarScreenTitleSize/…` (24, w700, -0.5). Both single
   `TextStyle`s, no `TextTheme` slot reuse (per Context: GC-4 roles don't fit).
   Wrap the passed `title` in `DefaultTextStyle.merge` with the resolved
   style + `maxLines: 1, overflow: TextOverflow.ellipsis` rather than
   requiring every caller to restyle its own `Text`.
4. Row layout: `Row` with `leading` (if present) → `SizedBox(width: AppSpacing.xs)`
   → `Expanded(child: title ?? SizedBox.shrink())` → if `actions` present,
   `SizedBox(width: AppSpacing.xs)` + the actions row (each pair separated by
   `AppSpacing.xs`, built with `Wrap`/`Row`+`SizedBox`, your call — no library
   needed). No actions → title keeps full remaining width (spec's "no
   actions" state) — this falls out for free from `Expanded`, don't special-case it.
5. `preferredSize = Size.fromHeight(kToolbarHeight)` (Flutter's own 56).
   No shadow, no elevation, no `Material` wrapper beyond what `AppBar`-shaped
   `PreferredSizeWidget` needs — background comes from the ambient
   `Scaffold`/`ColorScheme.surface`, which `app_app_bar_theme.dart` already
   sets globally; `MxAppBar` itself should paint nothing but a `SizedBox` +
   `Row`, no `Container` with its own colour (checklist: "Không nhận
   background").
6. `MxContentShell._buildAppBar`: when `widget.titleSubline == null`, return
   an `MxAppBar` built from `widget.title == null ? null : Text(widget.title!)`,
   `widget.leading`, `widget.actions`, and `density: MxAppBarDensity.compact`
   (every current call site is a compact/content-title bar — `large` has no
   call site yet, which matches the spec's own "NOT PART OF CURRENT V3
   CONTRACT" note about `ScreenHeader` having none either; build `large` as a
   complete, tested variant but do not invent a screen to consume it).
   Preserve every existing behavior around it verbatim: `automaticallyImplyLeading`
   logic, the scroll-derived hairline (`shape:`), `hasBackAffordance` check —
   none of that moves into `MxAppBar`, all of it stays exactly where it is in
   `_buildAppBar`, just now wrapping an `MxAppBar` as the `title:`/`leading:`/`actions:`
   payload of the `AppBar(...)` it already returns, OR (implementer's call,
   record which): replace the returned `AppBar(...)` outright with a
   `Scaffold.appBar: MxAppBar(...)` when there's no subline, keeping the
   hairline/back-affordance logic in `_buildAppBar` either way. Either shape
   is acceptable as long as the hairline, back-affordance and
   `automaticallyImplyLeading` behavior is provably unchanged (covered by
   existing `mx_content_shell` tests — run them, they must still pass
   unmodified).
7. Widgetbook: one new file or an addition to the existing chrome/structure
   file, following `control_components.dart`'s pattern — `@UseCase` per
   interesting configuration (`compact, with back + actions`,
   `large, screen title only`, `no actions`), knobs for `density` via
   `context.knobs.object.dropdown<MxAppBarDensity>`.
8. Tests: constructor renders leading/title/actions in the right slots; title
   ellipsises under a narrow width (golden or `tester.getSize` assertion);
   compact vs large padding/typography differ per the dimension table; no
   actions → title takes full width; `preferredSize.height == 56`.
9. Run `TZ=UTC flutter test --tags golden --update-goldens`, diff which PNGs
   under `test/demo/` moved, and only those — regenerate them, then rebuild
   and republish the screen gallery per CLAUDE.md's existing rule and its
   pinned Artifact URL. If regeneration needs Linux (per the repo's golden
   platform rule), use the WSL runbook referenced in this repo's tooling —
   do not author goldens on Windows.
10. Update `docs/wbs.md` — this closes the `MxAppBar` row noted as pending in
    `.claude/skills/flutter-theme-design/references/chrome-navigation.md`.

**Out of scope for this task (say so, don't build it):** `titleSubline`
redesign, `MxSessionTopBar` convergence, any `selectionMode` enum on the
widget itself, a `sizeAppBar` token, `dio`/network work, auth.
