# Study · Review — layout spec (Flutter handoff)

Reference frame: **390 × 780** (logical px = Flutter `dp`, 1:1). All values below are exact from the mock (`ui_kits/mobile/screens/StudyScreen/StudyScreen.jsx`).

## Vertical stack (root = Column, no scrolling anywhere)

| # | Block | Height | Notes |
|---|---|---|---|
| 1 | Status bar | **44** | mock chrome only — in Flutter this is `SafeArea` top inset |
| 2 | StudyTopBar (AppBar) | **56** | `--memox-size-appbar` |
| 3 | Context line block | **27** | see below |
| 4 | Body (Expanded) | rest = **653** | padding `0 / 14 / 12` |
| 4a | ↳ Card | **Expanded** ≈ 611 | fills all slack |
| 4b | ↳ gap | **14** | |
| 4c | ↳ Swipe hint row | **16** | |

Body = `780 − 44 − 56 − 27 = 653`. Card height = `653 − 12 (bottom pad) − 14 (gap) − 16 (hint) ≈ 611`.
The card is the only flexible element — never give it a fixed height.

## 2 · StudyTopBar

- Height 56, horizontal padding **8**, gap **4**.
- Close button: 36 × 36 circular tap target, icon **20**, `text-primary`.
- Middle group: `Expanded`, margin `0 6`, gap **8** between chip and bar.
  - Mode chip: text 12 / w700 / letter-spacing **1.2** / uppercase, padding `3 / 8`, radius 999,
    color `primary`, background `primary @ 10% alpha`.
  - Progress bar: height **4**, radius 999, track `surface-container`,
    fill `primary`, width = `current / total`. Animate width 200 ms, `cubic-bezier(0.2,0,0,1)`.
- Counter `8 / 23`: 12 / w600, tabular figures, `on-surface-variant`, **paddingRight 10**
  (this is what optically matches the ✕ inset on the left — don't use 8 or 14).

## 3 · Context line

`Vocab — chapter 1 · 12 new · 11 review`

- Style: 11 / w700 / letter-spacing **0.6** / uppercase, `text-secondary`, centered.
- Box: `marginTop −6`, padding `0 / 14 / 20`. Net block height **27**.
- Reason for the −6: the 56-high app bar centers a 4-high bar, leaving ~26 of dead space beneath it.
  In Flutter use `Transform.translate(offset: Offset(0,-6))` or just `Padding(top: −6 equivalent)` → simplest is
  `Padding(EdgeInsets.only(left:14,right:14,bottom:20))` inside a `Transform.translate(offset: Offset(0,-6))`.
  Result: ~20 dp of visual space above and below the label.

## 4a · Card

- `surface-raised`, radius **20**, no border, shadow `shadow-soft`
  (dark mode: no shadow, 1 px ghost border).
- Padding **0** (the two halves own their padding).
- Internal: Column of `Expanded(top) / Divider / Expanded(bottom)` — the two halves are exactly equal.

**Top half (term)**
- Padding `20 / 16 / 8`.
- Overline `Korean`: 11 / w700 / ls 0.6 / uppercase, positioned absolute **top 16, left 20**.
- Term: **32 / w700 / letter-spacing −0.5 / line-height 1.15**, centered.

**Divider**
- Height **1**, color `outline-variant` at **50 % opacity**, horizontal margin **20**.

**Bottom half (meaning)**
- Padding `8 / 16 / 20`.
- Overline `Meaning`: same as above, absolute top 16 / left 20.
- Meaning: **24 / w600 / letter-spacing −0.3**, centered. No example sentence.

## 4c · Swipe hint

- Row, centered, gap **8**. Icon `chevrons-right` **16**, text **12 / letter-spacing 0.3**,
  color `on-surface-variant`.
- Copy: `Swipe left for next, right to go back`.

## Gesture

- Drag threshold **70 dp**. Left → next, right → previous. Below threshold, snap back.
- While dragging: `translateX(dx)` + `rotate(dx × 0.025 deg)`, opacity `1 − min(|dx|/400, 0.5)`.
- On commit: fling to ±500, then swap card after **180 ms**.
- Settle animation: **220 ms**, `cubic-bezier(0.05,0.7,0.1,1)` for transform, `cubic-bezier(0.2,0,0,1)` for opacity.

## Color roles used

Use the role, not a hex — every role already resolves per theme in `colors_and_type.css`.

| Element | Role |
|---|---|
| Mode chip text, progress fill | `primary` |
| Mode chip background | `primary` @ 10 % alpha |
| Progress track | `surface-container` |
| Counter, overlines, swipe hint | `on-surface-variant` / `text-secondary` (same role) |
| Card background | `surface-raised` |
| Term & meaning text | `text-primary` (`on-surface`) |
| Divider | `outline-variant` @ 50 % opacity |
| Card shadow | `shadow-soft` |
| Close icon | `text-primary` |

Screen gutter is **14** everywhere on this screen — app bar padding (8 + 6 margin = 14 effective), context line, body.
