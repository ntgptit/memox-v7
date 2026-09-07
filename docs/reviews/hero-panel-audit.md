# Hero panels — full audit, and the trial that answers it

| | |
|---|---|
| **Status** | draft |
| **Purpose** | Audit every hero-tier panel in the app against the owner's 2026-09-08 brief — modern, legible, not colourful, appropriate to a study app — and record the trial built to answer it |
| **Scope** | The seven hero-tier panels: Library level summary, Study Home Resume, Progress streak, Progress today, Card Detail summary, Import outcome, study focal cards. Includes the Study Entry band, which has no hero and is judged for that. Out of scope: palette, business rules, the four frozen contracts this touches nothing of, the deck rows and list chrome under each hero |
| **Source of truth for** | The 2026-09-08 hero audit's evidence, its findings H1–H5, and the delta the trial branch applies; not a product or design-system specification |
| **Depends on** | `../document-conventions.md` · `../product.md` · `../business-rules.md` (BR-142, BR-150, BR-161, BR-162, BR-200) · `../design-system/v1-freeze.md` · `../design-system/card-recipes.md` |
| **Updated by task** | M100.61 |
| **Last updated** | 2026-09-08 |

## 1 · Method, and what it can and cannot claim

Baseline `e9b21777`, which is `origin/main` exactly — worktree clean at start,
`git rev-list --left-right --count origin/main...HEAD` → `0 0`. Every line
number below was read off that tree, not carried over from an earlier report.

| Evidence | Weight it carries |
|---|---|
| Source of all seven panels, plus `MxCard`'s ten recipes and `MxSectionLabel` | Full. Every finding names a file and line |
| Eight committed goldens opened and looked at: `deck_list_root_{light,dark}`, `study_home_{light,dark}`, `progress_overview_dark`, `study_entry_light`, `card_detail_light`, `card_import_result_complete_light` | Full for *composition*. They are committed PNGs, and until the trial's Linux run they were not proved to match a fresh render of HEAD |
| `flutter test --exclude-tags golden` on the changed tree | Full. Results in §6 |
| Linux golden authoring, WSL Ubuntu 24.04, Flutter 3.44.8, `TZ=UTC` | Full for pixels. Windows cannot author goldens here (freeze contract 14) |
| TalkBack, device profiling, real-device gesture sweep | **Not run.** No accessibility, performance or platform score below is a device measurement, and none is presented as one |

**One number in this report was produced by a measurement that did not exist
before it, and it changed the finding.** H3 was written from the source as a
*risk* — two `maxLines: 1` texts under a width calculation. Extending the
panel's own clipping guard from one width and two scales to sixteen
width × scale cases turned it into a confirmed defect at exactly one corner
(§H3). That is the difference between "this looks fragile" and "this clips",
and it is why the guard was widened before the code was touched.

## 2 · What a hero panel is here, and the inventory

A hero-tier panel is the first card on a screen, answering that screen's one
question before any list does. Seven exist. The inventory below is the whole
finding, so it comes before the findings:

| # | Panel | Surface recipe | Eyebrow | How it outranks its neighbours |
|---|---|---|---|---|
| 1 | Progress · Current streak | `MxCard.raised` | `MxSectionLabel` caps | numeral + supporting line |
| 2 | Progress · Today | `MxCard.raised` | `MxSectionLabel` caps | numeral + two-row split |
| 3 | Card Detail · summary | `MxCard.raised` | none — the term names itself | type scale, and it is the content |
| 4 | Import · outcome | `MxCard.raised` | none — the title names itself | centred icon well + headline |
| 5 | Study session · summary | `MxCard.raised` | `MxSectionLabel` caps | numeral rows |
| 6 | **Library · level summary** | **`MxCard.accent`** | none (removed 2026-08-25) | numeral + filled CTA **+ an indigo edge + a step of elevation** |
| 7 | **Study Home · Resume** | **`MxCard.tonal`** | hand-set `labelMedium` bold | filled CTA **+ a tinted fill + zero elevation** |

`MxCard.accent` and `MxCard.tonal` have exactly one production caller each, and
they are these two. Five panels rank themselves by type on the page's own
surface; two spend a second device on top of that, and they are the two the
owner's brief describes. **The direction this report recommends is therefore
not a new look — it is the look five sevenths of the app already has.**

`MxHeroCard` is not a surface. It measures the card's outer width so the CTA
can pick its width tier (S17), and it draws nothing. It should stay that way;
growing it into a slotted hero component would put three different anatomies
behind one API for no caller's benefit.

Two things deliberately do **not** join the family. **Study focal cards**
(`MxCard.focal`, four callers) are the screen, not a summary of it; their empty
space is the exercise. **Study Entry** has no card at all — a workload row and
two buttons on the bare page (§H5).

## 3 · Findings

### H1 · P2 · confirmed defect · The hero's headline is announced as a set it is not

- **Category:** Accessibility / content. Confirmed from source and from a
  failing-then-passing test; TalkBack not run.
- **Location:** `lib/features/deck/presentation/widgets/sections/deck_summary_metrics_widget.dart:266`
  (before the trial); `lib/l10n/app_en.arb` · `app_vi.arb`, key
  `deckHeroDueTodaySemanticLabel`.
- **Evidence.** `_numeral` passed `dueCount` to `deckHeroDueTodaySemanticLabel`.
  BR-162 defines `Due today` as `due_at >= startOfToday` and keeps
  `dueCardCount = overdueCardCount + dueTodayCardCount`, so `dueCount` is the
  **sum** of two disjoint sets. On the committed root fixture — 15 due, 8 of
  them overdue — a screen reader was told *"15 cards due today"* about a panel
  whose own visible line says `8 overdue · 7 today`.
- **It was pinned by a test, which is why it survived.**
  `deck_summary_overdue_test.dart` asserted
  `bySemanticsLabel(deckHeroDueTodaySemanticLabel(15))` on a level with 12
  overdue. The assertion encoded the bug; BR-162 is the higher authority.
- **Second half.** `_breakdown` announced only the overdue sentence, so the
  `· 7 today` half of BR-162's split reached no listener anywhere on the panel —
  the headline above it was busy announcing the sum.
- **Impact.** A listener receives a classification the screen never shows, and
  the panel contradicts itself between its two nodes. BR-162 exists to make the
  split reachable; it was reachable for one half only.
- **Fixed in the trial.** A new `deckHeroDueTotalSemanticLabel` for the sum
  ("15 cards to review" / "15 thẻ cần ôn"); the breakdown node now joins the
  **unchanged** `deckHeroOverdueSemanticLabel` — BR-162 requires the backlog age
  to arrive through that resource — with `deckHeroDueTodaySemanticLabel` given
  its correct count. The due-today resource keeps its meaning and gains its
  right argument.

### H2 · P3 · design direction · Two hero panels emphasise themselves by paint

- **Category:** Appearance. This is the owner's brief applied, not a Material
  violation: M3 permits filled, elevated and outlined cards, and choosing a
  variant by role is legitimate ([Android Developers — Card](https://developer.android.com/develop/ui/compose/components/card)).
- **Location:** `deck_level_summary_widget.dart:110` · `study_home_resume_section_widget.dart:73`.
- **Evidence, measured off the recipes** (`mx_card.dart:592`, `:654`):

  | Recipe | Fill | Edge | Elevation |
  |---|---|---|---|
  | `raised` (5 panels, all deck rows) | `surfaceContainerLow` | none | `card` |
  | `accent` (Library hero) | `surfaceContainerLow` | `borderAccent` | `raised` |
  | `tonal` (Resume) | `semantic.surfaceEmphasis` | none | `none` |

  In `deck_list_root_dark.png` the Library hero is the only outlined card above
  six hairlined ones, and the violet edge is the brightest line on the screen.
  In `study_home_dark.png` the Resume card is a 353 × 355 dp lighter slab
  holding four short lines — the largest single area of colour in the app, and
  simultaneously the only *unlifted* card on a screen of lifted ones.
- **The accent's original argument no longer holds.** It was adopted
  2026-08-20 because the panel "did not separate from the background at all".
  That reading was taken against a borderless card; `MxCard.raised` has carried
  `AppElevation.card` since. Separation is already paid for, and what the edge
  adds on top is rank.
- **Impact.** The two entrances to the same task — start something new, carry
  on something started — attract the eye in two different grammars, neither of
  them the one the other five panels use. Colour and edge compete with the
  numeral and the button, and dark is where it is worst.
- **Changed in the trial.** Both to `MxCard.raised`. Emphasis then comes from
  what already carried it: a 34 px numeral and the screen's only *filled*
  button on Library; the eyebrow, first position and the screen's only filled
  button on Study Home, against the rows' outlined `Study`. Both survive a
  greyscale print; a tint does not.
- **Consequence to accept or reject.** `MxCard.accent` and `MxCard.tonal` are
  left with no production caller. They stay compiled, specimen'd and tested
  (`mx_card_recipes_test.dart`); retiring or re-justifying them is a
  design-system decision, not this task's (§7).

### H3 · P2 · confirmed defect · The hero clips BR-162's split at 320 dp, scale 2.0

- **Category:** Adaptivity. **Confirmed by measurement**, and it was a P3
  suspicion until that measurement existed.
- **Location:** `deck_summary_metrics_widget.dart` — the hero word and the
  breakdown, both `maxLines: 1` with an ellipsis.
- **What the guard covered before.** `deck_summary_overdue_test.dart` already
  had a clipping guard — a `RenderParagraph.didExceedMaxLines` sweep, which is
  the right instrument, because this failure throws no overflow and raises no
  exception. It ran at **360 dp only, at scales 1.3 and 1.5**.
- **What widening it to 320/360/393/412 × 1.0/1.3/1.5/2.0 found.** Fifteen of
  sixteen cases clean. At **320 dp, textScaler 2.0** three paragraphs were cut:

  ```
  'cards due'            → the unit word, so the numeral loses what it counts
  '8 overdue · 7 today'  → BR-162's split, entire
  '10 of 52 learned'     → MxProgressBar's caption (expanded state)
  ```

- **Impact.** On the narrowest phone the app supports, at the accessibility
  scale that matters most, the panel silently deletes the split it exists to
  state — for the users most likely to need it.
- **Fixed in the trial, for the two the hero owns.** `maxLines: 2` on both.
  This is inert everywhere else: the shared-baseline branch is only entered
  after `fitsOnOneLine` has proved the whole line fits, so nothing wraps at any
  width or scale the goldens capture. The stacked branch is where it applies.
- **Not fixed, and reported instead:** `MxProgressBar`'s caption is a shared
  primitive's own layout. It follows the accepted shape the quiet context row
  writes down — the figures survive, the trailing word clips — but the fix
  belongs to a design-system task. The widened guard excludes that one string
  by name, with the debt stated at the exclusion.

### H4 · P3 · design direction · Three eyebrow policies for one tier

- **Category:** Appearance / accessibility.
- **Location:** `study_home_resume_section_widget.dart` (before the trial).
- **Evidence.** `MxSectionLabel` is the app's one heading treatment (D18), and
  `MxSectionLabelRung.small` is documented as "a face label inside a card" with
  five callers, the study prompt's own `QUESTION` among them. Resume drew its
  `Carry on` by hand: `labelMedium`, `w600`, `AppInk.stated` — the same ink and
  nearly the same weight as the deck name directly beneath it, so the card
  opened with two dark bold lines and the eyebrow competed with the thing it
  introduces. It also had no `header` node, so a screen reader could not jump
  to it the way it can on Progress.
- **The rule that reconciles all seven panels**, and it is not "every hero gets
  an eyebrow": **an eyebrow appears when the headline does not name itself.**
  `5 days` needs `CURRENT STREAK`; `Everyday Korean` needs `CARRY ON`;
  `15 cards due`, `사과` and `Import complete` do not. That is why re-adding
  `TODAY` to the Library hero would be wrong — the owner removed it
  2026-08-25 for exactly this reason, and the trial leaves it removed.
- **Changed in the trial.** `MxSectionLabel(rung: small)`, quiet caps, with the
  `header` node that comes with it.

### H5 · P3 · reported only · Study Entry is a hero-shaped screen with no hero

- **Location:** `study_entry_section_widget.dart`; `study_entry_light.png`.
- **Evidence.** The screen is a small workload row, two full-width buttons, and
  roughly 1,000 dp of empty page below them. It is the only screen in the study
  path with no card of any kind.
- **Why it is reported and not fixed.** Adding a panel to match the others is
  form-matching, and the brief asks for restraint. The screen may be right as
  a two-choice fork. It is named here so the decision is a decision.

**Totals:** 0 P0 · 0 P1 · 2 P2 confirmed (H1, H3) · 3 P3 direction/report.

## 4 · Why the direction is convergence, not invention

| Why | Finding | What it settles |
|---|---|---|
| 1. Why must a hero be restrained at all? | The user opens the app to find the next thing to study; every extra visual signal is time before the number or the button is found | One focus and at most one primary action per hero |
| 2. Why is desaturating not enough? | The Library hero was loud through an *edge* and a *step of depth*, not a fill. Changing hue would have changed nothing | Emphasis is a composition question before it is a colour question |
| 3. Why not give all seven the same anatomy? | Resume answers "continue what?", streak answers "how consistent?", Card Detail *is* the content | Share the surface, the eyebrow rule and the rhythm; keep anatomy per job |
| 4. Why not equalise their heights? | Vietnamese, long meanings and scale 2.0 all need more room; forcing height is what produced H3's clipping | Legibility first; measure geometry per state and viewport |
| 5. Why does no token or palette change? | Five panels already read the way the brief asks. The difference lives at two call sites | A narrow change, and V1's freeze untouched |

**Nothing in the trial touches a frozen contract.** `v1-freeze.md` puts
"composition của từng màn hình nghiệp vụ" explicitly out of freeze scope, and
none of the fourteen contracts covers which recipe a screen composes with. No
token value, no `ColorScheme` role, no shared primitive API, no business rule
moved.

## 5 · Technical audit scores

| Dimension | Score | Basis, and its limit |
|---|---|---|
| Accessibility | **3 / 4** | Labels, units, grouping and a 48 dp floor are in place across all seven; H1 was a real defect and is fixed; H4 adds a missing `header`. Source and host tests only — no TalkBack, no device contrast sweep |
| Performance | **not scored** | The panels are `Text` and layout, but nothing was profiled on a device. A score here would be invention |
| Appearance & theming | **3 / 4** | Semantic ink, recipes and typography tokens throughout — zero raw colours. The point lost is H2/H4: three emphasis devices and three eyebrow policies for one tier, before the trial |
| Platform conformance | **3 / 4** | Material components, shared primitives, Material Symbols, no web-shaped controls, no hover affordances. Back gesture, insets and ripple were not exercised on a device |
| Adaptivity | **3 / 4** | `LayoutBuilder`, measured wrap branches, an S17 width tier and a real clipping guard. The point lost is H3 — the guard had one width and the corner it never saw was clipping |
| **Total** | **not published** | Four of five dimensions is not a score out of 20, and calling it one would be the report's own worst finding |

**Platform verdict: pass.** This reads as a Flutter/Material Android app, not a
ported web page. No hero uses a gradient, a hover state, a decorative
illustration or a marketing-shaped headline. Nothing was certified from a PNG.

**What is working and must not be lost:** no decorative gradients anywhere;
CTA hierarchy is genuinely primary/secondary; every error and overdue state
carries words as well as colour; Card Detail never truncates a meaning; the
Progress hero folds a streak into one sentence a screen reader can use; the
hero CTA measures its width *outside* the card's padding, which is the trap
`MxHeroCard` exists to hold. The clipping guard in
`deck_summary_overdue_test.dart` is the best instrument in this area of the
suite — it was under-pointed, not wrong.

## 6 · The trial, and its verification

Branch `feat/hero-panel-quieter`, off `e9b21777`. **Not merged**, by request.

| Change | File |
|---|---|
| Headline announces the Reviewing total; breakdown announces both halves | `deck_summary_metrics_widget.dart`; two new ARB keys, EN + VI |
| Unit word and breakdown wrap instead of ellipsizing | `deck_summary_metrics_widget.dart` |
| `MxCard.accent` → `MxCard.raised` | `deck_level_summary_widget.dart` |
| `MxCard.tonal` → `MxCard.raised`; `Carry on` → `MxSectionLabel(rung: small)` | `study_home_resume_section_widget.dart` |
| Clipping guard widened 2 cases → 16 | `deck_summary_overdue_test.dart` |
| Three assertions corrected to BR-162 and to the new eyebrow treatment | `deck_summary_overdue_test.dart` · `study_ink_pairing_test.dart` · `study_home_card_geometry_test.dart` |

Progress, Card Detail, Import and every focal card are untouched.

| Gate | Result |
|---|---|
| `flutter pub get`, `build_runner`, `gen-l10n` | PASS — 3142 outputs |
| `flutter analyze` (repo-wide) | see §6.1 |
| `flutter test --exclude-tags golden` | see §6.1 |
| Golden authoring, Linux Flutter 3.44.8, `TZ=UTC` | see §6.1 |
| Android `integration_test/` on an emulator | **not run** — this change adds nothing under `lib/features/` that the device gate exists to catch, and the rule that requires it is written for new features. Stated rather than skipped silently |
| TalkBack, device profiling | **not run** |

### 6.1 · Recorded results

| Gate | Result |
|---|---|
| `flutter analyze` repo-wide | **No issues found** (122.6 s) |
| `TZ=UTC flutter test --exclude-tags golden` | **5144 passed**, exit 0 |
| Clipping matrix, 4 widths × 4 scales | 16/16 green *after* the fix; 15/16 before it, failing at 320 dp × 2.0 |
| `goldens (linux)` job, WSL Ubuntu 24.04 · Flutter 3.44.8 · `TZ=UTC` | 44 test files, **343 tests**, all green; **26 PNGs** rewritten |
| `check_docs.py` | PASS — specification internally consistent. C2 database invariants not run (no `--db`), so nothing here is runtime evidence |
| `build_screen_gallery.py` (Guard C) | PASS — 82 screens, 50 with dark, 15.5 MB, every on-surface PNG still owned |
| Android `integration_test/` | not run — see the table above for why |

**Which 26 pictures moved, and why that number is larger than the change.**
Twenty-three are Library screens whose sheet, dialog or menu is itself
unchanged and whose hero simply sits behind it — the delete confirm, the sort
sheet, the move picker, the rename form. Two are Study Home. One is the
deck-list rhythm plate, which measures band geometry. The review page embeds
the eight that show the change and lists the other seventeen by name rather
than padding itself with pictures of a dialog that did not move.

**Review page:** the before/after gallery is published as its own artifact,
paired at 393 × 852 dp with the light/dark filter and a side swap. **The
project's pinned gallery URL was deliberately not republished.** That page is
supposed to answer "what does the app look like", and pointing it at an
unmerged branch would make it answer "what might the app look like" without
saying so.

## 7 · Follow-ups this audit opens and does not close

1. **P2 · `MxProgressBar` caption clips at 320 dp × 2.0.** Shared primitive,
   design-system task. Excluded by name from the widened guard, with the debt
   written at the exclusion.
2. **P3 · `MxCard.accent` and `MxCard.tonal` have no production caller** after
   the trial. Retire, or re-justify with a caller. `card-recipes.md` is where
   that gets decided.
3. **P3 · Study Entry (H5)** — decide whether a two-choice fork with no panel
   is the intent.
4. **Runtime evidence.** Nothing here was measured with TalkBack or a profiler.
   The accessibility and performance rows stay provisional until it is.
