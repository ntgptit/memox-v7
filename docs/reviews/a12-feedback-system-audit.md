# A12 — feedback / status system deep audit

| | |
|---|---|
| **Status** | report only — no code, test, theme, Widgetbook or golden was changed |
| **Purpose** | Establish a taxonomy for every "the app is telling the user something is happening" surface — progress, loading, empty, completion, error, warning, info, success, transient feedback, tooltip/help — and audit theme, shared widgets and every production caller against it |
| **Scope** | `ProgressIndicatorThemeData` / `SnackBarThemeData` / `TooltipThemeData` (`lib/core/theme/components/feedback/`) · `MxProgressBar` · `MxLoadingState` · `MxAsyncView` · `MxEmptyState` · `MxErrorState` · `MxFeedbackBand` (`lib/shared/widgets/`) · every production caller of `LinearProgressIndicator`/`CircularProgressIndicator`, `SnackBar`/`ScaffoldMessenger`, `Tooltip`, and every hand-built status/feedback surface under `lib/features/` |
| **Audited against** | `main` @ **`3207e7b7e0d3a2ecefa5e6a85fed48a65890ba6b`** (BASE_SHA) · Flutter **3.44.8** (pinned in `.fvmrc`), Dart `^3.12.2` |
| **Not in scope** | Token *values*/contrast measurement methodology (AD-14 owns that) · `MxActionButton`'s own in-button spinner (covered by `docs/reviews/mx-action-button-deep-audit.md`) · `MxDialogTone`/confirm-dialog tone family · network-error copy (AD-05: no network yet) |
| **Last updated** | 2026-09-03 |

**Method note.** This pass is static reading, not a rendered/device audit: no
golden was regenerated, no emulator was run, no SDK contrast figure was
recomputed. Where a claim depends on Flutter's own runtime behaviour that this
environment has no SDK checkout to cite line numbers from (§7.3), it is marked
**unverified — recommend confirming** rather than asserted as fact, per "Flutter
3.44.8 canonical semantics first." Every other claim is a direct read of the
file and line cited.

---

## 1. Executive verdict

**No P0.** Nothing in this scope crashes, silently drops user data, or breaks
an existing contrast floor that a real screen reaches today.

The theme layer and four of the six shared widgets (`MxProgressBar`,
`MxLoadingState`, `MxAsyncView`, `MxErrorState`) are in good shape: each has a
recorded rationale for its geometry, its semantics and its animation policy,
each is covered by a golden and/or a Widgetbook case, and production callers
mostly reuse them correctly. The `Tooltip` family is clean outright — see §6.

The two real defects are both **taxonomy boundary violations that the
codebase's own widget docstrings already name as the anti-pattern to avoid**,
and both are already in production:

1. **Empty is being used to render Error.** `MxEmptyState`'s own doc says it is
   "deliberately distinct from `MxErrorState`" because painting a failure in
   good-news styling "tells the user something is broken when nothing is"
   (BR-29). Two production call sites do exactly the reverse — render a real
   `AsyncValue.error` through `MxEmptyState` — which is the same mistake
   pointed the other way: a real failure dressed as "nothing to see here,"
   with the brand-accent icon colour instead of danger red, and in one case no
   retry action at all. See §4.3.
2. **The Feedback-band family has one tone, and a warning-class caller has
   already landed.** `MxCardFeedbackTone` only defines `danger`, on the
   documented basis that "success/warning/info containers have no token yet."
   That comment is now stale: `AppSemanticColors` has shipped
   `warningContainer`/`onWarningContainer` since M100.21. Meanwhile
   `ReminderBannerSectionWidget` — a denied OS permission, a recoverable
   condition — is painted in the same red as a genuine write failure. See §4.6.

Three P2s round out the register: a raw, unlabelled loading spinner (§4.2), a
`.when()` bypass of `MxAsyncView`'s centralised loading policy with no
recorded reason (§4.4), and an inconsistent snackbar-action duration policy
(§5.2). None of the P2s breaks a rule outright; each is a place where the
system's own stated principle (one shared loading treatment, one clock for
"can the user react in time") was not carried through.

**Recommended next pass: §8, four steps, none needs a new abstraction beyond
one enum value.**

---

## 2. Taxonomy

Ten families, established from what the codebase actually distinguishes today
— not from a wish list:

| Family | What it means | Component today | Tone/colour |
|---|---|---|---|
| **Determinate progress** | A quantity moving toward a known total | `MxProgressBar` (linear), `MxSessionTopBar` (wraps it), one raw `CircularProgressIndicator` ring (`_ProgressRing`, card mastery) | `progressFill` → `success` at 100% |
| **Indeterminate loading** | Work is happening, duration unknown | `MxLoadingState` (full-region), `MxAsyncView` (policy wrapper around it), several raw inline spinners | `scheme.primary` (theme) |
| **Empty** | Nothing to show, and that is correct | `MxEmptyState` | `AppInk.accent` (brand, not danger) |
| **Completion** | A quantity reached its target | `MxProgressBar` at `value >= 1` (fill turns `success`) | `success` |
| **Error** | Something failed; may be retryable | `MxErrorState` (full-region), `MxFeedbackBand` (in-flow) | `danger` / `onErrorContainer` |
| **Warning** | A recoverable, non-failure condition needing attention | *(no dedicated component — see §4.6)* | token exists (`warningContainer`), unused by any feedback widget |
| **Info** | Neutral, non-actionable context | *(no dedicated component)* | token exists (`infoContainer`), unused |
| **Success (banner-level)** | A completed action, stated once | *(no banner; only the progress-bar completion cue)* | `successContainer` token exists, unused as a banner |
| **Transient feedback** | A message that appears and dismisses on its own, optionally reversible | `showMxMessage`/`showMxMessageOn` (`MxMessenger`), `showMxUndoSnackBar` | `SnackBarThemeData` (`inverseSurface`/`onInverseSurface`) |
| **Tooltip/help** | A name for an already-visible control, on long-press/hover | `tooltip:` param on `MxIconButton`/`MxFab`/`MxMenuButton`/`MxSearchField` | `TooltipThemeData` (`inverseSurface`) |

**The taxonomy gap is structural, not cosmetic.** Three of the ten families
(warning, info, success-as-banner) have colour tokens (`AppSemanticColors`)
but no widget-level tone to spend them through. §4.6 documents the one place
this has already produced a wrong-looking screen.

---

## 3. Theme layer

### 3.1 `ProgressIndicatorThemeData` (`app_progress_theme.dart:13-21`)

- `color: scheme.primary`, `circularTrackColor: Colors.transparent`,
  `linearTrackColor: scheme.secondaryContainer`.
- The doc (lines 3-12) records a real, measured defect and its fix: dark
  `primary` scored 2.81:1 against its own surface (below the 3.0 floor for a
  graphic) until M100.18 inverted the tone to 10.01:1. This is exactly the
  kind of decision this audit looks for evidence of, and it is present and
  dated.
- **Verdict: correct, and it is the one slot every un-tinted `CircularProgressIndicator` in the app reads from** — which is what makes §4.2/§4.4's raw indicators *inherit* this fix automatically, and also what made `MxLoadingState`'s doc (line 33-39) call out the one screen (a full-screen loading face) that used to override it and silently opt back into the broken contrast. No open finding here.

### 3.2 `SnackBarThemeData` (`app_snackbar_theme.dart:7-27`)

- `backgroundColor: scheme.inverseSurface`, text on `scheme.onInverseSurface`,
  `behavior: floating`, `actionTextColor: scheme.inversePrimary`,
  `shape`: `AppRadius.md` rounded rect, `elevation: AppElevation.overlay`.
- **Canonical inverse-role pairing.** `inverseSurface`/`onInverseSurface` and
  `inversePrimary` are exactly the M3 roles engineered for this — a floating
  surface that inverts with the active brightness so it reads as "the other
  mode's card" in both themes. No escape hatch, no hand-picked colour.
- `elevation: AppElevation.overlay` is stated explicitly rather than left to
  the SDK default (6.0) — the same overlay depth `Dialog`/`BottomSheet`/
  `PopupMenu`/FAB use, so a snackbar does not float at a different depth than
  every other floating surface in the same theme pass (M100.35).
- **Verdict: correct.** Duration and dismiss-queue policy are not part of
  `SnackBarThemeData` (SDK has no such slot) — that policy lives in
  `MxMessenger`/`MxUndoSnackBar`, audited in §5.

### 3.3 `TooltipThemeData` (`app_tooltip_theme.dart:30-42`)

- `decoration`: `inverseSurface` fill, `AppRadius.sm` corner. `textStyle`:
  `labelMedium` on `onInverseSurface`. `padding`: `md`×`sm`.
  `waitDuration: kTooltipWaitDuration` = 500ms, Material's own default, kept
  deliberately (doc lines 20-21: shortening it "makes a tooltip fire while a
  finger is still travelling across a toolbar of icon buttons" — a mobile-
  specific reason, correctly prioritised per this audit's rule "mobile/
  accessibility before decorative similarity").
- Same inverse-role pairing as the snackbar; consistent visual family for
  every ephemeral inverse surface in the app.
- **Verdict: correct.** See §6 for why the *usage* of this theme is also clean.

---

## 4. Shared widgets

### 4.1 `MxProgressBar` (`mx_progress_bar.dart`)

- Two sizes (`sm`=4, `md`=8, lines 16-27), two shapes (`pill`/`flush`, lines
  47-56) — each justified by a specific call site, not a free API.
- **Semantic role is separated from decorative accent by construction**: the
  fill is `semanticColors.progressFill` (a dedicated lighter indigo tint),
  never `scheme.primary` — the doc (lines 32-36) states the reason directly:
  a bar filled with the same hue as a button beside it would be
  indistinguishable from a call-to-action. This directly answers taxonomy
  item 2 ("study/deck progress vs decorative accent") — the two are
  structurally different tokens, not a convention a caller could accidentally
  violate.
- **Completion cue**: fill and value label both switch to `success` at
  `value >= 1` (lines 88-90, 183-187) — BR-88's "learned" state, the one
  place in this family the interface "congratulates."
- **Value handling**: `value.clamp(0.0, 1.0)` (line 87) rather than an
  assertion — the doc (lines 43-46) names the real caller that needs this
  (`DeckSummary.learnedFraction` on a zero-card deck), so a rendering bug
  never reaches a user in place of a caught precondition.
- **Motion**: animates via `TweenAnimationBuilder` at `AppDurations.slow`,
  collapsed to zero under `AppMotionPolicy` reduced-motion (lines 115-129) —
  final value, colour and announced label are unchanged either way.
- **Accessibility**: outer `Semantics(label, value)` wraps an
  `ExcludeSemantics`-wrapped visual (lines 92-95), so the announced text is
  exactly the caller's already-localized label/value pair, never a a raw
  fraction.
- **Production usage audited** (`grep MxProgressBar\(`, 2 call sites):
  - `deck_level_summary_widget.dart:180-190` — passes `label`/`valueLabel`
    directly; the widget's own header renders the visible caption.
  - `deck_tile_widget.dart:223-244` — passes neither; the caller wraps a bare
    bar + a separately-visible percent `Text` in one outer
    `Semantics(label, value)` + `ExcludeSemantics`, to avoid a screen reader
    hearing the percentage twice (once from the bar, once from the visible
    figure). Deliberate, correctly composed, not a defect.
  - `mx_session_top_bar.dart:202-204` wraps a **bare** `MxProgressBar` (no
    label/valueLabel) inside `MxSessionTopBar` — correct, because the
    `trailing` figure beside it already carries the one announcement
    (doc lines 197-201: "It announces nothing either — `trailing` carries the
    one announcement").
- **Verdict: no finding.** Every production usage is deliberate and
  internally consistent; the two integration styles (bare vs. labelled) are
  each justified by their layout, not by inconsistency.

#### 4.1.1 The one bespoke exception, verified correct: `ProgressWeekBarWidget`

`lib/features/progress/presentation/widgets/items/progress_week_bar_widget.dart`
hand-builds its bar rather than reusing `MxProgressBar`, and says exactly why
(lines 76-84): the shared component turns its fill `success` at 100%, which
is correct for "this deck is learned" and wrong for "this was the busiest day
of the week" — some day in every studied week is the week's maximum, and
painting one bar green per week would invent a "done" state that does not
exist for a bar chart. `trackHeight` is borrowed from
`MxProgressBarSize.sm.trackHeight` rather than re-typed (line 39), so the two
cannot silently drift. `ExcludeSemantics` at the root (line 45) because the
row's own label+figure already carry the value (doc lines 14-17). **Verdict:
a correct, reasoned escape hatch, not an audit finding** — flagged here only
so the escape hatch is on record as reviewed rather than missed.

### 4.2 `MxLoadingState` (`mx_loading_state.dart`)

- Full-region spinner, `Center` + `Padding(all: xl)`.
- **Two measured, documented decisions**: a `RepaintBoundary` around the
  indicator (lines 20-29) because an un-boundaried spinner was measured to
  force a sibling `CustomPaint` to repaint on every animation frame (10 extra
  paints over 10 frames) — a real perf regression this widget exists to
  close. And **no `color:` override** (lines 31-39), because a previous
  version passed `context.colors.primary` and silently defeated
  `buildProgressIndicatorTheme`'s own fix for dark `primary`'s 2.81:1 failure
  (§3.1) on the one screen whose entire job is to be a spinner.
- `semanticsLabel` is `required` — a bare spinner "announces nothing at all"
  (lines 5-7).
- **Finding: this contract is not universally followed by raw
  `CircularProgressIndicator()` call sites — see §4.4 and the P1/P2 register
  (§7).**

### 4.3 `MxAsyncView` (`mx_async_view.dart`)

- Centralises one policy every `.when()` call site should otherwise restate:
  `skipLoadingOnRefresh: true` always, `skipLoadingOnReload` opt-in per
  screen (doc lines 72-97, with the two real screens — Progress, Study Home —
  that need it and why). Initial load always shows `MxLoadingState`
  regardless of the flag (lines 16-18), so a screen never mistakes stale data
  for fresh.
- `error` is a required builder, deliberately with **no default copy** — "a
  generic 'something went wrong' is how every screen ends up with the same
  unhelpful sentence" (lines 24-26). This is the correct place to enforce
  "preserve empty ≠ error": the type signature forces every caller to hand
  back *some* widget for the error branch, but it cannot force that widget to
  be `MxErrorState` rather than `MxEmptyState` — which is exactly the gap
  §4.3 below walks through.
- 18 production files correctly route through `MxAsyncView`
  (`grep -l MxAsyncView lib/features`); 4 files call raw `.when()` instead
  (`grep -l '\.when\(' lib/features`, minus `MxAsyncView`'s own internals).
  Two of those four are justified with an inline comment (see §4.4); two are
  not.

#### 4.3.1 Finding: `MxAsyncView`'s `error` builder is used correctly everywhere it is used

Spot-checked every `MxAsyncView(..., error: ...)` call across `deck_list_screen.dart`, `starter_library_screen.dart`, `move_deck_sheet_widget.dart`, `progress_screen.dart`, `progress_deck_screen.dart` — each maps its `error` branch to `MxErrorState`/`DeckLevelErrorWidget`/`MxFeedbackBand`, never `MxEmptyState`. **The defect below is confined to the two files that bypass `MxAsyncView` entirely.**

#### 4.3.2 Finding (P1): a real `AsyncValue.error` rendered as `MxEmptyState`, twice

`MxEmptyState`'s own contract (`mx_empty_state.dart:10-14`):

> "Shown when there is nothing to display and that is fine. Deliberately
> distinct from `MxErrorState`: 'you have finished everything due today' is
> good news, and rendering it in error styling tells the user something is
> broken when nothing is (BR-29)."

Two production call sites do the mirror-image wrong thing — render a genuine
failure through the "good news" component:

- **`card_bulk_overlays_widget.dart:100-106`** (`_MoveTargetSheet`, the
  card-move target picker, UC-04 A5):
  ```dart
  error: (error, _) => MxEmptyState(
    icon: Icons.error_outline,
    title: context.l10n.unexpectedErrorTitle,
    message: error is Failure
        ? context.l10n.cardMoveEmptyMessage
        : context.l10n.cardMoveEmptyMessage,
  ),
  ```
  Both branches of the `error is Failure` ternary resolve to the same string
  (`cardMoveEmptyMessage` — literally the *empty*-state copy), and **no
  `actionLabel`/`onAction` is supplied**, so the user gets no way to retry a
  real read failure short of dismissing the sheet and reopening it.
  `MxEmptyState`'s icon `ink` is hardcoded to `AppInk.accent` (brand indigo,
  `mx_empty_state.dart:70`) regardless of which `icon:` glyph the caller
  passes — so this renders an "error" glyph in the brand's own colour, not
  danger red.

- **`card_editor_screen.dart:194-195, 201-203, 209-217`** (`_buildEdit` /
  `_recoveryFace`):
  ```dart
  Widget _recoveryFace(BuildContext context, String title) => _shell(
    context,
    body: MxEmptyState(
      icon: Icons.error_outline,
      title: title,
      actionLabel: context.l10n.cardEditorLoadRetry,
      onAction: _pop,
    ),
  );
  ```
  used for both `loaded.when(error: ...)` (a real read failure) and a
  deck/card context-mismatch guard. This one does supply an action, but it is
  still the wrong component: `MxErrorState` exists specifically to pair a
  danger-toned icon with a retry action for exactly this state, and this
  screen re-derives an inferior version of it (no danger ink, no
  `isRetrying` support if the "retry" ever needs to be an async re-read
  rather than a pop).

**Callers.** `_MoveTargetSheet` is reached from `showCardMoveTargetSheet`
(`card_bulk_overlays_widget.dart:62-69`), itself called from the card list's
bulk-move action (UC-04 A5). `CardEditorScreen._buildEdit` is reached
whenever `CardEditorScreen(cardId: ...)` is pushed with a non-null `cardId`
(every "edit existing card" entry point).

**Contract violated.** `mx_empty_state.dart:10-14` (BR-29); this audit's
taxonomy item 4 ("preserve empty ≠ error").

**Recommendation.**
1. `card_bulk_overlays_widget.dart:100-106` → `MxErrorState(title: ..., message: context.l10n.cardMoveErrorMessage, retryLabel: context.l10n.retryAction, onRetry: () => ref.invalidate(cardMoveTargetsProvider(sourceDeckId)))`. This needs a new, honest error-specific ARB string (`cardMoveErrorMessage` or similar) distinct from `cardMoveEmptyMessage`, since today the two states share one sentence.
2. `card_editor_screen.dart`'s `_recoveryFace` → `MxErrorState(title:, message:, retryLabel: context.l10n.cardEditorLoadRetry, onRetry: _pop)` (keeping the existing "pop back" recovery action, only the component and ink change).

**Closure test.** A widget test per site that forces the underlying provider
into `AsyncValue.error(...)`, pumps the widget, and asserts
`find.byType(MxErrorState)` is present and `find.byType(MxEmptyState)` is
absent. Extend `test/shared/widgets/mx_components_test.dart`'s existing
empty/error golden pair with a `card_move_target_error_{light,dark}` golden
once the widget swap lands (mirrors the existing `error_state_light.png` /
`error_state_dark.png` pattern already in `test/shared/widgets/goldens/`).

### 4.4 Finding (P1): a loading spinner with zero accessible name

Same file, same sheet, the branch immediately above the one in §4.3.2:

```dart
// card_bulk_overlays_widget.dart:93-99
child: targets.when(
  loading: () => const Center(
    child: Padding(
      padding: EdgeInsets.all(AppSpacing.xl),
      child: CircularProgressIndicator(),
    ),
  ),
  ...
```

No `semanticsLabel`, no enclosing `Semantics`. This is the **only** loading
spinner found in the entire audited scope with nothing announced to a screen
reader at all — every other raw `CircularProgressIndicator()` in the app
either passes `semanticsLabel` directly (`search_page_footer_widget.dart:58`,
`card_history_section_widget.dart:308`) or is wrapped in an outer
`Semantics(label: ...)` (`card_import_preview_step_widget.dart:192-195`,
`card_import_submit_progress_widget.dart:31-34`,
`card_editor_screen.dart:188-191`). This is exactly the failure mode
`MxLoadingState`'s own doc names as the reason the widget requires
`semanticsLabel` (§4.2): "a bare spinner is invisible to a screen reader — it
announces nothing at all."

**Callers.** Same as §4.3.2 — `_MoveTargetSheet`, reached from
`showCardMoveTargetSheet` (bulk-move UC-04 A5).

**Contract violated.** `mx_loading_state.dart:5-7`.

**Recommendation.** Replace the bare indicator with
`MxLoadingState(semanticsLabel: context.l10n.cardMoveTargetLoadingLabel)`
(new ARB key, EN+VI) — this also folds in the `RepaintBoundary` fix for free
and removes one more raw `.when()` branch (see §4.5).

**Closure test.** `tester.getSemantics(find.byType(CircularProgressIndicator))`
(or `find.bySemanticsLabel(...)`) while `cardMoveTargetsProvider` is
`AsyncLoading`, asserting a non-empty `label`. Add to whatever widget test
currently exercises `_MoveTargetSheet` (none was found in
`test/features/card/presentation/` under a "move target" name — this sheet
appears to have **no dedicated widget test today**, which is itself a
coverage gap worth recording — see §7 coverage gaps).

### 4.5 Finding (P2): `.when()` bypassing `MxAsyncView` with no recorded reason

Four production files call `AsyncValue.when()` directly instead of
`MxAsyncView`. Two are justified in an inline comment:

- `card_import_preview_step_widget.dart:66-98` (`document.when`) —
  explicitly sets `skipLoadingOnRefresh: false` with a dated review note
  (lines 67-73, "review finding, 2026-08-28") explaining why `MxAsyncView`'s
  default would create a second, disagreeing predicate for the same
  question already asked one line above (`document is! AsyncData`).
- `card_editor_context_widget.dart:67-97` (`deckContext.when`, ×2) — these
  `.when()` calls return `List<Widget>` fragments spliced into a `Column`,
  not a full loading/error/data replacement of one region — `MxAsyncView`'s
  contract (a single `Widget Function(T)` / loading / error) does not fit a
  "zero or more rows" shape, so this is a legitimate type mismatch, not
  negligence.

Two are not commented and reimplement what `MxAsyncView` already centralises,
one of them incorrectly (§4.3.2, §4.4):

- `card_bulk_overlays_widget.dart:93-114` (`targets.when`) — no comment
  explaining the bypass; also the site of the P1 findings above.
- `card_editor_screen.dart:184-204` (`loaded.when`) — no comment; reimplements
  loading (raw spinner, §4.2) and error (`MxEmptyState` misuse, §4.3.2)
  independently rather than inheriting `MxAsyncView`'s policy.

**Contract.** Not an explicit MUST — `MxAsyncView`'s doc frames itself as a
shared policy "written down once, not a default nobody looked at in three
separate files" (`mx_async_view.dart:11-14`), which is a SHOULD in spirit.
Per `docs/document-conventions.md`, a SHOULD deviation needs its reason on
record; two of the four sites don't have one.

**Recommendation.** Migrate `card_bulk_overlays_widget.dart` and
`card_editor_screen.dart` to `MxAsyncView` where the shape fits (both are a
single-region loading/error/data replacement, so both fit); this
mechanically fixes §4.3.2 and §4.4 as a side effect, since `MxAsyncView`'s
`loading` branch is `MxLoadingState` and its `error` branch is caller-chosen
(and would then naturally be written as `MxErrorState`).

**Closure test.** Covered by the closure tests in §4.3.2/§4.4 — once the
migration lands, a lint/architecture-guard rule could optionally assert "no
`AsyncValue.when(` outside `mx_async_view.dart` without an adjacent
`// escape:` comment," mirroring how `check_architecture.sh` already greps
for other raw-widget escape hatches. Not proposing that rule outright here —
flagging it as an option for whoever picks up §4.5's migration, since it
would have caught both P1s mechanically.

### 4.6 Finding (P1): the feedback-band family has one tone, and a warning caller has already landed

`MxCardFeedbackTone` (`mx_card.dart:69-80`):

```dart
/// Which meaning a feedback card carries.
///
/// Only [danger] exists because only failure bands exist in production.
/// AD-14 derives a role's container when a real caller lands, not before —
/// success/warning/info containers have no token yet, so a tone here without
/// a caller would be a colour waiting for a meaning.
enum MxCardFeedbackTone {
  danger,
}
```

**This comment is stale.** `AppSemanticColors` (`app_semantic_colors.dart:118-129`)
already defines `warningContainer`/`onWarningContainer`,
`infoContainer`/`onInfoContainer`, and `successContainer`/`onSuccessContainer`
— added at M100.21, per that file's own doc comment, specifically *because*
"the absence was putting business meaning on accent roles." The tokens this
audit needs already exist; only `MxCardFeedbackTone` and `MxFeedbackBand`
were never extended to expose them.

**The real caller has landed.** `ReminderBannerSectionWidget`
(`reminder_banner_section_widget.dart:19-43`) renders a denied OS
notification permission — "a state that lasts until the user changes it in
system settings" (doc lines 10-13) — through `MxFeedbackBand`, which is
hardcoded to `tone: danger` inside `MxFeedbackBand.build`
(`mx_feedback_band.dart:88`, `MxCard.feedback(tone: MxCardFeedbackTone.danger, ...)`).
A denied permission is not a failure the app caused; it is exactly the
"recoverable, non-failure condition" this audit's taxonomy calls **warning**.
It is now painted identically — same red container, same
`Icons.error_outline`, same `onErrorContainer` ink — to
`CardExportErrorBandWidget` and `SettingsErrorBandWidget`, both of which are
genuine write/export failures (BR-216, BR-180/181). A screen reader user
hears the same thing for both: there is no differentiated announcement for
"you can fix this in Settings whenever you like" versus "your last save was
lost."

**Callers.** `ReminderBannerSectionWidget` (reminder settings screen, M6 W5).
All 6 other `MxFeedbackBand` callers (`search_page_footer_widget.dart`,
`tag_rename_widget.dart`, `card_history_section_widget.dart`,
`settings_error_band_widget.dart`, `card_export_error_band_widget.dart`, and
`MxFeedbackBand` itself) are genuine failures and are correctly `danger` —
**verified individually, no other tone misuse found.**

**Contract.** This audit's taxonomy (§2, "warning" family) and AD-14's own
stated trigger condition for adding a tone: "derives a role's container when
a real caller lands, not before" — the caller has landed.

**Recommendation.**
1. Add `warning` to `MxCardFeedbackTone`, mapped to
   `semanticColors.warningContainer`/`onWarningContainer` inside
   `MxCard.feedback`'s private spec (mirrors how `danger` already maps to
   `dangerContainer`/`onDangerContainer`).
2. Add an optional `tone: MxCardFeedbackTone` parameter to `MxFeedbackBand`
   (default `danger`, so the other 6 call sites need no change), threading it
   to `MxCard.feedback(tone: tone, ...)` and to the icon/text ink (currently
   hardcoded `AppInk.onErrorContainer` at lines 92-117 — needs to resolve
   from the tone instead).
3. Switch `ReminderBannerSectionWidget` to `tone: MxCardFeedbackTone.warning`.
4. Update the stale comment at `mx_card.dart:71-74` — the "no token yet"
   half is no longer true; only "no caller yet" was ever the operative
   constraint, and it no longer holds either.
5. Leave `info`/`success` bands out of scope for this pass — no production
   caller for either exists yet (checked: no `MxFeedbackBand`-shaped
   surface anywhere renders a non-error, non-warning message), so adding
   them now would be exactly the "colour waiting for a meaning" AD-14 warns
   against. Add them the same way, when a caller lands.

**Closure test.** A golden pair
`mx_feedback_band_warning_{light,dark}.png` alongside the existing
danger-tone golden (find the existing one first — `MxFeedbackBand` is in
Widgetbook's `feedback_components.dart:50-85` but was not found as its own
named entry in `test/shared/widgets/golden_specimens.dart`; if it has no
golden today, add both danger and warning as part of this change, not
warning alone). A contrast unit test asserting `onWarningContainer` on
`warningContainer` clears the same floor `mx_feedback_band.dart:69-72`
already records for danger (4.50:1 light / 4.53:1 dark) — extend whichever
test currently owns that measurement (`focus_ring_contrast_test.dart` per
the button audit's method note, or the semantic-colors contract test if a
narrower one exists). A widget test on `ReminderBannerSectionWidget`
asserting the rendered `MxCard`'s fill resolves to `warningContainer`, not
`dangerContainer`, for a denied-permission `rejection`.

---

## 5. Snackbar / transient feedback

### 5.1 `MxMessenger` (`mx_messenger.dart`) and `MxUndoSnackBar` (`mx_undo_snack_bar.dart`)

- **One house pattern, and its own doc names the defect it replaced**: "Seven
  call sites used to assemble their own, and they disagreed about everything
  the user cannot see" (`mx_messenger.dart:5-12`). Both entry points now
  always `clearSnackBars()` before `showSnackBar()` (queue-clearing) and
  always wrap content in `Semantics(liveRegion: true, ...)` — the two axes
  the doc says used to disagree.
- **Dead-context safety is correctly handled.** `showMxMessageOn` takes a
  pre-captured `ScaffoldMessengerState` specifically for "the undo-failure
  paths" where "the context that started it may belong to a screen the user
  has already left" (lines 34-39). Verified both real callers of this path —
  `card_undo_widget.dart:53` and `deck_undo_widget.dart:55` — do capture
  `messenger` before the `await` and pass it through correctly. **No dead-context
  defect found; the pattern is used exactly as documented.**
- **No tone variants**, by explicit, correct restraint (`mx_messenger.dart:15-17`):
  "the design has not defined snack tone families, and the skill's own rule
  is that a wrapper must not invent one ahead of it" — consistent with how
  §4.6 recommends *not* adding `info`/`success` feedback-band tones ahead of
  a caller.
- **Action-text contrast**: `SnackBarThemeData.actionTextColor: scheme.inversePrimary`
  (§3.2) — an M3-generated pairing against `inverseSurface`, not a hand-picked
  colour; no separate measurement needed here, the token pair is designed
  for exactly this contrast case.

### 5.2 Finding (P2): actionable non-undo snackbars keep the 4-second default; undo gets 8

`kMxUndoDuration` (`mx_undo_snack_bar.dart:3-12`) is explicitly double
Material's default specifically because "four seconds is not enough to read
a sentence, notice the mistake and reach the button — least of all at a
large text scale, where the message wraps (R6)."

`showMxMessage`/`showMxMessageOn` (`mx_messenger.dart`) support an optional
`actionLabel`/`onAction` pair but never set `duration`, so any actionable
non-undo snackbar keeps the SDK's 4-second default. Two production callers
exercise this:

- `study_session_screen.dart:125-130` — `studyLeaveFailed` with a `retryAction`
  button, shown when leaving a study session fails (BR-82).
- `card_bulk_overlays_widget.dart:221-224` and `tag_catalog_screen.dart:252`
  use `showMxMessage` without an action (informational only — not affected
  by this finding).

The reasoning `kMxUndoDuration`'s doc gives for 8 seconds — reading time,
noticing the content, reaching a button, at a large text scale where the
sentence wraps — applies identically to "Retry" on a failed session-leave.
There is no reason specific to *undo* in that reasoning; it is a reason
specific to *any snackbar with a button a user has to physically reach*.

**Callers.** `study_session_screen.dart:121-131` (`ref.listen` error handler,
retry-to-leave).

**Contract.** Not an explicit rule — an internal-consistency gap between two
call sites of the same underlying mechanism (`SnackBar.duration`), each
independently reasoned but disagreeing on the same axis.

**Recommendation.** Either (a) give `showMxMessage`/`showMxMessageOn` a
`Duration duration = const Duration(seconds: 6)` default when `actionLabel`
is non-null (splitting the difference — longer than the no-action 4s default,
shorter than undo's destructive-recovery 8s, since a retry is lower-stakes
than an unreversed delete), or (b) explicitly document why "Retry" is
excluded from the reasoning `kMxUndoDuration` states, if the owner's
judgement is that 4s is in fact fine for this case. Either is acceptable;
leaving it unexamined is the gap.

**Closure test.** A unit test on `showMxMessage(..., actionLabel: 'x', ...)`
asserting the resolved `SnackBar.duration` matches whatever policy is chosen,
alongside the existing `mx_messenger`/`mx_undo_snack_bar` behavioural tests
(locate via `grep -rl showMxMessage test/`).

### 5.3 Finding (P2, unverified — recommend confirming against pinned SDK): possible nested live region

Both `mx_messenger.dart:57` and `mx_undo_snack_bar.dart:41` wrap their
message `Text` in an explicit `Semantics(liveRegion: true, child: Text(...))`.
Flutter's Material `SnackBar` widget has, in the versions this author has
prior knowledge of, wrapped its own content in
`Semantics(container: true, liveRegion: true, onDismiss: ...)` at the
`SnackBar` level itself. **This environment has no Flutter SDK checkout to
cite an exact `packages/flutter/lib/src/material/snack_bar.dart` line for
3.44.8**, so this is flagged as *unverified* rather than asserted, per this
audit's own "Flutter 3.44.8 canonical semantics first" rule — do not treat
this as confirmed.

If confirmed, the app's own inner `Semantics(liveRegion: true)` would be a
second live region nested inside the SDK's own, which TalkBack/VoiceOver may
either merge harmlessly or announce twice, depending on platform behaviour
that also cannot be confirmed without a device.

**Recommendation.** Before touching either file: (1) read
`packages/flutter/lib/src/material/snack_bar.dart` at the pinned 3.44.8
checkout to confirm whether `SnackBar` itself sets `liveRegion`; (2) if
confirmed, run a real TalkBack (Android) and VoiceOver (iOS/simulator — N/A,
iOS is deferred per AD-08, so TalkBack is the one that matters) pass on one
`showMxMessage` call to hear whether the message announces once or twice;
(3) only then decide whether to remove the app's inner wrap.

**Closure test.** Cannot be a unit/widget test — `SemanticsTester`/
`tester.getSemantics` can confirm a node's `liveRegion` flag is `true`, but
whether TalkBack announces a nested live region once or twice is a platform
rendering behaviour outside the semantics tree the widget test framework
exposes. This is a manual/device verification step, not an automatable
closure test — recorded honestly rather than invented.

---

## 6. Tooltip

**Verdict: clean, no finding.**

`grep -rn 'Tooltip('` across `lib/` returns zero literal `Tooltip(` widget
constructions in production code — the only two matches in the whole
repository are `app_tooltip_theme.dart` itself (the theme builder) and
`app_theme.dart` (wiring it into `ThemeData`). Every real tooltip in the app
is the `tooltip:` convenience parameter on `MxIconButton`, `MxFab`,
`MxMenuButton`, and `MxSearchField`'s clear action (12 production call sites
checked: `card_list_screen.dart`, `card_import_screen.dart`,
`card_detail_screen.dart`, `card_list_menu_widget.dart`,
`card_selection_bar_widget.dart`, `tag_catalog_row_widget.dart`,
`card_sort_control_widget.dart`, `deck_list_screen.dart`, `trash_screen.dart`,
`trash_row_widget.dart`).

This satisfies both of this audit's tooltip requirements directly:

- **"Trigger/mobile relevance."** Every tooltip sits on an icon-only control
  that is *already* the accessible name source (`tooltip:` doubles as the
  `Semantics` label for an unlabelled icon button — see
  `mx_icon_button.dart:109`, `mx_fab.dart:44`). A long-press reveals the
  tooltip text on a touch device; nothing here relies on hover, which does
  not exist on the release target (AD-08: Android).
- **"No tooltip-only discovery."** Every one of the 12 call sites is on a
  control that is already tappable and already does something without the
  tooltip firing — the tooltip only *names* an already-functional icon
  button, never gates functionality behind a hover/long-press reveal.

No production caller passes a bare `Tooltip` around non-interactive content,
which is the pattern that would actually risk "tooltip-only discovery" (a
sighted mouse user discovering information a touch/screen-reader user
cannot reach at all).

---

## 7. Severity registry

| # | Sev | Area | File:line | Summary |
|---|---|---|---|---|
| 1 | **P1** | Empty vs. Error | `card_bulk_overlays_widget.dart:100-106`, `card_editor_screen.dart:194-217` | Real `AsyncValue.error` rendered through `MxEmptyState` instead of `MxErrorState` — the exact anti-pattern BR-29/`mx_empty_state.dart` names |
| 2 | **P1** | Loading a11y | `card_bulk_overlays_widget.dart:93-99` | `CircularProgressIndicator()` with no `semanticsLabel` and no `Semantics` wrapper — the app's one silent spinner |
| 3 | **P1** | Feedback taxonomy | `mx_card.dart:69-80`, `mx_feedback_band.dart:88`, `reminder_banner_section_widget.dart:36-41` | No `warning` tone exists; a real warning-class caller (denied permission) is forced into the danger/error tone, though the underlying `warningContainer` token already exists |
| 4 | **P2** | `MxAsyncView` bypass | `card_bulk_overlays_widget.dart:93-114`, `card_editor_screen.dart:184-204` | Raw `.when()` with no recorded reason, reimplementing (and in this case mis-implementing) `MxAsyncView`'s centralised policy |
| 5 | **P2** | Snackbar duration | `mx_messenger.dart:40-63`, `study_session_screen.dart:125-130` | Actionable non-undo snackbar keeps the 4s SDK default while undo's identical "reach a button" reasoning got 8s |
| 6 | **P2** | Snackbar semantics (unverified) | `mx_messenger.dart:57`, `mx_undo_snack_bar.dart:41` | Possible nested live region if `SnackBar` itself already sets one in 3.44.8 — needs SDK/device confirmation, not asserted |
| 7 | **P3** | Loading duplication | `card_import_preview_step_widget.dart:192-195`, `card_import_submit_progress_widget.dart:31-34`, `card_editor_screen.dart:188-191` | Hand-rolled `Semantics(label) → CircularProgressIndicator()` instead of `MxLoadingState`, so none gets its `RepaintBoundary` fix — low risk today, same bug class `MxLoadingState` was built to close |
| 8 | **P3** | Progress a11y | `card_progress_panel_widget.dart:161-195` (`_ProgressRing`) | Mastery ring has no `Semantics(label, value)` wrap, unlike every other progress indicator in the app; the visible "67%" `Text` is still individually reachable, so not silent, but disconnected from "mastered" as a standalone node |
| 9 | **P3** | Duplication | `search_page_footer_widget.dart:51-64`, `card_history_section_widget.dart:291-314` (`_InlineSpinner`) | Same inline-spinner grammar independently reimplemented in two features; each is individually correct and accessible — a DRY note, not a defect |
| 10 | **P3** | Contrast recordkeeping | `app_semantic_colors.dart` (`progressFill`/`progressTrack`) | No measured contrast ratio recorded in comments, unlike `borderControl`/`success`/`danger`; nothing found suggests a floor is missed, but it is unverified either way |

**P0: none.**

---

## 8. Coverage gaps found during this audit

- `_MoveTargetSheet` (`card_bulk_overlays_widget.dart`) has no widget test
  found under `test/features/card/presentation/` exercising its loading or
  error branch — both P1 findings above (§4.3.2, §4.4) live in code with no
  test that would have caught either.
- `MxFeedbackBand` was not found as a named entry in
  `test/shared/widgets/golden_specimens.dart` (it does appear in Widgetbook's
  `feedback_components.dart:50-85` and is exercised incidentally by several
  feature-level widget tests via `liveRegion` assertions) — confirm whether
  it has a dedicated light/dark golden before adding the `warning`-tone
  golden §4.6 recommends, so the two land together rather than the new tone
  arriving with better coverage than the existing one.
- `progressFill`/`progressTrack` contrast is unmeasured in comments (§7 #10).

## 9. What is already solid (confirmed, not re-litigated)

- `ProgressIndicatorThemeData`, `SnackBarThemeData`, `TooltipThemeData`: all
  three correct, each with a recorded rationale (§3).
- `MxProgressBar`: correct role separation from decorative accent, correct
  clamping, correct motion policy, correct accessibility wrapping, both
  production call sites deliberate (§4.1).
- `ProgressWeekBarWidget`'s bespoke bar: a reasoned, correct escape hatch
  from `MxProgressBar`, not a defect (§4.1.1).
- `MxSessionTopBar`: correct reuse of `MxProgressBar`, correct
  single-announcement design between the bar and its trailing figure (§4.1).
- `MxLoadingState`: two real, measured fixes on record (`RepaintBoundary`,
  theme-colour inheritance) — no defect in the widget itself (§4.2).
- `MxAsyncView`: correctly used at 18 of 22 `.when()`-shaped call sites; its
  own `error` builder is used correctly everywhere it is reached (§4.3.1).
- Tooltip family: zero raw `Tooltip(` usage, zero tooltip-only-discovery risk
  (§6).
- Undo-snackbar dead-context handling: both real call sites correctly
  pre-capture `ScaffoldMessengerState` (§5.1).
- Localization: every ARB key cited in this report's evidence is present in
  both `app_en.arb` and `app_vi.arb` (spot-checked: `cardImportParsingLabel`,
  `cardImportSubmittingLabel`, `studyFrameProgress`, `cardEditorLoadingLabel`,
  `librarySearchLoadingMoreLabel`).
- High-contrast scheme (`app_high_contrast.dart`) deliberately does not
  re-point `success`/`warning`/`danger`/`info` — documented decision, each
  already clears its own floor per that file's own comments; consistent with
  "existing stricter contrast floor wins."

---

## 10. Recommended implementation order

None of the following needs a new abstraction beyond one enum value
(`MxCardFeedbackTone.warning`) and one optional parameter
(`MxFeedbackBand.tone`). Ordered by blast radius, smallest first:

1. **§4.4** — add `semanticsLabel`/wrap in `Semantics` for the one silent
   spinner (`card_bulk_overlays_widget.dart:93-99`). One file, one branch,
   new ARB key ×2 (EN/VI).
2. **§4.3.2** — swap both `MxEmptyState(icon: Icons.error_outline, ...)`
   sites for `MxErrorState`. Two files; the move-target sheet additionally
   needs a new error-specific ARB string and a way to re-invoke its provider
   for the retry action.
3. **§4.5** — migrate `card_bulk_overlays_widget.dart` and
   `card_editor_screen.dart` from raw `.when()` to `MxAsyncView`; steps 1-2
   are naturally subsumed by this migration if done together, since
   `MxAsyncView`'s `loading`/`error` slots are exactly where those fixes
   live. Consider doing 1-2 as part of this step rather than before it.
4. **§4.6** — extend `MxCardFeedbackTone` with `warning`, thread it through
   `MxFeedbackBand`, switch `ReminderBannerSectionWidget`, fix the stale
   comment, add the warning-tone golden (and `MxFeedbackBand`'s missing
   danger-tone golden, if §8 confirms it is in fact missing).
5. **§5.2** (duration policy) and **§5.3** (SDK/device verification) can land
   independently, in either order, once someone has time to (a) decide the
   duration policy and (b) check the pinned SDK source / run a TalkBack pass.

Everything in §7's P3 rows (#7-#10) is a record-for-later, not a blocker to
any of the above.
