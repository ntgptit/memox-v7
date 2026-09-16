---
last_updated: 2026-06-06
status: contract
route: /settings
screen: Settings Hub
mock_source: "docs/system-design/MemoX Design System/ui_kits/mobile/index.html — 20 · Settings"
---

# Settings Hub Visual Contract

Maps the approved **Settings Hub** mock to its (not-yet-built) Flutter
implementation. The `/settings` route and bottom-nav tab are wired, but the
**screen body is not implemented on this ref** (route → `RoutePlaceholder`; no
`lib/presentation/features/settings/**`). The hub is a **navigation owner** — a
grouped list of rows that push sub-screens. It hosts **no settings directly**.

> ⚠️ **Doc/code drift.** `docs/wireframes/04-settings-hub.md` ("Prompt 21")
> marks the hub Current and cites `features/settings/**` files absent on this
> ref. The sub-screens it links (Account, Learning, Audio/Speech, Tags) are also
> placeholders. Build per this contract; reconcile the wireframe. See §16.

## 1. Screen identity

- **Screen name:** Settings Hub
- **Route:** `/settings` (`RoutePaths.settings`, `RouteNames.settings`); shell
  branch 3. Sub-routes: `/settings/account`, `/settings/learning`,
  `/settings/learning/tags`, `/settings/audio-speech` (all `RoutePlaceholder`).
- **Feature / module:** planned `settings` (`lib/presentation/features/settings/**`).
- **User purpose:** Single entry point to all settings sub-screens; shows a few
  status subtitles (account/sync), hosts no toggles/sliders.
- **Mock source:** `index.html` `20 · Settings` (states: populated · loading ·
  signed out · signing in · sync error).
- **Related business docs:** `docs/business/navigation/navigation-flow.md`,
  `docs/business/account-sync/account-sync.md`.
- **Related wireframe:** `docs/wireframes/04-settings-hub.md`.
- **Related state docs:** `docs/state/state-management-contract.md`; per-row
  subtitle providers (account/sync, goal, TTS, tag count).
- **Existing Flutter implementation files:** **none** (route → `RoutePlaceholder`).
  Related: `lib/core/auth/google_auth.dart`, `core/config/google_oauth_config.dart`.
- **Scope status:** **Future** (screen body); route + shell tab are Current.
- **Out-of-scope items (Future):** Appearance & Language rows (render as disabled
  "Soon" rows; no route), About bottom-sheet (V1 uses Flutter `AboutDialog`),
  live aggregate subtitles for Learning/Audio/Tags (V1 summaries only).

## 2. Source priority

1. Business: `navigation-flow.md`, `account-sync.md`.
2. Wireframe `04-settings-hub.md` (use its `V1 verification status` table;
   discount file-path "Current owner" claims — see §16).
3. State: per-row subtitle providers; `state-management-contract.md`.
4. Route/navigation: `RoutePaths`/`RouteNames`; sub-routes push over the shell
   (shell hidden on sub-screens; back returns to hub).
5. Existing Flutter: none yet.
6. Shared widgets: `mx_widgets.dart` (notably `MxSettingsTile`, `MxSectionHeader`).
7. Theme/tokens: `lib/core/theme/**`.
8. Mock `20`.
9. This contract.

## 3. Screen layout overview

`MxScaffold` + `MxAppBar` ("Settings", no actions) over a scrolling grouped list
inside the shell. Groups: **Account · Study · App · About**. Each row =
`MxSettingsTile` (icon + title + dynamic subtitle + chevron); whole row tappable.

| Region | Position | Fixed/Scrollable | Visual weight | Token mapping | Shared widget | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| App bar | Top | Fixed | Low | `SizeTokens.appbar` | `MxAppBar(titleText:)` | No actions. |
| Section header (×4) | Above each group | Scrolls with list | Low | overline (ALL CAPS, `sectionSpacing`) | `MxSectionHeader` | "ACCOUNT", "STUDY", "APP", "ABOUT". |
| Account row | Account group | Scrollable | Medium | `MxSettingsTile`; `brLg` | `MxSettingsTile` | Subtitle = sign-in + sync state; never hidden when signed out. → `/settings/account`. |
| Learning row | Study group | Scrollable | Medium | `MxSettingsTile` | `MxSettingsTile` | Subtitle = study-defaults summary (V1). → `/settings/learning`. |
| Audio & Speech row | Study group | Scrollable | Medium | `MxSettingsTile` | `MxSettingsTile` | Subtitle = language/speech summary (V1). → `/settings/audio-speech`. |
| Manage tags row | Study group | Scrollable | Medium | `MxSettingsTile` | `MxSettingsTile` | Subtitle = management summary (V1). → `/settings/learning/tags`. |
| Appearance row | App group | Scrollable | Low | disabled tile + "Soon" badge | `MxSettingsTile` (disabled) + `MxStatusBadge` | **Future.** No route. |
| Language row | App group | Scrollable | Low | disabled tile + "Soon" badge | `MxSettingsTile` (disabled) + `MxStatusBadge` | **Future.** No route. |
| About row | About group | Scrollable | Low | `MxSettingsTile` | `MxSettingsTile` | Subtitle = version. Opens `AboutDialog` (V1); About sheet = Future. |
| Bottom nav | Bottom (shell) | Fixed | Low | `bottomNav` (80) | `MxBottomNavigationBar` | **Current.** |

No full-screen empty state — rows are always visible; only subtitles
skeleton/error per row.

## 4. State matrix

| State | Trigger | Visible regions | Hidden regions | Primary CTA | Secondary CTA | Shared state widget | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Loading | Initial open | all rows; subtitles skeleton | — | — | — | row-level skeleton ("—") | Rows visible immediately. |
| Populated | Normal | all rows + subtitles | — | tap any row | — | — | — |
| Signed out | No cloud account | all rows; Account subtitle "Not signed in — Tap to set up backup." | — | Account row | — | — | Never hide Account row. |
| Signing in | OAuth/token refresh | Account subtitle "Signing in…" + spinner | — | — | — | inline spinner | — |
| Sync error | Last sync failed | Account row error indicator + "Sync failed — Tap to review." | — | Account row | — | row error state | — |

## 5. Element mapping

| Mock element | Purpose | Existing shared widget | Token/theme mapping | State visibility | Behavior scope | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| App bar title | Identify screen | `MxAppBar(titleText:)` | app-bar title | all | **Current** | "Settings". |
| Section headers | Group rows | `MxSectionHeader` | overline; `onSurfaceVariant` | all | **Current-intent** | Announced as headings. |
| Account row | → account/sync | `MxSettingsTile` | `brLg`; icon `iconMd`; chevron | all | **Current-intent** | Subtitle dynamic; → `/settings/account` (target Future). |
| Learning row | → learning settings | `MxSettingsTile` | same | all | **Current-intent** | → `/settings/learning` (target Future). |
| Audio & Speech row | → TTS settings | `MxSettingsTile` | same | all | **Current-intent** | → `/settings/audio-speech` (target Future). |
| Manage tags row | → tag management | `MxSettingsTile` | same | all | **Current-intent** | → `/settings/learning/tags` (target Future). |
| Appearance row | theme prefs | `MxSettingsTile` (disabled) + `MxStatusBadge` "Soon" | disabled (38%) | all | **Future** | No route; disabled. |
| Language row | locale prefs | `MxSettingsTile` (disabled) + `MxStatusBadge` "Soon" | disabled (38%) | all | **Future** | No route; disabled. |
| About row | app info | `MxSettingsTile` | same | all | **Current-intent (dialog)** | Opens `AboutDialog`; About sheet = Future. |
| Row chevron | affordance | tile trailing | `iconSm`/`iconMd`; `onSurfaceVariant` | all | **Current-intent** | Decorative; row is the control. |
| Account status dot/badge | sync state | `MxStatusBadge` / status dot (8dp) | status palette | account states | **Current-intent** | "Synced" / error. |

## 6. Typography contract

| Text element | UI role | Typography token/role | Color role | Max lines | Overflow | l10n | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- |
| App bar title | Screen title | app-bar title | `onSurface` | 1 | ellipsis | yes | "Settings". |
| Section header | Group overline | section overline (ALL CAPS, `sectionSpacing`) | `onSurfaceVariant` | 1 | clip | yes | Sentence-case elsewhere; overlines are the exception. |
| Row title | Setting name | `titleSmall`/`bodyLarge` | `onSurface` | 1 | ellipsis | yes | — |
| Row subtitle | Dynamic status | `bodyMedium`/`labelMedium` | `onSurfaceVariant` | 1–2 | ellipsis | yes (values are data) | Must be in the row's a11y label too. |
| "Soon" badge | Future marker | label (small) | badge tokens | 1 | clip | yes | Appearance/Language. |
| Account email | identity | `bodyMedium` | `onSurfaceVariant` | 1 | ellipsis | data | "Signed in as {email}". |

## 7. Color and surface contract

| Surface/role | Required role | Notes |
| --- | --- | --- |
| Page background | `surface` | `MxScaffold`. |
| App bar | glass | `MxAppBar`. |
| Row tiles | `surfaceContainerLowest` via `MxSettingsTile`/`MxCard` | ghost border; grouped. |
| Section header text | `onSurfaceVariant` | overline. |
| Disabled rows | content @ 38% (`OpacityTokens`) | Appearance/Language. |
| Account status | status palette (success/error) | `CustomColors`. |
| Chevron / icon | `onSurfaceVariant` | — |
| Dark mode | Tokyo Nebula parity | — |

## 8. Spacing, sizing, and radius contract

| Area/element | Padding | Gap | Radius | Size token | Responsive | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| Screen horizontal | `screenPadding` (24) | — | — | — | scales naturally | — |
| Between groups | — | `sectionGap` (32) | — | — | — | — |
| Group block | — | row gap `sm`/`listItemGap` (8) | `brLg` | — | — | grouped card or divided list. |
| Row | `cardPadding`/list-tile insets | icon→text `md` | `brLg` (group) | leading `iconMd`; min height `touch` (48) | — | whole row tappable. |
| Divider (if used) | indent `dividerIndent` (56) | — | — | — | — | aligns past leading icon. |
| Touch targets | — | — | — | min `touch` (48) | — | — |

## 9. Interaction contract

| Interaction | Trigger | Expected behavior | State change | Shared component/API | Scope | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| Tap Account row | tap | push `/settings/account` | nav | router | **Current-intent** | target screen Future. |
| Tap Learning row | tap | push `/settings/learning` | nav | router | **Current-intent** | target Future. |
| Tap Audio & Speech | tap | push `/settings/audio-speech` | nav | router | **Current-intent** | target Future. |
| Tap Manage tags | tap | push `/settings/learning/tags` | nav | router | **Current-intent** | target Future. |
| Tap Appearance / Language | tap | (none) | — | disabled tile | **Future** | disabled "Soon". |
| Tap About | tap | open `AboutDialog` (version/legal) | dialog | Flutter `AboutDialog` | **Current-intent** | About sheet = Future. |
| Subtitle load/refresh | watch | fill subtitle per row independently | per-row provider | watch | **Current-intent** | failures isolated; show "—"/skeleton, never stale. |

## 10. Motion and animation contract

| Motion | Token | Notes |
| --- | --- | --- |
| Subtitle skeleton → text | `contentSwitch` (200) | per-row. |
| Row press | M3 state layer | no scale-down. |
| Push to sub-screen | `pageTransition` (300) + emphasized | router (shell hidden on sub-screen). |
| Sign-in spinner | indeterminate; reduced-motion ok | inline. |

## 11. Accessibility contract

- **SR order:** title → group header → rows (title + subtitle announced
  together) → next group → bottom nav.
- **Semantic labels:** section headers announced as headings; each row's subtitle
  MUST be part of its accessibility label; disabled rows announce disabled +
  "Soon".
- **Touch targets:** rows ≥ 48dp.
- **Contrast:** AA both themes. **Text scaling:** titles/subtitles reflow; rows
  grow in height rather than clip.

## 12. Responsive contract

| Context | Fixed | Scrolls | Wraps | Truncates | Never hidden | Denser |
| --- | --- | --- | --- | --- | --- | --- |
| Mobile (all) | app bar, bottom nav | list | subtitles | row titles | Account row | — |
| ≥600dp | app bar, side rail | list | subtitles | titles | Account row | list stays single-column (no column change) |
| ≥1024dp | as ≥600 wider gutters | list | — | titles | same | — |

## 13. Data/content contract

- **Real data:** account sign-in state + email + sync result (`AuthService` +
  prefs); app version (`package_info_plus`). V1 summaries for Learning/Audio/Tags.
- **Future data:** live aggregates (daily goal, TTS default voice label, total
  tag count) belong to the sub-screens, not the hub, in V1.
- **Mock/demo data (do NOT copy):** "giap@gmail.com", "Synced 2h ago", "Daily
  goal: 20 cards", "42 tags", "Version 1.0.0".
- **Empty/loading value display:** subtitle shows "—" or skeleton while loading;
  never stale.
- **Localization:** all labels/subtitles via ARB.

## 14. Flutter implementation guidance

**Inspect before building:** `app_router.dart` (`/settings` + sub-routes already
declared as placeholders — replace builders), `route_names.dart`,
`route_paths.dart`, `mx_widgets.dart` (`MxSettingsTile`, `MxSectionHeader`,
`MxStatusBadge`), `navigation-flow.md`, `account-sync.md`,
`lib/core/auth/google_auth.dart`.

**Create (planned):** `features/settings/screens/settings_screen.dart`,
`widgets/settings_overview_groups.dart`, `widgets/settings_group.dart`, plus the
four sub-screens as their own contracts/tasks (P4).

**Reuse:** `MxScaffold`, `MxAppBar`, `MxSettingsTile`, `MxSectionHeader`,
`MxStatusBadge`, `MxSkeleton`, `MxBottomNavigationBar`; Flutter `AboutDialog`.

**Must not change:** token classes, `Mx*` internals, route structure, l10n keys.

**Forbidden assumptions:** the hub hosts **no** settings UI (no toggles/sliders)
— each setting lives in its sub-screen. Do not hide the Account row when signed
out. Do not enable Appearance/Language. Do not show stale subtitles.

## 15. Visual parity checklist

- [ ] All mock elements documented (§5).
- [ ] Current-intent rows implementable with `MxSettingsTile` + tokens.
- [ ] Future rows marked (Appearance, Language; About sheet; live aggregates).
- [ ] No raw hex / random spacing / raw `TextStyle` / raw `Card`/`ListTile`
      where `MxSettingsTile` applies.
- [ ] No hardcoded strings (l10n).
- [ ] Loading / populated / signed-out / signing-in / sync-error states distinct
      (row-level).
- [ ] Account row never hidden when signed out.
- [ ] Dark mode considered. [ ] Text scaling considered. [ ] Accessibility
      (subtitle in label, headings) considered. [ ] Conflicts documented (§16).

## 16. Open questions and conflicts

| Issue | Type | Affected element | Reason | Recommended action |
| --- | --- | --- | --- | --- |
| Wireframe marks hub + sub-screens Current with `features/settings/**` files; none exist on this ref | Unknown source | Whole screen + sub-screens | Doc ahead of code | Confirm source of truth; build per this contract; update wireframe |
| About: V1 `AboutDialog` vs target About bottom-sheet | Mock-only element | About row | Sheet is release-polish target | Ship `AboutDialog` now; defer sheet |
| Appearance/Language rows shown in mock | Future scope | App group rows | No routes/implementation | Render disabled "Soon" rows; do not wire routes |
| Live aggregate subtitles (goal, TTS voice, tag count) in mock | Future scope | Row subtitles | V1 uses summaries; live counts belong to sub-screens | Use V1 summary subtitles; defer live aggregates |

## Related

- `docs/design/README.md`, `docs/design/screen-index.md`
- `docs/design/design-token-mapping.md`, `docs/design/component-visual-contract.md`
- `docs/wireframes/04-settings-hub.md`, `docs/wireframes/19-settings-account.md`,
  `docs/wireframes/20-settings-learning.md`, `docs/wireframes/21-settings-audio-speech.md`,
  `docs/wireframes/22-settings-tag-management.md`
- `docs/wireframes/25-shared-bottom-sheets.md` §about
