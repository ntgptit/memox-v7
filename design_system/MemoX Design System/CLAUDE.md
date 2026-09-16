# Project notes

## Flutter handoff — MemoX (Android first)

This design system feeds a Flutter app. **The handoff template lives in
[`docs/MEMOX_DESIGN_TO_FLUTTER_SPEC_TEMPLATE.md`](docs/MEMOX_DESIGN_TO_FLUTTER_SPEC_TEMPLATE.md).
Read it before generating or editing any Flutter handoff.** It replaced an
earlier repo-inspection template on 2026-09-11; the premise is inverted, so
don't carry over habits from the old one.

The binding premise: **Claude Design has no access to the Flutter repository.**
Never assume its folder structure, tokens, ThemeData, or shared widgets, and
never write Flutter source. The job is to author the design and extract a
complete visual specification another agent can rebuild from without reopening
the HTML/JSX.

- **Exact values are expected, not forbidden.** Raw hex, px, weights, line
  heights are design specifications. Vague words (modern, clean, premium,
  spacious, soft) are failures.
- **Both themes** whenever both exist — Tokyo Pure Light and Tokyo Nebula.
- **Spacing ≠ component size.** Keep them separate, and classify every dimension
  as FIXED / MINIMUM / MAXIMUM / CONTENT-DRIVEN / RESPONSIVE / SYSTEM-OWNED.
  Never turn a content-driven element into a fixed-height contract.
- **Typography is not on the spacing grid.** Preserve the hierarchy.
- **Icon visual size and touch area are separate** — state both.
- **Android owns** status bar, cutout, gesture/nav inset, keyboard inset, Back.
  The kit's 44px preview status bar is device-frame chrome, never an app token.
- **Inferred states get marked `INFERRED`.**
- **Component contracts must be implementation-complete.** A global token table
  is not enough. Each contract carries the concrete properties needed to rebuild
  that component: height / min height · width behaviour (content-driven,
  stretch-by-parent, fixed, responsive) · horizontal and vertical padding ·
  radius · label typography role · icon size · icon-to-label gap · border ·
  shadow/elevation · alignment. Where the design genuinely does not determine a
  value, write `UNSPECIFIED` — never invent one to fill the table.
- **Validate internal consistency before shipping the spec.** The same property
  must not carry two values (a global pressed overlay of 12% and a component one
  of 8%). When a component deliberately departs from the global rule, mark it
  `COMPONENT OVERRIDE`; otherwise use one value throughout.
- **Scope-label measurements that could be mistaken for global tokens** —
  `GLOBAL` / `COMPONENT` / `SCREEN` / `SYSTEM` / `PREVIEW`, e.g. 16 screen gutter
  GLOBAL, 48 button height COMPONENT, 48 scroll tail SCREEN, status bar SYSTEM,
  44px mock status bar PREVIEW. Only where the ambiguity is real — not on every
  color or type row. The point is to stop a downstream agent promoting a local
  or mock measurement into a global Flutter token.
- **Flag web techniques that must not be copied literally** (absolute
  positioning, fixed viewport heights, hover-only behaviour, CSS filters, fake
  system chrome) — describe the visual intent instead.
- Output follows the template's §14 section order and ends with the compact
  `Implementation handoff` block, which is what gets passed downstream.

**Division of ownership:** Claude Design owns the visual specification; the
downstream coding agent owns Flutter architecture and implementation. Never
generate Flutter source, repository paths, class names, or architecture guesses.

### Where the generated specs live

`ui_kits/mobile/flutter-prompt.html` renders one spec per kit widget, deep-linked
from every card in `ui_kits/mobile/components.html`. Widget facts come from
`ui_kits/mobile/flutter-prompts.json`, generated from the `<WidgetCard>` call
sites — edit the card, regenerate the JSON, never hand-edit the JSON. Global
token values are read from `colors_and_type.css` at page load so they cannot
drift from the design.

## Deferred issues — do not re-raise

- **FAB đè lên `⋮` của deck card (Library / deck list).** Đã đo: chồng 48×22px = 46% vùng chạm ở trạng thái nghỉ. Chủ động hoãn (2026-08-25) — chưa dùng thực tế, sẽ fix nếu gặp bug thật. Không đưa vào review, không đề xuất phương án (app bar / long-press menu / mirror FAB / hide-on-scroll) trừ khi user hỏi lại.

## Review style

- Khi review từ ảnh tĩnh: chỉ khẳng định những gì đo được từ pixel, và nói rõ cái nào là suy đoán. Phân biệt hộp vẽ (mực) với vùng chạm. Ngưỡng touch target của repo là **48px** (`AppSpacing.minimumTouchTarget`), không phải 44.
