# Tokyo handoff redesign — implementation plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Redesign the whole memox app against `memox-flutter-handoff.json` — foundations first, then every widget in sections A–G — so the running app matches the handoff in both themes.

**Architecture:** The handoff is the source of truth (owner, 2026-09-13). Work flows through the layers that already exist: tokens in `lib/core/theme/foundations/`, component themes in `lib/core/theme/components/`, shared `Mx*` widgets in `lib/shared/widgets/`, feature composition last. Each **phase is one PR** with its own WBS entry and one golden re-authoring pass; each **task is one commit** inside that PR. A contract that changes moves the test or guard that watches it in the same commit (`v1-freeze.md` §3c).

**Tech Stack:** Flutter 3.44.8 (`.fvmrc`) · Material 3 · Riverpod 3 · Drift · Widgetbook · `flutter_test` goldens authored on Linux (WSL) · Python guard `code-verification-guard-v2`.

**Spec:** `docs/design-system/handoff/memox-flutter-handoff.json` (committed by Task 1 from `C:\Users\ntgpt\OneDrive\Desktop\memox-flutter-handoff.json`, generated 2026-09-13T07:37Z from `ui_kits/mobile/flutter-prompt.html`). Read its `foundations` string once, then the `widgets[n].spec` of the widget a task names. Every value below was copied from that file or read from the repo at `dcd22f32`.

---

## Global Constraints

Every task implicitly includes this section.

**Repo contract (from `CLAUDE.md`, not negotiable in this redesign)**

- Tokens only — no hex, no raw padding, no raw text style in `lib/features/`. User-visible strings only in `lib/l10n/app_en.arb` + `app_vi.arb`.
- `domain/` imports no Flutter. `features/` never imports `app/`. `widgets/` buckets: `sections/ items/ overlays/ support/` only.
- Shared widget APIs are closed (AD-23): content, behaviour and **closed semantic enums** — never a `Color`, radius, elevation or padding parameter.
- 48dp touch floor on everything interactive. Visual size and hit area stay separate.
- `spacing_is_a_gap_test`: a spacing token is a gap on one axis; a box's width/height comes from `AppSizing` / `AppIconSize`.
- Deleting, excluding or disabling a test/guard to get through CI is forbidden. A changed contract moves its test to the new value in the same commit.
- Goldens are authored on **Linux only**, with `TZ=UTC`. A Windows `--update-goldens` writes PNGs CI rejects.
- Never log card content. No `DateTime.now()` in `lib/features/`.
- Subagents run `model: sonnet`; the hook in `.claude/settings.json` enforces it.
- Commits: Conventional Commits, scope = feature (`feat(theme): …`, `feat(deck): …`). End every commit message with `Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>`. The `git commit -m "…"` lines in the tasks show the subject only: add the trailer as the last paragraph (a second `-m`).

**Handoff foundations (verbatim values)**

- Palette: already shipped verbatim at M100.87 (`primary #5265F5 / #8B9AFF`, `surface #F7F9FE / #0A0E27`, `inverseSurface #34395D` both themes). Do not retune a hex.
- Opacities: disabled `0.38` · hover `0.08` · pressed `0.12` · glass `0.84`.
- Type: one family **Plus Jakarta Sans**. Roles — caption `12/600/1.4/+1.2` · body `14/400/1.5/0` · body large `16/500/1.5/0` · title `20/700/1.2/-0.64` · headline `24/700/1.2/-0.64` · display `32/800/1.1/-0.64` · stat `40/600/1.0/-0.64`. Tracking tokens: `ls-heading -0.64` · `ls-label 0.72` · `ls-section 1.2`. 12px is a hard floor.
- Spacing: `4 · 8 · 12 · 16 · 20 (card) · 24 · 32 · 48 (page-end clearance)`. Screen gutter 16 — **also on compact phones**.
- Radius: `xs 4 · sm 8 · md 12 · lg 16 · card 20 · xl 24 · xxl 28 · full 999`.
- Icons: `xs 16 · sm 20 · md 24 · lg 32 · xl 40`.
- Sizes: button `48` (compact `36`, large `52`) · input `52` · chip `32` (compact `24`) · icon-button ink box `36` · touch `48` · app bar `56` · bottom nav `80` (bar `64`) · FAB `52` extended only · list row `48` MINIMUM.
- Shadows: card `shadow-soft 0 1px 2px @4%` · raised `0 12px 32px @10%` (dark `0 16px 40px @42%`) · floating `0 8px 24px @12%` (dark `0 10px 28px @50%`) · **chrome `0 -2px 12px @5%` (dark `0 -2px 14px @36%`)**. Scrim `45%` of `scrim`.
- Composition: 12 related rows · 16 list items · 24 sections · 32 major groups · card interior 20 · scroll tail 48.
- Do not copy: hover-only affordances, the fake status bar, device bezel, absolute positioning, `::after` hit expanders, `color-mix`, fixed pixel boxes around text.

**Owner decisions (2026-09-13) — binding, do not re-ask**

1. Foundations first, then sections A–G.
2. Fill / surface / dot / icon hexes stay verbatim; **text** that fails AA uses a same-hue ink on `AppSemanticColors` (`accentInk`, `successInk`, `warningInk`, `dangerInk`, `infoInk`, `secondaryInk`, `tertiaryInk`, `inversePrimaryInk`).
3. One family, Plus Jakarta Sans; drop Inter.
4. Kit beats M3 canonical roles (FAB fill `primary`, NavigationBar indicator `primary`) — move `m3_role_binding_guard_test` bindings in the same commit.
5. Control edges and status dots keep the kit hex even under 3:1; the gate pins the measured figure as the new floor.
6. Shadows exactly as the handoff's three tiers (already in `app_elevation.dart`); dark = rim + drop.
7. **Library deck row follows the handoff:** icon-tile leading, name + workload subtitle, trailing mastery ring drawing `learnedFraction` (mastery colour only at 100%, BR-88) + overflow. The Study button leaves the row; tapping the row opens the deck. This reverses M4.12.
8. **StudyTopBar accent by session kind:** `StudySessionKind.learning` → `tertiary` (text via `tertiaryInk`); `StudySessionKind.reviewing` → `primary` (text via `accentInk`). Never green.
9. **Rating buttons map onto existing semantic containers:** again / forgotten → danger · hard → warning · good → brand (`primaryContainer`) · easy / remembered → success. Tonal fills, `on*Container` labels. No new token.
10. **Widgets with no feature yet are built into `lib/shared/widgets/` + Widgetbook**, tested, not wired into a screen: Avatar, OfflineBanner, BarChart, Slider, SegmentedControl, SearchField voice slot, Skeleton, StreakChip, SelfAssessment.

---

## Decision log — where the handoff is silent

Defaults chosen from handoff tokens; each is recorded in `docs/design-system/tokyo-component-mapping.md` §9 by Task 1 so the owner can overturn one without reading this plan.

| ID | Question the handoff does not answer | Default |
|---|---|---|
| D1 | Which of the 15 M3 `TextTheme` slots carries which of the 7 roles | Table in Task 2. Every slot resolves to a handoff size; `titleSmall`/`labelLarge` = 14 @ 600, `bodySmall` = 12/400/1.4/0, `labelMedium` = 12/600/1.4/0.72 are derived pairings of handoff tokens |
| D2 | "ghost border", "ghost divider", "hairline at 12%" | `outlineVariant` at `AppStroke.hairline` — the Foundations say "1px solid outlineVariant on cards, inputs and dividers" |
| D3 | Entries marked `[INFERRED]` | Keep the shipping behaviour (owner rule). Applies to: button/switch/slider disabled 38%, every "pressed 8%", card pressed tint, match-tile shake, sheet drag scrim, scrim tap-dismiss |
| D4 | IconTile glyph size per tile size | sm 28 → icon xs 16 · md 36 → icon sm 20 · lg 44 → icon md 24 |
| D5 | Which dialog is sm/md/lg | Confirm, alert, async-confirm → md 320; form dialog → lg 340. Inset horizontal 24, vertical 20 |
| D6 | Which `secondary` call sites become Tonal ("Secondary — sits on surface") vs stay Outlined ("Low-emphasis / cancel") | Table in Task 6 |
| D7 | Glass bottom nav | Solid `surface` — the handoff's own permitted fallback; `BackdropFilter` stays at 0 |
| D8 | MasteryRing colour steps `<34 / <67 / ≥67` name no colours | BR-88 governs deck progress: `primary` below 100%, `mastery` at 100% |
| D9 | Size variants with no caller: button large 52, chip compact 24, app bar compact 48 | Deferred (decision 10 covered whole widgets only) |
| D10 | Nav destination glyphs `home · layers · bar-chart-3 · settings` | Keep today's Material glyphs — same meanings (Library, Study, Progress, Settings) |
| D11 | Card lifecycle → status tokens | `isNew → statusNew` · `beginning → statusLearning` · `reviewing → statusReviewing` · `mastered → statusMastered` |
| D12 | Foundations say "16 FAB, dialog, sheet" and "24 bottom sheet top corners", but the Dialog and BottomSheet specs say 20 | The widget specs win: the Dialog spec says "not radius-lg 16", the BottomSheet spec "not radius-xl 24" |
| D13 | Card prompt size (30 is off the scale) | 32 / w700 / 1.2 / −0.64; compact prompt 24 |
| D14 | Hero numeral | Stat role 40 / w600 / tabular; keep `heroNumeralCapTrim` (a PJS cap-height trim, size-independent) |
| D15 | Scroll tail with a FAB | `AppSizing.fab + AppSpacing.lg + AppSpacing.xxxl` (button + its margin + 48) |
| D16 | Icon button glyph: spec says 20, Foundations say "24 app-bar and navigation actions" | App-bar actions 24 (`MxIconButtonPlacement.bar`), every other icon button 20 (default) |
| D17 | Flashcard flip vs the shipped "back supports front" layout | Flip is the reveal transition: rotate Y 0→90° on the prompt layout, 90→180° onto the revealed layout (prompt + answer). Nothing the user reads disappears |
| D18 | BarChart non-today bars | `primaryContainer`; today `primary` |
| D19 | Dialog `shadow-card` is not reachable through `DialogThemeData` | Material elevation `AppElevation.raised` with `materialShadowColor(scheme)` |
| D20 | Sheet enter "translateY 20% + fade" and scrim "220ms" | `showModalBottomSheet` only takes duration + curve: 260ms `Cubic(0.2,0,0,1)`. Dialog barrier fades with its 200ms route |
| D21 | Sheet `shadow-chrome` over a 45% scrim | Not painted — invisible over the scrim and `BottomSheetThemeData` has no `BoxShadow` slot |
| D22 | Spinner "0.8s linear, top segment transparent" | Deferred P3: keep `CircularProgressIndicator` (size and colour already match) |
| D23 | Mastery as **text** | Keeps `successInk`; `mastery` is only a fill/arc/dot |
| D24 | Status badge label colour | `onSurfaceVariant`; the dot carries the status colour |
| D25 | Glyph size inside the empty/error state tile | 64 tile → icon xl 40 ("illustrative"); 52 tile → icon lg 32 |
| D26 | ListRow says "both text lines truncate to one line"; SettingsTile and chooser rows carry sentence subtitles | One line applies to the ListRow compositions (search results, tag rows — Task 16). `MxListTile` keeps its two-line subtitle: the study direction chooser's recommendation must survive 320dp × 2.0 (`study_direction_chooser_layout_test.dart`) |
| D27 | Focused **and** in error at once — the spec gives focus 1px ("NOT 2px") and error 1px, never both | Focused-error keeps `AppStroke.focus` (2), M100.36 §4C: the hue is already `error`, so the stroke is the only channel left to show focus |

**Not built at all:** StatusBar (the spec says "build nothing"), backdrop blur, connectivity stream, speech recognition behind the mic glyph, `fl_chart`.

---

## Handoff → code map

| # | Handoff widget | Owner in code today | Phase · Task |
|---|---|---|---|
| 0 | StatusBar | OS (SafeArea) | — |
| 1 | AppBar | `appBarTheme` + `MxContentShell` | 1·T2 (title type) · 2·T7 (actions) |
| 2 | NavigationBar | `app_navigation_bar_theme.dart` + `MxNavigationBar` | 5·T21 |
| 3 | Breadcrumb | `MxBreadcrumb` / `mx_breadcrumb_step.dart` | 5·T22 |
| 4 | StudyTopBar | `MxSessionTopBar` + `study_session_frame_section_widget.dart` | 6·T29 |
| 5 | FilledButton | `MxActionButton.primary` | 2·T5 |
| 6 | TonalButton | `MxActionButtonVariant.tonal` | 2·T6 |
| 7 | OutlinedButton | `MxActionButtonVariant.secondary` | 2·T6 (no style change — #546) |
| 8 | IconButton | `MxIconButton` + `app_icon_button_theme.dart` | 2·T7 |
| 9 | FloatingActionButton | `MxFab` + `app_fab_theme.dart` | 2·T8 |
| 10 | TextButton | `MxTextButton` | no change (accentInk + `accent:` tone already) |
| 11 | Card | `MxCard` + `app_card_theme.dart` | 3·T9 |
| 12 | IconTile | — | 3·T10 |
| 13 | ListTile · deck row | `DeckTileWidget` | 3·T15 |
| 14 | ListRow | `MxListTile`, `SearchResultShellWidget`, `TagCatalogRowWidget` | 3·T12, T16 |
| 15 | SectionHeader | `MxSectionLabel` | 3·T11 |
| 16 | Divider | `app_divider_theme.dart` | 3·T12 |
| 17 | SettingsTile | `MxListTile` in `lib/features/settings/` | 3·T12 |
| 18 | Avatar | — | 5·T27 |
| 19 | TextField | `MxTextField` + `app_input_theme.dart` | 4·T17 |
| 20 | SearchField | `MxSearchField` | 4·T18 |
| 21 | Switch | `MxSwitchRow` | 4·T19 |
| 22 | SegmentedButton | — (0 callers) | 4·T20 |
| 23 | Chip | `MxPillButton` + `app_chip_theme.dart` | 4·T18 |
| 24 | Slider | — (0 callers) | 4·T20 |
| 25 | StatusBadge | `card_state_widget.dart` dot | 3·T13 |
| 26 | MasteryRing | — | 3·T14 |
| 27 | LinearProgress | `MxProgressBar` | 3·T13 |
| 28 | StatDisplay | `AppTextStyles.heroNumeral` callers | 6·T34 |
| 29 | StreakChip | — | 6·T34 |
| 30 | BarChart | — | 6·T35 |
| 31 | Flashcard | `study_card_face_section_widget.dart` | 6·T32 |
| 32 | RatingBar | `_controls` in the same file + `recall_timer_pieces_widget.dart` | 6·T28 |
| 33 | SelfAssessment | — | 6·T33 |
| 34 | ChoiceOption | `guess_option_item_widget.dart` | 6·T30 |
| 35 | MatchTile | `match_tile_widget.dart` | 6·T31 |
| 36 | OfflineBanner | — | 5·T25 |
| 37 | Banner / Callout | `MxFeedbackBand` + `MxCard.feedback` | 5·T25 |
| 38 | Snackbar | `app_snackbar_theme.dart` | done at M100.87 |
| 39 | BottomSheet | `app_bottom_sheet_theme.dart` + `showMxSheet` | 5·T24 |
| 40 | Dialog | `app_dialog_theme.dart` + four `Mx*Dialog` | 5·T23 |
| 41 | EmptyState | `MxEmptyState` | 5·T26 |
| 42 | ErrorState | `MxErrorState` | 5·T26 |
| 43 | Skeleton | — | 5·T27 |
| 44 | Spinner | `MxLoadingState` | D22 |
| 45 | Scrim | `modalBarrierColor` | 5·T23 |

## Phase → PR map

| Phase | PR title | Tasks | Touches `lib/features/` → integration suite |
|---|---|---|---|
| 0 | `docs(design-system): commit the Tokyo handoff and its decision log` | 1 | no |
| 1 | `feat(theme): handoff type scale, geometry ladders and composition` | 2–4 | yes (renames) |
| 2 | `feat(design-system): handoff buttons, icon buttons and extended FAB` | 5–8 | yes |
| 3 | `feat(design-system): handoff cards, rows, status and the Library deck row` | 9–16 | yes |
| 4 | `feat(design-system): handoff fields, chip, switch, slider, segmented control` | 17–20 | yes |
| 5 | `feat(design-system): handoff chrome and overlays` | 21–27 | yes |
| 6 | `feat(study): handoff study widgets, rating colours and data viz` | 28–35 | yes |
| 7 | `feat(design-system): composition sweep and V1 re-freeze` | 36–38 | yes |

Phases run in order; a later phase branches from `origin/main` after the previous PR merged.

---

## Procedures used by every phase

### P1 · Branch and WBS

```bash
git fetch origin --prune
git switch -c claude/tokyo-redesign-phase-<N> origin/main
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

The WBS id is claimed **at push time**, not at branch time (parallel PRs take numbers): `grep -nE "^### M100\.[0-9]+" docs/wbs.md docs/wbs-archive/m100.md | sort -t. -k2 -n | tail -3` after `git fetch`, then take the next free `M100.xx`. Add the entry under `## M99 · Adhoc` in `docs/wbs.md` in the phase's first code commit, with these fields (format of `docs/wbs-archive/m100.md` M100.87):

```markdown
### M100.xx · <phase title in Vietnamese>

- **Status:** in-progress
- **Owner:** Claude
- **Goal:** <one sentence>
- **Scope:** <tasks of this phase, bullet per task>
- **Editable documents:** `docs/wbs.md`, `docs/design-system/tokyo-component-mapping.md`<, others the phase names>
- **Output:** <files>
- **Acceptance criteria:**
  - [ ] <one per task, measurable>
  - [ ] `flutter analyze` 0/0 repo-wide; full host suite green; guard 0 findings
  - [ ] Goldens re-authored on Linux, `TZ=UTC`; gallery republished at the pinned URL
- **Dependencies:** <previous phase id>
- **Tests required:** <new/moved test files>
- **Checklist phases:** 7, 12, 13
```

On merge the entry flips to `done (YYYY-MM-DD)` and moves to `docs/wbs-archive/m100.md` (newest first).

### P2 · Task inner loop

After each task's last code step:

```bash
dart format lib test widgetbook/lib
flutter analyze --no-fatal-infos
```

Expected last line: `No issues found!` — read the summary line, never grep for errors. Then the task's targeted `flutter test <files>`.

### P3 · Phase gate (before push)

```bash
bash .claude/skills/flutter-workflow/scripts/check_format.sh
flutter analyze --no-fatal-infos
bash .claude/skills/flutter-architecture/scripts/check_architecture.sh
python .claude/skills/flutter-workflow/scripts/check_docs.py
python code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v7
flutter test --exclude-tags golden --reporter failures-only
(cd widgetbook && flutter analyze --no-fatal-infos && flutter test)
```

All must pass. The design-audit tests rewrite tracked files under `design_audit/`; commit those regenerated reports only when the diff is token values (no timestamps, no machine paths). Phases touching `lib/features/` or `lib/app/` also run, on the emulator, with nothing else heavy running:

```bash
flutter test integration_test/ -d emulator-5554 --flavor development
```

Expected: `9 passing, 0 failing`.

### P4 · Goldens on Linux (WSL, per-branch clone)

Never run this while the Windows host suite runs (Windows commit charge kills WSL). Write the script with the Write tool (a heredoc eats backslashes), copy it in, strip CRs, run:

`C:\Users\ntgpt\AppData\Local\Temp\goldens_branch.sh`

```bash
#!/usr/bin/env bash
# usage: goldens_branch.sh <branch> update|compare
set -uo pipefail
BRANCH="$1"; MODE="${2:-compare}"
REPO="$HOME/memox-${BRANCH//\//-}"
export PATH="/opt/flutter/bin:$PATH"
if [ ! -d "$REPO" ]; then
  git clone -q "$HOME/memox-hardening" "$REPO"
  git -C "$REPO" remote set-url origin "$(git -C "$HOME/memox-hardening" remote get-url origin)"
fi
cd "$REPO" || exit 1
git fetch -q origin "$BRANCH" && git reset -q --hard FETCH_HEAD || exit 1
echo "head before: $(git rev-parse --short HEAD)"
flutter pub get >/dev/null
dart run build_runner build --delete-conflicting-outputs >/dev/null
FLUTTER_ROOT=/opt/flutter bash .claude/skills/flutter-workflow/scripts/prepare_test_fonts.sh >/dev/null
mapfile -t FILES < <(grep -rlE '@Tags\(.*golden' test --include='*_test.dart' | sort)
[ "${#FILES[@]}" -ge 40 ] || { echo "FATAL: only ${#FILES[@]} golden files"; exit 1; }
status=0
for ((i = 0; i < ${#FILES[@]}; i += 6)); do
  slice=("${FILES[@]:i:6}")
  if [ "$MODE" = update ]; then
    TZ=UTC flutter test -j 1 --tags golden --update-goldens "${slice[@]}" || status=1
  else
    TZ=UTC flutter test -j 1 --tags golden "${slice[@]}" || status=1
  fi
done
echo "head after: $(git rev-parse --short HEAD)"
git status --porcelain -- '*.png' | wc -l
exit $status
```

```bash
MSYS_NO_PATHCONV=1 wsl.exe -d Ubuntu-24.04 -- bash -c 'cp /mnt/c/Users/ntgpt/AppData/Local/Temp/goldens_branch.sh /root/ && sed -i "s/\r$//" /root/goldens_branch.sh && chmod +x /root/goldens_branch.sh'
git push -u origin HEAD
MSYS_NO_PATHCONV=1 wsl.exe -d Ubuntu-24.04 -- bash -c '/root/goldens_branch.sh claude/tokyo-redesign-phase-<N> update'
```

"head before" and "head after" must match. Copy the PNGs back (the WSL clone cannot push) and commit from Windows:

```bash
MSYS_NO_PATHCONV=1 wsl.exe -d Ubuntu-24.04 -- bash -c 'cd /root/memox-claude-tokyo-redesign-phase-<N> && git status --porcelain -- "*.png" | awk "{print \$2}" | while read -r p; do cp "$p" "/mnt/d/workspace/memox-v7/.claude/worktrees/<worktree-dir>/$p"; done'
git add test && git commit -m "test(goldens): re-author on Linux for phase <N> (M100.xx)"
git push
MSYS_NO_PATHCONV=1 wsl.exe -d Ubuntu-24.04 -- bash -c '/root/goldens_branch.sh claude/tokyo-redesign-phase-<N> compare'
```

The compare run must exit 0 with `0` PNGs dirty.

### P5 · Gallery

```bash
python .claude/skills/flutter-testing/scripts/build_screen_gallery.py
```

Read the live artifact first (`Artifact action: read`, url `https://claude.ai/code/artifact/e8a68227-1582-407c-88c2-ff25d66bd9d8`); if another branch republished since your last read, splice your figures into the live page instead of overwriting it. Publish `build/screen_gallery.html` **at that URL** and quote the header's `ảnh <digest>` in the PR description.

### P6 · Merge

```bash
git fetch origin --prune
git merge-base --is-ancestor origin/main HEAD || git merge origin/main
```

If it merged anything, re-run P3 (and P4 compare if goldens could move). Open the PR (body ends with `🤖 Generated with [Claude Code](https://claude.com/claude-code)`), wait for CI green (no `--auto`, no `--admin`), then:

```bash
gh pr merge <n> --squash
gh pr view <n> --json state -q .state   # must print MERGED
git push origin --delete claude/tokyo-redesign-phase-<N>
```

---

## Phase 0 — the source travels with the code

### Task 1: Commit the handoff and the decision log

**Files:**
- Create: `docs/design-system/handoff/memox-flutter-handoff.json` (byte copy of the Desktop file)
- Modify: `docs/design-system/v1-freeze.md` §3c (the paragraph "Nguồn thiết kế đang nằm ngoài repo")
- Modify: `docs/design-system/tokyo-component-mapping.md` (header `Updated by task`, `Last updated`; new §9)
- Modify: `docs/wbs.md` (entry, P1)
- Add: this plan file

**Interfaces:**
- Produces: the path `docs/design-system/handoff/memox-flutter-handoff.json` every later task reads; `tokyo-component-mapping.md` §9 decision IDs D1–D27 that later tasks cite in comments.

- [ ] **Step 1: Copy the file byte for byte and prove it**

```bash
mkdir -p docs/design-system/handoff
cp "/c/Users/ntgpt/OneDrive/Desktop/memox-flutter-handoff.json" docs/design-system/handoff/memox-flutter-handoff.json
sha256sum "/c/Users/ntgpt/OneDrive/Desktop/memox-flutter-handoff.json" docs/design-system/handoff/memox-flutter-handoff.json
```

Expected: two identical hashes.

- [ ] **Step 2: Replace the §3c "outside the repo" paragraph** in `v1-freeze.md` with:

```markdown
**Nguồn thiết kế nằm trong repo từ M100.xx:**
`docs/design-system/handoff/memox-flutter-handoff.json` — bản sao nguyên byte của
file chủ dự án đưa ngày 2026-09-13. Session cloud và subagent đọc được nó. Kế
hoạch thực hiện: `docs/superpowers/plans/2026-09-13-tokyo-handoff-redesign.md`;
các chỗ handoff im lặng được ghi ở `tokyo-component-mapping.md` §9.
```

- [ ] **Step 3: Append §9 to `tokyo-component-mapping.md`** — title `## 9. Handoff redesign — quyết định của chủ dự án và mặc định khi handoff im lặng`, then two tables copied from this plan: *Owner decisions* 1–10 (none of them is recorded in the repo yet — `v1-freeze.md` §3c narrates the reopening, not these choices) and the *Decision log* D1–D27, both verbatim. Each row MUST keep its number or ID.

- [ ] **Step 4: WBS entry** per P1, Goal: "Đưa handoff Tokyo vào repo làm nguồn thiết kế đọc được, kèm sổ quyết định cho mọi chỗ handoff im lặng."

- [ ] **Step 5: Verify**

```bash
python .claude/skills/flutter-workflow/scripts/check_docs.py
```

Expected: exit 0.

- [ ] **Step 6: Commit and ship** (P6; no goldens, no gallery)

```bash
git add docs
git commit -m "docs(design-system): commit the Tokyo handoff and its decision log (M100.xx)"
```

---

## Phase 1 — foundations (P0)

### Task 2: One family, the handoff's seven type roles

**Files:**
- Modify: `lib/core/theme/typography/app_typography.dart`
- Modify: `lib/core/theme/typography/app_text_styles.dart`
- Modify: `pubspec.yaml` (drop the `Inter` family), `widgetbook/pubspec.yaml` (same), `test/flutter_test_config.dart` (drop the `'Inter'` entry)
- Delete: `assets/fonts/Inter-Variable.ttf`
- Modify (family references the compiler will name): `lib/core/theme/app_theme.dart:197`, `test/core/theme/components/component_theme_typography_test.dart:52`, `integration_test/it_platform_test.dart:311`, `test/features/deck/presentation/deck_list_rhythm_golden_test.dart:530` (and its `_interCapHeight`, Step 7)
- Test: `test/core/theme/typography/app_typography_test.dart` (metric groups replaced; the weight registry group kept and moved — Step 7), `test/core/theme/typography/cjk_fallback_test.dart`, `test/core/theme/typography/text_restyle_alias_test.dart` (family references)

**Interfaces:**
- Produces: `AppTypography.family` (replaces `displayFamily` and `bodyFamily`); `AppTypography.headingTracking = -0.64`, `labelTracking = 0.72`, `sectionLabelTracking = 1.2`; the slot table below, which every later task's text relies on. `AppTypography.heroNumeralWeight` becomes `FontWeight.w600`.

The slot table (D1):

| Slot | size | weight | height | tracking | handoff role |
|---|---|---|---|---|---|
| displayLarge, displayMedium | 40 | 600 | 1.0 | −0.64 | stat |
| displaySmall, headlineLarge | 32 | 800 | 1.1 | −0.64 | display |
| headlineMedium, headlineSmall | 24 | 700 | 1.2 | −0.64 | headline |
| titleLarge | 20 | 700 | 1.2 | −0.64 | title |
| titleMedium, bodyLarge | 16 | 500 | 1.5 | 0 | body large |
| titleSmall, labelLarge | 14 | 600 | 1.5 | 0 | body size, semibold (derived) |
| bodyMedium | 14 | 400 | 1.5 | 0 | body |
| bodySmall | 12 | 400 | 1.4 | 0 | caption size, regular (derived) |
| labelMedium | 12 | 600 | 1.4 | 0.72 | caption, `ls-label` (derived) |
| labelSmall | 12 | 600 | 1.4 | 1.2 | caption |

- [ ] **Step 1: Write the failing test** — in `test/core/theme/typography/app_typography_test.dart`, replace everything from the imports down to the end of `group('the weights the app spends'` (lines 1–300 at `dcd22f32`) with the code below. **Keep `group('the weight registry (A20.1 P1-10)'` and everything after it**, pasted back inside the new `main()` where the code marks it — Step 7b updates it; deleting it would delete a guard.

```dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/typography/app_text_styles.dart';
import 'package:memox/core/theme/typography/app_typography.dart';

/// The handoff's type roles (`docs/design-system/handoff/memox-flutter-handoff.json`
/// → Foundations · Typography), pinned by hand. The numbers are copied from the
/// handoff, not read from `AppTypography`: a test that read the code's own
/// constants would only prove the code agrees with itself.
///
/// The slot → role table is D1 in `tokyo-component-mapping.md` §9.
void main() {
  final TextTheme texts = buildLightTheme().textTheme;

  void expectRole(
    String slot,
    TextStyle? style, {
    required double size,
    required FontWeight weight,
    required double height,
    required double tracking,
  }) {
    expect(style, isNotNull, reason: '$slot has no style');
    expect(style!.fontSize, size, reason: '$slot size');
    expect(style.fontWeight, weight, reason: '$slot weight');
    expect(style.height, closeTo(height, 0.0001), reason: '$slot leading');
    expect(style.letterSpacing, tracking, reason: '$slot tracking');
    expect(style.fontFamily, 'PlusJakartaSans', reason: '$slot family');
  }

  test('stat — 40 / 600 / 1.0 / -0.64', () {
    for (final (slot, style) in <(String, TextStyle?)>[
      ('displayLarge', texts.displayLarge),
      ('displayMedium', texts.displayMedium),
    ]) {
      expectRole(slot, style,
          size: 40, weight: FontWeight.w600, height: 1.0, tracking: -0.64);
    }
  });

  test('display — 32 / 800 / 1.1 / -0.64', () {
    for (final (slot, style) in <(String, TextStyle?)>[
      ('displaySmall', texts.displaySmall),
      ('headlineLarge', texts.headlineLarge),
    ]) {
      expectRole(slot, style,
          size: 32, weight: FontWeight.w800, height: 1.1, tracking: -0.64);
    }
  });

  test('headline — 24 / 700 / 1.2 / -0.64', () {
    for (final (slot, style) in <(String, TextStyle?)>[
      ('headlineMedium', texts.headlineMedium),
      ('headlineSmall', texts.headlineSmall),
    ]) {
      expectRole(slot, style,
          size: 24, weight: FontWeight.w700, height: 1.2, tracking: -0.64);
    }
  });

  test('title — 20 / 700 / 1.2 / -0.64', () {
    expectRole('titleLarge', texts.titleLarge,
        size: 20, weight: FontWeight.w700, height: 1.2, tracking: -0.64);
  });

  test('body large — 16 / 500 / 1.5 / 0', () {
    for (final (slot, style) in <(String, TextStyle?)>[
      ('titleMedium', texts.titleMedium),
      ('bodyLarge', texts.bodyLarge),
    ]) {
      expectRole(slot, style,
          size: 16, weight: FontWeight.w500, height: 1.5, tracking: 0);
    }
  });

  test('body size at semibold — 14 / 600 / 1.5 / 0 (derived, D1)', () {
    for (final (slot, style) in <(String, TextStyle?)>[
      ('titleSmall', texts.titleSmall),
      ('labelLarge', texts.labelLarge),
    ]) {
      expectRole(slot, style,
          size: 14, weight: FontWeight.w600, height: 1.5, tracking: 0);
    }
  });

  test('body — 14 / 400 / 1.5 / 0', () {
    expectRole('bodyMedium', texts.bodyMedium,
        size: 14, weight: FontWeight.w400, height: 1.5, tracking: 0);
  });

  test('caption family — 12px is the floor for every slot', () {
    expectRole('bodySmall', texts.bodySmall,
        size: 12, weight: FontWeight.w400, height: 1.4, tracking: 0);
    expectRole('labelMedium', texts.labelMedium,
        size: 12, weight: FontWeight.w600, height: 1.4, tracking: 0.72);
    expectRole('labelSmall', texts.labelSmall,
        size: 12, weight: FontWeight.w600, height: 1.4, tracking: 1.2);
  });

  test('no slot renders below the 12px floor', () {
    for (final style in <TextStyle?>[
      texts.displayLarge, texts.displayMedium, texts.displaySmall,
      texts.headlineLarge, texts.headlineMedium, texts.headlineSmall,
      texts.titleLarge, texts.titleMedium, texts.titleSmall,
      texts.bodyLarge, texts.bodyMedium, texts.bodySmall,
      texts.labelLarge, texts.labelMedium, texts.labelSmall,
    ]) {
      expect(style!.fontSize, greaterThanOrEqualTo(12));
    }
  });

  test('dark resolves the same scale as light', () {
    final TextTheme dark = buildDarkTheme().textTheme;
    expect(dark.displayLarge?.fontSize, texts.displayLarge?.fontSize);
    expect(dark.titleLarge?.letterSpacing, texts.titleLarge?.letterSpacing);
    expect(dark.labelSmall?.height, texts.labelSmall?.height);
  });

  test('the component styles speak the same roles', () {
    final styles = buildLightTheme().extension<AppTextStyles>()!;

    expect(styles.heroNumeral.fontSize, 40, reason: 'stat role');
    expect(styles.heroNumeral.fontWeight, FontWeight.w600);
    expect(styles.cardPrompt.fontSize, 32, reason: 'D13');
    expect(styles.cardPrompt.fontWeight, FontWeight.w700);
    expect(styles.cardPrompt.letterSpacing, -0.64);
    expect(styles.sectionLabel.letterSpacing, 1.2, reason: 'ls-section');
    expect(styles.listHeading.letterSpacing, 0.72, reason: 'ls-label');
  });

  // group('the weight registry (A20.1 P1-10)', …) — kept from the old file,
  // pasted here unchanged, then updated in Step 7b.
}
```

- [ ] **Step 2: Run it to see it fail**

Run: `flutter test test/core/theme/typography/app_typography_test.dart`
Expected: FAIL — `displayLarge size` expected 40, actual 57. The test pins numbers only, so it compiles before the builder changes.

- [ ] **Step 3: Rewrite the builder** — in `app_typography.dart`, replace the two family constants, the tracking constants, `cardPrompt*`, `compactCardPromptSize`, `heroNumeralWeight`, `_display`, `_body` and `buildTextTheme` with the code below. Keep `cjkFallbackFamily`, `cjkFallback`, `heroNumeralCapTrim` (D14), `withWeight` and `_wght` exactly as they are, and rewrite the class doc to say "one face, the handoff's seven roles".

```dart
  /// The one face. The handoff sets every role in Plus Jakarta Sans, and the
  /// owner dropped Inter on 2026-09-13.
  static const String family = 'PlusJakartaSans';

  /// `ls-heading` — title, headline, display and stat.
  static const double headingTracking = -0.64;

  /// `ls-label` — the tracking a 12px label carries.
  static const double labelTracking = 0.72;

  /// `ls-section` — the caps overline above a group.
  static const double sectionLabelTracking = 1.2;

  static const double listHeadingTracking = labelTracking;
  static const double stateChipTracking = labelTracking;

  // The handoff's seven sizes and four leadings, named once.
  static const double captionSize = 12;
  static const double bodySize = 14;
  static const double bodyLargeSize = 16;
  static const double titleSize = 20;
  static const double headlineSize = 24;
  static const double displaySize = 32;
  static const double statSize = 40;

  static const double captionHeight = 1.4;
  static const double bodyHeight = 1.5;
  static const double headingHeight = 1.2;
  static const double displayHeight = 1.1;
  static const double statHeight = 1.0;

  /// The card prompt sits on the display size with the headline's weight
  /// (D13): 30 was off the handoff's scale.
  static const double cardPromptSize = displaySize;
  static const double cardPromptHeight = headingHeight;
  static const double cardPromptTracking = headingTracking;
  static const double compactCardPromptSize = headlineSize;

  /// The card prompt's weight — the headline role's (D13). Named, so
  /// `app_text_styles.dart` does not become a second file spelling w700.
  static const FontWeight cardPromptWeight = FontWeight.w700;

  /// The stat role's weight — the hero numeral is the stat role (D14).
  static const FontWeight heroNumeralWeight = FontWeight.w600;

  static TextStyle _role(
    TextStyle? base,
    FontWeight weight, {
    required double size,
    required double height,
    double tracking = 0,
  }) => (base ?? const TextStyle()).copyWith(
    fontFamily: family,
    fontFamilyFallback: cjkFallback,
    fontWeight: weight,
    fontVariations: _wght(weight),
    fontSize: size,
    height: height,
    letterSpacing: tracking,
  );

  static TextTheme buildTextTheme(TextTheme base) {
    TextStyle stat(TextStyle? b) => _role(b, FontWeight.w600,
        size: statSize, height: statHeight, tracking: headingTracking);
    TextStyle display(TextStyle? b) => _role(b, FontWeight.w800,
        size: displaySize, height: displayHeight, tracking: headingTracking);
    TextStyle headline(TextStyle? b) => _role(b, FontWeight.w700,
        size: headlineSize, height: headingHeight, tracking: headingTracking);
    TextStyle bodyLarge(TextStyle? b) =>
        _role(b, FontWeight.w500, size: bodyLargeSize, height: bodyHeight);
    TextStyle bodySemibold(TextStyle? b) =>
        _role(b, FontWeight.w600, size: bodySize, height: bodyHeight);

    return base.copyWith(
      displayLarge: stat(base.displayLarge),
      displayMedium: stat(base.displayMedium),
      displaySmall: display(base.displaySmall),
      headlineLarge: display(base.headlineLarge),
      headlineMedium: headline(base.headlineMedium),
      headlineSmall: headline(base.headlineSmall),
      titleLarge: _role(base.titleLarge, FontWeight.w700,
          size: titleSize, height: headingHeight, tracking: headingTracking),
      titleMedium: bodyLarge(base.titleMedium),
      titleSmall: bodySemibold(base.titleSmall),
      bodyLarge: bodyLarge(base.bodyLarge),
      bodyMedium:
          _role(base.bodyMedium, FontWeight.w400, size: bodySize, height: bodyHeight),
      bodySmall: _role(base.bodySmall, FontWeight.w400,
          size: captionSize, height: captionHeight),
      labelLarge: bodySemibold(base.labelLarge),
      labelMedium: _role(base.labelMedium, FontWeight.w600,
          size: captionSize, height: captionHeight, tracking: labelTracking),
      labelSmall: _role(base.labelSmall, FontWeight.w600,
          size: captionSize, height: captionHeight, tracking: sectionLabelTracking),
    );
  }
```

- [ ] **Step 4: Point `AppTextStyles.from` at the new names** — in `app_text_styles.dart` change `promptBase` to `(texts.headlineMedium ?? const TextStyle()).copyWith(fontFamily: AppTypography.family, …)` with the same four fields, `cardPrompt` weight `FontWeight.w600` → `AppTypography.cardPromptWeight`, and `heroNumeral`'s base `texts.headlineLarge` → `texts.displayLarge`. Leave the other styles' code alone — the constants moved underneath them.

- [ ] **Step 5: Remove Inter**

```bash
grep -rn "Inter" pubspec.yaml widgetbook/pubspec.yaml test/flutter_test_config.dart lib --include=*.dart --include=*.yaml
grep -rnE "AppTypography\.(displayFamily|bodyFamily)" lib test widgetbook/lib integration_test
```

Delete the `- family: Inter` block (both pubspecs), the `'Inter': 'assets/fonts/Inter-Variable.ttf',` map entry and the "Loads the bundled Inter and…" wording in `flutter_test_config.dart`, then `git rm assets/fonts/Inter-Variable.ttf`. Replace every `AppTypography.displayFamily` / `AppTypography.bodyFamily` hit with `AppTypography.family`. Re-run both greps — expected: the first prints only the CJK comment lines that mention "Inter" in prose (reword them), the second prints nothing.

- [ ] **Step 6: Run the typography tests**

```bash
flutter pub get
flutter test test/core/theme/typography/
```

Expected: PASS. If `cjk_fallback_test` asserts two families, collapse its expectation to `AppTypography.family`.

- [ ] **Step 7: Run the theme suites that pin text metrics**

```bash
flutter test test/core/theme test/shared
```

Every failure here is a pinned old metric (e.g. `component_theme_typography_test`, `mx_search_field_test`, `mx_section_label_test`, `app_bold_text_*`). For each: confirm the new value equals a row of the slot table, then move the expectation to it. A failure that is not a text metric is a real regression — stop and debug it (superpowers:systematic-debugging).

- [ ] **Step 7b: Move the two face-bound pins**

1. `app_typography_test.dart` · `the weight registry (A20.1 P1-10)`. The scale now spends five weights and the heavy ones move. Rename the per-theme test to `'$name reaches exactly the five weights, and every w700 and w800 is named'`; expect `{w400, w500, w600, w700, w800}`; collect `bold` from entries whose weight is `w700` **or** `w800`; set `boldAllowlist` to the D1 heading slots plus the buttons — `'displaySmall'`, `'headlineLarge'`, `'headlineMedium'`, `'headlineSmall'`, `'titleLarge'`, `'textStyles.cardPrompt'`, `'timePicker.hourMinuteTextStyle'` (it reads `displaySmall`), `'filledButton.textStyle'`, `'outlinedButton.textStyle'`, `'textButton.textStyle'`. `displayLarge`, `displayMedium` and `textStyles.heroNumeral` leave the list (stat is w600). Run it, and reconcile any remaining name against the D1 table — never add a name the table does not make heavy. In `the sources that may spell w700 are exactly the named ones` keep the three files and add a twin assertion for `'FontWeight.w800'` whose only speller is `app_typography.dart`.
2. `deck_list_rhythm_golden_test.dart:217`: `_interCapHeight = 0.727` is Inter's cap height, and the band geometry at line ~332 measures caps with it. Rename it `_capHeight` and set it to Plus Jakarta Sans's `0.741` — derived the way `AppTypography.heroNumeralCapTrim` records it (digit ink 23.7px in a 32px em) — and rewrite its doc. If that test's assertion still fails when P4 authors goldens on Linux, measure the cap ink of `YOUR DECKS` on the re-authored golden and pin that figure; do not widen the tolerance.

- [ ] **Step 8: Commit**

```bash
git add -A lib test integration_test pubspec.yaml pubspec.lock widgetbook/pubspec.yaml assets/fonts
git commit -m "feat(theme): one family and the handoff's seven type roles (M100.xx)"
```

### Task 3: Radius, icon and spacing ladders on the handoff's names; pressed at 12%

**Files:**
- Modify: `lib/core/theme/foundations/app_radius.dart`, `app_icon_size.dart`, `app_spacing.dart`
- Modify: `lib/shared/widgets/mx_icon.dart` (`MxIconSize`)
- Modify: `lib/core/theme/states/app_interaction_states.dart` (`stateLayerPressed`)
- Modify: every caller the compiler names (renames only)
- Modify: `widgetbook/lib/tokens/scale_sections.dart`
- Test: `test/core/theme/foundations/design_tokens_test.dart` (ladders, the two old `AppSpacing` pins, the new pressed pin)

**Interfaces:**
- Produces: `AppRadius.{xs 4, sm 8, md 12, lg 16, card 20, xl 24, xxl 28, full 999}` (`pill` → `full`, old `xl` 20 → `card`); `AppIconSize.{xs 16, sm 20, md 24, lg 32, xl 40}` (old `sm` → `xs`, `mdCompact` → `sm`, old `lg` 40 → `xl`); `MxIconSize.{xs, sm, md, lg, xl}` mirroring it; `AppSpacing.card = 20`, `AppSpacing.xxxl = 48`; `AppStateOpacity.stateLayerPressed = 0.12`.

A rename that reuses a name (`xl`, `sm`, `lg`) is done in two passes so no caller silently changes value: pass A moves every caller off the reused name and compiles; pass B introduces the new meaning.

- [ ] **Step 1: Write the failing ladder test** — in `design_tokens_test.dart` replace the radius ordering block (the four `expect(AppRadius…` lines) and add the icon and spacing ladders:

```dart
    test('radius ladder is the handoff\'s', () {
      expect(
        <double>[AppRadius.xs, AppRadius.sm, AppRadius.md, AppRadius.lg,
            AppRadius.card, AppRadius.xl, AppRadius.xxl, AppRadius.full],
        <double>[4, 8, 12, 16, 20, 24, 28, 999],
      );
    });

    test('icon ladder is the handoff\'s', () {
      expect(
        <double>[AppIconSize.xs, AppIconSize.sm, AppIconSize.md,
            AppIconSize.lg, AppIconSize.xl],
        <double>[16, 20, 24, 32, 40],
      );
      expect(
        MxIconSize.values.map((s) => s.dp),
        <double>[16, 20, 24, 32, 40],
      );
    });

```

Add `import 'package:memox/shared/widgets/mx_icon.dart';` if absent (`MxIconSize` exposes its size as `dp`).

The same file's `AppSpacing` group pins the old ladder twice. Rename `is exactly the 4/8/12/16/24/32 scale` (line 17) to `is exactly the handoff's 4/8/12/16/20/24/32/48 scale` with `expect(AppSpacing.scale, <double>[4, 8, 12, 16, 20, 24, 32, 48]);`, and add `AppSpacing.card` (after `lg`) and `AppSpacing.xxxl` (after `xxl`) to the `declared` list of `every declared constant is on the scale` (lines 23–38).

- [ ] **Step 2: Run to fail**

Run: `flutter test test/core/theme/foundations/design_tokens_test.dart`
Expected: compile FAIL — `AppRadius.xs` / `AppRadius.card` not defined.

- [ ] **Step 3: Pass A — move callers off reused names**

In `app_radius.dart` rename `xl` → `card` and `pill` → `full` (definitions). In `app_icon_size.dart` rename `sm` → `xs` and `lg` → `xl`. In `mx_icon.dart` rename the enum values `sm` → `xs`, `lg` → `xl`. Then the callers:

```bash
FILES=$(grep -rlE "AppRadius\.(xl|pill)\b|(AppIconSize|MxIconSize)\.(sm|lg)\b" lib test widgetbook/lib integration_test)
sed -i -E 's/AppRadius\.xl\b/AppRadius.card/g; s/AppRadius\.pill\b/AppRadius.full/g; s/(AppIconSize|MxIconSize)\.sm\b/\1.xs/g; s/(AppIconSize|MxIconSize)\.lg\b/\1.xl/g' $FILES
flutter analyze --no-fatal-infos
grep -rnE "AppRadius\.(xl|pill)\b|(AppIconSize|MxIconSize)\.(sm|lg)\b" lib test widgetbook/lib integration_test
```

Expected: `No issues found!`, then the grep prints nothing. `[AppRadius.xl]`-style doc references are renamed by the same sed; reread any doc sentence that now says "card" where it meant "the focal surface" and fix the prose.

- [ ] **Step 4: Pass B — introduce the handoff meanings.** Replace the bodies of the three ladders:

`lib/core/theme/foundations/app_radius.dart`

```dart
/// Corner radii — the handoff's radius roles, on the handoff's names.
abstract final class AppRadius {
  /// Badge, micro surface.
  static const double xs = 4;

  /// Small tile, icon tile.
  static const double sm = 8;

  /// Button, input.
  static const double md = 12;

  /// FAB.
  static const double lg = 16;

  /// Card, dialog, the bottom sheet's top corners — the roomiest common
  /// surface (D12: the Dialog and BottomSheet specs name 20 over 16 and 24).
  static const double card = 20;

  /// The handoff's `radius-xl`.
  static const double xl = 24;

  /// A large focal surface.
  static const double xxl = 28;

  /// Pill — chip, avatar, toggle track.
  static const double full = 999;
}
```

`lib/core/theme/foundations/app_icon_size.dart`

```dart
/// Icon sizes — the handoff's five roles. Visual size only; the touch area is
/// `AppSizing.touchTarget`, never a larger glyph.
abstract final class AppIconSize {
  /// Inline in body text, compact utility.
  static const double xs = 16;

  /// Compact control: dense rows, metadata, the FAB glyph, in-content icon
  /// buttons.
  static const double sm = 20;

  /// Standard action: app-bar and navigation actions.
  static const double md = 24;

  /// Large emphasis: feature tiles.
  static const double lg = 32;

  /// Illustrative: empty and error states, hero marks.
  static const double xl = 40;
}
```

Rename `mdCompact` → `sm` in `mx_icon.dart`'s enum and add `lg(AppIconSize.lg)` between `md` and `xl`, so the enum reads `xs, sm, md, lg, xl`. Then:

```bash
FILES=$(grep -rlE "(AppIconSize|MxIconSize)\.mdCompact\b" lib test widgetbook/lib integration_test)
sed -i -E 's/(AppIconSize|MxIconSize)\.mdCompact\b/\1.sm/g' $FILES
```

In `app_spacing.dart` add, between `lg` and `xl`:

```dart
  /// Card and sheet interior (`space-card`).
  static const double card = 20;
```

after `xxl`:

```dart
  /// Page-end clearance: the scroll tail above pinned chrome.
  static const double xxxl = 48;
```

change `scale` to `<double>[xs, sm, md, lg, card, xl, xxl, xxxl]`, and the class doc's "Six steps" to "Eight steps — the handoff's".

- [ ] **Step 5: Pressed state layer** — in `app_interaction_states.dart`, `static const double stateLayerPressed = 0.10;` → `0.12;` with the doc line "the handoff's `op-press`". No test pins that number today (`app_interaction_states_test.dart` only compares states), so add to `design_tokens_test.dart`: `test('pressed state layer is the handoff op-press', () => expect(AppStateOpacity.stateLayerPressed, 0.12));` (import `app_interaction_states.dart`).

- [ ] **Step 6: Catalogue** — in `widgetbook/lib/tokens/scale_sections.dart` list `AppSpacing` `xs sm md lg card xl xxl xxxl`, `AppRadius` `xs sm md lg card xl xxl full`, `AppIconSize` `xs sm md lg xl` (one `_SpacingBar` / `_RadiusBox` / `_IconSizeDemo` per value, same widget as today).

- [ ] **Step 7: Run**

```bash
flutter analyze --no-fatal-infos
flutter test test/core/theme test/shared
```

Expected: analyze clean; the ladder tests PASS. Other failures are expectations pinned to an old rung value (e.g. a test asserting a 16px glyph that is now `xs`): move each to the new value after checking the rendered size did not change. A pixel size that *did* change is a rename mistake — revert that file and redo pass A/B for it.

- [ ] **Step 8: Commit**

```bash
git add -A lib test widgetbook/lib
git commit -m "feat(theme): radius, icon and spacing ladders on the handoff's names (M100.xx)"
```

### Task 4: Screen composition — a 16 gutter everywhere and a 48 tail

**Files:**
- Modify: `lib/shared/widgets/mx_content_shell.dart` (`mxScreenGutter`)
- Modify: `lib/shared/widgets/mx_scroll_end_inset.dart` (`mxScrollEndInsetOf`)
- Test: `test/shared/widgets/mx_content_shell_geometry_test.dart`, `test/shared/widgets/mx_responsive_test.dart`, any test the grep in Step 1 lists

**Interfaces:**
- Consumes: `AppSpacing.lg`, `AppSpacing.xxxl` (Task 3).
- Produces: `mxScreenGutter(context) == AppSpacing.lg` at every width; `mxScrollEndInsetOf(context) == AppSpacing.xxxl` on a screen without a floating action (the FAB branch changes in Task 8).

- [ ] **Step 1: Find the pins**

```bash
grep -rnE "mxScreenGutter|mxScrollEndInsetOf|AppSpacing\.md.*compact|compact.*AppSpacing\.md" test
```

- [ ] **Step 2: Write the failing test** — add to `mx_content_shell_geometry_test.dart`:

```dart
  testWidgets('the gutter stays 16 on a compact phone (handoff Foundations)', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    late double gutter;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildLightTheme(),
        home: Builder(builder: (context) {
          gutter = mxScreenGutter(context);
          return const SizedBox();
        }),
      ),
    );

    expect(gutter, AppSpacing.lg);
  });
```

and to the test that covers `mxScrollEndInsetOf` without a scope (create `test/shared/widgets/mx_scroll_end_inset_test.dart` — none exists; Task 8 appends to it):

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/shared/widgets/mx_scroll_end_inset.dart';

void main() {
  testWidgets('a list with no floating action ends 48 above the chrome', (
    tester,
  ) async {
    late double inset;
    await tester.pumpWidget(Builder(builder: (context) {
      inset = mxScrollEndInsetOf(context);
      return const SizedBox();
    }));

    expect(inset, AppSpacing.xxxl);
  });
}
```

- [ ] **Step 3: Run to fail**

Run: `flutter test test/shared/widgets/mx_content_shell_geometry_test.dart test/shared/widgets/mx_scroll_end_inset_test.dart`
Expected: FAIL — gutter `12.0`, inset `16.0`.

- [ ] **Step 4: Implement**

`mx_content_shell.dart`:

```dart
/// The screen gutter: 16 at every width. The handoff's compact-phone rule is
/// "the content column narrows; the gutter stays 16".
double mxScreenGutter(BuildContext context) => AppSpacing.lg;
```

Replace the old doc block above it (the two-breakpoint explanation) with that doc, remove the now-unused `AppBreakpoints` import only if analyze flags it. The two-tier rule is also narrated elsewhere and goes stale: rewrite `MxContentShell.padding`'s doc (`mx_content_shell.dart:116-117`) and the comments at `study_session_screen.dart:180`, `card_list_body_widget.dart:56` and `library_search_body_widget.dart:100`.

`mx_scroll_end_inset.dart`, in `mxScrollEndInsetOf`: `return AppSpacing.lg;` → `return AppSpacing.xxxl;`.

- [ ] **Step 5: Run, move pins** — `flutter test test/shared test/features --exclude-tags golden`. Tests pinning the compact 12 gutter or a 16 list tail move to 16 / 48; nothing else should change.

- [ ] **Step 6: Commit**

```bash
git add -A lib/shared test
git commit -m "feat(design-system): one 16 gutter and a 48 scroll tail (M100.xx)"
```

- [ ] **Step 7: Close Phase 1** — P3 (with integration suite), P4, P5, P6. WBS goal: "Nền tảng theo handoff: một family Plus Jakarta Sans với bảy vai chữ, thang radius/icon/spacing mang tên handoff, pressed 12%, gutter 16 và đuôi cuộn 48."

---

## Phase 2 — buttons and actions (section B)

### Task 5: Compact button paints 36; loading holds its width

**Files:**
- Modify: `lib/core/theme/foundations/app_sizing.dart` (`controlCompact` 40 → `buttonCompact` 36)
- Modify: callers the compiler names (`lib/shared/widgets/mx_action_button.dart`, `lib/core/theme/components/actions/app_icon_button_theme.dart`)
- Test: `test/shared/widgets/mx_action_button_size_test.dart`, `test/shared/widgets/mx_action_button_state_matrix_test.dart`, `test/core/theme/foundations/app_sizing_test.dart`, `test/shared/widgets/mx_components_test.dart:118-145` (`compact draws 40` hardcodes the literal), `test/shared/widgets/mx_tonal_and_outlined_test.dart` (renamed constant, caught by the sed)

**Interfaces:**
- Produces: `AppSizing.buttonCompact = 36`. `MxActionButtonSize.compact` paints 36 and keeps a 48 target.

- [ ] **Step 1: Write the failing tests** — append to `mx_action_button_size_test.dart` (reuse its imports; add `app_sizing.dart`, `app_icon_size.dart` if missing):

```dart
  testWidgets('compact paints 36 and keeps a 48 target (handoff button-sm)', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildLightTheme(),
        home: Scaffold(
          body: Center(
            child: MxActionButton(
              label: 'Study',
              size: MxActionButtonSize.compact,
              onPressed: () {},
            ),
          ),
        ),
      ),
    );

    final painted = find
        .descendant(of: find.byType(MxActionButton), matching: find.byType(Material))
        .first;
    expect(tester.getSize(painted).height, AppSizing.buttonCompact);
    expect(
      tester.getSize(find.byType(MxActionButton)).height,
      greaterThanOrEqualTo(AppSizing.touchTarget),
    );
  });

  testWidgets('loading swaps the label for a 16px spinner and holds the width', (
    tester,
  ) async {
    Widget button({required bool isLoading}) => MaterialApp(
      theme: buildLightTheme(),
      home: Scaffold(
        body: Center(
          child: MxActionButton(
            label: 'Save changes',
            isLoading: isLoading,
            onPressed: () {},
          ),
        ),
      ),
    );

    await tester.pumpWidget(button(isLoading: false));
    final width = tester.getSize(find.byType(MxActionButton)).width;

    await tester.pumpWidget(button(isLoading: true));
    await tester.pump();

    expect(tester.getSize(find.byType(MxActionButton)).width, width);
    final spinner = find.byType(CircularProgressIndicator);
    expect(spinner, findsOneWidget);
    expect(tester.getSize(spinner).width, AppIconSize.xs);
  });
```

If `MxActionButton`'s size parameter is not named `size`, use its real name (read the constructor).

- [ ] **Step 2: Run to fail**

Run: `flutter test test/shared/widgets/mx_action_button_size_test.dart`
Expected: compile FAIL on `AppSizing.buttonCompact`.

- [ ] **Step 3: Implement** — in `app_sizing.dart` replace the `controlCompact` member and its doc with:

```dart
  /// The handoff's compact button (`size-button-sm`): paints 36, and
  /// `MaterialTapTargetSize.padded` restores [touchTarget] around it.
  static const double buttonCompact = 36;
```

```bash
FILES=$(grep -rlE "AppSizing\.controlCompact\b" lib test widgetbook/lib)
sed -i -E 's/AppSizing\.controlCompact\b/AppSizing.buttonCompact/g' $FILES
flutter analyze --no-fatal-infos
```

If the loading test fails on the spinner size, set the busy spinner's `SizedBox.square(dimension: …)` in `mx_action_button.dart` to `AppIconSize.xs`; if it fails on width, the busy branch must keep the label in the tree with `Opacity(opacity: 0)` / `Visibility(maintainSize: true, …)` under a centred spinner — use whichever mechanism the file already uses for `shouldKeepLabelWhileLoading`.

- [ ] **Step 4: Run** — `flutter test test/shared/widgets test/core/theme/foundations/app_sizing_test.dart`. Move `app_sizing_test`'s `controlCompact` assertions to `buttonCompact` (still `< touchTarget`). In `mx_components_test.dart` rename `compact draws 40 and still hits 48` → `compact draws 36 and still hits 48` and `expect(drawn.height, 40)` → `expect(drawn.height, AppSizing.buttonCompact)`.

- [ ] **Step 5: Commit**

```bash
git add -A lib test widgetbook/lib
git commit -m "feat(design-system): compact button paints 36, loading holds width (M100.xx)"
```

### Task 6: Secondary actions become Tonal; cancel stays Outlined

**Files:** the call sites in the table (variant argument only), `docs/design-system/tokyo-component-mapping.md` §2 (TonalButton row).

**Interfaces:**
- Consumes: `MxActionButtonVariant.tonal` (exists; `MxFilledPair.tonal` = `secondaryContainer` / `onSecondaryContainer`, which is the handoff's TonalButton).
- Produces: nothing new. The rating buttons (`study_card_face_section_widget.dart:414`, `recall_timer_pieces_widget.dart:244,251`) are **not** touched here — Task 28 owns them.

Rule (D6): Outlined = dismiss, back, cancel, clear, leave, or a low-emphasis entry into something dangerous. Tonal = a forward alternative next to the primary.

| File:line (at `dcd22f32`) | Label | Variant |
|---|---|---|
| `card/…/overlays/card_tag_filter_sheet_widget.dart:219` | `tagFilterClearAction` | secondary (keep) |
| `card/…/overlays/tag_rename_widget.dart:179` | `commonCancelAction` | keep |
| `card/…/sections/card_create_action_bar_widget.dart:65` | `cardEditorSaveAndAdd` | **tonal** |
| `card/…/sections/card_editor_action_bar_widget.dart:78` | `cardEditorCancelAction` | keep |
| `card/…/sections/card_export_action_bar_widget.dart:57, 68` | close / cancel | keep |
| `card/…/sections/card_filter_bar_widget.dart:229` | tag filter command | **tonal** |
| `card/…/sections/card_import_action_bar_widget.dart:194, 221, 250, 297` | back / back to preview | keep |
| `card/…/sections/card_import_action_bar_widget.dart:279` | `cardImportAnotherAction` | **tonal** |
| `card/…/sections/card_trash_action_widget.dart:89` | `cardEditorTrashAction` | keep |
| `deck/…/overlays/deck_form_widget.dart:211` | cancel | keep |
| `deck/…/overlays/deck_reset_progress_widget.dart:188` | cancel | keep |
| `deck/…/overlays/deck_scheduler_change_widget.dart:124, 236` | cancel | keep |
| `deck/…/overlays/deck_scheduler_change_widget.dart:140` | `deckResetProgressAction` | keep |
| `study/…/items/study_home_deck_item_widget.dart:155` | `studyHomeStudyAction` | **tonal** |
| `study/…/overlays/study_resume_widget.dart:74, 80` | `studyStartLearning` / `studyStartReview` (the `studyResumeContinue` button above them has no variant and stays primary) | **tonal** |
| `study/…/sections/fill_answer_section_widget.dart:240` | `studyShowHint` | keep |
| `study/…/sections/study_blocked_section_widget.dart:42` | `studyLeaveSession` | keep |
| `study/…/sections/study_entry_section_widget.dart:122` | `studyStartReview` | **tonal** |
| `shared/widgets/mx_confirm_dialog.dart:159`, `mx_form_dialog.dart:109` | cancel | keep |
| `shared/widgets/mx_empty_state.dart:104` | secondary action | **tonal** |

Line numbers drift; locate each by the label.

- [ ] **Step 1: Find the tests that pin these variants**

```bash
grep -rnE "OutlinedButton|MxActionButtonVariant\.secondary" test/features/study test/features/card test/shared/widgets/mx_empty_state* test/shared/widgets/mx_components_test.dart | cut -c1-160
```

- [ ] **Step 2: Write the failing test** — add to `test/shared/widgets/mx_components_test.dart`:

```dart
  testWidgets('an empty state\'s second action is tonal, not outlined', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildLightTheme(),
        home: Scaffold(
          body: MxEmptyState(
            title: 'No decks',
            actionLabel: 'Starter library',
            onAction: () {},
            secondaryActionLabel: 'New deck',
            onSecondaryAction: () {},
          ),
        ),
      ),
    );

    expect(find.byType(OutlinedButton), findsNothing);
    expect(find.byType(FilledButton), findsNWidgets(2));
  });
```

- [ ] **Step 3: Run to fail** — `flutter test test/shared/widgets/mx_components_test.dart` → FAIL (`OutlinedButton` found).

- [ ] **Step 4: Change the eight `tonal` rows** — `variant: MxActionButtonVariant.secondary` → `variant: MxActionButtonVariant.tonal`. Touch nothing else on those lines.

- [ ] **Step 5: Run** — `flutter test test/shared test/features/card test/features/study test/features/deck --exclude-tags golden`. Move each pin that asserted `OutlinedButton` at a tonal row to `FilledButton`.

- [ ] **Step 6: Docs + commit** — in `tokyo-component-mapping.md` §2 replace the FilledTonalButton row's MemoX cell "**không dựng**" with "= (`MxActionButtonVariant.tonal`, handoff redesign D6: forward alternatives)".

```bash
git add -A lib test docs/design-system/tokyo-component-mapping.md
git commit -m "feat(design-system): secondary forward actions become tonal (M100.xx)"
```

### Task 7: Icon button — 36 ink circle, 20 glyph, 48 target, primary tint

**Files:**
- Modify: `lib/core/theme/foundations/app_sizing.dart` (add `iconButtonInk`)
- Modify: `lib/core/theme/states/app_interaction_states.dart` (`AppStateOpacity.iconTintLight/Dark`, `AppInteractionStates.iconOverlay`)
- Modify: `lib/core/theme/components/actions/app_icon_button_theme.dart`
- Modify: `lib/shared/widgets/mx_icon_button.dart` (`isCompact` → `placement`)
- Modify: app-bar callers (Step 5), `lib/features/deck/presentation/screens/deck_list_screen.dart` comment at the two bar buttons
- Test: Create `test/shared/widgets/mx_icon_button_geometry_test.dart`

**Interfaces:**
- Produces: `AppSizing.iconButtonInk = 36`; `enum MxIconButtonPlacement { content, bar }`; `MxIconButton({required icon, required semanticLabel, required onPressed, tooltip, placement = MxIconButtonPlacement.content, tone, shape})` — `isCompact` is gone. Glyph `AppIconSize.sm` (20) for `content`, `AppIconSize.md` (24) for `bar` (D16).

- [ ] **Step 1: Write the failing test** — `test/shared/widgets/mx_icon_button_geometry_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/foundations/app_icon_size.dart';
import 'package:memox/core/theme/foundations/app_sizing.dart';
import 'package:memox/core/theme/states/app_interaction_states.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';

/// Handoff IconButton (B): a 36 ink box, a 20 glyph, a 48 hit target, and an
/// 8% primary tint behind the glyph (14% in dark). App-bar actions keep the
/// Foundations' 24 glyph (D16).
void main() {
  Future<void> pump(
    WidgetTester tester, {
    MxIconButtonPlacement placement = MxIconButtonPlacement.content,
  }) => tester.pumpWidget(
    MaterialApp(
      theme: buildLightTheme(),
      home: Scaffold(
        body: Center(
          child: MxIconButton(
            icon: Icons.search,
            semanticLabel: 'Search',
            onPressed: () {},
            placement: placement,
          ),
        ),
      ),
    ),
  );

  testWidgets('paints a 36 circle inside a 48 target', (tester) async {
    await pump(tester);

    expect(tester.getSize(find.byType(IconButton)), const Size.square(48));
    final ink = find
        .descendant(of: find.byType(IconButton), matching: find.byType(Material))
        .first;
    expect(tester.getSize(ink), const Size.square(AppSizing.iconButtonInk));
    expect(tester.widget<Material>(ink).shape, isA<CircleBorder>());
  });

  testWidgets('content glyph is 20, bar glyph is 24', (tester) async {
    await pump(tester);
    expect(tester.widget<Icon>(find.byType(Icon)).size, AppIconSize.sm);

    await pump(tester, placement: MxIconButtonPlacement.bar);
    expect(tester.widget<Icon>(find.byType(Icon)).size, AppIconSize.md);
  });

  test('hover and press tint primary at 8% light, 14% dark', () {
    for (final (theme, alpha) in <(ThemeData, double)>[
      (buildLightTheme(), AppStateOpacity.iconTintLight),
      (buildDarkTheme(), AppStateOpacity.iconTintDark),
    ]) {
      final overlay = theme.iconButtonTheme.style!.overlayColor!;
      final expected = theme.colorScheme.primary.withValues(alpha: alpha);
      expect(overlay.resolve(<WidgetState>{WidgetState.pressed}), expected);
      expect(overlay.resolve(<WidgetState>{WidgetState.hovered}), expected);
    }
    expect(AppStateOpacity.iconTintLight, 0.08);
    expect(AppStateOpacity.iconTintDark, 0.14);
  });
}
```

- [ ] **Step 2: Run to fail** — `flutter test test/shared/widgets/mx_icon_button_geometry_test.dart` → compile FAIL (`MxIconButtonPlacement`, `iconButtonInk`, `iconTintLight`).

- [ ] **Step 3: Tokens** — `app_sizing.dart`, after `buttonCompact`:

```dart
  /// The handoff icon button's painted circle (`size-icon-btn`). The target
  /// around it is still [touchTarget]: expand the hit area, never the ink.
  static const double iconButtonInk = 36;
```

`app_interaction_states.dart`, in `AppStateOpacity`:

```dart
  /// Handoff IconButton: the primary tint behind the glyph on hover and press.
  static const double iconTintLight = 0.08;

  /// The same tint in dark, where 8% of the lifted primary disappears.
  static const double iconTintDark = 0.14;
```

and make `AppInteractionStates.iconOverlay(scheme)` resolve hovered **and** pressed to `scheme.primary.withValues(alpha: scheme.brightness == Brightness.dark ? AppStateOpacity.iconTintDark : AppStateOpacity.iconTintLight)`. Keep its focused branch exactly as it is; return `null` for every other state.

- [ ] **Step 4: Theme and widget** — `app_icon_button_theme.dart`, `buildIconButtonTheme`:

```dart
IconButtonThemeData buildIconButtonTheme(
  ColorScheme scheme,
  AppSemanticColors semantic,
) => IconButtonThemeData(
  style:
      IconButton.styleFrom(
        minimumSize: const Size.square(AppSizing.iconButtonInk),
        fixedSize: const Size.square(AppSizing.iconButtonInk),
        padding: EdgeInsets.zero,
        tapTargetSize: MaterialTapTargetSize.padded,
        iconSize: AppIconSize.sm,
        foregroundColor: scheme.onSurfaceVariant,
        disabledForegroundColor: semantic.onDisabled,
        shape: const CircleBorder(),
      ).copyWith(
        overlayColor: AppInteractionStates.iconOverlay(scheme),
        side: WidgetStateProperty.resolveWith((states) {
          if (!states.contains(WidgetState.focused)) return null;
          return AppInteractionStates.focusIndicator(scheme);
        }),
      ),
);
```

In `buildOutlinedIconButtonStyle` change `AppSizing.buttonCompact` (Task 5's name for `controlCompact`) → `AppSizing.iconButtonInk`. Add the `app_icon_size.dart` import; drop `app_radius.dart` if now unused.

`mx_icon_button.dart` — add the enum above the class and replace the widget's fields and `build`:

```dart
/// Where the button sits, which decides its glyph (D16): the handoff's
/// IconButton draws 20; its Foundations give app-bar and navigation actions 24.
enum MxIconButtonPlacement {
  /// Rows, cards, fields, sheets — everything that is not the top bar.
  content,

  /// An action in the screen's app bar.
  bar,
}
```

```dart
  const MxIconButton({
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
    this.tooltip,
    this.placement = MxIconButtonPlacement.content,
    this.tone = MxIconButtonTone.standard,
    this.shape = MxIconButtonShape.plain,
    super.key,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback? onPressed;
  final String? tooltip;
  final MxIconButtonPlacement placement;
  final MxIconButtonTone tone;
  final MxIconButtonShape shape;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      style: switch (shape) {
        MxIconButtonShape.plain => null,
        MxIconButtonShape.outlined => buildOutlinedIconButtonStyle(
          context.colors,
          context.semanticColors,
        ),
      },
      color: switch (tone) {
        MxIconButtonTone.standard => null,
        MxIconButtonTone.warning => context.semanticColors.warningInk,
      },
      tooltip: tooltip ?? semanticLabel,
      icon: Icon(
        icon,
        size: switch (placement) {
          MxIconButtonPlacement.content => AppIconSize.sm,
          MxIconButtonPlacement.bar => AppIconSize.md,
        },
        semanticLabel: semanticLabel,
      ),
    );
  }
```

Remove the now-unused `app_sizing.dart` import if analyze flags it; keep the existing doc comments on the enums and class, rewriting the `isCompact` paragraph into the placement rule.

- [ ] **Step 5: Callers**

```bash
flutter analyze --no-fatal-infos            # every `isCompact:` on MxIconButton is now an error — delete the argument
grep -rn -B2 -A6 "MxIconButton(" lib/features lib/shared --include=*.dart | grep -nE "actions:|leading:|MxIconButton\(" | cut -c1-160
```

Add `placement: MxIconButtonPlacement.bar` to every `MxIconButton` that is an element of an `actions:` list or the `leading:` of an `AppBar` / `MxContentShell` / contextual selection bar — at `dcd22f32` that is in `card_detail_screen.dart`, `card_editor_screen.dart`, `card_editor_save_shortcut_widget.dart`, `card_import_screen.dart`, `card_list_screen.dart`, `card_selection_bar_widget.dart`, `deck_list_screen.dart`, `study_entry_screen.dart`, `trash_screen.dart`. Everything else stays `content`: `card_flag_toggle_widget.dart`, `card_import_source_summary_widget.dart`, `card_tag_section_widget.dart`, `deck_tile_widget.dart`, `study_swipe_deck_widget.dart`, `trash_row_widget.dart`, `mx_session_top_bar.dart`, `mx_text_field.dart`. Verify each classification by opening the line. In `deck_list_screen.dart` replace the last sentence of the comment above the two bar buttons with: "Handoff redesign: app-bar actions keep the 24 glyph (D16) inside the 36 ink circle."

- [ ] **Step 6: Run** — `flutter test test/shared test/core/theme test/features --exclude-tags golden`. `m3_role_binding_guard_test` should stay green (roles unchanged). Geometry pins on the old rounded-square 48 box move to the 36 circle. `mx_session_top_bar.dart` passed `isCompact: true` to get a tight 48 box with zero padding; the new theme gives the same 48 layout box (`tapTargetSize: padded`, `padding: EdgeInsets.zero`) with the 20 glyph centred, which is what its `_kRowFixedWidth` and `_kGlyphInset` assume. Prove it: `flutter test test/features/study/presentation/study_session_chrome_test.dart` passes unchanged. If it fails on the close button's box, read the measured rect before touching the bar — the constants there are derived, not chosen.

- [ ] **Step 7: Docs + commit** — `tokyo-component-mapping.md` §2 IconButton row gains "36 ink `CircleBorder`, glyph 20 (bar 24), hover/press `primary` 8% / 14% dark (M100.xx)"; §3's `MuiIconButton` row is superseded — strike it through with a note pointing at §2.

```bash
git add -A lib test docs/design-system/tokyo-component-mapping.md
git commit -m "feat(design-system): handoff icon button — 36 ink circle, 20 glyph (M100.xx)"
```

### Task 8: Extended FAB — 52 tall, primary, shadow-fab

**Files:**
- Modify: `lib/core/theme/foundations/app_sizing.dart` (`floatingAction` 56 → `fab` 52), `app_spacing.dart` (`fabScrollClearance`)
- Modify: `lib/core/theme/components/actions/app_fab_theme.dart`, `lib/shared/widgets/mx_fab.dart`
- Test: Create `test/shared/widgets/mx_fab_test.dart`; modify `test/core/theme/contracts/m3_role_bindings.dart`, `test/shared/widgets/mx_scroll_end_inset_test.dart`, `test/core/theme/components/component_depth_and_state_test.dart:259-264` (`the FAB floats` expects elevation > 0 — Step 7)

**Interfaces:**
- Produces: `AppSizing.fab = 52`; `AppSpacing.fabScrollClearance = AppSizing.fab + AppSpacing.lg + AppSpacing.xxxl` (D15); `MxFab` renders `FloatingActionButton.extended` with its `label` visible (the constructor is unchanged: `icon`, `label`, `onPressed`).

- [ ] **Step 1: Write the failing test** — `test/shared/widgets/mx_fab_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/foundations/app_elevation.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_sizing.dart';
import 'package:memox/shared/widgets/mx_fab.dart';

/// Handoff FloatingActionButton (B): extended only, 52 tall, radius 16,
/// `primary` / `onPrimary`, `shadow-fab`. The kit has no circular variant.
void main() {
  for (final (name, theme) in <(String, ThemeData)>[
    ('light', buildLightTheme()),
    ('dark', buildDarkTheme()),
  ]) {
    testWidgets('$name: extended, labelled, 52 tall, primary, shadow-fab', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(
            floatingActionButton: MxFab(
              icon: Icons.add,
              label: 'New deck',
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.text('New deck'), findsOneWidget);
      final fab = find.byType(FloatingActionButton);
      expect(tester.getSize(fab).height, AppSizing.fab);

      final material = tester.widget<Material>(
        find.descendant(of: fab, matching: find.byType(Material)).first,
      );
      expect(material.color, theme.colorScheme.primary);
      expect(material.elevation, AppElevation.none);
      expect(
        (material.shape! as RoundedRectangleBorder).borderRadius,
        BorderRadius.circular(AppRadius.lg),
      );

      final shadow = tester.widget<DecoratedBox>(
        find.ancestor(of: fab, matching: find.byType(DecoratedBox)).first,
      );
      expect(
        (shadow.decoration as BoxDecoration).boxShadow,
        shadowsFor(AppElevation.overlay, theme.colorScheme),
      );
    });
  }
}
```

Append to `mx_scroll_end_inset_test.dart`:

```dart
  testWidgets('with a floating action the tail clears it by 48 (D15)', (
    tester,
  ) async {
    late double inset;
    await tester.pumpWidget(
      MxScrollEndInsetScope(
        hasFloatingAction: true,
        child: Builder(builder: (context) {
          inset = mxScrollEndInsetOf(context);
          return const SizedBox();
        }),
      ),
    );

    expect(inset, AppSizing.fab + AppSpacing.lg + AppSpacing.xxxl);
  });
```

(add `import 'package:memox/core/theme/foundations/app_sizing.dart';`). A bare `Builder` has no `MediaQuery`; if `viewPaddingOf` throws, wrap the tree in `MediaQuery(data: const MediaQueryData(), child: …)`.

- [ ] **Step 2: Run to fail** — `flutter test test/shared/widgets/mx_fab_test.dart test/shared/widgets/mx_scroll_end_inset_test.dart` → compile FAIL (`AppSizing.fab`).

- [ ] **Step 3: Move the role guard first** — in `m3_role_bindings.dart` the two FAB bindings become:

```dart
  RoleBinding(
    component: 'FloatingActionButton',
    slot: 'backgroundColor',
    file: _fab,
    scope: 'buildFloatingActionButtonTheme',
    requires: <String>['primary'],
    refuses: <String>['primaryContainer', 'secondaryContainer', 'tertiaryContainer'],
    because:
        'The Tokyo handoff FAB is a primary fill with an onPrimary label; the '
        'kit beats the canonical primaryContainer (owner decision 4, '
        '2026-09-13).',
  ),
  RoleBinding(
    component: 'FloatingActionButton',
    slot: 'foregroundColor',
    file: _fab,
    scope: 'buildFloatingActionButtonTheme',
    requires: <String>['onPrimary'],
    refuses: <String>['onPrimaryContainer'],
    because: 'The label that travels with a primary fill is onPrimary.',
  ),
```

`scope` and `because` are required parameters (`m3_role_binding_guard_test.dart:91-99`). Every binding this plan moves keeps its `scope` and gets a `because` that cites the owner decision.

- [ ] **Step 4: Tokens** — `app_sizing.dart`: rename `floatingAction` → `fab`, value `52`, doc "The handoff's extended FAB height (`size-fab`). Width is content-driven." Then `sed -i -E 's/AppSizing\.floatingAction\b/AppSizing.fab/g' $(grep -rlE "AppSizing\.floatingAction\b" lib test)`. `app_spacing.dart`:

```dart
  static const double fabScrollClearance =
      AppSizing.fab + lg + xxxl;
```

and reword its doc: "the button, its 16 margin, and the handoff's 48 page-end clearance above pinned chrome (D15)".

- [ ] **Step 5: Theme** — `app_fab_theme.dart`:

```dart
FloatingActionButtonThemeData buildFloatingActionButtonTheme(
  ColorScheme scheme,
) => FloatingActionButtonThemeData(
  backgroundColor: scheme.primary,
  foregroundColor: scheme.onPrimary,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(AppRadius.lg),
  ),
  extendedSizeConstraints: const BoxConstraints.tightFor(
    height: AppSizing.fab,
  ),
  iconSize: AppIconSize.sm,
  hoverColor: scheme.onPrimary.withValues(alpha: AppStateOpacity.hoverControl),
  focusColor: scheme.onPrimary.withValues(alpha: AppStateOpacity.focus),
  splashColor: scheme.onPrimary.withValues(alpha: AppStateOpacity.pressed),
  // The depth is `shadow-fab`, painted by `MxFab` — Material's elevation
  // shadow is a different shape, so it is switched off here.
  elevation: AppElevation.none,
  focusElevation: AppElevation.none,
  hoverElevation: AppElevation.none,
  highlightElevation: AppElevation.none,
);
```

Add imports `app_sizing.dart`, `app_icon_size.dart`. Keep the file's doc comment, rewriting the "canonical `primaryContainer`" paragraph to "kit beats canonical (owner decision 4)".

- [ ] **Step 6: Widget** — `mx_fab.dart`:

```dart
import 'package:flutter/material.dart';

import '../../core/theme/extensions/theme_context_extension.dart';
import '../../core/theme/foundations/app_elevation.dart';
import '../../core/theme/foundations/app_radius.dart';

/// The handoff's extended FAB: glyph + label, 52 tall, radius 16, `shadow-fab`.
/// The label is visible, so it is also the accessible name — no tooltip.
class MxFab extends StatelessWidget {
  const MxFab({
    required this.icon,
    required this.label,
    required this.onPressed,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: shadowsFor(AppElevation.overlay, context.colors),
      ),
      child: FloatingActionButton.extended(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
      ),
    );
  }
}
```

- [ ] **Step 7: Run**

```bash
flutter analyze --no-fatal-infos
flutter test test/shared test/core/theme test/features/deck test/features/card --exclude-tags golden
```

Expected: the new tests PASS; `m3_role_binding_guard_test` PASS. Pins on the 56 circle or `find.byTooltip(<fab label>)` move to the extended FAB / `find.text(label)`. In `component_depth_and_state_test.dart` replace `expect(theme.floatingActionButtonTheme.elevation, greaterThan(0), reason: '${entry.key}: the FAB floats')` with `expect(theme.floatingActionButtonTheme.elevation, AppElevation.none, reason: '${entry.key}: the FAB paints shadow-fab through MxFab, not a Material elevation')` — `mx_fab_test.dart` now pins the shadow itself; keep the `theme.shadowColor` assertion beside it.

- [ ] **Step 8: Docs + commit** — `tokyo-component-mapping.md` §2 FAB rows: MemoX `primary` / `onPrimary`, note "extended 52, `shadow-fab` in `MxFab`; kit beats canonical (owner decision 4)". §4's binding table keeps its M100.32 history; add one line under it: "Superseded for FAB by M100.xx."

```bash
git add -A lib test docs/design-system/tokyo-component-mapping.md
git commit -m "feat(design-system): extended FAB, 52 tall, primary with shadow-fab (M100.xx)"
```

- [ ] **Step 9: Close Phase 2** — P3 (with integration suite), P4, P5, P6. WBS goal: "Nút theo handoff: compact 36, tonal cho hành động phụ tiến tới, icon button vòng 36 glyph 20, FAB extended 52 màu primary."

---

## Phase 3 — surfaces, rows, status and the Library deck row (sections C, E)

### Task 9: Card — radius 20, interior 20

**Files:**
- Modify: `lib/core/theme/components/surfaces/app_card_theme.dart` (`AppRadius.lg` → `AppRadius.card`)
- Modify: `lib/shared/widgets/mx_card.dart` (recipe radii, `MxCardPadding.standard`)
- Test: `test/shared/widgets/mx_card_recipes_test.dart` (the new test, plus the existing pins: lines 104, 126, 204, 214 `AppRadius.lg` → `AppRadius.card`; line 307 `MxCardPadding.standard: AppSpacing.lg` → `AppSpacing.card`), `test/shared/widgets/mx_card_test.dart`

**Interfaces:**
- Produces: every card-surface recipe (`flat`, `raised`, `focal`, `recessed`, `feedback`, `muted`, `tonal`, `accent`, `option`) at `AppRadius.card`; `tile` stays `AppRadius.md`. `MxCardPadding.standard` = `EdgeInsets.all(AppSpacing.card)`; `compact` stays `AppSpacing.md`.

Light fill `surfaceContainerLowest` + `shadow-soft`, dark rim — already shipped (M100.87); pressed tint is `[INFERRED]` (D3). Only geometry changes.

- [ ] **Step 1: Write the failing test** — add to `mx_card_recipes_test.dart` (reuse its pump helper; this is the shape the assertion needs):

```dart
  testWidgets('card-surface recipes round at 20 and pad at 20', (tester) async {
    final recipes = <String, Widget>{
      'flat': const MxCard.flat(child: SizedBox(height: 10)),
      'raised': const MxCard.raised(child: SizedBox(height: 10)),
      'tonal': const MxCard.tonal(child: SizedBox(height: 10)),
      'accent': const MxCard.accent(child: SizedBox(height: 10)),
    };
    for (final entry in recipes.entries) {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildLightTheme(),
          home: Scaffold(body: Center(child: entry.value)),
        ),
      );
      final box = tester.widget<DecoratedBox>(
        find.descendant(of: find.byType(MxCard), matching: find.byType(DecoratedBox)).first,
      );
      expect(
        (box.decoration as BoxDecoration).borderRadius,
        BorderRadius.circular(AppRadius.card),
        reason: entry.key,
      );
      final padding = tester.widget<Padding>(
        find.ancestor(of: find.byType(SizedBox).last, matching: find.byType(Padding)).first,
      );
      expect(padding.padding, const EdgeInsets.all(AppSpacing.card), reason: entry.key);
    }
  });
```

If `MxCard` paints through a different box type (read `mx_card.dart` build), assert on that type's radius instead; the expected values do not change.

- [ ] **Step 2: Run to fail** — `flutter test test/shared/widgets/mx_card_recipes_test.dart` → FAIL (radius 16, padding 16).

- [ ] **Step 3: Implement** — in `mx_card.dart` change `radius: AppRadius.lg` → `radius: AppRadius.card` in the `flat`, `raised`, `feedback`, `muted`, `tonal`, `accent`, `option` constructors (lines ~189–424; `focal` and `recessed` already read `AppRadius.card` after Task 3), and `MxCardPadding.standard => const EdgeInsets.all(AppSpacing.lg)` → `AppSpacing.card`. In `app_card_theme.dart` `BorderRadius.circular(AppRadius.lg)` → `AppRadius.card`, rewording the doc bullet "`AppRadius.lg`, not M3's 12" to "`AppRadius.card` (20) — the handoff's roomiest common surface".

- [ ] **Step 4: Run** — `flutter test test/shared test/core/theme test/features --exclude-tags golden`. Pins on 16 radius / 16 interior move to 20. `feature_geometry_grid_test` must stay green (20 is on the 4dp grid).

- [ ] **Step 5: Commit**

```bash
git add -A lib test
git commit -m "feat(design-system): cards round and pad at 20 (M100.xx)"
```

### Task 10: `MxIconTile`

**Files:**
- Modify: `lib/core/theme/foundations/app_sizing.dart`
- Create: `lib/shared/widgets/mx_icon_tile.dart`
- Create: `test/shared/widgets/mx_icon_tile_test.dart`
- Modify: `widgetbook/lib/components/structure_components.dart` + its registration in `widgetbook/lib/main.dart`

**Interfaces:**
- Produces: `AppSizing.iconTileSm = 28`, `iconTileMd = 36`, `iconTileLg = 44`; `enum MxIconTileSize { sm, md, lg }` with `extent` and `glyph`; `const MxIconTile({required IconData icon, MxIconTileSize size = MxIconTileSize.md})`.

- [ ] **Step 1: Write the failing test** — `test/shared/widgets/mx_icon_tile_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/shared/widgets/mx_icon.dart';
import 'package:memox/shared/widgets/mx_icon_tile.dart';

/// Handoff IconTile (C): a tinted square, sm 28 / md 36 / lg 44, primary at
/// 10%, radius 8, non-interactive. Glyph per size is D4.
void main() {
  for (final (size, extent, glyph) in <(MxIconTileSize, double, MxIconSize)>[
    (MxIconTileSize.sm, 28, MxIconSize.xs),
    (MxIconTileSize.md, 36, MxIconSize.sm),
    (MxIconTileSize.lg, 44, MxIconSize.md),
  ]) {
    testWidgets('$size is $extent with a ${glyph.name} glyph', (tester) async {
      final theme = buildLightTheme();
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(
            body: Center(child: MxIconTile(icon: Icons.folder_outlined, size: size)),
          ),
        ),
      );

      expect(tester.getSize(find.byType(MxIconTile)), Size.square(extent));
      expect(tester.widget<MxIcon>(find.byType(MxIcon)).size, glyph);
      final box = tester.widget<DecoratedBox>(
        find.descendant(of: find.byType(MxIconTile), matching: find.byType(DecoratedBox)).first,
      );
      final decoration = box.decoration as BoxDecoration;
      expect(decoration.borderRadius, BorderRadius.circular(AppRadius.sm));
      expect(decoration.color, theme.colorScheme.primary.withValues(alpha: 0.10));
      expect(find.byType(InkWell), findsNothing);
    });
  }
}
```

If `MxIcon` exposes its size under another field name, use it.

- [ ] **Step 2: Run to fail** — `flutter test test/shared/widgets/mx_icon_tile_test.dart` → compile FAIL.

- [ ] **Step 3: Tokens** — `app_sizing.dart`, near `statusDot`:

```dart
  /// Handoff IconTile extents — a row's tinted leading square. Painted marks,
  /// not controls: the row carries the target.
  static const double iconTileSm = 28;
  static const double iconTileMd = 36;
  static const double iconTileLg = 44;
```

- [ ] **Step 4: Widget** — `lib/shared/widgets/mx_icon_tile.dart`:

```dart
import 'package:flutter/material.dart';

import '../../core/theme/extensions/app_ink.dart';
import '../../core/theme/extensions/theme_context_extension.dart';
import '../../core/theme/foundations/app_radius.dart';
import '../../core/theme/foundations/app_sizing.dart';
import 'mx_icon.dart';

/// Handoff IconTile's tint: `primary` at 10%.
const double _tintAlpha = 0.10;

/// The three handoff sizes, each with the glyph step it holds (D4).
enum MxIconTileSize {
  sm(AppSizing.iconTileSm, MxIconSize.xs),
  md(AppSizing.iconTileMd, MxIconSize.sm),
  lg(AppSizing.iconTileLg, MxIconSize.md);

  const MxIconTileSize(this.extent, this.glyph);

  final double extent;
  final MxIconSize glyph;
}

/// Handoff IconTile (section C): the tinted square holding a row's leading
/// glyph. Non-interactive — the row it sits in owns the tap and the label.
class MxIconTile extends StatelessWidget {
  const MxIconTile({
    required this.icon,
    this.size = MxIconTileSize.md,
    super.key,
  });

  final IconData icon;
  final MxIconTileSize size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size.extent,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: context.colors.primary.withValues(alpha: _tintAlpha),
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Center(
          child: MxIcon(icon, ink: AppInk.accent, size: size.glyph),
        ),
      ),
    );
  }
}
```

- [ ] **Step 5: Widgetbook** — in `structure_components.dart` add (and register it in `main.dart` beside the other structure components):

```dart
WidgetbookComponent iconTileComponent() {
  return WidgetbookComponent(
    name: 'MxIconTile',
    useCases: <WidgetbookUseCase>[
      WidgetbookUseCase(
        name: 'Sizes',
        builder: (context) => CatalogCenterPage(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: AppSpacing.lg,
            children: <Widget>[
              for (final size in MxIconTileSize.values)
                MxIconTile(icon: Icons.folder_outlined, size: size),
            ],
          ),
        ),
      ),
    ],
  );
}
```

- [ ] **Step 6: Run + commit**

```bash
flutter test test/shared/widgets/mx_icon_tile_test.dart
(cd widgetbook && flutter analyze --no-fatal-infos)
git add lib/core/theme/foundations/app_sizing.dart lib/shared/widgets/mx_icon_tile.dart test/shared/widgets/mx_icon_tile_test.dart widgetbook/lib
git commit -m "feat(design-system): MxIconTile — the handoff's tinted leading square (M100.xx)"
```

### Task 11: Section header is the caption overline

**Files:**
- Modify: `lib/shared/widgets/mx_section_label.dart` (drop `MxSectionLabelRung.small`)
- Modify: `lib/core/theme/typography/app_text_styles.dart` (drop `sectionLabelSmall`; `sectionLabel` from `labelSmall`)
- Modify: callers the compiler names (12 `MxSectionLabelRung.` uses at `dcd22f32`; `sectionLabelSmall` readers, e.g. `study_session_frame_section_widget.dart`)
- Test: `test/shared/widgets/mx_section_label_test.dart`

**Interfaces:**
- Produces: `AppTextStyles.sectionLabel` = `labelSmall` (12/600/1.4/+1.2 — the handoff SectionHeader). `enum MxSectionLabelRung { standard, list }`.

After Task 2, `standard` and `small` resolve to the same metrics, so two names for one look is dead distinction.

- [ ] **Step 1: Write the failing test** — replace the "three rungs" test in `mx_section_label_test.dart` with:

```dart
  testWidgets('standard is the handoff overline, list is the ls-label heading', (
    tester,
  ) async {
    await pump(tester, const MxSectionLabel(label: 'x'));
    final overline = tester.widget<Text>(find.text('X')).style!;
    expect(overline.fontSize, 12);
    expect(overline.fontWeight, FontWeight.w600);
    expect(overline.letterSpacing, 1.2);

    await pump(tester, const MxSectionLabel(label: 'x', rung: MxSectionLabelRung.list));
    final heading = tester.widget<Text>(find.text('X')).style!;
    expect(heading.letterSpacing, 0.72);
    expect(MxSectionLabelRung.values, hasLength(2));
  });
```

- [ ] **Step 2: Run to fail** — `flutter test test/shared/widgets/mx_section_label_test.dart` → FAIL (`hasLength(2)` got 3).

- [ ] **Step 3: Implement** — remove `small` from the enum and its switch arm; in `AppTextStyles` delete the `sectionLabelSmall` field, constructor parameter, `copyWith` and `lerp` entries, and build `sectionLabel` from `texts.labelSmall` with `letterSpacing: AppTypography.sectionLabelTracking`. Then:

```bash
FILES=$(grep -rlE "MxSectionLabelRung\.small\b|\bsectionLabelSmall\b" lib test widgetbook/lib integration_test)
sed -i -E 's/MxSectionLabelRung\.small\b/MxSectionLabelRung.standard/g; s/\bsectionLabelSmall\b/sectionLabel/g' $FILES
flutter analyze --no-fatal-infos
```

Delete any `rung: MxSectionLabelRung.standard,` argument the sed produced (it is the default). Two call sites then need a person, not the sed: `app_typography_test.dart`'s weight registry map holds `'textStyles.sectionLabel'` twice — delete the second entry; `card_import_states_test.dart`'s assertion that the heading is *not* the small rung already left in Phase 1 (PLAN-DEV-2.10: D1 made both rungs 12px); its `expect(renderedSize, styles.sectionLabel.fontSize)` still pins the heading.

- [ ] **Step 4: Run + commit** — `flutter test test/shared test/features --exclude-tags golden`.

```bash
git add -A lib test widgetbook/lib
git commit -m "feat(design-system): section header is the handoff caption overline (M100.xx)"
```

### Task 12: Rows — 48 minimum, grouped with hairlines

**Files:**
- Modify: `lib/core/theme/foundations/app_sizing.dart` (`rowMinHeight` 56 → 48; add `listDividerIndent`)
- Not modified: `lib/shared/widgets/mx_list_tile.dart` keeps its two-line title and subtitle (D26)
- Create: `lib/shared/widgets/mx_row_group.dart`
- Test: Create `test/shared/widgets/mx_row_group_test.dart`; modify `test/core/theme/foundations/app_sizing_test.dart`, `test/shared/widgets/mx_list_tile_test.dart`

**Interfaces:**
- Produces: `AppSizing.rowMinHeight = 48`, `AppSizing.listDividerIndent = 56`; `enum MxRowDividerInset { none, leading }`; `const MxRowGroup({required List<Widget> children, MxRowDividerInset inset = MxRowDividerInset.leading})` — a hairline `Divider` between rows, none after the last.

SettingsTile needs no new widget: `MxListTile` already has optional `leading`, title `onSurface`, subtitle `onSurfaceVariant`; this task gives it the 48 minimum. The Settings screen rows keep their glyphs (`description_outlined`, `notifications_outlined`).

- [ ] **Step 1: Write the failing tests** — `test/shared/widgets/mx_row_group_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/foundations/app_sizing.dart';
import 'package:memox/shared/widgets/mx_list_tile.dart';
import 'package:memox/shared/widgets/mx_row_group.dart';

/// Handoff ListRow (C): a hairline between rows, none after the last; the
/// divider indents 56 when rows lead with a tile.
void main() {
  Future<void> pump(WidgetTester tester, MxRowDividerInset inset) =>
      tester.pumpWidget(
        MaterialApp(
          theme: buildLightTheme(),
          home: Scaffold(
            body: MxRowGroup(
              inset: inset,
              children: const <Widget>[
                MxListTile(title: 'One'),
                MxListTile(title: 'Two'),
                MxListTile(title: 'Three'),
              ],
            ),
          ),
        ),
      );

  testWidgets('n rows carry n - 1 dividers', (tester) async {
    await pump(tester, MxRowDividerInset.leading);
    expect(find.byType(Divider), findsNWidgets(2));
  });

  testWidgets('the inset follows the leading column', (tester) async {
    await pump(tester, MxRowDividerInset.leading);
    expect(tester.widget<Divider>(find.byType(Divider).first).indent,
        AppSizing.listDividerIndent);

    await pump(tester, MxRowDividerInset.none);
    expect(tester.widget<Divider>(find.byType(Divider).first).indent, 0);
  });

  testWidgets('a row is at least 48', (tester) async {
    await pump(tester, MxRowDividerInset.none);
    expect(tester.getSize(find.byType(ListTile).first).height,
        greaterThanOrEqualTo(48));
  });
}
```

In `app_sizing_test.dart` change `expect(AppSizing.rowMinHeight, greaterThan(AppSizing.touchTarget));` → `greaterThanOrEqualTo(AppSizing.touchTarget)` and `expect(AppSizing.rowMinHeight, 56);` → `48`.

- [ ] **Step 2: Run to fail** — `flutter test test/shared/widgets/mx_row_group_test.dart test/core/theme/foundations/app_sizing_test.dart` → compile FAIL.

- [ ] **Step 3: Tokens** — `app_sizing.dart`: `rowMinHeight` value `48`, doc replaced by "The handoff's list row: 48 MINIMUM, grows with content. Text is never clipped to hold it." Add:

```dart
  /// Where a row divider starts when the rows lead with a tile (handoff
  /// Divider `indent 0 / 56`).
  static const double listDividerIndent = 56;
```

- [ ] **Step 4: Widget** — create `lib/shared/widgets/mx_row_group.dart` (`MxListTile` keeps `maxLines: 2`, D26):

```dart
import 'package:flutter/material.dart';

import '../../core/theme/foundations/app_sizing.dart';

/// Where the hairline between rows starts.
enum MxRowDividerInset {
  /// Full width — rows without a leading tile or glyph.
  none,

  /// Aligned past the leading column (56).
  leading,
}

/// Handoff ListRow grouping: rows on one surface, a hairline between each
/// pair, none after the last. The divider is the theme's (`outlineVariant`,
/// hairline — D2); this widget only decides where it goes.
class MxRowGroup extends StatelessWidget {
  const MxRowGroup({
    required this.children,
    this.inset = MxRowDividerInset.leading,
    super.key,
  });

  final List<Widget> children;
  final MxRowDividerInset inset;

  @override
  Widget build(BuildContext context) {
    final double indent = switch (inset) {
      MxRowDividerInset.none => 0,
      MxRowDividerInset.leading => AppSizing.listDividerIndent,
    };
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (final (index, child) in children.indexed) ...<Widget>[
          if (index > 0) Divider(indent: indent),
          child,
        ],
      ],
    );
  }
}
```

- [ ] **Step 5: Run + commit** — `flutter test test/shared test/core/theme test/features --exclude-tags golden`; pins on the old 56 row minimum move to 48.

```bash
git add -A lib test
git commit -m "feat(design-system): 48 rows and MxRowGroup hairlines (M100.xx)"
```

### Task 13: Mastery and card-lifecycle tokens; `MxStatusBadge`; progress completes in mastery

**Files:**
- Modify: `lib/core/theme/foundations/app_colors.dart`, `app_semantic_colors.dart`
- Create: `lib/shared/widgets/mx_status_badge.dart`, `test/shared/widgets/mx_status_badge_test.dart`
- Modify: `lib/shared/widgets/mx_progress_bar.dart` (complete fill)
- Modify: `lib/features/card/presentation/widgets/support/card_state_widget.dart` (`cardStateColor` remapped, `cardStateTone` added), `lib/features/card/presentation/widgets/items/card_tile_widget.dart` (`_StateDot`)
- Repainted by the remap, no code change: `card_detail_state_widget.dart:283`, `card_state_distribution_widget.dart:66,131`
- Modify: `test/core/theme/foundations/app_semantic_colors_test.dart`, `test/design_audit/audit_test.dart` (dump length), `test/shared/widgets/mx_progress_bar_test.dart` (the two existing complete-state pins, Step 1)
- Modify: `widgetbook/lib/components/feedback_components.dart`, `widgetbook/lib/tokens/color_sections.dart`

**Interfaces:**
- Produces: `AppSemanticColors.mastery`, `.statusNew`, `.statusLearning`, `.statusReviewing`, `.statusMastered`; `enum MxStatusTone { isNew, learning, reviewing, mastered }`; `enum MxStatusBadgeForm { pill, dot }`; `const MxStatusBadge({required MxStatusTone tone, required String label, MxStatusBadgeForm form = MxStatusBadgeForm.pill})`; `extension CardStatePresentation` gains `MxStatusTone cardStateTone(CardState)`. `MxProgressBar` fills with `mastery` at 100%.

- [ ] **Step 1: Write the failing tests** — append to `app_semantic_colors_test.dart`:

```dart
  test('mastery and the four lifecycle statuses are the handoff hexes', () {
    const light = AppSemanticColors.light();
    const dark = AppSemanticColors.dark();

    expect(light.mastery, const Color(0xFF1F8A5B));
    expect(dark.mastery, const Color(0xFF6FE0BD));
    expect(light.statusNew, const Color(0xFF8C95B8));
    expect(dark.statusNew, const Color(0xFF6B75A3));
    expect(light.statusLearning, const Color(0xFFF59E0B));
    expect(dark.statusLearning, const Color(0xFFFFC658));
    expect(light.statusReviewing, const Color(0xFF5265F5));
    expect(dark.statusReviewing, const Color(0xFF8B9AFF));
    expect(light.statusMastered, const Color(0xFF1F8A5B));
    expect(dark.statusMastered, const Color(0xFF6FE0BD));
  });
```

`test/shared/widgets/mx_status_badge_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/foundations/app_semantic_colors.dart';
import 'package:memox/core/theme/foundations/app_sizing.dart';
import 'package:memox/shared/widgets/mx_status_badge.dart';

/// Handoff StatusBadge (E): dot + label, `status*` tokens, pill or bare dot.
void main() {
  Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(
    MaterialApp(
      theme: buildLightTheme(),
      home: Scaffold(body: Center(child: child)),
    ),
  );

  Color dotColor(WidgetTester tester) {
    final box = tester.widget<DecoratedBox>(
      find.descendant(
        of: find.byType(MxStatusBadge),
        matching: find.byWidgetPredicate((w) =>
            w is DecoratedBox &&
            (w.decoration as BoxDecoration).shape == BoxShape.circle),
      ),
    );
    return (box.decoration as BoxDecoration).color!;
  }

  for (final (tone, pick) in <(MxStatusTone, Color Function(AppSemanticColors))>[
    (MxStatusTone.isNew, (s) => s.statusNew),
    (MxStatusTone.learning, (s) => s.statusLearning),
    (MxStatusTone.reviewing, (s) => s.statusReviewing),
    (MxStatusTone.mastered, (s) => s.statusMastered),
  ]) {
    testWidgets('$tone paints its status token', (tester) async {
      await pump(tester, MxStatusBadge(tone: tone, label: 'State'));
      expect(dotColor(tester), pick(const AppSemanticColors.light()));
      expect(find.text('State'), findsOneWidget);
    });
  }

  testWidgets('the dot form is a labelled 8dp mark with no text', (tester) async {
    final handle = tester.ensureSemantics();
    await pump(
      tester,
      const MxStatusBadge(
        tone: MxStatusTone.mastered,
        label: 'Mastered',
        form: MxStatusBadgeForm.dot,
      ),
    );
    expect(find.text('Mastered'), findsNothing);
    expect(tester.getSize(find.byType(MxStatusBadge)),
        const Size.square(AppSizing.statusDot));
    expect(tester.getSemantics(find.byType(MxStatusBadge)).label, 'Mastered');
    handle.dispose();
  });
}
```

In `mx_progress_bar_test.dart` move the two existing complete-state pins instead of adding a third: `testWidgets('at 100% the fill turns success'` (line 63) becomes `'at 100% the fill turns mastery'` with `expect(indicatorOf(tester).color, semantic.mastery)`, and the `semantic.success` expectation at line 157 moves to `semantic.mastery`.

- [ ] **Step 2: Run to fail** — `flutter test test/core/theme/foundations/app_semantic_colors_test.dart test/shared/widgets/mx_status_badge_test.dart test/shared/widgets/mx_progress_bar_test.dart` → compile FAIL.

- [ ] **Step 3: Tokens** — `app_colors.dart`, after the status block:

```dart
  // --- Mastery and the card lifecycle (handoff `mastery`, `status-*`) --------
  //
  // Fills and dots only (owner decision 5, D23): none of these is a text ink.
  static const Color masteryLight = Color(0xFF1F8A5B);
  static const Color masteryDark = Color(0xFF6FE0BD);
  static const Color statusNewLight = Color(0xFF8C95B8);
  static const Color statusNewDark = Color(0xFF6B75A3);
  static const Color statusLearningLight = warningLight;
  static const Color statusLearningDark = warningDark;
  static const Color statusReviewingLight = primaryLight;
  static const Color statusReviewingDark = primaryDark;
  static const Color statusMasteredLight = masteryLight;
  static const Color statusMasteredDark = masteryDark;
```

`app_semantic_colors.dart`: add `mastery`, `statusNew`, `statusLearning`, `statusReviewing`, `statusMastered` as `required this.` constructor fields, `final Color` fields with a one-line doc each, `AppSemanticColors.light()` → `AppColors.<name>Light`, `.dark()` → `AppColors.<name>Dark`, `copyWith` parameters, and `lerp` entries in the same `mix(…)` form as `success`. Run `flutter analyze --no-fatal-infos`; every other constructor of `AppSemanticColors` (e.g. in `app_high_contrast.dart`) now fails to compile — give each the same five values its `success` line uses the pattern of.

In `test/design_audit/audit_test.dart:70` move `hasLength(78)` → `hasLength(83)` and add the five names wherever that test's resolver lists semantic fields.

- [ ] **Step 4: Widget** — `lib/shared/widgets/mx_status_badge.dart`:

```dart
import 'package:flutter/material.dart';

import '../../core/theme/extensions/app_ink.dart';
import '../../core/theme/extensions/theme_context_extension.dart';
import '../../core/theme/foundations/app_radius.dart';
import '../../core/theme/foundations/app_semantic_colors.dart';
import '../../core/theme/foundations/app_sizing.dart';
import '../../core/theme/foundations/app_spacing.dart';

/// The handoff's card lifecycle: new ▸ learning ▸ reviewing ▸ mastered.
enum MxStatusTone { isNew, learning, reviewing, mastered }

/// Pill (dot + label) or the bare dot.
enum MxStatusBadgeForm { pill, dot }

/// Handoff StatusBadge (E). The dot carries the status colour; the label reads
/// in `onSurfaceVariant` (D24). Non-interactive.
class MxStatusBadge extends StatelessWidget {
  const MxStatusBadge({
    required this.tone,
    required this.label,
    this.form = MxStatusBadgeForm.pill,
    super.key,
  });

  final MxStatusTone tone;
  final String label;
  final MxStatusBadgeForm form;

  Color _dotColor(AppSemanticColors semantic) => switch (tone) {
    MxStatusTone.isNew => semantic.statusNew,
    MxStatusTone.learning => semantic.statusLearning,
    MxStatusTone.reviewing => semantic.statusReviewing,
    MxStatusTone.mastered => semantic.statusMastered,
  };

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final dot = SizedBox.square(
      dimension: AppSizing.statusDot,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _dotColor(semantic),
          shape: BoxShape.circle,
        ),
      ),
    );
    if (form == MxStatusBadgeForm.dot) {
      return Semantics(label: label, child: dot);
    }
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: semantic.surfaceMuted,
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: AppSpacing.xs,
            children: <Widget>[
              dot,
              Text(label, style: context.texts.labelMedium!.inked(context, AppInk.quiet)),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 5: Feature + progress** — `card_state_widget.dart`: add

```dart
  MxStatusTone cardStateTone(CardState state) => switch (state) {
    CardState.isNew => MxStatusTone.isNew,
    CardState.beginning => MxStatusTone.learning,
    CardState.reviewing => MxStatusTone.reviewing,
    CardState.mastered => MxStatusTone.mastered,
  };
```

and remap `cardStateColor` to the status tokens — `isNew → semantic.statusNew`, `beginning → semantic.statusLearning`, `reviewing → semantic.statusReviewing`, `mastered → semantic.statusMastered` (D11). Keep the function: `card_detail_state_widget.dart:283` and `card_state_distribution_widget.dart:66,131` read it, and they must show the same lifecycle colours as the tile. Run `grep -rnE "cardStateColor|semantic\.info\b" test/features/card` and move any colour pin it finds. In `card_tile_widget.dart` replace `_StateDot`'s `Semantics` + `Container` with

```dart
      child: MxStatusBadge(
        tone: context.cardStateTone(item.state),
        form: MxStatusBadgeForm.dot,
        label: context.l10n.cardStateDotSemantics(
          context.cardStateLabel(item.state),
        ),
      ),
```

and remove `_stateDotSize` if now unused. `cardStateInk` (text inks) stays. In `mx_progress_bar.dart`: `isComplete ? semantic.success : semantic.progressFill` → `isComplete ? semantic.mastery : semantic.progressFill`.

- [ ] **Step 6: Widgetbook** — `feedback_components.dart`: a `MxStatusBadge` component with a use case listing all four tones in both forms; `color_sections.dart`: add the five tokens next to `success`.

- [ ] **Step 7: Run + commit**

```bash
flutter analyze --no-fatal-infos
flutter test test/core/theme test/shared test/features/card test/design_audit --exclude-tags golden
git add -A lib test widgetbook/lib design_audit
git commit -m "feat(design-system): mastery and status tokens, MxStatusBadge (M100.xx)"
```

`design_audit/*` diffs must be token values only.

### Task 14: `MxMasteryRing`

**Files:**
- Modify: `lib/core/theme/foundations/app_sizing.dart`, `app_stroke.dart`
- Create: `lib/shared/widgets/mx_mastery_ring.dart`, `test/shared/widgets/mx_mastery_ring_test.dart`
- Modify: `widgetbook/lib/components/feedback_components.dart`

**Interfaces:**
- Consumes: `AppSemanticColors.mastery`, `.progressTrack` (Task 13).
- Produces: `AppSizing.masteryRing = 40`; `AppStroke.ring = 3`; `const MxMasteryRing({required double value, required bool isComplete, required String semanticsLabel, String? semanticsValue})`. Arc `primary` below complete, `mastery` when `isComplete` (D8).

- [ ] **Step 1: Write the failing test** — `test/shared/widgets/mx_mastery_ring_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/foundations/app_semantic_colors.dart';
import 'package:memox/core/theme/foundations/app_sizing.dart';
import 'package:memox/shared/widgets/mx_mastery_ring.dart';

/// Handoff MasteryRing (E): 40 × 3px. Colour follows BR-88 (D8).
void main() {
  Future<MxMasteryRingPainter> pump(
    WidgetTester tester, {
    required double value,
    required bool isComplete,
  }) async {
    await tester.pumpWidget(MaterialApp(
      theme: buildLightTheme(),
      home: Scaffold(
        body: Center(
          child: MxMasteryRing(
            value: value,
            isComplete: isComplete,
            semanticsLabel: 'Learned',
            semanticsValue: '${(value * 100).round()}%',
          ),
        ),
      ),
    ));
    return tester
        .widget<CustomPaint>(find.descendant(
          of: find.byType(MxMasteryRing),
          matching: find.byType(CustomPaint),
        ))
        .painter! as MxMasteryRingPainter;
  }

  testWidgets('40 square, 3px stroke', (tester) async {
    final painter = await pump(tester, value: 0.4, isComplete: false);
    expect(tester.getSize(find.byType(MxMasteryRing)), const Size.square(AppSizing.masteryRing));
    expect(painter.stroke, 3);
  });

  testWidgets('primary until complete, mastery at complete', (tester) async {
    final theme = buildLightTheme();
    expect((await pump(tester, value: 0.99, isComplete: false)).fill, theme.colorScheme.primary);
    expect((await pump(tester, value: 1, isComplete: true)).fill, const AppSemanticColors.light().mastery);
  });

  testWidgets('speaks its label and value', (tester) async {
    final handle = tester.ensureSemantics();
    await pump(tester, value: 0.5, isComplete: false);
    final node = tester.getSemantics(find.byType(MxMasteryRing));
    expect(node.label, 'Learned');
    expect(node.value, '50%');
    handle.dispose();
  });
}
```

- [ ] **Step 2: Run to fail** — `flutter test test/shared/widgets/mx_mastery_ring_test.dart` → compile FAIL.

- [ ] **Step 3: Tokens** — `app_sizing.dart`: `/// Handoff MasteryRing extent. A mark, not a control. static const double masteryRing = 40;` · `app_stroke.dart`: `/// Handoff MasteryRing stroke (`40×3px`). static const double ring = 3;`

- [ ] **Step 4: Widget** — `lib/shared/widgets/mx_mastery_ring.dart`:

```dart
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/extensions/theme_context_extension.dart';
import '../../core/theme/foundations/app_sizing.dart';
import '../../core/theme/foundations/app_stroke.dart';

/// Handoff MasteryRing (section E): a 40 ring with a 3px arc. The arc is
/// `primary` until [isComplete], then `mastery` — BR-88 decides "complete",
/// the caller passes it (D8).
class MxMasteryRing extends StatelessWidget {
  const MxMasteryRing({
    required this.value,
    required this.isComplete,
    required this.semanticsLabel,
    this.semanticsValue,
    super.key,
  }) : assert(value >= 0 && value <= 1, 'value is a fraction');

  final double value;
  final bool isComplete;
  final String semanticsLabel;
  final String? semanticsValue;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    return Semantics(
      label: semanticsLabel,
      value: semanticsValue,
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: AppSizing.masteryRing,
        child: CustomPaint(
          painter: MxMasteryRingPainter(
            value: value,
            track: semantic.progressTrack,
            fill: isComplete ? semantic.mastery : context.colors.primary,
            stroke: AppStroke.ring,
          ),
        ),
      ),
    );
  }
}

/// Public for the test that reads the resolved colours; not for callers.
class MxMasteryRingPainter extends CustomPainter {
  const MxMasteryRingPainter({
    required this.value,
    required this.track,
    required this.fill,
    required this.stroke,
  });

  final double value;
  final Color track;
  final Color fill;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(stroke / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, math.pi * 2, false, paint..color = track);
    if (value <= 0) return;
    canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * value, false, paint..color = fill);
  }

  @override
  bool shouldRepaint(MxMasteryRingPainter old) =>
      old.value != value || old.fill != fill || old.track != track || old.stroke != stroke;
}
```

- [ ] **Step 5: Widgetbook + run + commit** — a `MxMasteryRing` use case with a `value` slider knob and an `isComplete` boolean knob.

```bash
flutter test test/shared/widgets/mx_mastery_ring_test.dart
git add -A lib test widgetbook/lib
git commit -m "feat(design-system): MxMasteryRing (M100.xx)"
```

### Task 15: The Library deck row (owner decision 7)

**Files:**
- Modify: `lib/features/deck/presentation/widgets/items/deck_tile_widget.dart` (rewrite)
- Modify: `lib/features/deck/presentation/widgets/items/deck_status_icon_widget.dart` (`DeckIconArea` → `MxIconTile`)
- Modify: `lib/features/deck/presentation/widgets/sections/deck_list_sliver_widget.dart` (rows grouped on one card)
- Delete: `deck_study_button_widget.dart`, `deck_icon_area_widget.dart` — only if Step 7's grep shows no other reader
- Modify: `lib/l10n/app_en.arb`, `app_vi.arb` (remove keys Step 7 shows unused)
- Test: rewrite `test/features/deck/presentation/deck_tile_counts_test.dart`, `deck_tile_geometry_test.dart`, `deck_tile_target_test.dart`, `deck_workload_role_test.dart`; modify `deck_list_level_test.dart:214`, `test/app/shell/app_navigation_shell_test.dart:243`, `deck_summary_compact_geometry_test.dart` (PLAN-DEV-2.9)
- Docs: `docs/design-system/listtile-deck-row-spec.md` (§5 resolution note), `tokyo-component-mapping.md` §7, `lib/features/deck/README.md` (tile description)

**Interfaces:**
- Consumes: `MxIconTile` (T10), `MxRowGroup` (T12), `MxMasteryRing` (T14), `MxPressable(onTap:, child:, shape: MxPressableShape.none)`, `MxIconButton` (T7), `DeckWorkloadLineWidget(summary:)`, `DeckSummary.{deck, learnedFraction, isFullyLearned, learnedCardCount, totalCardCount}`.
- Produces: `DeckTileWidget({required DeckSummary summary, required VoidCallback onTap, required VoidCallback onActions})` — same constructor, new body: a 48-minimum row. `DeckListSliverWidget` renders all rows inside one `MxCard.raised(padding: MxCardPadding.none)` separated by `MxRowGroup` hairlines.

- [ ] **Step 1: Write the failing test** — replace the body of `deck_tile_counts_test.dart`'s Study-button assertions with the row contract (keep its existing fixture builders for `DeckSummary`; the test below names them `summaryWith`):

```dart
  testWidgets('the row is tile · name + workload · ring · overflow, no Study', (
    tester,
  ) async {
    await pumpTile(tester, summaryWith(total: 20, learned: 5, due: 7, fresh: 14));

    expect(find.byType(MxIconTile), findsOneWidget);
    expect(find.byType(DeckWorkloadLineWidget), findsOneWidget);
    expect(find.byType(MxMasteryRing), findsOneWidget);
    expect(find.byIcon(Icons.more_vert), findsOneWidget);
    expect(find.byType(FilledButton), findsNothing);
    expect(tester.getSize(find.byType(DeckTileWidget)).height,
        greaterThanOrEqualTo(AppSizing.rowMinHeight));
  });

  testWidgets('the ring turns mastery only when every card is learned (BR-88)', (
    tester,
  ) async {
    await pumpTile(tester, summaryWith(total: 20, learned: 19));
    expect(tester.widget<MxMasteryRing>(find.byType(MxMasteryRing)).isComplete, isFalse);

    await pumpTile(tester, summaryWith(total: 20, learned: 20));
    expect(tester.widget<MxMasteryRing>(find.byType(MxMasteryRing)).isComplete, isTrue);
  });

  testWidgets('a deck with no cards has no ring', (tester) async {
    await pumpTile(tester, summaryWith(total: 0));
    expect(find.byType(MxMasteryRing), findsNothing);
  });

  testWidgets('tapping the row opens the deck', (tester) async {
    var opened = 0;
    await pumpTile(tester, summaryWith(total: 3), onTap: () => opened++);
    await tester.tap(find.byType(DeckTileWidget));
    expect(opened, 1);
  });
```

If the file's helpers are named differently, adapt the call sites, not the assertions.

- [ ] **Step 2: Run to fail** — `flutter test test/features/deck/presentation/deck_tile_counts_test.dart` → FAIL (`MxIconTile` not found, `FilledButton` found).

- [ ] **Step 3: Leading tile** — in `deck_status_icon_widget.dart` replace the `DeckIconArea(icon: …, tint: AppInk.accent)` construction with `MxIconTile(icon: …)` (default `md`, 36); keep the overdue `Semantics` wrapper exactly.

- [ ] **Step 4: Rewrite `DeckTileWidget`** — replace `DeckTileWidget`, `_DeckHeadRegion`, `_DeckStateRegion`, `_DeckActionRow`, `_DeckGauge` with:

```dart
/// The Library deck row — handoff "ListTile · deck row" (owner decision 7,
/// 2026-09-13, reversing M4.12): identity tile, name over the workload line,
/// the learned ring, the overflow. Studying starts from the Study tab or inside
/// the deck, not from this row.
class DeckTileWidget extends StatelessWidget {
  const DeckTileWidget({
    required this.summary,
    required this.onTap,
    required this.onActions,
    super.key,
  });

  final DeckSummary summary;
  final VoidCallback onTap;
  final VoidCallback onActions;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final percent = (summary.learnedFraction * 100).round();
    return MxPressable(
      onTap: onTap,
      shape: MxPressableShape.none,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppSizing.rowMinHeight),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.xs,
            AppSpacing.md,
          ),
          child: Row(
            children: <Widget>[
              DeckStatusIconWidget(
                status: summary.scheduleStatus,
                contentType: summary.deck.contentType,
                dueCardCount: summary.dueCardCount,
                overdueDayCount: summary.overdueDayCount,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  spacing: AppSpacing.xs,
                  children: <Widget>[
                    Text(
                      summary.deck.name,
                      style: context.texts.bodyLarge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    DeckWorkloadLineWidget(summary: summary),
                  ],
                ),
              ),
              if (summary.totalCardCount > 0) ...<Widget>[
                const SizedBox(width: AppSpacing.md),
                MxMasteryRing(
                  value: summary.learnedFraction,
                  isComplete: summary.isFullyLearned,
                  semanticsLabel: l10n.deckLearnedProgressLabel(
                    summary.learnedCardCount,
                    summary.totalCardCount,
                  ),
                  semanticsValue: l10n.deckLearnedPercentLabel(percent),
                ),
              ],
              MxIconButton(
                icon: Icons.more_vert,
                semanticLabel: l10n.deckRowActionsSemanticLabel(summary.deck.name),
                onPressed: onActions,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

Fix the imports (add `mx_mastery_ring.dart`, `mx_pressable.dart`, `app_sizing.dart`; drop `mx_card.dart`, `mx_progress_bar.dart`, `deck_study_button_widget.dart`, `app_breakpoints.dart` and anything else analyze reports unused). Remove `deckTileGutter` only if nothing else reads it.

- [ ] **Step 5: Group the rows on one card** — in `deck_list_sliver_widget.dart` replace the `SliverList.separated(…)` with:

```dart
      // ponytail: builds every row eagerly — a level holds tens of decks, not
      // thousands. Move to a DecoratedSliver-backed list if a level ever
      // measures slow.
      sliver: SliverToBoxAdapter(
        child: MxCard.raised(
          padding: MxCardPadding.none,
          child: MxRowGroup(
            children: <Widget>[
              for (final summary in summaries) _tileFor(context, summary),
            ],
          ),
        ),
      ),
```

and move the old `itemBuilder` body into `Widget _tileFor(BuildContext context, DeckSummary summary)` unchanged (it computes `manualIndex`, `earlier`, `later` and returns `DeckTileWidget(…)`). Keep the `SliverPadding` and its `mxScrollEndInsetOf` bottom.

- [ ] **Step 6: Keep a way to study a deck** — prove it before deleting the button:

```bash
grep -rnE "studyHomeStudyAction|RouteNames\.study" lib/features/study lib/app --include=*.dart | cut -c1-150
```

Expected: the Study tab's deck item still opens a session for a given deck. If it does not, stop and ask the owner (AskUserQuestion) where a deck's Study entry lives — do not re-add a button to the row.

- [ ] **Step 7: Delete what the row no longer reads**

```bash
grep -rnE "DeckStudyButtonWidget|DeckIconArea|deckTileLearnedPercentLabel|deckTileProgressLabel" lib widgetbook/lib --include=*.dart
```

Delete each file and ARB key (both locales, with its `@key` metadata) that has no reader left. Run `flutter gen-l10n` if the project generates l10n outside `build_runner` (check `pubspec.yaml` `generate: true`), then `flutter analyze --no-fatal-infos`.

- [ ] **Step 8: Move the remaining tests** — `deck_tile_geometry_test`, `deck_tile_target_test`, `deck_workload_role_test`: assert the new row (48 minimum, overflow button 48 target, workload line under the name). `deck_summary_compact_geometry_test.dart` goes back to **three whole deck rows above the bottom bar** (`greaterThanOrEqualTo(3)`) and drops the interim "third within 4px" pin Phase 1 measured (PLAN-DEV-2.9); if the row no longer draws the workload chip, its `_chipMinHeight` (PLAN-DEV-2.8) leaves with it. `deckTileGutter` still steps to 12 below 360dp (PLAN-DEV-4.3, the tile's interior rather than the screen gutter): the new row either drops it for its own inset or holds 16, since Task 4 left the screen gutter at 16 on every width. `deck_workload_role_test.dart` also has `group('the well: identity, not schedule (amends BR-161)'` (lines ~169–264) whose `pumpIcon` returns `DeckIconArea`: retarget it to the `MxIconTile` inside `DeckStatusIconWidget` and keep its identity assertions (glyph by content type, one well for every schedule state, overdue semantics); drop only assertions about `DeckIconArea`'s own fill, which `mx_icon_tile_test.dart` now covers. `deck_list_level_test.dart:214` and `app_navigation_shell_test.dart:243` used `DeckStudyButtonWidget` to start a session from the Library: switch them to the Study tab path found in Step 6. Run:

```bash
flutter test test/features/deck test/app --exclude-tags golden
grep -rnE "DeckStudyButton|deckStudy" integration_test
```

Expected: tests PASS; the integration grep prints nothing (if it prints a scenario, move it to the Study tab path in this task).

- [ ] **Step 9: Docs** — `listtile-deck-row-spec.md`: under §5 add "**Đã quyết (M100.xx, 2026-09-13):** chủ dự án chọn row theo handoff; ring = `learnedFraction`, mastery ở 100% (BR-88); nút Study rời hàng." · `tokyo-component-mapping.md` §7: the `MxCard` row example "deck tile" moves to "hàng thuộc feature trên một `MxCard` + `MxRowGroup` (M100.xx)" · `lib/features/deck/README.md`: rewrite the tile paragraph to the row.

- [ ] **Step 10: Commit**

```bash
git add -A lib test widgetbook/lib integration_test docs
git commit -m "feat(deck): Library deck row per the handoff — tile, workload, mastery ring (M100.xx)"
```

### Task 16: Search results and tag catalog as grouped rows

**Files:**
- Modify: `lib/features/search/presentation/widgets/items/search_result_shell_widget.dart`
- Modify: `lib/features/search/presentation/widgets/sections/library_search_body_widget.dart` (~line 189)
- Modify: `lib/features/card/presentation/widgets/items/tag_catalog_row_widget.dart`, `lib/features/card/presentation/screens/tag_catalog_screen.dart` (~line 217)
- Test: `test/features/search/presentation/*`, `test/features/card/presentation/tag_catalog*` (whatever `grep -rl "SearchResultShellWidget\|TagCatalogRowWidget" test` lists)

**Interfaces:**
- Consumes: `MxIconTile`, `MxRowGroup`, `MxPressable`.
- Produces: `SearchResultShellWidget` keeps its constructor (`icon`, `semanticLabel`, `onOpen`, `child`) but renders a transparent 48-minimum row: `MxIconTile(icon:)` · `child` · chevron. The search body groups a section's results in one `MxCard.raised(padding: none)` + `MxRowGroup`; the tag catalog groups its rows the same way with `TagCatalogRowWidget`'s `_TagWell` replaced by `MxIconTile(icon: Icons.sell_outlined)` (the glyph `_TagWell` draws today — keep whatever it draws).

- [ ] **Step 1: Write the failing test** — in `test/features/search/presentation/library_search_states_test.dart` (helpers `pumpSearchScreen`, `searchInput`, `FakeLibrarySearchRepository.serving`, `fakeSearchPage`, `fakeCardHit`, all already imported there):

```dart
  testWidgets('results are rows on one card, a hairline between each', (
    tester,
  ) async {
    await pumpSearchScreen(
      tester,
      repository: FakeLibrarySearchRepository.serving(
        fakeSearchPage(
          cards: <CardSearchHit>[
            fakeCardHit(id: 'card-1', front: 'noun'),
            fakeCardHit(id: 'card-2', front: 'nouns'),
            fakeCardHit(id: 'card-3', front: 'pronoun'),
          ],
        ),
      ),
    );
    await tester.enterText(searchInput, 'noun');
    await tester.pumpAndSettle();

    expect(find.byType(MxCard), findsOneWidget);
    expect(find.byType(MxRowGroup), findsOneWidget);
    expect(find.byType(Divider), findsNWidgets(2));
    expect(find.byType(MxIconTile), findsNWidgets(3));
  });
```

and the same shape for the tag catalog in `test/features/card/presentation/tag_catalog_screen_test.dart`, reusing the multi-row setup of `tag_catalog_alignment_test.dart`'s G5 test (`pumpTagCatalog` from `support/tag_catalog_harness.dart`): `findsNWidgets(n - 1)` dividers and `n` `MxIconTile`s. That file's G3–G5 edge assertions must stay green unchanged.

- [ ] **Step 2: Run to fail** — FAIL (three `MxCard`s).

- [ ] **Step 3: Shell** — replace `SearchResultShellWidget.build`'s `MxCard.raised(…)` with:

```dart
        child: MxPressable(
          onTap: onOpen,
          shape: MxPressableShape.none,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppSizing.rowMinHeight),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: ExcludeSemantics(
                child: Row(
                  children: <Widget>[
                    MxIconTile(icon: icon),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(child: child),
                    const SizedBox(width: AppSpacing.sm),
                    const MxIcon(Icons.chevron_right, size: MxIconSize.sm),
                  ],
                ),
              ),
            ),
          ),
        ),
```

- [ ] **Step 4: Group** — in `library_search_body_widget.dart` replace each result section's `SliverList.separated` with a `SliverToBoxAdapter(child: MxCard.raised(padding: MxCardPadding.none, child: MxRowGroup(children: [...])))` built from the same item builder (same `ponytail:` comment as Task 15). In `tag_catalog_screen.dart`, wrap the rows the screen builds at ~line 217 the same way; in `TagCatalogRowWidget` swap `_TagWell` for `MxIconTile` and delete `_TagWell`. `wellSize` is also read by `tag_catalog_screen.dart:226-227` (`_rowTextInset`) for the manual `Divider(indent: _rowTextInset, endIndent: AppSpacing.xs)` inside the loop you are replacing — delete the loop, `_rowTextInset` and `wellSize` together. Each row's text children keep `maxLines: 1` + ellipsis (ListRow).

- [ ] **Step 5: Run + commit**

```bash
flutter analyze --no-fatal-infos
flutter test test/features/search test/features/card --exclude-tags golden
git add -A lib test
git commit -m "feat(search): results and tags as grouped handoff rows (M100.xx)"
```

- [ ] **Step 6: Close Phase 3** — P3 (with integration suite — the Library changed shape), P4, P5, P6. WBS goal: "Bề mặt và hàng theo handoff: card 20, MxIconTile, overline caption, hàng 48 gom trên một card, token mastery/status, MxMasteryRing, và hàng deck của Library (đảo M4.12 theo quyết định chủ dự án)." Editable documents add `listtile-deck-row-spec.md`, `lib/features/deck/README.md`.

---

## Phase 4 — inputs and selection (section D)

### Task 17: Text field — filled, ghost edge, 52 tall, 1px focus, error row

**Files:**
- Modify: `lib/core/theme/foundations/app_sizing.dart` (`input`, `inputMultilineMin`)
- Modify: `lib/core/theme/components/inputs/app_input_theme.dart`
- Modify: `lib/shared/widgets/mx_text_field.dart`
- Test: `test/shared/widgets/mx_text_field_contract_test.dart`; move pins in `test/core/theme/contracts/m3_role_bindings_inputs.dart` (the TextField entries), `m3_role_contract_test.dart` (`test('TextField'`), `control_border_grounds_test.dart` (input edge); `m3_combined_state_test.dart` stays green (D27)

**Interfaces:**
- Produces: `AppSizing.input = 52`, `AppSizing.inputMultilineMin = 40`. Theme: `filled: true`, `fillColor: surfaceContainerLowest`, borders at `AppStroke.hairline` — enabled/disabled `outlineVariant` (D2), focused `primary`, error `error` — and focused-error `error` at `AppStroke.focus` (D27), `constraints: BoxConstraints(minHeight: AppSizing.input)`. `MxTextField` renders its error as a caption row led by `Icons.error_outline`, dims the whole field to `AppStateOpacity.disabledContent` when `isEnabled` is false (not `[INFERRED]` in the spec), and a multi-line field takes a 40 minimum with `8/12` padding. Constructor unchanged.

- [ ] **Step 1: Write the failing tests** — append to `mx_text_field_contract_test.dart`:

```dart
  group('handoff TextField (D)', () {
    Future<void> pump(WidgetTester tester, MxTextField field) =>
        tester.pumpWidget(MaterialApp(
          theme: buildLightTheme(),
          home: Scaffold(body: Center(child: field)),
        ));

    test('theme: filled lowest, hairline edges, 52 minimum', () {
      final theme = buildLightTheme();
      final input = theme.inputDecorationTheme;
      final scheme = theme.colorScheme;

      expect(input.filled, isTrue);
      expect(input.fillColor, scheme.surfaceContainerLowest);
      expect(input.constraints?.minHeight, AppSizing.input);
      for (final (border, color, width) in <(InputBorder?, Color, double)>[
        (input.enabledBorder, scheme.outlineVariant, AppStroke.hairline),
        (input.focusedBorder, scheme.primary, AppStroke.hairline),
        (input.errorBorder, scheme.error, AppStroke.hairline),
        // D27: focused and in error keeps the 2 stroke.
        (input.focusedErrorBorder, scheme.error, AppStroke.focus),
      ]) {
        final side = (border! as OutlineInputBorder).borderSide;
        expect(side.color, color);
        expect(side.width, width);
      }
    });

    testWidgets('an error is a caption row led by an alert glyph', (tester) async {
      await pump(tester, MxTextField(
        controller: TextEditingController(),
        label: 'Name',
        errorText: 'Required',
      ));

      final row = find.ancestor(of: find.text('Required'), matching: find.byType(Row)).first;
      expect(find.descendant(of: row, matching: find.byIcon(Icons.error_outline)), findsOneWidget);
      expect(tester.widget<Text>(find.text('Required')).style!.fontSize, 12);
    });

    testWidgets('a disabled field is dimmed as a whole', (tester) async {
      await pump(tester, MxTextField(
        controller: TextEditingController(),
        label: 'Name',
        isEnabled: false,
      ));

      final opacity = tester.widget<Opacity>(
        find.ancestor(of: find.byType(TextField), matching: find.byType(Opacity)).first,
      );
      expect(opacity.opacity, AppStateOpacity.disabledContent);
    });

    testWidgets('a multi-line field drops to a 40 minimum', (tester) async {
      await pump(tester, MxTextField(
        controller: TextEditingController(),
        label: 'Notes',
        minLines: 1,
        maxLines: 4,
      ));

      final decoration = tester.widget<TextField>(find.byType(TextField)).decoration!;
      expect(decoration.constraints?.minHeight, AppSizing.inputMultilineMin);
      expect(
        decoration.contentPadding,
        const EdgeInsets.symmetric(vertical: AppSpacing.sm, horizontal: AppSpacing.md),
      );
    });
  });
```

- [ ] **Step 2: Run to fail** — `flutter test test/shared/widgets/mx_text_field_contract_test.dart` → compile FAIL (`AppSizing.input`).

- [ ] **Step 3: Move the guards first** — `test/core/theme/contracts/m3_role_bindings_inputs.dart`: the TextField enabled-border binding requires `outlineVariant` and refuses `outline`; focused stays `primary`; error and focused-error stay `error` (keep each entry's `scope`; rewrite `because` to cite the handoff TextField spec and D2). `m3_role_contract_test.dart` `test('TextField'`: `enabled border` pins `scheme.outlineVariant`; replace the disabled-edge block (it asserted an edge dimmer than every live one) with `pin('disabled border', t.disabledBorder!.borderSide.color, scheme.outlineVariant)` — the field now dims as a whole, pinned by the Step 1 opacity test. `m3_combined_state_test.dart` `focused error is told apart by the stroke` stays green unchanged (D27). `control_border_grounds_test.dart` measures `semantic.borderControl`, which the outlined button still draws: change its `reason` to name only the outlined button, and add a sibling group `a text field edge on every ground it is drawn on` over the same `groundsOf(theme)` measuring `scheme.outlineVariant`; run it once, read the measured ratios from the failure output, and pin them in that group's own accepted map with the reason `'owner decision 5 (2026-09-13): kit input edge outlineVariant, accepted under 3:1'`.

- [ ] **Step 4: Tokens** — `app_sizing.dart`:

```dart
  /// The handoff text and search field height (`size-input`): a MINIMUM —
  /// large text grows it.
  static const double input = 52;

  /// A multi-line field's minimum (handoff TextField, multiline state).
  static const double inputMultilineMin = 40;
```

- [ ] **Step 5: Theme** — `app_input_theme.dart`:

```dart
InputDecorationTheme buildInputDecorationTheme(
  ColorScheme scheme,
  AppSemanticColors semantic,
  TextTheme texts,
) => InputDecorationTheme(
  filled: true,
  fillColor: scheme.surfaceContainerLowest,
  constraints: const BoxConstraints(minHeight: AppSizing.input),
  contentPadding: const EdgeInsets.symmetric(
    horizontal: AppSpacing.lg,
    vertical: AppSpacing.md,
  ),
  border: _inputBorder(scheme.outlineVariant),
  enabledBorder: _inputBorder(scheme.outlineVariant),
  focusedBorder: _inputBorder(scheme.primary),
  errorBorder: _inputBorder(scheme.error),
  focusedErrorBorder: _inputBorderAt(scheme.error, AppStroke.focus), // D27
  // The field dims as a whole (`MxTextField`), so the edge does not dim again.
  disabledBorder: _inputBorder(scheme.outlineVariant),
  hintStyle: WidgetStateTextStyle.resolveWith(
    (states) => texts.bodyLarge!.copyWith(color: scheme.onSurfaceVariant),
  ),
  suffixIconColor: WidgetStateColor.resolveWith((states) {
    if (states.contains(WidgetState.error)) return semantic.dangerInk;
    return scheme.onSurfaceVariant;
  }),
);

OutlineInputBorder _inputBorder(Color color) =>
    _inputBorderAt(color, AppStroke.hairline);

OutlineInputBorder _inputBorderAt(Color color, double width) =>
    OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: BorderSide(color: color, width: width),
    );
```

Add the `app_sizing.dart` import.

- [ ] **Step 6: Widget** — in `mx_text_field.dart`, where the `InputDecoration` is built:
  - replace `errorText: errorText` with
    ```dart
    error: errorText == null
        ? null
        : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: AppSpacing.xs,
            children: <Widget>[
              const MxIcon(Icons.error_outline, ink: AppInk.danger, size: MxIconSize.xs),
              Flexible(
                child: Text(
                  errorText!,
                  maxLines: _maxMessageLines,
                  style: context.texts.bodySmall!.inked(context, AppInk.danger),
                ),
              ),
            ],
          ),
    ```
    `errorMaxLines` does nothing once `error:` is a widget, so the `Text` carries `_maxMessageLines` itself; keep the file's supporting-line reservation logic as it is;
  - when `maxLines != 1`, set `constraints: const BoxConstraints(minHeight: AppSizing.inputMultilineMin)` and `contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.sm, horizontal: AppSpacing.md)` on that decoration;
  - wrap the returned field in `Opacity(opacity: isEnabled ? 1 : AppStateOpacity.disabledContent, child: …)`.

- [ ] **Step 7: Run + commit**

```bash
flutter analyze --no-fatal-infos
flutter test test/shared test/core/theme test/features --exclude-tags golden
git add -A lib test
git commit -m "feat(design-system): handoff text field — filled, ghost edge, 52 (M100.xx)"
```

### Task 18: Search field and chip

**Files:**
- Modify: `lib/shared/widgets/mx_search_field.dart`
- Modify: `lib/core/theme/components/selection/app_chip_theme.dart` (`_restingFill`)
- Test: `test/shared/widgets/mx_search_field_test.dart`, `test/shared/widgets/mx_pill_button_theme_test.dart`; `m3_role_bindings.dart` (`ChoiceChip._restingFill`)
- Modify: `widgetbook/lib/components/structure_components.dart` (the `MxSearchField` component, ~line 178: voice slot use case)

**Interfaces:**
- Produces: `MxSearchField` gains `VoidCallback? onVoice` and `String? voiceSemanticLabel` (both or neither); rest `surfaceContainer` + `outlineVariant` hairline, active `surfaceContainerLowest` + `primary` hairline + accent leading glyph, radius `AppRadius.md`, minimum `AppSizing.input`. Chip unselected fill `surfaceContainer`.

- [ ] **Step 1: Write the failing tests** — in `mx_search_field_test.dart` (its helper is `pump(tester, {String value = '', int? resultCount, bool disableAnimations = false, ValueChanged<String>? onChanged})`):

```dart
  testWidgets('rest: surfaceContainer, ghost hairline, radius 12, 52 tall', (tester) async {
    await pump(tester);
    final box = tester.widget<AnimatedContainer>(find.byType(AnimatedContainer)).decoration! as BoxDecoration;
    final scheme = buildLightTheme().colorScheme;
    expect(box.color, scheme.surfaceContainer);
    expect(box.borderRadius, BorderRadius.circular(AppRadius.md));
    expect((box.border! as Border).top.color, scheme.outlineVariant);
    expect((box.border! as Border).top.width, AppStroke.hairline);
    expect(tester.getSize(find.byType(AnimatedContainer)).height, greaterThanOrEqualTo(AppSizing.input));
  });

  testWidgets('active: lowest fill, primary hairline', (tester) async {
    await pump(tester);
    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();
    final box = tester.widget<AnimatedContainer>(find.byType(AnimatedContainer)).decoration! as BoxDecoration;
    final scheme = buildLightTheme().colorScheme;
    expect(box.color, scheme.surfaceContainerLowest);
    expect((box.border! as Border).top.color, scheme.primary);
  });

  testWidgets('empty with onVoice shows a mic; a query swaps it for clear', (tester) async {
    await pump(tester, onVoice: () {});
    expect(find.byIcon(Icons.mic_none), findsOneWidget);
    await pump(tester, value: 'kim', onVoice: () {});
    expect(find.byIcon(Icons.mic_none), findsNothing);
    expect(find.byIcon(Icons.close), findsOneWidget);
  });
```

Extend the file's `pump` helper with `VoidCallback? onVoice` and pass `onVoice: onVoice, voiceSemanticLabel: onVoice == null ? null : 'Voice search'` to `MxSearchField`. The field is driven by `value`, so a query is a second pump, not typing. In `mx_pill_button_theme_test.dart` move the unselected fill expectation to `scheme.surfaceContainer`.

- [ ] **Step 2: Run to fail** — `flutter test test/shared/widgets/mx_search_field_test.dart test/shared/widgets/mx_pill_button_theme_test.dart` → FAIL.

- [ ] **Step 3: Chip** — `app_chip_theme.dart:86`: `isSelected ? scheme.primaryContainer : scheme.surfaceContainerLow` → `… : scheme.surfaceContainer`. `m3_role_bindings.dart` `_restingFill`: `requires: <String>['primaryContainer', 'surfaceContainer']`, `refuses: <String>['secondaryContainer', 'surfaceContainerLow']` (keep `scope`, rewrite `because` to cite the handoff Chip spec); `m3_role_contract_test.dart` `test('ChoiceChip'` `unselected fill` → `scheme.surfaceContainer`. Update `tokyo-component-mapping.md` §2 ChoiceChip unselected row.

- [ ] **Step 4: Search field** — in `mx_search_field.dart`:
  - `_fieldInset = (AppSizing.touchTarget - _lineHeight) / 2` → `(AppSizing.input - _lineHeight) / 2`, and `BoxConstraints(minHeight: AppSizing.touchTarget)` → `AppSizing.input`;
  - the decoration:
    ```dart
      decoration: BoxDecoration(
        color: _hasFocus ? colors.surfaceContainerLowest : colors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: _hasFocus ? colors.primary : colors.outlineVariant,
          width: AppStroke.hairline,
          strokeAlign: BorderSide.strokeAlignOutside,
        ),
      ),
    ```
  - leading glyph `MxIcon(Icons.search, size: MxIconSize.xs, ink: _hasFocus ? AppInk.accent : AppInk.quiet)` (drop `const`);
  - add fields + assert:
    ```dart
    this.onVoice,
    this.voiceSemanticLabel,
    ```
    ```dart
    : assert(
        (onVoice == null) == (voiceSemanticLabel == null),
        'A voice slot has a callback and a label, or it is absent.',
      )
    ```
    and after the `if (hasQuery) ...[...]` block:
    ```dart
          if (!hasQuery && widget.onVoice != null)
            MxIconButton(
              icon: Icons.mic_none,
              semanticLabel: widget.voiceSemanticLabel!,
              onPressed: widget.onVoice,
            ),
    ```
  No production caller passes `onVoice` (owner decision 10). If `MxSearchField` already has a constructor initializer list, merge the assert into it.

- [ ] **Step 5: Widgetbook** — in the `MxSearchField` component add a use case "Voice slot" passing `onVoice: _noop, voiceSemanticLabel: 'Voice search'`.

- [ ] **Step 6: Run + commit**

```bash
flutter test test/shared test/core/theme --exclude-tags golden
git add -A lib test widgetbook/lib docs/design-system/tokyo-component-mapping.md
git commit -m "feat(design-system): handoff search field and chip resting fill (M100.xx)"
```

### Task 19: Switch — 44 × 26 track, 20 thumb on `surfaceBright`

**Files:**
- Modify: `lib/core/theme/foundations/app_sizing.dart`, `app_durations.dart`
- Create: `lib/shared/widgets/mx_switch.dart`, `test/shared/widgets/mx_switch_test.dart`
- Modify: `lib/shared/widgets/mx_switch_row.dart`
- Modify: `lib/core/theme/components/selection/app_toggle_themes.dart` (raw `Switch` follows the kit too)
- Test: `test/shared/widgets/mx_switch_row_test.dart:51` and `test/features/reminder/presentation/reminder_settings_a11y_test.dart:65` (both read semantics off `find.byType(SwitchListTile)` → `find.byType(MxSwitchRow)`); `test/app/router/settings_reminder_entry_test.dart:135` (`SwitchListTile` findsNothing → `MxSwitch` findsNothing); `m3_role_bindings.dart` and `m3_role_contract_test.dart` `test('Switch'` (thumb, track outline); `test/core/theme/components/app_toggle_themes_test.dart`
- Docs: `docs/design-system/switch-spec.md` (resolution note)

**Interfaces:**
- Produces: `AppSizing.switchTrackWidth = 44`, `switchTrackHeight = 26`, `switchThumb = 20`, `switchThumbInset = 3`; `AppDurations.toggle = Duration(milliseconds: 160)`; `const MxSwitch({required bool value, required ValueChanged<bool>? onChanged})` (visual only — no semantics of its own); `MxSwitchRow` keeps its constructor and becomes a 48-minimum row with one toggled semantics node.

Material's `Switch` track is fixed at 52 × 32 in `_SwitchConfigM3`; no theme slot reaches 44 × 26, so the handoff geometry needs its own paint. Disabled stays per-slot colours (D3).

- [ ] **Step 1: Write the failing test** — `test/shared/widgets/mx_switch_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/foundations/app_sizing.dart';
import 'package:memox/shared/widgets/mx_switch_row.dart';
import 'package:memox/shared/widgets/mx_switch.dart';

/// Handoff Switch (D): 44 × 26 track, 20 thumb inset 3, `surfaceBright` thumb,
/// `surfaceContainerHighest` off / `primary` on, 160ms.
void main() {
  Future<void> pump(WidgetTester tester, {required bool isOn, ValueChanged<bool>? onChanged}) =>
      tester.pumpWidget(MaterialApp(
        theme: buildLightTheme(),
        home: Scaffold(
          body: MxSwitchRow(label: 'Reminders', isOn: isOn, onChanged: onChanged),
        ),
      ));

  testWidgets('track and thumb geometry', (tester) async {
    await pump(tester, isOn: false, onChanged: (_) {});
    expect(tester.getSize(find.byType(MxSwitch)),
        const Size(AppSizing.switchTrackWidth, AppSizing.switchTrackHeight));

    final thumb = find.descendant(
      of: find.byType(MxSwitch),
      matching: find.byWidgetPredicate((w) =>
          w is SizedBox && w.width == AppSizing.switchThumb && w.height == AppSizing.switchThumb),
    );
    expect(thumb, findsOneWidget);
    final track = tester.getRect(find.byType(MxSwitch));
    expect(tester.getRect(thumb).left - track.left, AppSizing.switchThumbInset);

    await pump(tester, isOn: true, onChanged: (_) {});
    await tester.pumpAndSettle();
    expect(tester.getRect(thumb).left - tester.getRect(find.byType(MxSwitch)).left,
        AppSizing.switchTrackWidth - AppSizing.switchThumb - AppSizing.switchThumbInset);
  });

  testWidgets('colours: track off/on, thumb surfaceBright', (tester) async {
    final scheme = buildLightTheme().colorScheme;
    Color trackColor() => ((tester.widget<AnimatedContainer>(find.descendant(
          of: find.byType(MxSwitch), matching: find.byType(AnimatedContainer))).decoration!)
        as BoxDecoration).color!;

    await pump(tester, isOn: false, onChanged: (_) {});
    expect(trackColor(), scheme.surfaceContainerHighest);
    await pump(tester, isOn: true, onChanged: (_) {});
    await tester.pumpAndSettle();
    expect(trackColor(), scheme.primary);
  });

  testWidgets('the row toggles and announces one toggled node', (tester) async {
    final handle = tester.ensureSemantics();
    bool? changed;
    await pump(tester, isOn: false, onChanged: (v) => changed = v);

    await tester.tap(find.text('Reminders'));
    expect(changed, isTrue);

    final node = tester.getSemantics(find.byType(MxSwitchRow));
    expect(node.label, 'Reminders');
    expect(node.flagsCollection.hasToggledState, isTrue);
    expect(node.flagsCollection.isToggled, isFalse);
    expect(tester.getSize(find.byType(MxSwitchRow)).height,
        greaterThanOrEqualTo(AppSizing.touchTarget));
    handle.dispose();
  });

  testWidgets('a null handler disables the row and says so', (tester) async {
    final handle = tester.ensureSemantics();
    await pump(tester, isOn: true);
    final node = tester.getSemantics(find.byType(MxSwitchRow));
    expect(node.flagsCollection.hasEnabledState, isTrue);
    expect(node.flagsCollection.isEnabled, isFalse);
    handle.dispose();
  });
}
```

If the SDK's `SemanticsFlags` accessors differ in 3.44.8, use the ones `mx_switch_row_test.dart` already uses.

- [ ] **Step 2: Run to fail** — `flutter test test/shared/widgets/mx_switch_test.dart` → compile FAIL.

- [ ] **Step 3: Tokens** — `app_sizing.dart`:

```dart
  /// Handoff Switch geometry (FIXED): a 44 × 26 track, a 20 thumb, 3 in from
  /// the track's edge. The row around it carries the 48 target.
  static const double switchTrackWidth = 44;
  static const double switchTrackHeight = 26;
  static const double switchThumb = 20;
  static const double switchThumbInset = 3;
```

`app_durations.dart`: `/// Handoff Switch: track colour and thumb offset. static const Duration toggle = Duration(milliseconds: 160);`

- [ ] **Step 4: `MxSwitch`** — `lib/shared/widgets/mx_switch.dart`:

```dart
import 'package:flutter/material.dart';

import '../../core/theme/extensions/theme_context_extension.dart';
import '../../core/theme/foundations/app_durations.dart';
import '../../core/theme/foundations/app_elevation.dart';
import '../../core/theme/foundations/app_motion_policy.dart';
import '../../core/theme/foundations/app_radius.dart';
import '../../core/theme/foundations/app_sizing.dart';

/// The handoff Switch's paint: track and thumb, nothing else. It has no
/// semantics and no gesture — `MxSwitchRow` owns both, so the state is
/// announced once.
class MxSwitch extends StatelessWidget {
  const MxSwitch({required this.value, required this.onChanged, super.key});

  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final semantic = context.semanticColors;
    final isEnabled = onChanged != null;
    final Color track = switch ((isEnabled, value)) {
      (false, _) => semantic.disabledSurface,
      (true, true) => scheme.primary,
      (true, false) => scheme.surfaceContainerHighest,
    };
    final Color thumb = isEnabled ? scheme.surfaceBright : semantic.onDisabled;
    final duration = AppMotionPolicy.durationOf(context, AppDurations.toggle);

    return AnimatedContainer(
      duration: duration,
      curve: AppDurations.standard,
      width: AppSizing.switchTrackWidth,
      height: AppSizing.switchTrackHeight,
      decoration: BoxDecoration(
        color: track,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: AnimatedAlign(
        duration: duration,
        curve: AppDurations.standard,
        alignment: value
            ? AlignmentDirectional.centerEnd
            : AlignmentDirectional.centerStart,
        child: Padding(
          padding: const EdgeInsets.all(AppSizing.switchThumbInset),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: thumb,
              shape: BoxShape.circle,
              boxShadow: shadowsFor(AppElevation.card, scheme),
            ),
            child: const SizedBox.square(dimension: AppSizing.switchThumb),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 5: `MxSwitchRow`** — replace its `build` (keep the class doc; rewrite its "One state channel" comment to describe the new structure):

```dart
  @override
  Widget build(BuildContext context) {
    final isEnabled = onChanged != null;
    return MergeSemantics(
      child: Semantics(
        toggled: isOn,
        enabled: isEnabled,
        child: MxFocusRing(
          borderRadius: BorderRadius.zero,
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: isEnabled ? () => onChanged!(!isOn) : null,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: AppSizing.touchTarget),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        label,
                        style: context.texts.bodyLarge!.inked(
                          context,
                          isEnabled ? AppInk.stated : AppInk.disabled,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    ExcludeSemantics(child: MxSwitch(value: isOn, onChanged: onChanged)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
```

Imports: `app_ink.dart`, `app_sizing.dart`, `app_spacing.dart`, `mx_focus_ring.dart`, `mx_switch.dart`. If `MxFocusRing` requires more parameters, copy its call from `mx_list_tile.dart`.

- [ ] **Step 6: Raw theme and guard** — `app_toggle_themes.dart` `buildSwitchTheme`: `thumbColor` → disabled `semantic.onDisabled`, otherwise `scheme.surfaceBright`; `trackOutlineColor` → `const WidgetStatePropertyAll<Color>(Colors.transparent)`. `m3_role_bindings.dart`: Switch `thumbColor` `requires: <String>['surfaceBright']`, `refuses: <String>['outline', 'onPrimary']`; `trackOutlineColor` `requires: <String>[]`, `refuses: <String>['primary', 'outline']`. Move the matching pins in `app_toggle_themes_test.dart`, and in `m3_role_contract_test.dart` `test('Switch'`: `off thumb` and `on thumb` → `scheme.surfaceBright`, `off track outline` and `on track outline` → `Colors.transparent`. Rewrite the comment above `trackOutlineColor` in `app_toggle_themes.dart` (~lines 96–106): it explains a three-branch resolver that no longer exists. Point the three `SwitchListTile` finders named under Files at the new types.

- [ ] **Step 7: Docs** — `switch-spec.md` §5: "**Đã thực hiện theo handoff (M100.xx):** `MxSwitch` vẽ track 44×26, thumb 20 `surfaceBright`; disabled giữ màu từng slot (D3)."

- [ ] **Step 8: Run + commit**

```bash
flutter analyze --no-fatal-infos
flutter test test/shared test/core/theme test/features/reminder test/features/settings --exclude-tags golden
git add -A lib test docs/design-system/switch-spec.md
git commit -m "feat(design-system): handoff switch — 44x26 track, surfaceBright thumb (M100.xx)"
```

### Task 20: `MxSlider` and `MxSegmentedControl` (owner decision 10)

**Files:**
- Modify: `lib/core/theme/components/selection/app_slider_theme.dart` (inactive track)
- Create: `lib/shared/widgets/mx_slider.dart`, `lib/shared/widgets/mx_segmented_control.dart`
- Create: `test/shared/widgets/mx_slider_test.dart`, `test/shared/widgets/mx_segmented_control_test.dart`
- Modify: `widgetbook/lib/components/control_components.dart` (+ registration in `widgetbook/lib/main.dart`)

**Interfaces:**
- Produces: `MxSlider({required double value, required ValueChanged<double>? onChanged, required String semanticLabel, double min = 0, double max = 1, int? divisions})`; `class MxSegment<T> { const MxSegment({required T value, required String label}); }`; `MxSegmentedControl<T>({required List<MxSegment<T>> segments, required T selected, required ValueChanged<T> onChanged})` with 2–3 segments. No production caller.

The kit's segmented control is a `surfaceContainer` track with a floating `surfaceContainerLowest` pill — not M3's outlined `SegmentedButton`, which no theme slot turns into a track. The unused `SegmentedButtonThemeData` stays as it is.

- [ ] **Step 1: Write the failing tests** — `test/shared/widgets/mx_segmented_control_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/foundations/app_elevation.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_sizing.dart';
import 'package:memox/shared/widgets/mx_segmented_control.dart';

enum _Range { week, month, year }

void main() {
  Future<void> pump(WidgetTester tester, {_Range selected = _Range.week, ValueChanged<_Range>? onChanged}) =>
      tester.pumpWidget(MaterialApp(
        theme: buildLightTheme(),
        home: Scaffold(
          body: Center(
            child: MxSegmentedControl<_Range>(
              segments: const <MxSegment<_Range>>[
                MxSegment(value: _Range.week, label: 'Week'),
                MxSegment(value: _Range.month, label: 'Month'),
                MxSegment(value: _Range.year, label: 'Year'),
              ],
              selected: selected,
              onChanged: onChanged ?? (_) {},
            ),
          ),
        ),
      ));

  testWidgets('track is surfaceContainer, the selected pill is lowest + shadow-soft', (tester) async {
    final scheme = buildLightTheme().colorScheme;
    await pump(tester);

    final track = tester.widget<DecoratedBox>(find.descendant(
      of: find.byType(MxSegmentedControl<_Range>), matching: find.byType(DecoratedBox)).first);
    expect((track.decoration as BoxDecoration).color, scheme.surfaceContainer);
    expect((track.decoration as BoxDecoration).borderRadius, BorderRadius.circular(AppRadius.full));

    final pill = tester.widget<AnimatedContainer>(find.ancestor(
      of: find.text('Week'), matching: find.byType(AnimatedContainer)).first);
    final decoration = pill.decoration! as BoxDecoration;
    expect(decoration.color, scheme.surfaceContainerLowest);
    expect(decoration.boxShadow, shadowsFor(AppElevation.card, scheme));
    expect(tester.getSize(find.byType(MxSegmentedControl<_Range>)).height,
        greaterThanOrEqualTo(AppSizing.touchTarget));
  });

  testWidgets('tapping a segment selects it; semantics say which', (tester) async {
    final handle = tester.ensureSemantics();
    _Range? picked;
    await pump(tester, onChanged: (v) => picked = v);

    await tester.tap(find.text('Month'));
    expect(picked, _Range.month);
    final week = tester.getSemantics(find.text('Week'));
    expect(week.flagsCollection.isSelected, isTrue);
    expect(week.flagsCollection.isInMutuallyExclusiveGroup, isTrue);
    handle.dispose();
  });

  test('two or three segments only', () {
    expect(
      () => MxSegmentedControl<int>(
        segments: const <MxSegment<int>>[MxSegment(value: 1, label: 'One')],
        selected: 1,
        onChanged: (_) {},
      ),
      throwsAssertionError,
    );
  });
}
```

`test/shared/widgets/mx_slider_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/shared/widgets/mx_slider.dart';

void main() {
  test('theme: primary active, surfaceContainerHighest inactive, 12% halo', () {
    final theme = buildLightTheme();
    final slider = theme.sliderTheme;
    expect(slider.activeTrackColor, theme.colorScheme.primary);
    expect(slider.inactiveTrackColor, theme.colorScheme.surfaceContainerHighest);
    expect(slider.overlayColor, theme.colorScheme.primary.withValues(alpha: 0.12));
  });

  testWidgets('carries its label to semantics and reports changes', (tester) async {
    final handle = tester.ensureSemantics();
    double? value;
    await tester.pumpWidget(MaterialApp(
      theme: buildLightTheme(),
      home: Scaffold(
        body: MxSlider(value: 0.5, onChanged: (v) => value = v, semanticLabel: 'Daily goal'),
      ),
    ));
    expect(find.bySemanticsLabel(RegExp('Daily goal')), findsOneWidget);
    await tester.drag(find.byType(Slider), const Offset(60, 0));
    expect(value, isNotNull);
    handle.dispose();
  });
}
```

- [ ] **Step 2: Run to fail** — both files → compile FAIL; the theme test FAILs on `inactiveTrackColor`.

- [ ] **Step 3: Slider theme** — `app_slider_theme.dart`: `inactiveTrackColor: scheme.secondaryContainer` → `scheme.surfaceContainerHighest`; `inactiveTickMarkColor: scheme.onSecondaryContainer` → `scheme.onSurfaceVariant`. Move `m3_role_contract_test.dart` `test('Slider'` `inactive track` and `inactive tick` to the same roles. `lib/shared/widgets/mx_slider.dart`:

```dart
import 'package:flutter/material.dart';

/// Handoff Slider (D): a scrubber for a bounded value (daily goal, speech
/// rate). The theme owns every colour; this widget only names the control.
class MxSlider extends StatelessWidget {
  const MxSlider({
    required this.value,
    required this.onChanged,
    required this.semanticLabel,
    this.min = 0,
    this.max = 1,
    this.divisions,
    super.key,
  });

  final double value;
  final ValueChanged<double>? onChanged;
  final String semanticLabel;
  final double min;
  final double max;
  final int? divisions;

  @override
  Widget build(BuildContext context) => Semantics(
    label: semanticLabel,
    child: Slider(
      value: value,
      min: min,
      max: max,
      divisions: divisions,
      onChanged: onChanged,
    ),
  );
}
```

- [ ] **Step 4: Segmented control** — `lib/shared/widgets/mx_segmented_control.dart`:

```dart
import 'package:flutter/material.dart';

import '../../core/theme/extensions/app_ink.dart';
import '../../core/theme/extensions/theme_context_extension.dart';
import '../../core/theme/foundations/app_durations.dart';
import '../../core/theme/foundations/app_elevation.dart';
import '../../core/theme/foundations/app_motion_policy.dart';
import '../../core/theme/foundations/app_radius.dart';
import '../../core/theme/foundations/app_sizing.dart';
import '../../core/theme/foundations/app_spacing.dart';

/// One choice in an [MxSegmentedControl].
class MxSegment<T> {
  const MxSegment({required this.value, required this.label});

  final T value;
  final String label;
}

/// The segment's own height: the track's 48 target minus its inset.
const double _segmentMinHeight = AppSizing.touchTarget - AppSpacing.xs * 2;

/// Handoff SegmentedButton (D): 2–3 exclusive choices on a `surfaceContainer`
/// track; the selected one floats as a `surfaceContainerLowest` pill with
/// `shadow-soft`.
class MxSegmentedControl<T> extends StatelessWidget {
  const MxSegmentedControl({
    required this.segments,
    required this.selected,
    required this.onChanged,
    super.key,
  }) : assert(
         segments.length >= 2 && segments.length <= 3,
         'The handoff segmented control holds two or three choices.',
       );

  final List<MxSegment<T>> segments;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final duration = AppMotionPolicy.durationOf(context, AppDurations.fast);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xs),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            for (final segment in segments)
              Flexible(
                child: _Segment(
                  label: segment.label,
                  isSelected: segment.value == selected,
                  duration: duration,
                  onTap: () => onChanged(segment.value),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.isSelected,
    required this.duration,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final Duration duration;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    return Semantics(
      button: true,
      selected: isSelected,
      inMutuallyExclusiveGroup: true,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          customBorder: const StadiumBorder(),
          child: AnimatedContainer(
            duration: duration,
            curve: AppDurations.standard,
            constraints: const BoxConstraints(minHeight: _segmentMinHeight),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected ? scheme.surfaceContainerLowest : null,
              borderRadius: BorderRadius.circular(AppRadius.full),
              boxShadow: isSelected ? shadowsFor(AppElevation.card, scheme) : null,
            ),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.texts.labelLarge!.inked(
                context,
                isSelected ? AppInk.stated : AppInk.quiet,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

If `spacing_is_a_gap_test` or the guard flags `_segmentMinHeight` (a spacing token used inside a dimension), replace it with `AppSizing.segmentMin = 40` (doc: "a segment inside the 48 track") — a raw `48 - 8` is a magic value, not an alternative.

- [ ] **Step 5: Widgetbook** — `control_components.dart`: `MxSegmentedControl` (three segments, stateful selection through a knob) and `MxSlider` (value knob) components; register both in `main.dart`.

- [ ] **Step 6: Run + commit**

```bash
flutter analyze --no-fatal-infos
flutter test test/shared/widgets/mx_segmented_control_test.dart test/shared/widgets/mx_slider_test.dart test/core/theme
python code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v7
git add -A lib test widgetbook/lib
git commit -m "feat(design-system): MxSlider and MxSegmentedControl per the handoff (M100.xx)"
```

- [ ] **Step 7: Close Phase 4** — P3 (with integration suite), P4, P5, P6. WBS goal: "Input theo handoff: text field filled 52 viền ghost, search field + slot voice, chip nền surfaceContainer, switch 44×26, MxSlider và MxSegmentedControl dựng sẵn." Editable documents add `switch-spec.md`.

---

## Phase 5 — chrome and overlays (sections A, G)

### Task 21: Navigation bar — solid surface, primary pill, shadow-chrome

**Files:**
- Modify: `lib/core/theme/foundations/app_elevation.dart` (`_Shadow.chrome`, `chromeShadowsFor`)
- Modify: `lib/core/theme/components/navigation/app_navigation_bar_theme.dart`, `lib/core/theme/app_theme.dart:257`
- Modify: `lib/shared/widgets/mx_navigation_bar.dart`
- Test: `test/shared/widgets/mx_navigation_bar_test.dart`, `test/core/theme/foundations/app_elevation_test.dart`; `m3_role_bindings.dart` (four NavigationBar bindings)

**Interfaces:**
- Produces: `List<BoxShadow> chromeShadowsFor(ColorScheme scheme)` — light `0 -2 12 @5%`, dark `0 -2 14 @36%` of `scheme.shadow`. `buildNavigationBarTheme(ColorScheme scheme, AppSemanticColors semantic, TextTheme texts)` — background `surface` (D7), indicator `primary`, selected glyph `onPrimary`, selected label `semantic.accentInk` (text, owner decision 2), unselected `onSurfaceVariant`.

- [ ] **Step 1: Write the failing tests** — `app_elevation_test.dart`:

```dart
  test('chrome is the handoff shadow-chrome, pointing up', () {
    final light = chromeShadowsFor(buildLightTheme().colorScheme).single;
    expect(light.offset, const Offset(0, -2));
    expect(light.blurRadius, 12);
    expect(light.color.a, closeTo(0.05, 0.002));

    final dark = chromeShadowsFor(buildDarkTheme().colorScheme).single;
    expect(dark.offset, const Offset(0, -2));
    expect(dark.blurRadius, 14);
    expect(dark.color.a, closeTo(0.36, 0.002));
  });
```

`mx_navigation_bar_test.dart`:

```dart
  test('theme: surface bar, primary pill, onPrimary glyph, accentInk label', () {
    for (final theme in <ThemeData>[buildLightTheme(), buildDarkTheme()]) {
      final nav = theme.navigationBarTheme;
      final scheme = theme.colorScheme;
      final semantic = theme.extension<AppSemanticColors>()!;
      const selected = <WidgetState>{WidgetState.selected};

      expect(nav.backgroundColor, scheme.surface);
      expect(nav.indicatorColor, scheme.primary);
      expect(nav.iconTheme!.resolve(selected)!.color, scheme.onPrimary);
      expect(nav.iconTheme!.resolve(<WidgetState>{})!.color, scheme.onSurfaceVariant);
      expect(nav.labelTextStyle!.resolve(selected)!.color, semantic.accentInk);
    }
  });

  testWidgets('the bar paints shadow-chrome instead of a top border', (tester) async {
    await pumpBar(tester);   // the file's existing helper
    final box = tester.widget<DecoratedBox>(find.descendant(
      of: find.byType(MxNavigationBar), matching: find.byType(DecoratedBox)).first);
    final decoration = box.decoration as BoxDecoration;
    expect(decoration.border, isNull);
    expect(decoration.boxShadow, chromeShadowsFor(buildLightTheme().colorScheme));
  });
```

- [ ] **Step 2: Run to fail** — `flutter test test/core/theme/foundations/app_elevation_test.dart test/shared/widgets/mx_navigation_bar_test.dart` → compile FAIL (`chromeShadowsFor`).

- [ ] **Step 3: Guard** — `m3_role_bindings.dart` NavigationBar: `backgroundColor` requires `surface`, refuses `surfaceContainer`, `surfaceContainerHigh`; `indicatorColor` requires `primary`, refuses `secondaryContainer`, `primaryContainer`; `iconTheme` requires `onPrimary`, `onSurfaceVariant`, refuses `onSecondaryContainer`; `labelTextStyle` `requires: <String>['onSurfaceVariant']`, `requiresSemantic: <String>['accentInk']`, refuses `onSecondaryContainer`, `onSurface`. Keep each entry's `scope: 'buildNavigationBarTheme'` and rewrite its `because` to cite owner decision 4. `m3_role_contract_test.dart` `test('NavigationBar'`: `backgroundColor` → `scheme.surface`, `indicatorColor` → `scheme.primary`, `selected icon` → `scheme.onPrimary`, `selected label` → `theme.extension<AppSemanticColors>()!.accentInk`.

- [ ] **Step 4: Shadow** — in `app_elevation.dart`, add to `_Shadow`:

```dart
  /// `shadow-chrome` — pinned chrome (the bottom navigation) over content.
  chrome(
    lightY: -2,
    lightBlur: 12,
    lightAlpha: 0.05,
    darkY: -2,
    darkBlur: 14,
    darkAlpha: 0.36,
  ),
```

and below `_darkDepth`:

```dart
/// The handoff's `shadow-chrome`, for pinned chrome. Not a level on
/// [AppElevation]: it points up, and nothing stacks on it.
List<BoxShadow> chromeShadowsFor(ColorScheme scheme) => <BoxShadow>[
  _Shadow.chrome.paint(
    scheme.shadow,
    isDark: scheme.brightness == Brightness.dark,
  ),
];
```

- [ ] **Step 5: Theme** — `app_navigation_bar_theme.dart`:

```dart
NavigationBarThemeData buildNavigationBarTheme(
  ColorScheme scheme,
  AppSemanticColors semantic,
  TextTheme texts,
) => NavigationBarThemeData(
  // Solid `surface` — the handoff's own fallback for its glass chrome (D7).
  backgroundColor: scheme.surface,
  indicatorColor: scheme.primary,
  iconTheme: WidgetStateProperty.resolveWith(
    (Set<WidgetState> states) => IconThemeData(
      color: states.contains(WidgetState.selected)
          ? scheme.onPrimary
          : scheme.onSurfaceVariant,
    ),
  ),
  // PLAN-DEV-2.4: no selected re-weight — `labelMedium` is already 600 (D1),
  // and component_theme_typography_test asserts both states are the rung.
  labelTextStyle: WidgetStateProperty.resolveWith((Set<WidgetState> states) {
    if (!states.contains(WidgetState.selected)) {
      return texts.labelMedium!.copyWith(color: scheme.onSurfaceVariant);
    }
    return texts.labelMedium!.copyWith(color: semantic.accentInk);
  }),
  surfaceTintColor: Colors.transparent,
  elevation: AppElevation.none,
  labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
);
```

Import `../../foundations/app_semantic_colors.dart`. In `app_theme.dart:257`: `buildNavigationBarTheme(scheme, semantic, texts)` (use the local variable name the file already has for the semantic colours).

- [ ] **Step 6: Widget** — `mx_navigation_bar.dart` `build`: replace the `DecoratedBox(position: DecorationPosition.foreground, decoration: BoxDecoration(border: Border(top: …)))` with

```dart
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colors.surface,
        boxShadow: chromeShadowsFor(context.colors),
      ),
      child: Row(
```

(same child). Import `app_elevation.dart`.

- [ ] **Step 7: Run + commit**

```bash
flutter analyze --no-fatal-infos
flutter test test/core/theme test/shared test/app --exclude-tags golden
git add -A lib test
git commit -m "feat(design-system): handoff navigation bar — primary pill, shadow-chrome (M100.xx)"
```

### Task 22: Breadcrumb — chevron separators, bold current step

**Files:**
- Modify: `lib/shared/widgets/mx_breadcrumb.dart` (separator width, doc at lines ~142–143), `lib/shared/widgets/mx_breadcrumb_step.dart`
- Test: `test/shared/widgets/mx_breadcrumb_test.dart`

**Interfaces:**
- Produces: separators are `Icons.chevron_right` at `MxIconSize.xs`, `AppInk.quiet`; the non-tappable (current) step reads `labelMedium` at `FontWeight.w700` in `AppInk.stated`.

- [ ] **Step 1: Write the failing test** — append inside `main()` of `mx_breadcrumb_test.dart` (its helper is `pump(tester, List<MxBreadcrumbItem> items, {…})`):

```dart
  testWidgets('chevrons separate the steps; the current step is bold', (tester) async {
    await pump(tester, <MxBreadcrumbItem>[
      MxBreadcrumbItem(label: 'Korean', onTap: () {}),
      MxBreadcrumbItem(label: 'Verbs', onTap: () {}),
      MxBreadcrumbItem(label: 'Week 1', onTap: null),
    ]);

    expect(find.text('/'), findsNothing);
    expect(find.byIcon(Icons.chevron_right), findsNWidgets(2));
    final current = tester.widget<Text>(find.text('Week 1'));
    expect(current.style!.fontWeight, FontWeight.w700);
    expect(find.ancestor(of: find.text('Week 1'), matching: find.byType(InkWell)), findsNothing);
  });
```

- [ ] **Step 2: Run to fail** — `flutter test test/shared/widgets/mx_breadcrumb_test.dart` → FAIL (`/` found).

- [ ] **Step 3: Implement** — `mx_breadcrumb_step.dart`:

```dart
class _MxBreadcrumbSeparator extends StatelessWidget {
  const _MxBreadcrumbSeparator();

  @override
  Widget build(BuildContext context) => const ExcludeSemantics(
    child: MxIcon(Icons.chevron_right, ink: AppInk.quiet, size: MxIconSize.xs),
  );
}
```

delete `const String _kSeparator = '/';`, and in the `tap == null` branch set the `Text` style to `AppTypography.withWeight(context.texts.labelMedium!, FontWeight.w700).inked(context, AppInk.stated)`. `mx_breadcrumb.dart`: `final separator = AppSpacing.xs * 2 + widthOf(_kSeparator);` → `final separator = AppSpacing.xs * 2 + AppIconSize.xs;` and measure `items.last.label` with the bold style (`AppTypography.withWeight(style, FontWeight.w700)`) so the fold budget matches what paints. Rewrite the doc sentence "the separator between steps is a slash" → "steps are separated by a 16 chevron".

- [ ] **Step 4: Run + commit**

```bash
flutter test test/shared/widgets/mx_breadcrumb_test.dart test/shared/widgets/mx_breadcrumb_focus_test.dart test/features/deck --exclude-tags golden
git add -A lib test
git commit -m "feat(design-system): breadcrumb chevrons and a bold current step (M100.xx)"
```

### Task 23: Scrim 45%, dialog radius 20, widths 320/340, scale-in

**Files:**
- Modify: `lib/core/theme/components/overlays/app_backdrop_recipe.dart`, `lib/core/theme/components/surfaces/app_dialog_theme.dart`
- Modify: `lib/core/theme/foundations/app_sizing.dart` (`dialogMd`, `dialogLg`)
- Modify: `lib/shared/widgets/mx_dialog_metrics.dart` (inset)
- Create: `lib/shared/widgets/mx_dialog_route.dart`
- Modify: `mx_alert_dialog.dart`, `mx_confirm_dialog.dart`, `mx_async_confirm_dialog.dart`, `mx_form_dialog.dart` (constraints; `showDialog` → `showMxDialog`)
- Test: Create `test/shared/widgets/mx_dialog_route_test.dart`; modify `test/core/theme/components/app_overlay_themes_test.dart`

**Interfaces:**
- Produces: `modalBarrierColor(scheme)` = `scheme.scrim` at `0.45` in both modes. `AppSizing.dialogMd = 320`, `dialogLg = 340` (D5). `MxDialogMetrics.insetPadding = EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.card)`. `Future<T?> showMxDialog<T>(BuildContext context, {required WidgetBuilder builder, bool barrierDismissible = true})` — fade + scale `0.94 → 1` over 200ms `Cubic(0.2,0,0,1)`, instant under reduced motion. Dialog theme: radius `AppRadius.card`, no side, elevation `AppElevation.raised`, `shadowColor: materialShadowColor(scheme)` (D19).

- [ ] **Step 1: Write the failing tests** — `test/shared/widgets/mx_dialog_route_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_sizing.dart';
import 'package:memox/shared/widgets/mx_alert_dialog.dart';
import 'package:memox/shared/widgets/mx_dialog_route.dart';

void main() {
  Future<void> open(WidgetTester tester, {bool disableAnimations = false}) async {
    await tester.pumpWidget(MaterialApp(
      theme: buildLightTheme(),
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: disableAnimations),
        child: Builder(builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => showMxDialog<void>(
              context,
              builder: (_) => const MxAlertDialog(title: 'Heads up', message: 'Body'),
            ),
            child: const Text('open'),
          ),
        )),
      ),
    ));
    await tester.tap(find.text('open'));
  }

  testWidgets('scales in from 0.94 over 200ms', (tester) async {
    await open(tester);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final mid = tester.widget<ScaleTransition>(find.byType(ScaleTransition).last).scale.value;
    expect(mid, inExclusiveRange(0.94, 1.0));

    await tester.pump(const Duration(milliseconds: 120));
    expect(tester.widget<ScaleTransition>(find.byType(ScaleTransition).last).scale.value, 1.0);
  });

  testWidgets('reduced motion opens at full scale on the first frame', (tester) async {
    await open(tester, disableAnimations: true);
    await tester.pump();
    expect(find.text('Heads up'), findsOneWidget);
    expect(tester.widget<ScaleTransition>(find.byType(ScaleTransition).last).scale.value, 1.0);
  });

  testWidgets('an alert dialog is md 320 at most, radius 20', (tester) async {
    await open(tester);
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(AlertDialog)).width, lessThanOrEqualTo(AppSizing.dialogMd));
    final shape = buildLightTheme().dialogTheme.shape! as RoundedRectangleBorder;
    expect(shape.borderRadius, BorderRadius.circular(AppRadius.card));
    expect(shape.side, BorderSide.none);
  });
}
```

Use `MxAlertDialog`'s real required parameters (read its constructor at line 31). In `app_overlay_themes_test.dart` move the barrier expectations to `scheme.scrim.withValues(alpha: 0.45)` for both themes.

- [ ] **Step 2: Run to fail** — `flutter test test/shared/widgets/mx_dialog_route_test.dart test/core/theme/components/app_overlay_themes_test.dart` → compile FAIL.

- [ ] **Step 3: Scrim + theme + tokens**

`app_backdrop_recipe.dart`:

```dart
import 'package:flutter/material.dart';

/// Handoff Scrim: the `scrim` role at 45%, in both modes.
const double _scrimAlpha = 0.45;

Color modalBarrierColor(ColorScheme scheme) =>
    scheme.scrim.withValues(alpha: _scrimAlpha);
```

`app_dialog_theme.dart`:

```dart
DialogThemeData buildDialogTheme(ColorScheme scheme, TextTheme texts) =>
    DialogThemeData(
      barrierColor: modalBarrierColor(scheme),
      backgroundColor: scheme.surfaceContainerHigh,
      surfaceTintColor: Colors.transparent,
      // `shadow-card` has no DialogThemeData slot; the raised elevation's
      // Material shadow stands in for it (D19), and is transparent in dark.
      elevation: AppElevation.raised,
      shadowColor: materialShadowColor(scheme),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      titleTextStyle: texts.titleMedium?.copyWith(color: scheme.onSurface),
      contentTextStyle: texts.bodyMedium?.copyWith(
        color: scheme.onSurfaceVariant,
      ),
    );
```

`app_sizing.dart`:

```dart
  /// Handoff Dialog maximum widths (D5): confirm/alert `md`, forms `lg`.
  static const double dialogMd = 320;
  static const double dialogLg = 340;
```

`mx_dialog_metrics.dart`: `static const double inset = 40;` → `static const double inset = AppSpacing.xl;` and `insetPadding` → `EdgeInsets.symmetric(horizontal: inset, vertical: AppSpacing.card)`. No test pins the dialog's elevation today: add `expect(theme.dialogTheme.elevation, AppElevation.raised)` and `expect(theme.dialogTheme.shadowColor, materialShadowColor(theme.colorScheme))` for both themes to `app_overlay_themes_test.dart`.

- [ ] **Step 4: Route** — `lib/shared/widgets/mx_dialog_route.dart`:

```dart
import 'package:flutter/material.dart';

import '../../core/theme/foundations/app_durations.dart';

/// Handoff Dialog enter: scale 0.94 → 1 with a fade.
const double _enterScale = 0.94;

/// A Material dialog route with the handoff's enter motion. Everything else —
/// barrier, safe area, captured themes — is `DialogRoute`'s.
class MxDialogRoute<T> extends DialogRoute<T> {
  MxDialogRoute({
    required super.context,
    required super.builder,
    required super.themes,
    required super.barrierColor,
    required super.animationStyle,
    super.barrierDismissible,
    super.barrierLabel,
  });

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(parent: animation, curve: AppDurations.standard);
    return FadeTransition(
      opacity: curved,
      child: ScaleTransition(
        scale: Tween<double>(begin: _enterScale, end: 1).animate(curved),
        child: child,
      ),
    );
  }
}

/// `showDialog` with the handoff's motion. Same root-navigator and theme
/// capture `showDialog` does.
Future<T?> showMxDialog<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) {
  final navigator = Navigator.of(context, rootNavigator: true);
  return navigator.push<T>(
    MxDialogRoute<T>(
      context: context,
      builder: builder,
      themes: InheritedTheme.capture(from: context, to: navigator.context),
      barrierColor: DialogTheme.of(context).barrierColor,
      barrierDismissible: barrierDismissible,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      animationStyle: MediaQuery.disableAnimationsOf(context)
          ? AnimationStyle.noAnimation
          : const AnimationStyle(
              duration: AppDurations.normal,
              reverseDuration: AppDurations.normal,
            ),
    ),
  );
}
```

Verify the SDK constructor first: `grep -n "class DialogRoute" -A40 D:/Setup/flutter/packages/flutter/lib/src/material/dialog.dart`. If `DialogRoute` has no `animationStyle` parameter in 3.44.8, drop that argument and override `Duration get transitionDuration` / `reverseTransitionDuration` returning `AppDurations.normal` (and `Duration.zero` when a `bool reduceMotion` field — captured in `showMxDialog` from `MediaQuery.disableAnimationsOf` — is true). `DialogTheme.of(context).barrierColor` is non-null here because `buildDialogTheme` sets it; if the analyzer wants a `Color`, add `!`.

- [ ] **Step 5: Callers** — in the four dialog files replace `showDialog<X>(context: context, builder: …, barrierDismissible: …)` with `showMxDialog<X>(context, builder: …, barrierDismissible: …)` carrying the same arguments, and give each `AlertDialog(…)` a `constraints: const BoxConstraints(maxWidth: AppSizing.dialogMd)` — `mx_form_dialog.dart` uses `AppSizing.dialogLg`. Leave `insetPadding: MxDialogMetrics.insetPadding` where it is; add it to `mx_alert_dialog.dart` if absent.

- [ ] **Step 6: Run + commit**

```bash
flutter analyze --no-fatal-infos
flutter test test/shared test/core/theme test/features --exclude-tags golden
git add -A lib test
git commit -m "feat(design-system): scrim 45%, dialog 20 radius, handoff widths and scale-in (M100.xx)"
```

### Task 24: Bottom sheet — container high, 20 top corners, 36×4 grabber, 85% cap

**Files:**
- Modify: `lib/core/theme/foundations/app_sizing.dart`, `app_durations.dart`
- Modify: `lib/core/theme/components/surfaces/app_bottom_sheet_theme.dart`, `lib/shared/widgets/mx_sheet.dart` (`showMxSheet`)
- Test: `test/core/theme/components/app_overlay_themes_test.dart`, `test/shared/widgets/mx_sheet_test.dart`, `test/core/theme/contracts/m3_role_contract_test.dart` (`test('BottomSheet'`: `backgroundColor` → `surfaceContainerHigh`, `drag handle` → `outlineVariant`)

**Interfaces:**
- Produces: `AppSizing.sheetHandleWidth = 36`, `sheetHandleHeight = 4`; `AppDurations.sheet = Duration(milliseconds: 260)`. Theme: background `surfaceContainerHigh`, top radius `AppRadius.card` (D12), handle `outlineVariant` at 36 × 4. `showMxSheet` caps height at 85% of the screen and animates 260ms `Cubic(0.2,0,0,1)` (D20). No sheet shadow (D21).

- [ ] **Step 1: Write the failing tests** — `app_overlay_themes_test.dart`:

```dart
  test('sheet: container high, 20 top corners, 36x4 outlineVariant grabber', () {
    for (final theme in <ThemeData>[buildLightTheme(), buildDarkTheme()]) {
      final sheet = theme.bottomSheetTheme;
      final scheme = theme.colorScheme;
      expect(sheet.backgroundColor, scheme.surfaceContainerHigh);
      expect(sheet.dragHandleSize, const Size(36, 4));
      expect(sheet.dragHandleColor, isA<WidgetStateColor>());
      expect((sheet.dragHandleColor! as WidgetStateColor).resolve(<WidgetState>{}),
          scheme.outlineVariant);
      expect(
        (sheet.shape! as RoundedRectangleBorder).borderRadius,
        const BorderRadius.vertical(top: Radius.circular(AppRadius.card)),
      );
    }
  });
```

`mx_sheet_test.dart`:

```dart
  testWidgets('a tall sheet stops at 85% of the screen', (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(
      theme: buildLightTheme(),
      home: Builder(builder: (context) => Scaffold(
        body: TextButton(
          onPressed: () => showMxSheet<void>(
            context,
            builder: (_) => const SingleChildScrollView(child: SizedBox(height: 2000)),
          ),
          child: const Text('open'),
        ),
      )),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(tester.getSize(find.byType(BottomSheet)).height, lessThanOrEqualTo(852 * 0.85));
  });
```

- [ ] **Step 2: Run to fail** — both files → FAIL.

- [ ] **Step 3: Tokens** — `app_sizing.dart`: `/// Handoff BottomSheet grabber: 36 × 4. static const double sheetHandleWidth = 36; static const double sheetHandleHeight = 4;` · `app_durations.dart`: `/// Handoff BottomSheet enter. static const Duration sheet = Duration(milliseconds: 260);`

- [ ] **Step 4: Theme** — `app_bottom_sheet_theme.dart`:

```dart
BottomSheetThemeData buildBottomSheetTheme(ColorScheme scheme) =>
    BottomSheetThemeData(
      modalBarrierColor: modalBarrierColor(scheme),
      backgroundColor: scheme.surfaceContainerHigh,
      surfaceTintColor: Colors.transparent,
      elevation: AppElevation.none,
      showDragHandle: true,
      dragHandleSize: const Size(
        AppSizing.sheetHandleWidth,
        AppSizing.sheetHandleHeight,
      ),
      dragHandleColor: WidgetStateColor.resolveWith((states) {
        if (states.contains(WidgetState.dragged) ||
            states.contains(WidgetState.hovered)) {
          return Color.alphaBlend(
            scheme.onSurface.withValues(alpha: AppStateOpacity.pressed),
            scheme.outlineVariant,
          );
        }
        return scheme.outlineVariant;
      }),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.card)),
      ),
    );
```

Import `app_sizing.dart`. Keep the file's doc comments; where they argue the handle's `onSurfaceVariant` contrast, restate them for `outlineVariant` — a kit control edge accepted under 3:1 (owner decision 5).

- [ ] **Step 5: `showMxSheet`**:

```dart
/// Handoff BottomSheet: caps at 85% of the screen and scrolls inside.
const double _maxHeightFraction = 0.85;

Future<T?> showMxSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) {
  return showModalBottomSheet<T>(
    context: context,
    useRootNavigator: true,
    useSafeArea: true,
    isScrollControlled: true,
    constraints: BoxConstraints(
      maxHeight: MediaQuery.sizeOf(context).height * _maxHeightFraction,
    ),
    sheetAnimationStyle:
        AppMotionPolicy.animationStyleOf(context) ??
        const AnimationStyle(
          duration: AppDurations.sheet,
          reverseDuration: AppDurations.sheet,
          curve: AppDurations.standard,
        ),
    builder: builder,
  );
}
```

- [ ] **Step 6: Run + commit** — `flutter test test/shared test/core/theme test/features --exclude-tags golden`. A sheet test that asserted a height above 85% moves; a sheet whose body overflows at the cap is a real bug — its body needs its own scroll view, fix it in this task.

```bash
git add -A lib test
git commit -m "feat(design-system): handoff bottom sheet — container high, 20 corners, 85% cap (M100.xx)"
```

### Task 25: Callout tones and the offline banner

**Files:**
- Modify: `lib/shared/widgets/mx_card.dart` (`MxCardFeedbackTone` + fill + edge)
- Modify: `lib/shared/widgets/mx_feedback_band.dart` (`MxFeedbackTone`)
- Test: `test/shared/widgets/mx_surface_components_test.dart` (or the file that already covers `MxFeedbackBand` — `grep -rl MxFeedbackBand test`)
- Modify: `widgetbook/lib/components/feedback_components.dart`

**Interfaces:**
- Produces: `enum MxCardFeedbackTone { danger, warning, info, success }`; `enum MxFeedbackTone { danger, warning, info, success, offline }`. Fill: danger `errorContainer` · warning `warningContainer` · info `infoContainer` · success `successContainer` · offline = warning. Edge (hairline, "matching border"): `error` · `warning` · `primary` · `mastery`. Ink: `onErrorContainer` · `onWarningContainer` · `onInfoContainer` · `onSuccessContainer`. Glyph: `error_outline` · `warning_amber_outlined` · `info_outline` · `check_circle_outline` · `cloud_off_outlined`. Existing callers (danger, warning) keep their API.

- [ ] **Step 1: Write the failing test**:

```dart
  for (final (tone, icon) in <(MxFeedbackTone, IconData)>[
    (MxFeedbackTone.danger, Icons.error_outline),
    (MxFeedbackTone.warning, Icons.warning_amber_outlined),
    (MxFeedbackTone.info, Icons.info_outline),
    (MxFeedbackTone.success, Icons.check_circle_outline),
    (MxFeedbackTone.offline, Icons.cloud_off_outlined),
  ]) {
    testWidgets('$tone band: tinted fill, matching hairline, its glyph', (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: buildLightTheme(),
        home: Scaffold(body: MxFeedbackBand(title: 'T', message: 'M', tone: tone)),
      ));
      expect(find.byIcon(icon), findsOneWidget);

      final theme = buildLightTheme();
      final scheme = theme.colorScheme;
      final semantic = theme.extension<AppSemanticColors>()!;
      final (Color fill, Color edge) = switch (tone) {
        MxFeedbackTone.danger => (scheme.errorContainer, scheme.error),
        MxFeedbackTone.warning || MxFeedbackTone.offline => (semantic.warningContainer, semantic.warning),
        MxFeedbackTone.info => (semantic.infoContainer, scheme.primary),
        MxFeedbackTone.success => (semantic.successContainer, semantic.mastery),
      };
      final box = tester.widget<DecoratedBox>(find.descendant(
        of: find.byType(MxCard), matching: find.byType(DecoratedBox)).first);
      final decoration = box.decoration as BoxDecoration;
      expect(decoration.color, fill);
      expect((decoration.border! as Border).top.color, edge);
    });
  }
```

(If `MxCard` paints its edge through another channel than `BoxDecoration.border`, assert that channel; the expected colours stand.)

- [ ] **Step 2: Run to fail** — compile FAIL (`MxFeedbackTone.info`). Once the enums compile, the danger and warning cases still fail on `decoration.border!`: feedback cards draw no edge yet.

- [ ] **Step 3: Card recipe** — `mx_card.dart`: add `info` and `success` to `MxCardFeedbackTone` (one doc line each); in `_fillColor`'s feedback arm add `MxCardFeedbackTone.info => semantic.infoContainer,` and `MxCardFeedbackTone.success => semantic.successContainer,`; in `_restingEdgeColor`, right before its final `return switch (widget._spec.edge)`, add

```dart
    if (widget._spec.fill == _MxCardFill.feedback) {
      return switch (widget._tone!) {
        MxCardFeedbackTone.danger => colors.error,
        MxCardFeedbackTone.warning => semantic.warning,
        MxCardFeedbackTone.info => colors.primary,
        MxCardFeedbackTone.success => semantic.mastery,
      };
    }
```

`build` already paints a non-null resting edge as `Border.all(color: restingEdge)` (1px). Feedback cards drew no edge at `dcd22f32`; this is the handoff's "matching border".

- [ ] **Step 4: Band** — `mx_feedback_band.dart`: extend `MxFeedbackTone` with `info`, `success`, `offline` (doc: "connectivity lost — non-blocking; no stream is wired yet, owner decision 10") and the three switches:

```dart
    final AppInk ink = switch (tone) {
      MxFeedbackTone.danger => AppInk.onErrorContainer,
      MxFeedbackTone.warning || MxFeedbackTone.offline => AppInk.onWarningContainer,
      MxFeedbackTone.info => AppInk.onInfoContainer,
      MxFeedbackTone.success => AppInk.onSuccessContainer,
    };
    final IconData icon = switch (tone) {
      MxFeedbackTone.danger => Icons.error_outline,
      MxFeedbackTone.warning => Icons.warning_amber_outlined,
      MxFeedbackTone.info => Icons.info_outline,
      MxFeedbackTone.success => Icons.check_circle_outline,
      MxFeedbackTone.offline => Icons.cloud_off_outlined,
    };
    final MxCardFeedbackTone cardTone = switch (tone) {
      MxFeedbackTone.danger => MxCardFeedbackTone.danger,
      MxFeedbackTone.warning || MxFeedbackTone.offline => MxCardFeedbackTone.warning,
      MxFeedbackTone.info => MxCardFeedbackTone.info,
      MxFeedbackTone.success => MxCardFeedbackTone.success,
    };
```

- [ ] **Step 5: Widgetbook** — `feedbackBandComponent()` gains a `tone` list knob over `MxFeedbackTone.values` and an "Offline" use case.

- [ ] **Step 6: Run + commit**

```bash
flutter test test/shared --exclude-tags golden
git add -A lib test widgetbook/lib
git commit -m "feat(design-system): four callout tones and the offline banner (M100.xx)"
```

### Task 26: Empty and error states on a card with a tinted tile

**Files:**
- Modify: `lib/core/theme/foundations/app_sizing.dart` (`stateTile`, `stateTileCompact`)
- Create: `lib/shared/widgets/mx_state_tile.dart`
- Modify: `lib/shared/widgets/mx_empty_state.dart`, `lib/shared/widgets/mx_error_state.dart`
- Test: `test/shared/widgets/mx_components_test.dart` (or the existing empty/error state test file)
- Modify: `widgetbook/lib/components/feedback_components.dart`

**Interfaces:**
- Produces: `AppSizing.stateTile = 64`, `stateTileCompact = 52`; `enum MxStateTileTone { accent, danger }`; `enum MxStateSize { standard, compact }`; `MxStateTile({required IconData icon, required MxStateTileTone tone, MxStateSize size = MxStateSize.standard})`; `MxEmptyState` gains `String? footnote` and `MxStateSize size = MxStateSize.standard`. Decision D25 (glyph in tile): standard `MxIconSize.xl` (40, "illustrative"), compact `MxIconSize.lg` (32).

Handoff: EmptyState — card, 64 tile radius 20 (compact 52 / radius 16), headline 20 (compact 16), body, CTA, footnote. ErrorState — 52 danger tile (10%) radius 16, headline 16, copy, Retry primary.

- [ ] **Step 1: Write the failing tests**:

```dart
  testWidgets('empty state: a card, a 64 tinted tile, a 20 headline, a footnote', (tester) async {
    final theme = buildLightTheme();
    await tester.pumpWidget(MaterialApp(
      theme: theme,
      home: const Scaffold(
        body: MxEmptyState(title: 'No decks yet', message: 'Make one.', footnote: 'Nothing leaves this phone.'),
      ),
    ));

    expect(find.byType(MxCard), findsOneWidget);
    expect(tester.getSize(find.byType(MxStateTile)), const Size.square(AppSizing.stateTile));
    expect(tester.widget<Text>(find.text('No decks yet')).style!.fontSize, 20);
    expect(find.text('Nothing leaves this phone.'), findsOneWidget);
  });

  testWidgets('compact empty state: 52 tile, 16 headline', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: buildLightTheme(),
      home: const Scaffold(body: MxEmptyState(title: 'Empty', size: MxStateSize.compact)),
    ));
    expect(tester.getSize(find.byType(MxStateTile)), const Size.square(AppSizing.stateTileCompact));
    expect(tester.widget<Text>(find.text('Empty')).style!.fontSize, 16);
  });

  testWidgets('error state: 52 danger tile, 16 headline, primary retry', (tester) async {
    final theme = buildLightTheme();
    await tester.pumpWidget(MaterialApp(
      theme: theme,
      home: Scaffold(
        body: MxErrorState(title: 'Could not load', message: 'Nothing was lost.', retryLabel: 'Retry', onRetry: () {}),
      ),
    ));
    final tile = find.byType(MxStateTile);
    expect(tester.getSize(tile), const Size.square(AppSizing.stateTileCompact));
    expect(tester.widget<MxStateTile>(tile).tone, MxStateTileTone.danger);
    expect(tester.widget<Text>(find.text('Could not load')).style!.fontSize, 16);
    expect(find.widgetWithText(FilledButton, 'Retry'), findsOneWidget);
  });
```

- [ ] **Step 2: Run to fail** — compile FAIL.

- [ ] **Step 3: Tokens + tile** — `app_sizing.dart`:

```dart
  /// Handoff EmptyState tile (64) and its compact / ErrorState size (52).
  static const double stateTile = 64;
  static const double stateTileCompact = 52;
```

`lib/shared/widgets/mx_state_tile.dart`:

```dart
import 'package:flutter/material.dart';

import '../../core/theme/extensions/app_ink.dart';
import '../../core/theme/extensions/theme_context_extension.dart';
import '../../core/theme/foundations/app_radius.dart';
import '../../core/theme/foundations/app_sizing.dart';
import 'mx_icon.dart';

/// The handoff's tint for a state tile: 10% of the tone.
const double _tintAlpha = 0.10;

enum MxStateTileTone { accent, danger }

enum MxStateSize { standard, compact }

/// The tinted tile that leads an empty or error state (handoff G).
class MxStateTile extends StatelessWidget {
  const MxStateTile({
    required this.icon,
    required this.tone,
    this.size = MxStateSize.standard,
    super.key,
  });

  final IconData icon;
  final MxStateTileTone tone;
  final MxStateSize size;

  @override
  Widget build(BuildContext context) {
    final isCompact = size == MxStateSize.compact;
    final (Color base, AppInk ink) = switch (tone) {
      MxStateTileTone.accent => (context.colors.primary, AppInk.accent),
      MxStateTileTone.danger => (context.semanticColors.danger, AppInk.danger),
    };
    return SizedBox.square(
      dimension: isCompact ? AppSizing.stateTileCompact : AppSizing.stateTile,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: base.withValues(alpha: _tintAlpha),
          borderRadius: BorderRadius.circular(isCompact ? AppRadius.lg : AppRadius.card),
        ),
        child: Center(
          child: MxIcon(icon, ink: ink, size: isCompact ? MxIconSize.lg : MxIconSize.xl),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Empty state** — in `MxEmptyState` add `this.footnote,` and `this.size = MxStateSize.standard,` to the constructor, the two fields, and replace the body of `build`'s `SingleChildScrollView` child:

```dart
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: MxCard.raised(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              MxStateTile(icon: icon, tone: MxStateTileTone.accent, size: size),
              const SizedBox(height: AppSpacing.lg),
              Text(
                title,
                textAlign: TextAlign.center,
                style: size == MxStateSize.compact
                    ? context.texts.titleMedium
                    : context.texts.titleLarge,
              ),
              // … the existing message and action blocks, unchanged …
              if (footnote case final note?) ...<Widget>[
                const SizedBox(height: AppSpacing.md),
                Text(
                  note,
                  textAlign: TextAlign.center,
                  style: context.texts.bodySmall!.inked(context, AppInk.quiet),
                ),
              ],
            ],
          ),
        ),
      ),
```

Keep the message block and the `MxButtonPair` / `MxActionButton` block (with Task 6's tonal secondary) exactly as they are between the headline and the footnote.

- [ ] **Step 5: Error state** — in `MxErrorState` wrap the column the same way (`SingleChildScrollView(padding: AppSpacing.lg)` → `MxCard.raised` → `Column`), replace the `MxIcon(Icons.error_outline, …)` with `const MxStateTile(icon: Icons.error_outline, tone: MxStateTileTone.danger, size: MxStateSize.compact)`, and the title style with `context.texts.titleMedium` (16 after Task 2). Retry stays primary.

- [ ] **Step 6: Callers and tests** — 26 `MxEmptyState` and 24 `MxErrorState` call sites. Some already sit inside a card; find them:

```bash
grep -rn -B6 "MxEmptyState(\|MxErrorState(" lib/features --include=*.dart | grep -E "MxCard\.|MxEmptyState\(|MxErrorState\(" | cut -c1-150
```

Where a state is the direct child of an `MxCard.*`, remove that outer card (a card inside a card is wrong). Then `flutter test test/shared test/features --exclude-tags golden` and move pins on the old 40 glyph / `titleMedium` empty headline.

- [ ] **Step 7: Widgetbook + commit** — `emptyStateComponent()` gains `footnote` (`stringOrNull`) and `size` (list) knobs; add an error-state use case if absent.

```bash
git add -A lib test widgetbook/lib
git commit -m "feat(design-system): empty and error states on a card with a tinted tile (M100.xx)"
```

### Task 27: `MxSkeleton` and `MxAvatar` (owner decision 10)

**Files:**
- Modify: `lib/core/theme/foundations/app_sizing.dart`, `app_durations.dart`
- Create: `lib/shared/widgets/mx_skeleton.dart`, `lib/shared/widgets/mx_avatar.dart`
- Create: `test/shared/widgets/mx_skeleton_test.dart`, `test/shared/widgets/mx_avatar_test.dart`
- Modify: `widgetbook/lib/components/feedback_components.dart`, `structure_components.dart`, `widgetbook/lib/main.dart`

**Interfaces:**
- Produces: `AppSizing.skeletonLine = 12`, `avatarSm = 32`, `avatarMd = 40`, `avatarLg = 48`; `AppDurations.skeletonPulse = Duration(milliseconds: 1400)`; `MxSkeleton.block({double height = AppSizing.skeletonLine, double? width})`, `MxSkeleton.circle({required double diameter})`; `enum MxAvatarSize { sm, md, lg }`; `MxAvatar.initials({required String initials, required String semanticLabel, MxAvatarSize size})`, `MxAvatar.image({required ImageProvider image, required String semanticLabel, MxAvatarSize size})`, `MxAvatar.placeholder({required String semanticLabel, MxAvatarSize size})`.

- [ ] **Step 1: Write the failing tests** — `test/shared/widgets/mx_skeleton_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/shared/widgets/mx_skeleton.dart';

/// Handoff Skeleton (G): surfaceContainerHigh, a 1.4s opacity pulse between
/// 0.45 and 0.75 (not a shimmer), static 0.5 under reduced motion. h 12, r 6.
void main() {
  Future<void> pump(WidgetTester tester, {bool reduce = false}) => tester.pumpWidget(
    MaterialApp(
      theme: buildLightTheme(),
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: reduce),
        child: const Scaffold(body: Center(child: MxSkeleton.block(width: 120))),
      ),
    ),
  );

  double opacity(WidgetTester tester) => tester
      .widget<Opacity>(find.descendant(of: find.byType(MxSkeleton), matching: find.byType(Opacity)))
      .opacity;

  testWidgets('pulses between 0.45 and 0.75 over 1.4s', (tester) async {
    await pump(tester);
    expect(opacity(tester), closeTo(0.45, 0.01));
    await tester.pump(const Duration(milliseconds: 1400));
    expect(opacity(tester), closeTo(0.75, 0.01));
    await tester.pump(const Duration(milliseconds: 1400));
    expect(opacity(tester), closeTo(0.45, 0.01));
  });

  testWidgets('reduced motion holds at 0.5', (tester) async {
    await pump(tester, reduce: true);
    await tester.pump(const Duration(milliseconds: 700));
    expect(opacity(tester), 0.5);
  });

  testWidgets('a block is 12 tall with a 6 corner on surfaceContainerHigh', (tester) async {
    await pump(tester);
    expect(tester.getSize(find.byType(MxSkeleton)), const Size(120, 12));
    final box = tester.widget<DecoratedBox>(find.descendant(
      of: find.byType(MxSkeleton), matching: find.byType(DecoratedBox)));
    final decoration = box.decoration as BoxDecoration;
    expect(decoration.color, buildLightTheme().colorScheme.surfaceContainerHigh);
    expect(decoration.borderRadius, BorderRadius.circular(6));
  });
}
```

`test/shared/widgets/mx_avatar_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/foundations/app_sizing.dart';
import 'package:memox/shared/widgets/mx_avatar.dart';

void main() {
  Future<void> pump(WidgetTester tester, Widget avatar) => tester.pumpWidget(
    MaterialApp(theme: buildLightTheme(), home: Scaffold(body: Center(child: avatar))),
  );

  testWidgets('sizes 32 / 40 / 48', (tester) async {
    for (final (size, extent) in <(MxAvatarSize, double)>[
      (MxAvatarSize.sm, AppSizing.avatarSm),
      (MxAvatarSize.md, AppSizing.avatarMd),
      (MxAvatarSize.lg, AppSizing.avatarLg),
    ]) {
      await pump(tester, MxAvatar.initials(initials: 'GN', semanticLabel: 'Giap', size: size));
      expect(tester.getSize(find.byType(MxAvatar)), Size.square(extent));
    }
  });

  testWidgets('initials sit on a seeded container, the same seed every time', (tester) async {
    final scheme = buildLightTheme().colorScheme;
    Color fill() => ((tester.widget<DecoratedBox>(find.descendant(
          of: find.byType(MxAvatar), matching: find.byType(DecoratedBox))).decoration)
        as BoxDecoration).color!;

    await pump(tester, const MxAvatar.initials(initials: 'GN', semanticLabel: 'Giap'));
    final first = fill();
    expect(<Color>[scheme.primaryContainer, scheme.secondaryContainer, scheme.tertiaryContainer], contains(first));
    await pump(tester, const MxAvatar.initials(initials: 'GN', semanticLabel: 'Giap'));
    expect(fill(), first);
    expect(find.text('GN'), findsOneWidget);
  });

  testWidgets('placeholder shows a person glyph and announces its label', (tester) async {
    final handle = tester.ensureSemantics();
    await pump(tester, const MxAvatar.placeholder(semanticLabel: 'No photo'));
    expect(find.byIcon(Icons.person_outline), findsOneWidget);
    expect(tester.getSemantics(find.byType(MxAvatar)).label, 'No photo');
    handle.dispose();
  });
}
```

- [ ] **Step 2: Run to fail** — compile FAIL.

- [ ] **Step 3: Tokens** — `app_sizing.dart`:

```dart
  /// Handoff Skeleton default line height.
  static const double skeletonLine = 12;

  /// Handoff Avatar sizes. Painted identity, not controls.
  static const double avatarSm = 32;
  static const double avatarMd = 40;
  static const double avatarLg = 48;
```

`app_durations.dart`: `/// Handoff Skeleton: one opacity pulse (0.45 ↔ 0.75). static const Duration skeletonPulse = Duration(milliseconds: 1400);` — and amend `slow`'s doc ("the longest anything in the app is allowed to take"): it is the longest *transition*; the handoff names longer motions explicitly (skeleton pulse here, card flip in Task 32, chart draw in Task 35).

- [ ] **Step 4: Skeleton** — `lib/shared/widgets/mx_skeleton.dart`:

```dart
import 'package:flutter/material.dart';

import '../../core/theme/extensions/theme_context_extension.dart';
import '../../core/theme/foundations/app_durations.dart';
import '../../core/theme/foundations/app_sizing.dart';

// Handoff Skeleton constants — none sits on a token ladder.
const double _pulseLow = 0.45;
const double _pulseHigh = 0.75;
const double _restingOpacity = 0.5;
const double _blockRadius = 6;

enum _MxSkeletonShape { block, circle }

/// Handoff Skeleton (G): one placeholder shape that pulses its opacity. It has
/// no semantics — the loading region around it announces itself.
class MxSkeleton extends StatefulWidget {
  const MxSkeleton.block({
    this.height = AppSizing.skeletonLine,
    this.width,
    super.key,
  }) : _shape = _MxSkeletonShape.block;

  const MxSkeleton.circle({required double diameter, super.key})
    : height = diameter,
      width = diameter,
      _shape = _MxSkeletonShape.circle;

  final double height;
  final double? width;
  final _MxSkeletonShape _shape;

  @override
  State<MxSkeleton> createState() => _MxSkeletonState();
}

class _MxSkeletonState extends State<MxSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: AppDurations.skeletonPulse,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _pulse.stop();
      return;
    }
    if (!_pulse.isAnimating) _pulse.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isReduced = MediaQuery.disableAnimationsOf(context);
    final box = SizedBox(
      width: widget.width,
      height: widget.height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: context.colors.surfaceContainerHigh,
          shape: widget._shape == _MxSkeletonShape.circle
              ? BoxShape.circle
              : BoxShape.rectangle,
          borderRadius: widget._shape == _MxSkeletonShape.block
              ? BorderRadius.circular(_blockRadius)
              : null,
        ),
      ),
    );
    return ExcludeSemantics(
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (context, child) => Opacity(
          opacity: isReduced
              ? _restingOpacity
              : _pulseLow + (_pulseHigh - _pulseLow) * _pulse.value,
          child: child,
        ),
        child: box,
      ),
    );
  }
}
```

(A skeleton that repeats forever keeps `pumpAndSettle` from settling — tests that render one use `pump(duration)`.)

- [ ] **Step 5: Avatar** — `lib/shared/widgets/mx_avatar.dart`:

```dart
import 'package:flutter/material.dart';

import '../../core/theme/extensions/app_ink.dart';
import '../../core/theme/extensions/theme_context_extension.dart';
import '../../core/theme/foundations/app_sizing.dart';
import 'mx_icon.dart';

enum MxAvatarSize {
  sm(AppSizing.avatarSm, MxIconSize.xs),
  md(AppSizing.avatarMd, MxIconSize.sm),
  lg(AppSizing.avatarLg, MxIconSize.md);

  const MxAvatarSize(this.extent, this.glyph);

  final double extent;
  final MxIconSize glyph;
}

/// Handoff Avatar (C): an identity — image, initials on a seeded container, or
/// a placeholder glyph. No caller until accounts exist (owner decision 10).
class MxAvatar extends StatelessWidget {
  const MxAvatar.initials({
    required String this.initials,
    required this.semanticLabel,
    this.size = MxAvatarSize.md,
    super.key,
  }) : image = null;

  const MxAvatar.image({
    required ImageProvider this.image,
    required this.semanticLabel,
    this.size = MxAvatarSize.md,
    super.key,
  }) : initials = null;

  const MxAvatar.placeholder({
    required this.semanticLabel,
    this.size = MxAvatarSize.md,
    super.key,
  }) : initials = null,
       image = null;

  final String? initials;
  final ImageProvider? image;
  final String semanticLabel;
  final MxAvatarSize size;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final Widget face;
    if (image case final photo?) {
      face = ClipOval(child: Image(image: photo, fit: BoxFit.cover));
    } else if (initials case final letters?) {
      final seeds = <(Color, AppInk)>[
        (scheme.primaryContainer, AppInk.onPrimaryContainer),
        (scheme.secondaryContainer, AppInk.onSecondaryContainer),
        (scheme.tertiaryContainer, AppInk.onTertiaryContainer),
      ];
      final (fill, ink) =
          seeds[letters.codeUnits.fold<int>(0, (a, b) => a + b) % seeds.length];
      face = DecoratedBox(
        decoration: BoxDecoration(color: fill, shape: BoxShape.circle),
        child: Center(
          child: Text(
            letters,
            maxLines: 1,
            style: context.texts.labelLarge!.inked(context, ink),
          ),
        ),
      );
    } else {
      face = DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHigh,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: MxIcon(Icons.person_outline, ink: AppInk.quiet, size: size.glyph),
        ),
      );
    }
    return Semantics(
      label: semanticLabel,
      image: true,
      excludeSemantics: true,
      child: SizedBox.square(dimension: size.extent, child: face),
    );
  }
}
```

The `if … else` chain here assigns one final value from three exclusive sources; if the guard's `avoid_else` rule flags it, extract `Widget _face(BuildContext context)` with three early returns.

- [ ] **Step 6: Widgetbook + run + commit** — a `MxSkeleton` use case (three lines + a circle) and a `MxAvatar` use case (three forms × three sizes).

```bash
flutter analyze --no-fatal-infos
flutter test test/shared/widgets/mx_skeleton_test.dart test/shared/widgets/mx_avatar_test.dart
python code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v7
git add -A lib test widgetbook/lib
git commit -m "feat(design-system): MxSkeleton and MxAvatar per the handoff (M100.xx)"
```

- [ ] **Step 7: Close Phase 5** — P3 (with integration suite — back gesture and dialogs are device scenarios), P4, P5, P6. WBS goal: "Chrome và overlay theo handoff: nav bar primary + shadow-chrome, breadcrumb chevron, scrim 45%, dialog 20/320/340 scale-in, sheet 20/85%, callout bốn tone + offline, empty/error trên card, MxSkeleton và MxAvatar dựng sẵn."

---

## Phase 6 — study widgets and data viz (sections F, E)

### Task 28: Rating buttons in semantic tonal pairs (owner decision 9)

**Files:**
- Modify: `lib/core/theme/components/actions/app_button_themes.dart` (`MxFilledPair`)
- Modify: `lib/shared/widgets/mx_action_button.dart` (`MxActionButtonVariant`, the variant switch, `_busyStyle`)
- Modify: `lib/features/study/presentation/widgets/support/study_labels_widget.dart` (variant per action)
- Modify: `lib/features/study/presentation/widgets/sections/study_card_face_section_widget.dart` (`_controls`), `recall_timer_pieces_widget.dart` (~lines 242–256)
- Test: `test/shared/widgets/mx_action_button_state_matrix_test.dart`, Create `test/features/study/presentation/study_grade_variant_test.dart`; `test/features/study/presentation/study_card_face_test.dart`, `study_mode_action_gap_test.dart`; `test/shared/widgets/mx_action_button_composite_state_test.dart:135,150` and `test/shared/widgets/mx_tonal_and_outlined_test.dart:42-45` (one-argument `fillOf` / `labelOf` / `stateLayerOf` calls — pass `theme.extension<AppSemanticColors>()!`)

**Interfaces:**
- Produces: `MxFilledPair.{brandTonal, dangerTonal, warningTonal, successTonal}`; `fillOf`, `labelOf`, `stateLayerOf` take `(ColorScheme scheme, AppSemanticColors semantic)`. `MxActionButtonVariant.{brandTonal, dangerTonal, warningTonal, successTonal}` rendered as `FilledButton` with the matching pair. `MxActionButtonVariant studyActionVariant(StudyAction action)` (top-level function in `study_labels_widget.dart`): `forgotten`, `again` → `dangerTonal`; `hard` → `warningTonal`; `good` → `brandTonal`; `easy`, `remembered` → `successTonal`.

- [ ] **Step 1: Write the failing tests** — `test/features/study/presentation/study_grade_variant_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/study/domain/models/study_action_model.dart';
import 'package:memox/features/study/presentation/widgets/support/study_labels_widget.dart';
import 'package:memox/shared/widgets/mx_action_button.dart';

/// Owner decision 9 (2026-09-13): each grade wears the semantic container of
/// what it means. Never two grades in one colour.
void main() {
  test('every action maps to its tonal pair', () {
    expect(studyActionVariant(StudyAction.again), MxActionButtonVariant.dangerTonal);
    expect(studyActionVariant(StudyAction.forgotten), MxActionButtonVariant.dangerTonal);
    expect(studyActionVariant(StudyAction.hard), MxActionButtonVariant.warningTonal);
    expect(studyActionVariant(StudyAction.good), MxActionButtonVariant.brandTonal);
    expect(studyActionVariant(StudyAction.easy), MxActionButtonVariant.successTonal);
    expect(studyActionVariant(StudyAction.remembered), MxActionButtonVariant.successTonal);
  });

  test('sm2\'s four grades are four different variants', () {
    final variants = <StudyAction>[
      StudyAction.again, StudyAction.hard, StudyAction.good, StudyAction.easy,
    ].map(studyActionVariant).toSet();
    expect(variants, hasLength(4));
  });
}
```

Append to `mx_action_button_state_matrix_test.dart`:

```dart
  for (final (variant, fill, label) in <(MxActionButtonVariant, Color Function(ThemeData), Color Function(ThemeData))>[
    (MxActionButtonVariant.brandTonal, (t) => t.colorScheme.primaryContainer, (t) => t.colorScheme.onPrimaryContainer),
    (MxActionButtonVariant.dangerTonal, (t) => t.extension<AppSemanticColors>()!.dangerContainer, (t) => t.extension<AppSemanticColors>()!.onDangerContainer),
    (MxActionButtonVariant.warningTonal, (t) => t.extension<AppSemanticColors>()!.warningContainer, (t) => t.extension<AppSemanticColors>()!.onWarningContainer),
    (MxActionButtonVariant.successTonal, (t) => t.extension<AppSemanticColors>()!.successContainer, (t) => t.extension<AppSemanticColors>()!.onSuccessContainer),
  ]) {
    testWidgets('$variant fills its container and labels with its on-container', (tester) async {
      final theme = buildLightTheme();
      await tester.pumpWidget(MaterialApp(
        theme: theme,
        home: Scaffold(body: Center(child: MxActionButton(label: 'Good', variant: variant, onPressed: () {}))),
      ));
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      final style = button.style!;
      expect(style.backgroundColor!.resolve(<WidgetState>{}), fill(theme));
      expect(style.foregroundColor!.resolve(<WidgetState>{}), label(theme));
    });
  }
```

(If the button's resolved style is only visible through `ButtonStyleButton`'s merged style, resolve through `FilledButton.defaultStyleOf`/the `Material` color instead; the expected colours stand.)

- [ ] **Step 2: Run to fail** — `flutter test test/features/study/presentation/study_grade_variant_test.dart test/shared/widgets/mx_action_button_state_matrix_test.dart` → compile FAIL.

- [ ] **Step 3: Pairs** — `app_button_themes.dart`:

```dart
enum MxFilledPair {
  brand,
  destructive,
  tonal,

  /// A grade or verdict meaning "right on track" — `primaryContainer`.
  brandTonal,

  /// A grade meaning "missed" — the danger container.
  dangerTonal,

  /// A grade meaning "hard" — the warning container.
  warningTonal,

  /// A grade meaning "easy" / "remembered" — the success container.
  successTonal;

  Color fillOf(ColorScheme scheme, AppSemanticColors semantic) => switch (this) {
    MxFilledPair.brand => scheme.primary,
    MxFilledPair.destructive => scheme.error,
    MxFilledPair.tonal => scheme.secondaryContainer,
    MxFilledPair.brandTonal => scheme.primaryContainer,
    MxFilledPair.dangerTonal => semantic.dangerContainer,
    MxFilledPair.warningTonal => semantic.warningContainer,
    MxFilledPair.successTonal => semantic.successContainer,
  };

  Color labelOf(ColorScheme scheme, AppSemanticColors semantic) => switch (this) {
    MxFilledPair.brand => scheme.onPrimary,
    MxFilledPair.destructive => scheme.onError,
    MxFilledPair.tonal => scheme.onSecondaryContainer,
    MxFilledPair.brandTonal => scheme.onPrimaryContainer,
    MxFilledPair.dangerTonal => semantic.onDangerContainer,
    MxFilledPair.warningTonal => semantic.onWarningContainer,
    MxFilledPair.successTonal => semantic.onSuccessContainer,
  };

  /// Same role as [labelOf] for every pair (the M3 filled/tonal rule).
  Color stateLayerOf(ColorScheme scheme, AppSemanticColors semantic) =>
      labelOf(scheme, semantic);
}
```

Keep the existing doc comments above `brand`, `destructive`, `tonal`. Run `flutter analyze`; pass `semantic` at every call it reports — three inside `buildFilledStyle` (which already receives `AppSemanticColors`) and the two test files named under Files.

- [ ] **Step 4: Variants** — `mx_action_button.dart`: add after `tonal` in `MxActionButtonVariant`:

```dart
  /// A choice that carries a verdict — a grade in a study session. Filled
  /// tonal, in the container of what it means (owner decision 9).
  brandTonal,
  dangerTonal,
  warningTonal,
  successTonal,
```

In the variant `switch` that builds the button, add one arm shared by the four, modelled on the `tonal` arm:

```dart
      MxActionButtonVariant.brandTonal ||
      MxActionButtonVariant.dangerTonal ||
      MxActionButtonVariant.warningTonal ||
      MxActionButtonVariant.successTonal => FilledButton(
        onPressed: effectiveOnPressed,
        autofocus: _takesFocus(),
        style: _sized(
          context,
          busyStyle ??
              buildFilledStyle(
                context.colors,
                context.semanticColors,
                context.texts,
                pair: _pairOf(variant),
              ),
        ),
        child: child,
      ),
```

with

```dart
  static MxFilledPair _pairOf(MxActionButtonVariant variant) => switch (variant) {
    MxActionButtonVariant.brandTonal => MxFilledPair.brandTonal,
    MxActionButtonVariant.dangerTonal => MxFilledPair.dangerTonal,
    MxActionButtonVariant.warningTonal => MxFilledPair.warningTonal,
    MxActionButtonVariant.successTonal => MxFilledPair.successTonal,
    MxActionButtonVariant.primary ||
    MxActionButtonVariant.secondary ||
    MxActionButtonVariant.tonal ||
    MxActionButtonVariant.destructive => MxFilledPair.brand,
  };
```

In `_busyStyle`'s `(fill, label)` switch add `MxActionButtonVariant.brandTonal || … || successTonal => (_pairOf(variant).fillOf(colors, context.semanticColors), _pairOf(variant).labelOf(colors, context.semanticColors)),`. Fix every other exhaustive switch over `MxActionButtonVariant` the analyzer reports (the variant-count guard in `mx_naming_test` or Widgetbook knobs included).

- [ ] **Step 5: Study** — `study_labels_widget.dart`, below the extension:

```dart
/// The button a grade is drawn as (owner decision 9). A top-level function,
/// not a `switch` over `StudyMode` — AD-18's single mode dispatch is untouched.
MxActionButtonVariant studyActionVariant(StudyAction action) => switch (action) {
  StudyAction.forgotten || StudyAction.again => MxActionButtonVariant.dangerTonal,
  StudyAction.hard => MxActionButtonVariant.warningTonal,
  StudyAction.good => MxActionButtonVariant.brandTonal,
  StudyAction.easy || StudyAction.remembered => MxActionButtonVariant.successTonal,
};
```

(import `mx_action_button.dart`). In `study_card_face_section_widget.dart` `_controls`: `variant: action.isNormalGrade ? MxActionButtonVariant.primary : MxActionButtonVariant.secondary,` → `variant: studyActionVariant(action),`. In `recall_timer_pieces_widget.dart`: the forgotten button `variant: MxActionButtonVariant.dangerTonal`, the remembered button `variant: MxActionButtonVariant.successTonal`.

- [ ] **Step 6: Run + move pins** — `flutter test test/shared test/features/study test/core/theme --exclude-tags golden`. Pins asserting a primary "Good"/"Remembered" and outlined lapses move to the tonal variants. `study_mode_action_gap_test` measures gaps only — it must stay green unchanged.

- [ ] **Step 7: Docs + commit** — `tokyo-component-mapping.md` §2 actions: add rows "FilledButton (grade) · background/foreground · `*Container` / `on*Container` per grade · owner decision 9".

```bash
git add -A lib test docs/design-system/tokyo-component-mapping.md
git commit -m "feat(study): grades in semantic tonal pairs (M100.xx)"
```

### Task 29: Study top bar accent by session kind (owner decision 8)

**Files:**
- Modify: `lib/shared/widgets/mx_session_top_bar.dart` (`MxSessionAccent`, `_Chip`, progress)
- Modify: `lib/shared/widgets/mx_progress_bar.dart` (`MxProgressTone`)
- Modify: `lib/features/study/presentation/widgets/sections/study_session_frame_section_widget.dart` (~line 112)
- Test: `test/shared/widgets/mx_progress_bar_test.dart`, `test/shared/widgets/mx_session_top_bar_test.dart` (create if absent), `test/features/study/presentation/study_session_frame_test.dart` (or the frame's existing test)
- Docs: `docs/design-system/study-top-bar-spec.md` §7

**Interfaces:**
- Produces: `enum MxSessionAccent { brand, signature }`; `MxSessionTopBar({…, MxSessionAccent accent = MxSessionAccent.brand})`; `enum MxProgressTone { brand, signature }`; `MxProgressBar({…, MxProgressTone tone = MxProgressTone.brand})` — `brand` fills `progressFill`, `signature` fills `scheme.tertiary`, complete fills `mastery` either way. Chip label ink: `brand` → `AppInk.accent`, `signature` → `AppInk.tertiary`.

- [ ] **Step 1: Write the failing tests**:

```dart
  // mx_progress_bar_test.dart
  testWidgets('the signature tone fills tertiary until complete', (tester) async {
    final theme = buildLightTheme();
    await tester.pumpWidget(MaterialApp(
      theme: theme,
      home: const Scaffold(body: MxProgressBar(value: 0.4, tone: MxProgressTone.signature)),
    ));
    final bar = tester.widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator));
    expect(bar.valueColor!.value, theme.colorScheme.tertiary);
  });
```

```dart
  // mx_session_top_bar_test.dart
  testWidgets('signature accent: tertiary track, tertiaryInk chip', (tester) async {
    final theme = buildLightTheme();
    await tester.pumpWidget(MaterialApp(
      theme: theme,
      home: Scaffold(
        body: MxSessionTopBar(
          label: 'Learn',
          progress: 0.5,
          trailing: const Text('5/10'),
          onClose: () {},
          closeLabel: 'Close',
          accent: MxSessionAccent.signature,
        ),
      ),
    ));
    expect(tester.widget<MxProgressBar>(find.byType(MxProgressBar)).tone, MxProgressTone.signature);
    expect(
      tester.widget<Text>(find.text('LEARN')).style!.color,
      theme.extension<AppSemanticColors>()!.tertiaryInk,
    );
  });
```

and in the frame test: a `StudySessionKind.learning` session renders `MxSessionTopBar` with `accent == MxSessionAccent.signature`, a `reviewing` one with `brand`.

- [ ] **Step 2: Run to fail** — compile FAIL.

- [ ] **Step 3: Progress tone** — `mx_progress_bar.dart`:

```dart
/// Which family the fill draws in. `signature` is the violet a learning
/// session wears (owner decision 8); both finish in `mastery`.
enum MxProgressTone { brand, signature }
```

add `this.tone = MxProgressTone.brand,` + `final MxProgressTone tone;`, and

```dart
    final fill = isComplete
        ? semantic.mastery
        : switch (tone) {
            MxProgressTone.brand => semantic.progressFill,
            MxProgressTone.signature => context.colors.tertiary,
          };
```

Rewrite the class doc's "never the accent" paragraph to: "The fill is `progressFill`, or `tertiary` in a learning session (owner decision 8), and `mastery` when complete."

- [ ] **Step 4: Top bar** — `mx_session_top_bar.dart`:

```dart
/// The accent a session wears (owner decision 8): `brand` for review,
/// `signature` (the handoff's violet) for learning. Never green — green is
/// a verdict.
enum MxSessionAccent { brand, signature }
```

add `this.accent = MxSessionAccent.brand,` / `final MxSessionAccent accent;`; line ~199 `_Chip(label: label)` → `_Chip(label: label, accent: accent)`; line ~209 `MxProgressBar(value: progress, size: MxProgressBarSize.sm)` → add `tone: switch (accent) { MxSessionAccent.brand => MxProgressTone.brand, MxSessionAccent.signature => MxProgressTone.signature },`. In `_Chip` add `required this.accent` / `final MxSessionAccent accent;` and change `.inked(context, AppInk.accent)` → `.inked(context, switch (accent) { MxSessionAccent.brand => AppInk.accent, MxSessionAccent.signature => AppInk.tertiary })`.

- [ ] **Step 5: Frame** — `study_session_frame_section_widget.dart` at the `MxSessionTopBar(` call add:

```dart
            accent: kind == StudySessionKind.learning
                ? MxSessionAccent.signature
                : MxSessionAccent.brand,
```

(the widget already holds `kind`, line 59).

- [ ] **Step 6: Docs + run + commit** — `study-top-bar-spec.md` §7: "**Đã quyết (M100.xx, 2026-09-13):** accent theo loại phiên — learning = `tertiary` (chữ `tertiaryInk`), reviewing = `primary`; không dùng xanh lá."

```bash
flutter test test/shared test/features/study --exclude-tags golden
git add -A lib test docs/design-system/study-top-bar-spec.md
git commit -m "feat(study): session accent by kind — violet learning, indigo review (M100.xx)"
```

### Task 30: Guess option — ghost edge at rest, tinted verdicts

**Files:**
- Modify: `lib/features/study/presentation/widgets/items/guess_option_item_widget.dart` (build, ~lines 66–150)
- Test: `test/features/study/presentation/guess_option_item_test.dart` (or the file `grep -rl GuessOptionItem test` lists)

**Interfaces:**
- Produces: `open` / `dimmed` — `surfaceContainerLow` fill, `outlineVariant` hairline, no shadow; `correct` — `successContainer` fill, `success` edge at `AppStroke.control`; `chosenWrong` — `dangerContainer` fill, `error` edge at `AppStroke.control`. The handoff's "selected" state does not apply: a guess commits on tap (there is no pre-commit selection). Verdict glyphs and announcements unchanged. **This reverses M100.69** ("a resting row draws no edge", `guess_option_item_widget.dart:78-98`): the handoff ChoiceOption gives the resting row an `outlineVariant` border, and the redesign rule is kit over shipped code. Rewrite that doc comment, and move the test that pins the old resting state — `guess_answered_widget_test.dart:216-229` asserts the resting border `isNull`. Re-read `guess_option_height_test.dart:93`: an outside stroke does not change layout, so it should pass; its comment cites M100.69 and needs the same rewrite. Keep the verdict slot the row holds in every state and `AppGuessOption.verdictGlyphSize` (PLAN-DEV-2.7): `naturalHeightOf` measures the text beside that slot, which is what keeps it exact for all four states.

- [ ] **Step 1: Write the failing test**:

```dart
  for (final (state, fill, edge, width) in <(GuessOptionState, Color Function(ThemeData), Color Function(ThemeData), double)>[
    (GuessOptionState.open, (t) => t.colorScheme.surfaceContainerLow, (t) => t.colorScheme.outlineVariant, AppStroke.hairline),
    (GuessOptionState.correct, (t) => t.extension<AppSemanticColors>()!.successContainer, (t) => t.extension<AppSemanticColors>()!.success, AppStroke.control),
    (GuessOptionState.chosenWrong, (t) => t.extension<AppSemanticColors>()!.dangerContainer, (t) => t.colorScheme.error, AppStroke.control),
  ]) {
    testWidgets('$state paints the handoff ChoiceOption', (tester) async {
      final theme = buildLightTheme();
      await tester.pumpWidget(MaterialApp(
        theme: theme,
        home: Scaffold(body: GuessOptionItemWidget(text: '먹다', state: state, onTap: () {})),
      ));
      await tester.pumpAndSettle();
      final box = tester.widget<AnimatedContainer>(find.byType(AnimatedContainer)).decoration! as BoxDecoration;
      expect(box.color, fill(theme));
      expect((box.border! as Border).top.color, edge(theme));
      expect((box.border! as Border).top.width, width);
      expect(box.boxShadow, anyOf(isNull, isEmpty));
    });
  }
```

(Use the widget's real class name from line ~40 of the file.)

- [ ] **Step 2: Run to fail** — FAIL (open has no border, correct has no tint).

- [ ] **Step 3: Implement** — replace the `ground` / `accent` / `outline` / `outlineWidth` / `elevation` locals with:

```dart
    final scheme = context.colors;
    final semantic = context.semanticColors;
    final Color fill = switch (state) {
      GuessOptionState.correct => semantic.successContainer,
      GuessOptionState.chosenWrong => semantic.dangerContainer,
      GuessOptionState.open || GuessOptionState.dimmed => scheme.surfaceContainerLow,
    };
    final Color outline = switch (state) {
      GuessOptionState.correct => semantic.success,
      GuessOptionState.chosenWrong => scheme.error,
      GuessOptionState.open || GuessOptionState.dimmed => scheme.outlineVariant,
    };
    final double outlineWidth = switch (state) {
      GuessOptionState.correct || GuessOptionState.chosenWrong => AppStroke.control,
      GuessOptionState.open || GuessOptionState.dimmed => AppStroke.hairline,
    };
```

and the `BoxDecoration` to `color: fill`, `border: Border.all(color: outline, width: outlineWidth, strokeAlign: BorderSide.strokeAlignOutside)`, no `boxShadow`. If the option's text/glyph ink reads through `AppInk.success` / `AppInk.danger` on the new tint, switch it to `AppInk.onSuccessContainer` / `AppInk.onDangerContainer` (text on a container uses the on-container ink). Remove imports analyze reports unused.

- [ ] **Step 4: Run + commit** — `flutter test test/features/study --exclude-tags golden`; the visual-audit tests may count a new edge on the open state — read that delta as the design change, move the count.

```bash
git add -A lib test
git commit -m "feat(study): guess options per the handoff ChoiceOption (M100.xx)"
```

### Task 31: Match tile — surfaceContainer at rest, tinted pair and miss

**Files:**
- Modify: `lib/features/study/presentation/widgets/items/match_tile_widget.dart` (`_TileSkin.of`, the class doc paragraph "A state changes the edge and the ink. It never changes the surface.")
- Test: `test/features/study/presentation/match_tile_test.dart` (or the file `grep -rl MatchTileWidget test` lists)

**Interfaces:**
- Produces: `idle` — `surfaceContainer`; `selected` — `surfaceContainer` + `primary` edge (accent, unchanged); `paired` — `successContainer` fill + success edge + check; `wrong` — `dangerContainer` fill + error edge + cross (shake stays out, D3); `cleared` unchanged.

- [ ] **Step 1: Write the failing test**:

```dart
  for (final (state, fill) in <(MatchTileState, Color Function(ThemeData))>[
    (MatchTileState.idle, (t) => t.colorScheme.surfaceContainer),
    (MatchTileState.selected, (t) => t.colorScheme.surfaceContainer),
    (MatchTileState.paired, (t) => t.extension<AppSemanticColors>()!.successContainer),
    (MatchTileState.wrong, (t) => t.extension<AppSemanticColors>()!.dangerContainer),
  ]) {
    testWidgets('$state fills per the handoff MatchTile', (tester) async {
      final theme = buildLightTheme();
      await pumpTile(tester, text: 'kim', isTerm: true, state: state);
      final box = tester.widget<AnimatedContainer>(find.byType(AnimatedContainer).first).decoration! as BoxDecoration;
      expect(box.color, fill(theme));
    });
  }
```

- [ ] **Step 2: Run to fail** — FAIL.

- [ ] **Step 3: Implement** — in `_TileSkin.of`: `final ground = scheme.surfaceContainerLow;` → `scheme.surfaceContainer`; give `marked` a fill parameter:

```dart
    _TileSkin marked(AppInk ink, IconData? mark, {Color? fill}) => _TileSkin(
      background: fill ?? ground,
      outline: ink.resolve(context),
      outlineWidth: AppStroke.control,
      elevation: AppElevation.none,
      foreground: ink,
      mark: mark,
    );
```

and the arms `MatchTileState.wrong => marked(AppInk.danger, Icons.close, fill: semantic.dangerContainer)`, `MatchTileState.paired => marked(AppInk.success, Icons.check, fill: semantic.successContainer)`. Make the `idle` arm use `ground` (read it; if it paints a shadow, keep it — the handoff states only the fill). Rewrite the class doc paragraph to: "A state changes the edge and the ink, and the verdict states tint the surface (handoff MatchTile)."

- [ ] **Step 4: Run + commit**

```bash
flutter test test/features/study --exclude-tags golden
git add -A lib test
git commit -m "feat(study): match tiles per the handoff (M100.xx)"
```

### Task 32: The card flips on reveal (350ms, D17)

**Files:**
- Modify: `lib/core/theme/foundations/app_durations.dart` (`cardFlip`)
- Modify: `lib/features/study/presentation/widgets/sections/study_card_face_section_widget.dart` (`_StudyCardFaceViewState.build`)
- Test: `test/features/study/presentation/study_card_face_test.dart`; any study test that taps Reveal and expects the back on the next frame (`haptic_moments_test`, `study_accessibility_test`, `study_direction_card_test`, `study_self_assess_lifecycle_test`)

**Interfaces:**
- Produces: `AppDurations.cardFlip = Duration(milliseconds: 350)`. Revealing swaps the prompt layout for the revealed layout through a Y-axis flip; reduced motion swaps instantly.

- [ ] **Step 1: Write the failing test** — append inside `main()` of `study_card_face_test.dart` (helper `pump(tester, {required List<StudyAction> actions, …})`, fixtures `eightBox` / `sm2`, reveal label `'Show answer'`):

```dart
  testWidgets('reveal flips the card over 350ms', (tester) async {
    await pump(tester, actions: eightBox);
    await tester.tap(find.text('Show answer'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 175));

    expect(find.byType(Transform), findsWidgets);
    expect(find.byKey(const ValueKey<bool>(false)), findsOneWidget);
    expect(find.byKey(const ValueKey<bool>(true)), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byKey(const ValueKey<bool>(false)), findsNothing);
    expect(find.byKey(const ValueKey<bool>(true)), findsOneWidget);
  });

  testWidgets('reduced motion reveals without a flip', (tester) async {
    await pump(tester, actions: eightBox, disableAnimations: true);
    await tester.tap(find.text('Show answer'));
    await tester.pump();
    expect(find.byKey(const ValueKey<bool>(false)), findsNothing);
  });
```

`pump` has no `disableAnimations` switch: add `bool disableAnimations = false` and wrap the `StudyCardFaceSectionWidget` it builds in `Builder(builder: (context) => MediaQuery(data: MediaQuery.of(context).copyWith(disableAnimations: disableAnimations), child: …))` — the shape `mx_search_field_test.dart` uses, because a fresh `MediaQueryData` zeroes the size.

- [ ] **Step 2: Run to fail** — FAIL (no `ValueKey<bool>`).

- [ ] **Step 3: Token** — `app_durations.dart`: `/// Handoff Flashcard: the reveal flip. Never a bounce curve. static const Duration cardFlip = Duration(milliseconds: 350);`

- [ ] **Step 4: Implement** — in `study_card_face_section_widget.dart`, add at file level:

```dart
/// Depth for the reveal flip's perspective.
const double _flipPerspective = 0.001;

/// Handoff Flashcard flip (D17): the outgoing face turns 0 → 90°, the incoming
/// one 90 → 0°. Each is hidden past 90°, so the two never show at once.
Widget _flipTransition(Widget child, Animation<double> animation) {
  return AnimatedBuilder(
    animation: animation,
    child: child,
    builder: (context, child) {
      final angle = (1 - animation.value) * math.pi;
      return Visibility(
        visible: angle <= math.pi / 2,
        maintainSize: true,
        maintainAnimation: true,
        maintainState: true,
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, _flipPerspective)
            ..rotateY(angle),
          child: child,
        ),
      );
    },
  );
}
```

(import `dart:math' as math`), and in `build` wrap the `MxCard.focal(...)` that is the child of `Expanded`:

```dart
        Expanded(
          child: AnimatedSwitcher(
            duration: AppMotionPolicy.durationOf(context, AppDurations.cardFlip),
            switchInCurve: AppDurations.standard,
            switchOutCurve: AppDurations.standard,
            transitionBuilder: _flipTransition,
            layoutBuilder: (current, previous) => Stack(
              fit: StackFit.expand,
              children: <Widget>[...previous, ?current],
            ),
            child: KeyedSubtree(
              key: ValueKey<bool>(_showsBack),
              child: MxCard.focal(
                // … unchanged …
              ),
            ),
          ),
        ),
```

- [ ] **Step 5: Run + move pins** — `flutter test test/features/study --exclude-tags golden`. A test that taps Reveal then asserts the back after a bare `pump()` now needs `pumpAndSettle()` (or `pump(AppDurations.cardFlip)`); change only those waits, never the assertions.

- [ ] **Step 6: Commit**

```bash
git add -A lib test
git commit -m "feat(study): the card flips on reveal, 350ms (M100.xx)"
```

### Task 33: `MxSelfAssessment` (owner decision 10)

**Files:**
- Create: `lib/shared/widgets/mx_self_assessment.dart`, `test/shared/widgets/mx_self_assessment_test.dart`
- Modify: `widgetbook/lib/components/control_components.dart`, `widgetbook/lib/main.dart`

**Interfaces:**
- Produces: `enum MxSelfScore { missed, partial, gotIt }`; `MxSelfAssessment({required MxSelfScore? selected, required ValueChanged<MxSelfScore> onChanged, required String missedLabel, required String partialLabel, required String gotItLabel})`. Unselected: transparent, `outlineVariant` hairline, `onSurfaceVariant` label. Selected: its container (danger / warning / success) and on-container label, no edge. Chip paints `AppSizing.controlDense` (32) and keeps a 48 target. No production caller.

- [ ] **Step 1: Write the failing test**:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/foundations/app_semantic_colors.dart';
import 'package:memox/core/theme/foundations/app_sizing.dart';
import 'package:memox/shared/widgets/mx_self_assessment.dart';

void main() {
  Future<void> pump(WidgetTester tester, {MxSelfScore? selected, ValueChanged<MxSelfScore>? onChanged}) =>
      tester.pumpWidget(MaterialApp(
        theme: buildLightTheme(),
        home: Scaffold(
          body: Center(
            child: MxSelfAssessment(
              selected: selected,
              onChanged: onChanged ?? (_) {},
              missedLabel: 'Missed',
              partialLabel: 'Partial',
              gotItLabel: 'Got it',
            ),
          ),
        ),
      ));

  Color fillOf(WidgetTester tester, String label) => ((tester.widget<AnimatedContainer>(find.ancestor(
        of: find.text(label), matching: find.byType(AnimatedContainer)).first)).decoration! as BoxDecoration)
      .color ?? Colors.transparent;

  testWidgets('the selected score fills with its own container', (tester) async {
    const semantic = AppSemanticColors.light();
    await pump(tester, selected: MxSelfScore.partial);
    expect(fillOf(tester, 'Partial'), semantic.warningContainer);
    expect(fillOf(tester, 'Missed'), Colors.transparent);

    await pump(tester, selected: MxSelfScore.gotIt);
    expect(fillOf(tester, 'Got it'), semantic.successContainer);
  });

  testWidgets('tapping reports the score; each chip is a 48 target', (tester) async {
    MxSelfScore? picked;
    await pump(tester, onChanged: (s) => picked = s);
    await tester.tap(find.text('Missed'));
    expect(picked, MxSelfScore.missed);
    final target = find.ancestor(of: find.text('Missed'), matching: find.byType(InkWell)).first;
    expect(tester.getSize(target).height, greaterThanOrEqualTo(AppSizing.touchTarget));
  });
}
```

- [ ] **Step 2: Run to fail** — compile FAIL.

- [ ] **Step 3: Implement** — `lib/shared/widgets/mx_self_assessment.dart`:

```dart
import 'package:flutter/material.dart';

import '../../core/theme/extensions/app_ink.dart';
import '../../core/theme/extensions/theme_context_extension.dart';
import '../../core/theme/foundations/app_durations.dart';
import '../../core/theme/foundations/app_motion_policy.dart';
import '../../core/theme/foundations/app_radius.dart';
import '../../core/theme/foundations/app_sizing.dart';
import '../../core/theme/foundations/app_spacing.dart';
import '../../core/theme/foundations/app_stroke.dart';

/// A learner's own verdict after writing from memory.
enum MxSelfScore { missed, partial, gotIt }

/// Handoff SelfAssessment (F): three exclusive chips; the chosen one fills with
/// the container of what it means (same mapping as the grades, decision 9).
class MxSelfAssessment extends StatelessWidget {
  const MxSelfAssessment({
    required this.selected,
    required this.onChanged,
    required this.missedLabel,
    required this.partialLabel,
    required this.gotItLabel,
    super.key,
  });

  final MxSelfScore? selected;
  final ValueChanged<MxSelfScore> onChanged;
  final String missedLabel;
  final String partialLabel;
  final String gotItLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: AppSpacing.sm,
      children: <Widget>[
        for (final (score, label) in <(MxSelfScore, String)>[
          (MxSelfScore.missed, missedLabel),
          (MxSelfScore.partial, partialLabel),
          (MxSelfScore.gotIt, gotItLabel),
        ])
          _ScoreChip(
            score: score,
            label: label,
            isSelected: score == selected,
            onTap: () => onChanged(score),
          ),
      ],
    );
  }
}

class _ScoreChip extends StatelessWidget {
  const _ScoreChip({
    required this.score,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final MxSelfScore score;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final (Color fill, AppInk ink) = switch (score) {
      MxSelfScore.missed => (semantic.dangerContainer, AppInk.onDangerContainer),
      MxSelfScore.partial => (semantic.warningContainer, AppInk.onWarningContainer),
      MxSelfScore.gotIt => (semantic.successContainer, AppInk.onSuccessContainer),
    };
    return Semantics(
      button: true,
      selected: isSelected,
      inMutuallyExclusiveGroup: true,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          customBorder: const StadiumBorder(),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppSizing.touchTarget),
            child: Center(
              widthFactor: 1,
              child: AnimatedContainer(
                duration: AppMotionPolicy.durationOf(context, AppDurations.fast),
                curve: AppDurations.standard,
                height: AppSizing.controlDense,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? fill : null,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  border: isSelected
                      ? null
                      : Border.all(
                          color: context.colors.outlineVariant,
                          width: AppStroke.hairline,
                        ),
                ),
                child: Text(
                  label,
                  maxLines: 1,
                  style: context.texts.labelLarge!.inked(
                    context,
                    isSelected ? ink : AppInk.quiet,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

A fixed `height` around text is what the handoff forbids for text containers that must grow; if the large-text sweep (`mx_accessibility_test`) flags it, replace `height:` with `constraints: const BoxConstraints(minHeight: AppSizing.controlDense)`.

- [ ] **Step 4: Widgetbook + run + commit** — a stateful use case cycling the three scores.

```bash
flutter test test/shared/widgets/mx_self_assessment_test.dart
git add -A lib test widgetbook/lib
git commit -m "feat(design-system): MxSelfAssessment per the handoff (M100.xx)"
```

### Task 34: `MxStatDisplay` and `MxStreakChip`

**Files:**
- Create: `lib/shared/widgets/mx_stat_display.dart`, `lib/shared/widgets/mx_streak_chip.dart`
- Create: `test/shared/widgets/mx_stat_display_test.dart`, `test/shared/widgets/mx_streak_chip_test.dart`
- Modify: `lib/features/deck/presentation/widgets/sections/deck_summary_metrics_widget.dart` (~line 120) — only if the numeral there sits over a caption
- Modify: `widgetbook/lib/components/feedback_components.dart`, `widgetbook/lib/main.dart`

**Interfaces:**
- Consumes: `AppTextStyles.heroNumeral` (= stat role after Task 2).
- Produces: `MxStatDisplay({required String value, required String caption})` — tabular stat figure over a `bodySmall` caption, announced as one node "value caption". `MxStreakChip({required String label})` — pill `AppSizing.controlDense` tall, `streakContainer` fill, flame glyph `MxIconSize.xs`, `AppInk.onDueContainer` ink; the caller passes the already-localized "7 days". No production caller for the chip (decision 10).

- [ ] **Step 1: Write the failing tests**:

```dart
// test/shared/widgets/mx_stat_display_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/shared/widgets/mx_stat_display.dart';

void main() {
  testWidgets('a 40 tabular figure over its caption, one semantics node', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(MaterialApp(
      theme: buildLightTheme(),
      home: const Scaffold(body: MxStatDisplay(value: '128', caption: 'cards learned')),
    ));

    final figure = tester.widget<Text>(find.text('128')).style!;
    expect(figure.fontSize, 40);
    expect(figure.fontFeatures, contains(const FontFeature.tabularFigures()));
    expect(tester.widget<Text>(find.text('cards learned')).style!.fontSize, 12);
    expect(tester.getSemantics(find.byType(MxStatDisplay)).label, '128 cards learned');
    handle.dispose();
  });
}
```

```dart
// test/shared/widgets/mx_streak_chip_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/foundations/app_semantic_colors.dart';
import 'package:memox/core/theme/foundations/app_sizing.dart';
import 'package:memox/shared/widgets/mx_streak_chip.dart';

void main() {
  testWidgets('flame, label, streak container, 32 tall', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: buildLightTheme(),
      home: const Scaffold(body: Center(child: MxStreakChip(label: '7 days'))),
    ));

    expect(find.byIcon(Icons.local_fire_department_outlined), findsOneWidget);
    expect(find.text('7 days'), findsOneWidget);
    expect(tester.getSize(find.byType(MxStreakChip)).height, greaterThanOrEqualTo(AppSizing.controlDense));
    final box = tester.widget<DecoratedBox>(find.descendant(
      of: find.byType(MxStreakChip), matching: find.byType(DecoratedBox)).first);
    expect((box.decoration as BoxDecoration).color, const AppSemanticColors.light().streakContainer);
  });
}
```

- [ ] **Step 2: Run to fail** — compile FAIL.

- [ ] **Step 3: Implement**

```dart
// lib/shared/widgets/mx_stat_display.dart
import 'package:flutter/material.dart';

import '../../core/theme/extensions/app_ink.dart';
import '../../core/theme/extensions/theme_context_extension.dart';
import '../../core/theme/foundations/app_spacing.dart';

/// Handoff StatDisplay (E): a large tabular metric over its caption — the stat
/// step (40), deliberately not snapped to a spacing value.
class MxStatDisplay extends StatelessWidget {
  const MxStatDisplay({required this.value, required this.caption, super.key});

  final String value;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$value $caption',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        spacing: AppSpacing.xs,
        children: <Widget>[
          Text(value, style: context.textStyles.heroNumeral.inked(context, AppInk.stated)),
          Text(caption, style: context.texts.bodySmall!.inked(context, AppInk.quiet)),
        ],
      ),
    );
  }
}
```

(If the i18n guard flags the interpolated `'$value $caption'`, build it as `<String>[value, caption].join(' ')` — the same pattern `mx_section_label.dart` uses to stay clear of the guard's regex.)

```dart
// lib/shared/widgets/mx_streak_chip.dart
import 'package:flutter/material.dart';

import '../../core/theme/extensions/app_ink.dart';
import '../../core/theme/extensions/theme_context_extension.dart';
import '../../core/theme/foundations/app_radius.dart';
import '../../core/theme/foundations/app_sizing.dart';
import '../../core/theme/foundations/app_spacing.dart';
import 'mx_icon.dart';

/// Handoff StreakChip (E): the streak count on the streak (warm) container.
/// Non-interactive; the caller passes the localized count.
class MxStreakChip extends StatelessWidget {
  const MxStreakChip({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.semanticColors.streakContainer,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppSizing.controlDense),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: AppSpacing.xs,
            children: <Widget>[
              const MxIcon(
                Icons.local_fire_department_outlined,
                ink: AppInk.onDueContainer,
                size: MxIconSize.xs,
              ),
              Text(label, style: context.texts.labelLarge!.inked(context, AppInk.onDueContainer)),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: One real caller for the stat** — open `deck_summary_metrics_widget.dart` around line 120. If the `heroNumeral` figure is followed by a caption `Text` in the same `Column`, replace that pair with `MxStatDisplay(value: …, caption: …)` and move its test; otherwise leave the file (its style is already the stat role).

- [ ] **Step 5: Widgetbook + run + commit**

```bash
flutter test test/shared/widgets/mx_stat_display_test.dart test/shared/widgets/mx_streak_chip_test.dart test/features/deck --exclude-tags golden
git add -A lib test widgetbook/lib
git commit -m "feat(design-system): MxStatDisplay and MxStreakChip (M100.xx)"
```

### Task 35: `MxBarChart` (owner decision 10)

**Files:**
- Modify: `lib/core/theme/foundations/app_durations.dart` (`chartDraw`)
- Create: `lib/shared/widgets/mx_bar_chart.dart`, `test/shared/widgets/mx_bar_chart_test.dart`
- Modify: `widgetbook/lib/components/feedback_components.dart`, `widgetbook/lib/main.dart`

**Interfaces:**
- Produces: `AppDurations.chartDraw = Duration(milliseconds: 600)`; `MxBarChart({required List<int> values, required int todayIndex, required String semanticLabel})` — seven bars, today `primary`, others `primaryContainer` (D18), rounded `AppRadius.xs` tops, grows in over 600ms (instant under reduced motion). It fills the height its parent bounds — the caller decides the height (external layout, AD-23).

- [ ] **Step 1: Write the failing test**:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/shared/widgets/mx_bar_chart.dart';

void main() {
  Future<MxBarChartPainter> pump(WidgetTester tester, {bool reduce = false}) async {
    await tester.pumpWidget(MaterialApp(
      theme: buildLightTheme(),
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: reduce),
        child: const Scaffold(
          body: SizedBox(
            height: 120,
            child: MxBarChart(values: <int>[3, 0, 8, 5, 12, 1, 7], todayIndex: 6, semanticLabel: 'Last 7 days'),
          ),
        ),
      ),
    ));
    await tester.pump();
    return tester.widget<CustomPaint>(find.descendant(
      of: find.byType(MxBarChart), matching: find.byType(CustomPaint))).painter! as MxBarChartPainter;
  }

  testWidgets('today is primary, the rest primaryContainer', (tester) async {
    final scheme = buildLightTheme().colorScheme;
    final painter = await pump(tester);
    expect(painter.today, scheme.primary);
    expect(painter.rest, scheme.primaryContainer);
    expect(painter.todayIndex, 6);
  });

  testWidgets('draws in over 600ms; reduced motion is fully drawn at once', (tester) async {
    final early = await pump(tester);
    expect(early.progress, lessThan(1));
    await tester.pump(const Duration(milliseconds: 600));
    final done = tester.widget<CustomPaint>(find.descendant(
      of: find.byType(MxBarChart), matching: find.byType(CustomPaint))).painter! as MxBarChartPainter;
    expect(done.progress, 1);

    final reduced = await pump(tester, reduce: true);
    expect(reduced.progress, 1);
  });

  test('exactly seven values', () {
    expect(() => MxBarChart(values: const <int>[1, 2], todayIndex: 1, semanticLabel: 'x'), throwsAssertionError);
  });
}
```

- [ ] **Step 2: Run to fail** — compile FAIL.

- [ ] **Step 3: Implement** — `app_durations.dart`: `/// Handoff BarChart entrance (\`chartDraw\`). static const Duration chartDraw = Duration(milliseconds: 600);`

```dart
// lib/shared/widgets/mx_bar_chart.dart
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/extensions/theme_context_extension.dart';
import '../../core/theme/foundations/app_durations.dart';
import '../../core/theme/foundations/app_motion_policy.dart';
import '../../core/theme/foundations/app_radius.dart';
import '../../core/theme/foundations/app_spacing.dart';

const int _days = 7;

/// Handoff BarChart (E): seven days of activity, today highlighted, drawn in
/// over 600ms. It takes the height its parent gives it.
class MxBarChart extends StatelessWidget {
  const MxBarChart({
    required this.values,
    required this.todayIndex,
    required this.semanticLabel,
    super.key,
  }) : assert(values.length == _days, 'A week is seven values.'),
       assert(todayIndex >= 0 && todayIndex < _days, 'today is one of them');

  final List<int> values;
  final int todayIndex;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    return Semantics(
      label: semanticLabel,
      excludeSemantics: true,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: 1),
        duration: AppMotionPolicy.durationOf(context, AppDurations.chartDraw),
        curve: AppDurations.decelerate,
        builder: (context, progress, _) => CustomPaint(
          size: Size.infinite,
          painter: MxBarChartPainter(
            values: values,
            todayIndex: todayIndex,
            progress: progress,
            today: scheme.primary,
            rest: scheme.primaryContainer,
          ),
        ),
      ),
    );
  }
}

/// Public for the test that reads what it was given; not for callers.
class MxBarChartPainter extends CustomPainter {
  const MxBarChartPainter({
    required this.values,
    required this.todayIndex,
    required this.progress,
    required this.today,
    required this.rest,
  });

  final List<int> values;
  final int todayIndex;
  final double progress;
  final Color today;
  final Color rest;

  @override
  void paint(Canvas canvas, Size size) {
    final peak = values.fold<int>(1, math.max);
    final gap = AppSpacing.sm;
    final barWidth = (size.width - gap * (_days - 1)) / _days;
    for (var i = 0; i < _days; i++) {
      final height = size.height * (values[i] / peak) * progress;
      if (height <= 0) continue;
      final left = i * (barWidth + gap);
      final rect = RRect.fromRectAndCorners(
        Rect.fromLTWH(left, size.height - height, barWidth, height),
        topLeft: const Radius.circular(AppRadius.xs),
        topRight: const Radius.circular(AppRadius.xs),
      );
      canvas.drawRRect(rect, Paint()..color = i == todayIndex ? today : rest);
    }
  }

  @override
  bool shouldRepaint(MxBarChartPainter old) =>
      old.progress != progress ||
      old.todayIndex != todayIndex ||
      old.today != today ||
      old.rest != rest ||
      !identical(old.values, values);
}
```

With a zero-duration tween under reduced motion, `TweenAnimationBuilder` builds at `end` on the first frame. If `progress` is `< 1` there, pass `begin: MediaQuery.disableAnimationsOf(context) ? 1 : 0`.

- [ ] **Step 4: Widgetbook + run + commit** — a use case inside `SizedBox(height: 120)` with a `todayIndex` knob.

```bash
flutter test test/shared/widgets/mx_bar_chart_test.dart
git add -A lib test widgetbook/lib
git commit -m "feat(design-system): MxBarChart per the handoff (M100.xx)"
```

- [ ] **Step 5: Close Phase 6** — P3 (with integration suite — a study session is a device scenario), P4, P5, P6. WBS goal: "Study và data viz theo handoff: nút chấm điểm theo semantic container, accent phiên theo loại, guess/match tô verdict, lật thẻ 350ms, MxSelfAssessment/MxStatDisplay/MxStreakChip/MxBarChart." Editable documents add `study-top-bar-spec.md`.

---

## Phase 7 — composition sweep and the V2 freeze

### Task 36: Screen rhythm per feature

**Files:** `lib/features/<feature>/presentation/**` for, in this order and **one commit each**: `deck`, `card`, `study`, `progress`, `settings` + `reminder`, `trash` + `search`. Tests: each feature's existing geometry/rhythm tests (`grep -rlE "geometry|rhythm|spacing" test/features/<feature>`).

**Interfaces:**
- Consumes: `AppSpacing` (Task 3), `mxScreenGutter`, `mxScrollEndInsetOf` (Task 4), `MxCardPadding.standard` (Task 9).
- Produces: no new API. Every vertical gap between blocks in `lib/features/*/presentation` follows the handoff's composition table:

| What the gap separates | Token |
|---|---|
| related rows inside one block | `AppSpacing.md` (12) |
| items of a list, cards in a stack | `AppSpacing.lg` (16) |
| sections of a screen | `AppSpacing.xl` (24) |
| major groups | `AppSpacing.xxl` (32) |
| card interior | `MxCardPadding.standard` (20) — never a hand-written `Padding` inside a card |
| screen edge | `mxScreenGutter(context)` / `MxContentShell.padding` |
| list tail | `mxScrollEndInsetOf(context)` |

Horizontal gaps inside a row (icon-to-label `xs`, label-to-control `sm`) are not part of this sweep.

For each feature:

- [ ] **Step 1: Inventory**

```bash
F=deck   # then card, study, progress, settings, reminder, trash, search
grep -rnE "SizedBox\(height: AppSpacing\.[a-z]+|separatorBuilder|EdgeInsets\.(only|fromLTRB|symmetric)\([^)]*(top|bottom|vertical)" lib/features/$F/presentation --include=*.dart | cut -c1-170
```

- [ ] **Step 2: Write the failing rhythm assertion** — in the feature's existing screen geometry test (or a new `test/features/<F>/presentation/<screen>_rhythm_test.dart`), measure the one gap the table decides that the inventory shows is wrong, using the finders that test already uses:

```dart
  testWidgets('<screen>: sections sit 24 apart (handoff composition)', (tester) async {
    await pumpScreen(tester);                    // the file's helper
    final upper = tester.getRect(firstSectionFinder);
    final lower = tester.getRect(secondSectionFinder);
    expect(lower.top - upper.bottom, AppSpacing.xl);
  });
```

- [ ] **Step 3: Run to fail**, then change each inventory hit whose token disagrees with the table. A card whose child starts with its own `Padding` moves that inset into `MxCardPadding.standard` (or `none` when the child is a full-bleed row group).

- [ ] **Step 4: Run** — `flutter test test/features/$F --exclude-tags golden`; move the pins that encoded the old rhythm, only after confirming the new value is the table's.

- [ ] **Step 5: Commit** — `git commit -am "feat($F): screen rhythm per the handoff composition (M100.xx)"`

- [ ] **Step 6 (after the last feature): WBS** — P1 entry for Phase 7 with goal "Nhịp bố cục theo handoff trên mọi màn và đóng băng lại design system thành V2."

### Task 37: Re-freeze as V2 and record what was deferred

**Files:**
- Modify: `docs/design-system/v1-freeze.md` (new freeze record in §1, §2 values)
- Modify: `CLAUDE.md` (the "Design System V1 was frozen, and is reopened for the Tokyo redesign" section)
- Modify: `docs/design-system/tokyo-component-mapping.md` (header, §2 final pass, §9 deferred list)
- Modify: `docs/wbs.md` (`## Deferred and descoped`)

**Interfaces:** documentation only; `check_docs.py` is the test.

- [ ] **Step 1: Ask the owner before freezing** — `AskUserQuestion`: "Redesign theo handoff đã xong tới Phase 7. Đóng băng lại design system thành V2 bây giờ?" options "Đóng băng V2 ngay (Recommended)" / "Để mở thêm một thời gian". If "để mở", do Steps 5–6 only and write the answer into the WBS entry.

- [ ] **Step 2: `v1-freeze.md`** — §3c says the redesign closes with a new freeze record **in §1**: rewrite §1's record as the V2 freeze (M100.xx, date, base SHA, what was redesigned, links to this plan and `tokyo-component-mapping.md` §9), and mark §3c closed by it. §2's table is `# · Hợp đồng · Enforcement` with no value column: for each of rows 1–13 whose contract or enforcement moved, rewrite the contract sentence and the enforcement cell (the test or guard that now watches it) — at least type (one family PJS, seven roles; `app_typography_test`), the spacing/radius/icon ladders on handoff names (`design_tokens_test`), sizing (`buttonCompact`, `iconButtonInk`, `input`, `fab`, `rowMinHeight`; `app_sizing_test`), depth (+ `chromeShadowsFor`; `app_elevation_test`), the moved role bindings (FAB, NavigationBar, Switch, ChoiceChip resting fill, TextField edges; `m3_role_binding_guard_test`, `m3_role_contract_test`), `MxContentShell`'s gutter 16 at every width, and the new raw-Material owners (`MxSwitch`, `MxDialogRoute`, `MxSegmentedControl`). Row 14 (Linux-only goldens) is unchanged.

- [ ] **Step 3: `CLAUDE.md`** — replace the reopened-for-redesign section's first paragraph and bullet list with a short "Design System V2 is frozen (M100.xx)" paragraph that points at `v1-freeze.md` §3d and keeps, verbatim, the rules that did not come from the reopening: a changed contract moves its test in the same PR; goldens are authored on Linux only; a bug fix does not thaw a contract on the side.

- [ ] **Step 4: `tokyo-component-mapping.md`** — set `Updated by task` / `Last updated`; walk §2 row by row against `test/core/theme/contracts/m3_role_bindings.dart` and fix any MemoX cell that no longer matches the binding.

- [ ] **Step 5: Deferred** — in `docs/wbs.md` `## Deferred and descoped` add one row each for **deferred** work, citing the decision: size variants with no caller (D9), spinner rotation (D22), the connectivity stream behind the offline banner, speech recognition behind the mic slot. D7 (solid navigation bar) and D21 (no sheet shadow) are settled defaults with no mechanism to revisit, not backlog: record them as `descoped`, with the decision log's reason.

- [ ] **Step 6: Verify + commit**

```bash
python .claude/skills/flutter-workflow/scripts/check_docs.py
git add CLAUDE.md docs
git commit -m "docs(design-system): freeze V2 after the Tokyo handoff redesign (M100.xx)"
```

### Task 38: Final gate

- [ ] **Step 1: Full local gate**

```bash
bash .claude/skills/flutter-workflow/scripts/dod_check.sh --force
```

Expected: exit 0 (format, analyze, generated code, architecture, docs, guard, full host suite).

- [ ] **Step 2: Device suite** — `flutter test integration_test/ -d emulator-5554 --flavor development` → `9 passing, 0 failing`.

- [ ] **Step 3: Handoff coverage check** — every row of the *Handoff → code map* is either shipped or listed as deferred:

```bash
python -X utf8 -c "import json;d=json.load(open('docs/design-system/handoff/memox-flutter-handoff.json',encoding='utf-8'));print('\n'.join(w['name'] for w in d['widgets']))"
```

For each name, point at the commit that shipped it or the D-id that deferred it; write that list into the Phase 7 PR description.

- [ ] **Step 4: Close Phase 7** — P4 (compare must be clean after the rhythm commits' re-authoring), P5 (quote the `ảnh <digest>`), P6. Move every phase's WBS entry to `docs/wbs-archive/m100.md` if any is still in the live ledger.

---

## Self-review record (plan author)

- **Spec coverage:** all 46 handoff widgets appear in the *Handoff → code map*; each production widget has a task or a D-id; StatusBar is "build nothing" by its own spec; Snackbar shipped at M100.87; TextButton already matches (accentInk, `accent:` tone).
- **Foundations coverage:** palette (M100.87), type (T2), spacing/radius/icons (T3), press opacity (T3), gutter/tail (T4), sizes (T5, T7, T8, T10, T12, T14, T17, T19, T23, T24, T26, T27), chrome shadow (T21), scrim (T23), motion (T19, T23, T24, T27, T32, T35).
- **Type consistency checked:** `AppIconSize`/`MxIconSize` names after T3 are `xs sm md lg xl` everywhere later; `AppRadius.full`/`card` after T3; `AppSizing.buttonCompact` (T5) is renamed-from `controlCompact` and read by T7; `AppSizing.fab` (T8) is read by `fabScrollClearance`; `MxRowGroup`/`MxRowDividerInset` (T12), `MxIconTile`/`MxIconTileSize` (T10) and `MxMasteryRing` (T14) are defined before T15/T16 consume them; `MxStateSize` (T26) is shared by `MxEmptyState` and `MxStateTile`; `MxFilledPair` method signatures change in T28 together with every caller.
- **Order dependencies:** Phase 3 needs Phase 2's `MxIconButton` placement; Phase 6's rating variants need nothing from Phases 4–5; Task 36 must run last because every earlier phase moves geometry.

