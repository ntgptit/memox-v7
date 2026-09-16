# Study · Fill — layout spec (Flutter handoff)

Reference frame: **390 × 780**. Source: `ui_kits/mobile/screens/FillScreen/FillScreen.jsx`.

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

> Fill shares Recall's skeleton exactly — same two-card ratio, same CTA row, same hint slot.
> Only the card contents and the accent differ. Accent = **`mastery`**.

## Vertical stack (Column, nothing scrolls)

| # | Block | Height |
|---|---|---|
| 1 | Status bar | 44 |
| 2 | StudyTopBar — chip `FILL`, accent `mastery`, counter `12 / 15` | 56 |
| 3 | Context line `Vocab — chapter 1 · Meaning → term` | 27 |
| 4 | Body (**Expanded**), padding `0 / 14 / 0`, gap **10** | rest ≈ **543** |
| 4a | ↳ Meaning card (**Expanded**, min 160) | ≈ **266** |
| 4b | ↳ Answer card (**Expanded**, min 160) | ≈ **266** |
| 5 | CTA row, padding `14 / 14 / 0` | **66** |
| 6 | Hint line | **42** |

Both cards are **equal Expanded siblings**, min-height **160** each.

## 4a · Meaning card (prompt)

- `.card`: `surface-raised`, radius **20**, shadow `shadow-soft`, padding `18 / 16`, content centered.
- Text: **14 / line-height 1.55**, centered, `text-primary`, `text-wrap: pretty`.
- Pencil icon button **32 × 32** (icon 16) absolute **top 8, right 8**.

## 4b · Answer card

- Same card, background `surface-container-low`, padding **14**, min-height 160, centered.

**State `input`**
- Typed text: **32 / w700 / letter-spacing −0.4**, inline row with gap **4**.
- Caret: **2 × 30** bar, color = accent (`mastery`), blink **1 s** step (50 % on / 50 % off).

**State `wrong`**
- Column centered, gap **6**.
- Wrong answer: **24 / w700 / letter-spacing −0.3**, `rating-again` role, **strikethrough 1 px**.
- Correct answer below: **24 / w700 / letter-spacing −0.3**, `text-primary`.
- Two icon buttons **32 × 32** (icon 16): speaker absolute **top 8 / right 8**, undo absolute **bottom 8 / left 8**.

## 5 · CTA row

- Row centered, gap **10**, height `size-button` (**52**), radius 999, each button `flex: 1` **maxWidth 160**.
- `input`: `Hint` (outlined — transparent fill, 1 px `primary` border, `primary` text) + `Check` (filled `primary`).
- `wrong`: `Mark correct` (outlined) + `Try again` (filled).

## 6 · Hint

- `input`: `Type the term for this meaning, then check`
- `wrong`: `Compare your answer, then try again`
- Icon `pencil` **16**.

## Color roles

| Element | Role |
|---|---|
| Mode chip, progress fill, caret | `mastery` |
| Filled CTA | `primary` / `on-primary` |
| Outlined CTA | transparent + `primary` border & text |
| Meaning card | `surface-raised` + `shadow-soft` |
| Answer card | `surface-container-low` |
| Wrong answer text | `rating-again` |
| Prompt & correct answer text | `text-primary` |
| Icon buttons, counter, hint | `on-surface-variant` |
