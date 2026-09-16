# Study · Recall — layout spec (Flutter handoff)

Reference frame: **390 × 780**. Source: `ui_kits/mobile/screens/RecallScreen/RecallScreen.jsx`.

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

> Recall and Fill use **`mastery`** as the top-bar accent (chip + progress fill), not `primary`.

## Vertical stack (Column, nothing scrolls)

| # | Block | Height |
|---|---|---|
| 1 | Status bar | 44 |
| 2 | StudyTopBar — chip `RECALL`, accent `mastery`, counter `8 / 12` | 56 |
| 3 | Context line `Vocab — chapter 1 · Term → meaning` | 27 |
| 4 | Body (**Expanded**), padding `0 / 14 / 0`, gap **10** | rest ≈ **543** |
| 4a | ↳ Term card (**Expanded**, min 160) | ≈ **266** |
| 4b | ↳ Meaning card (**Expanded**, min 160) | ≈ **266** |
| 5 | CTA row, padding `14 / 14 / 0` | **66** (14 + 52 button) |
| 6 | Hint line | **42** (padding 10 / 14 / 16) |

The two cards are **equal Expanded siblings** — same flex, same min-height. That's the ratio to fix in Flutter.

## 4a · Term card

- `.card`: `surface-raised`, radius **20**, shadow `shadow-soft`, padding **14**, content centered.
- Term: **32 / w700 / letter-spacing −0.5 / line-height 1.15**, centered.
- Icon buttons **32 × 32**, icon **16**, `on-surface-variant`:
  - pencil — absolute **top 8, right 8**
  - speaker — absolute **bottom 8, right 8**

## 4b · Meaning card

- Same card, but background `surface-container-low` (one step down — signals "answer area").
- Padding **16**, min-height 160, content centered.
- **Hidden state**: a placeholder bar **140 × 14**, radius 999, `surface-container-high`, opacity **0.7**, blur **2 px**.
- **Revealed state**: text **14 / line-height 1.55**, centered, `text-primary`, `text-wrap: pretty`.

## 5 · CTA row

- Row centered, gap **10**, button height token `size-button` (**52**), radius 999.
- Hidden state: one button `Show answer`, padding `0 / 36` (hug width).
- Revealed state: two buttons `Forgot` / `Got it`, each `flex: 1` with **maxWidth 160**.

## 6 · Hint

- Hidden: `Recall the meaning, then show the answer`
- Revealed: `Rate how well you recalled it`
- Icon `check` **16**.

## Color roles

| Element | Role |
|---|---|
| Mode chip, progress fill, CTA fill | `mastery` (chip) / `primary` (buttons) |
| Term card | `surface-raised` + `shadow-soft` |
| Meaning card | `surface-container-low` |
| Placeholder bar | `surface-container-high` @ 70 % |
| Term & meaning text | `text-primary` |
| Icon buttons, counter, hint | `on-surface-variant` |
