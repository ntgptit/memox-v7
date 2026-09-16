# Study · Guess — layout spec (Flutter handoff)

Reference frame: **390 × 780**. Source: `ui_kits/mobile/screens/GuessScreen/GuessScreen.jsx`.

## Shared chrome (identical on all study screens)

| # | Block | Height |
|---|---|---|
| 1 | Status bar | **44** (Flutter: `SafeArea` top inset) |
| 2 | StudyTopBar (AppBar) | **56** |
| 3 | Context line block | **27** |

**StudyTopBar** — height 56, horizontal padding **8**, gap **4**.
- Close button 36 × 36, icon **20**, role `text-primary`.
- Middle group `Expanded`, margin `0 6`, gap **8**.
  - Mode chip: 12 / w700 / letter-spacing **1.2** / uppercase, padding `3 / 8`, radius 999, text = accent role, background = accent @ 10 % alpha.
  - Progress bar: height **4**, radius 999, track `surface-container`, fill = accent, width `current / total`, animate 200 ms `cubic-bezier(0.2,0,0,1)`.
- Counter: 12 / w600, tabular figures, `on-surface-variant`, **paddingRight 10** (optically matches the ✕ inset — don't use 8 or 14).

**Context line** — 11 / w700 / letter-spacing **0.6** / uppercase, `text-secondary`, centered.
Box: `marginTop −6`, padding `0 / 14 / 20` → net **27**. The −6 compensates for the dead space under the 4-high progress bar inside a 56-high app bar; result is ~20 dp above and below the label.

**Hint line (bottom of every screen)** — Row centered, gap **8**, icon **16**, text **12 / letter-spacing 0.3**, `on-surface-variant`.

Screen gutter is **14** on every study screen.

## Vertical stack (Column, nothing scrolls)

| # | Block | Height |
|---|---|---|
| 1 | Status bar | 44 |
| 2 | StudyTopBar — chip `GUESS`, counter `5 / 20` | 56 |
| 3 | Context line `Vocab — chapter 1 · Term → meaning` | 27 |
| 4 | Body (**Expanded**), padding `0 / 14 / 0`, gap **10** | rest ≈ **611** |
| 4a | ↳ Prompt card (**Expanded**, min 180) | ≈ **303** |
| 4b | ↳ Options column (fixed) | **298** |
| 5 | Hint line | **42** (padding 10 / 14 / 16 + ~16 content) |

Options column = `5 × 50 + 4 × 8 = 298`. Prompt card absorbs everything else — it must be
`Expanded` with `minHeight 180`, never a fixed height. **Every box uses border-box sizing**
(padding inside the height) — this was the bug that made the options overflow.

## 4a · Prompt card

- `.card`: `surface-raised`, radius **20**, shadow `shadow-soft`, padding `20 / 14`.
- Column centered, gap **10**.
- Overline `What is this?`: 11 / w700 / ls 0.6 / uppercase, `text-secondary`.
- Term: **32 / w700 / letter-spacing −0.5 / line-height 1.15**, centered.

## 4b · Option rows (5)

- Row: min-height **50**, padding `9 / 14`, radius **12**, gap **12**, vertically centered, border-box.
- Letter badge: **28 × 28** circle, border **1.5 px currentColor**, text 12 / w700, opacity 0.85, never shrinks.
- Answer text (meaning only, nothing else): **16 / w500 / letter-spacing −0.1 / line-height 1.25**, fills the remaining width.
- Trailing icon **18**: check on correct, ✕ on wrong.
- Transition **200 ms** `cubic-bezier(0.2,0,0,1)`.

### Option states

| State | Background | Text | Border | Opacity |
|---|---|---|---|---|
| idle | `surface-container-lowest` | `on-surface` | ghost 1 px | 1 |
| correct | `mastery` @ 14 % | `mastery` | 1 px `mastery` @ 40 % | 1 |
| wrong | `danger` @ 10 % | `error` | 1 px `danger` @ 35 % | 1 |
| faded (unpicked, after answer) | `surface-container-lowest` | `on-surface-variant` | ghost 1 px | **0.36** |

## Hint

`Answer shown — the correct option is highlighted` — icon `check`. No countdown, no auto-advance progress bar (removed on purpose).

## Color roles

| Element | Role |
|---|---|
| Mode chip, progress fill | `primary` |
| Correct option | `mastery` |
| Wrong option | `danger` fill / `error` text |
| Card | `surface-raised` + `shadow-soft` |
| Prompt term | `text-primary` |
| Overline, counter, hint | `text-secondary` / `on-surface-variant` |
