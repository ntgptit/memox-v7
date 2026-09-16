# Study · Match — layout spec (Flutter handoff)

Reference frame: **390 × 780** (logical px = Flutter `dp`, 1:1). Source: `ui_kits/mobile/screens/MatchScreen/MatchScreen.jsx`.

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
| 2 | StudyTopBar — chip `MATCH`, counter `1 / 5` | 56 |
| 3 | Context line `Board 1 of 3 · 4 pairs left` | 27 |
| 4 | Tile grid (**Expanded**) | rest ≈ **619** |
| 5 | Hint line | ~**38** (10 + 16 + ... see below) |

Grid padding `0 / 14 / 10`. Hint block padding `8 / 14 / 14`, content ~16 → block **38**.
Grid height = `780 − 44 − 56 − 27 − 38 = 615`, minus its own 10 bottom padding → tile area **605**.

## Tile grid

- **2 columns × 5 rows**, gap **8** both axes, all cells equal (`1fr`).
  Flutter: `GridView.count(crossAxisCount: 2, mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: …)` —
  or better, a `Column` of 5 `Expanded` `Row`s so the grid always fills the height exactly.
- Tile: radius **12**, padding `14 / 12`, content centered both axes, text centered.
- Cell height derives from the container: `(605 − 4 × 8) / 5 ≈ **113**`. Do not hard-code it — let it flex.

### Tile states

| State | Background | Text | Border | Opacity |
|---|---|---|---|---|
| idle | `surface-container-lowest` | `on-surface` | ghost border (1 px) | 1 |
| selected | `primary` | `on-primary` | 1 px `primary` | 1 |
| matched | `mastery` @ 12 % | `mastery` | 1 px `mastery` @ 30 % | **0.7** |

- Matched tiles also show a **14** check icon before the text, gap **6**.
- Type: front (term) **18 / w700 / letter-spacing −0.4**; back (meaning) **14 / w600 / letter-spacing 0**.
- State transition: **200 ms** `cubic-bezier(0.2,0,0,1)`.

## Content shown in the mock

Pair 1 matched (공부하다 / to study), 먹다 selected, 3 pairs untouched → counter `1 / 5`, subhead `4 pairs left`.

## Hint

`Tap a term, then its meaning to match` — icon `check`.

## Color roles

| Element | Role |
|---|---|
| Mode chip, selected tile | `primary` / `on-primary` |
| Matched tile | `mastery` (12 % fill, 30 % border, 100 % text) |
| Idle tile | `surface-container-lowest` + ghost border, `on-surface` text |
| Counter, subhead, hint | `on-surface-variant` / `text-secondary` |
| Progress track | `surface-container` |
