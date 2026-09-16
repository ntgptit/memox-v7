---
last_updated: 2026-06-06
status: contract
applies_to: UI mock-to-code implementation
ref: main @ 314d33290d5a
---

# Screen Index

Master scope table for every screen in the MemoX mobile mock
(`docs/system-design/MemoX Design System/ui_kits/mobile/index.html`). Read a
screen's **Scope status** before implementing, then open its **Visual contract**.

This table is the fuller, scope-oriented companion to `mock-design-index.md`.
Keep both in sync when scope changes.

## How scope status was determined

Status reflects the **current repository on `main` (sha `314d33290d5a`)**, not
prior chat history and not the wireframes' aspirational `V1 verification status`
blocks. The router is authoritative for what actually renders:

- `lib/app/router/app_router.dart` wires the four top-level tabs into a
  `StatefulShellRoute`. **Only the Library branch resolves to real screens**
  (`libraryBranchRoutes()`); `/home`, `/progress`, and `/settings` render
  `RoutePlaceholder`. All flashcard, study, and settings-sub routes also render
  `RoutePlaceholder`.
- `lib/presentation/features/` contains **only `folders/`**. There is no
  `dashboard/`, `progress/`, `settings/`, `flashcards/`, or `study/` feature
  package on this ref.

> ⚠️ **Documented drift.** Several wireframes (`01-dashboard.md` "Prompt 04",
> `03-progress.md` "Prompt 20", `04-settings-hub.md` "Prompt 21",
> `05-folder-detail.md` "Prompt 45/47/50") describe screens/sections as
> *Current/implemented/tested* and cite `lib/presentation/features/{dashboard,
> progress,settings}/…` files that **do not exist on this ref**. Treated as
> doc-ahead-of-code (or an unmerged branch). Scope below follows the code; the
> conflict is logged per-screen in §16 of the affected contracts and summarized
> in this file's Conflicts note.

## Scope status legend

| Status | Meaning |
| --- | --- |
| **Current** | Implemented on this ref and behaving per its contract. |
| **Partial** | Implemented, but only a subset of mock elements is in scope; others are Future. |
| **Future** | Not implemented on this ref (route renders `RoutePlaceholder`, or no route/screen exists). Mock + wireframe describe intent only. |
| **Unknown** | Source of truth is missing or ambiguous; needs a decision. |
| **Blocked** | Cannot proceed until a dependency/decision lands. |

## Index

| Screen | Route | Mock source (`index.html`) | Related docs | Existing Flutter files | Visual contract | Scope status | Priority | Notes |
|---|---|---|---|---|---|---|---|---|
| Library overview | `/library` | `03 · Library overview` (`03a`–`03f`) | `wireframes/02-library.md`; `business/folder/folder-management.md`; `state/*` | `features/folders/screens/library_overview_screen.dart` + `widgets/library_*`, `viewmodels/library_overview_viewmodel.dart` | `screens/library-overview.visual-contract.md` ✅ | **Partial** | P0 | Already fully mapped. Search is folder-scoped; sort/filter/progress/new-badge/root-deck are Future. |
| Folder detail | `/library/folder/:id` | `04 · Folder detail` | `wireframes/05-folder-detail.md`; `business/folder/folder-management.md`, `business/deck/deck-management.md` | `features/folders/screens/folder_detail_screen.dart`, `widgets/folder_detail_body.dart`, `folder_deck_tile.dart`, `folder_unlocked_empty.dart`, `folder_move_picker_sheet.dart`, `library_folder_actions_sheet.dart`, `viewmodels/folder_detail_viewmodel.dart`, `routes/folder_routes.dart` | `screens/folder-detail.visual-contract.md` ✅ | **Partial** | P0 | Browse (subfolders/decks/unlocked), breadcrumb, inline search, mode-locked create FAB = Current. **Hero mastery card, study/resume CTAs, overflow ⋮ actions = Future in code** (screen comment), though `05-folder-detail.md` claims Current — see conflict. |
| Dashboard | `/home` | `02 · Dashboard` | `wireframes/01-dashboard.md`; `business/engagement/dashboard-engagement.md`, `business/resume/resume-session.md` | _none_ (`RoutePlaceholder`); planned `features/dashboard/**` | `screens/dashboard.visual-contract.md` ✅ | **Future** | P1 | Route + shell tab Current; **screen body not implemented** (placeholder). Resume/Today/recent-decks are the intended V1 core; streak/goal/reminders are Future-of-Future. |
| Progress | `/progress` | `19 · Progress` (`18 · Stats` is legacy ref only) | `wireframes/03-progress.md`; `business/srs/srs-review.md`, `business/engagement/dashboard-engagement.md` | _none_ (`RoutePlaceholder`); planned `features/progress/**` | `screens/progress.visual-contract.md` ✅ | **Future** | P1 | Route + shell tab Current; **screen body not implemented**. V1 target = read-only overview (due/new/mastery + active sessions). Charts/box-distribution/streak = Future. |
| Settings hub | `/settings` | `20 · Settings` | `wireframes/04-settings-hub.md`; `business/navigation/navigation-flow.md`, `business/account-sync/account-sync.md` | _none_ (`RoutePlaceholder`); planned `features/settings/**` | `screens/settings-hub.visual-contract.md` ✅ | **Future** | P1 | Route + shell tab Current; **screen body not implemented**. Navigation-owner list; hosts no settings directly. Appearance/Language rows are disabled "Soon" rows. |
| Flashcard list | `/library/deck/:deckId/flashcards` | `06 · Flashcard list` | `wireframes/06-flashcard-list.md`; `business/flashcard/flashcard-management.md` | _none_ (deck-row nav target; no `flashcards` feature) | _TBD_ | **Future** | P2 | Target of "tap deck row" from Folder Detail. Feature not built; route registration via `folder_routes.dart` unconfirmed on this ref. |
| Flashcard create | `/library/deck/:deckId/flashcards/new` | `07 · Flashcard create` | `wireframes/07-flashcard-create.md`; `business/flashcard/flashcard-management.md` | _none_ (`RoutePlaceholder`) | _TBD_ | **Future** | P2 | Hidden route over shell. Uses shared form scaffold + inputs when built. |
| Flashcard edit | `/library/deck/:deckId/flashcards/:flashcardId/edit` | `08 · Flashcard edit` | `wireframes/08-flashcard-edit.md` | _none_ (`RoutePlaceholder`) | _TBD_ | **Future** | P2 | Hidden route over shell. |
| Flashcard history | `/library/deck/:deckId/flashcards/:flashcardId/history` | `09 · Flashcard history` | `wireframes/09-flashcard-history.md`; `business/history/card-history.md` | _none_ (no route registered) | _TBD_ | **Future** | P5 | Explicitly Future Proposal across docs; not exposed in V1. |
| Deck import | `/library/deck/:deckId/import` | `10 · Deck import` | `wireframes/10-deck-import.md`; `business/export/export.md` | _none_ (`RoutePlaceholder`) | _TBD_ | **Future** | P2 | Hidden route over shell. CSV/Excel import preview flow. |
| Library search | `/library/search` | `05 · Library search` | `wireframes/11-library-search.md`; `business/search/global-search.md` | _none_ (no route registered) | _TBD_ | **Future** | P5 | Global/cross-type search is Future. Library Overview & Folder Detail keep scope-local inline search only. |
| Tag management | `/settings/learning/tags` | `11 · Tag management` | `wireframes/22-settings-tag-management.md`; `business/tags/tag-system.md` | _none_ (`RoutePlaceholder`) | _TBD_ | **Future** | P4 | Sub-route of Learning settings; placeholder. |
| Study · Review | `/library/study/session/:sessionId` (Review mode) | `12 · Study · Review` | `wireframes/13-study-session-review.md`; `business/study/study-flow.md`, `business/srs/srs-review.md` | _none_ (`RoutePlaceholder`) | _TBD_ | **Future** | P3 | Study layer not built. Uses `MxStudyScaffold`, `MxFlashcard`, `MxRatingBar`. |
| Study · Match | `/library/study/session/:sessionId` (Match mode) | `13 · Study · Match` | `wireframes/14-study-session-match.md` | _none_ (`RoutePlaceholder`) | _TBD_ | **Future** | P3 | Uses `MxMatchTile`. |
| Study · Guess | `/library/study/session/:sessionId` (Guess mode) | `14 · Study · Guess` | `wireframes/15-study-session-guess.md` | _none_ (`RoutePlaceholder`) | _TBD_ | **Future** | P3 | Uses `MxChoiceOption`. |
| Study · Recall | `/library/study/session/:sessionId` (Recall mode) | `15 · Study · Recall` | `wireframes/16-study-session-recall.md` | _none_ (`RoutePlaceholder`) | _TBD_ | **Future** | P3 | Uses `MxSelfAssessment`; mastery-green accent. |
| Study · Fill | `/library/study/session/:sessionId` (Fill mode) | `16 · Study · Fill` | `wireframes/17-study-session-fill.md` | _none_ (`RoutePlaceholder`) | _TBD_ | **Future** | P3 | Typed-input mode; mastery-green accent. |
| Study entry gate | `/library/study/:entryType/:entryRefId`, `/library/study/today` | (gate; see `12 · Study` group) | `wireframes/12-study-entry-gate.md`; `business/study/study-flow.md` | _none_ (`RoutePlaceholder`) | _TBD_ | **Future** | P3 | Owns empty-scope validation, resume conflict, session creation. Folder/Today CTAs route here. |
| Study result | `/library/study/session/:sessionId/result` | `17 · Study result` | `wireframes/18-study-result.md`; `business/study/study-flow.md` | _none_ (`RoutePlaceholder`) | _TBD_ | **Future** | P3 | End-of-session summary. |
| Account & Drive sync | `/settings/account` | `21 · Account sync` | `wireframes/19-settings-account.md`; `business/account-sync/account-sync.md` | _none_ (`RoutePlaceholder`); `core/auth/google_auth.dart` exists | _TBD_ | **Future** | P4 | Sub-route over shell. Google sign-in/backup/restore chain. |
| Learning settings | `/settings/learning` | `22 · Learning settings` | `wireframes/20-settings-learning.md`; `business/engagement/dashboard-engagement.md` | _none_ (`RoutePlaceholder`) | _TBD_ | **Future** | P4 | Daily goal / reminders. Engagement is Future. |
| Audio & speech settings | `/settings/audio-speech` | `23 · Audio & speech` | `wireframes/21-settings-audio-speech.md`; `business/tts/tts-settings.md` | _none_ (`RoutePlaceholder`) | _TBD_ | **Future** | P4 | TTS voices/engine. |
| Onboarding | _no route_ (Dashboard empty state) | `01 · Onboarding` | `wireframes/23-onboarding.md`; `business/system/overview.md` | _none_ | _TBD_ | **Future** | P5 | No dedicated route in V1; empty-state guidance only. |
| Shared dialogs catalog | n/a (cross-cutting) | (overlays across screens) | `wireframes/24-shared-dialogs.md` | `shared/dialogs/mx_confirm_dialog.dart`, `mx_name_dialog.dart`, `mx_bottom_sheet.dart` | `component-visual-contract.md` | **Partial** | P0 (ongoing) | Confirm/name dialogs implemented & used by folders. Others (discard-session, restore-warning, etc.) built as their owning screens land. |
| Shared bottom-sheets catalog | n/a (cross-cutting) | (overlays across screens) | `wireframes/25-shared-bottom-sheets.md` | `features/folders/widgets/folder_move_picker_sheet.dart`, `library_folder_actions_sheet.dart`, `shared/dialogs/mx_bottom_sheet.dart` | `component-visual-contract.md` | **Partial** | P0 (ongoing) | Folder move/action sheets implemented. Scope-picker, tag-picker, deck-create, daily-goal, reminder-time, paused-sessions, etc. are Future. |

## Conflicts summary (see each contract's §16 for detail)

| Issue | Type | Affected | Reason | Recommended action |
| --- | --- | --- | --- | --- |
| Wireframes mark Dashboard/Progress/Settings screens "Current/tested" but feature folders are absent on this ref | Unknown source | Dashboard, Progress, Settings hub | Doc ahead of code, or implementation on an unmerged branch | Confirm branch/state of truth; if `main` is canonical, update the wireframes' `V1 verification status` blocks; treat screens as Future for new work |
| `05-folder-detail.md` claims hero mastery card + study/resume CTAs went Current (Prompt 45/47/50); `folder_detail_screen.dart` comment says they are Future ("the study layer is not built") and the code renders none of them | Business/state conflict | Folder detail | Wireframe ahead of code | Follow code (study layer absent) for now; reconcile wireframe; do not render hero/study CTAs with placeholder data |
| Overflow ⋮ on Folder Detail app bar is rendered with `onPressed: null` (disabled) | Mock-only element | Folder detail | No folder-level action sheet wired on Folder Detail (it exists on Library Overview rows) | Keep disabled/visual-only until folder overflow actions are promoted |
| Visual language naming: `wireframes/index.md` cross-ref calls the theme "Slate Meridian, Plus Jakarta Sans"; design system README calls it "Tokyo Pure Light / Tokyo Nebula, Plus Jakarta Sans" | Unknown source | All screens (color/theme contract) | Stale theme name in one cross-reference | Treat design-system README + `colors_and_type.css` as canonical (Tokyo Pure Light/Nebula); fix the wireframe cross-ref |

## Recommended implementation order

1. **P0 — finish what exists.** Library Overview & Folder Detail parity passes
   against their contracts (no new screens).
2. **P1 — top-level tabs (replace placeholders):** Dashboard → Settings hub →
   Progress. These complete the shell the user already navigates.
3. **P2 — library depth:** Flashcard list → create → edit → Deck import.
4. **P3 — study flow:** Study entry gate → session modes (Review, Guess, Match,
   Recall, Fill) → Study result.
5. **P4 — settings sub-screens:** Account sync → Learning → Audio & speech →
   Tag management.
6. **P5 — deferred:** Library/Global search, Flashcard history, dedicated
   Onboarding. Shared dialog/sheet catalog entries land alongside their owning
   screens throughout.

## Related

- `docs/design/README.md`
- `docs/design/mock-design-index.md`
- `docs/design/design-token-mapping.md`
- `docs/design/component-visual-contract.md`
- `docs/design/visual-parity-checklist.md`
- `docs/wireframes/index.md`
